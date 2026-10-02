# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Domain/replay fixtures are distinct from the single motor-driven journey below.
## No fixture, branch name or passed assertion authenticates this fictional encounter.
const State:=preload("res://workshops/workshop_state.gd")
const R:=preload("res://access/gate_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const SAVE:="user://gate-memory-test-isolated.json"
const BAD_SAVE:="user://gate-memory-invalid-test-isolated.json"
var passed:=0
var failed:=0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,label: String) -> void:
	if value:
		passed+=1
	else:
		failed+=1
		push_error("GATE MEMORY FAIL: "+label)

func ok(error: String,label: String) -> void:
	check(error.is_empty(),label+": "+error)

func refused(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(action.call()).is_empty(),label+" refuses")
	check(model.snapshot()==before,label+" preserves entire world")

func fresh():
	var model:=State.new()
	ok(model.restore(Fixture.complete()),"declared completed-inquiry domain fixture")
	return model

func gate_memories(model) -> Array:
	return model.journal().filter(func(entry): return entry.source_id==R.GUARD_ID)

func same_saved(a: Variant,b: Variant) -> bool:
	# Godot's decimal JSON transport can shift double motion values by a few ulps.
	# Integer identities/ticks, flags, strings, key sets and array order stay exact.
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size():
			return false
		for key in a:
			if not b.has(key) or not same_saved(a[key],b[key]):
				return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size():
			return false
		for i in range(a.size()):
			if not same_saved(a[i],b[i]):
				return false
		return true
	if typeof(a)==TYPE_INT:
		return Supply.finite_number(b) and a==b
	if typeof(a)==TYPE_FLOAT:
		return Supply.finite_number(a) and Supply.finite_number(b) and absf(a-b)<=1e-12
	return typeof(a)==typeof(b) and a==b

func frames(n: int=3) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func release() -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]:
		Input.action_release(action)

func look(scene,p: Vector3) -> void:
	var direction: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-direction.x,-direction.z)

