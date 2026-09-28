extends SceneTree

const Scene := preload("res://world/house_sandbox.tscn")
var failures := 0
var captures := 0

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://house-" + name + ".png") != OK:
		failures += 1

func require_success(error: String) -> void:
	if not error.is_empty():
		failures += 1
		push_error(error)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	scene.avatar.position = Vector3(0, 0.2, 3)
	scene.campaign.record_position(scene.avatar.position)
	scene._open_houses()
	await capture("codex")
	scene._open_biography("raj_kaur")
	await capture("biography")
	scene._perform("petition", "begin")
	await capture("petition")
	scene._perform("petition", "assert_authority")
	await capture("rival")
	scene._close_panel()
	require_success(scene.campaign.issue("patrol"))
	require_success(scene.campaign.delegate())
	scene.campaign.advance(100)
	scene._refresh_hud()
	await capture("report")
	print("HOUSE_RENDER: %d captures; %d failures" % [captures, failures])
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
