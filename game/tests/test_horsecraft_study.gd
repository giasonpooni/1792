extends SceneTree
## Actual shared horse motor/input qualification. No campaign pose injection or save writes.
const Study:=preload("res://mounts/horsecraft_study.tscn")
const HomeState:=preload("res://territory/gujranwala_state.gd")
const State:=preload("res://mounts/horsecraft_state.gd")
var passed:=0
var failed:=0
var scene: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("HORSECRAFT SCENE: "+message)

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0.0,steer: float=0.0,brake: bool=false,fast: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if steer<0: Input.action_press("move_left",absf(steer))
	if steer>0: Input.action_press("move_right",steer)
	if brake: Input.action_press("move_backward")
	if fast: Input.action_press("sprint")

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	scene._unhandled_input(event)

func click() -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	scene._unhandled_input(event)

func reset() -> void:
	controls();key(KEY_BACKSPACE);await frames(5)
	check(scene.model.stance()=="seated","restart returns to seated support")
	check(scene.observation().safe,"spawn grounds two independent horses safely")

func _run() -> void:
	# A detached authoritative Home profile supplies a preservation witness.
	var campaign:=HomeState.new()
	var preserved: Dictionary=campaign.snapshot()
	var save_paths: Array[String]=["user://1792-childhood-v1.json","user://1792-gujranwala-v1.json","user://1792-companions-v1.json"]
	var saved_digests: Dictionary={}
	for path in save_paths: saved_digests[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	scene=Study.instantiate();root.add_child(scene);await frames(5)
	check(scene.get_meta("campaign_admission")==false,"study is not admitted to campaign")
	check(scene.get_meta("historical_authentication")==false,"study does not authenticate the remembered feat")
	check(scene.left.get_rid()!=scene.right.get_rid(),"horses have independent physics identities")
	check(not scene.left.is_physics_processing() and not scene.right.is_physics_processing(),"scene alone executes both horse motors")
	check(is_equal_approx(scene.left.get_node("Hull").shape.radius,.8) and is_equal_approx(scene.right.get_node("Hull").shape.radius,.8),"existing conservative collision hulls retained")
	check(scene.observation().safe,"initial observed support is grounded and aligned")
	var left_start: Vector3=scene.left.global_position
	var right_start: Vector3=scene.right.global_position
	controls(1.0);await frames(35)
	check(scene.left.global_position.z<left_start.z-.3 and scene.right.global_position.z<right_start.z-.3,"actual W drives both existing motors")
	check(scene.left.speed>1.0 and scene.right.speed>1.0,"W accelerates both independently")
	check(scene.model.snapshot().stage=="stand","observed approach advances local objective")
	key(KEY_SPACE)
	check(scene.model.stance()=="rising","actual Space requests supported rise")
	await frames(State.RISE_TICKS+State.STAND_OBJECTIVE_TICKS+5)
	check(scene.model.stance()=="standing","continuous real straight riding completes rise")
	check(scene.model.snapshot().stage=="volley","supported standing hold completes local objective")
	check(scene.observation().safe and scene.observation().fore_aft<.45,"follower remains inside measured support during straight ride")
	for slot in range(4):
		key(KEY_1+slot)
		var before: int=scene.model.snapshot().shots.size()
		click()
		check(scene.model.snapshot().shots.size()==before+1,"real left click discharges slot %d"%slot)
		check(not scene.model.snapshot().slots[slot],"fired slot %d is independently empty"%slot)
	check(scene.shot_observations.size()==4,"four accepted shots retain scene collision observations")
	var emptied: Dictionary=scene.model.snapshot()
	click()
	check(scene.model.snapshot()==emptied,"fifth click cannot create an extra charge")
	check(scene.model.snapshot().stage=="reload","standing four-slot volley requests local reload")
	key(KEY_R)
	check(scene.model.snapshot().reload_slot==-1,"R refuses reload at actual trot speed")
	controls(0,0,true);await frames(45)
	check(scene.observation().max_speed<.15,"actual S brakes both to a stop")
	key(KEY_R)
	check(scene.model.snapshot().reload_slot==3,"R starts only the selected empty slot charge cycle")
	await frames(30)
	check(scene.model.snapshot().reload_ticks>0,"slow aligned grounded pair advances reload")
	controls(1.0);await frames(55)
	check(scene.observation().max_speed>State.RELOAD_SPEED,"actual W carries pair beyond allowed reload gait")
	var charge_ticks: int=scene.model.snapshot().reload_ticks
	await frames(12)
	check(scene.model.snapshot().reload_paused and scene.model.snapshot().reload_ticks==charge_ticks,"observed faster gait suspends charge progress")
	key(KEY_ESCAPE)
	var frozen: Dictionary=scene.model.snapshot()
	var left_pose: Transform3D=scene.left.global_transform
	var right_pose: Transform3D=scene.right.global_transform
	var observed_count: int=scene.observations.size()
	controls(1.0,1.0);key(KEY_R);key(KEY_SPACE);click();await frames(30)
	check(scene.model.snapshot()==frozen,"pause freezes local time, stance, charges and reload")
	check(scene.left.global_transform==left_pose and scene.right.global_transform==right_pose,"pause freezes both physical bodies")
	check(scene.observations.size()==observed_count,"pause produces no fake motion observations")
	controls();key(KEY_ESCAPE)
	await frames(State.RELOAD_TICKS)
	check(scene.model.snapshot().slots[3] and scene.model.snapshot().reload_slot==-1,"unpaused local reload restores exactly one charge")
	check(scene.model.snapshot().slots==[false,false,false,true],"reload cannot refill other spent slots")
	check(scene.model.snapshot().stage=="reload","one charge cycle cannot complete four-weapon reload objective")
	for slot in range(3):
		key(KEY_1+slot);key(KEY_R)
		check(scene.model.snapshot().reload_slot==slot,"next charge cycle is bound to selected empty slot %d"%slot)
		await frames(State.RELOAD_TICKS+1)
		check(scene.model.snapshot().slots[slot],"full exclusive charge cycle reloads slot %d"%slot)
	check(scene.model.snapshot().slots==[true,true,true,true],"four exclusive cycles recharge four individual weapons")
	check(scene.model.snapshot().stage=="exit","all four charges allow local settle-and-stop objective")
	key(KEY_SPACE);await frames(State.RECOVER_TICKS+5)
	check(scene.model.stance()=="seated" and scene.model.snapshot().stage=="complete","settle and stop completes only local study")
	await _test_steering()
	await _test_trot_turn_roundoff()
	await _test_collision()
	await _test_clock_rate()
	await _test_rays()
	check(campaign.snapshot()==preserved,"study leaves detached Home authority unchanged")
	for path in save_paths:
		var after: String=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		check(after==saved_digests[path],"study never writes campaign slot "+path)
	# The fixed-fps runner can process many game ticks before the audio mix thread
	# completes one wall-clock mix. Witness the actual resources without keeping
	# them alive; production _exit_tree must stop and release them on scene exit.
	var stream_witness: WeakRef=weakref(scene.shot_sound.stream)
	var playback_witness: WeakRef=weakref(scene.shot_sound.get_stream_playback())
	controls();scene.queue_free();scene=null;await process_frame
	var release_deadline: int=Time.get_ticks_usec()+1000000
	while (stream_witness.get_ref()!=null or playback_witness.get_ref()!=null) and Time.get_ticks_usec()<release_deadline:
		await process_frame
	check(playback_witness.get_ref()==null,"production scene exit releases active native audio playback")
	check(stream_witness.get_ref()==null,"production scene exit releases synthesized audio resource")
	print("HORSECRAFT_SCENE_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

func _test_steering() -> void:
	await reset()
	controls(1.0);await frames(35)
	var before_left: float=scene.left.rotation.y
	var before_right: float=scene.right.rotation.y
	controls(1.0,-.25);await frames(15)
	check(scene.left.rotation.y>before_left+.03,"actual A reins steer lead horse")
	check(scene.right.rotation.y>before_right+.015,"follower steers through its own shared motor")
	controls()

func _test_collision() -> void:
	await reset()
	controls(1.0);await frames(25);key(KEY_SPACE);await frames(State.RISE_TICKS+5)
	check(scene.model.stance()=="standing","one-sided collision fixture begins with supported standing")
	var obstruction: StaticBody3D=scene.obstacle("OneHorseObstruction",Vector3(scene.left.global_position.x,1.8,scene.left.global_position.z-3.0),Vector3(.8,3.6,.5),Color.GRAY)
	await frames(3)
	var stopped_z: float=obstruction.global_position.z+.25+.8
	var unsafe_seen:=false
	var independent_seen:=false
	for _i in range(85):
		await physics_frame
		var support: Dictionary=scene.observation()
		if not support.safe: unsafe_seen=true
		if absf(scene.left.global_position.z-scene.right.global_position.z)>.2: independent_seen=true
	await process_frame
	check(scene.left.global_position.z>=stopped_z-.08,"left collision hull cannot cross one-sided solid obstruction")
	check(independent_seen,"unblocked horse moves independently instead of copying blocked transform")
	check(unsafe_seen,"one-sided obstruction produces observed loss of support")
	check(scene.model.stance() in ["recovering","seated"],"lost physical support exits standing state")
	controls();obstruction.queue_free();await frames(3);await reset()
	check(scene.model.snapshot().slots==[true,true,true,true] and scene.shot_observations.is_empty(),"retry resets local weapons and retained shots")

func _test_trot_turn_roundoff() -> void:
	await reset()
	controls(1.0);await frames(100);key(KEY_SPACE);await frames(85)
	check(scene.model.stance()=="standing","real full-trot input completes supported rise")
	controls(1.0,.1);await frames(5)
	check(scene.observation().safe,"gentle native trot turn retains measured support within numeric tolerance")
	check(scene.model.stance()=="standing","floating-point norm roundoff cannot force recovery during safe trot turn")
	controls()

func _test_rays() -> void:
	scene.set_paused(true)
	var target: StaticBody3D=scene.targets[0]
	var endpoint: Vector3=target.global_position
	var origin: Vector3=endpoint+Vector3(0,0,10)
	var clear_hit: Dictionary=scene.shot_query(origin,endpoint-Vector3(0,0,1))
	check(not clear_hit.is_empty() and clear_hit.collider==target,"native target collision ray identifies existing practice target")
	var cover: StaticBody3D=scene.obstacle("TargetCover",origin.lerp(endpoint,.5),Vector3(2,3,.6),Color.GRAY)
	await frames(3)
	var blocked_hit: Dictionary=scene.shot_query(origin,endpoint-Vector3(0,0,1))
	check(not blocked_hit.is_empty() and blocked_hit.collider==cover,"native collision ray hits intervening cover before target")
	check(not blocked_hit.collider.has_meta("target_id"),"cover cannot be recorded as a practice target")
	# An explicit aiming fixture qualifies the real fire adapter, not a gameplay camera claim.
	# Both horse motors retain their owning callback; no body or campaign pose is injected.
	scene.set_paused(false)
	scene.camera.global_position=origin;scene.camera.look_at(endpoint,Vector3.UP)
	var fired: Dictionary=scene.fire()
	check(fired.accepted,"real fire adapter accepts a charged shot into cover")
	check(scene.shot_observations.back().target_id.is_empty(),"accepted shot cannot acknowledge target behind cover")
	check(scene.model.snapshot().hits.is_empty(),"cover hit does not create a target grant")
	scene.set_paused(true)
	cover.queue_free();await frames(3)
	await reset();scene.set_paused(true)
	# Explicit near-barrel cover fixture: the outward muzzle ray is clear because
	# the barrel has protruded through cover. Shoulder-to-muzzle clearance must
	# still reject a target acknowledgement without moving either horse.
	var muzzle: Vector3=scene.weapon.global_position-scene.weapon.global_basis.z*.85
	var target_at: Vector3=scene.camera.global_position-scene.camera.global_basis.z*15.0
	var barrel_target: StaticBody3D=scene.obstacle("MuzzleCoverTarget",target_at,Vector3(4,4,.3),Color.GRAY,2)
	barrel_target.set_meta("target_id","muzzle_cover_target")
	var thin_cover: StaticBody3D=scene.obstacle("ThinMuzzleCover",muzzle.lerp(scene.weapon.global_position,.5),Vector3(.6,1.2,.2),Color.GRAY)
	await frames(3)
	var camera_clear: Dictionary=scene.shot_query(scene.camera.global_position,target_at)
	var muzzle_clear: Dictionary=scene.shot_query(muzzle,target_at)
	check(not camera_clear.is_empty() and camera_clear.collider==barrel_target,"past-cover fixture leaves camera-to-target ray clear")
	check(not muzzle_clear.is_empty() and muzzle_clear.collider==barrel_target,"past-cover fixture leaves outward muzzle ray clear")
	scene.set_paused(false)
	var obstructed_shot: Dictionary=scene.fire()
	check(obstructed_shot.accepted,"barrel-obstructed attempt spends its accepted charge")
	check(scene.shot_observations.back().muzzle_obstructed,"native shoulder-to-muzzle probe detects protruding barrel cover")
	check(scene.shot_observations.back().target_id.is_empty() and scene.model.snapshot().hits.is_empty(),"protruding barrel cannot grant hit through thin cover")
	scene.set_paused(true)
	var inside_hit: Dictionary=scene.shot_query(thin_cover.global_position,target_at)
	check(not inside_hit.is_empty() and inside_hit.collider==thin_cover,"native ray starting inside cover reports that cover")
	thin_cover.queue_free();barrel_target.queue_free();await frames(3)

func _test_clock_rate() -> void:
	scene.set_paused(true)
	Engine.physics_ticks_per_second=30
	scene.set_paused(false)
	check(scene.paused,"unsupported physics rate cannot be explicitly unpaused")
	key(KEY_BACKSPACE)
	check(scene.paused and scene.model.snapshot().tick==0,"unsupported-rate retry resets locally but remains paused")
	var frozen: Dictionary=scene.model.snapshot()
	var left_pose: Transform3D=scene.left.global_transform
	var right_pose: Transform3D=scene.right.global_transform
	controls(1.0);key(KEY_SPACE);key(KEY_R);click();await frames(10)
	check(scene.model.snapshot()==frozen,"unsupported rate admits no physics ticks or weapon/stance input")
	check(scene.left.global_transform==left_pose and scene.right.global_transform==right_pose,"unsupported rate preserves both body transforms")
	Engine.physics_ticks_per_second=60
	controls();scene.set_paused(false);await frames(5)
	check(not scene.paused and scene.model.snapshot().tick>0,"restoring supported physics rate permits normal local execution")
