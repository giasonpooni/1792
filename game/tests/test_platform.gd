# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Synthetic Godot joypad events, NOT a physical controller or console certification.
const State := preload("res://narrative/oral_memory/memory_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Story := preload("res://childhood/aftermath_state.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const Equality := preload("res://territory/misl_rules.gd")
const Services := preload("res://platform/local_services.gd")
const Storage := preload("res://platform/local_storage.gd")
const Profile := preload("res://platform/input_profile.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const SAVE := "user://platform-foundation-test-only.json"
const PREFS := "user://platform-preferences-test-only.json"
var passed:=0
var failed:=0
var joy_events:=0
var journey_final: Dictionary={}

class RefusingTransport extends RefCounted:
	func write_bytes(_path: String,_bytes: PackedByteArray,_limit: int) -> String: return "Injected storage unavailability."
	func read_bytes(_path: String,_limit: int) -> Dictionary: return {"error":"Injected storage unavailability."}

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func axis(code: JoyAxis,value: float) -> void:
	var event:=InputEventJoypadMotion.new()
	event.device=0;event.axis=code;event.axis_value=value
	joy_events+=1;Input.parse_input_event(event)
func button(code: JoyButton,down: bool) -> void:
	var event:=InputEventJoypadButton.new()
	event.device=0;event.button_index=code;event.pressed=down
	joy_events+=1;Input.parse_input_event(event)
func tap(code: JoyButton) -> void:
	button(code,true);await frames(1)
	button(code,false);await frames(3)
func neutral() -> void:
	for code in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y,JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]: axis(code,0)
	for code in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_LEFT_STICK]: button(code,false)
func choose(prefix: String) -> void:
	# No direct button signal or grab_focus: navigate the actual GUI with the D-pad.
	for _i in range(50):
		var focused:=root.gui_get_focus_owner()
		if focused is Button and focused.text.begins_with(prefix):
			await tap(JOY_BUTTON_A)
			return
		await tap(JOY_BUTTON_DPAD_DOWN)
	check(false,"controller cannot reach action "+prefix)

func _domain() -> void:
	Profile.install()
	var events:=InputMap.action_get_events("interact").size()
	Profile.install()
	check(events==InputMap.action_get_events("interact").size(),"input installation is idempotent")
	var services:=Services.new()
	check(services.identity().platform_user_id==null,"local session does not fabricate a platform account")
	check(services.entitlement().status=="not_checked","local entitlement is not an ownership assertion")
	check(not services.unlock_achievement("first_story").ok,"unsupported achievements fail explicitly")
	for target in ["steam","microsoft_pc","xbox_series","unknown"]:
		check(not Services.create(target).error.is_empty(),"unimplemented provider refuses "+target)
	check(Services.create("local_pc").error.is_empty(),"implemented provider selected explicitly")
	var cap:=services.capabilities();cap.cloud_save=true
	check(not services.capabilities().cloud_save,"capability reads are detached")
	var s:=State.new()
	ok(s.save_to(SAVE),"original world saved through local byte transport")
	var bytes:=FileAccess.get_file_as_bytes(SAVE)
	var snapshot:=s.snapshot()
	check(not JSON.stringify(snapshot).contains("platform_user_id"),"platform identity stays outside character state")
	s.platform_services.storage=RefusingTransport.new()
	check(not s.save_to(SAVE).is_empty(),"write failure propagates")
	check(FileAccess.get_file_as_bytes(SAVE)==bytes and s.snapshot()==snapshot,"failed save changes neither old file nor world")
	check(not s.load_from(SAVE).is_empty() and s.snapshot()==snapshot,"failed read does not promote partial state")
	s.platform_services.storage=Storage.new()
	var bad:=snapshot.duplicate(true);bad.platform_user_id="invented"
	check(not s.restore(bad).is_empty() and s.snapshot()==snapshot,"serialized provider selector rejected")
	var store:=Storage.new()
	check(not store.write_bytes(SAVE,"oversized".to_utf8_buffer(),3).is_empty(),"byte budget checked before writing")
	check(FileAccess.get_file_as_bytes(SAVE)==bytes,"oversize write preserves destination")
	check(not store.read_bytes(SAVE,1).error.is_empty(),"oversize read refused")
	ok(s.save_to(SAVE),"existing local file replacement")
	var copy:=State.new();ok(copy.load_from(SAVE),"read replacement through game validator")
	check(Equality._equal(copy.snapshot(),s.snapshot()),"same validated serialized world")
	ok(store.write_bytes(SAVE,"not json".to_utf8_buffer(),100),"explicit corrupt file fixture")
	check(not s.load_from(SAVE).is_empty() and s.snapshot()==snapshot,"invalid stored JSON cannot replace live world")
	var defaults:=Profile.settings.duplicate(true)
	var changed:=defaults.duplicate(true);changed.invert_y=true;changed.deadzone=0.3;changed.look_speed=3.6
	ok(Profile.set_preferences(changed,PREFS),"save bounded controller preferences separately")
	ok(Profile.load_preferences(PREFS),"reload controller preferences")
	check(Profile.settings.invert_y and is_equal_approx(Profile.settings.deadzone,0.3),"preferences roundtrip")
	for field in ["deadzone","look_speed"]:
		for value in [NAN,INF,true,-1.0,9000.0,"bad"]:
			bad=changed.duplicate(true);bad[field]=value
			check(not Profile.set_preferences(bad,PREFS).is_empty(),"bad preference refused "+field)
	check(Profile.settings==changed,"bad preferences do not partly change settings")
	bad=changed.duplicate(true);bad.extra="hidden"
	check(not Profile.validate(bad).is_empty(),"unknown preference fields refused")
	check(not Profile.set_preferences(defaults,"user://missing-platform-directory/settings.json").is_empty(),"settings write failure propagated")
	check(Profile.settings==changed,"settings failure does not apply unsaved values")
	ok(Profile.set_preferences(defaults,PREFS),"restore preference baseline")
	DirAccess.remove_absolute(SAVE);DirAccess.remove_absolute(PREFS)

