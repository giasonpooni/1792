extends SceneTree
## Focused native regressions for the continuous childhood arc. These start from
## declared lesson/return fixtures; the retained childhood and aftermath suites
## remain responsible for full beginning-to-end input journeys.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Story := preload("res://childhood/aftermath_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const Direction := preload("res://childhood/lesson_direction.gd")
const SAVE := "user://childhood-arc-native-regression.json"
var passed := 0
var failed := 0

func _initialize() -> void: _run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func same_keys(first: Dictionary, second: Dictionary) -> bool:
	if first.size() != second.size(): return false
	for field in first:
		if not second.has(field): return false
	return true

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

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func look(scene, target: Vector3) -> void:
	var offset: Vector3 = target - scene.avatar.global_position
	scene.avatar.pivot.rotation.y = atan2(-offset.x, -offset.z)

func walk(scene, target: Vector3) -> void:
	var reached := false
	for _i in range(1200):
		if Base.distance(scene.avatar.global_position, target) < 0.6:
			reached = true
			break
		look(scene, target)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(5)
	check(reached, "native walk reaches " + str(target))

func press(scene, action: String) -> void:
	for button in scene._actions.get_children():
		for connection in button.pressed.get_connections():
			if action in connection.callable.get_bound_arguments():
				button.pressed.emit()
				await frames(2)
				return
	check(false, "authored action button exists: " + action)

func _lesson_fixture(tracking: bool) -> Dictionary:
	# Admission is explicit and before scene creation, never a claimed playthrough.
	var model := Base.new()
	ok(Fixture.pose(model, Base.SITES.letter + Vector3.RIGHT), "fixture letter contact")
	ok(model.inspect_letter(), "fixture acquired note")
	ok(model.hear("courier"), "fixture heard courier")
	ok(Fixture.pose(model, Base.SITES.steward + Vector3.RIGHT), "fixture steward contact")
	ok(model.hear("steward"), "fixture heard reading")
	var value := model.snapshot()
	value.childhood.walked = 6.0
	value.childhood.looked = 1.0
	value.childhood.ride_gate = 3
	value.childhood.parries = 2 if tracking else 0
	value.childhood.counters = 1 if tracking else 0
	var location: Vector3 = Base.SITES.track_2 + Vector3(0, 0, 2) if tracking else Base.SITES.spar + Vector3(0, 0, 2)
	value.player.position = Base.coords(location)
	value.actors[Base.Names.HERO_ID].position = Base.coords(location)
	ok(model.restore(value), "declared lesson fixture validates")
	return model.snapshot()

func _wait_phase(scene, target: int) -> void:
	for _i in range(155):
		if int(scene.model.progress().tick) % 150 == target: return
		await physics_frame
	check(false, "practice clock reaches phase " + str(target))

func _swing_at(scene, phase: int) -> String:
	await _wait_phase(scene, phase - 1)
	var strike := InputEventMouseButton.new()
	strike.button_index = MOUSE_BUTTON_LEFT
	strike.pressed = true
	scene._unhandled_input(strike)
	await frames(2)
	return scene._message

func _practice() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(_lesson_fixture(false)), "install pre-sparring fixture")
	root.add_child(home)
	await frames(5)
	look(scene, Base.SITES.spar)
	check(scene.model.stage() == "sparring", "fixture begins at physical practice circle")
	var accounts: Array = scene.model.progress().memories.duplicate(true)
	var without_guard := await _swing_at(scene, 132)
	check(scene.model.progress().parries == 0 and scene.model.progress().counters == 0,
		"recovery swing cannot skip two guarded strikes")
	check(not without_guard.is_empty(), "premature counter has trainer feedback")
	key(KEY_Q, true)
	await _wait_phase(scene, 122)
	check(scene.model.progress().parries == 1, "first real guarded strike records one parry")
	await _wait_phase(scene, 130)
	await _wait_phase(scene, 122)
	key(KEY_Q, false)
	check(scene.model.progress().parries == 2, "second real guarded strike enables recovery lesson")
	var early := await _swing_at(scene, 102)
	check(scene.model.progress().counters == 0, "windup swing does not advance lesson")
	check(early.to_lower().contains("early"), "windup swing explains early timing")
	var late := await _swing_at(scene, 25)
	check(scene.model.progress().counters == 0, "reset-phase swing does not advance lesson")
	check(late.to_lower().contains("late") or late.to_lower().contains("closed"), "reset-phase swing explains missed recovery")
	look(scene, scene.avatar.global_position + Vector3(0, 0, 4))
	var turned := await _swing_at(scene, 132)
	check(scene.model.progress().counters == 0, "unfaced recovery swing cannot count as counter")
	check(turned.to_lower().contains("face") or turned.to_lower().contains("turn"), "unfaced swing gives direction")
	look(scene, Base.SITES.spar)
	var correct := await _swing_at(scene, 132)
	check(scene.model.stage() == "tracking" and scene.model.progress().counters == 1,
		"facing recovery counter advances through actual queued mouse input")
	check(correct != early and correct != late, "successful counter has its own transition line")
	check(scene.model.progress().memories == accounts, "practice dialogue does not fabricate testimony")
	ok(scene.model.validate(scene.model.snapshot()), "practice result validates")
	home.queue_free()
	await frames(2)

