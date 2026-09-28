extends SceneTree

const Houses := preload("res://campaign/house_command_state.gd")
const Legacy := preload("res://campaign/command_state.gd")
const Scene := preload("res://world/house_sandbox.tscn")
const SAVE := "user://house-conflict-regression.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func ok(error: String, message: String) -> void:
	check(error.is_empty(), message + ": " + error)

func at_table(model) -> void:
	model.record_position(Vector3(0, 0.2, 3))

func setup(choice: String = "", package: String = "patrol"):
	var model = Houses.new()
	at_table(model)
	ok(model.petition("begin"), "hear petition")
	if choice != "":
		ok(model.petition(choice), "choose " + choice)
	ok(model.issue(package), "issue allocated patrol")
	return model

func visit_both(model) -> void:
	model.record_position(Vector3(-12, 0.2, -28))
	ok(model.visit("village"), "observe village")
	model.record_position(Vector3(20, 0.2, -58))
	ok(model.visit("outpost"), "observe outpost")

func refused(model, action: String, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not model.petition(action).is_empty(), label)
	check(model.snapshot() == before, label + " leaves live state unchanged")

func bad_save(model, candidate: Variant, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not model.restore(candidate).is_empty(), label + " rejected")
	check(model.snapshot() == before, label + " preserves live state")

