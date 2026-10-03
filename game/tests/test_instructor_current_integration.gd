# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit completed-inquiry entry fixture; subsequent journey uses game input,
## physical collision and the production E/menu callbacks. Separate mixed-domain
## setups below are labelled fixtures and are not claimed as played campaigns.
const Launch := preload("res://childhood/home_launch.gd")
const State := preload("res://commissions/commission_state.gd")
const Contract := preload("res://commissions/commission_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const Remount := preload("res://remounts/remount_rules.gd")
const SAVE := "user://instructor-current-integration-test-only.json"
const OUTPUT := "user://instructor-current-images"
var passed := 0
var failed := 0
var captures: Array=[]
var route: Array=[]
var home: Node3D
var chapter: Node3D
var _render := false
var completed_world: Dictionary={}

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> bool:
	if value: passed+=1
	else: failed+=1;push_error("INSTRUCTOR CURRENT: "+label)
	return value
func ok(error: String,label: String) -> bool: return check(error.is_empty(),label+": "+error)
static func roundtrip_equal(a: Variant,b: Variant) -> bool:
	# JSON preserves authored integral money exactly; native binary motion may
	# round its last decimal digit on textual storage, as in riding-training QA.
	if (a is int or a is float) and (b is int or b is float):
		return a==b if a==floor(a) and b==floor(b) else absf(float(a)-float(b))<=1.0e-12
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not roundtrip_equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in range(a.size()):
			if not roundtrip_equal(a[i],b[i]): return false
		return true
	return a==b
func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func controls() -> void:
	for id in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(id)
func active_body() -> CharacterBody3D:
	return chapter.specialist_body if chapter.model.controlling_specialist() else chapter.avatar
func settle_active_motor() -> void:
	controls()
	for _i in range(60):
		if Vector2(active_body().velocity.x,active_body().velocity.z).length()<=0.3: break
		await physics_frame
	await frames(2)
	check(Vector2(active_body().velocity.x,active_body().velocity.z).length()<=0.3,"shared active motor settles naturally before rest observation")
func look(target: Vector3) -> void:
	var body:=active_body();var d:=target-body.global_position
	body.pivot.rotation.y=atan2(-d.x,-d.z)
func key(code: Key) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	chapter._unhandled_input(event);await frames(2)
func button(action: String) -> Button:
	for candidate in chapter._actions.get_children():
		for connection in candidate.pressed.get_connections():
			var args: Array=connection.callable.get_bound_arguments()
			if action in args: return candidate
	return null
func select(action: String) -> bool:
	var b:=button(action)
	if not check(b!=null,"currently offered UI action "+action+"; "+chapter._panel_text.text): return false
	b.pressed.emit();await frames(2);return true
func interact(at: Vector3) -> void:
	look(at);await key(KEY_E)
func walk(target: Vector3,with_companion: bool=false) -> bool:
	controls();var reached:=false
	var prior_drawing: bool=root.disable_3d
	# During automated traversal only draw submission is suspended; the same
	# native physics, agents, eye rays and input keep executing. Captures restore
	# production rendering and retain its actual gameplay camera.
	if _render: root.disable_3d=true
	for _i in range(1500):
		var body:=active_body()
		if Base.distance(body.global_position,target)<0.45: reached=true;break
		look(target)
		var wait: bool=with_companion and Base.distance(chapter.avatar.global_position,chapter.specialist_body.global_position)>4.0
		if wait: Input.action_release("move_forward")
		else: Input.action_press("move_forward")
		await physics_frame
	controls();root.disable_3d=prior_drawing;await frames(8)
	return check(reached,"input/collision walk to "+str(target)+" at "+str(active_body().global_position)+"; "+chapter._message)
func note(id: String) -> void:
	route.append({"id":id,"tick":int(chapter.model.progress().tick),"position":Base.coords(chapter.model.position()),"specialist":chapter.model.specialist(),"contract":chapter.model.commission(),"message":chapter._message})
func capture(id: String) -> void:
	if not _render: return
	controls();var before: Dictionary=chapter.model.snapshot()
	var prior: int=home.process_mode;home.process_mode=Node.PROCESS_MODE_DISABLED
	await frames(2)
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.get_size()==Vector2i(800,450),"true native 800x450 capture "+id)
	var path:=OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"retain native frame "+id)
	check(chapter.model.snapshot()==before,"frame capture does not advance or mutate any world domain "+id)
	if chapter._paused:
		var rect: Rect2=chapter._panel.get_global_rect()
		check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=801 and rect.end.y<=451,"small-screen dialog remains inside actual viewport "+id)
	else:
		var hud=chapter.art.detail.hud
		for item in [hud.top,hud.bottom,hud.control_strip]:
			if item.is_visible_in_tree():
				var rect: Rect2=item.get_global_rect()
				check(rect.position.y>=0 and rect.end.y<=451,"small-screen foreground panel remains inside actual viewport "+id)
	var cam:=root.get_camera_3d()
	captures.append({"id":id,"file":id+".png","width":image.get_width(),"height":image.get_height(),"native_content_scale_size":[root.content_scale_size.x,root.content_scale_size.y],"camera":"production-gameplay","camera_position":Base.coords(cam.global_position),"actor":Contract.SPECIALIST if chapter.model.controlling_specialist() else Contract.HERO,"snapshot_sha256":chapter.model.present_sha256(),"execution_paused_for_capture":true})
	home.process_mode=prior
