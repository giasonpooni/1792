# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native presentation boundaries, not a claimed full campaign playthrough.
## Starting states and injected caption text are explicit fixtures; subsequent
## pause/save/load input and movement run through the production scene.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const Attention := preload("res://presentation/story_attention.gd")
const SAVE := "user://story-attention-scene-regression.json"
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

func press(scene, action: String) -> void:
	for button in scene._actions.get_children():
		for connection in button.pressed.get_connections():
			if action in connection.callable.get_bound_arguments():
				button.pressed.emit()
				await frames(2)
				return
	check(false, "displayed dialog action exists: " + action)

func look(scene, target: Vector3) -> void:
	var d: Vector3 = target - scene.avatar.global_position
	scene.avatar.pivot.rotation.y = atan2(-d.x, -d.z)

func walk_until_stage(scene, target: Vector3, wanted: String) -> void:
	for _i in range(900):
		if scene.model.stage() == wanted: break
		look(scene, target)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(4)
	check(scene.model.stage() == wanted, "physical travel reaches " + wanted + " boundary")

func presentation_line(scene, line: String) -> void:
	# Explicit presentation fixture, never an admitted report or model mutation.
	scene._message = line
	scene._refresh()

func _quiet_pause_and_load() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	root.add_child(home)
	await frames(5)
	check(scene.model.stage() == "orientation", "fresh production home begins before lessons")
	var opening: String = scene.story_caption()
	check(not opening.is_empty(), "opening scene line reaches the displayed caption")
	var before: Dictionary = scene.model.snapshot()
	var evidence: Array = scene.model.journal().duplicate(true)
	for _i in range(24):
		scene._refresh()
		scene.story_caption()
		scene.story_attention.history()
	check(scene.model.snapshot() == before, "repeated caption and staging samples leave authoritative state unchanged")
	check(scene.model.journal() == evidence, "caption samples add no report or remembered evidence")
	await tap(scene, KEY_J)
	var paused: Dictionary = scene.model.snapshot()
	var held: String = scene.story_caption()
	var history: Array = scene.story_attention.history()
	await frames(30)
	check(scene._paused and scene.model.snapshot() == paused, "journal input freezes world state and the shared clock")
	check(scene.story_caption() == held and scene.story_attention.history() == history,
		"journal pause consumes no caption time or dialogue history")
	check(not scene._panel_text.text.contains("RECENT SCENE DIALOGUE"),
		"journal keeps optional dialogue replay out of its main account text")
	await press(scene, "dialogue")
	check(scene._panel_text.text.contains("RECENT SCENE DIALOGUE") and scene._panel_text.text.contains(opening),
		"displayed journal action opens voluntary scene dialogue replay")
	await frames(20)
	check(scene._paused and scene.model.snapshot() == paused and scene.story_caption() == held,
		"dedicated replay keeps the simulation and current caption paused")
	check(scene.model.journal() == evidence and scene.story_attention.history() == history,
		"replay text remains separate from remembered evidence and adds no dialogue")
	await press(scene, "journal")
	check(scene._panel_text.text.contains("WHAT I HAVE HEARD AND SEEN") and not scene._panel_text.text.contains("RECENT SCENE DIALOGUE"),
		"displayed replay action returns to the normal journal")
	check(scene._paused and scene.model.snapshot() == paused and scene.model.journal() == evidence,
		"returning from replay grants no time, progress or evidence")
	await press(scene, "resume")
	await frames(Attention.reading_ticks(opening) + 8)
	check(scene.story_caption().is_empty(), "caption expires to quiet using the advancing production clock")
	check(not scene._caption.get_parent().visible, "quiet caption removes its empty panel")
	check(scene.story_attention.history().has(opening), "expiration preserves the voluntary dialogue replay")
	check(scene.model.progress().memories == before.childhood.memories, "quiet traversal creates no testimony")
	await tap(scene, KEY_F5)
	check(FileAccess.file_exists(SAVE), "actual manual-save input creates the isolated save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(not saved.has("story_attention") and not saved.has("scene_dialogue") and not saved.childhood.has("captions"),
		"manual save retains no transient caption or replay fields")
	var discarded := "TEST PRESENTATION FIXTURE · This line belongs only to the discarded live session."
	presentation_line(scene, discarded)
	# Clear the current save confirmation through the production queue's timeout.
	await frames(Attention.reading_ticks("Chapter saved.") + 8)
	check(scene.story_attention.history().has(discarded), "later presentation fixture has actually been displayed before load")
	look(scene, scene.avatar.global_position + Vector3.FORWARD * 4)
	Input.action_press("move_forward")
	await frames(20)
	Input.action_release("move_forward")
	await frames(6)
	check(not scene.model.position().is_equal_approx(Base.point(saved.player.position)), "pre-load physical input changes the live pose")
	await tap(scene, KEY_F9)
	check(scene.model.position().is_equal_approx(Base.point(saved.player.position)), "manual-load input restores the admitted saved pose")
	check(scene.model.progress().memories == saved.childhood.memories and scene.model.journal() == evidence,
		"load preserves authoritative accounts without importing scene dialogue")
	check(scene.model.progress().ride_gate == saved.childhood.ride_gate and scene.model.progress().tracks == saved.childhood.tracks,
		"load grants no unplayed lesson progress")
	check(not scene.story_attention.history().has(discarded) and not scene.story_attention.history().has(opening),
		"successful load discards prior transient caption history")
	check(scene.story_attention.pending_count() == 0, "successful load discards pending dialogue")
	check(scene.story_caption().contains("restored") or scene.story_caption().contains("loaded"),
		"fresh load acknowledgment replaces the discarded live caption")
	ok(scene.model.validate(scene.model.snapshot()), "loaded production state validates")
	home.queue_free()
	await frames(3)

