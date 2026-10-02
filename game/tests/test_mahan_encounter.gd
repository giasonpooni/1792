extends SceneTree
const Model := preload("res://mahan/mahan_encounter_state.gd")
const History := preload("res://mahan/mahan_history_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-encounter-regression.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), label + " refused")
	check(model.snapshot() == before, label + " unchanged")

func pose(model, p: Vector3) -> void:
	var s: Dictionary = model.snapshot()
	var riding = s.get("riding")
	s.erase("riding")
	s.player.position = Base.coords(p)
	s.actors[Base.ACTOR_ID].position = Base.coords(p)
	ok(model.restore(s), "pose restore")
	if riding != null:
		model._riding = riding.duplicate(true)

func _to_gujranwala_march(model) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.dispatch_scout("gujranwala_fort_road"), "dispatch fort road")
	ok(model.dispatch_scout("gujranwala_camp"), "dispatch gujranwala camp")
	ok(model.dispatch_scout("gujranwala_settlement"), "dispatch settlement")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision stage")
	ok(model.decide_column("advance_scouts"), "advance column")
	check(model.stage() == "march", "march stage")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.march_to("gujranwala_fort_road"), "march to fort road")
	pose(model, Base.SITES.gujranwala_fort_road)

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial encounter snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("encounter"), "encounter envelope present")
	check(model.snapshot().mahan.has("history"), "history envelope still present")
	check(model.authored_catalog().size() == 4, "four authored catalog events")
	check(model.authored_catalog().has("mahan_gujranwala_ridge_settlement_approach"), "approach event loaded")
	var approach: Dictionary = model.authored_event("mahan_gujranwala_ridge_settlement_approach")
	check(approach.location.place_id == "gujranwala_fort_road", "approach place is fort road")
	check(approach.canon_class == "authored_fiction", "approach is authored fiction")
	check(approach.gameplay.intervention_scope == "order_around", "approach allows order_around")
	check(approach.historical_outcome.fixed == false, "approach outcome not fixed-death")
	check("no_alternate_history_win" in approach.historical_outcome.invariants, "no alternate-history invariant")
	check("no_combat_ai" in approach.historical_outcome.invariants, "no combat AI invariant")
	check(model.encounter().resolved == false, "encounter not resolved yet")
	check(model.pending_encounter_reports().is_empty(), "no encounter scout pending")
	## History adapter stays encounter-free.
	var hist := History.new()
	hist.enable_riding()
	check(not hist.snapshot().mahan.has("encounter"), "history adapter stays encounter-free")
	## Refuse before march / wrong node.
	reject(model, model.begin_ridge_settlement_encounter, "encounter before march")
	_to_gujranwala_march(model)
	ok(model.begin_ridge_settlement_encounter(), "begin encounter on fort road")
	check(model.encounter().active == true, "encounter active")
	var known_ids: Array = []
	for event in model.known_historical_events():
		known_ids.append(event.event_id)
	check("mahan_gujranwala_ridge_settlement_approach" in known_ids, "approach frame known after begin")
	## Advance without custody refused.
	reject(model, model.resolve_encounter_choice.bind("advance_under_custody"), "advance without custody")
	## Hold/observe path (terminal).
	var held := Model.new()
	held.enable_riding()
	_to_gujranwala_march(held)
	ok(held.resolve_encounter_choice("hold_observe"), "hold observe resolves")
	check(held.encounter().resolved == true, "held resolved")
	check(held.encounter().choice == "hold_observe", "held choice")
	check(held.encounter().active == false, "held not active")
	ok(held.validate(held.snapshot()), "valid after hold observe")
	reject(held, held.resolve_encounter_choice.bind("hold_observe"), "duplicate resolve")
	## Delayed scout custody then advance under custody.
	var scouted := Model.new()
	scouted.enable_riding()
	_to_gujranwala_march(scouted)
	ok(scouted.dispatch_approach_scout(), "dispatch approach scout")
	check(scouted.pending_encounter_reports().size() == 1, "encounter scout pending")
	check(scouted.received_encounter_reports().is_empty(), "not knowledge yet")
	check(scouted.encounter().resolved == false, "dispatch is non-terminal")
	check(scouted.journal().filter(func(m): return str(m.id) == "encounter_approach_scout.report").is_empty(), "no early encounter scout journal")
	reject(scouted, scouted.dispatch_approach_scout, "duplicate approach scout")
	reject(scouted, scouted.resolve_encounter_choice.bind("advance_under_custody"), "advance still blocked pending")
	scouted.advance(Model.ENCOUNTER_DELAY - 1)
	check(scouted.pending_encounter_reports().size() == 1, "still pending one tick early")
	scouted.advance(1)
	check(scouted.received_encounter_reports().size() == 1, "encounter scout delivered")
	check(scouted.pending_encounter_reports().is_empty(), "no pending after delivery")
	var found := false
	for memory in scouted.journal():
		if memory.id == "encounter_approach_scout.report" and memory.channel == "delayed_encounter_report":
			found = true
	check(found, "encounter scout memory on delivery only")
	ok(scouted.resolve_encounter_choice("advance_under_custody"), "advance under custody")
	check(scouted.encounter().choice == "advance_under_custody", "advance choice recorded")
	check(scouted.encounter().resolved == true, "advance resolved")
	ok(scouted.validate(scouted.snapshot()), "valid after advance under custody")
	## Fixed endpoint still reachable; no alternate-history win API.
	pose(scouted, Base.SITES.camp_table)
	ok(scouted.acknowledge_fixed_endpoint(), "fixed endpoint after encounter")
	check(scouted.stage() == "closed", "closed after endpoint")
	check(not scouted.has_method("alter_historical_outcome"), "no alter_outcome method")
	check(not scouted.has_method("win_alternate_history"), "no alternate-history win method")
	## Ontology + save/load + forbidden tokens.
	var round := Model.new()
	round.enable_riding()
	_to_gujranwala_march(round)
	ok(round.dispatch_approach_scout(), "round dispatch")
	ok(round.resolve_encounter_choice("hold_observe"), "round hold while scout pending")
	ok(round.save_to(SAVE), "save encounter")
	var again := Model.new()
	ok(again.load_from(SAVE), "load encounter")
	check(again.encounter().resolved == true, "resolved round trip")
	check(again.encounter().choice == "hold_observe", "choice round trip")
	check(again.pending_encounter_reports().size() == 1, "pending scout round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	check(again.resolve_place_id("gujranwala_settlement"), "settlement still place object")
	check(not again.snapshot().actors.has("gujranwala_settlement"), "settlement not a person actor")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.encounter.scout_reports[0].text = "rewritten"
	reject(again, again.restore.bind(bad), "encounter scout text rewrite")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from encounter slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from encounter slice")
	check(not snap_text.contains("sandhawalia") and not snap_text.contains("Sandhawalia"), "Sandhawalia absent from encounter snapshot")
	check(not snap_text.to_lower().contains("khalsa faith") and not snap_text.to_lower().contains("religious war"), "no religious framing tokens")
	ok(Model.validate_authored_event(approach), "approach authored validates")

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes encounter chapter")
	check(chapter.campaign.has_method("begin_ridge_settlement_encounter"), "chapter campaign is encounter model")
	check(chapter.campaign.has_method("observe_historical_event"), "encounter still exposes history")
	check(chapter.campaign.has_method("issue_sub_order"), "encounter still exposes orders")
	check(chapter.campaign.has_method("consult_subordinates"), "encounter still exposes politics")
	check(chapter.campaign.has_method("forage"), "encounter still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("encounter"), "chapter encounter envelope")
	check(chapter.campaign.snapshot().mahan.has("history"), "chapter history envelope")
	check(chapter.campaign.authored_catalog().size() == 4, "chapter catalog loaded")
	check(chapter.campaign.snapshot().mahan.household_id == "sukerchakia", "chapter household object")
	check(chapter.get_node_or_null("FieldHorse") != null, "horse still spawned")
	world.queue_free()
	await process_frame

func _run() -> void:
	_domain()
	await _smoke()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_ENCOUNTER_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
