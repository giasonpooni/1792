# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared staging fixtures. Real recruitment/escort lives in integration QA.
## Captures keep the gameplay camera and true native 800x450 viewport.
const Launch:=preload("res://childhood/home_launch.gd")
const Setup:=preload("res://tests/instructor_story_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const D:=preload("res://commissions/commission_direction.gd")
const R:=preload("res://commissions/commission_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
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
	if image.get_size()!=Vector2i(800,450) or root.get_visible_rect().size!=Vector2(800,450): failed+=1;push_error("Native small viewport required: "+name)
	if image.is_empty() or image.save_png("user://instructor-story-"+name+".png")!=OK: failed+=1
func settle(scene) -> void:
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
func look(scene,at: Vector3) -> void:
	var body: CharacterBody3D=scene.foreground_actor()
	var d:=at-body.global_position;body.pivot.rotation.y=atan2(-d.x,-d.z);body.pivot.rotation.x=-.16
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(800,450)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	ok(scene.model.restore(Setup.make("introduced")));root.add_child(home);await frames(8);settle(scene)
	ok(Pose.pose(scene.model,R.RECEPTION+Vector3(0,0,2)));scene._apply();settle(scene);look(scene,R.RECEPTION)
	scene._show_dialog("THE CANDIDATE'S TERMS",D.CANDIDATE,[["Accept terms and walk home","commission:engage"],["Continue your day","resume"]]);await capture("candidate-small")
	scene._resume();ok(scene.model.restore(Setup.make("escorting")));scene._apply();settle(scene)
	ok(Pose.pose(scene.model,Vector3(-13,.14,-11)));scene._apply();settle(scene);look(scene,R.RECEPTION)
	scene._message=D.line("separated");scene.story_attention.reset(int(scene.model.progress().tick));scene._refresh();await capture("waiting-small")
	var s: Dictionary=scene.model.snapshot();s.commission_actor.position=Base.coords(R.HOME+Vector3(-1,0,0));ok(scene.model.restore(s));ok(Pose.pose(scene.model,R.HOME))
	scene._apply();settle(scene);look(scene,R.HOME+Vector3(-1,0,0))
	scene._show_dialog("ENTERING HIS NAME",D.SIGNING,[["Sign with the instructor present","commission:appoint"],["Continue your day","resume"]]);await capture("signing-small")
	scene._resume();ok(scene.model.restore(Setup.make("active",true)));scene._apply();settle(scene);look(scene,R.POST)
	scene._message=D.line("lesson_start");scene.story_attention.reset(int(scene.model.progress().tick));scene._refresh();await capture("practice-small")
	# A declared waiting-principal position demonstrates the active missing cue;
	# no practice is earned while that physical presence is absent.
	ok(Pose.pose(scene.model,R.HOME+Vector3(7,0,0)));scene.avatar.global_position=scene.model.position()
	scene.model.advance();scene._advance_commission_drill();scene._refresh();await capture("interrupted-small")
	ok(Pose.pose(scene.model,R.HOME));scene.avatar.global_position=scene.model.position()
	for _i in range(R.PRACTICE_TICKS+1): scene.model.advance();scene._advance_commission_drill()
	if scene.model.commission().lesson!="complete": failed+=1;push_error("Renderer fixture did not physically complete its admitted drill")
	ok(scene.model.commission_action("control",R.HERO));scene._apply();settle(scene);look(scene,R.HOME+Vector3(-1,0,0))
	scene._show_dialog("KEEPING A PLACE",D.AFTER,[["Continue your day","resume"]]);await capture("aftermath-small")
	home.queue_free();await frames(4)
	print("INSTRUCTOR_STORY_RENDER: %d captures; %d failures"%[count,failed]);quit(1 if failed or count!=6 else 0)
