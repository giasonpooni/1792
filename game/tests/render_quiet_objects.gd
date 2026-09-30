# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Inspect the actual object meshes after a played route. No concept images or new game result.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
var scene: Node3D
var home: Node3D
var lens: Camera3D
var records: Array=[]
var failed:=0
const OUTPUT:="user://quiet-object-images"
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed+=1;push_error(message)
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func apply(record: Dictionary) -> void:
	check(scene.model.restore(record.state).is_empty(),"observed state restores")
	scene._apply();scene._resume();scene.avatar.pivot.rotation=Base.point(record.pivot)
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	scene.bazaar_performance.sound_enabled=false
	scene.quiet_objects.show_page(record.detail,record.page)
	check(scene._panel_text.text==record.text,"same text as played choice")
func capture(name: String,record: Dictionary,macro: bool) -> void:
	apply(record)
	var authority: Dictionary=scene.model.snapshot()
	var player_camera: Camera3D=scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	player_camera.current=true
	if macro:
		var target: Vector3=scene.quiet_objects.turnables[record.detail].global_position
		lens.global_position=target+Vector3(.65,.75,-.95);lens.look_at(target);lens.current=true
		scene._panel.hide();scene._hud.hide();scene._caption.hide();scene._narrator_label.hide()
		scene.art.detail.hud.hide();scene.quiet_objects.hint_layer.hide();scene.bazaar_performance.canvas.hide()
		for label in home.find_children("*","Label3D",true,false):label.hide()
	await frames(3);await RenderingServer.frame_post_draw
	check(scene.model.snapshot()==authority,"inspection lens leaves observed world untouched")
	var image:=root.get_texture().get_image()
	check(not image.is_empty(),"rendered image exists")
	check(image.save_png(OUTPUT.path_join(name+".png"))==OK,"PNG written")
	records.append({"file":name+".png","detail":record.detail,"page":record.page,"camera":"macro inspection" if macro else "recorded player camera",
		"scope":"playback of actual mesh and played choice; not a fresh gameplay run or historical artefact"})
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://quiet-objects-journey.json"))
	if not data is Dictionary or data.get("failed")!=0:
		push_error("Run successful quiet-object journey first.");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	home=Launch.make_world();root.add_child(home);scene=home.get_node("ChildhoodChapter")
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	lens=Camera3D.new();lens.near=.02;lens.fov=44;scene.add_child(lens)
	await frames(8)
	for name in ["cloth-first","cloth-turn","rein-first","rein-turn","pan-first","pan-turn"]:
		await capture(name,data.captures[name],true)
	await capture("pan-other",data.captures["pan-other"],false)
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":"1792.quiet-object-renders.v1","captures":records,"failed":failed,"portrait_embedded":false},"\t"));file.close()
	home.queue_free();await frames(4)
	print("QUIET_OBJECT_RENDER: %d captures; %d failures"%[records.size(),failed]);quit(1 if failed else 0)
