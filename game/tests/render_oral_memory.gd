# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit presentation fixtures, separate from the real-input journey in test_oral_memory.gd.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://oral-memory-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://oral-memory-render-only.json"
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home);await frames()
	scene._open_quartermaster();await capture("household-invitation")
	scene._resume()
	ok(scene.model.oral_operation("hear","quartermaster_account"))
	ok(Pose.pose(scene.model,Memory.SITES.market+Vector3(0,0,1)))
	ok(scene.model.oral_operation("hear","trader_account"))
	scene._apply();scene._open_oral_memory()
	await capture("differing-accounts")
	scene._resume()
	ok(Pose.pose(scene.model,Memory.SITES.trace+Vector3(0,0,2)))
	ok(scene.model.oral_operation("observe","rope_trace"))
	ok(scene.model.oral_operation("compare","borrowed_rope"))
	scene._apply()
	var camera:=Camera3D.new();home.add_child(camera)
	camera.position=Vector3(18,4,-1)
	camera.look_at(Memory.SITES.trace+Vector3.UP*0.6);camera.current=true
	await frames();await capture("physical-trace")
	ok(Pose.pose(scene.model,Memory.SITES.listener+Vector3(2,0,-1)))
	ok(scene.model.oral_operation("retell","comparison"))
	scene._apply()
	root.size=Vector2i(800,600)
	scene._open_listener();await frames();await capture("listener-small-window")
	home.queue_free();await frames()
	print("ORAL_MEMORY_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=4 else 0)
