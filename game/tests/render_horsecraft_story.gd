extends SceneTree
## Real input and the gameplay camera. Capture pauses physics, not presentation.
const Lesson := preload("res://mounts/horsecraft_training.tscn")
const State := preload("res://mounts/horsecraft_state.gd")
const OUTPUT := "user://horsecraft-story-images"
var lesson: Node3D
var failures := 0
var captures: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, text: String) -> void:
	if not value:
		failures += 1; push_error("HORSECRAFT STORY RENDER: " + text)

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	lesson._unhandled_input(event)

func capture(id: String, size: Vector2i) -> void:
	lesson.set_physics_process(false)
	var before: Dictionary = lesson.model.snapshot()
	var tick: int = lesson.lesson_tick
	var pose: Transform3D = lesson.left.global_transform
	root.size = size
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == size, "exact native capture size " + id)
	check(image.save_png(OUTPUT.path_join(id + ".png")) == OK, "capture saved " + id)
	check(lesson.model.snapshot() == before and lesson.lesson_tick == tick and lesson.left.global_transform == pose, "capture preserves authority and horse body " + id)
	check(lesson.hud.get_global_rect().end.y < lesson.status.get_global_rect().position.y, "task and caption areas do not overlap " + id)
	captures.append({"id": id, "size": [size.x, size.y], "phase": lesson.lesson_phase,
		"gameplay_camera": true, "native_input": true, "hud": lesson.hud.text, "caption": lesson.status.text})
	lesson.set_physics_process(true)

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO; root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	lesson = Lesson.instantiate(); root.add_child(lesson); current_scene = lesson
	await frames(6)
	await capture("01-one-horse-invitation", Vector2i(1280, 720))
	Input.action_press("move_forward"); await frames(35); key(KEY_SPACE)
	await frames(State.RISE_TICKS + 64)
	check(lesson._has_milestone("single_standing"), "first physical hold earned")
	await capture("02-one-horse-earned-small", Vector2i(800, 450))
	key(KEY_ENTER); await frames(5)
	await frames(35); key(KEY_SPACE); await frames(State.RISE_TICKS + 64)
	check(lesson._has_milestone("paired_standing"), "second physical hold earned")
	await capture("03-pair-earned", Vector2i(1280, 720))
	key(KEY_ENTER); await frames(2)
	for slot in range(4):
		key(KEY_1 + slot)
		var event := InputEventMouseButton.new(); event.pressed = true; event.button_index = MOUSE_BUTTON_LEFT
		lesson._unhandled_input(event)
	Input.action_release("move_forward"); Input.action_press("move_backward"); await frames(45)
	Input.action_release("move_backward"); key(KEY_1); key(KEY_R); await frames(60)
	check(lesson.model.snapshot().reload_slot == 0, "actual first charge active")
	await capture("04-reload-small", Vector2i(800, 450))
	await frames(State.RELOAD_TICKS)
	for slot in range(1, 4): key(KEY_1 + slot); key(KEY_R); await frames(State.RELOAD_TICKS + 1)
	key(KEY_SPACE); await frames(State.RECOVER_TICKS + 5)
	check(lesson.lesson_phase == "complete" and not lesson.completion_receipt().is_empty(), "all exercises produce guarded completion proof")
	await capture("05-safe-return", Vector2i(1280, 720))
	var manifest := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"captures": captures, "failures": failures, "historical_authentication": false, "human_playtest": false}, "\t")); manifest.close()
	current_scene = null; lesson.queue_free(); lesson = null; await frames(3)
	print("HORSECRAFT_STORY_RENDER: %d captures; %d failures" % [captures.size(), failures])
	quit(1 if failures else 0)
