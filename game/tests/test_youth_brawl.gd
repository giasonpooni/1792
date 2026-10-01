# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State:=preload("res://youth/brawl_state.gd")
const R:=preload("res://youth/brawl_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const Catalogue:=preload("res://youth/catalogue.gd")
const SAVE:="user://youth-brawl-test-isolated.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error(label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func refused(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot();check(not str(action.call()).is_empty(),label+" refuses");check(model.snapshot()==before,label+" preserves state")
func fresh():
	var model:=State.new();ok(model.restore(Fixture.complete()),"fixture restore")
	ok(Pose.pose(model,Supply.MARKET),"fixture market")
	ok(model.begin_brawl(),"invitation")
	return model
func event(s: Dictionary,kind: String,tick: int,index: int=-1) -> Dictionary:
	var positions: Array=[]
	for i in range(5): positions.append(Base.coords(R.RING+Vector3(float(i)*0.1,0,0)))
	return {"seq":1,"tick":tick,"kind":kind,"index":index,"at":Base.coords(R.RING),"positions":positions}
func _domain() -> void:
	var model=fresh()
	refused(model,model.begin_brawl,"duplicate invitation")
	refused(model,model.brawl_action.bind("report"),"premature report")
	refused(model,model.brawl_action.bind("stand"),"stand before hearing")
	refused(model,model.mount,"mount during outing")
	refused(model,model.rest_watch,"rest during outing")
	var tele: Dictionary=model.brawl().actors[3];tele.position[0]+=1
	refused(model,model.record_brawl_actor.bind(3,tele,1.0/60.0,true),"actor teleport")
	tele=model.brawl().actors[3];tele.position[0]+=0.01
	refused(model,model.record_brawl_actor.bind(3,tele,1.0/60.0,false),"movement without contact")
	for key in ["schema","story_id","variant","tick","seq","memory","actor","unknown"]:
		var bad: Dictionary=model.snapshot()
		match key:
			"schema": bad.youth_brawl.schema="other"
			"story_id": bad.youth_brawl.story_id="maan_singh_lethal"
			"variant": bad.youth_brawl.variant="verified_history"
			"tick": bad.youth_brawl.events[0].tick+=1
			"seq": bad.youth_brawl.events[0].seq=0
			"memory": bad.youth_brawl.ledger.memories[0].text="I know a secret culprit."
			"actor": bad.youth_brawl.actors[3].id="household_guard_slot_0"
			"unknown": bad.youth_brawl.events[0].extra=true
		refused(model,model.restore.bind(bad),"tampered "+key)
	ok(model.save_to(SAVE),"domain save")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"domain load")
	check(Supply._equal(model.snapshot(),loaded.snapshot()),"JSON roundtrip")
	var detached: Dictionary=model.brawl();detached.ledger.hits=2
	check(model.brawl().ledger.hits==0,"detached query")
	ok(model.restore(Fixture.complete()),"earlier checkpoint snapshot")
	check(not model.has_brawl(),"earlier whole-world restore removes future story")
	# Pure combat reducer fixtures, not an input journey or evidence of physical travel.
	var s:=R.initial();var e:=event(s,"invite",0);e.at=Base.coords(Supply.MARKET)
	ok(R.apply(s,e),"pure invite")
	e=event(s,"challenge",1);ok(R.apply(s,e),"pure challenge")
	e=event(s,"stand",2);ok(R.apply(s,e),"pure stand")
	e=event(s,"counter",3,0);check(not R.apply(s,e).is_empty(),"no counter without parry")
	e=event(s,"parry",107,0);ok(R.apply(s,e),"timed parry")
	check(not R.apply(s,e).is_empty(),"no duplicate strike")
	e=event(s,"counter",107,0);check(not R.apply(s,e).is_empty(),"counter waits for post-strike recovery")
	e=event(s,"counter",108,0);ok(R.apply(s,e),"timed counter")
	check(not R.apply(s,e).is_empty(),"downed opponent cannot be farmed")
	e=event(s,"parry",152,1);ok(R.apply(s,e),"second timed parry")
	e=event(s,"counter",153,1);ok(R.apply(s,e),"second counter")
	e=event(s,"regroup",200);e.at=Base.coords(R.REGROUP)
	check(not R.apply(s,e).is_empty(),"friends cannot teleport to regroup")
	for i in [3,4]: e.positions[i]=e.at.duplicate()
	ok(R.apply(s,e),"physical-party receipt regroup")
	check(s.outcome=="stood_ground","two counters keep distinct outcome")
	e=event(s,"report",201);e.at=Base.coords(Supply.QUARTERMASTER)
	for i in [3,4]: e.positions[i]=e.at.duplicate()
	ok(R.apply(s,e),"report receipt")
	check(not R.apply(s,e).is_empty(),"report only once")
	check(Catalogue.data().stories.size()==28,"28 required stories")
	check(Catalogue.notebook().contains("NOT BUDDH'S MEMORY"),"authoring view isolated")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true;scene._unhandled_input(e);await frames(2)