func steer_look(scene,target: Vector3) -> float:
	var d: Vector3=target-scene.avatar.global_position
	var error: float=wrapf(atan2(-d.x,-d.z)-scene.avatar.pivot.rotation.y,-PI,PI)
	axis(JOY_AXIS_RIGHT_X,-signf(error)*clampf(absf(error)*3.0,0.24,1.0) if absf(error)>0.012 else 0.0)
	return error
func look(scene,target: Vector3) -> void:
	for _i in range(500):
		if absf(steer_look(scene,target))<0.018: break
		await physics_frame
	axis(JOY_AXIS_RIGHT_X,0)
	await frames(2)
func walk(scene,target: Vector3,run: bool=false) -> void:
	var reached:=false
	for _i in range(1800):
		var distance: float=Base.distance(scene.avatar.global_position,target)
		if distance<0.55: reached=true;break
		var error:=steer_look(scene,target)
		axis(JOY_AXIS_LEFT_Y,-1.0 if absf(error)<0.14 else 0.0)
		axis(JOY_AXIS_TRIGGER_RIGHT,1.0 if run else 0.0)
		await physics_frame
	axis(JOY_AXIS_LEFT_Y,0);axis(JOY_AXIS_RIGHT_X,0);axis(JOY_AXIS_TRIGGER_RIGHT,0)
	await frames(10)
	check(reached,"controller walk to "+str(target)+"; actual "+str(scene.avatar.global_position))
func drive(scene,target: Vector3) -> void:
	var reached:=false
	for _i in range(1800):
		var d: Vector3=target-scene.horse.global_position;d.y=0
		if d.length()<1.25 and scene.horse.speed<0.3: reached=true;break
		var error: float=wrapf(atan2(-d.x,-d.z)-scene.horse.rotation.y,-PI,PI)
		var stop: float=scene.horse.speed*scene.horse.speed/18.0+0.7
		axis(JOY_AXIS_LEFT_Y,-1.0 if absf(error)<0.4 and d.length()>stop else 0.0)
		axis(JOY_AXIS_LEFT_X,-signf(error)*clampf(absf(error)*3.0,0.24,1.0) if absf(error)>0.02 else 0.0)
		await physics_frame
	axis(JOY_AXIS_LEFT_Y,0);axis(JOY_AXIS_LEFT_X,0)
	await frames(15)
	check(reached,"controller rides original horse to "+str(target))

