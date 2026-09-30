# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Read-only playback of actually played observations; close-ups use an explicit inspection lens.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
var chapter: Node3D
var home: Node3D
var lens: Camera3D
var records: Array=[]
var failed:=0
var output:="user://bazaar-face-images"
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if not value: failed+=1;push_error("FACE RENDER: "+label)
func frames(n: int=4) -> void:
	for i in range(n): await process_frame
func apply(record: Dictionary) -> void:
	check(chapter.model.restore(record.state).is_empty(),"played state restored")
	chapter._apply();chapter._resume()
	chapter.set_physics_process(false);chapter.avatar.set_physics_process(false)
	chapter.avatar.pivot.rotation=Base.point(record.camera_pivot);chapter.avatar.velocity=Base.point(record.velocity)
	chapter._message=record.message;chapter.bazaar_performance.sound_enabled=false
	chapter.bazaar_performance.speech=record.speech.duplicate(true)
	chapter.bazaar_performance.report_until=int(record.report_until)
	chapter.bazaar_performance._guard=record.guard
	chapter._refresh();chapter.bazaar_performance.sample(false)
func capture(name: String,record: Dictionary,closeup: bool,neutral: bool=false) -> void:
	apply(record)
	var director: Node=chapter.bazaar_performance
	var index:=int(record.actor)
	var figure: Node3D=director.figures[index]
	var player_camera: Camera3D=chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	player_camera.current=true
	if closeup:
		var target: Vector3=figure.head.global_transform*Vector3(0,.075,0)
		lens.global_position=target+figure.head.global_basis*Vector3(.06,.045,-.92)
		lens.look_at(target);lens.current=true
		director.canvas.hide();chapter._hud.hide();chapter._caption.hide();chapter._narrator_label.hide()
		chapter.art.detail.hud.hide()
		for actor in chapter.youths: actor.caption.hide()
	var expected: Dictionary=chapter.model.snapshot()
	await frames(2)
	if neutral: figure.apply_expression("neutral",0.0)
	check(chapter.model.snapshot()==expected,"lens and facial variant do not alter the played state")
	if not neutral: check(figure.expression_name==record.faces[index].expression,"playback retains observed expression")
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.get_width()==1280 and image.get_height()==720,"nonempty full-size rendered image")
	check(image.save_png(output.path_join(name+".png"))==OK,"PNG saved")
	records.append({"file":name+".png","tick":record.tick,"actor":index,"expression":figure.expression_name,
		"camera":"inspection close-up" if closeup else "recorded player camera",
		"variant":"neutral visual comparison, identical state" if neutral else "played performance observation",
		"speech":record.speech.get("text","")})
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bazaar-face-performance.json"))
	if not data is Dictionary or data.get("failed")!=0:
		push_error("A successful actual face-performance journey is required first.");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	home=Launch.make_world();root.add_child(home);chapter=home.get_node("ChildhoodChapter")
	chapter.set_physics_process(false);chapter.avatar.set_physics_process(false)
	lens=Camera3D.new();lens.near=.02;lens.fov=40;chapter.add_child(lens)
	await frames(8)
	for pair in [["mela-amused","3-amused"],["jiva-wry","4-wry"],["challenger","0-challenging"],
		["mela-resolute","3-resolute"],["mela-relieved","3-relieved"],["jiva-relieved","4-relieved"]]:
		check(data.performances.has(pair[1]),"required expression actually observed: "+pair[1])
		if data.performances.has(pair[1]): await capture(pair[0],data.performances[pair[1]],true)
	await capture("mela-neutral-comparison",data.performances["3-amused"],true,true)
	await capture("player-view",data.performances["3-amused"],false)
	var manifest: Dictionary={"schema":"1792.bazaar-face-render.v1","captures":records,"failed":failed,
		"audio":"none","human_art_review":false,"scope":"native observation playback; inspection lenses are not gameplay camera changes"}
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	home.queue_free();await frames(4)
	print("BAZAAR_FACE_RENDER: %d captures; %d failures"%[records.size(),failed]);quit(1 if failed else 0)
