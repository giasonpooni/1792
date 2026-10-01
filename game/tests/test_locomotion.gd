# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Physical fixtures are labelled separately from the no-teleport connected journey.
const Course := preload("res://mechanics/course.gd")
const M := preload("res://player/locomotion_rules.gd")
const Probe := preload("res://player/traversal_probe.gd")
var passed := 0
var failed := 0
var metrics: Dictionary={}
const SAVE := "user://test-locomotion-isolated.json"

func _initialize() -> void: run.call_deferred()
func check(condition: bool,label: String) -> void:
	if condition: passed+=1
	else: failed+=1;push_error("LOCOMOTION FAIL: "+label)
func near(a: float,b: float,tolerance: float,label: String) -> void:
	check(absf(a-b)<=tolerance,label+" / "+str(a)+" vs "+str(b))
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func release() -> void:
	for name in ["move_left","move_right","move_forward","move_backward","sprint","traverse_jump","traverse_obstacle"]: Input.action_release(name)
func action(name: String) -> void:
	var event:=InputEventAction.new();event.action=name;event.pressed=true;Input.parse_input_event(event)
	await frames(1);event=InputEventAction.new();event.action=name;event.pressed=false;Input.parse_input_event(event)
func fixture(c: Node3D,p: Vector3) -> void:
	# Explicit physical-test setup, not claimed as a played route.
	release();c.set_paused(false);c.avatar._route.clear();c.avatar.traversal_enabled=true
	c.avatar.global_position=p;c.avatar.velocity=Vector3.ZERO;c.avatar._grounded=false
	c.avatar._coyote=0;c.avatar._buffer=0;c.avatar.pivot.rotation=Vector3(-0.2,0,0)
	c.avatar.clear_motion_requests();await frames(10)
func new_course() -> Node3D:
	var c:=Course.new();c.save_path=SAVE;root.add_child(c);await frames(10);return c
func dispose(c: Node3D) -> void:
	release();root.remove_child(c);c.queue_free();await frames(2)
func blocker(c: Node3D,id: String,at: Vector3,size: Vector3) -> Node3D:
	return c.build_box({"id":id,"at":M.array(at),"size":M.array(size),"traversable":false})

func math_tests() -> void:
	for strength in [0.0,0.1,0.25,0.5,1.0]:
		for yaw in [0.0,0.5,-1.3]: near(M.direction(Vector2(0,-strength),yaw).length(),strength,0.000001,"analog magnitude")
	near(M.direction(Vector2(1,1),0).length(),1,0.000001,"diagonal input bounded")
	var forward:=Vector3.ZERO;var diagonal:=Vector3.ZERO
	for _i in range(10):
		forward=M.horizontal(forward,Vector3(0,0,-7.5),18,1.0/60)
		diagonal=M.horizontal(diagonal,Vector3(1,0,-1).normalized()*7.5,18,1.0/60)
	near(forward.length(),3,0.00001,"acceleration after ten ticks")
	near(forward.length(),diagonal.length(),0.00001,"isotropic acceleration")
	for _i in range(10): forward=M.horizontal(forward,Vector3.ZERO,18,1.0/60)
	near(forward.length(),0,0.00001,"bounded braking reaches rest")