func _lifecycle_fixture() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	scene.controller_settings_path=PREFS
	ok(scene.model.restore(Fixture.complete()),"explicit isolated lifecycle/analog fixture")
	root.add_child(home);await frames(4)
	axis(JOY_AXIS_LEFT_Y,-0.1);await frames(30)
	check(scene.avatar.velocity.length()<0.02,"sub-deadzone input cannot walk")
	axis(JOY_AXIS_LEFT_Y,-0.5);await frames(30)
	var partial: float=Vector2(scene.avatar.velocity.x,scene.avatar.velocity.z).length()
	axis(JOY_AXIS_LEFT_Y,-1);await frames(15)
	var full: float=Vector2(scene.avatar.velocity.x,scene.avatar.velocity.z).length()
	check(partial>0.8 and partial<full*0.6 and is_equal_approx(full,4.5),"partial stick keeps analog speed; full stick keeps old cap")
	neutral();await frames(8)
	var yaw: float=scene.avatar.pivot.rotation.y
	axis(JOY_AXIS_RIGHT_X,0.1);await frames(20)
	check(is_equal_approx(scene.avatar.pivot.rotation.y,yaw),"look deadzone suppresses drift")
	axis(JOY_AXIS_RIGHT_X,0.7);await frames(20);axis(JOY_AXIS_RIGHT_X,0)
	check(absf(scene.avatar.pivot.rotation.y-yaw)>0.1,"right stick rotates actual camera")
	await tap(JOY_BUTTON_START)
	check(scene._paused and root.gui_get_focus_owner() is Button,"Menu opens focused pause UI")
	var paused: Dictionary=scene.model.snapshot()
	button(JOY_BUTTON_X,true);button(JOY_BUTTON_X,false)
	await tap(JOY_BUTTON_DPAD_LEFT);await frames(20)
	check(scene.model.snapshot()==paused,"UI controller actions cannot mutate gameplay or advance clock")
	await choose("Controller settings")
	var before_settings: Dictionary=scene.model.snapshot()
	await choose("Cycle stick deadzone")
	check(FileAccess.file_exists(PREFS) and is_equal_approx(Profile.settings.deadzone,0.3),"controller changes and persists deadzone via settings UI")
	await choose("Reset controller settings")
	check(Profile.settings==Profile.DEFAULTS and scene.model.snapshot()==before_settings,"controller resets preferences without changing world")
	await tap(JOY_BUTTON_B);check(not scene._paused,"B returns from panel")
	check(scene._hud.text.contains("Menu save/load") and scene._hud.text.contains("View:") and not scene._hud.text.contains("WASD"),"integrated home HUD switches to controller labels")
	DirAccess.remove_absolute(PREFS)
	# A focus loss happens before a queued interaction can execute.
	button(JOY_BUTTON_X,true)
	scene.controls.set_focus(false)
	paused=scene.model.snapshot()
	await frames(30)
	check(scene._paused and not scene._interact_requested and scene.model.snapshot()==paused,"focus loss clears queued gameplay and freezes world")
	await tap(JOY_BUTTON_A)
	check(scene._paused and scene.model.snapshot()==paused,"background confirm cannot resume game")
	scene.controls.set_focus(true);await frames(15)
	check(scene._paused and scene.model.snapshot()==paused,"returning focus never resumes automatically")
	button(JOY_BUTTON_X,false)
	await tap(JOY_BUTTON_A);check(not scene._paused,"deliberate confirm resumes")
	axis(JOY_AXIS_LEFT_Y,-1);await frames(2)
	Input.joy_connection_changed.emit(0,false) # Explicit simulated lifecycle notification.
	paused=scene.model.snapshot();await frames(30)
	check(scene._paused and scene.model.snapshot()==paused,"last-used controller loss pauses full world")
	check(not Input.is_action_pressed("move_forward"),"disconnect releases held movement")
	Input.joy_connection_changed.emit(0,true);await frames(10)
	check(scene._paused,"reconnection does not resume")
	neutral();await tap(JOY_BUTTON_A)
	check(not scene._paused,"new controller input can deliberately resume")
	home.queue_free();await frames(2)

