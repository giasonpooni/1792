# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State:=preload("res://workshops/workshop_state.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const View:=preload("res://workshops/workshop_world.gd")
const Prior:=preload("res://youth/brawl_state.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const SAVE:="user://home-workshop-test-isolated.json"
var passed:=0
var failed:=0
var journey: Array=[]
var isolated_save:=SAVE
var output_dir:="user://"
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error(label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func refused(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot();check(not str(action.call()).is_empty(),label+" refuses");check(model.snapshot()==before,label+" atomic")
func fresh():
	var model:=State.new();ok(model.restore(Fixture.complete()),"declared completed-inquiry fixture")
	ok(model.begin_allowance(),"existing household allowance");return model
func _domain() -> void:
	var model=fresh();var initial: Dictionary=model.snapshot()
	refused(model,model.workshop_action.bind("collect"),"premature pickup")
	refused(model,model.workshop_action.bind("ready"),"player cannot complete work")
	refused(model,model.operate.bind("smith.reserve"),"generic API cannot inject workshop actions")
	ok(model.workshop_action("reserve"),"reserve real fuel and payment")
	check(model.economy().ledger.treasury==116 and model.economy().ledger.stock.timber==6,"reserve debits household")
	check(model.economy().ledger.purse==18,"private purse unchanged")
	for action in [model.workshop_action.bind("reserve"),model.begin_water_round,model.begin_service,model.begin_brawl,model.mount,model.operate.bind("accept_delivery")]: refused(model,action,"incompatible carried commitment")
	refused(model,model.workshop_action.bind("start"),"remote handover")
	ok(model.save_to(isolated_save),"save carried fuel")
	var loaded:=State.new();ok(loaded.load_from(isolated_save),"load carried fuel")
	check(Supply._equal(loaded.snapshot(),model.snapshot()),"fuel roundtrip equals all fields")
	var old:=Prior.new();check(not old.restore(model.snapshot()).is_empty(),"old reader refuses unsupported workshop receipts")
	ok(Pose.pose(model,Craft.SITE+Vector3(0,0,-2)),"domain fixture near smith")
	ok(model.workshop_action("start"),"handover")
	check(model.workshop().fuel_used==2 and model.workshop().fee_paid==4 and not model.carrying_workshop(),"custody passes to smith")
	refused(model,model.workshop_action.bind("start"),"duplicate handover")
	refused(model,model.workshop_action.bind("refund"),"spent fee is not refundable")
	var memories: Array=model.journal()
	for _i in range(599): model.advance()
	check(model.workshop_phase()=="working","no early completion")
	ok(model.save_to(isolated_save),"working save preserves deadline")
	ok(loaded.load_from(isolated_save),"reload pending work");loaded.advance();model.advance()
	check(loaded.workshop()==model.workshop() and model.workshop_phase()=="ready","completion at original deadline after load")
	check(model.journal()==memories and model.economy().ledger.stock.tools==2,"no remote heard memory or premature inventory")
	ok(model.workshop_action("collect"),"collect actual output")
	refused(model,model.workshop_action.bind("collect"),"duplicate pickup")
	refused(model,model.workshop_action.bind("deliver"),"remote delivery")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"domain return pose")
	ok(model.workshop_action("deliver"),"physical store settlement")
	check(model.economy().ledger.stock.tools==4 and model.economy().ledger.favor==53,"two tools and bounded standing once")
	refused(model,model.workshop_action.bind("deliver"),"duplicate settlement")
	ok(model.validate(model.snapshot()),"entire workshop history validates")
	var current: Dictionary=model.snapshot()
	for key in ["schema","fee_paid","fuel_used","tools_carried","started_tick","ready_tick","settled_tick"]:
		var bad: Dictionary=current.duplicate(true)
		if key=="schema": bad.misl.ledger.workshop[key]="gujranwala-smith.v1"
		else: bad.misl.ledger.workshop[key]+=1
		refused(model,model.restore.bind(bad),"tampered "+key)
	var bad: Dictionary=current.duplicate(true);bad.misl.events[1].arg="999"
	refused(model,model.restore.bind(bad),"altered receipt time")
	ok(model.restore(initial),"whole-world rewind")
	check(model.workshop_phase()=="unassigned" and model.economy().ledger.stock.tools==2,"rewind removes later output")
	ok(model.workshop_action("reserve"),"refund case reserve");ok(model.workshop_action("refund"),"unused refund")
	check(model.economy().ledger.stock==initial.misl.ledger.stock and model.economy().ledger.treasury==initial.misl.ledger.treasury,"exact materials/money refund")
	refused(model,model.workshop_action.bind("refund"),"no repeated refund")
	refused(model,model.workshop_action.bind("reserve"),"finite cancelled job stays cancelled")
	# Direct reducers are explicitly arithmetic fixtures, not claimed movement.
	var ledger:=Supply.initial();ledger.treasury=3;var before:=ledger.duplicate(true)
	check(not Craft.apply(ledger,"smith.reserve","0").is_empty() and ledger==before,"insufficient funds atomic")
	ledger=Supply.initial();ledger.stock.timber=1;before=ledger.duplicate(true)
	check(not Craft.apply(ledger,"smith.reserve","0").is_empty() and ledger==before,"insufficient fuel atomic")
	ledger=Supply.initial();ok(Craft.apply(ledger,"smith.reserve","0"),"pure reserve")
	ledger.stock.food+=Supply.capacity(ledger)-Supply.stored(ledger);before=ledger.duplicate(true)
	check(not Craft.apply(ledger,"smith.refund","1").is_empty() and ledger==before,"full-store refund retains cargo and fee")
	ok(Craft.apply(ledger,"smith.start","1"),"pure handover");ok(Craft.apply(ledger,"smith.ready","601"),"pure completion");ok(Craft.apply(ledger,"smith.collect","602"),"pure collect")
	before=ledger.duplicate(true);check(not Craft.apply(ledger,"smith.deliver","603").is_empty() and ledger==before,"full-store delivery retains tools")
	# Work ending at an upkeep boundary must replay after that same watch receipt.
	model=fresh();ok(model.workshop_action("reserve"),"watch reserve")
	for _i in range(Supply.WATCH_TICKS-Craft.WORK_TICKS): model.advance()
	ok(Pose.pose(model,Craft.SITE),"watch fixture smith");ok(model.workshop_action("start"),"watch handover")
	for _i in range(Craft.WORK_TICKS): model.advance()
	var receipts: Array=model.economy().events
	check(receipts[-2].kind=="watch" and receipts[-1].kind=="smith.ready" and receipts[-2].tick==receipts[-1].tick,"upkeep precedes coincident completion")
	ok(model.validate(model.snapshot()),"coincident deadline replay")
	# The existing service validator reconstructs economic prefixes containing smith actions.
	ok(Pose.pose(model,Supply.QUARTERMASTER),"service fixture quartermaster")
	ok(model.begin_service(),"service can begin with hands free while tools await pickup")
	ok(model.begin_water_round(),"water can begin with hands free")
	ok(model.save_to(isolated_save),"integrated service/water/workshop save")
	ok(loaded.load_from(isolated_save),"integrated prefix replay after save")
	check(Supply._equal(loaded.snapshot(),model.snapshot()),"all three systems survive roundtrip")
	ok(Pose.pose(model,Craft.SITE),"return to smith domain fixture");ok(model.workshop_action("collect"),"pickup with idle service/water records")
	refused(model,model.water_action.bind("draw"),"existing water task cannot overlap tool cargo")
	refused(model,model.service_action.bind("dispatch","market"),"existing service cannot overlap tool cargo")
	ok(model.validate(model.snapshot()),"idle service with carried output validates")
	var stream:=View._strike_stream()
	check(stream.mix_rate==22050 and stream.format==AudioStreamWAV.FORMAT_16_BITS and not stream.stereo and stream.data.size()==14112,"original bounded mono PCM cue")

func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true;scene._unhandled_input(e);await frames(2)
func press(scene,prefix: String) -> void:
	for b in scene._actions.get_children():
		if b.text.begins_with(prefix): b.pressed.emit();await frames(2);return
	check(false,"Missing button: "+prefix)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1200):
		if Base.distance(scene.avatar.global_position,p)<0.4: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(6)
	if not reached: print("WORKSHOP WALK: ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(reached,"input walk "+str(p))
func capture_state(scene,step: String) -> void:
	journey.append({"step":step,"tick":scene.model.progress().tick,"snapshot":scene.model.snapshot(),"camera_yaw":scene.avatar.pivot.rotation.y,"message":scene._message})

func _journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=isolated_save
	ok(scene.model.restore(Fixture.complete()),"single initial journey fixture")
	root.add_child(home);await frames(5)
	# From here: real movement, Godot collision, E input and button signals. No pose injection.
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Commission two")
	check(scene.model.workshop_phase()=="fuel" and scene.workplace.carried.visible,"UI reserve and visible fuel")
	check(scene.avatar.external_speed_limit==3.0,"same motor capped while carrying")
	capture_state(scene,"fuel")
	for p in [Vector3(3,0,1),Vector3(-15,0,1),Vector3(-15,0,5.7)]: await walk(scene,p)
	look(scene,Craft.SITE);await tap(scene,KEY_E)
	var prior: Dictionary=scene.model.snapshot();await frames(30)
	check(scene.model.snapshot()==prior,"smith dialogue freezes common clock")
	await press(scene,"Hand over fuel")
	check(scene.model.workshop_phase()=="working" and not scene.workplace.carried.visible,"actual handover releases hands")
	await frames(90);check(scene.workplace.strike_count>0,"work-state contiguous clock triggers sound")
	await tap(scene,KEY_F5);var deadline: int=scene.model.workshop().started_tick+Craft.WORK_TICKS
	await frames(45);await tap(scene,KEY_F9)
	check(scene.model.workshop().started_tick+Craft.WORK_TICKS==deadline,"F9 retains original due tick")
	capture_state(scene,"working")
	await tap(scene,KEY_F7);prior=scene.model.snapshot();var strikes: int=scene.workplace.strike_count;await frames(90)
	check(scene.model.snapshot()==prior and scene.workplace.strike_count==strikes and not scene.workplace.hammer_audio.playing,"F7 pauses work/pose/sound without another clock")
	await tap(scene,KEY_F7)
	var remote_hint: String=scene.workshop_hint();var received: Array=scene.model.journal()
	while scene.model.progress().tick<deadline: await physics_frame
	await frames(2)
	check(scene.model.workshop_phase()=="ready" and scene.workplace.finished.visible,"native clock completes visible bench tools")
	check(scene.workshop_hint()==remote_hint and scene.model.journal()==received,"ready does not leak remote knowledge")
	look(scene,Craft.SITE);await tap(scene,KEY_E);await press(scene,"Collect both")
	check(scene.model.workshop_phase()=="tools" and scene.workplace.carried.get_node("ToolHeads").visible,"tools now travel with player")
	await tap(scene,KEY_F5);await frames(10);await tap(scene,KEY_F9)
	check(scene.model.workshop_phase()=="tools" and scene.workplace.carried.visible,"carried-tool save reload")
	capture_state(scene,"tools")
	for p in [Vector3(-15,0,1),Vector3(3,0,1),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Return both tool")
	check(scene.model.workshop_phase()=="complete" and scene.model.economy().ledger.stock.tools==4,"full input-driven commission settled")
	check(scene.model.economy().ledger.treasury==116 and scene.model.economy().ledger.purse==18,"no duplicated fees or personal payout")
	ok(scene.model.validate(scene.model.snapshot()),"journey validates")
	capture_state(scene,"complete")
	var file:=FileAccess.open(output_dir.path_join("home-workshop-journey.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":"1792.home-workshop-journey.v2","kind":"input_driven_after_completed_inquiry_fixture","engine":Engine.get_version_info().string,"historical_authentication":false,"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),"source_commit":OS.get_environment("SOURCE_COMMIT"),"steps":journey},"\t",true,true));file.close()
	home.queue_free();await frames()

func _late_access() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=isolated_save
	var model=fresh();ok(model.workshop_action("reserve"),"access fixture reserve")
	ok(Pose.pose(model,Craft.SITE+Vector3(0,0,-2.3)),"explicit access fixture")
	ok(scene.model.restore(model.snapshot()),"access fixture load");root.add_child(home);await frames(5)
	look(scene,Craft.SITE);await tap(scene,KEY_E)
	check(scene._workshop_choices.has("start"),"local handover choice offered")
	var wall: MeshInstance3D=scene._box(Vector3(4,3,0.25),Craft.SITE+Vector3(0,1.2,-1.4),Color.GRAY,true)
	await frames(3);var before: Dictionary=scene.model.snapshot();await press(scene,"Hand over fuel")
	check(scene.model.economy()==before.misl and scene.model.workshop_phase()=="fuel","late wall prevents custody/payment")
	check(scene._message.contains("unobstructed"),"physical refusal explained")
	wall.get_parent().queue_free();await frames(3)
	# A bare action without its current local dialogue cannot be replayed.
	before=scene.model.economy();scene._menu_action("smith:start");await frames(3)
	check(scene.model.economy()==before,"stale external menu event refused")
	look(scene,Craft.SITE);await tap(scene,KEY_E);await press(scene,"Hand over fuel")
	check(scene.model.workshop_phase()=="working","renewed sight permits handover")
	scene._show_dialog("ISOLATED TEST","",[["Return","resume"]]);ok(scene.model.save_to(isolated_save),"standing-space fixture save")
	wall=scene._box(Vector3(1.5,3,1.5),scene.avatar.global_position+Vector3.UP,Color.GRAY,true);await frames(3)
	before=scene.model.snapshot();scene._load()
	check(scene.model.snapshot()==before and not scene._message.begins_with("Whole Home restored"),"blocked saved body refuses before live-state replacement")
	wall.get_parent().queue_free();home.queue_free();await frames()


func _retry_keeps_one_world() -> void:
	# Declared domain setup; this tests controller rollback, not another played fight.
	var seed=fresh();ok(seed.workshop_action("reserve"),"retry fixture reserve")
	ok(Pose.pose(seed,Craft.SITE),"retry fixture smith");ok(seed.workshop_action("start"),"retry fixture handover")
	ok(Pose.pose(seed,Supply.MARKET),"retry fixture market");ok(seed.begin_brawl(),"hands-free pending work permits outing")
	ok(Pose.pose(seed,Vector3(-12,0.14,-18)),"retry fixture confrontation")
	var prior: Dictionary=seed.snapshot()
	for i in [3,4]: prior.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,0.14,-16))
	ok(seed.restore(prior),"retry fixture friends");ok(seed.brawl_action("challenge"),"retry fixture challenge")
	ok(seed.save_to(isolated_save+".bazaar-retry.json"),"whole-world pre-confrontation checkpoint")
	var deadline: int=seed.workshop().started_tick+Craft.WORK_TICKS
	ok(seed.brawl_action("stand"),"retry fixture stand")
	while seed.progress().tick<deadline: seed.advance()
	check(seed.workshop_phase()=="ready","later workshop completion exists before rollback")
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=isolated_save
	ok(scene.model.restore(seed.snapshot()),"load later multi-system fixture")
	root.add_child(home);await frames(3);scene._retry_bazaar()
	check(scene.model.workshop_phase()=="working" and scene.model.brawl_phase()=="challenged","retry retains new model and rewinds both systems")
	check(scene.model.progress().tick<deadline and scene.model.workshop().ready_tick==-1,"future workshop deadline receipt is removed")
	ok(scene.model.validate(scene.model.snapshot()),"multi-system retry validates")
	home.queue_free();await frames()

func _run() -> void:
	var specified:=OS.get_environment("HOME_WORKSHOP_OUTPUT")
	if not specified.is_empty():
		if not DirAccess.dir_exists_absolute(specified): push_error("Dedicated test output does not exist.");quit(2);return
		output_dir=specified;isolated_save=specified.path_join("isolated-test-slot.json")
	_domain();await _journey();await _late_access();await _retry_keeps_one_world()
	for suffix in ["",".tmp",".checkpoint.json",".bazaar-retry.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated_save+suffix))
	print("HOME_WORKSHOP_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
