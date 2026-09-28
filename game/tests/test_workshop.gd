extends SceneTree
## Domain fixtures and rendering setups are explicit; the integration journey uses physical input.
const State:=preload("res://workshops/workshop_state.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const Economy:=preload("res://territory/misl_rules.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Town:=preload("res://settlement/town_state.gd")
const SAVE:="user://workshop-test-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(condition: bool,label: String) -> void:
	if condition: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(s,fn: Callable,label: String) -> void:
	var before: Dictionary=s.snapshot()
	check(not str(fn.call()).is_empty(),label+" refuses")
	check(s.snapshot()==before,label+" leaves whole world unchanged")
func fresh() -> State:
	var s:=State.new();ok(s.restore(Fixture.complete()),"completed-inquiry setup fixture")
	ok(s.begin_allowance(),"allowance in original ledger")
	return s
func roundtrip(s) -> void:
	ok(s.validate(s.snapshot()),"valid "+s.workshop_phase())
	ok(s.save_to(SAVE),"save "+s.workshop_phase())
	var restored:=State.new();ok(restored.load_from(SAVE),"restore "+s.workshop_phase())
	check(Economy._equal(restored.economy(),s.economy()),"receipt, funds and custody roundtrip")
func start_job(s) -> void:
	ok(s.workshop_action("reserve"),"reserve")
	ok(Pose.pose(s,Craft.SITE+Vector3(2,0,0)),"domain-only smith pose")
	ok(s.workshop_action("start"),"deliver fuel")
func _domain() -> void:
	var cold:=State.new();var old:=Town.new()
	check(cold.snapshot()==old.snapshot(),"no eager new fields in early checkpoint")
	reject(cold,cold.workshop_action.bind("reserve"),"early assignment")
	var s:=fresh();var before: Dictionary=s.economy().ledger
	ok(s.workshop_action("reserve"),"real stock/fund reservation")
	check(s.economy().ledger.stock.timber==before.stock.timber-2 and s.economy().ledger.treasury==before.treasury-4,"existing stock and coffers debited")
	check(s.workshop().fuel_carried==2 and s.workshop().fee_held==4,"fuel/payment custody conserved")
	check(s.economy().ledger.purse==before.purse,"personal purse unchanged")
	roundtrip(s)
	reject(s,s.workshop_action.bind("reserve"),"duplicate reservation")
	reject(s,s.workshop_action.bind("ready"),"manual clock completion")
	reject(s,s.operate.bind("smith.ready","0"),"economic entry-point bypass")
	reject(s,s.operate.bind("accept_delivery"),"two hand-carried cargos")
	reject(s,s.record_position.bind(s.position()+Vector3(0.3,0,0),1.0/60.0),"carried excessive motion")
	ok(Pose.pose(s,Base.point(s.horse_record().position)),"domain-only horse proximity")
	reject(s,s.mount,"mount with fuel")
	ok(Pose.pose(s,Economy.QUARTERMASTER+Vector3.RIGHT),"domain-only home pose")
	reject(s,s.workshop_action.bind("start"),"remote start")
	ok(Pose.pose(s,Craft.SITE+Vector3(2,0,0)),"domain-only workshop pose")
	ok(s.workshop_action("start"),"fuel/payment handed over exactly once")
	check(s.workshop().fuel_used==2 and s.workshop().fuel_carried==0 and s.workshop().fee_paid==4 and s.workshop().fee_held==0,"material/payment custody moved, not duplicated")
	reject(s,s.workshop_action.bind("start"),"duplicate fuel delivery")
	reject(s,s.workshop_action.bind("collect"),"premature output")
	for _i in range(Craft.WORK_TICKS-1): s.advance()
	check(s.workshop_phase()=="working","no early completion")
	roundtrip(s)
	var memories: Array=s.journal();s.advance()
	check(s.workshop_phase()=="ready","clock reaches actual completion")
	check(s.journal()==memories,"remote completion does not grant received knowledge")
	check(s.economy().ledger.stock.tools==before.stock.tools,"ready products are not household stock")
	roundtrip(s)
	ok(s.workshop_action("collect"),"physical-custody pickup")
	check(s.workshop().tools_carried==2,"tools are carried")
	roundtrip(s)
	reject(s,s.workshop_action.bind("collect"),"duplicate pickup")
	reject(s,s.workshop_action.bind("deliver"),"remote household credit")
	ok(Pose.pose(s,Economy.QUARTERMASTER+Vector3.RIGHT),"domain-only return pose")
	ok(s.workshop_action("deliver"),"tools in household stock")
	check(s.economy().ledger.stock.tools==before.stock.tools+2 and s.workshop().tools_carried==0,"single output accounting")
	check(s.economy().ledger.purse==before.purse and s.economy().ledger.favor==before.favor+3,"standing change, no cash minted")
	roundtrip(s)
	var old_reader:=Town.new()
	check(not old_reader.restore(s.snapshot()).is_empty(),"old controller refuses new receipts rather than inventing support")
	reject(s,s.workshop_action.bind("deliver"),"duplicate final settlement")
	reject(s,s.workshop_action.bind("reserve"),"no replayable commission reward")
	for field in ["fuel_carried","tools_carried","fee_paid","ready_tick","phase","schema"]:
		var bad: Dictionary=s.snapshot()
		bad.misl.ledger.workshop[field]="forged" if field in ["phase","schema"] else 999
		reject(s,s.restore.bind(bad),"tampered "+field)
	var bad: Dictionary=s.snapshot();bad.misl.events[1].arg=str(int(bad.misl.events[1].tick)+1)
	reject(s,s.restore.bind(bad),"self-consistent arg cannot replace receipt clock")
	bad=s.snapshot();bad.misl.ledger.stock.tools+=2
	reject(s,s.restore.bind(bad),"fabricated extra tools")
	bad=s.snapshot();bad.misl.events.append(bad.misl.events.back().duplicate(true))
	reject(s,s.restore.bind(bad),"duplicate economic receipt")
	ok(s.restore(Fixture.complete()),"legacy town snapshot imports without invented order")
	check(s.workshop_phase()=="unassigned" and not s.has_economy(),"earlier snapshot discards later funds/workshop progress")
	ok(s.restore(Pose.precursor()),"original checkpoint restore")
	check(not s.district_open() and not s.snapshot().has("settlement"),"early checkpoint closes town and retains envelope")

func _edge_cases() -> void:
	var s:=fresh();var initial: Dictionary=s.economy().ledger
	ok(s.workshop_action("reserve"),"refund reserve")
	ok(s.workshop_action("refund"),"cancel before fuel handover")
	check(s.economy().ledger.stock==initial.stock and s.economy().ledger.treasury==initial.treasury,"cancellation restores actual reserved resources")
	reject(s,s.workshop_action.bind("refund"),"duplicate refund")
	roundtrip(s)
	for shortage in ["treasury","timber"]:
		var ledger:=Economy.initial()
		if shortage=="treasury": ledger.treasury=3
		else: ledger.stock.timber=1
		var original: Dictionary=ledger.duplicate(true)
		check(not Craft.apply(ledger,"smith.reserve","5").is_empty() and ledger==original,"pure-reducer shortage fixture "+shortage)
	# The original economy rejects new operations unless trusted code opts in.
	var ledger:=Economy.initial()
	check(not Economy.apply(ledger,"smith.reserve","5").is_empty(),"base reducer has no hidden workshop capability")
	for arg in ["5.0","true","-1","01","10000001"]:
		check(not Craft.apply(ledger,"smith.reserve",arg).is_empty(),"strict workshop tick "+arg)
	s=fresh();start_job(s)
	for _i in range(Craft.WORK_TICKS): s.advance()
	ok(s.workshop_action("collect"),"capacity-fixture pickup")
	# Explicit transaction fixture: legal receipt replay, not physical market-travel evidence.
	while Economy.stored(s.economy().ledger)<Economy.capacity(s.economy().ledger): ok(s._post("buy","tools"),"fill store through existing purchase reducer")
	ok(Pose.pose(s,Economy.QUARTERMASTER+Vector3.RIGHT),"capacity-fixture home pose")
	reject(s,s.workshop_action.bind("deliver"),"full store cannot destroy/credit load")
	ok(s.operate("build","mill"),"real construction spends from same stock")
	ok(s.workshop_action("deliver"),"store room freed by original economy permits return")
	roundtrip(s)
	# Both due processes coincide: upkeep first, workshop completion second, one clock.
	s=fresh();ok(s.workshop_action("reserve"),"simultaneous deadline reserve")
	for _i in range(Economy.WATCH_TICKS-Craft.WORK_TICKS): s.advance()
	ok(Pose.pose(s,Craft.SITE+Vector3(2,0,0)),"simultaneous deadline pose")
	ok(s.workshop_action("start"),"start before watch deadline")
	for _i in range(Craft.WORK_TICKS): s.advance()
	check(s.economy().ledger.watch==1 and s.workshop_phase()=="ready","both clock-owned processes completed")
	check(s.economy().events[-2].kind=="watch" and s.economy().events[-1].kind=="smith.ready","stable same-tick settlement order")
	roundtrip(s)
	var bad: Dictionary=s.snapshot();bad.misl.events.pop_back();bad.misl.ledger=Economy.replay(bad.misl.events,Craft.apply)
	reject(s,s.restore.bind(bad),"due completion absent even with resealed ledger")

	# Full-store cancellation must return neither half of the reserved resources.
	s=fresh();ok(s.workshop_action("reserve"),"full-store refund setup")
	while Economy.stored(s.economy().ledger)<Economy.capacity(s.economy().ledger): ok(s._post("buy","tools"),"refund-capacity purchase fixture")
	reject(s,s.workshop_action.bind("refund"),"full-store refund is atomic")
	check(s.workshop().fee_held==Craft.FEE and s.workshop().fuel_carried==Craft.FUEL,"failed refund leaves both resource custodians intact")
	# Bounded-history fixture assembled from valid original upkeep receipts, not played time.
	s=fresh();var bounded: Dictionary=s.snapshot()
	for i in range(250):
		bounded.misl.events.append({"seq":i+1,"tick":int(bounded.misl.origin_tick)+(i+1)*Economy.WATCH_TICKS,"kind":"watch","arg":""})
	bounded.childhood.tick=bounded.misl.events.back().tick
	var hours: float=7.0+bounded.childhood.tick/216000.0
	bounded.game_time.day=1+int(hours/24.0);bounded.game_time.hour=fmod(hours,24.0)
	bounded.misl.events.append({"seq":251,"tick":bounded.childhood.tick,"kind":"contribute","arg":""})
	bounded.misl.ledger=Economy.replay(bounded.misl.events)
	ok(s.restore(bounded),"valid near-budget original receipt fixture")
	check(s.economy().ledger.treasury>=Craft.FEE and s.economy().ledger.stock.timber>=Craft.FUEL,"budget fixture has resources so limit is actually exercised")
	reject(s,s.workshop_action.bind("reserve"),"insufficient receipt capacity refuses before debit")

func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true;scene._unhandled_input(event);await frames(2)
func button(scene,fragment: String) -> void:
	for b in scene._actions.get_children():
		if b.text.contains(fragment): b.pressed.emit();await frames(2);return
	check(false,"missing UI action: "+fragment)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(2400):
		if Base.distance(scene.avatar.global_position,p)<0.4: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(8)
	if not reached: print("WORKSHOP WALK ",scene.avatar.global_position," -> ",p," ",scene._message)
	check(reached,"physical travel "+str(p))
func _journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"one completed-inquiry fixture; no pose/state injection after launch")
	root.add_child(home);await frames(6)
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Accept the limited")
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Commission two")
	check(scene.model.workshop_phase()=="fuel" and scene.workshop_world.carried.visible,"actual UI assignment changes custody and visible load")
	check(scene.avatar.run_speed<=Craft.CARRY_SPEED,"carried sprint speed limited")
	for p in [Vector3(2,0,-10),Vector3(-24,0,-11),Vector3(-35,0,-11),Vector3(-38,0,-7),Vector3(-43.6,0,-7)]: await walk(scene,p)
	look(scene,Craft.SITE);await tap(scene,KEY_E)
	var before: int=int(scene.model.progress().tick);await frames(30)
	check(int(scene.model.progress().tick)==before,"smith conversation pauses the existing clock")
	await button(scene,"Hand over")
	check(scene.model.workshop_phase()=="working" and not scene.workshop_world.carried.visible,"handover removes player's fuel projection")
	var pose: float=scene.workshop_world.smith_arm.rotation.x;await frames(20)
	check(scene.workshop_world.smith_arm.rotation.x!=pose,"working smith animates from chapter ticks")
	await tap(scene,KEY_F5);var recorded: Dictionary=scene.model.workshop();await frames(10);await tap(scene,KEY_F9)
	check(scene.model.workshop().started_tick==recorded.started_tick,"pending save/load preserves start rather than restarting work")
	for _i in range(Craft.WORK_TICKS+10): await physics_frame
	check(scene.model.workshop_phase()=="ready" and scene.workshop_world.finished.visible,"actual engine clock leaves output on bench")
	check(not scene._hud.text.contains("ready"),"remote-ready state not advertised as received knowledge")
	look(scene,Craft.SITE);await tap(scene,KEY_E);await button(scene,"Collect two")
	check(scene.model.workshop_phase()=="tools" and scene.workshop_world.carried.visible and not scene.workshop_world.finished.visible,"pickup moves visible custody")
	await tap(scene,KEY_F5);await tap(scene,KEY_F9)
	check(scene.model.workshop_phase()=="tools" and scene.workshop_world.carried.visible,"carried-output save reload")
	for p in [Vector3(-38,0,-7),Vector3(-38,0,-11),Vector3(-24,0,-11),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Return the two")
	check(scene.model.workshop_phase()=="complete" and scene.model.economy().ledger.stock.tools==4,"full physical round trip settles original stock exactly once")
	check(not scene.workshop_world.carried.visible,"settlement removes carried projection")
	ok(scene.model.validate(scene.model.snapshot()),"whole played chapter validates")
	var f:=FileAccess.open("user://workshop-journey.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema":"1792.workshop-test-trace.v1","scope":"automated-input-driven-after-declared-inquiry-fixture","world":scene.model.snapshot()},"",true,true));f.close()
	home.queue_free();await frames(5)

