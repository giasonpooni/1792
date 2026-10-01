# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Restore source-bound states from the executed input journey, then draw with Godot.
const Launch:=preload("res://childhood/home_launch.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
var records: Array=[]
var failures:=0
var output:=""
var tag: Label
var source_journey: Dictionary
func _initialize() -> void: run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func restore_step(chapter,step: String) -> bool:
	for item in source_journey.steps:
		if item.step!=step: continue
		chapter._paused=true;chapter.avatar.set_physics_process(false)
		var error: String=chapter.model.restore(item.snapshot)
		if error.is_empty(): error=chapter._candidate_error(chapter.model)
		if not error.is_empty(): push_error(error);failures+=1;return false
		chapter._apply();chapter.avatar.pivot.rotation.y=item.camera_yaw;chapter._message=item.message
		chapter._refresh();return true
	failures+=1;push_error("Missing journey step "+step);return false
func capture(id: String,chapter,camera_kind: String) -> void:
	tag.text="1792 · "+id.replace("-"," ")+"\nNative prototype · original fictional errand · not a surveyed historical workshop"
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=output.path_join("home-workshop-"+id+".png")
	if image==null or image.is_empty() or image.save_png(path)!=OK: failures+=1;push_error("Capture failed: "+id);return
	records.append({"capture_id":id,"camera_kind":camera_kind,"viewport":[root.size.x,root.size.y],"image_sha256":FileAccess.get_sha256(path),
		"scene_pixels_sha256":image.get_region(Rect2i(0,96,image.get_width(),image.get_height()-96)).get_data().hex_encode().sha256_text(),
		"engine":Engine.get_version_info().string,"device":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"workshop_phase":chapter.model.workshop_phase(),"tick":chapter.model.progress().tick,"source_commit":OS.get_environment("SOURCE_COMMIT"),
		"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),"model_id":Craft.VERSION,"operation_id":"home-workshop-capture.v2","journey_sha256":FileAccess.get_sha256(output.path_join("home-workshop-journey.json"))})
func run() -> void:
	output=OS.get_environment("HOME_WORKSHOP_OUTPUT")
	if output.is_empty() or not DirAccess.dir_exists_absolute(output): push_error("Dedicated output required.");quit(2);return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("home-workshop-journey.json")))
	if not parsed is Dictionary or parsed.get("schema")!="1792.home-workshop-journey.v2" or parsed.get("source_content_sha256","")!=OS.get_environment("SOURCE_CONTENT_SHA256") or OS.get_environment("SOURCE_CONTENT_SHA256").is_empty():
		push_error("Missing or mismatched executed-journey source identity.");quit(2);return
	source_journey=parsed
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var home:=Launch.make_world();var chapter=home.get_node("ChildhoodChapter")
	chapter.save_path=output.path_join("unwritten-render-slot.json")
	root.add_child(home);await frames()
	var layers: Array[Node]=home.find_children("*","CanvasLayer",true,false)
	var layer_visibility: Array[bool]=[]
	for layer in layers: layer_visibility.append(layer.visible)
	var evidence:=CanvasLayer.new();home.add_child(evidence);evidence.layer=100
	tag=Label.new();tag.position=Vector2(20,16);tag.add_theme_font_size_override("font_size",17)
	tag.add_theme_color_override("font_shadow_color",Color.BLACK);tag.add_theme_constant_override("shadow_offset_y",2);evidence.add_child(tag)
	var camera:=Camera3D.new();camera.far=400;camera.fov=58;home.add_child(camera)
	camera.position=Craft.SITE+Vector3(4.8,2.4,-5.7);camera.look_at(Craft.SITE+Vector3(-0.55,1.05,0));camera.current=true
	if not restore_step(chapter,"working"): quit(1);return
	for layer in layers: layer.hide()
	# Let the same world tick drive the hammer; no direct pose or production injection.
	chapter._resume();await frames(32);chapter._show_dialog("CAPTURE","",[["Return","resume"]])
	await capture("working-daylight",chapter,"inspection-from-input-journey")
	chapter.art.set_preset("golden_hour");await capture("working-golden",chapter,"inspection-same-state")
	chapter.art.set_preset("daylight")
	if not restore_step(chapter,"tools"): quit(1);return
	camera.current=false;chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	for i in range(layers.size()): layers[i].visible=layer_visibility[i]
	chapter._resume();await frames(3)
	chapter._paused=true;chapter.avatar.set_physics_process(false);chapter.avatar.input_enabled=false
	chapter._refresh();tag.position=Vector2(20,root.size.y-104)
	await capture("carried-tools-gameplay",chapter,"existing-player-camera-restored-journey-look")
	# Compact real interaction, with the complete choices inside the normal scroll container.
	root.size=Vector2i(800,450);tag.hide();chapter._open_smith();await frames(8)
	if not Rect2(Vector2.ZERO,Vector2(root.size)).encloses(chapter._panel.get_global_rect()): failures+=1;push_error("Compact workshop dialog overflow.")
	await capture("smith-compact",chapter,"existing-player-camera-paused")
	root.size=Vector2i(1280,720);tag.show();tag.position=Vector2(20,16)
	if not restore_step(chapter,"complete"): quit(1);return
	chapter._open_accounts();await frames(8);tag.hide()
	await capture("settled-accounts",chapter,"existing-player-camera-paused")
	var report: Dictionary={"schema":"1792.home-workshop-captures.v2","captures":records,"failures":failures,"historical_authentication":false,"hardware_performance_qualified":false}
	var file:=FileAccess.open(output.path_join("home-workshop-captures.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	else: failures+=1
	home.queue_free();await frames()
	print("HOME_WORKSHOP_RENDER: %d captures; %d failures"%[records.size(),failures]);quit(1 if failures or records.size()!=5 else 0)