func wall_between(a: Vector3,b: Vector3) -> Node3D:
	var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
	var d:=b-a;d.y=0
	box.size=Vector3(3.0,2.8,0.15);shape.shape=box;body.add_child(shape)
	body.position=(a+b)*0.5+Vector3.UP*1.25;body.rotation.y=atan2(d.x,d.z)
	home.add_child(body);return body
func assert_paused(label: String,count: int=24) -> void:
	var before: Dictionary=chapter.model.snapshot();var body: Transform3D=chapter.avatar.global_transform;var specialist: Transform3D=chapter.specialist_body.global_transform
	await frames(count)
	check(chapter.model.snapshot()==before and chapter.avatar.global_transform==body and chapter.specialist_body.global_transform==specialist,label+" freezes common clock, both bodies and all domains")
func blocked_payment(action: String,at: Vector3,label: String) -> void:
	var economy: Dictionary=chapter.model.economy()
	var obstruction:=wall_between(active_body().global_position,at)
	await frames(3);await select(action)
	check(chapter.model.economy()==economy,"late physical occlusion prevents "+label+" payment and any receipt")
	obstruction.queue_free();await frames(3);await select("resume")

func _journey() -> void:
	home=Launch.make_world();chapter=home.get_node("ChildhoodChapter");chapter.save_path=SAVE
	if not ok(chapter.model.restore(Fixture.complete()),"explicit completed-inquiry initial fixture"): return
	root.add_child(home);current_scene=home;await frames(8)
	if not check(chapter.model.has_method("commissioned") and chapter.has_method("_access"),"production Home owns current commission chapter/state"): return
	var primary: Camera3D=chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	var specialist_cam: Camera3D=chapter.specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D")
	check(root.get_camera_3d()==primary and not specialist_cam.current,"unaccepted second body leaves primary gameplay camera current")
	await interact(Contract.HOME);await select("econ:begin")
	await interact(Contract.HOME);await select("econ:accept_delivery")
	for at in [Vector3(2,0.14,-10),Vector3(-17,0.14,-10),Vector3(-24,0.14,-13)]:
		if not await walk(at): return
	await interact(Contract.BROKER);await select("econ:deliver")
	check(chapter.model.economy().ledger.delivery=="delivered","existing physical delivery funds this appointment")
	for at in [Vector3(-17,0.14,-10),Vector3(2,0.14,-10),Vector3(3,0.14,4)]:
		if not await walk(at): return
	await interact(Contract.HOME);await select("econ:hire|guard")
	await interact(Contract.HOME);await select("econ:rest")
	check(chapter.model.economy().ledger.guards==1 and chapter.model.economy().ledger.duty_guards==1,"same household guard payroll provisions drill pupil")
	await interact(Contract.HOME);await select("commission:terms")
	check(button("commission:reserve|standard").has_focus(),"focused standard offer is keyboard reachable in dedicated authorization dialogue")
	await capture("01-authorize-offer")
	await assert_paused("authorization reading")
	var money: int=chapter.model.economy().ledger.treasury
	var blocker:=wall_between(chapter.avatar.global_position,Contract.HOME)
	await frames(3);await select("commission:reserve|standard")
	check(not chapter.model.commissioned() and chapter.model.economy().ledger.treasury==money,"late real occlusion prevents reservation and debit")
	blocker.queue_free();await frames(3)
	await select("resume")
	chapter._menu_action("commission:reserve|standard");await frames(3)
	check(not chapter.model.commissioned(),"bare stale action outside offered dialogue cannot spend money")
	await interact(Contract.HOME);await select("commission:terms");await select("commission:reserve|standard")
	if not check(chapter.model.commissioned() and chapter.model.commission().phase=="reserved","visible local offer authorizes standard appointment"): return
	check(chapter.model.economy().ledger.treasury==money-108 and chapter.model.commission().escrow==108,"one reserved purse debits treasury once")
	var reserved: Dictionary=chapter.model.snapshot()
	chapter._menu_action("commission:reserve|standard");await frames(3)
	check(chapter.model.economy().ledger.treasury==reserved.misl.ledger.treasury and chapter.model.commission().escrow==108,"replayed reservation callback grants no debit or purse")
	note("reserved")
	for at in [Vector3(2,0.14,-10),Vector3(-17,0.14,-10),Vector3(-24,0.14,-13)]:
		if not await walk(at): return
	await interact(Contract.BROKER);await capture("02-agent-introduction")
	await blocked_payment("commission:broker",Contract.BROKER,"agent introduction")
	await interact(Contract.BROKER);await select("commission:broker")
	check(chapter.model.commission().phase=="introduced" and chapter.model.commission().spent==8,"physical agent introduces candidate for exactly one fee")
	if not await walk(Contract.RECEPTION+Vector3(0,0,-1.5)): return
	await interact(Contract.RECEPTION);await capture("03-candidate-terms");await assert_paused("candidate terms")
	await blocked_payment("commission:engage",chapter.specialist_body.global_position,"candidate travel")
	await interact(Contract.RECEPTION);await select("commission:engage")
	if not check(chapter.model.commission().phase=="escorting" and chapter.model.commission().spent==20,"candidate acceptance pays actual travel stage only"): return
	var waiting: Vector3=chapter.specialist_body.global_position
	blocker=wall_between(chapter.specialist_body.global_position,chapter.avatar.global_position)
	await frames(30)
	check(Base.distance(chapter.specialist_body.global_position,waiting)<0.001,"instructor waits behind real occlusion instead of following through wall")
	await capture("04-waiting-instructor")
	blocker.queue_free();await frames(3)
	for at in [Vector3(-17,0.14,-10),Vector3(2,0.14,-10),Vector3(3,0.14,4)]:
		if not await walk(at,true): return
	await frames(40)
	await interact(Contract.HOME)
	check(button("commission:appoint")==chapter._actions.get_child(0) and button("commission:appoint").has_focus(),"signing continuation leads and focuses current local menu")
	await capture("05-sign-together")
	await blocked_payment("commission:appoint",Contract.HOME,"service signing")
	await interact(Contract.HOME);await select("commission:appoint")
	if not check(chapter.model.commission().phase=="appointed","full physical escort signs only once together at home"): return
	check(chapter.model.commission().spent==84 and chapter.model.commission().escrow==24,"travel, agent and signing are distinct from remaining wage reserve")
	ok(chapter.model.validate(chapter.model.snapshot()),"current journey validates with composed economic receipts")
	await interact(Contract.HOME);await select("oral:hear|quartermaster_account")
	if chapter._paused: await select("resume")
	check(chapter.model.oral_progress().heard.has("quartermaster_account"),"Buddh receives his own local story before viewpoint change")
	var private_journal: Array=chapter.model.journal();var hero_pose: Transform3D=chapter.avatar.global_transform
	await interact(Contract.HOME);await select("commission:control|fictional_local_drillmaster")
	if not check(chapter.model.controlling_specialist(),"actual scoped UI switches to commissioned instructor viewpoint"): return
	check(root.get_camera_3d()==specialist_cam and chapter.avatar.global_transform==hero_pose and not chapter.avatar.input_enabled,"actual specialist camera owns view while principal stays at retained body")
	check(not chapter.model.journal().any(func(row):return row.text.contains("rope") or row.channel=="heard"),"instructor does not inherit Buddh's received testimony")
	await settle_active_motor()
	await capture("06a-instructor-current-place")
	look(Contract.HOME);Input.action_press("move_backward");await frames(8)
	chapter.art.detail.hud.sample()
	check(chapter.art.detail.hud.visible and not chapter.art.detail.hud.title.visible and not chapter.art.detail.hud.narrator.visible,"compact foreground reads active instructor movement and hides extra exposition")
	check(not chapter._hud.is_visible_in_tree(),"specialist movement has one current foreground")
	await capture("06b-instructor-moving")
	await settle_active_motor()
	chapter.art.detail.hud.sample()
	check(chapter.art.detail.hud.title.visible and chapter.art.detail.hud.narrator.visible,"current place explanation returns when instructor stops")
	check(chapter.avatar.global_transform==hero_pose and chapter.specialist_body.global_position.distance_to(State.point(chapter.model.specialist().position))<0.25,"shared input moves specialist only and records the actual second body")
	await key(KEY_J);await assert_paused("instructor's participation journal")
	check(not chapter._panel_text.text.contains("quartermaster remembers") and not chapter._panel_text.text.contains("Latif") and not chapter._panel_text.text.contains("WHAT I HAVE HEARD AND SEEN"),"viewpoint notebook omits principal memory and impression")
	await capture("06-instructor-own-view")
	await select("resume")
	await interact(Contract.HOME);await select("commission:control|ranjit_singh")
	check(not chapter.model.controlling_specialist() and root.get_camera_3d()==primary and chapter.avatar.input_enabled,"scoped return restores primary camera and input")
	check(chapter.model.journal().slice(0,private_journal.size())==private_journal,"return retains principal's earlier received knowledge")
	await interact(Contract.HOME);await select("commission:lesson_start")
	if not check(chapter.model.commission().lesson=="active","present supplied pupil begins physical drill"): return
	blocker=wall_between(chapter.specialist_body.global_position,chapter.avatar.global_position)
	await frames(4);var practice: int=chapter.model.specialist().practice
	await frames(35)
	check(chapter.model.specialist().practice==practice,"real drill occlusion stops earned progress while shared clock advances")
	await capture("07-drill-interrupted")
	await key(KEY_J);await assert_paused("drill journal pause")
	await select("resume");blocker.queue_free();await frames(3)
	for _i in range(Contract.PRACTICE_TICKS+30):
		if chapter.model.commission().lesson=="complete": break
		await physics_frame
	check(chapter.model.commission().lesson=="complete" and chapter.model.specialist().practice==Contract.PRACTICE_TICKS,"only eligible local physical ticks complete finite drill")
	await interact(Contract.HOME)
	if button("commission:after")!=null:
		await select("commission:after");await capture("08-aftermath");await assert_paused("optional aftermath");await select("resume")
	else: check(false,"completed drill offers optional local aftermath")
	ok(chapter.model.validate(chapter.model.snapshot()),"completed instruction journey validates")
	note("completed")
	completed_world=chapter.model.snapshot()

