extends SceneTree
const State := preload("res://territory/road/road_state.gd")
const Road := preload("res://territory/road/road_rules.gd")
const Narrative := preload("res://narrative/narration_track.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Economy := preload("res://territory/misl_rules.gd")
const SAVE := "user://shah-road-regression-only.json"
var passed:=0
var failed:=0

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(s,call: Callable,label: String) -> void:
	var before: Dictionary=s.snapshot()
	check(not str(call.call()).is_empty(),label+" refuses")
	check(s.snapshot()==before,label+" leaves active world unchanged")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true
	scene._unhandled_input(e)
	await frames(2)
func press(scene,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix):
			button.pressed.emit()
			await frames(2)
			return
	check(false,"UI choice missing: "+prefix)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(800):
		if Base.distance(scene.avatar.global_position,p)<0.5: reached=true;break
		look(scene,p)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(8)
	check(reached,"physical player walk to "+str(p))

func market_fixture() -> Dictionary:
	# Deliberately constructed already-delivered first contract, NOT a played journey.
	var s:=State.new()
	assert(s.restore(Fixture.complete()).is_empty())
	assert(s.begin_allowance().is_empty())
	assert(s.operate("accept_delivery").is_empty())
	assert(Pose.pose(s,Economy.MARKET+Vector3.RIGHT).is_empty())
	assert(s.operate("deliver").is_empty())
	return s.snapshot()

func checkpoint_fixture() -> Dictionary:
	# Domain/presentation fixture with declared arrival receipts. Route tests below
	# instead generate each receipt from the carrier's actual Godot collision motion.
	var s:=State.new()
	assert(s.restore(market_fixture()).is_empty())
	assert(s.accept_disputed_escort().is_empty())
	var value:=s.snapshot()
	for i in range(2): value.road_dispute.visited.append({"index":i,"tick":value.childhood.tick,"position":Base.coords(Road.APPROACH[i])})
	value.misl.merchant.position=Base.coords(Road.APPROACH[1])
	assert(s.restore(value).is_empty())
	assert(Pose.pose(s,Road.SPEAKER+Vector3.LEFT).is_empty())
	return s.snapshot()

func _domain() -> void:
	var s:=State.new()
	reject(s,s.accept_disputed_escort,"cannot add escort to childhood tutorial")
	ok(s.restore(market_fixture()),"old Gujranwala profile imports without inventing dispute")
	check(not s.has_road(),"old saves retain original direct assignment")
	var money: Dictionary=s.economy().ledger.duplicate(true)
	ok(s.accept_disputed_escort(),"accept disputed variant through original supply contract")
	check(s.economy().ledger.purse==money.purse and s.economy().ledger.treasury==money.treasury,"variant does not charge or duplicate money")
	check(s.road().caravan_id==s.economy().merchant.id,"same retained carrier identity")
	reject(s,s.accept_disputed_escort,"no repeat allocation")
	reject(s,s.hear_roadkeeper,"cannot hear checkpoint before arrival")
	reject(s,s.operate.bind("checkin"),"cannot check in before route")
	ok(s.restore(checkpoint_fixture()),"explicit checkpoint fixture validates")
	reject(s,s.choose_road.bind("recognize_claim"),"cannot decide before testimony")
	ok(s.hear_roadkeeper(),"hear one local claim")
	var memories:=s.journal().size()
	reject(s,s.hear_roadkeeper,"repeating claim is not independent corroboration")
	check(s.journal().size()==memories,"one source record")
	ok(s.choose_road("seek_confirmation"),"request corroborating permission")
	reject(s,s.receive_road_reply,"reply cannot arrive early")
	var motion: Dictionary=s.economy().merchant.duplicate(true)
	motion.position[0]+=0.02
	reject(s,s.record_merchant.bind(motion,1.0/60),"no motion through waiting gate")
	for _i in range(Road.REPLY_DELAY): s.advance()
	check(s.road().reply_received_tick<0 and not Road.permitted(s.road()),"time alone does not grant hearing or open gate")
	ok(s.receive_road_reply(),"receive reply at speaker after actual world ticks")
	check(Road.permitted(s.road()),"temporary passage after hearing reply")
	reject(s,s.receive_road_reply,"reply received once")
	reject(s,s.choose_road.bind("bypass"),"no silent route rewriting")
	ok(s.save_to(SAVE),"save waiting/permission state")
	var loaded:=State.new()
	ok(loaded.load_from(SAVE),"restore route alongside economy")
	check(Economy._equal(loaded.road(),s.road()),"route survives numeric JSON normalization")
	check(loaded.journal()==s.journal(),"same remembered sources after load")
	for corrupt in ["schema","actor","bool","choice","time","index","position","string_receipt","premature","complete","missing","extra"]:
		var bad:=s.snapshot()
		match corrupt:
			"schema":bad.road_dispute.schema="future"
			"actor":bad.road_dispute.caravan_id="spawn_extra_caravan"
			"bool":bad.road_dispute.accepted_tick=true
			"choice":bad.road_dispute.choice="annex_religion"
			"time":bad.road_dispute.decision_tick=bad.childhood.tick+1
			"index":bad.road_dispute.visited[0].index=1
			"position":bad.road_dispute.visited[0].position=[0,0.14,0]
			"string_receipt":bad.road_dispute.visited[1]="not a record"
			"premature":bad.road_dispute.reply_received_tick=bad.road_dispute.decision_tick
			"complete":bad.road_dispute.completed_tick=bad.childhood.tick
			"missing":bad.road_dispute.erase("heard_tick")
			"extra":bad.road_dispute.hidden_mastermind="invented"
		reject(s,s.restore.bind(bad),"invalid save "+corrupt)
	var detached:=s.road();detached.choice="bypass"
	check(s.road().choice=="seek_confirmation","read query is detached")
	check(not s.snapshot().actors.has("shah_muhammad"),"narrator is not inserted into character knowledge/actors")

func _narration() -> void:
	var n:=Narrative.new()
	check(n.catalog.size()==8,"bounded authored narrator catalogue")
	ok(n.observe(["home_open","home_open"]),"observe permitted event")
	check(n.queued.size()==1,"deduplicated cue")
	n.step(1.0/60,false)
	check(n.current=="" and n.transcript.is_empty(),"dialogue/combat can suspend playback")
	n.step(1.0/60,true)
	check(n.current=="home_open" and n.transcript==["home_open"],"started cue enters presentation transcript")
	var before: Array=n.observed.duplicate()
	check(not n.observe(["allowance","hidden_assassin"]).is_empty(),"reject hidden/unknown cue atomically")
	check(n.observed==before and n.queued.is_empty(),"invalid cue set leaves narrator unchanged")
	var remaining:=n.remaining
	n.step(1.0/60,false)
	check(n.remaining==remaining,"pause does not expire caption")
	n.step(-1,true);n.step(NAN,true)
	check(n.remaining==remaining,"invalid presentation deltas ignored")
	n.set_enabled(false)
	ok(n.observe(["allowance"]),"disabled narrator still marks events as baseline")
	n.set_enabled(true)
	ok(n.observe(["allowance"]),"reenable without backlog")
	check(n.queued.is_empty() and n.current=="","no replay spam after toggle")
	ok(n.rebase(["home_open","ambush_return"]),"restore baseline")
	check(n.transcript.is_empty(),"restored old narration is not falsely described as heard")
	ok(n.observe(["home_open","ambush_return","road_assignment"]),"new cue after restore")
	n.step(1.0/60,true)
	check(n.current=="road_assignment","only fresh event plays")
	ok(n.rebase(["home_open"]),"rewind removes later presentation")
	check(n.current=="" and n.queued.is_empty() and n.transcript.is_empty(),"no later narration carried into earlier checkpoint")
	var model:=State.new()
	ok(model.restore(market_fixture()),"narration isolation fixture")
	var world:=model.snapshot()
	for _i in range(8): n.observe(["allowance"]);n.step(0.1,true)
	check(model.snapshot()==world,"narrator has no mutation path to world or knowledge")

func _follow(scene, destination_phase: String, do_save: bool=false) -> void:
	var reached:=false
	var saved:=false
	for i in range(4000):
		if Road.phase(scene.model.road())==destination_phase:
			reached=true;break
		if Base.distance(scene.avatar.global_position,scene.merchant.global_position)>2.5:
			look(scene,scene.merchant.global_position)
			Input.action_press("move_forward")
		else: Input.action_release("move_forward")
		await physics_frame
		if i==250 and do_save:
			Input.action_release("move_forward")
			await tap(scene,KEY_F5)
			var old: Dictionary=scene.model.road()
			await frames(20)
			await tap(scene,KEY_F9)
			check(scene.model.road().accepted_tick==old.accepted_tick,"mid-route load keeps same contract")
			saved=true
	Input.action_release("move_forward")
	await frames(5)
	if not reached: print("ROAD DIAG: phase=",Road.phase(scene.model.road())," player=",scene.avatar.global_position," carrier=",scene.merchant.global_position," target=",Road.target(scene.model.road())," message=",scene._message)
	check(reached,"physical convoy reaches "+destination_phase)
	if do_save: check(saved,"mid-route save/load was exercised")

func _journey(choice: String) -> void:
	print("road physical journey: ",choice)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(market_fixture()),"install labelled market fixture")
	root.add_child(home)
	await frames(6)
	look(scene,Economy.MARKET)
	await tap(scene,KEY_E)
	await press(scene,"Escort via")
	check(scene.model.has_road() and scene.merchant.visible,"UI accepts real optional route")
	check(scene._boom.collision_layer==1,"physical checkpoint is now closed")
	await _follow(scene,"hear_claim")
	var at: Vector3=scene.merchant.global_position
	await frames(90)
	check(Base.distance(at,scene.merchant.global_position)<0.005,"carrier actually halts at the checkpoint")
	await walk(scene,Road.SPEAKER+Vector3.LEFT)
	look(scene,Road.SPEAKER)
	await tap(scene,KEY_E)
	check(scene._paused and scene.model.road().heard_tick>=0,"actual on-foot conversation receives claim")
	var frozen: Dictionary=scene.model.snapshot()
	await frames(40)
	check(scene.model.snapshot()==frozen,"conversation pauses road, caravan and economy")
	var prefix: String={"recognize_claim":"Recognize the local","seek_confirmation":"Ask for confirmation","bypass":"Use the longer"}[choice]
	await press(scene,prefix)
	if choice=="seek_confirmation":
		check(scene._boom.collision_layer==1,"inquiry alone leaves bar closed")
		await frames(Road.REPLY_DELAY+2)
		check(scene.model.road().reply_received_tick<0,"no telepathic permission on timer expiry")
		look(scene,Road.SPEAKER)
		await tap(scene,KEY_E)
		await press(scene,"Hear the returned")
		check(scene.model.road().reply_received_tick>=0,"reply acquired through actual interaction")
	check(scene._boom.collision_layer==(1 if choice=="bypass" else 0),"gate reflects the selected access, not a title")
	await _follow(scene,"arrived",true)
	await walk(scene,Economy.QUARTERMASTER+Vector3(0,0,-1))
	look(scene,Economy.QUARTERMASTER)
	await tap(scene,KEY_E)
	await press(scene,"Check the physically")
	check(Road.phase(scene.model.road())=="complete","physical check-in completes "+choice)
	check(scene.model.economy().ledger.caravan=="complete","original ledger settles same load")
	check(scene.model.economy().events.filter(func(e):return e.kind=="checkin").size()==1,"only one caravan payment")
	ok(scene.model.validate(scene.model.snapshot()),"played road state validates")
	reject(scene.model,scene.model.operate.bind("checkin"),"no second arrival reward")
	await tap(scene,KEY_N)
	frozen=scene.model.snapshot()
	await press(scene,"Turn narrator captions")
	await frames(40)
	check(scene.model.snapshot()==frozen,"caption toggle cannot change world or memory")
	await press(scene,"Return")
	home.queue_free()
	await frames()