func _run() -> void:
	_test_roster()
	_test_authority_and_transitions()
	_test_patrol_outcomes()
	_test_wait_and_reconciliation()
	_test_persistence()
	await _test_scene()
	print("HOUSE_CONFLICT_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_roster() -> void:
	var model = Houses.new()
	check(model is Legacy, "one extended command authority, not a parallel simulation")
	var catalog: Dictionary = model.roster()
	check(catalog.schema_version == "antagonist-roster.v1", "versioned roster")
	check(catalog.people.size() == 6, "six requested biographies")
	var ids: Array = []
	var group_ids: Array = []
	for group in catalog.groups:
		check(group.id not in group_ids, "unique group " + group.id)
		group_ids.append(group.id)
	var active: Array = []
	for person in catalog.people:
		check(person.id not in ids, "unique person " + person.id)
		ids.append(person.id)
		check(person.narrative_role == "antagonist" and person.playable == false, "NPC antagonist " + person.id)
		check(person.primary_group in group_ids, "group reference " + person.id)
		for group_id in person.organization_ids:
			check(group_id in group_ids, "organization reference " + person.id)
		for ref in person.source_refs:
			check(catalog.sources.has(ref), "source reference " + person.id)
		check(person.source_note.length() > 20 and person.biography.begins_with("Campaign portrayal:"), "authored biography separate from source status")
		if person.scenario_presence == "active":
			active.append(person.id)
	check(active == ["sada_kaur", "mehtab_kaur", "datar_kaur"], "chapter-gated active roster")
	check(model.biography("raj_kaur").scenario_presence == "earlier_chapter", "regency not spawned into 1801")
	check(model.biography("jind_kaur").scenario_presence == "later_chapter", "later character not spawned early")
	check(model.biography("missing").is_empty(), "unknown biography fails closed")
	check(model.snapshot().actors.size() == 2, "six biographies do not create playable slots")
	var info: Dictionary = model.biography("sada_kaur")
	info.playable = true
	check(not model.biography("sada_kaur").playable, "biography reads are independent")
	var copied: Dictionary = model.house_state()
	copied.relations.sada_kaur.trust = 100
	check(model.house_state().relations.sada_kaur.trust == 60, "views cannot mutate authority")
	ok(model.validate(model.snapshot()), "initial state valid")

func _test_authority_and_transitions() -> void:
	var model = Houses.new()
	refused(model, "begin", "table proximity required")
	at_table(model)
	refused(model, "kill_mother", "no invented murder operation")
	refused(model, "respect_claim", "cannot decide before petition")
	ok(model.petition("begin"), "begin once")
	check(model.house_state().relations.sada_kaur.stance == "competing_patron", "patron becomes competing patron")
	refused(model, "begin", "no duplicate petition")
	var other: Dictionary = model.house_state().relations.mehtab_kaur
	ok(model.petition("assert_authority"), "assert authority")
	check(model.house_state().relations.sada_kaur.stance == "rival", "assertion creates rivalry")
	check(model.house_state().relations.mehtab_kaur == other, "shared household does not force hostility")
	check(model.house_state().relations.datar_kaur.stance == "ally", "antagonist cast member can remain ally")
	refused(model, "respect_claim", "cannot farm alternating decisions")
	ok(model.petition("reconcile"), "rival can reconcile")
	check(model.house_state().relations.sada_kaur.stance == "ally", "rival becomes ally")
	check(model.house_state().relations.sada_kaur.grievance == 25, "reconciliation retains grievance")
	refused(model, "reconcile", "reconciliation cannot repeat")
	ok(model.issue("patrol"), "issue after promise")
	var allocation: Dictionary = model.snapshot().resources
	ok(model.cancel(), "cancel before deployment")
	check(model.snapshot().resources.riders == allocation.riders + 4, "original refund remains correct")
	check(model.house_state().decision == "reconcile", "cancelling patrol does not erase house promise")
	ok(model.validate(model.snapshot()), "cancelled extended state validates")
	ok(model.issue("patrol"), "second order ID after cancellation")
	ok(model.play_commander(), "take captain")
	refused(model, "begin", "captain cannot make house concessions")
	ok(model.return_to_darbar(), "return without changing command identity")
	ok(model.validate(model.snapshot()), "handover validates")

func _test_patrol_outcomes() -> void:
	for choice in ["respect_claim", "assert_authority"]:
		var model = setup(choice)
		var order_id: String = model.snapshot().order.id
		ok(model.play_commander(), "manual " + choice)
		var before: Dictionary = model.snapshot()
		check(not model.resolve("secure").is_empty(), "cannot resolve before observations")
		check(model.snapshot() == before, "failed base resolution does not mutate politics")
		visit_both(model)
		ok(model.resolve("secure"), "secure under " + choice)
		check(model.house_state().phase == "resolved", "political outcome recorded")
		check(model.snapshot().order.id == order_id, "same command identity")
		check(is_equal_approx(model.place("outpost").security, 0.60), "original security effect retained")
		check(not model.house_state().territory.annexed, "security never means annexation")
		check(model.received_house_report().is_empty(), "actual outcome not leaked as received evidence")
		ok(model.validate(model.snapshot()), "pending combined report valid")
		model.advance(3)
		check(model.received_house_report().is_empty(), "report still in transit")
		model.advance(1)
		check(not model.received_house_report().is_empty(), "same original delivery tick releases house report")
		check(model.received_house_report().id == order_id + ".house-report", "separate evidence identity bound to order")
		check(model.snapshot().resources.riders == 6 and model.snapshot().resources.treasury == 80, "unchanged resource accounting")
		var riders: int = model.snapshot().resources.riders
		model.advance(10)
		check(model.snapshot().resources.riders == riders, "report arrival releases riders once")
		refused(model, "reconcile", "cannot rewrite reported political outcome")
		var t: Dictionary = model.received_house_report().territory
		if choice == "respect_claim":
			check(t.passage == "permitted" and t.revenue_status == "recognized_local_claim" and t.local_cooperation == 60, "negotiated passage preserves local claim")
		else:
			check(t.passage == "contested" and t.revenue_status == "disputed" and t.local_cooperation == 20, "force projects presence without legitimacy")
		var delegated = setup(choice)
		ok(delegated.delegate(), "delegate same commission")
		delegated.advance(100)
		check(delegated.snapshot().order.status == "completed", "delegated commission finishes")
		check(delegated.house_state().territory == model.house_state().territory, "manual and delegated consequences agree")
		ok(delegated.validate(delegated.snapshot()), "delegated combined state validates")

func _test_wait_and_reconciliation() -> void:
	var model = setup("defer")
	ok(model.delegate(), "delegate observe-only commission")
	model.advance(100)
	check(model.snapshot().order.status == "active" and model.snapshot().order.visited.size() == 2, "delegated captain reaches outpost and waits")
	check(model.snapshot().reports.is_empty(), "waiting does not fake a report")
	var events: int = model.house_state().history.size()
	model.advance(100)
	check(model.house_state().history.size() == events, "waiting does not spam outcome events")
	ok(model.petition("reconcile"), "Ranjit revises commission at table")
	model.advance(10)
	check(model.snapshot().order.status == "completed", "reconciled delegated patrol resumes")
	ok(model.validate(model.snapshot()), "resumed state validates")
	for choice in ["", "defer"]:
		var scouts = setup(choice, "scout")
		ok(scouts.play_commander(), "control scouts")
		check(not scouts.resolve("secure").is_empty(), "unsettled commission cannot secure")
		ok(scouts.resolve("withdraw"), "withdraw without forced victory")
		check(scouts.snapshot().reports[0].road_security == null, "unobserved security stays unknown")
		scouts.advance(4)
		check(scouts.house_state().territory.military_presence == "none", "withdrawal creates no military presence")
		ok(scouts.validate(scouts.snapshot()), "withdrawal validates")
	var old = Legacy.new()
	at_table(old)
	ok(old.issue("patrol"), "legacy assignment")
	ok(old.delegate(), "legacy delegation")
	old.advance(100)
	var extended = Houses.new()
	ok(extended.restore(old.snapshot()), "import completed legacy save")
	check(extended.house_state().phase == "dormant", "legacy import never invents political history")
	refused(extended, "begin", "cannot attach a petition retroactively")

func _test_persistence() -> void:
	var model = setup("assert_authority")
	ok(model.play_commander(), "active save setup")
	model.record_position(Vector3(2.5, 0.2, -10))
	ok(model.save_to(SAVE), "save extended active state")
	var restored = Houses.new()
	ok(restored.load_from(SAVE), "load extended state")
	check(model.snapshot() == restored.snapshot(), "complete active snapshot roundtrip")
	check(typeof(restored.house_state().relations.sada_kaur.trust) == TYPE_INT, "derived counts normalized after JSON")
	ok(model.return_to_darbar(), "saved continuation delegate")
	ok(restored.return_to_darbar(), "restored continuation delegate")
	model.advance(100)
	restored.advance(100)
	check(model.snapshot() == restored.snapshot(), "identical deterministic continuation")
	ok(model.save_to(SAVE), "replace existing save")
	ok(restored.load_from(SAVE), "load replaced save")
	var original: Dictionary = model.snapshot()
	for value in [null, [], "invalid"]:
		bad_save(model, value, "bad top-level value")
	var malformed: Dictionary = original.duplicate(true)
	malformed.house_conflict = []
	bad_save(model, malformed, "wrong house type")
	for key in ["schema_version", "roster_version", "phase", "scenario_id"]:
		malformed = original.duplicate(true)
		malformed.house_conflict[key] = "forged"
		bad_save(model, malformed, "invalid " + key)
	malformed = original.duplicate(true)
	malformed.house_conflict.territory.annexed = true
	bad_save(model, malformed, "forged annexation")
	malformed = original.duplicate(true)
	malformed.house_conflict.relations.sada_kaur.trust = true
	bad_save(model, malformed, "boolean trust")
	malformed = original.duplicate(true)
	malformed.house_conflict.relations.sada_kaur.trust = 40.5
	bad_save(model, malformed, "fractional forged trust")
	malformed = original.duplicate(true)
	malformed.house_conflict.history[0].actor_id = "sada_kaur"
	bad_save(model, malformed, "NPC making player decision")
	malformed = original.duplicate(true)
	malformed.house_conflict.history[0].tick = -1
	bad_save(model, malformed, "negative event time")
	malformed = original.duplicate(true)
	malformed.house_conflict.history[0].sequence = 1.5
	bad_save(model, malformed, "fractional sequence")
	malformed = original.duplicate(true)
	malformed.house_conflict.history[0].petition_id = "other_claim"
	bad_save(model, malformed, "wrong petition identity")
	malformed = original.duplicate(true)
	malformed.house_conflict.history[1].kind = "declare_religious_war"
	bad_save(model, malformed, "unknown religious hostility rule")
	malformed = original.duplicate(true)
	malformed.house_conflict.report.order_id = "other_order"
	bad_save(model, malformed, "unbound political evidence")
	malformed = original.duplicate(true)
	malformed.house_conflict.report.arrives_at = 999
	bad_save(model, malformed, "independent report clock")
	malformed = original.duplicate(true)
	malformed.player.character_id = "raj_kaur"
	bad_save(model, malformed, "antagonist turned playable")
	var legacy = Legacy.new()
	at_table(legacy)
	ok(legacy.issue("scout"), "legacy in-progress allocation")
	ok(restored.restore(legacy.snapshot()), "import active legacy data")
	var no_extension: Dictionary = restored.snapshot()
	no_extension.erase("house_conflict")
	check(no_extension == legacy.snapshot(), "legacy base fields unchanged by migration")
	var json = JSON.parse_string(JSON.stringify(restored.snapshot(), "", true, true))
	ok(restored.restore(json), "JSON float quantities accepted only when exact")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var before: Dictionary = restored.snapshot()
	check(not restored.load_from(SAVE).is_empty(), "malformed file rejected")
	check(restored.snapshot() == before, "malformed file cannot partially replace state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func _test_scene() -> void:
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	check(scene.campaign is Houses, "visible scene uses extended authority")
	scene.avatar.position = Vector3(0, 0.2, 3)
	scene._interact()
	check(scene._choices.has_node("HousePoliticsButton"), "table exposes house politics")
	scene._choices.get_node("HousePoliticsButton").emit_signal("pressed")
	check(scene._modal.visible, "codex opens")
	check(scene._choices.get_child_count() == 10, "codex has title/body plus petition, six biographies and close")
	scene._perform("biography", "raj_kaur")
	check(scene._choices.get_child(0).text.contains("Raj Kaur"), "biography rendered")
	check(scene._choices.get_child(1).text.contains("NON-PLAYABLE"), "UI does not offer protagonist control")
	scene._perform("petition", "begin")
	scene._perform("petition", "respect_claim")
	check(scene.campaign.house_state().decision == "respect_claim", "UI decision reaches authority")
	scene._perform("issue", "patrol")
	scene._perform("delegate")
	scene.campaign.advance(100)
	scene._refresh_hud()
	check(scene._journal.text.contains("recognized local claim"), "delivered political result in journal")
	check(scene._field_sign.text.contains("permitted"), "world sign reflects received consequence")
	scene._open_houses()
	var tick: int = scene.campaign.snapshot().campaign_tick
	scene._physics_process(10)
	check(scene.campaign.snapshot().campaign_tick == tick, "biography menu pauses simulation")
	scene._close_panel()
	check(scene.avatar.get("input_enabled"), "closing restores player input")
	scene.queue_free()
	await process_frame
