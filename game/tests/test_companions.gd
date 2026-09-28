extends SceneTree
const Houses := preload("res://campaign/house_command_state.gd")
const Legacy := preload("res://campaign/command_state.gd")
const Rules := preload("res://patrol/companion_rules.gd")
const Scene := preload("res://world/house_sandbox.tscn")
const SAVE := "user://companions-regression-only.json"
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

func reject(model, action: Callable, message: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), message + " refused")
	check(model.snapshot() == before, message + " leaves state unchanged")

func fresh(package: String = "patrol", decision: String = "respect_claim"):
	var model = Houses.new()
	model.enable_riding()
	model.record_position(Rules.HOME)
	ok(model.petition("begin"), "hear petition")
	ok(model.petition(decision), "commission")
	ok(model.issue(package), "assign original resource package")
	ok(model.muster_patrol(), "muster allocated troopers")
	return model

func fixture_at_outpost(model, with_companions: bool = true) -> void:
	# Domain-only fixture. The separate route test below uses engine inputs/physics.
	model.record_position(Vector3(-12, 0.04, -28))
	ok(model.visit("village"), "observe village")
	model.record_position(Vector3(20, 0.04, -58))
	ok(model.visit("outpost"), "observe outpost")
	if with_companions:
		var candidate: Dictionary = model.snapshot()
		for i in range(candidate.companions.members.size()):
			var at: Vector3 = Vector3(20, 0.04, -58) + Rules.OFFSETS[i]
			candidate.companions.members[i].position = [at.x, at.y, at.z]
		ok(model.restore(candidate), "outpost troop fixture")

func fixture_home(model) -> void:
	var candidate: Dictionary = model.snapshot()
	candidate.actors.patrol_captain.position = [0.0, 0.04, 3.0]
	if candidate.player.character_id == "patrol_captain":
		candidate.player.position = candidate.actors.patrol_captain.position.duplicate()
	for i in range(candidate.companions.members.size()):
		var p: Vector3 = Rules.HOME + Rules.OFFSETS[i]
		candidate.companions.members[i].position = [p.x, p.y, p.z]
	ok(model.restore(candidate), "home troop fixture")

