# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Authored presentation fixtures. Input/collision-driven journeys live in test_remounts.gd.
## Only this renderer uses an overview camera; gameplay retains the player camera.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const R:=preload("res://remounts/remount_rules.gd")
const D:=preload("res://remounts/remount_direction.gd")
const S:=preload("res://territory/misl_rules.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func capture(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();count+=1
	if Vector2i(root.get_visible_rect().size)!=root.size or image.get_size()!=root.size:
		failed+=1;push_error("Capture must use the native requested viewport: "+name)
	if image.is_empty() or image.save_png("user://remounts-"+name+".png")!=OK: failed+=1
func pose(scene,at: Vector3,yaw: float) -> void:
	ok(Pose.pose(scene.model,at));scene._apply();scene._paused=false
	scene.avatar.set_physics_process(false);scene.avatar.pivot.rotation=Vector3(-0.2,yaw,0)
	scene.yard.sample(at,true,true);scene._refresh()
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	ok(scene.model.restore(Fixture.complete()));root.add_child(home);await frames()
	ok(scene.model.begin_allowance());ok(scene.model.begin_remounts());scene._sync_remounts(true)
	scene.set_physics_process(false);scene.avatar.set_physics_process(false);scene._message="";scene.story_attention.reset(int(scene.model.progress().tick))
	var camera:=Camera3D.new();home.add_child(camera)
	camera.position=Vector3(19,14,35);camera.look_at(Vector3(0,0.8,21));camera.current=true
	scene._refresh();await capture("yard-overview")
	camera.queue_free();scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	pose(scene,Vector3(13,0.14,21),PI/2);await capture("public-gate")
	pose(scene,Vector3(-12,0.14,24),-PI/2);await capture("service-passage")
	pose(scene,Vector3(-3,1.63,17.7),PI);await capture("overlook")
	root.size=Vector2i(800,450)
	ok(Pose.pose(scene.model,R.HITCH));ok(scene.model.remount_action("horses"))
	pose(scene,Vector3(4,0.14,23),PI);scene._message=D.action_line("horses");scene._refresh();await capture("discovery-small")
	for pair in [["note",R.NOTE]]:
		ok(Pose.pose(scene.model,pair[1]));ok(scene.model.remount_action(pair[0]))
	pose(scene,Vector3(4,0.14,21),PI);scene._message=D.action_line("note");scene._refresh();await capture("homeward-small")
	ok(Pose.pose(scene.model,S.QUARTERMASTER));ok(scene.model.remount_action("resolve"));scene._apply();scene.avatar.set_physics_process(false)
	scene._show_dialog("THE SEALED ACCOUNT",D.report(scene.model.remounts().ledger),[["And the horses?","resume"],["Return","resume"]])
	await capture("account-small")
	scene._show_dialog("THE HORSES STAY IN THE YARD",D.AFTERMATH,[["Return","resume"]]);await capture("aftermath-small")
	home.queue_free();await frames()
	print("REMOUNTS_RENDER: %d captures; %d failures"%[count,failed]);quit(1 if failed or count!=8 else 0)