func _mount_recall() -> void:
	# Explicit lesson-complete stable fixture. Mount/dismount still use native F.
	var model := Base.new()
	ok(model.restore(Fixture.precursor()), "declared stable lesson fixture validates")
	ok(Fixture.pose(model, Base.point(model.horse_record().position) + Vector3.RIGHT * 1.6),
		"declared fixture stands beside the horse")
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(model.snapshot()), "install stable fixture before scene initialization")
	root.add_child(home)
	await frames(6)
	var recollection := "TEST PRESENTATION FIXTURE · Keep this recent dialogue through mounting."
	presentation_line(scene, recollection)
	var accounts: Array = scene.model.progress().memories.duplicate(true)
	await tap(scene, KEY_F)
	check(scene.model.mounted(), "native mount input admits the nearby horse")
	check(scene.story_attention.history().has(recollection), "admitted mounting preserves this session's dialogue recall")
	await frames(6)
	await tap(scene, KEY_F)
	check(not scene.model.mounted(), "native dismount input returns to clear standing ground")
	check(scene.story_attention.history().has(recollection), "admitted dismounting also preserves dialogue recall")
	check(scene.model.progress().memories == accounts, "mount presentation changes no remembered evidence")
	ok(scene.model.validate(scene.model.snapshot()), "mount and dismount result validates")
	home.queue_free()
	await frames(3)

func _ready_fixture() -> Dictionary:
	# Explicit pre-ambush fixture; the encounter itself is entered by real travel.
	var model := Base.new()
	ok(model.restore(Fixture.precursor()), "declared completed-lessons fixture validates")
	ok(model.observe_quarry(true), "fixture admits the required quiet quarry observation")
	ok(Fixture.pose(model, Base.SITES.bend + Vector3(0, 0, -4.2)), "fixture starts outside ambush activation distance")
	check(model.stage() == "ready", "fixture is ready without an active threat")
	return model.snapshot()

func _danger_and_return() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(_ready_fixture()), "install declared return-path fixture before scene initialization")
	root.add_child(home)
	await frames(5)
	check(scene.model.stage() == "ready", "native scene remains outside encounter trigger")
	# Fixture captions isolate ordering from unrelated courier history and timing.
	scene.story_attention.reset(int(scene.model.progress().tick))
	scene._last_story_message = ""
	var trail := "TEST PRESENTATION FIXTURE · The grass lies flat beside the trail."
	var queued := "TEST PRESENTATION FIXTURE · An older trail reaction waiting to be spoken."
	var before: Dictionary = scene.model.snapshot()
	presentation_line(scene, trail)
	scene.story_attention.offer(queued, int(scene.model.progress().tick), Attention.STORY)
	scene._refresh()
	check(scene.story_caption() == trail and scene.story_attention.pending_count() == 1,
		"declared presentation fixtures leave one current and one pending trail reaction")
	check(scene.model.snapshot() == before, "queuing trail presentation cannot add observations or alter the model")
	await walk_until_stage(scene, Base.SITES.bend, "active")
	check(scene.story_caption().contains("Sudden movement") or scene.story_caption().contains("raised strike"),
		"actual ambush entry immediately displays its actionable danger cue")
	check(scene.story_attention.pending_count() == 0, "ambush entry clears queued trail speech")
	check(not scene.story_attention.history().has(queued), "undelivered trail reaction never becomes heard dialogue")
	check(scene.story_caption() != trail and scene.story_caption() != queued, "urgent cue preempts the previous trail caption")
	await walk_until_stage(scene, Base.SITES.home, "escaped")
	var returned: String = scene.story_caption()
	check(not returned.is_empty() and not returned.contains("Sudden movement") and not returned.contains("raised strike"),
		"actual courtyard return replaces active-threat speech")
	check(not scene.story_attention.history().has(queued), "cleared trail reaction stays discarded after return")
	check(scene.model.aftermath_phase() == "accounts", "cinematic return beat does not skip inquiry witnesses")
	var return_evidence: Array = scene.model.journal().duplicate(true)
	await frames(Attention.reading_ticks(returned) + 5)
	var beat: String = scene.story_caption()
	check(beat.contains("same gate"), "quiet return releases its authored recognition beat after the urgent caption")
	await frames(Attention.reading_ticks(beat) + 5)
	check(scene.story_caption().is_empty(), "return beat ends in quiet instead of repeating the threat")
	check(scene.model.journal() == return_evidence, "return dialogue creates no culprit or extra remembered account")
	ok(scene.model.validate(scene.model.snapshot()), "physically escaped production snapshot validates")
	home.queue_free()
	await frames(3)

func _run() -> void:
	await _quiet_pause_and_load()
	await _mount_recall()
	await _danger_and_return()
	for suffix in ["", ".tmp", ".checkpoint.json", ".checkpoint.json.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("STORY_ATTENTION_SCENE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
