# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Contact persistence, atomic refusal, reachable hand IK and physical journey tests.
const Course := preload("res://mechanics/course.gd")
const M := preload("res://player/locomotion_rules.gd")
const R := preload("res://player/traversal_record.gd")
const IK := preload("res://player/two_bone_ik.gd")
var passed := 0
var failed := 0
var observations: Array=[]
const SAVE := "user://test-traversal-contact.json"

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1;push_error("CONTACT FAIL: "+label)
func near(a: float,b: float,epsilon: float,label: String) -> void: check(absf(a-b)<=epsilon,label+" / "+str(a)+" vs "+str(b))
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func json_copy(s: Dictionary) -> Dictionary: return JSON.parse_string(JSON.stringify(s))
func release() -> void:
	for key in ["move_forward","move_backward","move_left","move_right","sprint","traverse_obstacle","traverse_jump"]: Input.action_release(key)
func new_course() -> Node3D:
	var c:=Course.new();c.save_path=SAVE;root.add_child(c);await frames(8);return c
func dispose(c: Node3D) -> void:
	release();root.remove_child(c);c.queue_free();await frames(2)
func manual(c: Node3D,p: Vector3) -> void:
	# A labelled physical fixture. Subsequent movement always uses the shared motor.
	c.set_paused(true);c.avatar.input_enabled=true;c.avatar.clear_traversal()
	c.avatar.global_position=p;c.avatar.velocity=Vector3.ZERO;c.avatar._grounded=false
	c.avatar._coyote=0;c.avatar._buffer=0;c.avatar.pivot.rotation=Vector3(-0.2,0,0)
	for _i in range(10): step(c)
func step(c: Node3D,obstacle: bool=false) -> void:
	var error: String=c.avatar.step_motion(1.0/60,Vector2.ZERO,false,false,obstacle)
	c.tick+=1
	if not error.is_empty(): print("CONTACT FIXTURE refusal: ",error)
func trace(c: Node3D,n: int) -> Array:
	var out: Array=[]
	for _i in range(n):
		step(c);out.append(json_copy(c.snapshot()))
	return out

func math_tests() -> void:
	for translation in [Vector3.ZERO,Vector3(3,-2,8)]:
		for target in [Vector3(.2,.1,-.3),Vector3(0,0,.4),Vector3(0,.4,0),Vector3(.44,0,0)]:
			var answer:=IK.solve(translation,translation+target,translation+Vector3(.3,-.2,.1),.28,.28)
			check(answer.reachable,"reachable analytic arm")
			near(answer.elbow.distance_to(translation),.28,.000001,"upper length preserved")
			near(answer.elbow.distance_to(answer.end),.28,.000001,"lower length preserved")
			near(answer.end.distance_to(translation+target),0,.000001,"analytic endpoint")
	for target in [Vector3.ZERO,Vector3(0,0,1),Vector3(NAN,0,0),Vector3(INF,0,0)]:
		check(not IK.solve(Vector3.ZERO,target,Vector3.UP,.28,.28).reachable,"unreachable/singular arm refused")
	check(not IK.solve(Vector3.ZERO,Vector3(0,0,.2),Vector3.UP,-1,.28).reachable,"negative length refused")
	check(not IK.solve(Vector3.ZERO,Vector3(0,0,.2),Vector3.UP,NAN,.28).reachable,"nonfinite length refused")
	check(IK.solve(Vector3.ZERO,Vector3(0,.4,0),Vector3.UP,.28,.28).reachable,"collinear pole has finite deterministic bend")

func persistence_tests() -> void:
	var c=await new_course()
	for kind in ["vault","mantle"]:
		for segment in range(3):
			manual(c,Vector3(0,.04,.95) if kind=="vault" else Vector3(0,.04,-2.7))
			step(c,true)
			for _i in range(120):
				if c.avatar._route.is_empty() or c.avatar._route_index==segment: break
				step(c)
			check(not c.avatar._route.is_empty() and c.avatar._route_index==segment,"active "+kind+" segment "+str(segment))
			var saved:=json_copy(c.snapshot())
			check(saved.motion.has("traversal") and c.validate(saved).is_empty(),"captured contact passes replay validation")
			check(c.save_course().begins_with("Course motion saved"),"actual mid-contact file save")
			var baseline:=trace(c,80)
			check(c.load_course().begins_with("Course motion restored"),"actual mid-contact file load")
			check(c.samples.is_empty(),"rewind clears later observations")
			var replay:=trace(c,80)
			check(baseline==replay,"every resumed tick matches uninterrupted "+kind+" segment "+str(segment))
			check(c.avatar._route.is_empty() and c.avatar._grounded,"resumed traversal lands")
			observations.append({"kind":kind,"segment":segment,"saved":saved,"uninterrupted":baseline,"resumed":replay})
	# A new scene has different process handles but the same author-owned support IDs.
	manual(c,Vector3(0,.04,-2.7));step(c,true)
	var saved:=json_copy(c.snapshot());var rid: RID=c.get_node("mantle_block").get_rid()
	var expected:=trace(c,80)
	await dispose(c);c=await new_course();c.set_paused(true);c.avatar.input_enabled=true
	check(c.get_node("mantle_block").get_rid()!=rid,"fresh scene allocates a different support handle")
	check(c.restore(saved).is_empty(),"fresh scene restores via stable ID, not old instance handle")
	check(trace(c,80)==expected,"fresh-scene replay is identical")
	await dispose(c)

