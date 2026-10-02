extends SceneTree
## Domain fixtures are labelled separately from input/collision-driven journeys.
const State := preload("res://remounts/remount_state.gd")
const R := preload("res://remounts/remount_rules.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Base := preload("res://childhood/childhood_state.gd")
const SAVE := "user://remount-regression-only.json"
var passed:=0
var failed:=0

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else:
		failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func same_retained(a: Variant,b: Variant) -> bool:
	# JSON preserves discrete knowledge exactly; collision poses tolerate serialization rounding only.
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_retained(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same_retained(a[i],b[i]): return false
		return true
	if a is float or b is float:
		return Supply.finite_number(a) and Supply.finite_number(b) and absf(a-b)<=1e-12
	return typeof(a)==typeof(b) and a==b
func reject(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(action.call()).is_empty(),label+" refuses")
	check(model.snapshot()==before,label+" preserves state")
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
	for button in scene._actions.get_children():
		if button.text.begins_with(text):
			button.pressed.emit();await frames(2);return
	check(false,"missing action "+text)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1300):
		if Base.distance(scene.avatar.global_position,p)<0.5: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(8)
	if not reached: print("REMOUNT WALK DIAG ",scene.avatar.global_position," -> ",p," message ",scene._message)
	check(reached,"walk "+str(p))
func fresh() -> State:
	var s:=State.new();ok(s.restore(Fixture.complete()),"completed inquiry fixture")
	ok(s.begin_allowance(),"allowance");ok(s.begin_remounts(),"investigation")
	return s
func _domain() -> void:
	var s:=State.new()
	reject(s,s.begin_remounts,"no mission during tutorial")
	s=fresh()
	reject(s,s.begin_remounts,"one beginning")
	reject(s,s.remount_action.bind("resolve"),"no outcome before evidence")
	ok(Pose.pose(s,R.OBSERVERS.yard_gatekeeper.position),"gate fixture")
	reject(s,s.remount_action.bind("permission"),"no implied social permission")
	ok(Pose.pose(s,Supply.MARKET),"market fixture")
	ok(s.remount_action("introduction"),"introduction")
	reject(s,s.remount_action.bind("introduction"),"one testimony source")
	ok(Pose.pose(s,R.OBSERVERS.yard_gatekeeper.position),"gate fixture")
	ok(s.remount_action("permission"),"explicit permission")
	ok(Pose.pose(s,Vector3(5.5,0.14,21)),"visible permitted fixture")
	ok(s.observe_yard("yard_gatekeeper",true,0),"perceived permitted person")
	check(s.remounts().ledger.contacts.yard_gatekeeper.identified_tick>=0,"familiar observer recognizes")
	check(s.remounts().ledger.report.stage=="none","visibility is not trespass")
	var before: Dictionary=s.snapshot()
	ok(s.observe_yard("yard_gatekeeper",true,0),"repeated perception")
	check(s.snapshot()==before,"repeat is not corroboration")
	var m:=s.snapshot();m.remounts.ledger.permission=false
	reject(s,s.restore.bind(m),"tampered permission")
	m=s.snapshot();m.remounts.ledger.response.reserve=9
	reject(s,s.restore.bind(m),"fabricated reserve")
	m=s.snapshot();m.remounts.events[0].tick=m.childhood.tick+1
	reject(s,s.restore.bind(m),"future event")
	m=s.snapshot();m.remounts.events[1].detail={"extra":1}
	reject(s,s.restore.bind(m),"unexpected payload")
	ok(s.save_to(SAVE),"save permitted state")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load permitted state")
	check(Supply._equal(loaded.snapshot(),s.snapshot()),"full JSON roundtrip")
	var senses:=R.sense("yard_gatekeeper",Vector3(5.5,0.14,21),0,false)
	check(not senses.seen and not senses.identified,"occlusion prevents identification")
	senses=R.sense("yard_keeper",Vector3(-7,0.14,23),0,true)
	check(senses.seen and not senses.identified,"unfamiliar witness cannot name player")
	s=fresh();ok(Pose.pose(s,Vector3(-7,0.14,24.5)),"noise fixture")
	ok(s.observe_yard("yard_keeper",false,4.5),"nearby sound behind obstruction")
	check(s.remounts().ledger.contacts.yard_keeper.seen_tick==-1,"hearing is not seeing")
	check(s.remounts().ledger.contacts.yard_keeper.identified_tick==-1,"hearing is not identity")
	check(s.remounts().ledger.contacts.yard_keeper.place==Base.coords(R.HITCH),"coarse acoustic location")
	check(s.remounts().ledger.recipient_knowledge.is_empty(),"no instant faction knowledge")
	check(not s.remounts().ledger.memories.any(func(x): return "report" in x.id),"player journal omits hidden reports")
	reject(s,s.rest_watch,"no fast-forward through moving message")
	var teleport:=R.agent("yard_runner",R.POST)
	reject(s,s.record_remount_agent.bind("runner",teleport,1.0/60),"no messenger teleport")
	# Existing economy remains the ONLY household horse/fund ledger.
	var money: Dictionary=s.economy().ledger.duplicate(true)
	for kind in ["note","horses","resolve"]:
		var at: Vector3=R.NOTE if kind=="note" else R.HITCH if kind=="horses" else Supply.QUARTERMASTER
		ok(Pose.pose(s,at),"action fixture "+kind);ok(s.remount_action(kind),kind)
	check(s.remounts().ledger.resolved,"objective resolved")
	check(s.economy().ledger==money,"no duplicate remounts or invented treasury reward")
	reject(s,s.remount_action.bind("resolve"),"no repeat resolution")
	check(s.journal().any(func(x): return x.channel=="read_aloud" and x.id=="remounts_resolve"),"Buddh hears tally; no granted literacy")
	ok(s.validate(s.snapshot()),"closed domain encounter validates")
	ok(s.restore(Fixture.complete()),"older save replaces whole state")
	check(not s.has_remounts() and not s.has_economy(),"discarded future not carried backward")

func _relay_boundaries() -> void:
	var ledger:=R.initial()
	var seq:=0
	var apply_event:=func(kind: String,tick: int,detail: Dictionary) -> String:
		seq+=1
		return R.apply(ledger,{"seq":seq,"kind":kind,"tick":tick,"detail":detail})
	ok(apply_event.call("begin",0,{}),"relay fixture begin")
	ok(apply_event.call("seen",1,{"observer":"yard_keeper","place":[-7,0.14,23]}),"unfamiliar source saw an actor")
	check(not apply_event.call("collect",60,{"position":Base.coords(R.OBSERVERS.yard_keeper.position)}).is_empty(),"pickup delay enforced")
	check(not apply_event.call("collect",61,{"position":Base.coords(R.POST)}).is_empty(),"no remote pickup")
	ok(apply_event.call("collect",61,{"position":Base.coords(R.OBSERVERS.yard_keeper.position)}),"physical pickup fixture")
	ok(apply_event.call("seen",62,{"observer":"yard_gatekeeper","place":[5.5,0.14,21]}),"other witness later sees")
	ok(apply_event.call("identified",62,{"observer":"yard_gatekeeper","place":[5.5,0.14,21]}),"other witness later identifies")
	check(ledger.report.subject=="" and ledger.report.sender=="yard_keeper","other observer cannot rewrite packet in custody")
	check(ledger.recipient_knowledge.is_empty(),"no recipient knowledge before delivery")
	check(not apply_event.call("deliver",180,{"position":Base.coords(R.POST)}).is_empty(),"delivery time enforced")
	check(not apply_event.call("deliver",181,{"position":Base.coords(R.HITCH)}).is_empty(),"no remote delivery")
	ok(apply_event.call("deliver",181,{"position":Base.coords(R.POST)}),"delivered anonymous packet")
	check(ledger.recipient_knowledge[0].subject=="" and ledger.relations.yard_custodians.grievance==0,"anonymous activity is not a named accusation")
	check(not apply_event.call("deliver",182,{"position":Base.coords(R.POST)}).is_empty(),"no duplicate packet or reserve")
	check(not apply_event.call("response_arrive",182,{"position":Base.coords(R.POST)}).is_empty(),"reserve cannot arrive remotely")
	ok(apply_event.call("response_arrive",190,{"position":[-7,0.14,23]}),"reported-place search fixture")
	check(not apply_event.call("response_return",789,{}).is_empty(),"bounded search cannot finish early")
	ok(apply_event.call("response_return",790,{}),"search interval reached")
	check(not apply_event.call("response_home",791,{"position":Base.coords(R.HITCH)}).is_empty(),"reserve must return physically")
	ok(apply_event.call("response_home",800,{"position":Base.coords(R.POST)}),"same reserve returns")
	check(ledger.response.reserve==1,"one reserve conserved")
	var s:=fresh();var value:=s.snapshot()
	value.remounts.runner.position[1]=0.10023;value.remounts.responder.position[1]=0.10023
	ok(s.restore(value),"idle collision-floor settling allowed")
	value=s.snapshot();value.remounts.responder.position[0]+=1
	reject(s,s.restore.bind(value),"idle horizontal teleport")
	value=s.snapshot();value.remounts.ledger.recipient_knowledge.append({"subject":"ranjit_singh"})
	reject(s,s.restore.bind(value),"injected recipient knowledge")

func _start_scene() -> Node3D:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"only initial inquiry fixture")
	root.add_child(home);await frames(6)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Investigate the two");await press(scene,"Find the horses")
	check(scene.model.has_remounts() and scene.runner.visible,"mission starts through real menu signals")
	return home

