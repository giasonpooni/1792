# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Inspection-camera captures, not proof of human playtesting or surveyed geometry.
const Launch := preload("res://childhood/home_launch.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://reconstruction-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	root.add_child(home)
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://reconstruction-render-isolated.json"
	await frames()
	var camera:=Camera3D.new()
	camera.far=300
	home.add_child(camera)
	camera.current=true
	camera.position=Vector3(56,48,64)
	camera.look_at(Vector3(0,0,-2))
	await frames()
	await capture("district")
	camera.position=Vector3(15,6,-3)
	camera.look_at(Vector3(0,2,11.35))
	await frames()
	await capture("veranda")
	camera.position=Vector3(28,4,21)
	camera.look_at(Vector3(24,1,15))
	await frames()
	await capture("well")
	scene._show_dialog("GUJRANWALA — RESEARCH VIEW",scene.fabric.notebook(),[["Return","resume"]])
	await capture("evidence")
	home.queue_free()
	await frames()
	print("RECONSTRUCTION_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=4 else 0)