func tap(scene,key: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=key
	event.pressed=true
	scene._unhandled_input(event)
	await frames(2)

func press(scene,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix):
			button.pressed.emit()
			await frames(2)
			return
	check(false,"missing current dialogue button: "+prefix)
	if scene._paused:
		scene._resume()

func walk(scene,p: Vector3,sprint: bool=false) -> void:
	var reached:=false
	for _i in range(1200):
		if Base.distance(scene.avatar.global_position,p)<0.28:
			reached=true
			break
		look(scene,p)
		Input.action_press("move_forward")
		if sprint:
			Input.action_press("sprint")
		await physics_frame
	release()
	await frames(8)
	if not reached:
		print("GATE WALK STOP: ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(reached,"input-driven route to "+str(p))

func dispose(home: Node3D) -> void:
	release()
	home.queue_free()
	await frames(3)

func _run() -> void:
	_domain()
	await _journey()
	await _late_wall()
	await _witness_wall()
	for name in [SAVE,BAD_SAVE]:
		for suffix in ["",".tmp",".checkpoint.json",".bazaar-retry.json"]:
			if FileAccess.file_exists(name+suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(name+suffix))
	print("GATE_MEMORY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

func _domain() -> void:
	var blank:=State.new()
	refused(blank,blank.gate_action.bind("request",true),"no household gate before the inquiry")
	var model=fresh()
	check(not model.has_gate_passage() and gate_memories(model).is_empty(),"legacy import invents no gate ledger or testimony")
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.05)),"legacy-domain crossing start")
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.05),0.1,true,true),"legacy inherited travel remains possible")
	check(not model.has_gate_passage(),"legacy travel does not invent a gate encounter")
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,1)),"local dialogue domain fixture")
	refused(model,model.gate_action.bind("unknown",true),"unknown gate action")
	refused(model,model.gate_action.bind("request",false),"unobserved conversation")
	refused(model,model.gate_action.bind("account",true),"no account before first local request")
	ok(Pose.pose(model,R.GUARD+Vector3(0,4,0)),"elevated speaker domain fixture")
	refused(model,model.gate_action.bind("request",true),"elevated planar-near speaker")
	ok(Pose.pose(model,Vector3(3,0.14,4)),"remote speaker domain fixture")
	refused(model,model.gate_action.bind("request",true),"remote gate request")
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,1)),"return to local speaker domain fixture")
	ok(model.gate_action("request",true),"local foot request creates one agreement")
	check(model.gate_passage().ledger.permit and gate_memories(model).size()==1,"agreement and received permission recorded together")
	var detached: Dictionary=model.gate_passage()
	detached.ledger.permit=false
	detached.events.clear()
	check(model.gate_passage().ledger.permit and model.gate_passage().events.size()==1,"gate queries are detached")
	var prior: Dictionary=model.gate_passage()
	for _i in range(8):
		model.advance()
		ok(model.record_gate_position(model.position(),1.0/60,true,true),"stationary admitted sample")
	check(model.gate_passage()==prior,"stationary sampling creates no crossing receipts")
	refused(model,model.record_gate_position.bind(Vector3(NAN,0.14,0),0.1,true,true),"nonfinite player motion")
	refused(model,model.record_gate_position.bind(model.position(),INF,true),"nonfinite timestep")
	refused(model,model.record_gate_position.bind(model.position(),0.0,true),"zero timestep")
	refused(model,model.record_gate_position.bind(model.position()+Vector3(10,0,0),0.1,true,true),"unbounded player translation")
	# Explicit half-open boundary fixtures. Arrival at the south-owned plane is not a crossing.
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.02)),"exact-plane domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR,0.1,true,true),"arrival exactly at threshold plane")
	check(model.gate_passage().events.size()==1 and model.gate_passage().ledger.permit,"plane arrival keeps permission")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.02),0.1,true,true),"depart plane toward north")
	check(model.gate_passage().ledger.crossings==1 and not model.gate_passage().ledger.permit,"one plane departure consumes one permission")
	check(not model.gate_passage().ledger.challenge,"witnessed controlled permitted crossing creates no concern")
	refused(model,model.record_gate_position.bind(R.ANCHOR+Vector3(0,0,0.02),0.1,true,true),"second crossing inside the same simulation tick")
	var received: Array=gate_memories(model)
	check(received.size()==1 and model.gate_passage().ledger.memories.size()==2 and model.gate_passage().ledger.memories[-1].source_id=="self","crossing adds self memory without guard account")
	prior=model.gate_passage()
	ok(Pose.pose(model,R.ANCHOR+Vector3(R.LANE_HALF_WIDTH+0.01,0,0.02)),"side-route domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(R.LANE_HALF_WIDTH+0.01,0,-0.02),0.1,true,true),"side route remains valid inherited motion")
	check(model.gate_passage()==prior,"side bypass has no central gate receipt")
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,1,0.02)),"elevated-route domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,1,-0.02),0.1,true,true),"elevated movement admitted by inherited domain")
	check(model.gate_passage()==prior,"elevated route is not central passage")
	# Knowledge is delivered only after a local account. Unwitnessed conduct stays unknown to the keeper.
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.3)),"unwitnessed domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.3),0.1,false),"unwitnessed rushed crossing remains physical travel")
	check(not model.gate_passage().ledger.challenge and gate_memories(model)==received,"unwitnessed travel invents no guard knowledge")
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.3)),"witnessed unpermitted domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.3),0.1,true,true),"witnessed rush remains physical travel")
	check(model.gate_passage().ledger.challenge and not model.gate_passage().ledger.challenge_heard,"witnessed misconduct changes hidden control state")
	check(gate_memories(model)==received,"witness receipt does not give the player unheard testimony")
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,1)),"account domain fixture")
	refused(model,model.gate_action.bind("reconcile",true),"reconciliation before hearing")
	model.advance()
	ok(model.gate_action("account",true),"local heard concern")
	check(model.gate_passage().ledger.challenge_heard and gate_memories(model)[-1].text.contains("without a passage agreement"),"keeper's delivered account describes witnessed unpermitted conduct")
	ok(model.validate(model.snapshot()),"complete gate replay validates")
	_tampering(model)
	model.advance()
	ok(model.gate_action("reconcile",true),"received concern can be settled locally")
	check(model.gate_passage().ledger.permit and not model.gate_passage().ledger.challenge,"settlement clears concern and grants one passage")
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.3)),"renewed witnessed domain start")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.3),0.1,true,true),"new witnessed rush")
	check(model.gate_passage().ledger.challenge and not model.gate_passage().ledger.challenge_heard,"new concern does not inherit a previously heard concern")
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,1)),"return domain fixture")
	model.advance()
	ok(model.gate_action("request",true),"request receives current objection")
	check(not model.gate_passage().ledger.permit and model.gate_passage().ledger.challenge_heard,"outstanding challenge prevents silent reauthorization")
	_mounted_domain()
	_airborne_domain()
	_custody_and_rollback()
	_budget()

