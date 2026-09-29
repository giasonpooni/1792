# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Render retained input observations through the same player camera; no invented walk.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
var output:=""
var journey: Dictionary
var records: Array=[]
var motions: Array=[]
var failures:=0
var c: Node3D
var home: Node3D
var camera: Camera3D
func _initialize() -> void: run.call_deferred()
func frames(n: int=2) -> void:
	for _i in range(n): await process_frame
	await RenderingServer.frame_post_draw
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1;push_error("COURTYARD_RENDER: "+label)
func restore_observation(o: Dictionary) -> bool:
	var error: String=c.model.restore(o.snapshot)
	if error.is_empty(): error=c._candidate_error(c.model)
	if not error.is_empty(): check(false,"world replay: "+error);return false
	c._apply();error=c.avatar.restore_motion(o.avatar_motion)
	if not error.is_empty(): check(false,"motor replay: "+error);return false
	c._paused=false;c.avatar.input_enabled=false;c.avatar.set_physics_process(false)
	c._message=o.message;c._refresh()
	camera.global_transform=Transform3D(Basis(Base.point(o.camera_basis[0]),Base.point(o.camera_basis[1]),Base.point(o.camera_basis[2])),Base.point(o.camera_position))
	camera.fov=o.camera_fov
	return true
func metadata(path: String) -> Dictionary:
	return {"file":path.get_file(),"tick":c.model.progress().tick,"position":Base.coords(c.avatar.global_position),
		"camera_position":Base.coords(camera.global_position),"camera_basis":[Base.coords(camera.global_basis.x),Base.coords(camera.global_basis.y),Base.coords(camera.global_basis.z)],
		"camera_kind":"existing-player-camera-observation-replay","fov":camera.fov,"phase":c.model.workshop_phase(),
		"image_sha256":FileAccess.get_sha256(path),"source_commit":OS.get_environment("SOURCE_COMMIT"),
		"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),"viewport":[root.size.x,root.size.y],"msaa":root.msaa_3d}
func capture(id: String) -> void:
	var before: Dictionary=c.model.snapshot();await frames(3)
	var image:=root.get_texture().get_image();var path:=output.path_join("courtyard-"+id+".png")
	check(image!=null and image.save_png(path)==OK,"capture "+id)
	check(c.model.snapshot()==before,"rendering cannot advance world")
	var r:=metadata(path);r.capture_id=id
	r.scene_pixels_sha256=image.get_region(Rect2i(0,150,image.get_width(),image.get_height()-240)).get_data().hex_encode().sha256_text()
	r.device=RenderingServer.get_video_adapter_name();r.renderer=RenderingServer.get_current_rendering_method()
	r.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);r.primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	records.append(r)
func step(id: String) -> Dictionary:
	for o in journey.steps:
		if o.step==id: return o
	return {}
func run() -> void:
	output=OS.get_environment("HOME_ART_OUTPUT")
	var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("home-workshop-journey.json")))
	if not source is Dictionary or source.get("schema")!="1792.home-workshop-journey.v2" or source.get("source_content_sha256")!=OS.get_environment("SOURCE_CONTENT_SHA256") or OS.get_environment("SOURCE_CONTENT_SHA256").is_empty(): push_error("Missing source-bound input journey.");quit(2);return
	journey=source
	if not journey.get("motion_frames") is Array or journey.motion_frames.size()<40 or journey.motion_frames.size()>240: push_error("Missing or excessive motion observations.");quit(2);return
	if DirAccess.dir_exists_absolute(output.path_join("walk-frames")): push_error("Refuse previous motion output.");quit(2);return
	DirAccess.make_dir_absolute(output.path_join("walk-frames"))
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(854,480)
	home=Launch.make_world();c=home.get_node("ChildhoodChapter");c.save_path=output.path_join("unwritten-replay-slot.json");root.add_child(home)
	await frames(3)
	# Stop actor scripts, not the renderer. Every transform below comes from recorded input.
	for n in home.find_children("*","Node",true,false): n.set_physics_process(false);n.set_process(false)
	c.set_physics_process(false)
	var arm: SpringArm3D=c.avatar.get_node("CameraPivot/SpringArm3D");arm.set_physics_process_internal(false)
	camera=arm.get_node("Camera3D");camera.current=true
	var previous_tick: int=-1
	for o in journey.motion_frames:
		if int(o.tick)<=previous_tick: check(false,"nonchronological input trace");break
		previous_tick=int(o.tick)
		if not restore_observation(o): break
		var before: Dictionary=c.model.snapshot();await frames(1)
		var path:=output.path_join("walk-frames/%04d.png"%motions.size());var image:=root.get_texture().get_image()
		check(image.save_png(path)==OK,"motion frame");check(c.model.snapshot()==before,"motion replay freezes source state")
		var r:=metadata(path);r.input_observation_index=motions.size();motions.append(r)
	if not restore_observation(step("working")): quit(1);return
	c.art.set_refinement(false);await capture("earlier-study")
	c.art.set_refinement(true);await capture("authored-daylight")
	await capture("working-daylight")
	c.art.set_preset("evening");await capture("working-evening");c.art.set_preset("daylight")
	if not restore_observation(step("tools")): quit(1);return
	await capture("carried-tools")
	root.size=Vector2i(800,450);c.open_art_study();await frames(5)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(c._panel.get_global_rect()),"compact F7 fits")
	await capture("controls-compact")
	var report: Dictionary={"schema":"1792.courtyard-captures.v1","captures":records,"motion_frames":motions,"failures":failures,
		"rendering_kind":"recorded-input-observation-replay","initial_fixture":"completed-inquiry-only","engine":Engine.get_version_info().string,
		"hardware_performance_qualified":false,"historical_authentication":false,"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),
		"journey_sha256":FileAccess.get_sha256(output.path_join("home-workshop-journey.json"))}
	var file:=FileAccess.open(output.path_join("courtyard-captures.json"),FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	else: failures+=1
	home.queue_free();await frames()
	print("COURTYARD_RENDER: %d captures; %d motion frames; %d failures"%[records.size(),motions.size(),failures]);quit(1 if failures or records.size()!=6 else 0)
