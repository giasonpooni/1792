# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State:=preload("res://misl/service_state.gd")
const Service:=preload("res://misl/service_rules.gd")
const View:=preload("res://misl/service_presentation.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const SAVE:="user://service-story-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(test: bool,label: String) -> void:
	if test: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func fresh() -> State:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed inquiry setup fixture")
	ok(model.begin_allowance(),"existing allowance");ok(model.begin_service(),"existing brief")
	ok(model.operate("hire","guard"),"existing guard");ok(model.rest_watch(),"existing supplied watch")
	return model
func hear(model,route: String) -> void:
	ok(Pose.pose(model,Service.SITES[route]),"speaker setup fixture")
	ok(model.service_action("hear",route),"receive local request")
	ok(Pose.pose(model,Supply.QUARTERMASTER+Vector3(0,0,-1)),"quartermaster setup fixture")
func travel(model,target: Vector3) -> void:
	# Domain-only movement receipts; the inherited native service suite separately
	# proves both real collision-driven journeys. No invented arrival event here.
	for _i in range(2000):
		if model.service().ledger.stage not in ["outbound","returning"]: break
		var record: Dictionary=model.service().agent
		var position:=Base.point(record.position)
		if position.distance_to(target)<1.2: break
		var next:=position.move_toward(target,Service.SPEED/60.0)
		record.position=Base.coords(next);record.velocity=Base.coords((next-position)*60)
		var error: String=model.record_service_motion(record,1.0/60.0)
		if not error.is_empty(): check(false,"bounded route: "+error);return
		model.advance();model.progress_service()
func returned() -> State:
	var model:=fresh();hear(model,"market");ok(model.service_action("dispatch","market"),"dispatch original guard")
	travel(model,Service.SITES.market)
	check(model.service().ledger.stage=="attending","actual receipt location admits attendance")
	check(View.received_account(model.service().ledger).is_empty(),"onsite progress reveals no account")
	for _i in range(Service.SERVICE_TICKS): model.advance();model.progress_service()
	travel(model,Service.home(0));model.progress_service()
	check(model.service().ledger.stage=="awaiting_account","return requires actual movement receipts")
	return model
func domain() -> void:
	check(View.request("market").contains("carts") and View.request("well").contains("pots"),"different immediate needs")
	check(View.request("market")!=View.request("well"),"request voices are distinct")
	check(View.request("unknown").is_empty(),"unknown route has no invented speech")
	var model:=returned();var before: Dictionary=model.snapshot()
	check(View.received_account(model.service().ledger).is_empty(),"physical return alone does not disclose testimony")
	View.quartermaster_context(model.service().ledger)
	check(model.snapshot()==before,"presentation never mutates the saved account")
	ok(model.save_to(SAVE),"save returned unheard guard")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load returned unheard guard")
	check(View.received_account(loaded.service().ledger).is_empty(),"load cannot turn return into receipt")
	ok(model.service_action("debrief"),"hear actual report")
	var line:=View.received_account(model.service().ledger)
	check(line.contains(Service.ACCOUNTS.market),"closure retains exact market testimony")
	check(not line.contains(Service.ACCOUNTS.well),"closure cannot borrow the other route's testimony")
	check(line.ends_with("Take your place again."),"received report gets human closing beat")
	before=model.snapshot()
	check(not model.service_action("debrief").is_empty(),"second debrief refused")
	check(model.snapshot()==before,"duplicate debrief adds no receipt or closing reward")
	var unsupported:=Service.initial();unsupported.completed=["market"]
	check(View.received_account(unsupported).is_empty(),"completion list alone cannot authorize speech")
	ok(model.validate(model.snapshot()),"completed story remains schema-valid")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func press(scene,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix): button.pressed.emit();await frames(2);return
	check(false,"missing UI action "+prefix)
func scene_checks() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	var model:=fresh();hear(model,"market");ok(scene.model.restore(model.snapshot()),"service setup fixture")
	root.add_child(home);await frames(8);look(scene,Supply.QUARTERMASTER)
	var id: int=scene.service_agent.get_instance_id();var rid: RID=scene.service_agent.get_rid()
	check(not scene.service_agent.visible and scene._guard_posts[0].visible,"guard begins at original home post")
	scene._menu_action("service:dispatch|market");await frames()
	check(not scene.model.service_reserved(),"unoffered service callback is inert")
	scene._open_quartermaster();scene._resume();scene._menu_action("service:dispatch|market");await frames()
	check(not scene.model.service_reserved(),"closed service dialog cannot dispatch")
	scene._open_quartermaster()
	var wall:=StaticBody3D.new();wall.collision_layer=1
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(2,3,0.2);shape.shape=box;wall.add_child(shape)
	scene.add_child(wall);wall.global_position=Supply.QUARTERMASTER+Vector3(0,1,-0.5);await frames()
	await press(scene,"Commit one provisioned guard")
	check(not scene.model.service_reserved(),"new obstruction blocks queued dispatch")
	wall.queue_free();await frames();look(scene,Supply.QUARTERMASTER)
	scene._open_quartermaster();await press(scene,"Commit one provisioned guard")
	check(scene.model.service_reserved(),"clear actual button dispatches")
	check(scene.service_agent.visible and not scene._guard_posts[0].visible,"one visible guard representation during absence")
	check(scene.service_agent.get_instance_id()==id and scene.service_agent.get_rid()==rid,"presentation retains exact actor and collision body")
	check(scene._service_satchel.get_parent()==scene.service_agent and scene._service_satchel.visible,"carried prop belongs to dispatched guard")
	check(scene._message.begins_with("Guard ·") and not scene._message.contains("Recorded:"),"departure is voiced as intention")
	var count: int=scene.model.service().events.size()
	scene._menu_action("service:dispatch|market");await frames()
	check(scene.model.service().events.size()==count,"repeated stale callback does not duplicate dispatch")
	await frames(48)
	check(scene._service_satchel.position.is_equal_approx(Vector3(0.34,0.86,0.12)),"carried prop settles on existing tick")
	check(scene.model.journal().filter(func(m):return m.id.begins_with("service-account-")).is_empty(),"native absence adds no remote report")
	ok(scene.model.save_to(SAVE),"save live service guard")
	scene._load();await frames()
	check(scene.service_agent.get_instance_id()==id and scene.service_agent.get_rid()==rid,"save/load does not spawn replacement actor")
	check(scene._service_satchel.visible and not scene._guard_posts[0].visible,"save/load preserves absence and carried staging")
	# Restore an explicitly prepared returned state to target debrief UI boundaries.
	var returned_model:=returned();ok(scene.model.restore(returned_model.snapshot()),"returned setup fixture")
	scene._apply();await frames(8);look(scene,Supply.QUARTERMASTER)
	scene._open_quartermaster();check(not scene._panel_text.text.contains(Service.ACCOUNTS.market),"offered debrief has no premature account")
	await press(scene,"Hear the returned guard")
	check(scene.model.service().ledger.completed==["market"],"button receives one report")
	check(scene._message.contains(Service.ACCOUNTS.market),"native closure contains only now-received account")
	check(not scene.service_agent.visible and scene._guard_posts[0].visible and not scene._service_satchel.visible,"debrief restores same home post and removes carried prop")
	count=scene.model.service().events.size();scene._menu_action("service:debrief");await frames()
	check(scene.model.service().events.size()==count,"closed debrief callback cannot repeat receipt")
	ok(scene.model.validate(scene.model.snapshot()),"native completed state validates")
	home.queue_free();await frames()
func _run() -> void:
	domain();await scene_checks()
	for suffix in ["",".tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("SERVICE_STORY_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
