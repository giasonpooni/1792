# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit presentation fixtures, not the controller-only journey.
const Launch := preload("res://childhood/home_launch.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames() -> void:
	for _i in range(4): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://platform-remapping-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	root.add_child(home);await frames()
	var scene=home.get_node("ChildhoodChapter")
	scene.controls.using_gamepad=true
	scene._open_controller_bindings()
	await capture("actions")
	root.size=Vector2i(800,600)
	scene._open_binding_confirmation("interact",JOY_BUTTON_Y)
	await capture("swap-confirmation-small-window")
	scene._open_controller_bindings("Not saved: storage unavailable. Your previous button layout is still active.")
	await capture("save-failure-small-window")
	home.queue_free();await frames()
	print("CONTROLLER_REMAPPING_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=3 else 0)
