# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State := preload("res://narrative/oral_memory/memory_state.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const Narrator := preload("res://narrative/shah_observer.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Economy := preload("res://territory/misl_rules.gd")
const SAVE := "user://oral-memory-domain-test-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(s,action: Callable,label: String) -> void:
	var before: Dictionary=s.snapshot()
	check(not str(action.call()).is_empty(),label+" rejected")
	check(s.snapshot()==before,label+" leaves complete world unchanged")
func fresh() -> State:
	var s:=State.new()
	ok(s.restore(Fixture.complete()),"explicit completed-inquiry fixture")
	return s
func at(s: State,site_id: String) -> void:
	ok(Pose.pose(s,Memory.SITES[site_id]+Vector3(0,0,-1)),"explicit domain pose "+site_id)
func hear(s: State,id: String) -> void:
	at(s,Memory.content().tellings[id].site)
	ok(s.oral_operation("hear",id),"receive "+id)
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame

func _domain() -> void:
	ok(Memory.content_error(Memory.content()),"content contract")
	var c:=Memory.content()
	c.tellings.well_echo.root_id="invented_independent_source"
	check(not Memory.content_error(c).is_empty(),"an echo cannot be reclassified as an independent origin")
	check(Memory.content().tellings.well_echo.root_id!="invented_independent_source","content reads detached")
	var s:=State.new()
	reject(s,s.oral_operation.bind("hear","quartermaster_account"),"before inquiry")
	s=fresh()
	check(not s.has_oral_memory() and s.oral_view().tellings.is_empty(),"legacy import invents no story")
	check(not JSON.stringify(s.oral_view()).contains("permission_given"),"undiscovered catalogue is not public")
	reject(s,s.oral_operation.bind("retell","comparison"),"remote unknown retelling")
	reject(s,s.oral_operation.bind("compare","borrowed_rope"),"comparison without accounts")
	ok(s.begin_allowance(),"existing economy remains accessible")
	ok(s.begin_water_round(),"existing water task remains accessible")
	var money: Dictionary=s.economy().ledger
	var known: Array=s.snapshot().player.known_places.duplicate()
	hear(s,"quartermaster_account")
	check(s.oral_view().tellings.size()==1,"only actually received telling is projected")
	reject(s,s.oral_operation.bind("hear","quartermaster_account"),"duplicate hearing")
	reject(s,s.oral_operation.bind("hear","trader_account"),"remote hearing")
	reject(s,s.oral_operation.bind("hear","future_unknown_tale"),"unknown telling")
	hear(s,"trader_account")
	check(s.oral_view().distinct_reported_origins==2,"two reported origins, not a truth probability")
	hear(s,"well_echo")
	check(s.oral_view().tellings.size()==3 and s.oral_view().distinct_reported_origins==2,"echo adds a variant but not an origin")
	ok(s.oral_operation("compare","borrowed_rope"),"comparison of heard accounts")
	reject(s,s.oral_operation.bind("compare","borrowed_rope"),"duplicate comparison")
	at(s,"quartermaster")
	reject(s,s.oral_operation.bind("ask","quartermaster_reflection"),"question requires physical trace")
	at(s,"trace")
	ok(s.oral_operation("observe","rope_trace"),"material trace remains limited observation")
	at(s,"quartermaster")
	ok(s.oral_operation("ask","quartermaster_reflection"),"further recollection requested")
	reject(s,s.oral_operation.bind("hear","quartermaster_reflection"),"no immediate reply")
	ok(s.save_to(SAVE),"pending recollection saved with whole world")
	var copy:=State.new()
	ok(copy.load_from(SAVE),"pending recollection loaded")
	check(Economy._equal(s.snapshot(),copy.snapshot()),"JSON roundtrip preserves complete state")
	for _i in range(Memory.RECALL_TICKS-1): s.advance();copy.advance()
	reject(s,s.oral_operation.bind("hear","quartermaster_reflection"),"reply refused one tick early")
	s.advance();copy.advance()
	check(not s.oral_progress().heard.has("quartermaster_reflection"),"elapsed time alone conveys no answer")
	check(Economy._equal(s.snapshot(),copy.snapshot()),"saved pending clock replays identically")
	at(s,"listener")
	reject(s,s.oral_operation.bind("hear","quartermaster_reflection"),"mature reply still needs local hearing")
	at(s,"quartermaster")
	ok(s.oral_operation("hear","quartermaster_reflection"),"local reply at or after due time")
	check(s.oral_view().distinct_reported_origins==2,"later recollection keeps its source root")
	at(s,"listener")
	ok(s.oral_operation("retell","quartermaster_account"),"attributed story reaches a listener")
	check(s.listener_response().contains("not something you saw"),"listener retains hearsay distinction")
	ok(s.oral_operation("retell","comparison"),"listener can receive a later qualified telling")
	check(s.listener_response().contains("difference"),"listener changes only after a received retelling")
	reject(s,s.oral_operation.bind("retell","comparison"),"duplicate retelling grants nothing")
	check(s.economy().ledger==money and s.snapshot().player.known_places==known,"no money, troop or geographic-knowledge reward")
	check(s.has_water_round() and s.water_round().events.is_empty(),"oral memory does not drive the water task")
	var view:=s.oral_view()
	view.tellings.clear()
	check(s.oral_view().tellings.size()==4,"public projections are detached")
	var observer:=Narrator.new()
	var before:=s.snapshot()
	check(observer.observe(before).contains("Shah Muhammad"),"retrospective presentation observes received events")
	check(s.snapshot()==before,"narrator cannot mutate live memory")
	observer.rebind(s.snapshot())
	check(observer.observe(s.snapshot()).is_empty(),"load baselines narration without replaying it")
	for what in ["schema","digest","extra","origin","seq","future","fraction","bool","parent","actor","operation","position","nan","duplicate","unknown","oversize","empty","late_origin"]:
		var bad:=s.snapshot()
		match what:
			"schema": bad.oral_memory.schema="unknown"
			"digest": bad.oral_memory.content_digest="changed-content"
			"extra": bad.oral_memory.canonical_truth="permission_given"
			"origin": bad.oral_memory.origin_tick=-1
			"seq": bad.oral_memory.events[0].seq=9
			"future": bad.oral_memory.events[0].tick=bad.childhood.tick+1
			"fraction": bad.oral_memory.events[0].tick=4.5
			"bool": bad.oral_memory.events[0].seq=true
			"parent": bad.oral_memory.events[-1].parent_seq=0
			"actor": bad.oral_memory.events[0].actor_id="shah_muhammad"
			"operation": bad.oral_memory.events[0].operation_id="oral-memory.retell.v1"
			"position": bad.oral_memory.events[0].position=[-24,0.14,-15]
			"nan": bad.oral_memory.events[0].position=[NAN,0.14,0]
			"duplicate": bad.oral_memory.events.append(bad.oral_memory.events[-1].duplicate(true))
			"unknown": bad.oral_memory.events[0].subject_id="unheard_secret"
			"oversize":
				for _i in range(33): bad.oral_memory.events.append(bad.oral_memory.events[0].duplicate(true))
			"empty": bad.oral_memory.events=[]
			"late_origin": bad.oral_memory.origin_tick+=1
		reject(s,s.restore.bind(bad),"malformed save "+what)
	# The narrative extension cannot permanently eclipse the inherited supply-story cues.
	s.advance()
	at(s,"quartermaster");ok(s.operate("accept_delivery"),"inherited delivery after oral episode")
	at(s,"market");ok(s.operate("deliver"),"inherited payment after oral episode")
	check(Narrator.key_for(s.snapshot())=="market","later inherited narrator cue is preserved")
	# Mounted status is a present admission constraint, not reconstructed from old coordinates.
	ok(Pose.pose(s,State.point(s.horse_record().position)+Vector3.RIGHT),"mounted refusal fixture")
	ok(s.mount(),"existing horse can still be mounted")
	reject(s,s.oral_operation.bind("compare","borrowed_rope"),"mounted memory operation")
	ok(s.restore(Fixture.complete()),"whole-world rollback to older save")
	check(not s.has_oral_memory() and not s.has_economy() and not s.has_water_round(),"rollback discards all future domains together")
	check(s.listener_response().contains("What have you heard"),"rollback discards listener's future knowledge")
	# Nonlinear entry: a trace or a transmitted account can be found before the household telling.
	at(s,"trace");ok(s.oral_operation("observe","rope_trace"),"exploration-first discovery")
	hear(s,"well_echo")
	check(s.oral_view().tellings.size()==1 and s.oral_view().distinct_reported_origins==1,"echo-first discovery reveals no unreceived telling")
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
	check(false,"UI action missing: "+prefix+" in "+scene._panel_text.text)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1400):
		if State.distance(scene.avatar.global_position,p)<0.42: reached=true;break
		look(scene,p);Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(8)
	check(reached,"input/collision walk to "+str(p)+"; actual "+str(scene.avatar.global_position))