func _mixed_roundtrip_and_visit() -> void:
	# Explicit domain fixtures qualify coexistence and retained-world restoration.
	# These pose calls do not represent an additional played remount/workshop arc.
	var mixed:=State.new()
	if not ok(mixed.restore(chapter.model.snapshot()),"explicit mixed-domain seed from played instructor journey"): return
	ok(Pose.pose(mixed,Contract.HOME+Vector3(0,0,-1)),"mixed fixture quartermaster pose")
	ok(mixed.begin_service(),"idle current service extension remains available after appointment")
	ok(mixed.begin_water_round(),"idle current water extension remains available after appointment")
	ok(mixed.begin_remounts(),"resolved appointment can coexist with later remount fixture")
	ok(Pose.pose(mixed,Supply.MARKET),"remount fixture market")
	ok(mixed.remount_action("introduction"),"remount fixture introduction")
	ok(Pose.pose(mixed,Remount.OBSERVERS.yard_gatekeeper.position),"remount fixture gatekeeper")
	ok(mixed.remount_action("permission"),"remount fixture permission")
	ok(Pose.pose(mixed,Remount.NOTE),"remount fixture tally")
	ok(mixed.remount_action("note"),"remount fixture tally custody")
	ok(Pose.pose(mixed,Remount.HITCH),"remount fixture horses")
	ok(mixed.remount_action("horses"),"remount fixture observed cord marks")
	ok(Pose.pose(mixed,Contract.HOME),"remount fixture home")
	ok(mixed.remount_action("resolve"),"remount fixture read-aloud settlement")
	ok(mixed.workshop_action("reserve"),"current smith reservation composes commission receipts")
	ok(Pose.pose(mixed,Craft.SITE),"mixed fixture smith")
	ok(mixed.workshop_action("start"),"current smith handover composes commission receipts")
	for _i in range(Craft.WORK_TICKS): mixed.advance()
	check(mixed.workshop_phase()=="ready" and mixed.commission().lesson=="complete","common existing clock completes smith work while preserving completed drill")
	ok(Pose.pose(mixed,Vector3(5.5,0.14,-4)),"declared retained-visit entry pose")
	ok(mixed.save_to(SAVE+".mixed"),"mixed whole-world save")
	var copy:=State.new();ok(copy.load_from(SAVE+".mixed"),"mixed current-state restore")
	check(roundtrip_equal(copy.snapshot(),mixed.snapshot()),"roundtrip retains oral memory, resolved remounts, riding skills, workshop, idle service/water and commission together")
	check(copy.has_oral_memory() and copy.has_remounts() and copy.has_service() and copy.has_water_round() and copy.snapshot().has("riding_skills"),"all current extensions are explicitly retained")
	var bad: Dictionary=mixed.snapshot();bad.misl.events[-1].arg="999999"
	var prior: Dictionary=copy.snapshot()
	check(not copy.restore(bad).is_empty() and copy.snapshot()==prior,"tampered workshop receipt in commission prefix is rejected atomically")
	chapter._show_dialog("EXPLICIT TEST FIXTURE","Mixed-domain lifecycle qualification.",[["Return","resume"]])
	ok(chapter.model.restore(mixed.snapshot()),"install explicit mixed-domain lifecycle fixture")
	chapter._apply();chapter._resume();await frames(5)
	look(Vector3(6,0.14,-4));await frames(2)
	var before: Dictionary=chapter.model.snapshot();var body: Transform3D=chapter.avatar.global_transform;var second: Transform3D=chapter.specialist_body.global_transform
	var art_id: int=chapter.art.get_instance_id();var smith_id: int=chapter.workplace.get_instance_id()
	if not ok(chapter.open_riding_training(),"existing retained riding session accepts hands-free settled instructor fixture"): return
	var session=chapter.training_session;var lesson=session.lesson
	await frames(6)
	check(home.process_mode==Node.PROCESS_MODE_DISABLED and root.disable_3d and session.viewport.own_world_3d,"existing retained lesson exclusively owns execution and separate physics/view")
	Input.action_press("move_forward");await frames(24);controls();await frames(4)
	check(chapter.model.snapshot()==before and chapter.avatar.global_transform==body and chapter.specialist_body.global_transform==second,"actual lesson input leaves every retained Home extension and both bodies frozen")
	check(chapter.art.get_instance_id()==art_id and chapter.workplace.get_instance_id()==smith_id,"riding visit preserves current Home art and smith attachment identities")
	check(not chapter._access("reserve").is_empty(),"active retained riding session refuses concurrent commission spending")
	var returning: Dictionary={}
	session.tree_exiting.connect(func(): returning.snapshot=chapter.model.snapshot();returning.camera=root.get_camera_3d())
	var event:=InputEventKey.new();event.keycode=KEY_F1;event.pressed=true;session._input(event)
	await frames(4)
	check(not is_instance_valid(chapter.training_session) and home.process_mode!=Node.PROCESS_MODE_DISABLED and not root.disable_3d,"actual F1 lesson return restores retained Home execution and rendering")
	check(returning.get("snapshot",{})==before,"withdrawn retained lesson return preserves entire composed authority")
	check(root.get_camera_3d()==chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D") and chapter.avatar.input_enabled,"lesson return leaves current primary camera/input playable")
	chapter._show_dialog("EXPLICIT TEST FIXTURE","Load safety qualification.",[["Return","resume"]])
	ok(chapter.model.save_to(SAVE),"composed active save before physical obstruction")
	var saved_specialist: Vector3=chapter.specialist_body.global_position
	var blocker:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.7,3,1.7)
	shape.shape=box;blocker.add_child(shape);blocker.position=saved_specialist+Vector3.UP;home.add_child(blocker);await frames(3)
	before=chapter.model.snapshot();chapter._load();await frames(2)
	check(chapter.model.commission()==before.misl.ledger.commission and chapter.model.specialist()==before.commission_actor and not chapter._message.begins_with("Whole world"),"real blocked saved specialist refuses before replacing current authority")
	blocker.queue_free();await frames(3)
	chapter._show_dialog("EXPLICIT TEST FIXTURE","Old-save rollback qualification.",[["Return","resume"]])
	var older: Dictionary=Fixture.complete()
	var file:=FileAccess.open(SAVE+".older",FileAccess.WRITE);file.store_string(JSON.stringify(older));file.close()
	chapter._load(SAVE+".older");await frames(3)
	check(not chapter.model.commissioned() and not chapter.model.has_oral_memory() and not chapter.model.has_remounts() and not chapter.model.has_economy(),"whole-world rollback removes future contract, memory, remounts and economy together")
	check(not chapter.specialist_body.visible and root.get_camera_3d()==chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D"),"rollback removes candidate projection and preserves playable camera")

func _preadd_hydration() -> void:
	# Explicit restored-appointment fixtures cover the floor cache before any
	# native escort has been stepped in this fresh scene. They are not journeys.
	for controlled in [false,true]:
		var seed:=State.new();ok(seed.restore(completed_world),"pre-add appointed fixture")
		ok(Pose.pose(seed,Contract.HOME+Vector3(0,0,-1)),"pre-add primary standing fixture")
		if controlled: ok(seed.commission_action("control",Contract.SPECIALIST),"pre-add controlled viewpoint fixture")
		var visit:=Launch.make_world();var c=visit.get_node("ChildhoodChapter");c.save_path=SAVE+".hydrated"
		ok(c.model.restore(seed.snapshot()),"restore current appointed world before scene enters tree")
		root.add_child(visit);await frames(5)
		check(c.specialist_body.is_on_floor(),"pre-add restore reconstructs specialist ground contact without replayed escort")
		check(c.avatar.is_on_floor(),"pre-add restore reconstructs waiting principal ground contact")
		var cam: Camera3D=c.specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D") if controlled else c.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
		check(root.get_camera_3d()==cam and c.model.controlling_specialist()==controlled,"hydration chooses correct retained current actor camera")
		check(c.model.commission().spent==seed.commission().spent and c.model.commission().escrow==seed.commission().escrow and c.model.specialist().practice==Contract.PRACTICE_TICKS,"hydration invents no payment or drill work")
		ok(c.model.validate(c.model.snapshot()),"pre-add hydrated current state validates")
		visit.queue_free();await frames(3)

func _run() -> void:
	_render=OS.get_environment("INSTRUCTOR_CURRENT_RENDER")=="1" and DisplayServer.get_name()!="headless"
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(800,450)
	if _render: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _journey()
	if failed==0: await _mixed_roundtrip_and_visit()
	controls()
	if is_instance_valid(home): home.queue_free()
	await frames(3)
	if failed==0: await _preadd_hydration()
	if _render:
		var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema":"1792.instructor-current-integration.v1","entry":"explicit completed-inquiry fixture; native input/menu/motion thereafter","mixed_roundtrip":"separate labelled domain fixtures; not claimed played","human_pacing_review":false,"continuous_render_during_automated_walk":false,"captures":captures,"route":route},"\t",true,true));file.close()
	for suffix in ["",".tmp",".mixed",".mixed.tmp",".older"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("INSTRUCTOR_CURRENT_TESTS: %d passed, %d failed"%[passed,failed])
	print("INSTRUCTOR_CURRENT_RENDER: %d captures"%captures.size())
	quit(1 if failed else 0)