func hold(key: Key,pressed: bool) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=pressed;Input.parse_input_event(e)
func click_strike(scene) -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;scene._unhandled_input(e)
func press(scene,prefix: String) -> void:
	for b in scene._actions.get_children():
		if b.text.begins_with(prefix): b.pressed.emit();await frames(2);return
	check(false,"Missing button: "+prefix)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1200):
		if Base.distance(scene.avatar.global_position,p)<0.5: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(6)
	if not reached: print("YOUTH WALK: ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(reached,"input walk "+str(p))
func _journey(route: String) -> void:
	var fight: bool=route=="fight"
	var stand: bool=route!="leave"
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"only initial journey fixture")
	root.add_child(home);await frames(5)
	# Existing movement, collision and UI; no pose/progress injection after launch.
	for p in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-13)]: await walk(scene,p)
	look(scene,Supply.MARKET);await tap(scene,KEY_E);await press(scene,"Walk with Mela")
	check(scene.model.brawl_phase()=="invited","market invitation UI")
	await walk(scene,Vector3(-18,0,-12));await walk(scene,Vector3(-12,0,-18));await frames(180)
	look(scene,scene.youths[0].global_position);await tap(scene,KEY_E)
	if scene.model.brawl_phase()!="challenged": print("CHALLENGE DIAG: ",scene.model.position()," / ",scene.model.brawl().actors," / ",scene._message)
	check(scene.model.brawl_phase()=="challenged","challenge heard with physical friends")
	var frozen: Dictionary=scene.model.snapshot();await frames(30)
	check(scene.model.snapshot()==frozen,"conversation pauses the common clock and actors")
	await press(scene,"Stand with" if stand else "Walk away")
	check(scene.model.brawl_phase()==("fighting" if stand else "leaving"),"selected branch begins")
	await tap(scene,KEY_F5);var saved: Dictionary=scene.model.snapshot();await frames(15);await tap(scene,KEY_F9)
	check(scene.model.brawl_phase()==saved.youth_brawl.ledger.phase,"mid-episode save/load retains branch")
	if fight:
		hold(KEY_Q,true)
		for target in [0,1]:
			for _i in range(440):
				if scene.model.brawl().ledger.down[target] or scene.model.brawl_phase()=="caught": break
				look(scene,scene.youths[target].global_position)
				if scene.model.brawl().ledger.stun_until[target]>=scene.model.progress().tick: click_strike(scene)
				await physics_frame
			check(scene.model.brawl().ledger.down[target],"actual guard/counter target "+str(target))
		hold(KEY_Q,false)
	await walk(scene,Vector3(2,0,-10));await frames(240)
	check(scene.model.brawl_phase()=="returning","both companions physically regroup")
	check(scene.model.brawl().ledger.outcome=={"fight":"stood_ground","leave":"walked_away","withdraw":"withdrew"}[route],"distinct real-play outcome")
	await walk(scene,Vector3(3,0,4));await frames(240)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Give the bazaar account")
	check(scene.model.brawl_phase()=="reported","full scene report completed")
	check(not scene.model.has_economy(),"no fabricated purse, wage ledger or reward")
	ok(scene.model.validate(scene.model.snapshot()),"journey state validates")
	check(scene.model.journal().filter(func(m):return m.id=="youth-bazaar-report").size()==1,"one heard report")
	await tap(scene,KEY_T);frozen=scene.model.snapshot();await frames(20)
	check(scene.model.snapshot()==frozen,"story slate adds no character knowledge")
	check(scene._panel_text.text.contains("Sialkot") and scene._panel_text.text.contains("Lethal Variant"),"full required slate in game")
	var trace: Dictionary={"schema":"1792.youth-brawl-evidence.v1","kind":"synthetic_engine_journey","branch":route,"engine":Engine.get_version_info().string,"tick":scene.model.progress().tick,"story":scene.model.brawl(),"catalogue_sha256":Catalogue.digest(),"historical_truth_verified":false}
	var file:=FileAccess.open("user://youth-brawl-"+route+"-trace.json",FileAccess.WRITE);file.store_string(JSON.stringify(trace,"\t",true,true));file.close()
	home.queue_free();await frames()
