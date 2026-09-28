extends SceneTree
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Explicit presentation fixtures. Input-driven journeys remain in the inherited suites.
const Launch:=preload("res://childhood/home_launch.gd")
var captures:=0
var failures:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=6) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func shot(label: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();captures+=1
	if image.is_empty() or image.save_png("user://fabric-"+label+".png")!=OK: failures+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world();root.add_child(home);await frames()
	var scene=home.get_node("ChildhoodChapter")
	scene._paused=true;scene.avatar.set_physics_process(false)
	var camera:=Camera3D.new();home.add_child(camera);camera.current=true
	camera.position=Vector3(-8,2.2,5);camera.look_at(Vector3(0,1.5,12))
	await shot("courtyard")
	camera.position=Vector3(7,1.9,-0.8);camera.look_at(Vector3(10,2.0,-5))
	await shot("stable")
	camera.position=Vector3(-24,2.4,-13.0);camera.look_at(Vector3(-28,1.7,-20))
	await shot("market")
	camera.position=Vector3(19,14,35);camera.look_at(Vector3(0,1,12))
	await shot("overview")
	var event:=InputEventKey.new();event.keycode=KEY_F2;event.pressed=true
	scene._unhandled_input(event)
	root.size=Vector2i(800,600);await shot("notes-800")
	var f:=FileAccess.open("user://gujranwala-fabric-manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(scene.fabric.manifest(),"  ",true,true));f.close()
	home.queue_free();await frames()
	print("GUJRANWALA_FABRIC_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures or captures!=5 else 0)
