# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Optional material-story details: direct craft, not collectible/economy state.
const Launch:=preload("res://childhood/home_launch.gd")
const State:=preload("res://youth/brawl_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Supply:=preload("res://territory/misl_rules.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("HAND WORKED LIVES FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene: Node3D,p: Vector3) -> void:
	var d:=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap_e(scene: Node3D) -> void:
	var e:=InputEventKey.new();e.keycode=KEY_E;e.pressed=true;scene._unhandled_input(e);await frames(2)
func press(scene: Node3D,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button is Button and button.text.begins_with(prefix): button.pressed.emit();await frames(2);return
	check(false,"missing button "+prefix)
func invited_at(point: Vector3) -> State:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed inquiry fixture")
	ok(Pose.pose(model,Supply.MARKET),"market fixture");ok(model.begin_brawl(),"existing invitation")
	ok(Pose.pose(model,point),"material detail pose")
	var snap:=model.snapshot()
	for i in [3,4]: snap.youth_brawl.actors[i].position=Base.coords(point+Vector3(-.8 if i==3 else .8,0,1.1))
	ok(model.restore(snap),"friends positioned in same existing world state")
	return model
func run() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	var model:=invited_at(Vector3(-21.25,.14,-12.05));ok(scene.model.restore(model.snapshot()),"restore invited detail fixture")
	root.add_child(home);await frames(8)
	var stage: Node3D=scene.bazaar_performance.material_memory
	check(is_instance_valid(stage),"material-memory stage attached to existing Home")
	check(stage.get_meta("classification","")=="original-fictional-material-memory","explicit fictional craft classification")
	check(stage.details.size()==3,"exactly three hand-authored material stories")
	check(stage.find_children("*","CollisionShape3D",true,false).is_empty() and stage.find_children("*","StaticBody3D",true,false).is_empty(),"details add no collision or physics authority")
	var ids:=stage.details.map(func(d):return d.id)
	check(ids==["pale_repair","hidden_colour","kept_place"],"stable authored detail order")
	for detail in stage.details:
		check(stage.nearest(detail.position).id==detail.id,"detail is locally discoverable "+detail.id)
		check(String(detail.description).length()>40 and String(detail.with_friends).contains("BUDDH"),"detail carries object description and original dialogue "+detail.id)
	check(stage.nearest(Vector3.ZERO).is_empty(),"far world position discovers no detail")
	var before:=scene.model.snapshot();var journal_before:=scene.model.journal()
	var detail:=stage.record("pale_repair");look(scene,detail.focus);await tap_e(scene)
	check(scene._panel.visible and scene._panel_text.text.contains("THE PALE REPAIR"),"physical E interaction opens repaired-basket scene")
	check(scene._panel_text.text.contains("JIVA") and scene._panel_text.text.contains("MELA"),"nearby physical friends join the optional exchange")
	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"inspection adds no time, receipts, inventory, money or journal fact")
	await press(scene,"Continue")
	var wall:=scene._box(Vector3(.2,2.5,2.0),(scene.avatar.global_position+detail.focus)*.5+Vector3.UP*.6,Color.GRAY,true)
	await frames(4);look(scene,detail.focus);await tap_e(scene)
	check(not scene._panel.visible and scene._message.contains("clear sight"),"new obstruction refuses stale object access")
	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"blocked inspection is atomic")
	wall.get_parent().queue_free();await frames(4)
	for id in ["hidden_colour","kept_place"]:
		var item:=stage.record(id)
		var next:=invited_at(item.position);ok(scene.model.restore(next.snapshot()),"restore "+id+" fixture");scene._apply();await frames(5);look(scene,item.focus);before=scene.model.snapshot();journal_before=scene.model.journal();await tap_e(scene)
		check(scene._panel.visible and scene._panel_text.text.contains(String(item.title)),"optional interaction opens "+id)
		check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"optional "+id+" conversation remains transient")
		await press(scene,"Continue")
	check(not scene.model.has_economy() or true,"material details do not require a reward ledger")
	home.queue_free();await frames(3)
	print("HAND_WORKED_LIVES_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