func _run() -> void:
	print("companion domain checks")
	_test_rules()
	_test_return()
	_test_saves()
	print("companion delegated journey")
	await _test_delegated_journey()
	print("companion manual journey")
	await _test_manual_and_geometry()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("COMPANION_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_rules() -> void:
	var model = Houses.new()
	check(not model.has_companions(), "legacy worlds do not silently acquire soldiers")
	reject(model, model.muster_patrol, "muster without allocation")
	model = fresh("scout")
	check(model.companion_state().members.size() == 1, "two-person scout includes captain plus one")
	check(model.snapshot().resources.riders == 4, "muster spends no second rider pool")
	var query: Dictionary = model.companion_state()
	query.members.clear()
	check(model.companion_state().members.size() == 1, "read projection detached from authority")
	reject(model, model.muster_patrol, "duplicate muster")
	reject(model, model.command_companions.bind("hold"), "Ranjit cannot remotely issue field orders")
	var old_id: String = model.companion_state().order_id
	ok(model.cancel(), "cancel mustered but unstarted command")
	check(not model.has_companions() and model.snapshot().resources.riders == 6, "cancellation removes squad and refunds once")
	ok(model.issue("patrol"), "new allocation after cancellation")
	ok(model.muster_patrol(), "new squad belongs to new order")
	check(model.companion_state().order_id != old_id and model.companion_state().members.size() == 3, "new identity and exact patrol count")
	ok(model.play_commander(), "captain takes physical command")
	check(model.companion_state().phase == "outbound", "deployment begins on handover")
	ok(model.command_companions("hold"), "hold acknowledged")
	reject(model, model.command_companions.bind("hold"), "duplicate hold does not spam events")
	model.record_position(Vector3(45, 0.04, -70))
	reject(model, model.command_companions.bind("follow"), "out of range regroup")
	model.record_position(Vector3(8, 0.04, -8))
	ok(model.command_companions("follow"), "return within calling range and regroup")
	var member: Dictionary = model.companion_state().members[0]
	var motion: Dictionary = member.duplicate(true)
	motion.position[2] -= 0.1
	ok(model.record_patrol_motion(member.id, motion, 0.1), "bounded physical motion")
	for delta in [0.0, -0.1, 0.5, NAN]:
		reject(model, model.record_patrol_motion.bind(member.id, motion, delta), "invalid physical delta")
	motion.position[0] = 50
	reject(model, model.record_patrol_motion.bind(member.id, motion, 0.1), "teleport catch-up")
	motion = member.duplicate(true)
	motion.velocity[0] = true
	reject(model, model.record_patrol_motion.bind(member.id, motion, 0.1), "boolean velocity")
	motion = member.duplicate(true)
	motion.id = "patrol_captain"
	reject(model, model.record_patrol_motion.bind("patrol_captain", motion, 0.1), "manual captain has no delegated executor")
	fixture_at_outpost(model, false)
	reject(model, model.resolve.bind("secure"), "remote soldiers cannot secure an outpost")
	ok(model.validate(model.snapshot()), "live outbound record valid")

func _test_return() -> void:
	var model = fresh("patrol", "defer")
	ok(model.play_commander(), "deferred captain")
	fixture_at_outpost(model)
	reject(model, model.resolve.bind("secure"), "companions cannot bypass political commission")
	ok(model.return_to_darbar(), "handover keeps deployed companions")
	var before: Dictionary = model.companion_state()
	model.advance(5)
	check(model.companion_state() == before, "domain clock without physical adapter cannot move or auto-complete squad")
	ok(model.petition("reconcile"), "revise observation-only commission")
	ok(model.play_commander(), "take same deployed captain")
	ok(model.resolve("secure"), "choose outcome once assembled")
	check(model.actor_id() == "patrol_captain", "field decision retains embodied captain")
	check(model.snapshot().reports.is_empty() and model.snapshot().resources.riders == 2, "no report or refund before physical return")
	reject(model, model.resolve.bind("secure"), "duplicate field outcome")
	reject(model, model.finish_patrol, "remote check-in")
	reject(model, model.visit.bind("village"), "no rewritten observations after commitment")
	ok(model.return_to_darbar(), "delegate physical return")
	reject(model, model.petition.bind("assert_authority"), "cannot rewrite committed field terms")
	fixture_home(model)
	ok(model.finish_patrol(), "check in assembled squad")
	check(model.snapshot().resources.riders == 2, "riders still reserved during report transit")
	check(model.received_house_report().is_empty(), "political report delayed")
	model.advance(4)
	check(model.snapshot().resources.riders == 6, "return and delivery release riders once")
	check(model.received_house_report().territory.passage == "permitted", "joint-patrol political consequence retained")
	check(not model.received_house_report().territory.annexed, "no annexation by muster or return")
	reject(model, model.finish_patrol, "duplicate check-in")
	model.advance(30)
	check(model.snapshot().resources.riders == 6, "time cannot duplicate returns")
	ok(model.validate(model.snapshot()), "complete physical patrol valid")
	var scout = fresh("scout")
	ok(scout.play_commander(), "scout control")
	ok(scout.resolve("withdraw"), "withdraw without observing anything")
	fixture_home(scout)
	ok(scout.finish_patrol(), "scout checks in")
	scout.advance(4)
	check(scout.received_house_report().territory == null and scout.received_reports()[0].road_security == null, "return cannot invent outpost information")
	ok(scout.validate(scout.snapshot()), "unobserved returned scout valid")

func _test_saves() -> void:
	var model = fresh()
	ok(model.play_commander(), "saved captain")
	ok(model.command_companions("hold"), "save hold order")
	ok(model.save_to(SAVE), "save physical patrol")
	var loaded = Houses.new()
	loaded.enable_riding()
	ok(loaded.load_from(SAVE), "restore physical patrol")
	check(same_snapshot(loaded.snapshot(), model.snapshot()), "all identities, positions, held orders and budgets roundtrip")
	for key in ["schema_version", "order_id", "phase", "instruction", "members", "pending_outcome", "decision_tick", "return_tick"]:
		var bad: Dictionary = model.snapshot()
		bad.companions.erase(key)
		reject(model, model.restore.bind(bad), "missing companion " + key)
	for value in [null, [], 1, "forged"]:
		var bad: Dictionary = model.snapshot()
		bad.companions = value
		reject(model, model.restore.bind(bad), "invalid companion record type")
	for pair in [["id", "clone"], ["position", [true, 0, 0]], ["position", [0, 0]], ["position", [1000, 0, 0]], ["velocity", [NAN, 0, 0]], ["velocity", [40, 0, 0]], ["yaw", true], ["yaw", INF]]:
		var bad: Dictionary = model.snapshot()
		bad.companions.members[0][pair[0]] = pair[1]
		reject(model, model.restore.bind(bad), "invalid member " + pair[0])
	for pair in [["order_id", "other"], ["phase", "completed"], ["instruction", "attack_faith"], ["decision_tick", true], ["decision_tick", 0.5], ["pending_outcome", "secure"]]:
		var bad: Dictionary = model.snapshot()
		bad.companions[pair[0]] = pair[1]
		reject(model, model.restore.bind(bad), "invalid squad " + pair[0])
	var bad: Dictionary = model.snapshot()
	bad.companions.members.append(bad.companions.members[0].duplicate(true))
	reject(model, model.restore.bind(bad), "unallocated duplicate trooper")
	ok(model.command_companions("follow"), "recall before returning")
	fixture_at_outpost(model)
	ok(model.resolve("secure"), "commit saved returning state")
	ok(model.save_to(SAVE), "save return in progress")
	ok(loaded.load_from(SAVE), "load returning state")
	check(same_snapshot(model.snapshot(), loaded.snapshot()), "pending outcome and return progress preserved")
	fixture_home(model)
	ok(model.finish_patrol(), "report fixture")
	ok(model.save_to(SAVE), "save report in transit")
	ok(loaded.load_from(SAVE), "load report in transit")
	model.advance(4)
	loaded.advance(4)
	check(same_snapshot(model.snapshot(), loaded.snapshot()), "same delayed report after load")
	bad = model.snapshot()
	bad.companions.members[0].position = [50.0, 0.04, -50.0]
	reject(model, model.restore.bind(bad), "claimed return with trooper still away")
	ok(loaded.restore(Legacy.new().snapshot()), "legacy command import")
	check(not loaded.has_companions(), "legacy import invents no deployed soldiers")
	var riding = Houses.new()
	riding.enable_riding()
	ok(loaded.restore(riding.snapshot()), "earlier riding import")
	check(loaded.snapshot() == riding.snapshot(), "earlier riding state stays exact")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func new_scene():
	var scene = Scene.instantiate()
	scene.riding_save_path = SAVE
	root.add_child(scene)
	await frames(4)
	scene.avatar.position = Rules.HOME
	await frames(2)
	scene._perform("petition", "begin")
	scene._perform("petition", "respect_claim")
	scene._perform("issue", "patrol")
	scene._perform("muster")
	await frames(3)
	check(scene.campaign.has_companions(), "UI muster reaches authority in physics time")
	check(scene.patrol.members.size() == 3, "allocated troopers visibly instantiated")
	check(scene.patrol.members.values()[0].caption.fixed_size, "trooper labels cannot grow across the screen near the camera")
	check(not scene._horse_label.visible, "horse billboard cannot overlap the companion HUD")
	check(scene.riding_save_path != scene.COMPANION_SAVE, "tests cannot overwrite player progress")
	return scene

func _test_delegated_journey() -> void:
	var scene = await new_scene()
	scene._perform("delegate")
	var observed_village := false
	var observed_outpost := false
	var saw_return := false
	var exceeded_step := false
	var positions: Dictionary = {}
	var finished := false
	# No position injection after departure. All agents move using CharacterBody3D.
	for _i in range(4200):
		var s: Dictionary = scene.campaign.snapshot()
		observed_village = observed_village or "village" in s.order.visited
		observed_outpost = observed_outpost or "outpost" in s.order.visited
		saw_return = saw_return or s.companions.phase == "returning"
		for record in s.companions.members:
			var p := Rules.point(record.position)
			if positions.has(record.id) and Rules.horizontal(p, positions[record.id]) > 0.15:
				exceeded_step = true
			positions[record.id] = p
		if s.order.status == "completed":
			finished = true
			break
		await physics_frame
	check(observed_village and observed_outpost and saw_return, "delegation visits both sites and physically returns")
	check(finished, "full physical delegated journey completes: " + str(scene.campaign.companion_state()) + " captain=" + str(scene.campaign.actor_position("patrol_captain")) + " notice=" + scene._notice)
	check(not exceeded_step, "no troop teleports during delegated round trip")
	check(scene.campaign.snapshot().resources.riders == 6, "journey reconciles original rider budget")
	ok(scene.campaign.validate(scene.campaign.snapshot()), "engine journey state valid")
	check(scene.campaign.actor_id() == "ranjit_singh", "delegation never steals player's viewpoint")
	scene.queue_free()
	await process_frame

func walk_to(scene, target: Vector3) -> void:
	var reached := false
	for _i in range(1200):
		var d: Vector3 = target - scene.avatar.position
		d.y = 0
		if d.length() < 0.7:
			reached = true
			break
		scene.avatar.pivot.rotation.y = atan2(-d.x, -d.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(8)
	check(reached, "input-driven captain walk reaches " + str(target))
	print("walk complete ", target, " t=", Time.get_ticks_msec())

func _test_manual_and_geometry() -> void:
	var scene = await new_scene()
	scene._perform("play_commander")
	await frames(8)
	await walk_to(scene, Vector3(6.2, 0.04, -5))
	var event := InputEventKey.new()
	event.keycode = KEY_F
	event.pressed = true
	scene._unhandled_input(event)
	await frames(2)
	check(scene.campaign.is_mounted(), "captain mounts shared horse with companions deployed")
	Input.action_press("move_forward")
	await frames(35)
	Input.action_release("move_forward")
	await frames(40)
	scene._unhandled_input(event)
	await frames(3)
	check(not scene.campaign.is_mounted(), "mounted patrol captain dismounts without duplicating control")
	check(scene.patrol.members.size() == 3, "mount handover retains allocated soldiers")
	ok(scene.campaign.command_companions("hold"), "manual hold")
	await frames(4)
	var held: Array = scene.campaign.companion_state().members
	await walk_to(scene, Vector3(0, 0.04, -10))
	for i in range(held.size()):
		check(Rules.horizontal(Rules.point(held[i].position), Rules.point(scene.campaign.companion_state().members[i].position)) < 0.03, "held trooper stays put")
	ok(scene.campaign.command_companions("follow"), "manual regroup")
	await walk_to(scene, Vector3(-12, 0.04, -28))
	scene._interact()
	await frames(180)
	check(scene.campaign.assembled_at(Vector3(-12, 0.04, -28)) == 3, "manual companions navigate to village")
	scene._open_patrol()
	var paused: Dictionary = scene.campaign.snapshot()
	await frames(25)
	check(scene.campaign.snapshot() == paused, "patrol menu pauses both clock and physical troop movement")
	scene._close_panel()
	# Save on hold; reload must retain order and position, with no duplicate bodies.
	ok(scene.campaign.command_companions("hold"), "hold for save")
	await frames(4)
	scene._perform("save")
	var saved: Dictionary = scene.campaign.snapshot()
	ok(scene.campaign.command_companions("follow"), "change live instruction")
	scene._perform("load")
	await frames(1)
	check(same_snapshot(scene.campaign.companion_state(), saved.companions), "staged scene load restores held group")
	check(scene.patrol.members.size() == 3, "loading cannot clone soldiers")
	# Well-shaped but spatially impossible troop pose must not partially install.
	var bad: Dictionary = saved.duplicate(true)
	bad.companions.members[0].position = [0.0, 0.04, 0.0]
	ok(scene.campaign.validate(bad), "impossible placement is domain-valid before spatial audit")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(bad, "", true, true))
	file.close()
	var before: Dictionary = scene.campaign.snapshot()
	scene._perform("load")
	await frames(1)
	check(scene.campaign.snapshot() == before, "blocked loaded troop leaves whole live state unchanged")
	check(scene._notice.contains("companion"), "blocked load reports the relevant cause")
	# Static-obstacle avoidance and no-path stopping, independent of the route fixture.
	var nav = scene.patrol.navigator
	var wall = scene._box(Vector3(12, 3, 0.35), Vector3(35, 1.5, -35), Color.GRAY, true)
	await frames(2)
	print("rebuilding navigation t=", Time.get_ticks_msec())
	nav.rebuild()
	print("navigation rebuilt t=", Time.get_ticks_msec())
	check(not nav.clear_segment(Vector3(35, 0.04, -30), Vector3(35, 0.04, -40)), "navigation sees new test wall")
	var at := Vector3(35, 0.04, -30)
	print("test detour t=", Time.get_ticks_msec())
	var waypoint: Vector3 = nav.waypoint(at, Vector3(35, 0.04, -40))
	print("detour computed t=", Time.get_ticks_msec())
	check(waypoint != at and absf(waypoint.x - 35) > 0.2, "A star chooses a detour rather than tunneling")
	wall.queue_free()
	await frames(2)
	ok(scene.campaign.command_companions("follow"), "regroup for last leg")
	await walk_to(scene, Vector3(20, 0.04, -58))
	scene._interact()
	scene._close_panel()
	await frames(240)
	check(scene.campaign.assembled_at(Vector3(20, 0.04, -58)) == 3, "all manual companions arrive at outpost")
	scene._perform("resolve", "secure")
	check(scene.campaign.actor_id() == "patrol_captain", "manual return does not teleport viewpoint")
	await walk_to(scene, Vector3(-12, 0.04, -28))
	await walk_to(scene, Vector3(0, 0.04, -10))
	await walk_to(scene, Vector3(4, 0.04, -3))
	await walk_to(scene, Vector3(4, 0.04, 3))
	await walk_to(scene, Rules.HOME)
	await frames(220)
	scene._perform("finish_patrol")
	await frames(140)
	check(scene.campaign.snapshot().order.status == "completed", "manual input-driven patrol completes with physical return")
	check(scene.campaign.snapshot().resources.riders == 6, "manual return refunds only original allocation")
	ok(scene.campaign.validate(scene.campaign.snapshot()), "manual end state valid")
	await _test_blocked_physics(scene)
	scene.queue_free()
	await process_frame

func same_snapshot(a: Variant, b: Variant) -> bool:
	# JSON conversion may differ by a double-precision ULP; discrete data is exact.
	if typeof(a) != typeof(b):
		return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same_snapshot(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not same_snapshot(a[i], b[i]): return false
		return true
	if typeof(a) == TYPE_FLOAT:
		return is_finite(a) and is_finite(b) and absf(a - b) <= 1e-12
	return a == b

func _test_blocked_physics(scene) -> void:
	var body = scene.patrol._agent("collision_fixture")
	body.position = Vector3(35, 0.04, -20)
	var wall = scene._box(Vector3(8, 3, 0.3), Vector3(35, 1.5, -25), Color.GRAY, true)
	await frames(3)
	for _i in range(100):
		body.step(1.0 / 60.0, Vector3(35, 0.04, -35), true)
		await physics_frame
	check(body.position.z > -24.6 and body.position.z < -24.3, "real trooper capsule stops at a wall under movement input")
	wall.queue_free()
	body.position = Vector3(35, 0.04, -20)
	body.velocity = Vector3.ZERO
	var ring: Array[Node3D] = []
	for x in [-1.2, 1.2]:
		ring.append(scene._box(Vector3(0.25, 3, 3), Vector3(35 + x, 1.5, -20), Color.GRAY, true))
	for z in [-1.2, 1.2]:
		ring.append(scene._box(Vector3(3, 3, 0.25), Vector3(35, 1.5, -20 + z), Color.GRAY, true))
	await frames(3)
	scene.patrol.navigator.rebuild()
	var next: Vector3 = scene.patrol.navigator.waypoint(body.position, Vector3(45, 0.04, -30))
	check(next == body.position, "unreachable route stops instead of warping to a free grid cell")
	for _i in range(20):
		body.step(1.0 / 60.0, next, false)
		await physics_frame
	check(Rules.horizontal(body.position, Vector3(35, 0.04, -20)) < 0.01, "blocked trooper remains in physical enclosure")
	for part in ring: part.queue_free()
	body.queue_free()
	await frames(2)