func _traces() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(_lesson_fixture(true)), "install explicit second-trace approach fixture")
	root.add_child(home)
	await frames(5)
	look(scene, Base.SITES.track_2)
	var before: Array = scene.model.progress().memories.duplicate(true)
	await tap(scene, KEY_E)
	check(scene.model.progress().tracks == 0 and scene.model.progress().memories == before,
		"future trace cannot skip unseen earlier ground")
	check(scene._message.to_lower().contains("first") or scene._message.to_lower().contains("earlier"),
		"future trace gives an explicit route-order refusal")
	var captions: Array[String] = []
	for number in range(1, 4):
		var id := "track_%d" % number
		var at: Vector3 = Base.SITES[id]
		await walk(scene, at + Vector3(0, 0, 2))
		look(scene, at)
		await tap(scene, KEY_E)
		check(scene.model.progress().tracks == number, "physical inspection admits " + id)
		captions.append(scene._message)
		check(scene._message.contains(str(Direction.TRACE_DETAILS[id])), "inspection displays authored ground detail for " + id)
		check(scene.model.progress().memories.back().text == Base.PERSONAL_MEMORIES[id],
			"specific display preserves legacy observation receipt for " + id)
	check(captions[0] != captions[1] and captions[1] != captions[2] and captions[0] != captions[2],
		"three ground observations have distinct scene descriptions")
	var remembered: Array = scene.model.progress().memories.duplicate(true)
	await tap(scene, KEY_E)
	check(scene.model.progress().tracks == 3 and scene.model.progress().memories == remembered,
		"repeated trace inspection cannot duplicate observation")
	await tap(scene, KEY_F5)
	# F5 is processed before the next movement tick. Compare with the actual
	# serialized sample, not a later sample after the player's final deceleration.
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	await walk(scene, Base.SITES.track_3 + Vector3(2, 0, 2))
	await tap(scene, KEY_F9)
	check(scene.model.position().is_equal_approx(Base.point(saved.player.position)),
		"trace save restores admitted location: expected " + str(saved.player.position) + ", got " + str(scene.model.position()) + "; " + scene._message)
	check(scene.model.progress().memories == remembered and scene.model.progress().tracks == 3,
		"trace save retains original receipt format and progress")
	ok(scene.model.validate(scene.model.snapshot()), "tracked scene snapshot validates")
	home.queue_free()
	await frames(2)

func _report_fixture(choice: String) -> Dictionary:
	var model := Story.new()
	ok(model.restore(Fixture.survived()), "declared survived fixture for " + choice)
	for speaker in ["steward", "courier"]:
		ok(Fixture.pose(model, Base.SITES[speaker] + Vector3.RIGHT), "return witness contact fixture")
		ok(model.hear_return(speaker), "fixture hears " + speaker)
	ok(Fixture.pose(model, Story.MOTHER + Vector3(0, 0, -1.8)), "offer contact fixture")
	ok(model.hear_offer(), "fixture hears household offer")
	ok(model.decide_protection(choice), "fixture chooses " + choice)
	ok(Fixture.pose(model, Story.CLUE + Vector3(0, 0, 2)), "clue approach fixture")
	if choice == "household_escort":
		var clue := model.snapshot()
		clue.aftermath.escort.position = Base.coords(Story.CLUE + Vector3.RIGHT * 2)
		ok(model.restore(clue), "fixture guard attends clue")
	ok(model.inspect_bend(), "fixture contains actually admitted bend observation")
	ok(Fixture.pose(model, Story.MOTHER + Vector3(0, 0, -1.8)), "oral return contact fixture")
	if choice == "household_escort":
		var returned := model.snapshot()
		returned.aftermath.escort.position = Base.coords(Story.MOTHER + Vector3.RIGHT * 3)
		ok(model.restore(returned), "fixture guard returns to household")
	return model.snapshot()