func _recovery_and_visibility() -> void:
	# Declared pre-confrontation fixture; not a claim to have replayed the tutorial.
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	var seed=fresh();ok(Pose.pose(seed,Vector3(-12,0.14,-18)),"recovery fixture pose")
	var initial: Dictionary=seed.snapshot()
	for i in [3,4]: initial.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,0.14,-16))
	ok(scene.model.restore(initial),"recovery fixture restore")
	root.add_child(home);await frames(6)
	look(scene,scene.youths[0].global_position);await tap(scene,KEY_E)
	check(scene.model.brawl_phase()=="challenged","recovery challenge heard")
	# A wall introduced after the dialogue opens must invalidate the queued choice.
	var wall: MeshInstance3D=scene._box(Vector3(5,3,0.3),Vector3(-12,1.5,-19),Color.GRAY,true)
	await frames(4)
	var prior: Dictionary=scene.model.snapshot()
	await press(scene,"Stand with")
	check(scene.model.brawl_phase()=="challenged" and scene.model.brawl().events==prior.youth_brawl.events,"stale choice cannot cross a new wall")
	check(not scene._contact(scene.youths[0]),"actual static wall removes opponent contact")
	wall.get_parent().queue_free();await frames(4)
	look(scene,scene.youths[0].global_position);await tap(scene,KEY_E)
	prior=scene.model.snapshot();await press(scene,"Stand with")
	check(scene.model.brawl_phase()=="fighting","fight after unobstructed renewed choice")
	for _i in range(500):
		if scene.model.brawl_phase()=="caught": break
		await physics_frame
	await frames(3)
	check(scene.model.brawl_phase()=="caught" and scene.model.brawl().ledger.hits==3,"three actual unguarded strikes end the attempt")
	var failed_world: Dictionary=scene.model.snapshot();await frames(30)
	check(scene.model.snapshot()==failed_world,"failure freezes the same world")
	await press(scene,"Retry the bazaar")
	check(scene.model.brawl_phase()=="challenged","retry restores pre-confrontation phase")
	check(scene.model.brawl().ledger.hits==0 and scene.model.brawl().ledger.start_tick==-1,"retry discards later injury and combat")
	# JSON parsing can change the last binary digit of a position. Compare all
	# serialized fields against the same decoded snapshot, not a wider tolerance.
	var decoded: Dictionary=JSON.parse_string(JSON.stringify(prior,"",true,true))
	check(Supply._equal(scene.model.brawl().events,decoded.youth_brawl.events),"retry discards later receipts and memories")
	check(scene.model.progress().tick<failed_world.childhood.tick,"retry restores earlier common clock")
	ok(scene.model.validate(scene.model.snapshot()),"retried world validates")
	# Save passes domain validation but a new physical obstruction must reject load.
	scene._paused=true;scene.avatar.set_physics_process(false)
	ok(scene.model.save_to(SAVE),"spatial fixture save")
	var friend: Vector3=scene.youths[3].global_position
	wall=scene._box(Vector3(1.5,3,1.5),friend+Vector3(0,1,0),Color.GRAY,true)
	await frames(3);prior=scene.model.snapshot();scene._load()
	check(scene._message.contains("standing room"),"load tests saved friend against actual collision")
	check(scene.model.snapshot()==prior,"blocked load preserves entire live world")
	wall.get_parent().queue_free();home.queue_free();await frames()
func _budget() -> void:
	# Pure reducer fixture: tests the finite receipt boundary, not physical travel.
	var model=fresh();ok(Pose.pose(model,Vector3(-12,0.14,-18)),"budget fixture pose")
	var snapshot: Dictionary=model.snapshot()
	for i in [3,4]: snapshot.youth_brawl.actors[i].position=Base.coords(Vector3(-12,0.14,-18))
	ok(model.restore(snapshot),"budget companions fixture")
	ok(model.brawl_action("challenge"),"budget challenge");ok(model.brawl_action("stand"),"budget stand")
	var start: int=int(model.progress().tick);var all_valid:=true
	for n in range(90):
		while model.progress().tick<start+105+n*180: model.advance()
		all_valid=all_valid and model.brawl_action("parry",0).is_empty()
	check(all_valid and model.brawl().events.size()==R.MAX_EVENTS-3,"combat reaches its declared bound with valid ordered strikes")
	while model.progress().tick<start+105+90*180: model.advance()
	refused(model,model.brawl_action.bind("parry",0),"combat leaves reserved exit receipts")
	snapshot=model.snapshot();snapshot.player.position=Base.coords(R.REGROUP);snapshot.actors.ranjit_singh.position=snapshot.player.position.duplicate()
	for i in [3,4]: snapshot.youth_brawl.actors[i].position=snapshot.player.position.duplicate()
	ok(model.restore(snapshot),"budget regroup fixture");ok(model.brawl_action("regroup"),"budget retains exit")
	snapshot=model.snapshot();snapshot.player.position=Base.coords(Supply.QUARTERMASTER);snapshot.actors.ranjit_singh.position=snapshot.player.position.duplicate()
	for i in [3,4]: snapshot.youth_brawl.actors[i].position=snapshot.player.position.duplicate()
	ok(model.restore(snapshot),"budget report fixture");ok(model.brawl_action("report"),"budget retains final report")
	ok(model.validate(model.snapshot()),"bounded completed history validates")
func _run() -> void:
	_domain();_budget();await _journey("leave");await _journey("fight");await _journey("withdraw");await _recovery_and_visibility()
	for suffix in ["",".tmp",".bazaar-retry.json",".bazaar-retry.json.tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("YOUTH_BRAWL_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