func physics_tests() -> void:
	var c=await new_course();var a=c.avatar
	# Analog InputMap path: 0.6 raw strength maps to 0.5 after the declared 0.2 deadzone.
	await fixture(c,Vector3(-5,0.04,8))
	Input.action_press("move_forward",0.6);await frames(25)
	near(Vector2(a.velocity.x,a.velocity.z).length(),2.25,0.02,"half-stick walk")
	release();await frames(20);near(a.velocity.length(),0,0.001,"release brakes")
	for pitch in [-0.9,0.5]:
		await fixture(c,Vector3(-5,0.04,8));a.pivot.rotation.x=pitch
		Input.action_press("move_forward");await frames(25)
		near(Vector2(a.velocity.x,a.velocity.z).length(),4.5,0.02,"camera pitch does not change walk speed")
	await fixture(c,Vector3(-5,0.04,8))
	Input.action_press("move_forward");Input.action_press("sprint");await frames(30)
	near(Vector2(a.velocity.x,a.velocity.z).length(),7.5,0.02,"run speed")
	await fixture(c,Vector3(-5,0.04,8));Input.action_press("move_forward");Input.action_press("move_right");await frames(5)
	var diagonal: float=Vector2(a.velocity.x,a.velocity.z).length()
	await fixture(c,Vector3(-5,0.04,8));Input.action_press("move_forward");await frames(5)
	near(Vector2(a.velocity.x,a.velocity.z).length(),diagonal,0.0001,"physical diagonal acceleration matches cardinal")
	# Inject actual joypad events through InputMap, not only action strengths.
	await fixture(c,Vector3(-5,0.04,8))
	var joy:=InputEventJoypadMotion.new();joy.device=0;joy.axis=JOY_AXIS_LEFT_Y;joy.axis_value=-0.1;Input.parse_input_event(joy)
	await frames(8);near(Vector2(a.velocity.x,a.velocity.z).length(),0,0.001,"stick deadzone")
	joy=InputEventJoypadMotion.new();joy.device=0;joy.axis=JOY_AXIS_LEFT_Y;joy.axis_value=-0.6;Input.parse_input_event(joy)
	await frames(25);near(Vector2(a.velocity.x,a.velocity.z).length(),2.25,0.02,"actual mapped half-stick event")
	joy=InputEventJoypadMotion.new();joy.device=0;joy.axis=JOY_AXIS_LEFT_Y;joy.axis_value=0;Input.parse_input_event(joy)
	await frames(15)
	joy=InputEventJoypadMotion.new();joy.device=0;joy.axis=JOY_AXIS_RIGHT_X;joy.axis_value=0.6;Input.parse_input_event(joy)
	await frames(20);check(a.pivot.rotation.y < -0.2,"actual right stick moves camera")
	joy=InputEventJoypadMotion.new();joy.device=0;joy.axis=JOY_AXIS_RIGHT_X;joy.axis_value=0;Input.parse_input_event(joy)
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_START;pad.pressed=true;Input.parse_input_event(pad);await frames(2)
	check(c.paused,"controller Start pauses course")
	pad=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_START;pad.pressed=false;Input.parse_input_event(pad)
	var locked: Dictionary=c.snapshot();await frames(10);check(c.snapshot()==locked,"controller pause freezes motion")
	pad=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_START;pad.pressed=true;Input.parse_input_event(pad);await frames(2)
	check(not c.paused,"controller Start resumes course")
	pad=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_START;pad.pressed=false;Input.parse_input_event(pad)
	# The proxy animates only its own skeleton and cannot write the capsule/world state.
	c.set_paused(true);var proxy_before: Dictionary=c.snapshot()
	var hull_id: int=a.get_node("CollisionShape3D").get_instance_id()
	a.get_node("LocomotionProxy")._process(0.5)
	check(c.snapshot()==proxy_before and a.get_node("CollisionShape3D").get_instance_id()==hull_id,"proxy does not own movement or collision")
	check(a.get_node("LocomotionProxy/ProxySkeleton").get_bone_count()==11,"articulated proxy skeleton exists")
	near(a.get_node("LocomotionProxy/ProxySkeleton").get_bone_global_pose(2).origin.y,1.4,0.001,"proxy head is at skeletal height, not collapsed to origin")
	var old_speed: float=a.walk_speed;a.walk_speed+=0.1
	check(not c.restore(proxy_before).is_empty(),"different resolved tuning refuses old course snapshot")
	a.walk_speed=old_speed
	# Jump arc and no held-key repeated jumping.
	await fixture(c,Vector3(-5,0.04,7));var floor_y: float=a.global_position.y
	var e:=InputEventAction.new();e.action="traverse_jump";e.pressed=true;Input.parse_input_event(e)
	var apex: float=floor_y;var launches:=0;var landings:=0
	for _i in range(100):
		await physics_frame;apex=maxf(apex,a.global_position.y)
		if a.last_motion_event=="jump": launches+=1
		if a.last_motion_event=="land": landings+=1
	release();metrics.jump_apex=apex-floor_y
	check(apex-floor_y>1.15 and apex-floor_y<1.30,"measured jump apex within declared discrete envelope")
	check(launches==1 and landings==1,"held jump produces one takeoff and landing")
	check(a._grounded,"jump lands")
	# Restore exactly the same mid-air state, then replay identical zero input.
	await fixture(c,Vector3(-5,0.04,7));await action("traverse_jump");await frames(7)
	var saved: Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()))
	check(not saved.motion.grounded and saved.motion.velocity[1]>0,"save fixture is actually ascending")
	c.set_paused(true);var frozen: Dictionary=c.snapshot();await frames(15)
	check(c.snapshot()==frozen,"pause preserves velocity, position and timers")
	c.set_paused(false);await frames(18);var expected: Vector3=a.global_position;var speed: Vector3=a.velocity
	check(c.restore(saved).is_empty(),"airborne restore")
	await frames(18);near(a.global_position.distance_to(expected),0,0.00001,"airborne replay position")
	near(a.velocity.distance_to(speed),0,0.00001,"airborne replay velocity")
	# Changed profile, malformed JSON data, unsupported speed, false ground all refuse atomically.
	await fixture(c,Vector3(-5,0.04,7));c.set_paused(true)
	for kind in ["schema","digest","fraction","velocity","nan","keys","blocked","floating"]:
		var bad: Dictionary=c.snapshot().duplicate(true);var before: Dictionary=c.snapshot()
		match kind:
			"schema": bad.schema="world-state.v1"
			"digest": bad.motor_digest="other"
			"fraction": bad.tick=0.5
			"velocity": bad.motion.velocity=[8,0,0]
			"nan": bad.motion.velocity=[NAN,0,0]
			"keys": bad.motion.extra=true
			"blocked": bad.motion.position=[0,0.1,0]
			"floating": bad.motion.position=[-5,3,7]
		check(not c.restore(bad).is_empty(),"refuse "+kind)
		check(c.snapshot()==before,"atomic refusal "+kind)
	check(c.save_course().begins_with("Course motion saved"),"actual file save")
	var filebytes: String=FileAccess.get_file_as_string(SAVE)
	c.tick+=10;check(c.load_course().begins_with("Course motion restored"),"actual file load")
	check(FileAccess.get_file_as_string(SAVE)==filebytes,"loading does not rewrite file")
	# Course camera uses a hull on the retained spring arm and retracts under obstruction.
	await fixture(c,Vector3(-9,0.04,3));await frames(8)
	check(a.get_node("CameraPivot/SpringArm3D").get_hit_length()<5.5,"camera retracts below low ceiling")
	await action("traverse_jump");var ceiling_apex: float=a.global_position.y
	for _i in range(50): await physics_frame;ceiling_apex=maxf(ceiling_apex,a.global_position.y)
	check(ceiling_apex<0.36,"ceiling blocks upward motion")
	check(a._grounded,"ceiling bump returns to floor")
	# The campaign still declines vertical actions; no newly reachable story roof exploits.
	await fixture(c,Vector3(-5,0.04,7));a.traversal_enabled=false;await action("traverse_jump");await frames(15)
	near(a.global_position.y,floor_y,0.01,"traversal disabled preserves ground-only campaign")
	# Coyote time is earned by physically leaving a supporting platform.
	await fixture(c,Vector3(1.0,1.44,-5));Input.action_press("move_right")
	for _i in range(40):
		await physics_frame
		if not a._grounded: break
	check(not a._grounded,"walked off edge")
	release();await frames(1);await action("traverse_jump")
	check(a.velocity.y>5,"short edge grace permits jump")
	await fixture(c,Vector3(1.0,1.44,-5));Input.action_press("move_right")
	for _i in range(40):
		await physics_frame
		if not a._grounded: break
	release();await frames(9);await action("traverse_jump")
	check(a.velocity.y<0,"expired grace refuses air jump")
	# Buffered input shortly before landing triggers once on the following supported tick.
	await fixture(c,Vector3(-5,0.04,7));a.global_position.y=0.30;a.velocity=Vector3(0,-3,0);a._grounded=false;a._coyote=0
	await action("traverse_jump");var buffered:=false
	for _i in range(8): await physics_frame;buffered=buffered or a.velocity.y>5
	check(buffered,"pre-landing jump input is buffered")
	# Surface semantics and real swept-body clearance.
	for setup in [[Vector3(9,0.04,6.9),"unmarked"],[Vector3(9,0.04,1.7),"too high"]]:
		await fixture(c,setup[0]);var before: Vector3=a.global_position;await action("traverse_obstacle");await frames(6)
		check(a._route.is_empty(),"refuse "+setup[1]+" obstacle")
		near(a.global_position.distance_to(before),0,0.01,"refusal does not teleport")
	await fixture(c,Vector3(0,0.04,0.95))
	var wall=blocker(c,"landing_blocker",Vector3(0,1.1,-1.0),Vector3(3,2.2,.2));await frames(3)
	await action("traverse_obstacle");check(a._route.is_empty(),"blocked vault destination refused")
	c.remove_child(wall);wall.queue_free();await frames(3)
	await action("traverse_obstacle");check(not a._route.is_empty(),"clear vault admitted")
	check(c.save_course().contains("before saving"),"mid-vault save refusal is explicit")
	check(FileAccess.get_file_as_string(SAVE)==filebytes,"mid-vault refusal retains previous save")
	wall=blocker(c,"late_blocker",Vector3(0,1.8,-0.4),Vector3(3,3.0,.1));await frames(90)
	check(a._route.is_empty(),"late obstacle ends committed traversal")
	check(a.global_position.z>0,"late obstacle does not allow wall crossing")
	c.remove_child(wall);wall.queue_free();await frames(3)
	await fixture(c,Vector3(0,0.04,0.95));await action("traverse_obstacle")
	c.get_node("vault_rail").position.x+=0.1;await frames(3)
	check(a._route.is_empty(),"moved surface invalidates contact")
	c.get_node("vault_rail").position.x-=0.1
	await fixture(c,Vector3(9,0.20,-1.3));Input.action_press("move_forward");var slope_height:=0.0
	for _i in range(45): await physics_frame;slope_height=maxf(slope_height,a.global_position.y)
	check(slope_height>1.0,"real sloped collision permits ascent")
	await dispose(c)

