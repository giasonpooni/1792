# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Diagnostic art inspection views for Gujranwala. These are not gameplay cameras or historical evidence.
const Launch:=preload("res://childhood/home_launch.gd")
var home: Node3D
var scene: Node3D
var camera: Camera3D
var failures:=0
var records: Array[Dictionary]=[]
const OUTPUT:="user://gujranwala-beauty-images"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool,label: String) -> void:
	if not value:
		failures+=1
		push_error("GUJRANWALA BEAUTY RENDER: "+label)

func frames(n: int=3) -> void:
	for _i in range(n):
		await process_frame
	await RenderingServer.frame_post_draw

func prepare_camera(at: Vector3,target: Vector3,fov: float=48.0) -> void:
	camera.global_position=at
	camera.fov=fov
	camera.look_at(target,Vector3.UP)
	camera.current=true

func capture(id: String,preset: String,at: Vector3,target: Vector3,fov: float=48.0) -> void:
	var before: Dictionary=scene.model.snapshot()
	scene.art.set_enabled(true)
	scene.art.set_refinement(true)
	var error: String=scene.art.set_preset(preset)
	check(error.is_empty(),"preset "+preset+": "+error)
	prepare_camera(at,target,fov)
	if is_instance_valid(scene._hud): scene._hud.hide()
	if is_instance_valid(scene._caption): scene._caption.hide()
	if is_instance_valid(scene._narrator_label): scene._narrator_label.hide()
	if is_instance_valid(scene.art.detail) and is_instance_valid(scene.art.detail.hud): scene.art.detail.hud.hide()
	await frames(4)
	var image:=root.get_texture().get_image()
	var path:=OUTPUT.path_join(id+".png")
	check(not image.is_empty(),"image exists "+id)
	check(image.get_width()==1280 and image.get_height()==720,"expected 1280x720 "+id)
	check(image.save_png(path)==OK,"write "+id)
	check(scene.model.snapshot()==before,"render freezes game state "+id)
	records.append({
		"id":id,
		"preset":preset,
		"file":id+".png",
		"sha256":FileAccess.get_sha256(path),
		"camera_position":[at.x,at.y,at.z],
		"target":[target.x,target.y,target.z],
		"fov":fov,
		"camera_kind":"explicit-art-inspection",
		"gameplay_camera":false
	})

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	home=Launch.make_world()
	root.add_child(home)
	scene=home.get_node("ChildhoodChapter")
	await frames(8)
	# Freeze gameplay scripts; keep the renderer and art presentation alive.
	for node in home.find_children("*","Node",true,false):
		node.set_physics_process(false)
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	camera=Camera3D.new()
	camera.name="GujranwalaArtInspectionCamera"
	camera.far=220.0
	home.add_child(camera)

	await capture("courtyard-daylight","daylight",Vector3(0,4.7,-3.0),Vector3(0,1.65,10.2),52.0)
	await capture("courtyard-golden","golden_hour",Vector3(0,4.7,-3.0),Vector3(0,1.65,10.2),52.0)
	await capture("veranda-close","golden_hour",Vector3(-7.4,2.75,5.2),Vector3(-8.2,1.75,11.1),42.0)
	await capture("market-close","golden_hour",Vector3(-19.7,3.2,-11.8),Vector3(-24.0,1.45,-17.75),45.0)
	await capture("skyline-evening","evening",Vector3(0,5.0,-8.5),Vector3(0,4.2,27.0),54.0)

	check(records.size()==5,"five art-inspection captures")
	if records.size()==5:
		check(records[0].sha256!=records[1].sha256,"daylight and golden-hour frames differ")
		check(records[1].sha256!=records[4].sha256,"golden-hour and evening frames differ")
	var report:={
		"schema":"1792.gujranwala-beauty-render.v1",
		"captures":records,
		"failures":failures,
		"engine":Engine.get_version_info().string,
		"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),
		"historical_authentication":false,
		"human_art_approval":false,
		"inspection_camera_only":true
	}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report,"\t",true,true))
		file.close()
	else:
		failures+=1
	print("GUJRANWALA_BEAUTY_RENDER: %d captures; %d failures"%[records.size(),failures])
	home.queue_free()
	await frames(2)
	quit(1 if failures else 0)
