# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Study:=preload("res://presentation/equipment_study.tscn")
const Launch:=preload("res://childhood/home_launch.gd")
var output: String
var records: Array[Dictionary]=[]
var failures:=0

func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for _i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func capture(id: String, camera_kind: String) -> void:
	await frames()
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty() or image.get_size()!=Vector2i(1280,720):
		failures+=1
		return
	var path:=output.path_join(id+".png")
	if image.save_png(path)!=OK:
		failures+=1
		return
	records.append({"capture_id":id,"camera_kind":camera_kind,"image_sha256":FileAccess.get_sha256(path),
		"scene_pixels_sha256":image.get_region(Rect2i(20,100,1240,460)).get_data().hex_encode().sha256_text(),
		"viewport":[1280,720],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})

func run() -> void:
	output=OS.get_environment("EQUIPMENT_OUTPUT")
	if output.is_empty() or not DirAccess.dir_exists_absolute(output):
		push_error("EQUIPMENT_OUTPUT must be an existing capture directory.")
		quit(2)
		return
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var study:=Study.instantiate()
	root.add_child(study)
	await capture("equipment-sheathed","native-equipment-study")
	study.draw_slider.value=.5
	await capture("equipment-drawing","native-equipment-study")
	study.draw_slider.value=1.0
	await capture("equipment-drawn","native-equipment-study")
	if records.size()!=3 or records[0].scene_pixels_sha256==records[1].scene_pixels_sha256 or records[1].scene_pixels_sha256==records[2].scene_pixels_sha256:
		failures+=1
	study.queue_free()
	await process_frame
	var home:=Launch.make_world()
	root.add_child(home)
	await process_frame
	var chapter: Node3D=home.get_node("ChildhoodChapter")
	chapter._show_dialog("Inspection","",[["Return","resume"]])
	for layer in home.find_children("*","CanvasLayer",true,false): layer.hide()
	var state: Dictionary=chapter.model.snapshot()
	var player: Transform3D=chapter.avatar.global_transform
	var camera:=Camera3D.new()
	home.add_child(camera)
	var guard: Vector3=chapter.gate_passage.guard_root.global_position
	camera.position=guard+Vector3(2.0,1.5,-2.5)
	camera.look_at(guard+Vector3(0,.87,0))
	camera.fov=42
	camera.current=true
	await capture("gate-service-equipment","inspection-of-live-home")
	if chapter.model.snapshot()!=state or chapter.avatar.global_transform!=player: failures+=1
	var report: Dictionary={"schema":"1792.service-equipment-render.v1","operation_id":"service-equipment-render.v1",
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"source_tree":OS.get_environment("SOURCE_TREE"),
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
		"hardware_performance_qualified":false,"historical_attribution_verified":false,"records":records,"failures":failures}
	var file:=FileAccess.open(output.path_join("equipment-captures.json"),FileAccess.WRITE)
	if file==null: failures+=1
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	home.queue_free()
	await process_frame
	print("SERVICE_EQUIPMENT_RENDER: %d captures, %d failures"%[records.size(),failures])
	quit(1 if failures or records.size()!=4 else 0)
