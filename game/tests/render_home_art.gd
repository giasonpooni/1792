# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Real runtime captures: named inspection views + an untouched gameplay camera + UI.
const Launch := preload("res://childhood/home_launch.gd")
var captures := 0
var failures := 0
var records: Array[Dictionary] = []
var output := ""
var tag: Label
func _initialize() -> void: run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(id: String, chapter: Node3D, camera_kind: String) -> void:
	tag.text="1792 · "+id.replace("-"," ")+"\nIn-engine art study · authored compressed Home, not surveyed terrain"
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=output.path_join("home-art-"+id+".png")
	if image==null or image.is_empty() or image.save_png(path)!=OK:
		failures+=1;push_error("Failed capture: "+id);return
	captures+=1
	var record: Dictionary=chapter.art.report()
	record.capture_id=id;record.camera_kind=camera_kind;record.viewport=[root.size.x,root.size.y]
	record.image_sha256=FileAccess.get_sha256(path)
	record.scene_pixels_sha256=image.get_region(Rect2i(0,96,image.get_width(),image.get_height()-96)).get_data().hex_encode().sha256_text()
	record.engine=Engine.get_version_info().string;record.rendering_method=RenderingServer.get_current_rendering_method()
	record.rendering_device=RenderingServer.get_video_adapter_name()
	record.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	record.rendered_primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	record.source_commit=OS.get_environment("SOURCE_COMMIT")
	record.operation_id="home-art-capture.v1";records.append(record)
func run() -> void:
	output=OS.get_environment("HOME_ART_OUTPUT")
	if output.is_empty() or not DirAccess.dir_exists_absolute(output):
		push_error("HOME_ART_OUTPUT must name an existing dedicated directory.");quit(2);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var home:=Launch.make_world();var chapter=home.get_node("ChildhoodChapter")
	chapter.save_path=output.path_join("isolated-unwritten-save.json")
	root.add_child(home);await frames()
	chapter._show_dialog("Inspection","",[["Return","resume"]])
	var layers: Array[Node]=home.find_children("*","CanvasLayer",true,false)
	var visibility: Array[bool]=[]
	for layer in layers: visibility.append(layer.visible);layer.hide()
	var evidence:=CanvasLayer.new();home.add_child(evidence);evidence.layer=100
	tag=Label.new();tag.position=Vector2(20,16);tag.add_theme_font_size_override("font_size",18)
	tag.add_theme_color_override("font_shadow_color",Color.BLACK);tag.add_theme_constant_override("shadow_offset_y",2);evidence.add_child(tag)
	var camera:=Camera3D.new();home.add_child(camera);camera.far=400;camera.fov=65
	camera.position=Vector3(14,2.75,1.5);camera.look_at(Vector3(-1,1.7,11.35));camera.current=true
	chapter.art.set_enabled(false);await capture("courtyard-baseline",chapter,"inspection")
	chapter.art.set_enabled(true);await capture("courtyard-daylight",chapter,"inspection")
	chapter.art.set_preset("golden_hour");await capture("courtyard-golden",chapter,"inspection")
	chapter.art.set_preset("evening");await capture("courtyard-evening",chapter,"inspection")
	chapter.art.set_preset("daylight")
	camera.position=Vector3(2.8,2.15,-0.3);camera.look_at(Vector3(8.7,1.5,-4.8));await capture("stable-daylight",chapter,"inspection")
	camera.position=Vector3(-19.2,2.4,-13.7);camera.look_at(Vector3(-24,1.7,-17.6));await capture("market-daylight",chapter,"inspection")
	# The stock gameplay camera remains unchanged; no staged avatar pose is introduced.
	camera.current=false;chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	for i in range(layers.size()): layers[i].visible=visibility[i]
	chapter._resume();await frames(3)
	tag.position=Vector2(20,root.size.y-94)
	await capture("gameplay-camera",chapter,"existing-player-camera")
	chapter.open_art_study();root.size=Vector2i(800,450);tag.hide();await frames(8)
	var rect:=Rect2(Vector2.ZERO,Vector2(root.size))
	if not rect.encloses(chapter._panel.get_global_rect()): failures+=1;push_error("Art dialog does not fit compact viewport.")
	await capture("controls-compact",chapter,"existing-player-camera-paused");tag.hide()
	var report: Dictionary={"schema":"1792.home-art-capture-batch.v1","captures":records,"failures":failures,"software_renderer_detected":RenderingServer.get_video_adapter_name().to_lower().contains("llvmpipe"),"hardware_performance_qualified":false}
	var file:=FileAccess.open(output.path_join("home-art-captures.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t"));file.close()
	else: failures+=1
	home.queue_free();await frames()
	print("HOME_ART_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures or captures!=8 else 0)
