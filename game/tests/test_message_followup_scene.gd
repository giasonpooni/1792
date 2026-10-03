extends SceneTree
## The optional message errand through the production Home and real player motion.
## The direct-route fixture is declared separately; the main journey never injects poses.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const SAVE := "user://message-followup-scene-regression.json"
var passed := 0
var failed := 0
var offered_fixture: Dictionary

func _initialize() -> void: _run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func tap(scene, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	scene._unhandled_input(event)
	await frames(2)

func press(scene, action: String) -> bool:
	# Use the actual authored button; labels can improve without changing action identity.
	for button in scene._actions.get_children():
		for connection in button.pressed.get_connections():
			var bound: Array = connection.callable.get_bound_arguments()
			if action in bound:
				button.pressed.emit()
				await frames(2)
				return true
	check(false, "dialog button exists: " + action)
	return false

func look(scene, target: Vector3) -> void:
	var d: Vector3 = target - scene.avatar.global_position
	scene.avatar.pivot.rotation.y = atan2(-d.x, -d.z)

func walk(scene, target: Vector3) -> void:
	var reached := false
	for _i in range(1500):
		if Base.distance(scene.avatar.global_position, target) < 0.6:
			reached = true
			break
		look(scene, target)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(8)
	check(reached, "physical walk reaches " + str(target))

func receipt(scene) -> Dictionary:
	return scene.model.snapshot().get("opening_message", {}).duplicate(true)

func _clarify_journey() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	root.add_child(home)
	await frames(5)
	check(scene.model.stage() == "orientation", "production construction starts before lessons")
	# Actual mouse observation and admitted keyboard motion satisfy the yard lesson.
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(130, 0)
	for _i in range(3):
		scene.avatar._unhandled_input(motion)
		scene._unhandled_input(motion)
	await walk(scene, Vector3(0, 0, -7))
	await walk(scene, Vector3(-2.5, 0, 3))
	look(scene, Base.SITES.courier)
	await tap(scene, KEY_E)
	await tap(scene, KEY_E)
	check(scene.model.progress().letter_seen and scene.model.progress().heard == ["courier"], "letter collected and courier heard in person")
	await walk(scene, Vector3(-2, 0, 0))
	await walk(scene, Vector3(-10, 0, 0))
	await walk(scene, Vector3(-10.5, 0, 5))
	look(scene, Base.SITES.steward)
	await tap(scene, KEY_E)
	check(scene.model.stage() == "riding", "optional errand preserves original lesson progression")
	var original_accounts: Array = scene.model.progress().memories.duplicate(true)
	offered_fixture = scene.model.snapshot()
	await tap(scene, KEY_E)
	check(scene._paused and scene._panel_text.text.contains("THE WORDS BETWEEN US"), "steward opens the optional authored choice")
	var paused: Dictionary = scene.model.snapshot()
	var paused_accounts: Array = scene.model.journal()
	await frames(12)
	check(scene.model.snapshot() == paused, "choice holds world clock and player state")
	check(scene._message_contact("steward"), "steward is in actual speaking contact")
	# The menu is not permission to speak through a newly obstructed world.
	var at: Vector3 = (scene.avatar.global_position + Base.SITES.steward) * 0.5
	var wall = scene._box(Vector3(0.18, 3, 4), at + Vector3.UP * 1.5, Color.GRAY, true).get_parent()
	await frames(3)
	check(not scene._message_contact("steward"), "new wall blocks the already opened conversation")
	await press(scene, "message:clarify")
	check(receipt(scene) == paused.get("opening_message", {}) and scene.model.journal() == paused_accounts,
		"queued choice rechecks contact without adding a decision or knowledge")
	wall.queue_free()
	await frames(3)
	if scene._paused: await press(scene, "resume")
	look(scene, Base.SITES.steward)
	await tap(scene, KEY_E)
	await press(scene, "message:clarify")
	check(not receipt(scene).is_empty(), "choice creates a persistent message receipt")
	check(scene.model.message_phase() == "clarify", "questioning route requires courier contact")
	check(scene.model.stage() == "riding", "optional choice does not relock riding")
	await walk(scene, Vector3(-10, 0, 0))
	await walk(scene, Vector3(-2, 0, 0))
	await walk(scene, Vector3(-2.5, 0, 3))
	look(scene, Base.SITES.courier)
	await tap(scene, KEY_E)
	await press(scene, "message:confirm")
	check(scene.model.message_phase() == "report", "courier clarification opens an oral return task")
	await tap(scene, KEY_F5)
	var saved: Dictionary = scene.model.snapshot()
	await walk(scene, Vector3(-2, 0, 0))
	await tap(scene, KEY_F9)
	check(scene.model.position().is_equal_approx(Base.point(saved.player.position)), "scene load restores physical return position")
	check(receipt(scene) == saved.opening_message, "scene load retains chosen route and attributed clarification")
	await walk(scene, Vector3(-2, 0, 0))
	await walk(scene, Vector3(-10, 0, 0))
	await walk(scene, Vector3(-14, 0, -3))
	look(scene, Base.SITES.spar)
	await tap(scene, KEY_E)
	await press(scene, "message:report")
	check(scene.model.message_phase() == "complete", "physical trainer report completes the chosen route")
	check(scene.model.progress().memories == original_accounts, "follow-up does not rewrite the original accounts")
	check(scene.model.stage() == "riding" and scene.model.progress().ride_gate == 0, "report grants no unplayed riding or combat progress")
	ok(scene.model.validate(scene.model.snapshot()), "complete production snapshot validates")
	var finished := receipt(scene)
	ok(scene.model.save_to(SAVE), "completed route saves")
	var reloaded = scene.model.get_script().new()
	ok(reloaded.load_from(SAVE), "completed route reloads through production authority")
	check(reloaded.snapshot().opening_message == finished, "local consequence survives a fresh authority")
	await tap(scene, KEY_E)
	check(receipt(scene) == finished, "repeat interaction cannot duplicate the completed report")
	home.queue_free()
	await frames(2)

func _direct_fixture() -> void:
	if offered_fixture.is_empty(): return
	# Explicit pre-choice fixture, before the scene is added. All subsequent travel is physical.
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(offered_fixture), "install separately declared pre-choice fixture")
	root.add_child(home)
	await frames(5)
	look(scene, Base.SITES.steward)
	await tap(scene, KEY_E)
	await press(scene, "message:direct")
	check(scene.model.message_phase() == "report", "direct branch permits report without inventing clarification")
	await walk(scene, Vector3(-10, 0, 0))
	await walk(scene, Vector3(-14, 0, -3))
	look(scene, Base.SITES.spar)
	await tap(scene, KEY_E)
	await press(scene, "message:report")
	check(scene.model.message_phase() == "complete", "direct branch also closes through the trainer")
	ok(scene.model.validate(scene.model.snapshot()), "direct production snapshot validates")
	home.queue_free()
	await frames(2)

func _run() -> void:
	await _clarify_journey()
	await _direct_fixture()
	for suffix in ["", ".tmp", ".checkpoint.json", ".checkpoint.json.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("MESSAGE_FOLLOWUP_SCENE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