func walk(c: Node3D,p: Vector3,threshold: float=0.18) -> void:
	var arrived:=false
	for _i in range(500):
		var d: Vector3=p-c.avatar.global_position;d.y=0
		if d.length()<threshold: arrived=true;break
		c.avatar.pivot.rotation.y=atan2(-d.x,-d.z);Input.action_press("move_forward");await physics_frame
	release();await frames(15)
	check(arrived,"input-driven route point "+str(p))
	if not arrived: print("ROUTE STOP: ",c.avatar.global_position," / ",c.message)

func journey() -> void:
	var c=await new_course();var a=c.avatar
	# Normal course spawn. No pose, velocity or progress injection from here onward.
	await walk(c,Vector3(0,0,1.15));await action("traverse_obstacle");await frames(100)
	check(a.last_traversal_kind=="vault" and a.global_position.z < -0.8 and a._grounded,"physical vault completes")
	await walk(c,Vector3(0,0,-2.65));await action("traverse_obstacle");await frames(90)
	check(a.last_traversal_kind=="mantle" and a.global_position.y>1.39 and a._grounded,"physical mantle completes")
	Input.action_press("move_forward");Input.action_press("sprint")
	for _i in range(70):
		await physics_frame
		if a.global_position.z < -5.90: break
	check(a._grounded and a.global_position.z>=-6.5,"jump takeoff remains on source platform")
	await action("traverse_jump")
	var gap_passed:=false
	for _i in range(65):
		await physics_frame
		if a._grounded and a.global_position.z < -9 and a.global_position.y>1.35: gap_passed=true;break
	release();await frames(20)
	check(gap_passed,"input-driven 2.5m gap lands on destination")
	check(c.save_course().begins_with("Course motion saved"),"save after linked traversal")
	await walk(c,Vector3(0,0,-20),0.25)
	check(a._grounded and a.global_position.z < -19,"drop and gate exit completed")
	var events: Array=[]
	for s in c.samples:
		if not s.event.is_empty(): events.append({"tick":s.tick,"event":s.event,"position":s.position})
	var record: Dictionary={"model_id":M.VERSION,"operation_id":"locomotion-connected-route.v1","engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,"motor_digest":c.motor_digest(),"geometry_digest":c.geometry_digest(),"setup":"normal course spawn; no subsequent pose/progress injection","samples":c.samples,"events":events,"end":c.snapshot(),"human_playtested":false}
	var f:=FileAccess.open("user://locomotion-route-trace.json",FileAccess.WRITE);f.store_string(JSON.stringify(record,"\t"));f.close()
	metrics.route_ticks=c.tick;metrics.route_end=M.array(a.global_position)
	await dispose(c)

func run() -> void:
	math_tests();await physics_tests();await journey()
	var f:=FileAccess.open("user://locomotion-test-summary.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"verification_id":"locomotion-native-checks.v1","passed":passed,"failed":failed,"metrics":metrics,"physics_hz":Engine.physics_ticks_per_second},"\t"));f.close()
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("LOCOMOTION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