func _tampering(model) -> void:
	var value: Dictionary=model.snapshot()
	ok(model.save_to(SAVE),"valid full-world domain save")
	var bytes: String=FileAccess.get_file_as_string(SAVE)
	var loaded:=State.new()
	ok(loaded.load_from(SAVE),"domain file load")
	check(same_saved(loaded.snapshot(),value) and Supply._equal(loaded.gate_passage().ledger,value.gate_passage.ledger),"domain JSON retains exact ledgers and identities, with motion transport within 1e-12")
	for kind in ["schema","gate_id","guard_id","authority","historical_class","origin_future","origin_nan","seq","tick_future","tick_fraction","tick_nan","before_nan","after_inf","delta","auth","witness_type","ground_type","cross_contact","extra_actor","memory_text","memory_source","ledger","duplicate","reordered"]:
		var bad: Dictionary=value.duplicate(true)
		var gate: Dictionary=bad.gate_passage
		match kind:
			"schema","gate_id","guard_id","authority","historical_class": gate[kind]="wrong_identity"
			"origin_future": gate.origin_tick=bad.childhood.tick+1
			"origin_nan": gate.origin_tick=NAN
			"seq": gate.events[0].seq=0
			"tick_future": gate.events[-1].tick=bad.childhood.tick+1
			"tick_fraction": gate.events[-1].tick+=0.5
			"tick_nan": gate.events[-1].tick=NAN
			"before_nan": gate.events[-1].before[0]=NAN
			"after_inf": gate.events[-1].after[2]=INF
			"delta": gate.events[1].delta=0.0
			"auth": gate.events[1].authorized=not gate.events[1].authorized
			"witness_type": gate.events[1].witnessed=1
			"ground_type": gate.events[1].grounded=1
			"cross_contact": gate.events[1].contact=true
			"extra_actor": gate.events[0].actor_id="another_person"
			"memory_text": gate.ledger.memories[-1].text="I know who ordered the attack."
			"memory_source": gate.ledger.memories[-1].source_id="fictional_household_guard"
			"ledger": gate.ledger.crossings+=1
			"duplicate": gate.events.append(gate.events[-1].duplicate(true))
			"reordered": gate.events.reverse()
		refused(model,model.restore.bind(bad),"corrupt receipt or identity "+kind)
		check(FileAccess.get_file_as_string(SAVE)==bytes,"failed restore retains saved bytes "+kind)
	var hostile: Dictionary=value.duplicate(true)
	hostile.gate_passage.guard_id="fictional_household_guard"
	var file:=FileAccess.open(BAD_SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(hostile))
	file.close()
	refused(model,model.load_from.bind(BAD_SAVE),"hostile on-disk snapshot")
	check(FileAccess.get_file_as_string(SAVE)==bytes,"failed load cannot rewrite the valid manual save")

func _mounted_domain() -> void:
	var model=fresh()
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.1)),"mounted domain local start")
	ok(model.gate_action("request",true),"mounted domain first receives foot permission")
	var value: Dictionary=model.snapshot()
	value.riding.horse.position=value.player.position.duplicate()
	ok(model.restore(value),"declared parked-horse fixture")
	ok(model.mount(),"same original horse mounts")
	refused(model,model.gate_action.bind("request",true),"mounted speaker cannot receive permission")
	var motion: Dictionary={"position":Base.coords(R.ANCHOR+Vector3(0,0,-0.1)),"yaw":0.0,"speed":2.0,"vertical_speed":0.0,"grounded":true}
	var invalid: Dictionary=motion.duplicate(true)
	invalid.position[0]=NAN
	refused(model,model.record_gate_ride.bind(invalid,0.1,true),"nonfinite horse motion")
	invalid=motion.duplicate(true)
	invalid.id="another_horse"
	refused(model,model.record_gate_ride.bind(invalid,0.1,true),"unexpected horse identity field")
	model.advance()
	ok(model.record_gate_ride(motion,0.1,true),"controlled mounted crossing uses inherited horse admission")
	check(model.mounted() and model.gate_passage().ledger.crossings==1 and not model.gate_passage().ledger.challenge,"controlled mounted agreement is consumed once")
	ok(model.validate(model.snapshot()),"mounted gate and original horse replay validate together")