func _report(choice: String) -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(_report_fixture(choice)), "install observed return fixture: " + choice)
	root.add_child(home)
	await frames(5)
	look(scene, Story.MOTHER)
	await tap(scene, KEY_E)
	check(scene._paused and scene.model.aftermath_phase() == "return", "physical contact opens uncommitted report")
	check(scene._panel_text.text.contains("Fresh hoof marks"), "report uses the admitted ground observation")
	check(scene._panel_text.text.contains("I saw the man"), "report recalls this fixture's witnessed attacker")
	var paused: Dictionary = scene.model.snapshot()
	await frames(8)
	check(scene.model.snapshot() == paused, "report panel holds clock without granting completion")
	check(scene._inquiry_contact(), "report begins in actual audible and visible contact")
	var midpoint: Vector3 = (scene.avatar.global_position + Story.MOTHER) * 0.5
	var wall = scene._box(Vector3(4, 3, 0.18), midpoint + Vector3.UP * 1.5, Color.GRAY, true).get_parent()
	await frames(3)
	check(not scene._inquiry_contact(), "intervening wall blocks an already opened report")
	await press(scene, "report")
	check(scene.model.snapshot() == paused, "blocked queued report cannot grant completion or new knowledge")
	wall.queue_free()
	await frames(3)
	await press(scene, "resume")
	var before_reopen: Dictionary = scene.model.aftermath()
	scene._menu_action("report")
	await frames(2)
	check(scene.model.aftermath().memories == before_reopen.memories and scene.model.aftermath_phase() == "return",
		"stale report callback cannot complete a closed conversation")
	look(scene, Story.MOTHER)
	await tap(scene, KEY_E)
	await press(scene, "report")
	check(scene.model.aftermath_phase() == "complete", "native report button commits observed oral account")
	var expected := "You brought the guard home with you" if choice == "household_escort" else "You chose to go alone"
	check(scene._message.contains(expected), "Raj Kaur acknowledges the chosen route")
	check(scene.model.aftermath().memories.back().text == Story.AFTER_ACCOUNTS.oral_return.text,
		"route-specific reply retains validated legacy oral receipt")
	var completed: Dictionary = scene.model.aftermath()
	await tap(scene, KEY_E)
	check(scene.model.aftermath() == completed, "repeated household interaction cannot duplicate completed report")
	ok(scene.model.save_to(SAVE), "completed arc report saves")
	var restored = scene.model.get_script().new()
	ok(restored.load_from(SAVE), "completed arc report reloads")
	var reloaded: Dictionary = restored.aftermath()
	var same_receipts := same_keys(reloaded, completed)
	for field in completed:
		if field != "escort" and reloaded.get(field) != completed[field]: same_receipts = false
	check(same_receipts, "presentation variation adds no schema or saved knowledge")
	check(same_keys(reloaded.escort, completed.escort) and reloaded.escort.id == completed.escort.id
		and reloaded.escort.active == completed.escort.active and reloaded.escort.instruction == completed.escort.instruction
		and Base.point(reloaded.escort.position).is_equal_approx(Base.point(completed.escort.position))
		and Base.point(reloaded.escort.velocity).is_equal_approx(Base.point(completed.escort.velocity))
		and is_equal_approx(float(reloaded.escort.yaw), float(completed.escort.yaw)),
		"JSON round trip preserves retired guard state within numeric precision")
	home.queue_free()
	await frames(2)

func _run() -> void:
	await _practice()
	await _traces()
	await _report("household_escort")
	await _report("independent_inquiry")
	for suffix in ["", ".tmp", ".checkpoint.json", ".checkpoint.json.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("CHILDHOOD_ARC_NATIVE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