func _journey() -> void:
	# Real title screen entry. There are no pose, camera or progress injections in this journey.
	var menu=load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu);current_scene=menu;await frames(4)
	check(root.gui_get_focus_owner() is Button,"title screen gives initial controller focus")
	await tap(JOY_BUTTON_A);await frames(4)
	var home:=current_scene
	check(home!=menu and home.has_node("ChildhoodChapter"),"A enters original Home territory")
	if not home.has_node("ChildhoodChapter"): return
	var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	axis(JOY_AXIS_RIGHT_X,1);await frames(32);axis(JOY_AXIS_RIGHT_X,0)
	await walk(scene,Vector3(0,0,-7))
	check(scene.model.stage()=="letter","controller movement and camera satisfy orientation")
	await walk(scene,Vector3(-2.5,0,3));await look(scene,Base.SITES.letter)
	await tap(JOY_BUTTON_X);await tap(JOY_BUTTON_X)
	check(scene.model.progress().heard==["courier"],"X hears letter account")
	await walk(scene,Vector3(-2,0,0));await walk(scene,Vector3(-10,0,0));await walk(scene,Vector3(-10.5,0,5))
	await look(scene,Base.SITES.steward);await tap(JOY_BUTTON_X)
	check(scene.model.stage()=="riding","second controller-heard account opens riding")
	await walk(scene,Vector3(-10,0,0));await walk(scene,Vector3(4,0,-4));await walk(scene,Vector3(6.3,0,-5))
	await tap(JOY_BUTTON_Y);check(scene.model.mounted(),"Y mounts existing horse")
	for gate in Base.GATES: await drive(scene,gate)
	check(scene.model.progress().ride_gate==3,"controller completes original riding course")
	await tap(JOY_BUTTON_Y);check(not scene.model.mounted(),"Y dismounts")
	await walk(scene,Vector3(-14,0,-3));await look(scene,Base.SITES.spar)
	button(JOY_BUTTON_LEFT_SHOULDER,true);await frames(320);button(JOY_BUTTON_LEFT_SHOULDER,false)
	check(scene.model.progress().parries==2,"LB guards actual practice strikes")
	for _i in range(160):
		if int(scene.model.progress().tick)%150>123:
			await tap(JOY_BUTTON_RIGHT_SHOULDER);break
		await physics_frame
	check(scene.model.stage()=="tracking","RB counter completes lesson")
	for i in range(1,4):
		var at: Vector3=Base.SITES["track_%d"%i]
		await walk(scene,at+Vector3(0,0,2.2));await look(scene,at);await tap(JOY_BUTTON_X)
		check(scene.model.progress().tracks==i,"controller inspects track "+str(i))
	button(JOY_BUTTON_LEFT_STICK,true)
	await walk(scene,Vector3(13,0,-18.5));await look(scene,Base.SITES.quarry);await tap(JOY_BUTTON_X)
	button(JOY_BUTTON_LEFT_STICK,false)
	check(scene.model.stage()=="ready","L3 quiet approach and X observe quarry")
	await walk(scene,Base.SITES.bend);await walk(scene,Base.SITES.home,true)
	check(scene.model.stage()=="escaped","controller escapes authored ambush")
	await walk(scene,Vector3(-10,0,2));await walk(scene,Vector3(-10.5,0,5));await look(scene,Base.SITES.steward)
	await tap(JOY_BUTTON_X);await choose("Remember")
	await walk(scene,Vector3(-7,0,2));await walk(scene,Vector3(-5.6,0,3));await look(scene,Base.SITES.courier)
	await tap(JOY_BUTTON_X);await choose("Remember")
	await walk(scene,Story.MOTHER+Vector3(0,0,-1.8));await look(scene,Story.MOTHER)
	await tap(JOY_BUTTON_X);await choose("Insist")
	check(scene.model.aftermath().decision=="independent_inquiry","controller chooses household response")
	await walk(scene,Vector3(2,0,-2));await walk(scene,Vector3(3,0,-12));await walk(scene,Story.CLUE+Vector3(0,0,2))
	await look(scene,Story.CLUE);await tap(JOY_BUTTON_X)
	await walk(scene,Vector3(2,0,1));await walk(scene,Story.MOTHER+Vector3(0,0,-1.8));await look(scene,Story.MOTHER)
	await tap(JOY_BUTTON_X);await choose("Give")
	check(scene.model.aftermath_phase()=="complete","controller completes full household inquiry")
	await walk(scene,Memory.SITES.quartermaster+Vector3(0,0,-1));await look(scene,Memory.SITES.quartermaster)
	await tap(JOY_BUTTON_X);await choose("Listen to the quartermaster");await choose("Continue")
	await walk(scene,Vector3(2,0,-10));await walk(scene,Vector3(-17,0,-10));await walk(scene,Vector3(-24,0,-13))
	await look(scene,Memory.SITES.market);await tap(JOY_BUTTON_X);await choose("Listen to the trader");await choose("Continue")
	await tap(JOY_BUTTON_BACK);await choose("Compare the two");await choose("Continue")
	check(scene.model.oral_progress().compared_seq>0,"View opens only received stories and controller compares")
	await tap(JOY_BUTTON_START);await choose("Save chapter")
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(saved is Dictionary and saved.has("oral_memory"),"controller UI saves full oral-memory world")
	await walk(scene,Vector3(-17,0,-10))
	await tap(JOY_BUTTON_START);await choose("Load chapter")
	check(Base.distance(scene.model.position(),Base.point(saved.player.position))<0.05,"controller UI load restores saved pose")
	check(scene.model.oral_progress().compared_seq>0,"controller load retains received accounts")
	await walk(scene,Vector3(-17,0,-10));await walk(scene,Vector3(2,0,-10));await walk(scene,Vector3(26,0,-10));await walk(scene,Vector3(26,0,20))
	await look(scene,Memory.SITES.listener);await tap(JOY_BUTTON_X);await choose("Retell both accounts");await choose("Continue")
	check(scene.model.oral_progress().retellings.has("comparison"),"controller reaches listener and retells differing accounts")
	journey_final=scene.model.snapshot()
	ok(scene.model.validate(journey_final),"complete controller journey obeys unchanged world rules")
	await tap(JOY_BUTTON_START);await choose("Main menu")
	check(current_scene.scene_file_path=="res://ui/main_menu.tscn","controller returns to focused title screen")
	current_scene.queue_free();current_scene=null;await frames(2)