func _journey() -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://oral-memory-journey-test-only.json"
	ok(scene.model.restore(Fixture.complete()),"explicit post-inquiry journey start; no later pose injection")
	root.add_child(home)
	await frames()
	look(scene,Memory.SITES.quartermaster)
	await tap(scene,KEY_E)
	# A queued dialogue command must recheck actual occlusion, not trust a stale menu.
	var wall:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new();box.size=Vector3(2,2,0.15)
	shape.shape=box;wall.add_child(shape);wall.position=Vector3(3,1.2,4.5)
	home.add_child(wall)
	await frames()
	await press(scene,"Listen to the quartermaster")
	check(not scene.model.has_oral_memory(),"occluded queued hearing refused")
	wall.queue_free();await frames()
	await press(scene,"Return")
	look(scene,Memory.SITES.quartermaster)
	await tap(scene,KEY_E);await press(scene,"Listen to the quartermaster")
	check(scene.model.oral_progress().heard.has("quartermaster_account"),"actual UI hearing records first account")
	var frozen: Dictionary=scene.model.snapshot()
	await frames(30)
	check(scene.model.snapshot()==frozen,"story reading pauses existing clock and every world domain")
	await press(scene,"Continue")
	await walk(scene,Vector3(2,0.14,-10))
	await walk(scene,Vector3(-17,0.14,-10))
	await walk(scene,Vector3(-24,0.14,-13))
	look(scene,Memory.SITES.market)
	await tap(scene,KEY_E);await press(scene,"Listen to the trader")
	check(scene.model.oral_progress().heard.has("trader_account"),"different account requires reaching market")
	await press(scene,"Continue")
	await walk(scene,Vector3(-17,0.14,-10))
	await walk(scene,Vector3(2,0.14,-10))
	await walk(scene,Vector3(14,0.14,-10))
	await walk(scene,Vector3(14,0.14,-2))
	look(scene,Memory.SITES.trace)
	await tap(scene,KEY_E);await press(scene,"Inspect the rope")
	check(scene.model.oral_progress().trace_seq>0,"actual eye-visible material inspection")
	await press(scene,"Continue")
	await tap(scene,KEY_F7);await press(scene,"Compare the two")
	check(scene.model.oral_progress().compared_seq>0,"reflection compares only received accounts")
	await press(scene,"Continue")
	await walk(scene,Vector3(14,0.14,4))
	await walk(scene,Vector3(3,0.14,4))
	look(scene,Memory.SITES.quartermaster)
	await tap(scene,KEY_E);await press(scene,"Ask the quartermaster")
	await press(scene,"Continue")
	ok(scene.model.save_to(scene.save_path),"pending local recollection saved")
	await frames(310)
	check(not scene.model.oral_progress().heard.has("quartermaster_reflection"),"no remote or automatic delivery")
	await tap(scene,KEY_E);await press(scene,"Listen for the quartermaster")
	check(scene.model.oral_progress().heard.has("quartermaster_reflection"),"returning to listen discovers reflection")
	scene._load()
	check(not scene.model.oral_progress().heard.has("quartermaster_reflection"),"load rolls later testimony back")
	check(scene.narrator.text.is_empty(),"load does not replay a narrator cue")
	await frames(310)
	look(scene,Memory.SITES.quartermaster)
	await tap(scene,KEY_E);await press(scene,"Listen for the quartermaster")
	await press(scene,"Continue")
	await walk(scene,Vector3(2,0.14,-10))
	await walk(scene,Vector3(26,0.14,-10))
	await walk(scene,Vector3(26,0.14,20))
	look(scene,Memory.SITES.listener)
	await tap(scene,KEY_E);await press(scene,"Hear what the neighbour")
	await press(scene,"Continue")
	await tap(scene,KEY_E);await press(scene,"Retell the quartermaster")
	await press(scene,"Continue")
	await tap(scene,KEY_E);await press(scene,"Retell both accounts")
	check(scene.model.oral_view().retellings.size()==2,"listener receives two sequential attributed tellings")
	check(scene.model.oral_view().distinct_reported_origins==2,"repetition does not manufacture corroboration")
	check(not scene.model.has_economy(),"oral story needs no allowance and mints no economy")
	ok(scene.model.save_to(scene.save_path),"completed oral loop saved")
	var snapshot: Dictionary=scene.model.snapshot()
	var audit: Dictionary={"schema":"1792.oral-memory-observation.v1","evidence_kind":"synthetic_validation",
		"model_id":Memory.MODEL_ID,"operation_ids":Memory.OP_IDS.values(),"execution_id":OS.get_environment("GITHUB_RUN_ID"),
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"verification_id":"oral-memory-native-conformance.v1",
		"engine":Engine.get_version_info().string,"content_sha256":Memory.content_digest(),
		"oral_snapshot_sha256":JSON.stringify(snapshot.oral_memory,"",true,true).sha256_text(),
		"receipts":snapshot.oral_memory.events.size(),"distinct_reported_origins":scene.model.oral_view().distinct_reported_origins,
		"history_verified":false,"human_playtest":false,"passed":passed,"failed":failed}
	var file:=FileAccess.open("user://oral-memory-audit.json",FileAccess.WRITE)
	check(file!=null,"retain conformance evidence")
	if file!=null:
		audit.passed=passed
		audit.failed=failed
		file.store_string(JSON.stringify(audit,"\t"))
		file.close()
	DirAccess.remove_absolute(scene.save_path)
	home.queue_free();await frames()
func _run() -> void:
	_domain()
	await _journey()
	print("ORAL_MEMORY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
