# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State:=preload("res://commissions/commission_state.gd")
const C:=preload("res://commissions/commission_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const SAVE:="user://commission-regression-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(b: bool,label: String) -> void:
	if b: passed+=1
	else: failed+=1;push_error("COMMISSION FAIL: "+label)
func ok(e: String,label: String) -> void: check(e.is_empty(),label+" "+e)
func refuse(m,fn: Callable,label: String) -> void:
	var before: Dictionary=m.snapshot();check(not fn.call().is_empty(),"refuse "+label);check(Supply._equal(before,m.snapshot()),"atomic "+label)
func fresh() -> RefCounted:
	var m:=State.new();ok(m.restore(Fixture.complete()),"labelled completed-inquiry domain fixture");ok(m.begin_allowance(),"allowance");return m
func near(m,p: Vector3) -> void: ok(Pose.pose(m,p),"domain pose fixture")
func recruit(m) -> void:
	ok(m.commission_action("reserve","standard"),"reserve")
	near(m,C.BROKER);ok(m.commission_action("broker"),"agent paid")
	near(m,C.RECEPTION);ok(m.commission_action("engage"),"candidate accepts")
	# Declared domain-only final-location fixture; the separate engine journey moves the body.
	var s: Dictionary=m.snapshot();s.commission_actor.position=Base.coords(C.HOME+Vector3.RIGHT)
	ok(m.restore(s),"domain arrived specialist fixture");near(m,C.HOME)
	ok(m.commission_action("appoint"),"sign")
func domain() -> void:
	var m:=fresh()
	refuse(m,m.commission_action.bind("reserve","senior"),"senior offer exceeds 120 available")
	refuse(m,m.commission_action.bind("reserve","allard"),"later officer not available in childhood")
	ok(m.commission_action("reserve","standard"),"108 reserved")
	check(m.economy().ledger.treasury==12 and m.commission().escrow==108 and m.economy().ledger.purse==18,"funds committed once, personal purse separate")
	refuse(m,m.commission_action.bind("reserve","standard"),"duplicate reservation")
	refuse(m,m.commission_action.bind("broker"),"remote fee delivery")
	ok(m.commission_action("cancel"),"unspent cancellation")
	check(m.economy().ledger.treasury==120 and m.commission().escrow==0,"full unspent refund")
	refuse(m,m.commission_action.bind("cancel"),"duplicate refund")
	m=fresh();ok(m.commission_action("reserve","standard"),"second fixture")
	near(m,C.BROKER);ok(m.commission_action("broker"),"paid introduction")
	refuse(m,m.commission_action.bind("broker"),"double fee")
	near(m,C.HOME);ok(m.commission_action("cancel"),"cancel after broker")
	check(m.economy().ledger.treasury==112 and m.commission().spent==8,"earned agent fee not refunded")
	m=fresh();recruit(m)
	check(m.commission().escrow==24 and m.commission().spent==84 and m.economy().ledger.treasury==12,"appointment debit partition")
	var purse: int=m.economy().ledger.purse
	ok(m.rest_watch(),"first upkeep watch")
	check(m.commission().escrow==12 and m.commission().arrears==0,"wages debit earmarked reserve")
	ok(m.rest_watch(),"second upkeep watch")
	check(m.commission().escrow==0,"second reserved wage paid once")
	ok(m.rest_watch(),"third watch")
	check(m.commission().arrears>0 and not C.ready(m.economy().ledger),"no funds means actual arrears and unavailable drill")
	check(m.economy().ledger.purse==purse,"payroll never steals private funds")
	refuse(m,m.commission_action.bind("lesson_start"),"unpaid unsupported drill")
	var before: Dictionary=m.snapshot();ok(m.save_to(SAVE),"save arrears")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load arrears");check(Supply._equal(JSON.parse_string(JSON.stringify(before,"",true,true)),JSON.parse_string(JSON.stringify(loaded.snapshot(),"",true,true))),"same serialized whole state after JSON numeric normalization")

	for fault in ["escrow","actor","tick","phase","extra","practice","control","velocity"]:
		var bad:=before.duplicate(true)
		match fault:
			"escrow": bad.misl.ledger.commission.escrow+=1
			"actor": bad.commission_actor.id="jean_francois_allard"
			"tick": var d: Dictionary=JSON.parse_string(bad.misl.events[0].arg);d.tick+=1;bad.misl.events[0].arg=JSON.stringify(d)
			"phase": bad.misl.ledger.commission.phase="cancelled"
			"extra": bad.commission_actor.extra=1
			"practice": bad.commission_actor.practice=180
			"control": bad.misl.ledger.commission.controlled="sada_kaur"
			"velocity": bad.commission_actor.velocity=[100,0,0]
		refuse(m,m.restore.bind(bad),"tampered "+fault)
	ok(m.commission_action("dismiss"),"dismiss present unpaid instructor")
	check(m.commission().arrears>0,"dismissal does not erase earned wage debt")
	ok(m.operate("contribute"),"explicit personal contribution")
	ok(m.commission_action("pay_arrears"),"settle dismissed wage claim")
	check(m.commission().arrears==0,"debt paid")
	ok(m.restore(Fixture.complete()),"rewind entire old state")
	check(not m.commissioned() and not m.has_economy(),"no future contract survives rewind")
	m=fresh();near(m,C.HOME+Vector3(0,3,0))
	refuse(m,m.commission_action.bind("reserve","standard"),"wrong floor")
	m=fresh();recruit(m)
	var snapshot: Dictionary=m.snapshot()
	ok(m.commission_action("control",C.SPECIALIST),"grant limited viewpoint")
	check(m.position()==Base.point(snapshot.player.position) and m.specialist().position==snapshot.commission_actor.position,"switch moves neither body")
	check(m.economy().ledger.treasury==snapshot.misl.ledger.treasury and m.economy().ledger.stock==snapshot.misl.ledger.stock,"switch grants no assets")
	check(m.journal().is_empty(),"new controlled actor receives none of Buddh's private journal")
	refuse(m,m.operate.bind("buy","food"),"no treasury authority for instructor")
	refuse(m,m.mount,"no duplicate rider authority")
	ok(m.commission_action("control",C.HERO),"return principal control")
	check(m.journal().size()>0,"principal observations preserved")

func interlocks() -> void:
	var m:=fresh()
	ok(m.operate("accept_delivery"),"domain accepted income task")
	near(m,C.BROKER);ok(m.operate("deliver"),"domain earned delivered income")
	near(m,C.HOME);recruit(m)
	ok(m.operate("hire","guard"),"domain drill pupil")
	ok(m.rest_watch(),"domain provision pupil")
	ok(m.commission_action("lesson_start"),"domain funded drill")
	refuse(m,m.begin_brawl,"drill excludes brawl")
	refuse(m,m.begin_service,"drill excludes new service")
	refuse(m,m.begin_water_round,"drill excludes water")
	refuse(m,m.operate.bind("accept_delivery"),"drill excludes hand cargo")
	refuse(m,m.commission_action.bind("control",C.SPECIALIST),"no role switch during drill")
	refuse(m,m.operate.bind("release_guard"),"committed pupil retained")
	m.advance();m.progress_drill(false)
	check(m.specialist().practice==0,"no invisible drill credit")
	m.progress_drill(true);var count: int=m.specialist().practice
	m.progress_drill(true);check(count==1 and m.specialist().practice==1,"only one practice increment per common tick")
	ok(m.validate(m.snapshot()),"partial drill state validates")

func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var actor: CharacterBody3D=scene.specialist_body if scene.model.controlling_specialist() else scene.avatar
	var d:=p-actor.global_position;actor.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true;scene._unhandled_input(e);await frames(2)
func press(scene,prefix: String) -> void:
	for b in scene._actions.get_children():
		if b.text.begins_with(prefix): b.pressed.emit();await frames(2);return
	check(false,"missing button "+prefix)
func walk(scene,p: Vector3,slow: bool=false) -> void:
	var reached:=false
	for _i in range(1800):
		var actor: CharacterBody3D=scene.specialist_body if scene.model.controlling_specialist() else scene.avatar
		if Base.distance(actor.global_position,p)<0.5: reached=true;break
		look(scene,p);Input.action_press("move_forward",0.45 if slow else 1);await physics_frame
	Input.action_release("move_forward");await frames(6)
	if not reached: print("COMMISSION WALK ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(reached,"walk "+str(p))
func camera_ownership() -> void:
	# Declared presentation fixture: ordinary scene hydration cannot seize its camera.
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	root.add_child(home);await frames(8)
	check(root.get_camera_3d()==scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D"),"secondary body does not steal initial scene camera")
	var external:=Camera3D.new();home.add_child(external);external.current=true
	var before: Dictionary=scene.model.snapshot()
	scene._sync_commission()
	check(root.get_camera_3d()==external,"ordinary commission sync preserves selected camera")
	scene._apply()
	check(root.get_camera_3d()==external,"uncommissioned whole-world hydration preserves selected camera")
	scene._open_journal()
	check(root.get_camera_3d()==external,"ordinary modal preserves selected camera")
	scene._resume()
	check(root.get_camera_3d()==external,"ordinary resume preserves selected camera")
	check(Supply._equal(before,scene.model.snapshot()),"camera coordination creates no gameplay state")
	home.queue_free();await frames(3)
func journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"only journey setup is completed inquiry")
	root.add_child(home);await frames(8)
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Reserve senior")
	check(not scene.model.commissioned(),"real UI refuses unfunded senior contract")
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Carry four food")
	for p in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-14)]: await walk(scene,p)
	look(scene,C.BROKER);await tap(scene,KEY_E);await press(scene,"Deliver the four")
	check(scene.model.economy().ledger.treasury==146,"real delivery earns only its specified proceeds")
	# 146 still does not meet 156; choose affordable standard and retain running costs.
	for p in [Vector3(-13,0,-11),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Reserve standard")
	check(scene.model.commission().phase=="reserved","UI commits reserve")
	for p in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-14)]: await walk(scene,p)
	look(scene,C.BROKER);await tap(scene,KEY_E);await press(scene,"Present commission")
	await walk(scene,Vector3(-24,0,-10));look(scene,C.RECEPTION);await tap(scene,KEY_E)
	var held: Dictionary=scene.model.snapshot();await frames(12);check(Supply._equal(held,scene.model.snapshot()),"modal freezes contract and bodies")
	await press(scene,"Accept terms")
	for p in [Vector3(-23,0,-12),Vector3(-13,0,-11)]: await walk(scene,p,true)
	await tap(scene,KEY_F5);var saved: Dictionary=scene.model.snapshot();await frames(12);await tap(scene,KEY_F9)
	check(scene.model.commission().phase=="escorting" and Base.distance(scene.specialist_body.global_position,Base.point(saved.commission_actor.position))<0.2,"mid-escort world restore")
	for p in [Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p,true)
	for _i in range(300):
		if C.near(scene.specialist_body.global_position,C.HOME,3.8): break
		await physics_frame
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Sign with")
	check(scene.model.commission().phase=="appointed","actual physical return admits signing")
	var external:=Camera3D.new();home.add_child(external);external.current=true
	scene._sync_commission(true)
	check(root.get_camera_3d()==external,"appointed principal hydration still preserves external camera")
	scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true;external.queue_free()
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Hire a garrison guard")
	await tap(scene,KEY_E);await press(scene,"Rest until next")
	check(scene.model.economy().ledger.duty_guards==1,"pupil paid and provisioned")
	await tap(scene,KEY_E);await press(scene,"Take the instructor")
	check(scene.model.controlling_specialist(),"limited specialist actually controlled")
	check(root.get_camera_3d()==scene.specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D"),"actual role transition selects instructor camera")
	var principal: Vector3=scene.model.position();var stock: Dictionary=scene.model.economy().ledger.stock.duplicate()
	await walk(scene,Vector3(5,0,5));check(scene.model.position()==principal,"instructor movement does not move Buddh")
	check(scene.model.economy().ledger.stock==stock,"walking in another role creates no stock")
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Begin funded drill")
	check(scene.model.commission().lesson=="active","drill began using resources")
	await frames(75);await tap(scene,KEY_F5);var practice: int=scene.model.specialist().practice
	await frames(12);await tap(scene,KEY_F9)
	check(scene.model.controlling_specialist() and abs(scene.model.specialist().practice-practice)<=3,"save retains controlled actor and partial drill")
	for _i in range(250):
		if scene.model.commission().lesson=="complete": break
		await physics_frame
	check(scene.model.commission().lesson=="complete" and scene.model.specialist().practice==180,"bounded practice completes with common clock")
	look(scene,C.HOME);await tap(scene,KEY_E);await press(scene,"Return to Buddh")
	check(not scene.model.controlling_specialist() and scene.model.position()==principal,"view returns without moving principal")
	check(root.get_camera_3d()==scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D"),"return transition selects principal camera")
	ok(scene.model.validate(scene.model.snapshot()),"played journey and economy replay validate")
	var file:=FileAccess.open("user://commission-journey.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"input_driven_after_declared_inquiry_fixture","engine":Engine.get_version_info().string,"state":scene.model.snapshot()},"\t",true,true));file.close()
	# Already-open handover invalidated by a wall: no stale approval.
	look(scene,C.HOME);await tap(scene,KEY_E)
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.8,3,0.1);shape.shape=box;wall.add_child(shape)
	wall.position=(scene.avatar.global_position+C.HOME)/2+Vector3.UP;home.add_child(wall);await frames(3)
	var money_before: Dictionary=scene.model.economy()
	await press(scene,"Release unspent")
	check(Supply._equal(money_before,scene.model.economy()),"new wall prevents previously offered reserve release")
	wall.queue_free();await frames(3)
	await tap(scene,KEY_F5)
	var blocker:=StaticBody3D.new();var hull:=CollisionShape3D.new();var blocked_box:=BoxShape3D.new()
	blocked_box.size=Vector3(1.2,3,1.2);hull.shape=blocked_box;blocker.add_child(hull)
	blocker.position=scene.specialist_body.global_position+Vector3.UP;home.add_child(blocker)
	scene._open_journal();await frames(3)
	var retained: Dictionary=scene.model.snapshot()
	scene._load()
	check(Supply._equal(retained,scene.model.snapshot()),"obstructed specialist load leaves live state intact")
	check(scene._message.contains("standing space"),"obstructed specialist load gives explicit refusal")
	blocker.queue_free();await frames(3)
	home.queue_free();await frames(3)
func run() -> void:
	domain();interlocks()
	var catalogue:=preload("res://commissions/officer_catalogue.gd")
	for record in catalogue.data().officers:
		check(not catalogue.eligible(record.id,1792),"later officer not eligible in 1792 "+record.id)
		check(catalogue.eligible(record.id,record.source_service_window[0]),"reference start year "+record.id)
		check(not catalogue.playable_now(record.id,record.source_service_window[0]),"no fake playable historical chapter "+record.id)
	check(not catalogue.eligible("unknown",1827),"unknown officer")
	check(not catalogue.eligible("jean_francois_allard",NAN),"nonfinite year")
	await camera_ownership();await journey()
	print("COMMISSION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
