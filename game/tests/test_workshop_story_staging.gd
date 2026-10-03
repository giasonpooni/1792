# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Geometry and custody continuity through real commission receipts; explicit pose fixtures.
const View:=preload("res://workshops/workshop_world.gd")
const State:=preload("res://workshops/workshop_state.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error(label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func project(view,model) -> void:
	var snapshot: Dictionary=model.snapshot()
	view.sample(int(model.progress().tick),model.workshop_phase(),int(model.workshop().get("started_tick",-1)))
	check(model.snapshot()==snapshot,"projection preserves all model fields")
func waiting(view) -> int:
	var count:=0
	for blank in view.waiting_blanks:
		if blank.is_visible_in_tree(): count+=1
	return count
func run() -> void:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed-inquiry fixture")
	ok(model.begin_allowance(),"household allowance")
	var world:=Node3D.new();root.add_child(world)
	var avatar:=Node3D.new();world.add_child(avatar)
	var view:=View.new();world.add_child(view);view.build(avatar)
	var collider_count:=world.find_children("*","CollisionShape3D",true,false).size()
	check(collider_count==4,"original four station colliders retained; story props have none")
	project(view,model)
	check(waiting(view)==2 and not view.active_blank.visible,"both rough blanks establish the order")
	check(not view.finished.visible and not view.carried.visible,"no premature finished output or carried load")
	check(view.waiting_blanks[0].get_child_count()==2,"raw blank contains only head and tang")
	check(view.finished.get_child_count()==4,"finished pair retains two distinct handled tools")
	ok(model.workshop_action("reserve"),"receive fuel")
	project(view,model)
	check(waiting(view)==2 and view.carried.visible and not view.carried.get_node("ToolHeads").visible,"fuel custody leaves both raw blanks at smith")
	ok(Pose.pose(model,Craft.SITE+Vector3(0,0,-2)),"declared smith contact fixture")
	ok(model.workshop_action("start"),"actual work receipt")
	project(view,model)
	check(waiting(view)==1 and view.active_blank.visible,"one blank moves to anvil; one waits on bench")
	check(not view.finished.visible and not view.carried.visible,"working has no duplicate finished or carried pair")
	check(is_equal_approx(view.active_blank.global_position.y,Craft.SITE.y+0.895),"active metal rests on anvil top")
	var pose_before: Transform3D=view.smith_arm.transform
	var strikes_before: int=view.strike_count
	for _i in range(4): project(view,model)
	check(view.smith_arm.transform==pose_before and view.strike_count==strikes_before,"repeat sample cannot advance performance or strike")
	for _i in range(Craft.WORK_TICKS-1): model.advance()
	project(view,model)
	check(model.workshop_phase()=="working" and not view.finished.visible,"no visually premature completion")
	var working: Dictionary=model.snapshot()
	model.advance();project(view,model)
	check(waiting(view)==0 and not view.active_blank.visible and view.finished.visible,"deadline reveals only finished pair")
	ok(model.workshop_action("collect"),"physical collection")
	project(view,model)
	check(waiting(view)==0 and not view.active_blank.visible and not view.finished.visible,"collection leaves a visibly empty bench")
	check(view.carried.visible and view.carried.get_node("ToolHeads").visible,"same pair is now carried")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"declared return contact fixture")
	ok(model.workshop_action("deliver"),"physical settlement")
	project(view,model)
	check(not view.carried.visible and not view.finished.visible and waiting(view)==0,"settlement neither duplicates nor respawns order")
	ok(model.restore(working),"restore working save")
	project(view,model)
	check(waiting(view)==1 and view.active_blank.visible and not view.finished.visible,"rewind restores earlier object custody")
	check(world.find_children("*","CollisionShape3D",true,false).size()==collider_count,"phase sampling adds no collision or nodes")
	world.queue_free();await process_frame
	print("WORKSHOP_STORY_STAGING_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