func _spatial_and_restore() -> void:
	# Explicit scene fixtures for visibility/candidate geometry, not route traversal.
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(checkpoint_fixture()),"scene checkpoint fixture")
	root.add_child(home)
	await frames(5)
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(-14,1.05,-11.5),Vector3(-10,1.05,-11.5),1)
	var hit: Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==scene._boom,"closed road bar is a real collision obstacle")
	look(scene,Road.SPEAKER)
	scene.avatar.pivot.rotation.y+=PI
	await tap(scene,KEY_E)
	check(scene.model.road().heard_tick<0,"turning camera away cannot receive claim")
	look(scene,Road.SPEAKER)
	var wall: Node3D=scene._box(Vector3(0.2,2,1),Vector3(-16.5,1.0,-9.2),Color.GRAY,true).get_parent()
	await frames(2)
	await tap(scene,KEY_E)
	check(scene.model.road().heard_tick<0,"physical occlusion blocks roadkeeper account")
	wall.queue_free()
	await frames(3)
	look(scene,Road.SPEAKER)
	await tap(scene,KEY_E)
	check(scene.model.road().heard_tick>=0,"visible roadkeeper can be heard")
	var closed: Dictionary=scene.model.snapshot()
	await press(scene,"Recognize the local")
	check(scene._boom.collision_layer==0,"live gate is open before candidate test")
	await tap(scene,KEY_N)
	var live: Dictionary=scene.model.snapshot()
	var bad: Dictionary=closed.duplicate(true)
	bad.player.position=[-12,0.14,-11.5]
	bad.actors.ranjit_singh.position=bad.player.position.duplicate()
	var file:=FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(bad,"",true,true));file.close()
	scene._load()
	check(scene.model.snapshot()==live,"candidate closed gate rejects colliding actor without replacing world")
	check(scene._boom.collision_layer==0,"failed candidate check restores live gate collision state")
	var good: Dictionary=live.duplicate(true)
	good.player.position=[-12,0.14,-11.5]
	good.actors.ranjit_singh.position=good.player.position.duplicate()
	ok(scene.model.restore(closed),"restore closed-world scene fixture")
	scene._apply()
	file=FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(good,"",true,true));file.close()
	scene._load()
	check(scene._boom.collision_layer==0 and scene.model.road().choice=="recognize_claim","valid open-gate save not rejected by previously closed gate")
	check(scene.narration.current=="" and scene.narration.queued.is_empty(),"load resets stale presentation cues")
	# Old-slot import does not invent a road assignment or retain the closed bar.
	file=FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(market_fixture(),"",true,true));file.close()
	scene._load()
	check(not scene.model.has_road() and scene._boom.collision_layer==0,"legacy import leaves original route available")
	check(scene.narration.transcript.is_empty(),"old import creates no fake narrator transcript")
	home.queue_free()
	await frames()

func _run() -> void:
	_domain()
	_narration()
	await _spatial_and_restore()
	for choice in Road.CHOICES: await _journey(choice)
	for suffix in ["",".tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("SHAH_ROAD_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
