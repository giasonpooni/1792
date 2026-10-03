# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Meaningful presentation probes complement the real escort/input journey.
const Launch:=preload("res://childhood/home_launch.gd")
const Setup:=preload("res://tests/instructor_story_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const D:=preload("res://commissions/commission_direction.gd")
const R:=preload("res://commissions/commission_rules.gd")
const Timing:=preload("res://presentation/story_attention.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("INSTRUCTOR STORY: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func _run() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	ok(scene.model.restore(Setup.make("active",true)),"declared active perspective fixture restored before ready")
	root.add_child(home);await frames(8)
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	check(is_instance_valid(scene.specialist_body),"controlled pre-ready hydration builds secondary body")
	check(root.get_camera_3d()==scene.specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D"),"actual role chooses its camera once")
	check(scene.foreground_actor()==scene.specialist_body,"foreground follows controlled actor")
	check(scene.specialist_body.is_on_floor(),"hydrated secondary has native ground contact")
	var before: Dictionary=scene.model.snapshot();var camera:=root.get_camera_3d()
	var hero_transform: Transform3D=scene.avatar.global_transform
	for _i in range(6):
		var cue:=D.read(scene,false);check(cue.task=="Stay together for the next movement","live eligible requirement is singular")
		check(not D.read(scene,true).show_progress,"moving suppresses explanatory copy")
	check(scene.model.snapshot()==before and scene.avatar.global_transform==hero_transform,"guidance does not mutate world or waiting hero")
	check(root.get_camera_3d()==camera,"guidance sampling does not change camera")
	# Domain pose fixture changes the waiting principal only. No tick or practice
	# credit can follow because physical/model mismatch is a contact refusal.
	ok(Pose.pose(scene.model,R.HOME+Vector3(7,0,0)),"declared interruption pose")
	scene.model.advance();scene._advance_commission_drill()
	check(scene._message==D.line("drill_paused"),"practical concern returns after actual lost contact")
	var practice: int=scene.model.specialist().practice
	scene.model.advance();scene._advance_commission_drill()
	check(scene.model.specialist().practice==practice,"interruption cannot advance attendance")
	check(scene._message==D.line("drill_paused"),"stable interruption preserves one response")
	ok(Pose.pose(scene.model,R.HOME),"declared restored place")
	scene.model.advance();scene._advance_commission_drill()
	check(scene._message==D.line("drill_resumed"),"rejoined practice earns the return motif")
	check(scene.model.specialist().practice==practice+1,"resumption retains rather than restarts prior practice")
	var started: Dictionary=scene.model.snapshot()
	scene._open_journal();await frames(3)
	check(scene._panel_text.text.contains("LOCAL INSTRUCTOR · MY WORK HERE"),"secondary journal uses its own voice")
	check(not scene._panel_text.text.contains("WORKING IMPRESSION") and not scene._panel_text.text.contains("borrowed-rope"),"secondary notebook excludes principal private exposition")
	check(scene.model.snapshot()==started,"pause freezes original state and attendance")
	check(root.get_camera_3d()==camera,"paused notebook preserves role camera")
	var actor_notebook: String=scene._panel_text.text
	scene._menu_action("oral_view");scene._menu_action("dialogue")
	check(scene._panel_text.text==actor_notebook,"stale principal story/replay callbacks cannot expose private prose")
	check(scene.model.snapshot()==started,"stale private-view callbacks leave world unchanged")
	scene._resume();scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	# Original dialogue and transient queue are absent from durable participation.
	var retained: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
	for _i in range(3): scene._refresh()
	check(scene.model.snapshot()==retained and scene.model.journal()==journal,"repeated presentation creates no historical or private knowledge")
	check(not D.AFTER.contains("when I left"),"uninterrupted aftermath asserts no unearned departure")
	check(D.CANDIDATE.contains("Keep a place") and D.line("drill_paused").contains("Keep a place"),"candidate concern foreshadows playable interruption")
	check(Timing.reading_ticks(D.line("lesson_complete"))<=360,"completion reaction stays short and finite")
	# A stable control sync cannot steal an externally chosen study camera.
	var external:=Camera3D.new();home.add_child(external);external.current=true
	scene._sync_commission();scene._show_dialog("PAUSED PRACTICE","The place waits.",[["Resume","resume"]])
	check(root.get_camera_3d()==external,"ordinary sync and dialog do not own camera")
	var contract: Dictionary=scene.model.snapshot();scene._menu_action("commission:appoint");scene._physics_process(1.0/60.0)
	check(scene.model.snapshot()==contract,"undisplayed stale appointment callback creates no receipt")
	check(scene._commission_action.is_empty(),"undisplayed commission callback is not queued")
	# A separate declared offer fixture exercises the narrower scene menu. The
	# inherited household menu has one optional question; the actual offers live
	# in a focused pause with only their terms and the available cash.
	ok(scene.model.restore(Setup.make("available")),"declared available commission fixture")
	scene._apply();scene._resume();scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	scene._open_quartermaster()
	check("terms" in scene._commission_choices and not "reserve|standard" in scene._commission_choices,"shared household menu offers the question before the reservation")
	var available: Dictionary=scene.model.snapshot()
	scene._menu_action("commission:terms");scene._physics_process(1.0/60.0)
	check(scene._panel_text.text.contains("KEEPING AN INSTRUCTOR") and "reserve|standard" in scene._commission_choices and "reserve|senior" in scene._commission_choices,"focused terms display both scoped offers")
	check(scene._actions.get_child_count()==3 and scene.model.snapshot()==available,"focused conversation has two offers and return with no commitment")
	home.queue_free();await frames(4)
	print("INSTRUCTOR_STORY_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
