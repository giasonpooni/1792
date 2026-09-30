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
	var d: Vector3=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap_e(scene: Node3D) -> void:
	var e:=InputEventKey.new();e.keycode=KEY_E;e.pressed=true;scene._unhandled_input(e);await frames(2)
func press(scene: Node3D,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button is Button and button.text.begins_with(prefix): button.pressed.emit();await frames(2);return
	check(false,"missing button "+prefix)
func invited() -> State:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed inquiry fixture")
	ok(Pose.pose(model,Supply.MARKET),"market fixture");ok(model.begin_brawl(),"existing invitation")
	return model
func align_detail(scene: Node3D,item: Dictionary) -> bool:
	var offsets: Array[Vector3]=[Vector3(0,0,1.15),Vector3(1.15,0,0),Vector3(0,0,-1.15),Vector3(-1.15,0,0)]
	for offset in offsets:
		var p:=Vector3(item.position.x+offset.x,.14,item.position.z+offset.z)
		if not Pose.pose(scene.model,p).is_empty(): continue
		var snap: Dictionary=scene.model.snapshot()
		for i in [3,4]: snap.youth_brawl.actors[i].position=Base.coords(p+Vector3(-.8 if i==3 else .8,0,1.05))
		if not scene.model.restore(snap).is_empty(): continue
		scene._apply();look(scene,item.focus)
		if scene._seen(item.focus,2.8): return true
	return false
func authority_record(scene: Node3D) -> Dictionary:
	var b: Dictionary=scene.model.brawl()
	return {"events":b.events.duplicate(true),"ledger":b.ledger.duplicate(true),"journal":scene.model.journal(),
		"economy":scene.model.economy().duplicate(true) if scene.model.has_economy() else {}}
func authority_same(scene: Node3D,before: Dictionary) -> bool:
	var b: Dictionary=scene.model.brawl()
	return b.events==before.events and b.ledger==before.ledger and scene.model.journal()==before.journal and (not scene.model.has_economy() or scene.model.economy()==before.economy)
func run() -> void:
	var home: Node3D=Launch.make_world();var scene: Node3D=home.get_node("ChildhoodChapter")
	var model: State=invited();ok(scene.model.restore(model.snapshot()),"restore invited detail fixture")
	root.add_child(home);scene._apply();await frames(8)
	var stage: Node3D=scene.material_memory
	check(is_instance_valid(stage),"material-memory stage attached to existing Home")
	check(stage.get_meta("classification","")=="original-fictional-material-memory","explicit fictional craft classification")
	check(stage.details.size()==3,"exactly three hand-authored material stories")
	check(stage.find_children("*","CollisionShape3D",true,false).is_empty() and stage.find_children("*","StaticBody3D",true,false).is_empty(),"details add no collision or physics authority")
	var records: Array=stage.get("details");var ids: Array[String]=[]
	for raw in records:
		var detail_record: Dictionary=raw;ids.append(String(detail_record.id))
		var found: Dictionary=stage.call("nearest",detail_record.position)
		check(found.id==detail_record.id,"detail is locally discoverable "+String(detail_record.id))
		check(String(detail_record.description).length()>40 and String(detail_record.with_friends).contains("BUDDH"),"detail carries object description and original dialogue "+String(detail_record.id))
	check(ids==["pale_repair","hidden_colour","kept_place"],"stable authored detail order")
	var far: Dictionary=stage.call("nearest",Vector3.ZERO);check(far.is_empty(),"far world position discovers no detail")
	var detail: Dictionary=stage.call("record","pale_repair")
	check(align_detail(scene,detail),"repaired basket has at least one clear physical inspection stance")
	var before: Dictionary=authority_record(scene);var tick_before: int=int(scene.model.progress().tick)
	await tap_e(scene)
	check(scene._panel.visible and scene._panel_text.text.contains("THE PALE REPAIR"),"physical E interaction opens repaired-basket scene")
	check(scene._panel_text.text.contains("JIVA") and scene._panel_text.text.contains("MELA"),"nearby physical friends join the optional exchange")
	check(authority_same(scene,before),"inspection adds no receipts, outcome, inventory, money or journal fact")
	check(int(scene.model.progress().tick)==tick_before+1,"interaction consumes only the normal input physics tick before dialogue pause")
	await press(scene,"Continue")
	# Broad cube centered on the current eye-to-object line: actual physics obstruction, not a mocked visibility result.
	var wall: MeshInstance3D=scene._box(Vector3(1.2,2.5,1.2),(scene.avatar.global_position+detail.focus)*.5+Vector3.UP*.55,Color.GRAY,true)
	await frames(2);look(scene,detail.focus);before=authority_record(scene);await tap_e(scene)
	check(not scene._panel.visible and scene._message.contains("clear sight"),"new obstruction refuses stale object access")
	check(authority_same(scene,before),"blocked inspection changes no receipts, outcome, economy or journal")
	wall.get_parent().queue_free();await frames(3)
	for id in ["hidden_colour","kept_place"]:
		var item: Dictionary=stage.call("record",id)
		var next: State=invited();ok(scene.model.restore(next.snapshot()),"restore "+id+" invitation");scene._apply()
		check(align_detail(scene,item),"clear physical inspection stance exists for "+id)
		before=authority_record(scene);tick_before=int(scene.model.progress().tick);await tap_e(scene)
		check(scene._panel.visible and scene._panel_text.text.contains(String(item.title)),"optional interaction opens "+id)
		check(authority_same(scene,before),"optional "+id+" conversation remains receipt/economy/journal neutral")
		check(int(scene.model.progress().tick)==tick_before+1,"optional "+id+" consumes only normal input tick")
		await press(scene,"Continue")
	home.queue_free();await frames(3)
	print("HAND_WORKED_LIVES_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