func _airborne_domain() -> void:
	var model=fresh()
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.05)),"airborne domain local start")
	ok(model.gate_action("request",true),"airborne domain receives foot permission")
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0.25,0.05)),"declared low-airborne pose fixture")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0.25,-0.05),0.1,false),"low-airborne foot crossing remains admitted inherited motion")
	check(model.gate_passage().events[-1].grounded==false,"unknown or airborne ground observation is retained without inventing ground contact")
	ok(model.validate(model.snapshot()),"airborne observation replays without inferring ground")
	check(R.crossing(R.ANCHOR+Vector3(R.LANE_HALF_WIDTH,0,0.1),R.ANCHOR+Vector3(R.LANE_HALF_WIDTH,0,-0.1)),"lane boundary belongs to the declared opening")
	check(not R.crossing(R.ANCHOR+Vector3(R.LANE_HALF_WIDTH+0.01,0,0.1),R.ANCHOR+Vector3(R.LANE_HALF_WIDTH+0.01,0,-0.1)),"outside lane boundary remains a side route")

func _custody_and_rollback() -> void:
	var model=fresh()
	ok(model.begin_allowance(),"shared-world allowance fixture")
	ok(model.workshop_action("reserve"),"shared-world fuel reserve")
	var initial: Dictionary=model.snapshot()
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.2)),"carried-fuel gate fixture")
	ok(model.gate_action("request",true),"gate interaction shares existing carried custody")
	refused(model,model.record_gate_position.bind(R.ANCHOR+Vector3(0,0,-0.35),0.1,true,true),"gate cannot bypass workshop carry speed")
	refused(model,model.mount,"gate permission cannot bypass workshop mounting restriction")
	ok(Pose.pose(model,Craft.SITE),"shared-world handover fixture")
	ok(model.workshop_action("start"),"old smith handover unchanged")
	for _i in range(Craft.WORK_TICKS):
		model.advance()
	check(model.workshop_phase()=="ready" and model.has_gate_passage(),"same inherited clock progresses smith beside gate memory")
	ok(model.restore(initial),"valid earlier whole-world snapshot")
	check(not model.has_gate_passage() and model.workshop_phase()=="fuel" and model.progress().tick==initial.childhood.tick,"whole-world rewind removes future gate and workshop completion together")
	check(Supply._equal(model.snapshot(),initial),"whole-world rewind preserves all earlier identities, receipts and resources exactly")
	ok(model.validate(model.snapshot()),"whole-world rewind revalidates")

func _budget() -> void:
	var model=fresh()
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,1)),"bounded-account fixture")
	ok(model.gate_action("request",true),"bounded-account begins")
	for _i in range(R.MAX_EVENTS-1):
		model.advance()
		ok(model.gate_action("check",true),"bounded local account")
	check(model.gate_status()=="suspended" and model.gate_passage().events.size()==R.MAX_EVENTS,"gate receipt capacity is explicit and finite")
	refused(model,model.gate_action.bind("request",true),"full gate account")
	var prior: Dictionary=model.gate_passage()
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.1)),"suspended route fixture")
	model.advance()
	ok(model.record_gate_position(R.ANCHOR+Vector3(0,0,-0.1),0.1,true,true),"receipt capacity keeps inherited physical travel available")
	check(model.gate_passage()==prior,"suspended ledger invents no unretained permission or witness transition")
	ok(model.validate(model.snapshot()),"finite suspended account remains replayable")

