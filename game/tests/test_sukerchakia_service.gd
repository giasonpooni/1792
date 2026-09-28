# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State:=preload("res://misl/service_state.gd")
const R:=preload("res://misl/service_rules.gd")
const Notes:=preload("res://misl/service_notes.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const SAVE:="user://service-regression-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(test: bool,label: String) -> void:
	if test: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(action.call()).is_empty(),label+" refuses")
	check(model.snapshot()==before,label+" preserves state")
func fresh(hire: bool=true) -> State:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed inquiry fixture")
	ok(model.begin_allowance(),"old household allowance")
	ok(model.begin_service(),"service brief")
	if hire:
		ok(model.operate("hire","guard"),"existing hire")
		ok(model.rest_watch(),"existing supplied watch")
	return model
func hear(model,route: String) -> void:
	ok(Pose.pose(model,R.SITES[route]),"speaker fixture")
	ok(model.service_action("hear",route),"local request")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"return fixture")
func _domain() -> void:
	var model:=State.new();reject(model,model.begin_service,"no service before household inquiry")
	model=fresh(false)
	reject(model,model.begin_service,"one service brief")
	reject(model,model.service_action.bind("dispatch","market"),"cannot dispatch to an unheard request")
	hear(model,"market")
	reject(model,model.service_action.bind("dispatch","market"),"cannot invent a guard")
	ok(model.operate("hire","guard"),"hire through old authority")
	reject(model,model.service_action.bind("dispatch","market"),"unprovisioned hire is not deployable")
	ok(model.rest_watch(),"provision through original watch")
	var funds: Dictionary=model.economy().ledger.duplicate(true)
	ok(model.service_action("dispatch","market"),"dispatch same guard")
	check(model.economy().ledger==funds,"dispatch creates no money, men or stock")
	check(model.service().ledger.slot==0 and model.service().agent.id==R.identity(0),"single existing slot reserved")
	reject(model,model.service_action.bind("dispatch","well"),"no simultaneous second duty")
	reject(model,model.operate.bind("release_guard"),"reserved guard cannot be dismissed")
	reject(model,model.rest_watch,"no time skipping moving detail")
	reject(model,model.service_action.bind("home"),"player cannot invent arrival")
	reject(model,model.service_action.bind("debrief"),"no report while guard is away")
	var tele:=R.motion(0);tele.position=Base.coords(R.SITES.market)
	reject(model,model.record_service_motion.bind(tele,1.0/60),"no teleport")
	for mutate in ["ledger","event","supply","agent"]:
		var bad: Dictionary=model.snapshot()
		match mutate:
			"ledger": bad.service.ledger.completed=["market"]
			"event": bad.service.events[-1].tick+=1
			"supply": bad.service.events[-1].economy_seq=0
			"agent": bad.service.agent.id="another_guard"
		reject(model,model.restore.bind(bad),"tampered "+mutate)
	var bad: Dictionary=model.snapshot()
	bad.misl.events.append({"seq":bad.misl.events.size()+1,"tick":bad.childhood.tick,"kind":"release_guard","arg":""})
	ok(Supply.apply(bad.misl.ledger,"release_guard",""),"syntactically valid hostile release fixture")
	reject(model,model.restore.bind(bad),"cross-ledger release of committed guard")
	ok(model.save_to(SAVE),"save active service")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load active service")
	check(Supply._equal(model.snapshot(),loaded.snapshot()),"state/receipts/money roundtrip")
	var copy: Dictionary=model.service();copy.ledger.slot=2
	check(model.service().ledger.slot==0,"detached service query")
	# Shortage occurs through the real supply rules, not fabricated readiness flags.
	for _i in range(10*Supply.WATCH_TICKS): model.advance()
	check(not model.service_ready(),"shortage holds existing detail")
	tele=model.service().agent;tele.position[0]+=0.02
	reject(model,model.record_service_motion.bind(tele,1.0/60),"held guard cannot move")
	ok(Pose.pose(model,Supply.MARKET),"restock fixture")
	ok(model.operate("buy","food"),"original food purchase")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"restock return")
	ok(model.rest_watch(),"rest held detail without moving agent")
	check(model.service_ready(),"paid supplied watch restores readiness")
	ok(model.validate(model.snapshot()),"cross-ledger state revalidates")
	ok(model.restore(Fixture.complete()),"older save replacement")
	check(not model.has_service() and not model.has_economy(),"no future services retained by rewind")

func _coexistence() -> void:
	# Independent tasks share one saved world and tick, not each other's resources.
	var model:=fresh()
	ok(model.begin_water_round(),"retained main water task begins")
	hear(model,"market")
	ok(model.service_action("dispatch","market"),"service coexists with water task")
	ok(Pose.pose(model,Vector3(26,0.14,14)),"combined well fixture")
	ok(model.water_action("draw"),"existing water draw while guard committed")
	for _i in range(179): model.advance()
	ok(model.save_to(SAVE),"save committed guard and pending draw together")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"restore both task histories")
	check(Supply._equal(loaded.snapshot(),model.snapshot()),"both histories roundtrip exactly")
	var service_before: Dictionary=model.service()
	model.advance();loaded.advance()
	check(Supply._equal(loaded.snapshot(),model.snapshot()),"same tick finishes only the water draw")
	check(model.water_round().ledger.carried==3 and model.service()==service_before,"water transfer does not fabricate guard movement")
	reject(model,model.mount,"water carrier constraint still applies")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"combined store fixture")
	ok(model.water_action("deposit"),"existing deposit remains usable")
	check(model.service_reserved() and model.water_round().ledger.stored==3,"no cross-task reward or cancellation")
	ok(model.validate(model.snapshot()),"combined task state validates")