func _run() -> void:
	Input.use_accumulated_input=false
	_domain()
	await _lifecycle_fixture()
	neutral();await frames(2)
	await _journey()
	var audit: Dictionary={"schema":"cg.controller-conformance.v1","source_commit":OS.get_environment("SOURCE_COMMIT"),
		"execution_id":OS.get_environment("GITHUB_RUN_ID"),"verification_id":"platform-native.v1",
		"operation_id":"synthetic-gamepad-journey.v1","engine":Engine.get_version_info().string,"os":OS.get_name(),
		"input_kind":"InputEventJoypadButton/InputEventJoypadMotion","joy_events":joy_events,
		"keyboard_or_mouse_events_in_journey":0,"journey_fixture":false,"physical_controller_test":false,
		"final_snapshot_sha256":JSON.stringify(journey_final,"",true,true).sha256_text(),"passed":passed,"failed":failed}
	var file:=FileAccess.open("user://platform-foundation-audit.json",FileAccess.WRITE)
	check(file!=null,"retain controller conformance record")
	if file!=null:
		audit.passed=passed;audit.failed=failed
		file.store_string(JSON.stringify(audit,"\t"));file.close()
	for suffix in ["",".tmp",".checkpoint.json",".checkpoint.json.tmp"]: DirAccess.remove_absolute(SAVE+suffix)
	print("PLATFORM_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
