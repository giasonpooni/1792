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
const COURTYARD_POSITION:=Vector3(0,4.7,-3.0)
const COURTYARD_TARGET:=Vector3(0,1.65,10.2)
const COURTYARD_FOV:=52.0

func bytes_sha256(data: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()

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
	if not scene.art.enabled: scene.art.set_enabled(true)
	if not scene.art.refinement_enabled: scene.art.set_refinement(true)
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
	# A canonical decoded-pixel digest distinguishes light changes from PNG metadata.
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	check(image.save_png(path)==OK,"write "+id)
	check(scene.model.snapshot()==before,"render freezes game state "+id)
	records.append({
		"id":id,
		"preset":preset,
		"file":id+".png",
		"sha256":FileAccess.get_sha256(path),
		"pixel_sha256":bytes_sha256(image.get_data()),
		"pixel_format":"rgba8",
		"width":image.get_width(),
		"height":image.get_height(),
		"tick":int(scene.model.progress().tick),
		"campaign_snapshot_sha256":bytes_sha256(JSON.stringify(before,"",true,true).to_utf8_buffer()),
		"frozen_state":scene.model.snapshot()==before,
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
		node.set_process(false)
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	camera=Camera3D.new()
	camera.name="GujranwalaArtInspectionCamera"
	camera.far=220.0
	home.add_child(camera)

	await capture("courtyard-daylight","daylight",COURTYARD_POSITION,COURTYARD_TARGET,COURTYARD_FOV)
	await capture("courtyard-golden","golden_hour",COURTYARD_POSITION,COURTYARD_TARGET,COURTYARD_FOV)
	await capture("veranda-close","golden_hour",Vector3(-7.4,2.75,5.2),Vector3(-8.2,1.75,11.1),42.0)
	# Approach the counter directly; the former east approach inspected the store wall.
	await capture("market-close","golden_hour",Vector3(-24.0,2.2,-14.5),Vector3(-24.0,1.25,-17.8),58.0)
	await capture("skyline-evening","evening",Vector3(0,5.0,-8.5),Vector3(0,4.2,27.0),54.0)
	await capture("courtyard-evening","evening",COURTYARD_POSITION,COURTYARD_TARGET,COURTYARD_FOV)

	check(records.size()==6,"six art-inspection captures")
	if records.size()==6:
		var lighting: Array[Dictionary]=[records[0],records[1],records[5]]
		for i in range(lighting.size()):
			for j in range(i):
				check(lighting[i].pixel_sha256!=lighting[j].pixel_sha256,"same-camera lighting pixels differ: "+lighting[i].id+" / "+lighting[j].id)
	var report:={
		"schema":"1792.gujranwala-beauty-render.v2",
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
	home=null
	scene=null
	camera=null
	await frames(8)
	quit(1 if failures else 0)
