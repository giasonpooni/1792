# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Production-world inspection from explicit domain fixtures, not an input-playthrough claim.
const Launch:=preload("res://childhood/home_launch.gd")
const State:=preload("res://workshops/workshop_state.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
var failed:=0
var captures:=0
var camera: Camera3D
func _initialize() -> void: run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): push_error(error);failed+=1
func capture(chapter,model,id: String) -> void:
	ok(chapter.model.restore(model.snapshot()));chapter._apply();chapter._paused=true
	chapter.avatar.set_physics_process(false);chapter.avatar.input_enabled=false
	camera.current=true
	for layer in chapter.get_parent().find_children("*","CanvasLayer",true,false): layer.hide()
	await frames();await RenderingServer.frame_post_draw
	if root.get_camera_3d()!=camera: push_error("Inspection camera was replaced.");failed+=1
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty() or image.save_png("user://workshop-story-"+id+".png")!=OK: failed+=1
	else: captures+=1
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var model:=State.new();ok(model.restore(Fixture.complete()));ok(model.begin_allowance())
	ok(Pose.pose(model,Craft.SITE+Vector3(0,0,-2)))
	var home:=Launch.make_world();var chapter=home.get_node("ChildhoodChapter")
	chapter.save_path="user://unwritten-workshop-story-render.json";root.add_child(home);await frames()
	for layer in home.find_children("*","CanvasLayer",true,false): layer.hide()
	camera=Camera3D.new();home.add_child(camera);camera.fov=52;camera.far=400
	camera.position=Craft.SITE+Vector3(4.8,2.4,-5.7);camera.look_at(Craft.SITE+Vector3(-0.3,1.1,0.1));camera.current=true
	await capture(chapter,model,"unfinished")
	ok(Pose.pose(model,Supply.QUARTERMASTER));ok(model.workshop_action("reserve"))
	ok(Pose.pose(model,Craft.SITE+Vector3(0,0,-2)));ok(model.workshop_action("start"))
	for _i in range(36): model.advance()
	await capture(chapter,model,"working")
	for _i in range(Craft.WORK_TICKS-36): model.advance()
	await capture(chapter,model,"ready")
	ok(model.workshop_action("collect"));await capture(chapter,model,"collected")
	home.queue_free();await frames()
	print("WORKSHOP_STORY_STAGING_RENDER: %d captures; %d failures"%[captures,failed]);quit(1 if failed or captures!=4 else 0)
