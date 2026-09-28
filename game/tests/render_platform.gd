# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Deliberately posed UI/render fixtures, not the real-input conformance journey.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
var captures:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	captures+=1
	if image.is_empty() or image.save_png("user://platform-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var menu=load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await capture("title-focus")
	menu.queue_free();await frames()
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	if not scene.model.restore(Fixture.complete()).is_empty(): failed+=1
	root.add_child(home);await frames()
	scene.controls.using_gamepad=true;scene._refresh()
	await capture("home-controller")
	root.size=Vector2i(800,600)
	scene._open_controller_settings()
	await capture("settings-small-window")
	scene.controls.set_focus(false)
	await capture("interrupted-small-window")
	home.queue_free();await frames()
	print("PLATFORM_RENDER: %d captures; %d failures"%[captures,failed])
	quit(1 if failed or captures!=4 else 0)