func _catalogue() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Notes.PATH))
	ok(Notes.validate(data),"catalogue resolves")
	for case in ["identity","year","source","claim","relation"]:
		var bad:=data.duplicate(true)
		match case:
			"identity": bad.nodes[1].kind="misl"
			"year": bad.year=1845
			"source": bad.sources[0].url="file:///private/source"
			"claim": bad.relations[0].claim_id="unknown"
			"relation": bad.relations[1].to="ranjit_singh"
		check(not Notes.validate(bad).is_empty(),"refuse unsupported research "+case)
	check(Notes.notebook().contains("NOT BUDDH'S KNOWLEDGE"),"research is not hero memory")

func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true
	scene._unhandled_input(e);await frames(2)
func press(scene,text: String) -> void:
	for b in scene._actions.get_children():
		if b.text.begins_with(text): b.pressed.emit();await frames(2);return
	check(false,"missing UI "+text)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1200):
		if Base.distance(scene.avatar.global_position,p)<0.55: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(6)
	if not reached: print("SERVICE WALK: ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(reached,"physical walk "+str(p))

func _journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"only journey start is a completed-inquiry fixture")
	root.add_child(home);await frames(5)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Hear the Sukerchakia")
	await tap(scene,KEY_E);await press(scene,"Hire a garrison guard")
	await tap(scene,KEY_E);await press(scene,"Rest until next")
	check(scene.model.economy().ledger.guards==1,"UI hires exactly one existing guard")
	for p in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-14)]: await walk(scene,p)
	look(scene,Supply.MARKET);await tap(scene,KEY_E);await press(scene,"Hear the handler")
	for p in [Vector3(-13,0,-11),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Commit one provisioned guard")
	check(scene.model.service_reserved(),"actual dispatch UI")
	check(scene.service_agent.visible and not scene._guard_posts[0].visible,"guard is not present at home and away twice")
	check(scene.model.journal().filter(func(m):return m.id.begins_with("service-account-")).is_empty(),"no remote report in journal")
	await frames(60);await tap(scene,KEY_B)
	var frozen: Dictionary=scene.model.snapshot();await frames(40)
	check(scene.model.snapshot()==frozen,"one modal clock freezes physical detail")
	scene._resume();await tap(scene,KEY_F5)
	var saved: Dictionary=scene.model.snapshot();await frames(30);await tap(scene,KEY_F9)
	check(Base.distance(scene.service_agent.global_position,Base.point(saved.service.agent.position))<0.3,"mid-route load preserves actual guard position")
	var attended:=false
	for _i in range(6500):
		var s: Dictionary=scene.model.service().ledger
		if s.stage=="attending":
			if not attended: check(Base.distance(scene.service_agent.global_position,R.SITES.market)<=1.7,"guard reaches actual market")
			attended=true
		if s.stage=="awaiting_account": break
		await physics_frame
	if scene.model.service().ledger.stage!="awaiting_account": print("SERVICE AGENT DIAG: ",scene.model.service()," / ",scene._message)
	check(attended and scene.model.service().ledger.stage=="awaiting_account","physical roundtrip and attendance complete")
	check(scene.model.journal().filter(func(m):return m.id.begins_with("service-account-")).is_empty(),"return alone does not give unheard testimony")
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Hear the returned guard")
	check(scene.model.service().ledger.completed==["market"],"one received account")
	check(not scene.service_agent.visible and scene._guard_posts[0].visible,"same guard slot returns to home representation")
	check(scene.model.economy().ledger.guards==1,"no duplicate manpower")
	ok(scene.model.validate(scene.model.snapshot()),"completed service validates")
	# Second route heard in person, not disclosed by opening the research notebook.
	for p in [Vector3(2,0,-10),Vector3(24,0,-10),Vector3(24,0,10)]: await walk(scene,p)
	look(scene,Vector3(26.3,1.7,10));await tap(scene,KEY_E);await press(scene,"Hear the well-approach")
	check(scene.model.service().ledger.heard.has("well"),"physical well request")
	for p in [Vector3(24,0,-10),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Commit one provisioned guard")
	for _i in range(6500):
		if scene.model.service().ledger.stage=="awaiting_account": break
		await physics_frame
	check(scene.model.service().ledger.stage=="awaiting_account","well roundtrip complete")
	await tap(scene,KEY_E);await press(scene,"Hear the returned guard")
	check(scene.model.service().ledger.completed==["market","well"],"both finite requests fulfilled")
	ok(scene.model.validate(scene.model.snapshot()),"second account validates")
	await tap(scene,KEY_F2);frozen=scene.model.snapshot();await frames(12)
	check(scene.model.snapshot()==frozen and scene._panel_text.text.contains("SUKERCHAKIA"),"research notebook pauses without adding knowledge")
	check(scene._panel_text.text.contains(scene.fabric.digest),"earlier research notebook retained")
	var trace: Dictionary={"schema":"1792.service-test-evidence.v1","kind":"synthetic_engine_test","operation_id":"sukerchakia-service-conformance.v1",
		"engine":Engine.get_version_info().string,"service":scene.model.service(),"economy":scene.model.economy(),"tick":scene.model.progress().tick,"historical_truth_verified":false}
	var f:=FileAccess.open("user://sukerchakia-service-trace.json",FileAccess.WRITE);f.store_string(JSON.stringify(trace,"\t",true,true));f.close()
	home.queue_free();await frames()

func _run() -> void:
	_domain();_coexistence();_catalogue();await _journey()
	for suffix in ["",".tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("SUKERCHAKIA_SERVICE_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