func _journey() -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"single declared completed-inquiry journey start")
	root.add_child(home)
	await frames(8)
	check(scene.gate_passage.guard_root.global_position.distance_to(R.GUARD)<R.POSITION_EPSILON and scene.gate_passage.guard_root.get_meta("actor_projection_id","")==R.GUARD_ID,"visible keeper pose and projection identity match gate authority")
	# All progress from here uses the original motor, native collision, E and UI actions.
	# Camera turning supplies direction; pose, velocity, receipt and progress are never injected.
	for point in [Vector3(3,0,1),Vector3(-5.9,0,1),Vector3(-6,0,-2.0)]:
		await walk(scene,point)
	look(scene,R.GUARD)
	await tap(scene,KEY_E)
	check(scene._paused and scene._gate_choices.has("request"),"physically local E opens keeper conversation")
	var frozen: Dictionary=scene.model.snapshot()
	await frames(20)
	check(scene.model.snapshot()==frozen,"keeper conversation pauses the same whole-world tick")
	await press(scene,"Ask for one passage")
	check(scene.model.has_gate_passage() and scene.model.gate_passage().ledger.permit,"native keeper request grants one passage")
	if not scene.model.has_gate_passage():
		await dispose(home)
		return
	var permission: Array=gate_memories(scene.model)
	await walk(scene,Vector3(-8,0,-1.5))
	await walk(scene,Vector3(-8,0,-6.7),true)
	check(scene.model.gate_passage().ledger.crossings==1 and not scene.model.gate_passage().ledger.permit,"native sprint crosses the marked physical plane and consumes permission")
	check(scene.model.gate_passage().ledger.challenge and not scene.model.gate_passage().ledger.challenge_heard,"visible keeper retains witnessed rushed conduct")
	check(gate_memories(scene.model)==permission,"hidden keeper concern is absent from the received journal")
	# Return along the side route; this does not fabricate a second central passage.
	for point in [Vector3(-4.5,0,-6.7),Vector3(-4.5,0,-2.0),Vector3(-5.9,0,-2.0)]:
		await walk(scene,point)
	look(scene,R.GUARD)
	await tap(scene,KEY_E)
	check(not scene._panel_text.text.contains("I saw you rush"),"opening dialogue does not reveal an unheard hidden account")
	await press(scene,"Hear the keeper's account")
	check(scene.model.gate_passage().ledger.challenge_heard and scene._message.contains("I saw you rush"),"later native conversation delivers changed keeper account")
	look(scene,R.GUARD)
	await tap(scene,KEY_E)
	check(scene._panel_text.text.contains("I saw you rush"),"subsequent dialogue uses the actually received account")
	await optional_capture(scene,"keeper-heard-concern")
	await press(scene,"Acknowledge the heard concern")
	check(scene.model.gate_passage().ledger.permit and not scene.model.gate_passage().ledger.challenge,"native reconciliation grants one new passage")
	await tap(scene,KEY_F5)
	var saved: Dictionary=scene.model.snapshot()
	var bytes: String=FileAccess.get_file_as_string(SAVE)
	check(not bytes.is_empty() and bytes.contains("gate_passage"),"F5 writes same whole-world slot with gate history")
	await walk(scene,Vector3(-5.9,0,0))
	await tap(scene,KEY_F9)
	check(same_saved(scene.model.gate_passage(),saved.gate_passage) and Supply._equal(scene.model.gate_passage().ledger,saved.gate_passage.ledger) and gate_memories(scene.model)==saved.gate_passage.ledger.memories.filter(func(entry): return entry.source_id==R.GUARD_ID),"F9 retains exact permission, identity and delivered keeper memories")
	check(Base.distance(scene.model.position(),Base.point(saved.player.position))<0.1 and scene.model.progress().tick<=saved.childhood.tick+3,"F9 restores the whole Home pose and clock alongside gate history")
	check(FileAccess.get_file_as_string(SAVE)==bytes,"F9 leaves valid manual save bytes unchanged")
	ok(scene.model.validate(scene.model.snapshot()),"native joined journey validates through inherited authority")
	await dispose(home)