func _scene_refusals() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"occlusion fixture")
	ok(scene.model.begin_allowance(),"occlusion allowance")
	ok(scene.model.workshop_action("reserve"),"occlusion task")
	ok(Pose.pose(scene.model,Craft.SITE+Vector3(2.4,0,0)),"isolated visibility fixture; not gameplay travel")
	root.add_child(home);await frames(6);look(scene,Craft.SITE)
	var wall=scene.town.box(scene,Vector3(0.25,3,3),Craft.SITE+Vector3(1.2,1.3,0),Color.GRAY,true)
	await frames(4);await tap(scene,KEY_E)
	check(not scene._paused and scene.model.workshop_phase()=="fuel","wall blocks workshop interaction")
	wall.queue_free();await frames(4);look(scene,Craft.SITE);await tap(scene,KEY_E)
	check(scene._paused,"visible smith opens dialogue")
	# A queued menu action is rechecked if the geometry changes before its physics tick.
	wall=scene.town.box(scene,Vector3(0.25,3,3),Craft.SITE+Vector3(1.2,1.3,0),Color.GRAY,true)
	await frames(4);await button(scene,"Hand over")
	check(scene.model.workshop_phase()=="fuel","new obstruction refuses queued custody change")
	wall.queue_free();await frames(4)
	var bad: Dictionary=scene.model.snapshot();bad.player.position=[-55,0.14,-7];bad.actors.ranjit_singh.position=bad.player.position.duplicate()
	var staged:=State.new();ok(staged.restore(bad),"domain-valid blocked physical pose")
	ok(staged.save_to(SAVE),"isolated rejected-load file")
	scene._open_places();var before: Dictionary=scene.model.snapshot();scene._load()
	check(scene.model.snapshot()==before,"blocked load preserves world and pending workshop")
	home.queue_free();await frames(5)
func _run() -> void:
	_domain();_edge_cases();await _journey();await _scene_refusals()
	for path in [SAVE,SAVE+".tmp",SAVE+".checkpoint.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("WORKSHOP_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
