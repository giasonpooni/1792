# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State := preload("res://territory/gujranwala_state.gd")
const Water := preload("res://territory/water_round_rules.gd")
const View := preload("res://territory/water_round_view.gd")
const Rules := preload("res://territory/misl_rules.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Launch := preload("res://childhood/home_launch.gd")
const WELL_STAND := Vector3(26,0.14,14)
const SAVE := "user://water-round-regression-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(action.call()).is_empty(),label+" rejected")
	check(model.snapshot()==before,label+" is atomic")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func fresh() -> State:
	var s:=State.new()
	ok(s.restore(Fixture.complete()),"explicit completed-inquiry fixture")
	ok(s.begin_allowance(),"same allowance authority")
	ok(s.begin_water_round(),"assign water round")
	return s
func _domain() -> void:
	var s:=State.new()
	reject(s,s.begin_water_round,"no water task before inquiry/allowance")
	ok(s.restore(Fixture.complete()),"legacy completed inquiry accepted")
	check(not s.has_water_round(),"legacy import invents no water")
	s=fresh()
	reject(s,s.begin_water_round,"assignment only once")
	var money: Dictionary=s.economy().ledger.duplicate(true)
	reject(s,s.water_action.bind("filled"),"player cannot fabricate completion")
	reject(s,s.water_action.bind("draw"),"cannot draw from the store")
	reject(s,s.water_action.bind("deposit"),"cannot deposit empty carrier")
	ok(Pose.pose(s,WELL_STAND),"explicit well fixture")
	ok(s.water_action("draw"),"start timed drawing")
	reject(s,s.water_action.bind("draw"),"draw cannot be queued twice")
	reject(s,s.mount,"mount during draw")
	reject(s,s.rest_watch,"rest cannot finish a draw offscreen")
	for _i in range(179): s.advance()
	check(s.water_round().ledger.phase=="drawing" and s.water_round().ledger.remaining==6,"no transfer before completion")
	ok(s.save_to(SAVE),"save pending draw")
	var copy:=State.new()
	ok(copy.load_from(SAVE),"load pending draw")
	check(Rules._equal(s.snapshot(),copy.snapshot()),"whole session including draw roundtrips")
	s.advance();copy.advance()
	check(Rules._equal(s.snapshot(),copy.snapshot()),"next tick completes identically after load")
	check(s.water_round().ledger.carried==3 and s.water_round().ledger.remaining==3,"one transfer on exact tick")
	for _i in range(5): s.advance()
	check(s.water_round().ledger.carried==3 and s.water_round().events.size()==2,"completion is not repeated")
	reject(s,s.mount,"cannot mount with open carrier")
	reject(s,s.water_action.bind("deposit"),"well is not household store")
	reject(s,s.record_position.bind(s.position()+Vector3(0.16,0,0),1.0/60),"model enforces carrying bound")
	ok(Pose.pose(s,Water.STORE-Vector3(0,0,1)),"explicit store fixture")
	ok(s.water_action("deposit"),"deposit once")
	check(s.water_round().ledger.stored==3 and s.water_round().ledger.carried==0,"store and carried balance")
	reject(s,s.water_action.bind("deposit"),"no repeated deposit")
	ok(Pose.pose(s,WELL_STAND),"second-trip fixture")
	ok(s.water_action("draw"),"second draw")
	for _i in range(180): s.advance()
	ok(Pose.pose(s,Water.STORE-Vector3(0,0,1)),"second return fixture")
	ok(s.water_action("deposit"),"complete finite round")
	check(s.water_round().ledger.phase=="complete" and s.water_round().ledger.stored==6,"six assigned units delivered")
	check(s.economy().ledger==money,"water does not mint currency or rewrite supply recipes")
	check(s.snapshot().player.known_places==["sukerchakia_home"],"no invented historical/map knowledge")
	ok(Pose.pose(s,WELL_STAND),"completed well fixture")
	reject(s,s.water_action.bind("draw"),"no infinite round")
	for what in ["quantity","origin","seq","future","early","pose","actor","extra","model","bool","nan","duplicate","without_allowance"]:
		var bad:=s.snapshot()
		match what:
			"quantity": bad.water_round.ledger.stored=999
			"origin": bad.water_round.origin_tick=-1
			"seq": bad.water_round.events[0].seq=12
			"future": bad.water_round.events[-1].tick=bad.childhood.tick+1
			"early": bad.water_round.events[1].tick=bad.water_round.events[0].tick+179
			"pose": bad.water_round.events[0].position=[0,0.14,0]
			"actor": bad.water_round.events[0].actor_id="shah_muhammad"
			"extra": bad.water_round.secret_reward=200
			"model": bad.water_round.model_id="different"
			"bool": bad.water_round.ledger.stored=true
			"nan": bad.water_round.events[0].position=[NAN,0,0]
			"duplicate": bad.water_round.events.append(bad.water_round.events[-1].duplicate(true))
			"without_allowance": bad.erase("misl")
		reject(s,s.restore.bind(bad),"tamper "+what)
	var detached:=s.water_round()
	detached.ledger.stored=100
	check(s.water_round().ledger.stored==6,"read is detached")
	# Cancellation preserves the full assignment, including leaving the interaction radius.
	s=fresh();ok(Pose.pose(s,WELL_STAND),"cancellation fixture")
	ok(s.water_action("draw"),"draw for cancellation")
	for _i in range(90):s.advance()
	ok(s.water_action("cancel"),"cancel drawing")
	check(s.water_round().ledger.remaining==6 and s.water_round().ledger.carried==0,"cancellation does not consume water")
	ok(s.water_action("draw"),"restart cancelled draw")
	for _i in range(10): ok(s.record_position(s.position()+Vector3(0.12,0,0),0.02),"admitted movement away")
	check(s.water_round().ledger.phase=="ready","walking away cancels immediately")
	ok(s.validate(s.snapshot()),"cancelled snapshot valid")
	# Restore old checkpoints as whole earlier sessions, never retaining later water.
	ok(s.restore(Fixture.complete()),"restore whole old profile")
	check(not s.has_water_round() and not s.has_economy(),"old profile rolls back water and allowance together")
	# Bounded receipt budget reserves the last fill/deposit, so carried water is not stranded.
	s=fresh();ok(Pose.pose(s,WELL_STAND),"receipt budget fixture")
	for _i in range(62):
		ok(s.water_action("draw"),"bounded draw")
		ok(s.water_action("cancel"),"bounded cancel")
	ok(s.water_action("draw"),"last reserved draw")
	for _i in range(180):s.advance()
	ok(Pose.pose(s,Water.STORE-Vector3(0,0,1)),"budget return fixture")
	ok(s.water_action("deposit"),"reserved deposit is still possible")
	ok(Pose.pose(s,WELL_STAND),"budget revisit")
	reject(s,s.water_action.bind("draw"),"receipt ceiling refuses next draw")
	ok(s.validate(s.snapshot()),"bounded task can be saved without blocking other play")
	DirAccess.remove_absolute(SAVE)

func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,code: Key) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true
	scene._unhandled_input(e)
	await frames(2)