func tamper_tests() -> void:
	var c=await new_course();manual(c,Vector3(0,.04,-2.7));step(c,true)
	var saved:=json_copy(c.snapshot())
	for kind in ["kind","schema","extra","missing","index","fraction","negative","path","contact","origin","forward","up","surface","landing","binding","grounded","velocity","timer","off_path","disabled_profile","loaded"]:
		var bad: Dictionary=saved.duplicate(true)
		match kind:
			"kind": bad.motion.traversal.kind="teleport"
			"schema": bad.motion.traversal.schema="other"
			"extra": bad.motion.traversal.privilege=true
			"missing": bad.motion.traversal.erase("landing")
			"index": bad.motion.traversal.index=3
			"fraction": bad.motion.traversal.index=.5
			"negative": bad.motion.traversal.index=-1
			"path": bad.motion.traversal.points[1][0]=4
			"contact": bad.motion.traversal.contact[1]+=.2
			"origin": bad.motion.traversal.origin[2]+=1
			"forward": bad.motion.traversal.forward=[NAN,0,-1]
			"up": bad.motion.traversal.forward=[0,1,0]
			"surface": bad.motion.traversal.surface.id="missing_obstacle"
			"landing": bad.motion.traversal.landing.id="ground"
			"binding": bad.motion.traversal.surface.digest="0".repeat(64)
			"grounded": bad.motion.grounded=true
			"velocity": bad.motion.velocity[0]=1
			"timer": bad.motion.coyote=.1
			"off_path": bad.motion.position[0]+=.3
			"disabled_profile": c.avatar.traversal_enabled=false;bad.motor_digest=c.motor_digest()
			"loaded": c.avatar.external_speed_limit=3
		var before:=json_copy(c.snapshot());var events: Array=c.samples.duplicate(true)
		check(not c.restore(bad).is_empty(),"refuse contact tamper "+kind)
		check(json_copy(c.snapshot())==before and c.samples==events,"refusal preserves world/tick/trace "+kind)
		c.avatar.traversal_enabled=true;c.avatar.external_speed_limit=INF
	# Last good file remains intact when a currently active binding becomes invalid.
	check(c.save_course().begins_with("Course motion saved"),"establish last good file")
	var bytes:=FileAccess.get_file_as_string(SAVE)
	var source: StaticBody3D=c.get_node("mantle_block")
	source.get_child(0).shape.size.x+=.1
	check(not c.save_course().begins_with("Course motion saved"),"edited support refuses save")
	check(FileAccess.get_file_as_string(SAVE)==bytes,"refused save retains last good file")
	source.get_child(0).shape.size.x-=.1
	await dispose(c)

func world_tests() -> void:
	for change in ["moved_source","reshaped","layer","disabled","unmarked","conveyor","deleted_source","moved_landing","deleted_landing","duplicate","blocked_path","blocked_pose"]:
		var c=await new_course();manual(c,Vector3(0,.04,.95));step(c,true)
		var saved:=json_copy(c.snapshot());var source: StaticBody3D=c.get_node("vault_rail")
		var landing: StaticBody3D=R.resolve(c.avatar,saved.motion.traversal.landing)
		check(landing!=null,"resolved actual vault landing")
		match change:
			"moved_source": source.position.x+=.1
			"reshaped": source.get_child(0).shape.size.x+=.1
			"layer": source.collision_layer=2
			"disabled": source.get_child(0).disabled=true
			"unmarked": source.set_meta("traversable",false)
			"conveyor": source.constant_linear_velocity=Vector3.RIGHT
			"deleted_source": source.free()
			"moved_landing": landing.position.y-=.1
			"deleted_landing": landing.free()
			"duplicate":
				var duplicate=c.build_box({"id":"duplicate_fixture","at":[10,0,10],"size":[1,1,1],"traversable":false})
				duplicate.set_meta("traversal_id","vault_rail")
			"blocked_path": c.build_box({"id":"contact_late_wall","at":[0,1.8,-.4],"size":[3,3,.1],"traversable":false})
			"blocked_pose": c.build_box({"id":"contact_at_pose","at":M.array(c.avatar.global_position+Vector3.UP),"size":[.5,.5,.5],"traversable":false})
		await frames(3)
		var before:=json_copy(c.snapshot())
		check(not c.restore(saved).is_empty(),"world change refuses resume "+change)
		check(json_copy(c.snapshot())==before,"world refusal is atomic "+change)
		if change!="blocked_pose":
			for _i in range(60):
				step(c)
				if c.avatar._route.is_empty(): break
			check(c.avatar._route.is_empty() and c.avatar.contact_frame().is_empty(),"live traversal releases invalid contact "+change)
		await dispose(c)