func _late_wall() -> void:
	# Declared physical access fixture; separate from the played journey above.
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	var model=fresh()
	ok(Pose.pose(model,R.GUARD+Vector3(0,0,2)),"late-wall local fixture")
	ok(scene.model.restore(model.snapshot()),"late-wall fixture import")
	root.add_child(home)
	await frames(8)
	look(scene,R.GUARD)
	await tap(scene,KEY_E)
	check(scene._gate_choices.has("request"),"request was offered before physical occlusion")
	var wall: MeshInstance3D=scene._box(Vector3(2.5,3,0.2),R.GUARD+Vector3(0,1.3,1),Color.GRAY,true)
	await frames(3)
	var before: Dictionary=scene.model.snapshot()
	await press(scene,"Ask for one passage")
	check(not scene.model.has_gate_passage() and scene.model.snapshot().get("gate_passage")==before.get("gate_passage"),"late witness wall prevents permission and received account")
	check(scene._message.contains("unobstructed"),"late sight refusal is explained by physical access")
	wall.get_parent().queue_free()
	await frames(3)
	before=scene.model.snapshot()
	scene._menu_action("gate:request")
	await frames(3)
	check(not scene.model.has_gate_passage() and scene.model.journal()==model.journal(),"stale detached menu event cannot become keeper testimony")
	look(scene,R.GUARD)
	await tap(scene,KEY_E)
	await press(scene,"Ask for one passage")
	check(scene.model.has_gate_passage() and scene.model.gate_passage().ledger.permit,"renewed actual sight allows new request")
	await dispose(home)

func _witness_wall() -> void:
	# Declared runtime observation fixture, not a second played or motor-driven route.
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	var model=fresh()
	ok(Pose.pose(model,R.ANCHOR+Vector3(0,0,0.3)),"witness-wall crossing start fixture")
	ok(model.gate_action("request",true),"witness-wall received agreement fixture")
	ok(scene.model.restore(model.snapshot()),"witness-wall runtime import")
	root.add_child(home)
	await frames(8)
	scene._show_dialog("ISOLATED WITNESS FIXTURE","",[["Return","resume"]])
	var target: Vector3=R.ANCHOR+Vector3(0,0,-0.3)
	check(scene._gate_contact(target),"native keeper-to-crossing ray is clear before wall")
	var center: Vector3=(R.GUARD+target)*0.5+Vector3.UP*1.3
	var wall: MeshInstance3D=scene._box(Vector3(0.2,3,1.0),center,Color.GRAY,true)
	await frames(3)
	check(not scene._gate_contact(target),"native witness ray is occluded by actual collision geometry")
	var received: Array=gate_memories(scene.model)
	ok(scene._record_walk(target,0.1),"same runtime admitted-walk seam crosses behind witness wall")
	check(scene.model.gate_passage().ledger.crossings==1 and not scene.model.gate_passage().ledger.challenge,"occluded rushed crossing creates no guard challenge")
	check(scene.model.gate_passage().events[-1].witnessed==false and gate_memories(scene.model)==received,"native occlusion receipt delivers no invented keeper testimony")
	wall.get_parent().queue_free()
	await frames(3)
	check(scene._gate_contact(target),"removing actual wall restores the same witness query")
	ok(scene.model.validate(scene.model.snapshot()),"occluded runtime receipt replays with whole Home authority")
	await dispose(home)

func optional_capture(scene,name: String) -> void:
	var directory:=OS.get_environment("GATE_CAPTURE_OUTPUT")
	if directory.is_empty():
		return
	if not DirAccess.dir_exists_absolute(directory):
		check(false,"requested screenshot output directory exists")
		return
	var before: Dictionary=scene.model.snapshot()
	check(scene._paused,"retained journey capture is the executed paused conversation")
	var record: Dictionary={"schema":"1792.gate-journey-capture.v1","snapshot":before,
		"camera":[scene.avatar.pivot.rotation.x,scene.avatar.pivot.rotation.y],
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"source_tree":OS.get_environment("SOURCE_TREE"),
		"received_account":scene._panel_text.text}
	var file:=FileAccess.open(directory.path_join(name+".json"),FileAccess.WRITE)
	if file==null:
		check(false,"retained executed journey capture can be opened")
		return
	file.store_string(JSON.stringify(record,"\t",true,true))
	file.flush()
	var result:=file.get_error()
	file.close()
	check(result==OK,"retained executed journey state saved for a short native render")
	check(scene.model.snapshot()==before,"retaining paused journey state changes no world facts or clock")
	if DisplayServer.get_name()=="headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(scene.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"optional current keeper dialogue screenshot")
	check(scene.model.snapshot()==before,"direct native screenshot changes no paused world facts")