func press(scene,prefix: String) -> void:
	for b in scene._actions.get_children():
		if b.text.begins_with(prefix):
			b.pressed.emit()
			await frames(2)
			return
	check(false,"UI action missing: "+prefix)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1400):
		if State.distance(scene.avatar.global_position,p)<0.42: reached=true;break
		look(scene,p)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(8)
	if not reached: print("WATER ROUTE: ",scene.avatar.global_position," wanted ",p," notice ",scene._message)
	check(reached,"input-driven walk "+str(p))
func _journey() -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://water-round-scene-only.json"
	ok(scene.model.restore(Fixture.complete()),"explicit post-inquiry scene start")
	root.add_child(home)
	await frames()
	look(scene,Rules.QUARTERMASTER)
	await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Accept household water round")
	check(scene.model.has_water_round(),"UI assigns task through existing authority")
	check(State.distance(scene.fabric.get_node("household_well").global_position,Water.WELL)<0.01,"task binds existing well geometry")
	check(Water.STORE==Rules.QUARTERMASTER,"task reuses existing household endpoint")
	for trip in range(2):
		await walk(scene,Vector3(2,0.14,-10))
		await walk(scene,Vector3(26,0.14,-10))
		await walk(scene,WELL_STAND)
		look(scene,Water.WELL)
		await tap(scene,KEY_E)
		await press(scene,"Draw one load")
		check(scene.model.water_round().ledger.phase=="drawing","UI starts timed well action")
		if trip==0:
			await frames(50)
			await tap(scene,KEY_F2)
			var frozen: Dictionary=scene.model.snapshot()
			await frames(40)
			check(scene.model.snapshot()==frozen,"notebook freezes draw and supply clock together")
			ok(scene.model.save_to(scene.save_path),"pending action saved in original slot")
			scene._resume()
			await frames(185)
			check(scene.model.water_round().ledger.phase=="carrying","draw completed once")
			scene._load()
			check(scene.model.water_round().ledger.phase=="drawing","load restores pending not completed action")
		await frames(185)
		check(scene.model.water_round().ledger.carried==3,"physical draw fills one carrier")
		check(scene.water_view.carried.visible,"carried water is represented on player")
		check(scene.avatar.external_speed_limit==3.0,"loaded carrier caps actual movement speed")
		await walk(scene,Vector3(26,0.14,-10))
		await walk(scene,Vector3(2,0.14,-10))
		await walk(scene,Vector3(3,0.14,4))
		look(scene,Rules.QUARTERMASTER)
		await tap(scene,KEY_E);await press(scene,"Deposit carried water")
		check(scene.model.water_round().ledger.stored==3*(trip+1),"input-driven deposit balances store")
		check(not scene.water_view.carried.visible and is_inf(scene.avatar.external_speed_limit),"unloaded movement returns to original defaults")
	check(scene.model.water_round().ledger.phase=="complete","two whole physical trips complete")
	check(scene.water_view.tank_water.visible,"household vessel reflects delivered state")
	ok(scene.model.save_to(scene.save_path),"complete session saves")
	var before: Dictionary=scene.model.snapshot()
	var task_hash: String=JSON.stringify(before.water_round,"",true,true).sha256_text()
	var audit: Dictionary={"schema":"1792.water-round-observation.v1","evidence_kind":"synthetic_validation","operation_id":"water-round-native-conformance.v1","model_id":Water.MODEL_ID,"execution_source_sha":OS.get_environment("GITHUB_SHA"),"engine":Engine.get_version_info().string,"passed":passed,"failed":failed,"layout_sha256":scene.fabric.digest,"task_snapshot_sha256":task_hash,"stored_units":before.water_round.ledger.stored,"historical_truth_verified":false}
	var out:=FileAccess.open("user://water-round-audit.json",FileAccess.WRITE)
	if out==null:check(false,"audit retained")
	else:out.store_string(JSON.stringify(audit,"\t"));out.close()
	DirAccess.remove_absolute(scene.save_path)
	home.queue_free()
	await frames()
func _run() -> void:
	_domain()
	await _journey()
	print("WATER_ROUND_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
