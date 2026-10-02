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
func check(condition: bool,label: String) -> void:
	if not condition:
		failed+=1
		push_error("RECONSTRUCTION_RENDER: "+label)
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
	var guidance: Node=scene.art.detail.hud
	check(guidance.visible and not scene._narrator_label.is_visible_in_tree() and not scene._hud.is_visible_in_tree() and not scene._caption.is_visible_in_tree(),"default compact guidance suppresses legacy narration and captions")
	# These retained research-view captures inspect the existing classic narrator
	# layout. Select that supported presentation while execution is parked; this
	# cannot advance the childhood world or grant first-task progress.
	var prior_process: int=home.process_mode
	home.process_mode=Node.PROCESS_MODE_DISABLED
	var parked: Dictionary=scene.model.snapshot()
	var player_pose: Transform3D=scene.avatar.global_transform
	var horse_pose: Transform3D=scene.horse.global_transform
	var guard_pose: Transform3D=scene.escort.global_transform
	guidance.compact=false;guidance.sample();await frames()
	check(not guidance.visible and parked==scene.model.snapshot() and player_pose==scene.avatar.global_transform and horse_pose==scene.horse.global_transform and guard_pose==scene.escort.global_transform,"classic HUD selection preserves whole authority and native body poses")
	home.process_mode=prior_process
	check(scene._narrator_label.visible,"initial narration is visible")
	check(not scene._narrator_label.get_global_rect().intersects(scene._hud.get_global_rect()),"narrator overlaps controls")
	check(not scene._narrator_label.get_global_rect().intersects(scene._caption.get_global_rect()),"narrator overlaps protagonist caption")
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
	check(not scene._narrator_label.visible,"narrator remains behind paused notebook")
	await capture("evidence")
	home.queue_free()
	await frames()
	print("RECONSTRUCTION_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=4 else 0)