func pose_tests() -> void:
	var c=await new_course();manual(c,Vector3(0,.04,-3.08));step(c,true)
	var a=c.avatar;var proxy=a.get_node("LocomotionProxy")
	check(not a._route.is_empty(),"close-reach mantle is physically admitted")
	proxy.update_pose(0);check(proxy.grips.size()==2,"both proxy hands reach admitted top without stretching")
	var before:=json_copy(c.snapshot());var contact: Dictionary=a.contact_frame()
	var high_error:=0.0
	for grip in proxy.grips:
		high_error=maxf(high_error,grip.error);near(grip.error,0,.00001,"actual skeleton hand meets world-space top target")
	check(json_copy(c.snapshot())==before,"IK never writes motion, route, clock or resources")
	a.pivot.rotation.y=1.4;proxy.update_pose(0)
	check(proxy.grips.size()==2 and a.contact_frame()==contact,"looking aside does not rotate the admitted grip")
	near(proxy.rotation.y,0,.00001,"proxy faces traversal direction, not moving camera")
	# Save/load updates the paused rig immediately, without advancing animation or physics.
	before=json_copy(c.snapshot());step(c);step(c)
	check(c.restore(before).is_empty(),"paused hand-contact restore")
	check(proxy.grips.size()==2,"restored frame rebuilds contact pose immediately")
	for _i in range(30): step(c)
	proxy.update_pose(0);check(proxy.grips.is_empty(),"out-of-reach/completed hand contacts release")
	observations.append({"operation_id":"proxy-two-bone-contact.v1","max_endpoint_error":high_error,"limb_lengths":[.28,.28],"body_writes":false,"setup":"close-reach mantle fixture; limited contact phase, not a full climbing animation"})
	await dispose(c)

func walk(c: Node3D,p: Vector3) -> void:
	var arrived:=false
	for _i in range(400):
		var d: Vector3=p-c.avatar.global_position;d.y=0
		if d.length()<.18: arrived=true;break
		c.avatar.pivot.rotation.y=atan2(-d.x,-d.z);Input.action_press("move_forward");await physics_frame
	release();await frames(15);check(arrived,"linked journey reaches "+str(p))
func obstacle() -> void:
	var event:=InputEventAction.new();event.action="traverse_obstacle";event.pressed=true;Input.parse_input_event(event)
	await frames(2);event=InputEventAction.new();event.action="traverse_obstacle";event.pressed=false;Input.parse_input_event(event)
func journey() -> void:
	var c=await new_course()
	# Normal spawn. No pose/progress injection. Save/reload both actual inputs' traversals.
	for p in [Vector3(0,0,1.15),Vector3(0,0,-2.65)]:
		await walk(c,p);await obstacle();check(not c.avatar._route.is_empty(),"input starts active traversal")
		c.set_paused(true);var saved:=json_copy(c.snapshot());await frames(5)
		check(json_copy(c.snapshot())==saved,"pause freezes committed path")
		check(c.save_course().begins_with("Course motion saved"),"journey saves mid-traversal")
		c.set_paused(false);await frames(80)
		check(c.load_course().begins_with("Course motion restored"),"journey rewinds to saved contact")
		check(not c.avatar._route.is_empty(),"loaded journey has remaining path, not completed teleport")
		await frames(80);check(c.avatar._grounded,"reloaded journey completes and lands")
	check(c.avatar.global_position.y>1.39,"input-driven restored vault and mantle reach platform")
	observations.append({"operation_id":"contact-connected-journey.v1","setup":"normal spawn, walking and action inputs, no pose/progress injection","final":c.snapshot(),"trace":c.samples})
	await dispose(c)

func run() -> void:
	math_tests();await persistence_tests();await tamper_tests();await world_tests();await pose_tests();await journey()
	var record: Dictionary={"verification_id":"traversal-contact-native.v1","model_id":R.VERSION,"engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,"passed":passed,"failed":failed,"observations":observations,"human_playtested":false}
	var file:=FileAccess.open("user://traversal-contact-native.json",FileAccess.WRITE);file.store_string(JSON.stringify(record,"\t"));file.close()
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("TRAVERSAL_CONTACT_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
