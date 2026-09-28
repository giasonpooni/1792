extends SceneTree

const Campaign := preload("res://campaign/command_state.gd")
const SAVE := "user://test-command-story.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + description)

func ok(error: String, description: String) -> void:
	check(error.is_empty(), description + ": " + error)

func at_site(model, id: String) -> void:
	# Domain fixture positioning; physics travel is checked separately below.
	var p: Array = model.place(id).position
	model.record_position(Vector3(p[0], p[1], p[2]))

func assigned(package_id: String = "patrol"):
	var model = Campaign.new()
	at_site(model, "lahore_darbar")
	ok(model.issue(package_id), "assign " + package_id)
	return model

func observe_both(model) -> void:
	at_site(model, "village")
	ok(model.visit("village"), "observe village")
	at_site(model, "outpost")
	ok(model.visit("outpost"), "observe outpost")

func reject_restore(model, candidate: Variant, description: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not model.restore(candidate).is_empty(), "reject " + description)
	check(model.snapshot() == before, "failed restore preserves session: " + description)

func _run() -> void:
	_test_orders()
	_test_handover_and_reports()
	_test_delegation()
	_test_persistence()
	_test_corruption()
	await _test_scenes()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("COMMAND_STORY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_orders() -> void:
	var model = Campaign.new()
	ok(model.validate(model.snapshot()), "seed validates")
	check(not model.play_commander().is_empty(), "cannot play unassigned command")
	check(not model.delegate().is_empty(), "cannot delegate unassigned command")
	check(not model.issue("patrol").is_empty(), "must be at table to issue")
	at_site(model, "lahore_darbar")
	check(not model.issue("unlimited").is_empty(), "reject unknown allocation")
	ok(model.issue("patrol"), "reserve patrol")
	check(model.snapshot().resources == {"riders": 2, "supplies": 6, "treasury": 80}, "resources reserved once")
	var first_id: String = model.snapshot().order.id
	var before: Dictionary = model.snapshot()
	check(not model.issue("patrol").is_empty(), "duplicate assignment rejected")
	check(model.snapshot() == before, "duplicate assignment does not mutate")
	ok(model.cancel(), "cancel before departure")
	check(model.snapshot().resources == {"riders": 6, "supplies": 12, "treasury": 100}, "full predeparture refund")
	ok(model.validate(model.snapshot()), "cancelled state validates")
	ok(model.issue("patrol"), "reassign cancelled order")
	check(model.snapshot().order.id != first_id, "new order has new identity")
	ok(model.play_commander(), "take captain control")
	check(not model.cancel().is_empty(), "cannot refund spent budget")
	check(not model.issue("scout").is_empty(), "captain cannot issue Lahore orders")
	check(not model.visit("village").is_empty(), "visit requires proximity")
	at_site(model, "outpost")
	check(not model.visit("outpost").is_empty(), "outpost cannot skip village")
	check(not model.resolve("secure").is_empty(), "cannot secure unobserved road")
	ok(model.validate(model.snapshot()), "active state validates")

func _test_handover_and_reports() -> void:
	var model = assigned()
	var ranjit_position: Vector3 = model.actor_position(Campaign.RANJIT)
	ok(model.play_commander(), "play subordinate")
	at_site(model, "village")
	ok(model.visit("village"), "captain observes village")
	check("village" not in model.snapshot().actors.ranjit_singh.known_places, "no remote knowledge leak")
	var captain_position: Vector3 = model.actor_position(Campaign.CAPTAIN)
	var before: Dictionary = model.snapshot()
	check(not model.visit("village").is_empty(), "duplicate observation rejected")
	check(model.snapshot() == before, "duplicate observation has no effect")
	var order_id: String = model.snapshot().order.id
	ok(model.return_to_darbar(), "hand off existing patrol")
	check(model.actor_position(Campaign.RANJIT) == ranjit_position, "Ranjit position preserved")
	check(model.actor_position(Campaign.CAPTAIN) == captain_position, "captain not teleported home")
	check(model.snapshot().player.known_places == ["lahore_darbar"], "viewpoint has separate knowledge")
	model.advance(1)
	check(model.actor_position(Campaign.CAPTAIN) != captain_position, "delegated captain continues moving")
	ok(model.play_commander(), "reacquire same patrol")
	check(model.snapshot().order.id == order_id, "handover preserves operation identity")
	captain_position = model.actor_position(Campaign.CAPTAIN)
	model.advance(2)
	check(model.actor_position(Campaign.CAPTAIN) == captain_position, "manual captain has no duplicate AI driver")
	at_site(model, "outpost")
	ok(model.visit("outpost"), "observe outpost after handover")
	ok(model.resolve("secure"), "secure road")
	check(model.actor_id() == Campaign.RANJIT, "resolution returns viewpoint")
	check(model.snapshot().order.status == "reporting", "outcome precedes report")
	check(model.received_reports().is_empty(), "no immediate report")
	check(model.snapshot().player.known_places == ["lahore_darbar"], "pending report has not informed Lahore")
	check(model.snapshot().resources.riders == 2, "riders not returned before report")
	ok(model.validate(model.snapshot()), "pending state validates")
	before = model.snapshot()
	check(not model.resolve("secure").is_empty(), "duplicate resolution refused")
	check(model.snapshot() == before, "duplicate resolution has no effects")
	model.advance(Campaign.REPORT_DELAY - 1)
	check(model.received_reports().is_empty(), "report respects delay")
	model.advance(1)
	check(model.received_reports().size() == 1, "one report delivered")
	check(model.snapshot().resources == {"riders": 6, "supplies": 6, "treasury": 80}, "riders returned; supply and coins consumed")
	check("outpost" in model.snapshot().player.known_places, "delivered observation updates Lahore knowledge")
	check(is_equal_approx(model.place("outpost").security, 0.60), "local security improves")
	check(is_equal_approx(model.snapshot().relationships[0].trust, 0.60), "relationship consequence persists")
	ok(model.validate(model.snapshot()), "completed state validates")
	var resources: Dictionary = model.snapshot().resources
	model.advance(100)
	check(model.snapshot().resources == resources, "delivery cannot duplicate riders")
	check(not model.play_commander().is_empty(), "completed story cannot replay rewards")
	check(not model.issue("patrol").is_empty(), "completed story cannot be reassigned")

func _test_delegation() -> void:
	var delegated = assigned()
	ok(delegated.delegate(), "delegate full patrol")
	delegated.advance(100)
	check(delegated.snapshot().order.status == "completed", "delegated route resolves")
	check(delegated.received_reports()[0].outcome == "secure", "funded policy secures road")
	ok(delegated.validate(delegated.snapshot()), "delegated state validates")
	var manual = assigned()
	ok(manual.play_commander(), "manual comparison")
	observe_both(manual)
	ok(manual.resolve("secure"), "manual comparison outcome")
	manual.advance(Campaign.REPORT_DELAY)
	for field in ["resources", "relationships", "places"]:
		check(manual.snapshot()[field] == delegated.snapshot()[field], "manual/delegated consequences match: " + field)
	var scout = assigned("scout")
	ok(scout.play_commander(), "play under-resourced scout")
	observe_both(scout)
	check(not scout.resolve("secure").is_empty(), "insufficient force cannot secure")
	ok(scout.return_to_darbar(), "delegate existing scout")
	scout.advance(100)
	check(scout.received_reports()[0].outcome == "withdraw", "limited policy withdraws")
	check(is_equal_approx(scout.place("outpost").security, 0.25), "withdrawal has persistent consequence")
	ok(scout.validate(scout.snapshot()), "withdrawal validates")
	var early = assigned()
	ok(early.play_commander(), "early retreat setup")
	ok(early.resolve("withdraw"), "early retreat allowed")
	early.advance(Campaign.REPORT_DELAY)
	check(early.received_reports()[0].road_security == null, "unseen outpost not reported as known")
	check(early.snapshot().player.known_places == ["lahore_darbar"], "early retreat invents no observations")
	ok(early.validate(early.snapshot()), "early withdrawal validates")

func _test_persistence() -> void:
	var model = assigned()
	var decoded = JSON.parse_string(JSON.stringify(model.snapshot(), "", true, true))
	ok(model.restore(decoded), "JSON float allocation accepts exact integer quantities")
	check(typeof(model.snapshot().resources.riders) == TYPE_INT, "restored resource counts are canonical integers")
	check(typeof(model.snapshot().order.allocation.riders) == TYPE_INT, "restored allocation counts are canonical integers")
	ok(model.play_commander(), "save active captain")
	model.record_position(Vector3(12.25, 0.2, -20.75))
	ok(model.save_to(SAVE), "write manual save")
	var restored = Campaign.new()
	ok(restored.load_from(SAVE), "load active captain")
	check(model.snapshot() == restored.snapshot(), "complete active snapshot roundtrip")
	ok(model.return_to_darbar(), "delegate after save")
	ok(model.save_to(SAVE), "replace existing save")
	ok(restored.load_from(SAVE), "reload overwritten save")
	model.advance(100)
	restored.advance(100)
	check(model.snapshot() == restored.snapshot(), "deterministic continuation across save/load")
	var pending = assigned()
	ok(pending.play_commander(), "pending save setup")
	observe_both(pending)
	ok(pending.resolve("secure"), "pending outcome")
	ok(pending.save_to(SAVE), "save pending report")
	ok(restored.load_from(SAVE), "load pending report")
	check(restored.received_reports().is_empty(), "load does not prematurely deliver report")
	pending.advance(Campaign.REPORT_DELAY)
	restored.advance(Campaign.REPORT_DELAY)
	check(pending.snapshot() == restored.snapshot(), "pending report delivers identically after load")
	var before: Dictionary = restored.snapshot()
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	check(not restored.load_from(SAVE).is_empty(), "malformed JSON rejected")
	check(restored.snapshot() == before, "malformed file preserves live state")
	file = FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(" ".repeat(Campaign.SAVE_LIMIT + 1))
	file.close()
	check(not restored.load_from(SAVE).is_empty(), "oversize file rejected")
	check(restored.snapshot() == before, "oversize file preserves live state")
	check(not restored.save_to("user://missing-command-test-directory/save.json").is_empty(), "write failure is reported")

func _test_corruption() -> void:
	var model = Campaign.new()
	for value in [null, [], "text", 4, true]:
		reject_restore(model, value, "non-object snapshot")
	for key in model.snapshot():
		var candidate: Dictionary = model.snapshot()
		candidate.erase(key)
		reject_restore(model, candidate, "missing " + key)
	var corruptions := [
		["schema_version", "world-state.v99"], ["command_schema_version", "command-story.v99"],
		["campaign_tick", -1], ["campaign_tick", 0.5], ["campaign_tick", true], ["next_order", 0],
		["reports", ["bad report"]], ["events", ["bad event"]]
	]
	for corruption in corruptions:
		var candidate: Dictionary = model.snapshot()
		candidate[corruption[0]] = corruption[1]
		reject_restore(model, candidate, str(corruption[0]))
	var bad: Dictionary = model.snapshot()
	bad.actors.patrol_captain.position = [1, 2]
	reject_restore(model, bad, "wrong vector length")
	bad = model.snapshot()
	bad.game_time.hour = INF
	reject_restore(model, bad, "nonfinite time")
	bad = model.snapshot()
	bad.resources.riders = 1000
	reject_restore(model, bad, "duplicated resource balance")
	bad = model.snapshot()
	bad.player.character_id = "unknown"
	reject_restore(model, bad, "unknown actor")
	bad = model.snapshot()
	bad.order.mode = "manual"
	reject_restore(model, bad, "unassigned executor")
	bad = model.snapshot()
	bad.game_time.day = 366
	reject_restore(model, bad, "invalid day in nonleap year")
	bad = model.snapshot()
	bad.player.known_places = ["outpost"]
	reject_restore(model, bad, "desynchronized knowledge")
	var allocated = assigned()
	bad = allocated.snapshot()
	bad.order.allocation.riders = 4.5
	reject_restore(allocated, bad, "fractional allocation cannot be coerced")
	bad = allocated.snapshot()
	bad.order.allocation.riders = true
	reject_restore(allocated, bad, "boolean allocation cannot be coerced")
	var before: Dictionary = model.snapshot()
	model.record_position(Vector3(INF, 0, 0))
	check(model.snapshot() == before, "nonfinite physics input ignored")
	bad = model.snapshot()
	bad["future_extension"] = {"preserved": true}
	ok(model.restore(bad), "additive future fields accepted")
	check(model.snapshot().future_extension.preserved, "unknown extension retained")

func _test_scenes() -> void:
	for path in ["res://ui/main_menu.tscn", "res://world/home_territory.tscn", "res://world/command_sandbox.tscn"]:
		var packed = load(path)
		check(packed is PackedScene, "load " + path)
		if not packed is PackedScene:
			continue
		var scene = packed.instantiate()
		root.add_child(scene)
		await process_frame
		await physics_frame
		check(scene.get_child_count() > 0, "scene starts " + path)
		if path.ends_with("command_sandbox.tscn"):
			check(scene.avatar != null, "sandbox spawns avatar")
			var camera: Camera3D = scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
			check(camera.current, "active viewpoint camera")
			var start: Vector3 = scene.avatar.global_position
			Input.action_press("move_forward")
			for _i in range(15):
				await physics_frame
			Input.action_release("move_forward")
			check(scene.avatar.global_position.z < start.z, "real physics movement advances forward")
			scene.avatar.global_position = Vector3(0, 0.2, 2)
			scene._interact()
			check(scene._modal.visible, "courtyard interaction opens command panel")
			scene._perform("issue", "patrol")
			scene._perform("play_commander")
			check(scene.campaign.actor_id() == Campaign.CAPTAIN, "UI action switches authority")
			check(scene.avatar.global_position == scene.campaign.actor_position(Campaign.CAPTAIN), "UI binds captain position")
			scene.avatar.global_position = Vector3(-12, 0.2, -28)
			scene._interact()
			scene.avatar.global_position = Vector3(20, 0.2, -58)
			scene._interact()
			scene._perform("resolve", "secure")
			check(scene.campaign.actor_id() == Campaign.RANJIT, "UI outcome restores Ranjit")
			scene.campaign.advance(Campaign.REPORT_DELAY)
			scene._refresh_hud()
			check("secure" in scene._journal.text, "received report reaches journal")
			ok(scene.campaign.validate(scene.campaign.snapshot()), "interactive loop state validates")
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
