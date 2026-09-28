extends SceneTree
const State := preload("res://territory/gujranwala_state.gd")
const Rules := preload("res://territory/misl_rules.gd")
const Cell := preload("res://territory/home_cell.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Base := preload("res://childhood/childhood_state.gd")
const SAVE := "user://gujranwala-regression-only.json"
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
	check(not str(action.call()).is_empty(),label+" refuses")
	check(model.snapshot()==before,label+" unchanged")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,code: Key) -> void:
	var e:=InputEventKey.new()
	e.keycode=code;e.pressed=true
	scene._unhandled_input(e)
	await frames(2)
func press(scene,text: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(text):
			button.pressed.emit()
			await frames(2)
			return
	check(false,"missing UI action "+text)
func walk(scene,p: Vector3,slow: bool=false) -> void:
	var reached:=false
	for _i in range(1100):
		if Base.distance(scene.avatar.global_position,p)<0.55:
			reached=true;break
		look(scene,p)
		# Follow the physically moving caravan rather than teleporting it to the player.
		if not slow or Base.distance(scene.avatar.global_position,scene.merchant.global_position)<6:
			Input.action_press("move_forward")
		else: Input.action_release("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(10)
	if not reached: print("ROUTE DIAG: actor=",scene.avatar.global_position," merchant=",scene.merchant.global_position," notice=",scene._message," paused=",scene._paused," waypoint=",scene._navigation.waypoint(scene.merchant.global_position,Rules.QUARTERMASTER))
	check(reached,"physical walk "+str(p))
func fresh() -> State:
	var s:=State.new()
	ok(s.restore(Fixture.complete()),"legacy inquiry import")
	ok(s.begin_allowance(),"start one bounded allowance")
	return s

func _domain() -> void:
	var s:=State.new()
	reject(s,s.begin_allowance,"no economy in tutorial")
	s=fresh()
	check(s.economy().ledger.treasury==120 and s.economy().ledger.purse==18,"separate funds")
	reject(s,s.begin_allowance,"no duplicated allowance")
	reject(s,s.operate.bind("withdraw_private"),"cannot withdraw coffers")
	reject(s,s.operate.bind("watch"),"cannot fabricate economic time")
	reject(s,s.operate.bind("buy","feed"),"cannot shop from home")
	ok(s.operate("hire","guard"),"hire guard")
	check(s.economy().ledger.guards==1 and s.economy().ledger.treasury==98,"hire incurs upfront cost")
	ok(s.operate("hire","worker"),"hire worker")
	var need:=Rules.due(s.economy().ledger)
	check(need.food==4 and need.wages==4 and need.feed==2,"coupled upkeep rises with hires")
	ok(s.operate("build","palisade"),"start real resource-backed build")
	check(s.economy().ledger.stock.timber==2 and s.economy().ledger.stock.tools==1,"materials consumed once")
	reject(s,s.operate.bind("build","mill"),"no parallel labor double-spend")
	var old_tick: int=s.progress().tick
	ok(s.rest_watch(),"rest advances existing clock")
	check(s.progress().tick>old_tick and s.economy().ledger.watch==1,"one clock and one settled watch")
	check(s.economy().ledger.work_left==4 and s.economy().ledger.stock.grain==8,"workers build instead of producing")
	ok(s.rest_watch(),"second work watch")
	check(s.economy().ledger.work_left==2,"additional worker changes completion time")
	ok(s.operate("meeting"),"attend within meeting window")
	check(s.economy().ledger.meeting=="attended","meeting remembered")
	reject(s,s.operate.bind("meeting"),"no repeat meeting reward")
	ok(s.rest_watch(),"third watch shortage")
	check(s.economy().ledger.work_left==2 and s.economy().ledger.duty_guards==0,"short food stalls work and guard readiness")
	ok(Pose.pose(s,Rules.MARKET),"explicit domain market fixture")
	ok(s.operate("buy","food"),"replenish food with treasury")
	ok(Pose.pose(s,Rules.QUARTERMASTER),"explicit domain home fixture")
	ok(s.rest_watch(),"resume after replenishment")
	check("palisade" in s.economy().ledger.built,"project finishes after provisioned work")
	check(s.economy().ledger.treasury>=0,"treasury never negative")
	ok(s.save_to(SAVE),"save coupled state")
	var loaded:=State.new()
	ok(loaded.load_from(SAVE),"load coupled state")
	check(Rules._equal(loaded.economy(),s.economy()),"economic ledger and causal receipts reproduce")
	for what in ["money","food","bool","time","seq","missing_watch","kind","seed","extra","merchant","warp"]:
		var bad:=s.snapshot()
		match what:
			"money":bad.misl.ledger.treasury+=1
			"food":bad.misl.ledger.stock.food=-1
			"bool":bad.misl.ledger.guards=true
			"time":bad.misl.origin_tick+=1
			"seq":bad.misl.events[0].seq=200
			"missing_watch":bad.misl.events.remove_at(3)
			"kind":bad.misl.events[0].kind="free_money"
			"seed":bad.misl.seed=6
			"extra":bad.misl.ledger.hidden_knowledge="culprit"
			"merchant":bad.misl.merchant.id="other"
			"warp":bad.misl.merchant.position=[1,0.14,1]
		reject(s,s.restore.bind(bad),"tamper "+what)
	var baseline: Dictionary=s.economy().ledger
	var forecast:=Rules.forecast(baseline)
	check(baseline==s.economy().ledger and forecast.scope=="next_watch_under_unchanged_choices","forecast is read-only and scoped")
	var detached:=s.economy()
	detached.ledger.purse=999
	check(s.economy().ledger.purse!=999,"read copies detached")
	var miss:=fresh()
	for _i in range(5):ok(miss.rest_watch(),"meeting clock")
	check(miss.economy().ledger.meeting=="missed","meeting miss settles")
	var favor: int=miss.economy().ledger.favor
	ok(miss.rest_watch(),"later watch")
	check(favor-miss.economy().ledger.favor<=4,"missed meeting penalty not repeated")
	var supply:=fresh()
	ok(supply.operate("accept_delivery"),"cargo dispatched")
	check(supply.economy().ledger.stock.food==6 and supply.economy().ledger.cargo==4,"cargo removed from store")
	reject(supply,supply.operate.bind("accept_delivery"),"no duplicate dispatch")
	ok(Pose.pose(supply,Rules.MARKET),"market fixture")
	ok(supply.operate("satchel"),"personal equipment purchase")
	check(supply.economy().ledger.purse==6 and supply.economy().ledger.treasury==120,"equipment not charged to coffers")
	ok(supply.operate("deliver"),"delivery paid")
	check(supply.economy().ledger.purse==22,"satchel premium uses same contract")
	reject(supply,supply.operate.bind("deliver"),"no reward farming")
	ok(supply.operate("accept_escort"),"caravan assigned")
	ok(Pose.pose(supply,Rules.QUARTERMASTER),"return fixture without caravan")
	reject(supply,supply.operate.bind("checkin"),"no remote caravan return")
	reject(supply,supply.rest_watch,"no resting past active escort")
	var motion:=Rules.blank_merchant()
	motion.position=[3,0.14,5]
	reject(supply,supply.record_merchant.bind(motion,1.0/60),"no merchant teleport")
	# Pure recipe/capacity economics tested separately from geography.
	var a:=Rules.initial()
	var b:=Rules.initial()
	b.built=["mill"]
	ok(Rules.apply(a,"watch",""),"base production")
	ok(Rules.apply(b,"watch",""),"upgraded production")
	check(b.stock.food>a.stock.food and b.stock.grain<a.stock.grain,"mill increases throughput and input consumption")
	a=Rules.initial();a.stock.food=200
	check(not Rules.apply(a.duplicate(true),"buy","food").is_empty(),"full storage blocks purchase")
	a=Rules.initial();a.treasury=0;a.guards=2
	Rules.apply(a,"watch","")
	check(a.arrears==5 and a.treasury==0 and a.duty_guards==0,"arrears and readiness when wages cannot be paid")
	var cell:=Cell.new()
	for p in Base.SITES.values():check(is_equal_approx(cell.height(p.x,p.z),0.1),"legacy site preserves flat support")
	check(cell.height(28,-28)>0.1,"outer field has real relief")
	cell.free()

func _journey() -> void:
	# Completed-inquiry fixture only. Thereafter real input, interactions, motion and saves.
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"install completed inquiry")
	root.add_child(home)
	await frames(5)
	check(scene.cell.manifest.id==Rules.CELL_ID and scene.cell.manifest.vertices==961,"procedural mesh built")
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(28,2,-28),Vector3(28,-1,-28),1)
	var terrain_hit: Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not terrain_hit.is_empty() and absf(terrain_hit.position.y-scene.cell.height(28,-28))<0.002,"generated field collision matches its height")
	var second:=Cell.new();root.add_child(second);second.build()
	check(second.manifest==scene.cell.manifest,"same seed regenerates the same mesh manifest")
	second.queue_free();await frames()
	look(scene,Rules.QUARTERMASTER)
	await tap(scene,KEY_E)
	check(scene._paused,"quartermaster dialogue opens")
	await press(scene,"Accept the limited")
	check(scene.model.has_economy(),"button releases allowance")
	await tap(scene,KEY_E)
	await press(scene,"Carry four")
	await walk(scene,Vector3(2,0,-10))
	await walk(scene,Vector3(-13,0,-11))
	await walk(scene,Vector3(-23,0,-14))
	look(scene,Rules.MARKET)
	await tap(scene,KEY_E)
	await press(scene,"Deliver")
	check(scene.model.economy().ledger.delivery=="delivered","actual delivery reached market")
	await tap(scene,KEY_E)
	await press(scene,"Escort a return")
	check(scene.merchant.visible,"assigned caravan appears physically")
	await frames(100)
	await tap(scene,KEY_B)
	var frozen: Dictionary=scene.model.snapshot()
	await frames(30)
	check(scene.model.snapshot()==frozen,"accounts pause motion and all upkeep")
	await press(scene,"Return")
	# Accompany the caravan along its actual collision-checked route rather than
	# insisting its independent navigator follow the test driver's waypoints.
	var saved_midway:=false
	for i in range(2200):
		if Base.distance(scene.merchant.global_position,Rules.QUARTERMASTER)<2.5: break
		if Base.distance(scene.avatar.global_position,scene.merchant.global_position)>2.5:
			look(scene,scene.merchant.global_position)
			Input.action_press("move_forward")
		else: Input.action_release("move_forward")
		await physics_frame
		if i==400:
			Input.action_release("move_forward")
			await tap(scene,KEY_F5)
			var saved: Dictionary=scene.model.snapshot()
			await frames(30)
			await tap(scene,KEY_F9)
			check(Base.distance(scene.merchant.global_position,Base.point(saved.misl.merchant.position))<0.3,"mid-route load restores real caravan")
			saved_midway=true
	Input.action_release("move_forward")
	check(saved_midway,"save/load occurred during physical caravan journey")
	await walk(scene,Rules.QUARTERMASTER+Vector3(0,0,-1))
	await frames(30)
	check(Base.distance(scene.merchant.global_position,Rules.QUARTERMASTER)<4.5,"physical caravan arrives home")
	look(scene,Rules.QUARTERMASTER)
	await tap(scene,KEY_E)
	await press(scene,"Check the physically")
	check(scene.model.economy().ledger.caravan=="complete","actual caravan check-in settles once")
	await tap(scene,KEY_E)
	await press(scene,"Hire a garrison")
	check(scene._guard_posts[0].visible,"hired guard visible in home yard")
	await tap(scene,KEY_E)
	await press(scene,"Build storehouse")
	for _i in range(4):
		await tap(scene,KEY_E)
		await press(scene,"Rest until")
	check("storehouse" in scene.model.economy().ledger.built and scene._works.storehouse.visible,"completed construction changes world")
	ok(scene.model.validate(scene.model.snapshot()),"played supply run validates")
	for _i in range(5):
		await tap(scene,KEY_E)
		await press(scene,"Rest until")
	check(scene.horse.gait_speed_limit==3,"unfed horse loses faster gaits")
	# Explicit blocked-pose fixture: ensure failed load does not partially replace live state.
	scene._open_accounts()
	var before: Dictionary=scene.model.snapshot()
	var bad:=before.duplicate(true)
	bad.misl.merchant.position=[-12,0.14,5]
	# Completed caravan cannot teleport to remote obstacle at either domain/spatial boundary.
	var file:=FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(bad,"",true,true));file.close()
	scene._load()
	check(scene.model.snapshot()==before,"rejected caravan load preserves the session")
	home.queue_free()
	await frames()

func _run() -> void:
	_domain()
	await _journey()
	for suffix in ["",".tmp",".checkpoint.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("GUJRANWALA_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