func _social_journey() -> void:
	var home:=await _start_scene();var scene=home.get_node("ChildhoodChapter")
	for p in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-14)]: await walk(scene,p)
	look(scene,Supply.MARKET);await tap(scene,KEY_E);await press(scene,"Ask the handler")
	check(scene.model.remounts().ledger.introduced,"physical market visit receives introduction")
	for p in [Vector3(-13,0,-11),Vector3(22,0,-10),Vector3(24,0,-7),Vector3(24,0,13.2),Vector3(13,0,13.2),Vector3(13,0,21)]: await walk(scene,p)
	look(scene,R.OBSERVERS.yard_gatekeeper.position);await tap(scene,KEY_E);await press(scene,"Present the handler")
	check(scene.model.remounts().ledger.permission,"guard grants access")
	for p in [Vector3(8.5,0,21),Vector3(0,0,22.8),Vector3(-5,0,22.8)]: await walk(scene,p)
	look(scene,R.NOTE);await tap(scene,KEY_E)
	check(scene.model.remounts().ledger.note,"physically acquire sealed tally")
	await walk(scene,Vector3(0,0,22.8));await walk(scene,Vector3(4,0,23.5))
	look(scene,R.HITCH);await tap(scene,KEY_E)
	check(scene.model.remounts().ledger.horses,"observe remounts in actual yard")
	check(scene.model.remounts().ledger.report.stage=="none","introduced visit creates no complaint")
	await tap(scene,KEY_F5);var saved: Dictionary=scene.model.snapshot();await frames(10);await tap(scene,KEY_F9)
	check(same_retained(scene.model.remounts().ledger,saved.remounts.ledger),"save/load retains serialized permission and observations")
	for p in [Vector3(4,0,21),Vector3(13,0,21),Vector3(13,0,13.2),Vector3(24,0,13.2),Vector3(24,0,-10),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Give the remount")
	check(scene.model.remounts().ledger.resolved,"input-driven introduction route completes")
	check(scene._panel_text.text.contains("Buddh · The cord marks matched.") and scene._panel_text.text.contains("The gatekeeper gave me permission"),"social return stages own observation before retained read-aloud account")
	var closed: Dictionary=scene.model.snapshot();var camera: Transform3D=scene.avatar.pivot.transform
	await press(scene,"And the horses?");await frames(20)
	check(scene._panel_text.text.contains("Now the adults must arrange their return"),"optional aftermath distinguishes discovery from possession")
	check(scene.model.snapshot()==closed and scene.avatar.pivot.transform==camera,"aftermath preserves world, pause and camera")
	ok(scene.model.validate(scene.model.snapshot()),"social journey state validates")
	home.queue_free();await frames()

func _service_journey() -> void:
	var home:=await _start_scene();var scene=home.get_node("ChildhoodChapter")
	for p in [Vector3(2,0,-10),Vector3(-22,0,-10),Vector3(-22,0,14),Vector3(-13,0,14),Vector3(-13,0,24),Vector3(-9,0,24),Vector3(-9,0,22),Vector3(-6.5,0,22.5)]: await walk(scene,p)
	look(scene,R.NOTE);await tap(scene,KEY_E)
	check(scene.model.remounts().ledger.note,"service passage reaches real tally")
	for p in [Vector3(-7,0,23.3),Vector3(0,0,23.3),Vector3(4,0,23.5)]: await walk(scene,p)
	look(scene,R.HITCH);await tap(scene,KEY_E)
	check(scene.model.remounts().ledger.horses and not scene.model.remounts().ledger.permission,"observation does not require magic permission flag")
	check(scene.model.remounts().ledger.contacts.yard_keeper.identified_tick==-1,"unfamiliar keeper never acquires identity")
	for p in [Vector3(0,0,23.3),Vector3(-7,0,23.3),Vector3(-9,0,22.8),Vector3(-9,0,24),Vector3(-13,0,24),Vector3(-22,0,14),Vector3(-22,0,-10),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Give the remount")
	check(scene.model.remounts().ledger.resolved and scene.model.remounts().ledger.resolution_context=="unpermitted_visit","service route independently completes the same objective")
	ok(scene.model.validate(scene.model.snapshot()),"unpermitted journey validates")
	home.queue_free();await frames()

func _overlook_journey() -> void:
	var home:=await _start_scene();var scene=home.get_node("ChildhoodChapter")
	for p in [Vector3(2,0,-10),Vector3(24,0,-10),Vector3(24,0,13.2),Vector3(-3,0,13.2),Vector3(-3,0,17.7)]: await walk(scene,p)
	check(scene.avatar.global_position.y>1.4,"existing character physically ascends overlook")
	await walk(scene,Vector3(-3,0,22.8))
	check(scene.avatar.global_position.y<0.3,"walkable descent reaches yard floor")
	check(not scene._observer_clear("yard_keeper"),"actual screen collision occludes keeper ray")
	await walk(scene,Vector3(-5,0,22.8));look(scene,R.NOTE);await tap(scene,KEY_E)
	await walk(scene,Vector3(0,0,22.8));await walk(scene,Vector3(4,0,23.5));look(scene,R.HITCH);await tap(scene,KEY_E)
	check(scene.model.remounts().ledger.note and scene.model.remounts().ledger.horses,"overlook route acquires both distinct observations")
	for p in [Vector3(4,0,21),Vector3(13,0,21),Vector3(13,0,13.2),Vector3(24,0,13.2),Vector3(24,0,-10),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Give the remount")
	check(scene.model.remounts().ledger.resolved,"overlook route completes through real report signal")
	check(scene._panel_text.text.contains("I went inside without asking"),"unpermitted route callback describes only Buddh's own action")
	ok(scene.model.validate(scene.model.snapshot()),"overlook completed state validates")
	home.queue_free();await frames()

func _messenger_journey() -> void:
	# Start from an explicit unauthorized-visible pose fixture; all subsequent motion is physical.
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	var s:=fresh();ok(Pose.pose(s,Vector3(5.5,0.14,21)),"identified-incursion pose fixture")
	ok(scene.model.restore(s.snapshot()),"install incursion fixture")
	root.add_child(home);await frames(8)
	check(scene.model.remounts().ledger.report.stage=="queued","real ray creates local report")
	check(scene.model.remounts().ledger.recipient_knowledge.is_empty(),"no remote pre-delivery knowledge")
	var observed: Array=scene.model.remounts().ledger.contacts.yard_gatekeeper.place.duplicate()
	await walk(scene,Vector3(13,0,21))
	scene._open_accounts();var frozen: Dictionary=scene.model.snapshot();await frames(50)
	check(scene.model.snapshot()==frozen,"menus pause clock, runner and reserve together")
	scene._resume()
	var saved_midway:=false
	var delivered:=false
	for _i in range(4800):
		var m: Dictionary=scene.model.remounts()
		if m.ledger.report.stage=="in_transit" and not saved_midway:
			await tap(scene,KEY_F5);var saved: Dictionary=scene.model.snapshot()
			await frames(20);await tap(scene,KEY_F9)
			check(Base.distance(scene.runner.global_position,Base.point(saved.remounts.runner.position))<0.3,"mid-flight restore keeps messenger custody and pose")
			saved_midway=true
		if m.ledger.report.stage=="delivered" and not delivered:
			delivered=true
			check(m.ledger.recipient_knowledge.size()==1,"one delivered report, not duplicated corroboration")
			check(m.ledger.report.subject==Base.Names.HERO_ID,"identity arrives only with its witness report")
			check(m.ledger.response.reserve==0,"finite reserve is actually consumed")
			check(m.ledger.response.target==observed,"response searches retained location, not current actor")
			check(Base.distance(Base.point(m.ledger.response.target),scene.model.position())>3,"player already left search location")
		if m.ledger.response.stage=="complete": break
		await physics_frame
	check(saved_midway and delivered,"physical messenger completed both handovers")
	check(scene.model.remounts().ledger.response.stage=="complete","searcher physically returned after bounded search")
	check(scene.model.remounts().ledger.response.reserve==1,"same reserve returned, not a new spawn")
	check(scene.model.remounts().ledger.relations.yard_custodians.grievance==1,"identified complaint persists")
	ok(scene.model.validate(scene.model.snapshot()),"messenger/search journey validates")
	var output:=FileAccess.open("user://remounts-trace.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(scene.model.remount_trace(),"",true,true));output.close()
	scene._open_accounts();var before: Dictionary=scene.model.snapshot();var bad:=before.duplicate(true)
	bad.remounts.runner.position=[10,0.14,25]
	var f:=FileAccess.open(SAVE,FileAccess.WRITE);f.store_string(JSON.stringify(bad,"",true,true));f.close()
	scene._load();check(scene.model.snapshot()==before,"blocked save refuses without partial live-state replacement")
	home.queue_free();await frames()

func _run() -> void:
	_domain()
	_relay_boundaries()
	await _social_journey()
	await _service_journey()
	await _overlook_journey()
	await _messenger_journey()
	for suffix in ["",".tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("REMOUNTS_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
