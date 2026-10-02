# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Real native collision fixtures and a separate input-driven, normal-spawn journey.
const Course := preload("res://mechanics/ground_course.gd")
const M := preload("res://player/locomotion_rules.gd")
const Probe := preload("res://player/traversal_probe.gd")
const Ground := preload("res://player/ground_contact.gd")
var isolated_slot := "user://test-ground-contact-isolated-%d.json" % OS.get_process_id()
var passed := 0
var failed := 0
var summary: Dictionary = {}
var spatial_summary: Dictionary = {}
var journey_trace: Array = []
var retained_snapshot: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(condition: bool, text: String) -> void:
	if condition: passed += 1
	else: failed += 1; push_error("GROUND CONTACT FAIL: " + text)
func near(a: float,b: float,tolerance: float,text: String) -> void:
	check(absf(a-b) <= tolerance,text + " / " + str(a) + " vs " + str(b))
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func release() -> void:
	for action in ["move_left","move_right","move_forward","move_backward","sprint","traverse_jump","traverse_obstacle"]: Input.action_release(action)
func new_course() -> Node3D:
	var course := Course.new(); course.save_path = isolated_slot; root.add_child(course); await frames(12); return course
func dispose(course: Node3D) -> void:
	release(); root.remove_child(course); course.queue_free(); await frames(2)
func fixture(course: Node3D, position: Vector3, settle: int = 12) -> void:
	# Declared setup for one collision experiment. Never used by played_journey().
	release(); course.set_paused(false); course.avatar.global_position = position
	course.avatar.velocity = Vector3.ZERO; course.avatar._grounded = false
	course.avatar._coyote = 0; course.avatar._buffer = 0; course.avatar._route.clear(); course.avatar.clear_ground_contact()
	course.avatar.clear_motion_requests(); course.avatar.pivot.rotation = Vector3(-0.2,0,0)
	await frames(settle); course.samples.clear()
func walk_z(course: Node3D, target: float, maximum: int = 700, strength: float = 0.6) -> bool:
	release()
	var start: float = course.avatar.global_position.z
	var sign: float = signf(target-start)
	Input.action_press("move_backward" if sign > 0 else "move_forward",strength)
	var arrived := false
	for _i in range(maximum):
		await frames(1)
		if sign*(target-course.avatar.global_position.z) <= 0.16: arrived = true; break
	release(); await frames(18); return arrived
func collision_box(course: Node3D,name: String,position: Vector3,size: Vector3) -> StaticBody3D:
	return course.build_box({"id": name,"at": M.array(position),"size": M.array(size)})
func no_overlap(course: Node3D) -> bool:
	# Small elevation separates resting contact from capsule penetration.
	var separated: Transform3D = course.avatar.global_transform; separated.origin += Vector3.UP*0.003
	return Ground.clear_at(course.avatar,separated)

func observed_motion(actor: CharacterBody3D) -> Dictionary:
	# A refused save is not a motion observation; retain the actual body and contact.
	var contact: Dictionary = {}
	if actor.ground_contact_active():
		contact = {"elapsed": actor._ground_step.elapsed,"sole": actor._ground_step.sole,
			"anchor": M.array(actor._ground_step.anchor.origin),"direction": M.array(actor._ground_step.direction),
			"surface": str(actor._ground_step.surface.get_path())}
	return {"position": M.array(actor.global_position),"velocity": M.array(actor.velocity),
		"grounded": actor._grounded,"native_floor": actor.is_on_floor(),"coyote": actor._coyote,"buffer": actor._buffer,
		"camera": M.array(actor.pivot.rotation),"mode": actor.motion_mode_name,"event": actor.last_ground_event,
		"rise": actor.last_ground_rise,"displacement": M.array(actor.last_ground_displacement),"contact": contact,
		"capture": actor.capture_motion()}

func manual_tick(actor: CharacterBody3D,stick: Vector2) -> String:
	await physics_frame
	return actor.step_motion(1.0/60.0,stick,false)

func slope_midpoint(course: Node3D) -> bool:
	await fixture(course,Vector3(-6,0.04,-0.7))
	Input.action_press("move_forward",0.6)
	var reached:=false
	for _i in range(180):
		await frames(1)
		if course.avatar.global_position.z < -2.25: reached=true;break
	release();await frames(1);course.samples.clear()
	return reached

func physical_contact_modes(samples: Array, actor: CharacterBody3D) -> bool:
	# Upward corner transfer is explicit bounded contact. Descending stair nosings
	# may release into real gravity for a short, geometrically supported fall.
	var previous: Dictionary = {}; var contact_run := 0; var air_run := 0; var air_origin := 0.0
	for sample in samples:
		if not sample.grounded and sample.mode == "step_contact":
			contact_run += 1
			if contact_run > 60: return false
			air_run = 0
		elif not sample.grounded and sample.mode == "air":
			if previous.is_empty(): return false
			var p := M.point(sample.position); var prior := M.point(previous.position)
			var velocity := M.point(sample.velocity); var previous_velocity := M.point(previous.velocity)
			if air_run == 0:
				if previous.mode != "ground" or previous_velocity.z <= 0: return false
				air_origin = prior.y
			else:
				if absf(velocity.y-(previous_velocity.y-actor.gravity_strength/60)) > 0.0001: return false
			air_run += 1; contact_run = 0
			if air_run > 12 or p.y > prior.y+0.0001 or velocity.y > 0 or p.z < prior.z-0.0001: return false
			if p.z < 1.3 or p.z > 4.5 or air_origin-p.y > 0.202: return false
			var query := PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.01,p-Vector3.UP*0.302,actor.collision_mask,[actor.get_rid()])
			var floor_hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
			if floor_hit.is_empty() or not floor_hit.collider is StaticBody3D or floor_hit.normal.y < cos(actor.floor_max_angle): return false
		elif not sample.grounded: return false
		else: contact_run = 0; air_run = 0
		previous = sample
	return true

func played_journey() -> void:
	var course = await new_course()
	check(course.avatar.ground_contact_enabled,"ground qualification opt-in enabled only here")
	check(course.avatar.is_on_floor(),"normal authored spawn settles on actual floor")
	near(course.avatar.global_position.z,7,0.0001,"normal spawn requires no injected pose")
	course.samples.clear()
	check(await walk_z(course,-0.65),"connected normal-spawn stair ascent")
	near(course.avatar.global_position.y,0.72,0.012,"stair ascent reaches real plateau height")
	check(course.avatar.is_on_floor() and no_overlap(course),"plateau floor and capsule clearance")
	course.set_paused(true); retained_snapshot = course.snapshot().duplicate(true)
	var frozen: Dictionary = course.snapshot(); var sample_count: int = course.samples.size()
	Input.action_press("move_forward"); await frames(15)
	check(course.snapshot() == frozen and course.samples.size() == sample_count,"pause preserves course time, capsule, timers and evidence")
	release(); course.set_paused(false)
	check(await walk_z(course,-6.4),"connected incline descent reaches exit")
	near(course.avatar.global_position.y,0,0.012,"incline descent reaches original floor")
	check(await walk_z(course,-0.6),"connected incline ascent returns to plateau")
	near(course.avatar.global_position.y,0.72,0.012,"incline ascent height follows geometry")
	check(await walk_z(course,7),"connected stair descent returns to normal spawn")
	near(course.avatar.global_position.y,0,0.012,"stair descent returns floor height")
	journey_trace = course.samples.duplicate(true)
	var up := 0; var down := 0; var horizontal_max := 0.0; var rise_max := 0.0
	var bounds_ok := true; var finite_ok := true; var tick_ok := true; var floor_count := 0
	var clearance_ok := true
	var previous: Dictionary = {}
	for sample in journey_trace:
		var p := M.point(sample.position)
		finite_ok = finite_ok and p.is_finite() and M.point(sample.velocity).is_finite() and M.finite(sample.rise)
		bounds_ok = bounds_ok and absf(p.x) < 0.02 and p.y >= -0.012 and p.y <= 0.732
		if sample.grounded: floor_count += 1
		var occupied: Transform3D = course.avatar.global_transform; occupied.origin = p+Vector3.UP*0.003
		clearance_ok = clearance_ok and Ground.clear_at(course.avatar,occupied)
		if sample.event == "step_up": up += 1
		if sample.event == "ground_follow": down += 1
		rise_max = maxf(rise_max,absf(sample.rise))
		if not previous.is_empty():
			var prior := M.point(previous.position)
			horizontal_max = maxf(horizontal_max,Vector2(p.x-prior.x,p.z-prior.z).length())
			tick_ok = tick_ok and sample.tick == previous.tick+1
		previous = sample
	check(up >= 4,"native ascent records at least four actual step contacts")
	check(down >= 4,"native descending ground-follow observations retained")
	check(horizontal_max <= 2.25/60.0+0.002,"per-tick horizontal motion remains commanded budget")
	check(rise_max <= 0.302,"recorded step adjustment remains configured height bound")
	check(finite_ok and bounds_ok and tick_ok,"continuous played trace finite, lane bounded, single tick sequence")
	var contact_modes_ok := physical_contact_modes(journey_trace,course.avatar)
	check(contact_modes_ok,"non-floor route observations qualify bounded contact or supported descending gravity")
	if not contact_modes_ok: print("GROUND_ROUTE_UNSUPPORTED: ",JSON.stringify(journey_trace.filter(func(s): return not s.grounded and s.mode != "step_contact").slice(0,12)))
	check(clearance_ok,"full actual capsule remains clear at every played-route tick")
	check(no_overlap(course),"return journey ends with capsule outside collision geometry")
	summary = {"journey": "normal_spawn_input_only_stairs_and_incline_out_and_back", "ticks": journey_trace.size(),
		"step_up_events": up,"ground_follow_events": down,"maximum_horizontal_per_tick": horizontal_max,
		"maximum_step_adjustment": rise_max,"grounded_ticks": floor_count,"end_position": M.array(course.avatar.global_position)}
	if not OS.get_environment("GROUND_CAPTURE_OUTPUT").is_empty():
		var commit := OS.get_environment("SOURCE_COMMIT"); var tree := OS.get_environment("SOURCE_TREE")
		check(commit.length() == 40 and tree.length() == 40,"retained evidence declares exact source commit and tree")
		var directory := OS.get_environment("GROUND_CAPTURE_OUTPUT")
		DirAccess.make_dir_recursive_absolute(directory)
		var output := directory.path_join("ground-contact-journey.json")
		var f := FileAccess.open(output,FileAccess.WRITE)
		check(f != null,"retained evidence output writable")
		if f != null:
			f.store_string(JSON.stringify({"schema": "ground-contact-evidence.v1","source_commit": commit,"source_tree": tree,
				"source_digest": course.source_digest(),"geometry_digest": course.geometry_digest(),"motor_digest": course.motor_digest(),
				"physics_hz": Engine.physics_ticks_per_second,"journey": {"trace": journey_trace,"summary": summary},
				"spatial_control": spatial_summary,"snapshot": retained_snapshot},"\t",true,true))
			f.flush(); check(f.get_error() == OK,"executed journey and paused plateau snapshot retained"); f.close()
	await dispose(course)

func quarter_speed_journey() -> void:
	var course = await new_course(); course.samples.clear()
	check(await walk_z(course,-0.65,800,0.4),"quarter-speed normal-spawn stairs ascend")
	near(course.avatar.global_position.y,0.72,0.012,"quarter-speed stair ascent plateau")
	check(await walk_z(course,-6.4,800,0.4),"quarter-speed continuous incline descends")
	check(await walk_z(course,-0.6,800,0.4),"quarter-speed continuous incline ascends")
	check(await walk_z(course,7,800,0.4),"quarter-speed continuous stairs descend")
	near(course.avatar.global_position.y,0,0.012,"quarter-speed out-and-back returns authored floor")
	var previous: Dictionary = {}; var budget_ok := true; var clearance_ok := true
	for sample in course.samples:
		var p := M.point(sample.position)
		if not previous.is_empty():
			var prior := M.point(previous.position)
			budget_ok = budget_ok and Vector2(p.x-prior.x,p.z-prior.z).length() <= 1.125/60+0.002
		previous = sample
		var occupied: Transform3D = course.avatar.global_transform; occupied.origin = p+Vector3.UP*0.003
		clearance_ok = clearance_ok and Ground.clear_at(course.avatar,occupied)
	check(budget_ok,"quarter-speed physical displacement never exceeds commanded budget")
	check(physical_contact_modes(course.samples,course.avatar),"quarter-speed non-floor observations qualify bounded contact or descending gravity")
	check(clearance_ok,"quarter-speed full capsule never clips at any route tick")
	await dispose(course)

func fine_control_fixtures() -> void:
	var course = await new_course(); var actor: CharacterBody3D = course.avatar
	course.samples.clear()
	check(await walk_z(course,-0.65,5000,0.22),"near-deadzone mapped input ascends the connected stairs without cycling")
	near(actor.global_position.y,0.72,0.012,"near-deadzone ascent reaches the real plateau")
	check(actor.is_on_floor() and no_overlap(course),"near-deadzone ascent finishes supported with full capsule clearance")
	var prior_z := INF; var monotonic := true; var maximum_contact_run := 0; var contact_run := 0
	for sample in course.samples:
		monotonic = monotonic and sample.position[2] <= prior_z+0.0001
		prior_z = sample.position[2]
		if sample.mode == "step_contact": contact_run += 1; maximum_contact_run = maxi(maximum_contact_run,contact_run)
		else: contact_run = 0
	check(monotonic,"near-deadzone commanded ascent never reverses horizontal progress")
	check(maximum_contact_run > 0 and maximum_contact_run <= 60,"near-deadzone stair contact remains finite")
	check(course.samples.filter(func(s): return not s.grounded and s.mode == "air").is_empty(),"near-deadzone ascent has no undeclared fall-and-retry cycle")
	await dispose(course)
	for kind in ["stop","reverse","turn"]:
		course = await new_course(); actor = course.avatar
		await fixture(course,Vector3(0,0.04,4.65))
		Input.action_press("move_forward",0.4)
		var reached := false
		for _i in range(600):
			await frames(1)
			if actor.ground_contact_active(): reached = true; break
		check(reached,kind+" fixture begins during real stair contact")
		var before := actor.global_position
		release()
		if kind == "reverse": Input.action_press("move_backward",0.4)
		elif kind == "turn": Input.action_press("move_right",0.4)
		await frames(1)
		check(not actor.ground_contact_active(),kind+" input releases retained contact in one physics tick")
		check(Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length() <= actor.walk_speed/60.0+0.002,kind+" release respects one-tick commanded travel budget")
		await frames(24); release()
		if kind == "stop": check(actor.global_position.distance_to(before) < 0.05,"released stick stops without a stair-edge launch")
		elif kind == "reverse": check(actor.global_position.z > before.z+0.2,"reverse input retreats from the stair")
		else: check(actor.global_position.x > before.x+0.2,"turn input exits laterally from the stair")
		check(actor.is_on_floor() and no_overlap(course),kind+" result ends supported and capsule-clear")
		await dispose(course)

func slope_control_fixtures() -> Dictionary:
	var course=await new_course();var actor: CharacterBody3D=course.avatar
	check(await slope_midpoint(course),"slope stop fixture reaches real mid-slope support")
	var start:=actor.global_position
	await frames(30)
	var stopped:=actor.global_position;var stop_distance:=stopped.distance_to(start)
	var stable_start:=actor.global_position;await frames(30);var settled:=actor.global_position
	check(actor.is_on_floor() and no_overlap(course),"released slope input stays supported and capsule-clear")
	check(stop_distance<0.11 and Vector2(actor.velocity.x,actor.velocity.z).length()<0.001,"released slope input stops under inherited acceleration")
	check(settled.distance_to(stable_start)<0.002,"stopped actor does not drift on the slope")
	var stop_result:={"start":M.array(start),"stopped":M.array(stopped),"settled":M.array(settled),
		"stop_distance":stop_distance,"settled_drift":settled.distance_to(stable_start)}
	await dispose(course)
	course=await new_course();actor=course.avatar
	check(await slope_midpoint(course),"slope reverse fixture reaches real mid-slope support")
	Input.action_press("move_backward",0.6)
	var reverse_air:=0;var reverse_max:=0.0
	for _i in range(35):
		await frames(1);reverse_air+=int(not actor.is_on_floor())
		reverse_max=maxf(reverse_max,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
	release()
	check(actor.global_position.z>-1.7 and actor.global_position.y<0.02,"slope reversal returns to the lower real floor")
	check(reverse_air==0 and actor.is_on_floor() and no_overlap(course),"slope reversal remains supported and capsule-clear")
	check(reverse_max<=actor.walk_speed*0.6/60.0+0.002,"slope reversal respects commanded travel budget")
	var reverse_result:={"end":M.array(actor.global_position),"air_ticks":reverse_air,"maximum_horizontal_per_tick":reverse_max}
	await dispose(course)
	course=await new_course();actor=course.avatar
	check(await slope_midpoint(course),"lateral slope fixture reaches real mid-slope support")
	Input.action_press("move_right",0.6)
	var lateral_air:=0;var lateral_max:=0.0;var lateral_events:=0
	for _i in range(25):
		await frames(1);lateral_air+=int(not actor.is_on_floor());lateral_events+=int(actor.last_ground_event=="step_up")
		lateral_max=maxf(lateral_max,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
	release()
	check(actor.global_position.x>-5.4 and actor.global_position.y>0.3,"lateral command traverses the real sloped support")
	check(lateral_air==0 and actor.is_on_floor() and no_overlap(course),"lateral slope travel stays supported and capsule-clear")
	check(lateral_events==0,"ordinary lateral slope travel does not invent stair contact")
	check(lateral_max<=actor.walk_speed*0.6/60.0+0.002,"lateral slope travel respects commanded budget")
	var lateral_result:={"end":M.array(actor.global_position),"air_ticks":lateral_air,"step_up_events":lateral_events,"maximum_horizontal_per_tick":lateral_max}
	await dispose(course)
	course=await new_course();actor=course.avatar
	check(await slope_midpoint(course),"diagonal slope fixture reaches real mid-slope support")
	Input.action_press("move_forward",0.45);Input.action_press("move_right",0.45)
	var diagonal_air:=0;var diagonal_max:=0.0
	for _i in range(30):
		await frames(1);diagonal_air+=int(not actor.is_on_floor())
		diagonal_max=maxf(diagonal_max,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
	release()
	check(actor.global_position.x>-5.4 and actor.global_position.z<-2.8 and actor.global_position.y>0.7,"diagonal redirection climbs across real sloped support")
	check(diagonal_air==0 and actor.is_on_floor() and no_overlap(course),"diagonal slope redirection stays supported and capsule-clear")
	check(diagonal_max<=actor.walk_speed*0.6/60.0+0.002,"diagonal slope redirection respects commanded budget")
	var diagonal_result:={"end":M.array(actor.global_position),"air_ticks":diagonal_air,"maximum_horizontal_per_tick":diagonal_max}
	await dispose(course)
	return {"stop":stop_result,"reverse":reverse_result,"lateral":lateral_result,"diagonal":diagonal_result}

func spatial_control_fixtures() -> void:
	var oblique_results: Array = []
	for angle in [-45.0,-30.0,0.0,30.0,45.0]:
		var course = await new_course(); var actor: CharacterBody3D = course.avatar
		collision_box(course,"oblique_floor",Vector3(20,-0.2,3),Vector3(14,0.4,8))
		collision_box(course,"oblique_step",Vector3(20,0.09,-2),Vector3(14,0.18,2))
		await fixture(course,Vector3(20,0.04,2.5))
		course.set_physics_process(false); actor.set_physics_process(false); actor.input_enabled = true
		var stick := Vector2(sin(deg_to_rad(angle)),-cos(deg_to_rad(angle)))*0.6
		var errors: Array = []; var ticks := 0; var air := 0; var contact_run := 0; var maximum_contact := 0
		var maximum_horizontal := 0.0; var reversed := false; var clearance := true
		for _i in range(180):
			var error := await manual_tick(actor,stick); ticks += 1
			if not error.is_empty(): errors.append(error)
			var horizontal := Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z)
			maximum_horizontal = maxf(maximum_horizontal,horizontal.length())
			reversed = reversed or horizontal.dot(stick)<-0.0001
			air += int(not actor.is_on_floor() and actor.motion_mode_name=="air")
			if actor.ground_contact_active(): contact_run += 1; maximum_contact=maxi(maximum_contact,contact_run)
			else: contact_run = 0
			clearance = clearance and no_overlap(course)
			if actor.global_position.z < -2: break
		check(actor.global_position.z < -2 and absf(actor.global_position.y-0.18)<=0.012,"oblique "+str(angle)+" degree approach reaches real 18cm tread")
		check(actor.is_on_floor() and clearance,"oblique "+str(angle)+" degree approach remains supported and capsule-clear")
		check(errors.is_empty() and air==0,"oblique "+str(angle)+" degree approach has no motor refusal or fall cycle")
		check(not reversed,"oblique "+str(angle)+" degree approach never reverses commanded progress")
		check(maximum_horizontal<=actor.walk_speed*0.6/60.0+0.002,"oblique "+str(angle)+" degree approach respects commanded travel budget")
		check(maximum_contact<=60,"oblique "+str(angle)+" degree retained contact remains finite")
		oblique_results.append({"degrees":angle,"ticks":ticks,"end":M.array(actor.global_position),"air_ticks":air,
			"maximum_contact_ticks":maximum_contact,"maximum_horizontal_per_tick":maximum_horizontal})
		await dispose(course)
	# The authored side station performs a 90-degree turn from an 18cm tread onto
	# a perpendicular 12cm rise, then returns down that edge under native gravity.
	var course = await new_course(); var actor: CharacterBody3D = course.avatar
	await fixture(course,Vector3(9,0.04,2.5))
	course.set_physics_process(false); actor.set_physics_process(false); actor.input_enabled = true
	var errors: Array = []; var maximum_horizontal := 0.0; var clearance := true; var step_events := 0
	for _i in range(180):
		var error := await manual_tick(actor,Vector2(0,-0.6))
		if not error.is_empty(): errors.append(error)
		maximum_horizontal=maxf(maximum_horizontal,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
		clearance=clearance and no_overlap(course); step_events+=int(actor.last_ground_event=="step_up")
		if actor.global_position.z < -2: break
	var entry := actor.global_position; var turn_air := 0
	for _i in range(180):
		var error := await manual_tick(actor,Vector2(0.6,0))
		if not error.is_empty(): errors.append(error)
		maximum_horizontal=maxf(maximum_horizontal,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
		clearance=clearance and no_overlap(course); step_events+=int(actor.last_ground_event=="step_up")
		turn_air+=int(not actor.is_on_floor() and actor.motion_mode_name=="air")
		if actor.global_position.x > 12.5: break
	var high := actor.global_position; var down_air := 0; var down_run := 0; var maximum_down_run := 0
	for _i in range(180):
		var error := await manual_tick(actor,Vector2(-0.6,0))
		if not error.is_empty(): errors.append(error)
		maximum_horizontal=maxf(maximum_horizontal,Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length())
		clearance=clearance and no_overlap(course)
		if not actor.is_on_floor() and actor.motion_mode_name=="air": down_air+=1; down_run+=1; maximum_down_run=maxi(maximum_down_run,down_run)
		else: down_run=0
		if actor.global_position.x < 10.5: break
	var returned := actor.global_position
	check(entry.z < -2 and absf(entry.y-0.18)<=0.012,"authored turn terrace reaches the first real tread")
	check(high.x>12.5 and absf(high.y-0.30)<=0.012,"perpendicular turn reaches the higher real terrace")
	check(turn_air==0,"perpendicular uneven-ground turn stays natively supported")
	check(returned.x<10.5 and absf(returned.y-0.18)<=0.012 and actor.is_on_floor(),"terrace return follows the 12cm step down to support")
	check(down_air>0 and maximum_down_run<=12,"step down is a short bounded native-gravity transition")
	check(step_events>=2,"two real rises publish explicit upward contact observations")
	check(errors.is_empty() and clearance,"turn terrace has no motor refusal or capsule overlap")
	check(maximum_horizontal<=actor.walk_speed*0.6/60.0+0.002,"turn and step-down motion respects commanded travel budget")
	var turn_result := {"entry":M.array(entry),"high":M.array(high),"returned":M.array(returned),
		"turn_air_ticks":turn_air,"down_air_ticks":down_air,"maximum_down_air_run":maximum_down_run,
		"step_up_events":step_events,"maximum_horizontal_per_tick":maximum_horizontal}
	await dispose(course)
	# Clearance is directional too: a diagonal approach beneath a low ceiling must
	# remain on the lower floor rather than accepting the otherwise walkable rise.
	course = await new_course(); actor = course.avatar
	collision_box(course,"diagonal_ceiling_floor",Vector3(-20,-0.2,3),Vector3(14,0.4,8))
	collision_box(course,"diagonal_ceiling_step",Vector3(-20,0.09,-2),Vector3(14,0.18,2))
	collision_box(course,"diagonal_low_ceiling",Vector3(-20,1.8,-2),Vector3(14,0.3,6))
	await fixture(course,Vector3(-21,0.04,2.5))
	course.set_physics_process(false); actor.set_physics_process(false); actor.input_enabled = true
	var ceiling_events := 0; var ceiling_clear := true; var ceiling_error := false
	var ceiling_stick := Vector2(sin(deg_to_rad(30.0)),-cos(deg_to_rad(30.0)))*0.6
	for _i in range(180):
		ceiling_error = ceiling_error or not (await manual_tick(actor,ceiling_stick)).is_empty()
		ceiling_events += int(actor.last_ground_event=="step_up"); ceiling_clear=ceiling_clear and no_overlap(course)
	check(actor.global_position.y<0.02 and actor.global_position.z>-1.0,"diagonal low ceiling refuses the walkable rise / "+str(actor.global_position))
	check(ceiling_events==0 and not ceiling_error,"diagonal clearance refusal publishes no step admission or motor error")
	check(actor.is_on_floor() and ceiling_clear,"diagonal clearance refusal stays supported and capsule-clear")
	var ceiling_result:={"end":M.array(actor.global_position),"step_up_events":ceiling_events}
	await dispose(course)
	spatial_summary={"oblique_steps":oblique_results,"turn_terrace":turn_result,
		"diagonal_ceiling":ceiling_result,"slope_control":await slope_control_fixtures()}

func physical_fixtures() -> void:
	var course = await new_course(); var actor: CharacterBody3D = course.avatar
	await fixture(course,Vector3(6,0.04,4.8))
	Input.action_press("move_forward"); await frames(55); release()
	check(actor.global_position.z >= 3.82 and actor.global_position.y < 0.02,"36cm riser blocks 30cm grounded step")
	check(no_overlap(course),"overheight riser never clips capsule")
	var events: Array = course.samples.filter(func(s): return s.event == "step_up")
	check(events.is_empty(),"overheight collision never publishes step admission")
	await fixture(course,Vector3(-6,0.04,4.8))
	Input.action_press("move_forward"); await frames(55); release()
	check(actor.global_position.z >= 4.00 and actor.global_position.y < 0.02,"low ceiling refuses lifted capsule despite low riser")
	check(no_overlap(course),"low ceiling refusal leaves whole capsule clear")
	await fixture(course,Vector3(6,0.04,-0.7))
	Input.action_press("move_forward"); await frames(35); release()
	check(actor.global_position.z < -1.7,"narrow curb remains traversable without hanging on edge")
	check(no_overlap(course),"curb path has no capsule penetration")
	# Short corner continuation carries unsaved contact state and must refuse capture.
	await fixture(course,Vector3(0,0.04,4.65))
	check(course.save_course() == "Practice saved.","pre-contact practice slot seeded")
	var pre_contact_bytes := FileAccess.get_file_as_bytes(isolated_slot)
	Input.action_press("move_forward",0.6)
	var corner_refused := false
	for _i in range(65):
		await frames(1)
		if actor.capture_motion().has("error"): corner_refused = true; break
	check(corner_refused,"capture refuses an active partial stair-corner continuation")
	check(course.save_course() != "Practice saved." and FileAccess.get_file_as_bytes(isolated_slot) == pre_contact_bytes,"mid-contact save refusal retains previous slot bytes")
	course.set_paused(true)
	var paused_position: Vector3 = actor.global_position; var paused_velocity: Vector3 = actor.velocity; var paused_tick: int = course.tick
	await frames(70)
	check(actor.ground_contact_active() and actor.global_position == paused_position and actor.velocity == paused_velocity and course.tick == paused_tick,"pause freezes unfinished contact past its active-time deadline")
	release(); course.set_paused(false); await frames(20)
	check(not actor.ground_contact_active(),"zero input releases unfinished stair contact")
	check(not actor.capture_motion().has("error"),"capture resumes after bounded corner continuation completes")
	await fixture(course,Vector3(0,0.04,4.65)); Input.action_press("move_forward",0.6)
	var blocked_contact_found := false
	for _i in range(65):
		await frames(1)
		if actor.ground_contact_active(): blocked_contact_found = true; break
	check(blocked_contact_found,"late-contact obstruction fixture enters real native contact")
	course.set_paused(true)
	var contact_wall := collision_box(course,"late_contact_wall",actor.global_position+Vector3(0,1,-0.46),Vector3(3,2,0.2))
	await frames(2); course.set_paused(false); await frames(4); release()
	check(not actor.ground_contact_active(),"new physical obstruction releases active corner continuation")
	check(no_overlap(course),"new physical obstruction never clips active contact capsule")
	contact_wall.queue_free(); await frames(2)
	await fixture(course,Vector3(6,0.04,-3.25))
	Input.action_press("move_forward"); await frames(30); release()
	check(actor.global_position.y < -0.1 and not actor.is_on_floor(),"no destination support releases genuine falling motion")
	check(course.samples.filter(func(s): return s.event == "step_up").is_empty(),"unsupported gap never invents step-up")
	# Airborne contact at the stair is a physical setup fixture, not a played jump route.
	await fixture(course,Vector3(0,0.24,4.5),0)
	actor.velocity = Vector3(0,2,-3); actor._grounded = false
	await frames(1); var airborne_start: int = course.samples.size()
	Input.action_press("move_forward"); await frames(7); release()
	var airborne_samples: Array = course.samples.slice(airborne_start)
	check(airborne_samples.filter(func(s): return s.event == "step_up").is_empty(),"ascending airborne capsule cannot invoke grounded step")
	# A real body introduced after the prior clear observation must be seen next tick.
	await fixture(course,Vector3(0,0.04,4.7)); actor.set_physics_process(false)
	Input.action_press("move_forward"); await frames(1); release()
	var late := collision_box(course,"late_wall",Vector3(0,1,4.15),Vector3(3,2,0.2)); await frames(2)
	actor.set_physics_process(true); Input.action_press("move_forward"); await frames(30); release()
	check(actor.global_position.z >= 4.58 and actor.global_position.y < 0.02,"late real wall is checked at execution time")
	check(no_overlap(course),"late wall cannot produce swept capsule clipping")
	late.queue_free(); await frames(2)
	# Only StaticBody3D support without imposed velocity belongs to this profile.
	for mode in ["rigid","animatable","static_velocity"]:
		var support: PhysicsBody3D
		if mode == "rigid": support = RigidBody3D.new(); support.set("freeze",true)
		elif mode == "animatable": support = AnimatableBody3D.new()
		else: support = StaticBody3D.new(); support.set("constant_linear_velocity",Vector3(0.1,0,0))
		support.name = "dynamic_support_"+mode; support.position = Vector3(10,0.5,5)
		var shape := BoxShape3D.new(); shape.size = Vector3(3,0.4,3)
		var collider := CollisionShape3D.new(); collider.shape = shape; support.add_child(collider); course.add_child(support)
		var obstacle := collision_box(course,"dynamic_step_"+mode,Vector3(10,0.79,3.65),Vector3(3,0.18,0.3))
		await fixture(course,Vector3(10,0.74,5))
		Input.action_press("move_forward"); await frames(35); release()
		check(course.samples.filter(func(s): return s.event == "step_up").is_empty(),mode+" support refuses grounded static-step operation")
		check(no_overlap(course),mode+" refusal preserves capsule clearance")
		support.queue_free(); obstacle.queue_free(); await frames(2)
	# Steep slope must stay a wall under configured floor normal bounds.
	await fixture(course,Vector3(-6,0.04,-0.7))
	check(await walk_z(course,-3.5,200),"native 30 degree slope ascent")
	check(actor.global_position.y > 0.8 and actor.is_on_floor(),"walkable 30 degree slope provides real elevated floor")
	check(await walk_z(course,-0.7,200),"native 30 degree slope descent")
	near(actor.global_position.y,0,0.012,"30 degree slope descent returns authored floor")
	await fixture(course,Vector3(-10,0.04,-1.4))
	Input.action_press("move_forward"); await frames(35); release()
	check(actor.global_position.y < 0.15,"55 degree slope is outside 45 degree floor profile")
	check(no_overlap(course),"steep slope refusal does not clip")
	await dispose(course)

func save_fixtures() -> void:
	var course = await new_course(); var actor: CharacterBody3D = course.avatar
	course.set_paused(true)
	var original: Dictionary = course.snapshot(); check(course.validate(original).is_empty(),"normal settled snapshot admitted")
	check(original.motion.size() == 7,"original motion capture schema remains seven fields")
	check(course.save_path != "user://1792-world-v1.json","qualification slot isolated from campaign")
	for kind in ["schema","geometry","motor","source","future_tick","tick_nan","hz_bool","pause_type","position_nan","position_wall","velocity","grounded_type","timer","missing","extra"]:
		var bad := original.duplicate(true)
		match kind:
			"schema": bad.schema = "ground-contact-course-save.future"
			"geometry": bad.geometry_digest = "0".repeat(64)
			"motor": bad.motor_digest = "0".repeat(64)
			"source": bad.source_digest = "0".repeat(64)
			"future_tick": bad.tick = 10000001
			"tick_nan": bad.tick = NAN
			"hz_bool": bad.physics_hz = true
			"pause_type": bad.paused = 1
			"position_nan": bad.motion.position[0] = NAN
			"position_wall": bad.motion.position = [0,0,-8.15]
			"velocity": bad.motion.velocity = [8,0,0]
			"grounded_type": bad.motion.grounded = 1
			"timer": bad.motion.coyote = -0.01
			"missing": bad.erase("paused")
			"extra": bad.invented = true
		check(not course.restore(bad).is_empty(),"malformed snapshot refused: "+kind)
		check(course.snapshot() == original,"malformed refusal atomic: "+kind)
	check(course.save_course() == "Practice saved.","native practice slot write")
	var bytes := FileAccess.get_file_as_bytes(isolated_slot)
	var wall := collision_box(course,"changed_runtime_wall",Vector3(0,1,6),Vector3(1,2,0.2)); await frames(2)
	var mutated: Dictionary = course.snapshot()
	check(not course.restore(original).is_empty(),"runtime collider addition invalidates old geometry binding")
	check(course.snapshot() == mutated,"geometry refusal changes no world state")
	check(FileAccess.get_file_as_bytes(isolated_slot) == bytes,"geometry refusal keeps slot bytes")
	wall.queue_free(); await frames(2)
	check(course.restore(original).is_empty(),"identical runtime geometry restores admitted save")
	actor.walk_speed += 0.2
	var tune_before: Dictionary = course.snapshot()
	check(not course.load_course().begins_with("Practice restored"),"resolved tuning mismatch refuses file load")
	check(course.snapshot() == tune_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"tuning refusal preserves state and file bytes")
	actor.walk_speed -= 0.2
	check(course.load_course() == "Practice restored.","matching resolved tuning permits file load")
	var actor_shape: CapsuleShape3D = actor.get_node("CollisionShape3D").shape
	var actor_bias: float = actor_shape.custom_solver_bias
	actor_shape.custom_solver_bias = 0.2
	var actor_bias_before: Dictionary = observed_motion(actor)
	check(not course.restore(original).is_empty(),"actor contact solver bias mutation refuses prior tuning binding")
	check(observed_motion(actor) == actor_bias_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"actor bias refusal preserves native state and prior slot bytes")
	actor_shape.custom_solver_bias = actor_bias
	# Native registration can bypass scene children; never hash only the visible map.
	var authored: StaticBody3D = course.get_node("stair_01")
	var native_owner: int = authored.create_shape_owner(authored)
	var extra_shape := BoxShape3D.new(); extra_shape.size = Vector3(3,2,0.15)
	authored.shape_owner_add_shape(native_owner,extra_shape)
	authored.shape_owner_set_transform(native_owner,Transform3D(Basis.IDENTITY,Vector3(0,1.11,2.45)))
	var native_before: Dictionary = observed_motion(actor)
	check(course.snapshot().has("error") and not course.restore(original).is_empty(),"manually registered static geometry refuses save and restore")
	check(observed_motion(actor) == native_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"unrepresented static owner refusal preserves motion and slot bytes")
	authored.remove_shape_owner(native_owner)
	var authored_collider: CollisionShape3D = authored.get_node("CollisionShape3D")
	var authored_owner: int = authored.get_shape_owners()[0]
	authored.remove_shape_owner(authored_owner)
	var removed_before: Dictionary = observed_motion(actor)
	check(course.snapshot().has("error") and not course.restore(original).is_empty(),"removed native registration refuses authored-only geometry identity")
	check(observed_motion(actor) == removed_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"removed native owner refusal preserves state and slot bytes")
	var rebuilt_owner: int = authored.create_shape_owner(authored_collider)
	authored.shape_owner_add_shape(rebuilt_owner,authored_collider.shape)
	authored.shape_owner_set_transform(rebuilt_owner,authored_collider.transform)
	authored.shape_owner_set_disabled(rebuilt_owner,authored_collider.disabled)
	check(course.validate(original).is_empty(),"restored one-to-one native collider representation admits original geometry")
	var original_margin: float = authored_collider.shape.margin
	authored_collider.shape.margin = original_margin+0.01
	var margin_before: Dictionary = observed_motion(actor)
	check(course.geometry_digest() != original.geometry_digest and not course.restore(original).is_empty(),"resolved static shape margin changes geometry identity")
	check(observed_motion(actor) == margin_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"static shape margin refusal preserves state and slot bytes")
	authored_collider.shape.margin = original_margin
	var original_bias: float = authored_collider.shape.custom_solver_bias
	authored_collider.shape.custom_solver_bias = original_bias+0.1
	var bias_before: Dictionary = observed_motion(actor)
	check(course.geometry_digest() != original.geometry_digest and not course.restore(original).is_empty(),"resolved static solver bias changes geometry identity")
	check(observed_motion(actor) == bias_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"static solver bias refusal preserves state and slot bytes")
	authored_collider.shape.custom_solver_bias = original_bias
	actor.add_collision_exception_with(authored)
	var exception_before: Dictionary = observed_motion(actor)
	check(course.snapshot().has("error") and not course.restore(original).is_empty(),"unqualified actor collision exception refuses save and restore")
	check(not actor.step_motion(1.0/60,Vector2(0,-1),false).is_empty(),"actor exception refuses native motor admission")
	check(observed_motion(actor) == exception_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"actor exception refusal preserves state and slot bytes")
	actor.remove_collision_exception_with(authored)
	var actor_owner: int = actor.create_shape_owner(actor)
	actor.shape_owner_add_shape(actor_owner,extra_shape)
	var hull_before: Dictionary = observed_motion(actor)
	check(course.snapshot().has("error") and not course.restore(original).is_empty(),"manually registered actor hull refuses save and restore")
	check(not actor.step_motion(1.0/60,Vector2(0,-1),false).is_empty(),"unrepresented actor hull refuses native motor admission")
	check(observed_motion(actor) == hull_before and FileAccess.get_file_as_bytes(isolated_slot) == bytes,"extra actor hull refusal preserves state and slot bytes")
	actor.remove_shape_owner(actor_owner)
	for gap in [0.01,0.02,0.03,0.039]:
		var floating: Dictionary = original.motion.duplicate(true); floating.position[1] = gap
		check(not actor.motion_fits(floating).is_empty(),"floating claimed-grounded capsule refused at gap "+str(gap))
		check(actor.capture_motion() == original.motion,"floating grounded-fit refusal preserves native state")
	# Malformed enabled profiles refuse before touching integration state.
	var hull: CollisionShape3D = actor.get_node("CollisionShape3D")
	for kind in ["step_nan","step_inf","step_negative","step_overheight","snap_nan","snap_overheight","angle_zero","angle_nan","margin_large","up_wrong_axis","shape_disabled","nonuniform_body"]:
		var height: float = actor.step_height; var snap: float = actor.floor_snap_length
		var angle: float = actor.floor_max_angle; var margin: float = actor.safe_margin
		var up: Vector3 = actor.up_direction; var transform: Transform3D = actor.global_transform
		match kind:
			"step_nan": actor.step_height = NAN
			"step_inf": actor.step_height = INF
			"step_negative": actor.step_height = -0.01
			"step_overheight": actor.step_height = 0.31
			"snap_nan": actor.floor_snap_length = NAN
			"snap_overheight": actor.floor_snap_length = 0.31
			"angle_zero": actor.floor_max_angle = 0
			"angle_nan": actor.floor_max_angle = NAN
			"margin_large": actor.safe_margin = 0.1
			"up_wrong_axis": actor.up_direction = Vector3(1,0,0)
			"shape_disabled": hull.disabled = true
			"nonuniform_body": actor.scale = Vector3(1,1.1,1)
		var before: Dictionary = observed_motion(actor)
		check(not actor.step_motion(1.0/60,Vector2(0,-1),false).is_empty(),"malformed ground profile refused: "+kind)
		check(observed_motion(actor) == before,"malformed ground profile preserves motion: "+kind)
		actor.step_height = height; actor.floor_snap_length = snap; actor.floor_max_angle = angle
		actor.safe_margin = margin; actor.up_direction = up; actor.global_transform = transform; hull.disabled = false
	# Shape-aware restore must see a shifted local capsule rather than fixed body centre.
	var original_hull: Transform3D = hull.transform
	hull.position.x = 0.45
	var offset_wall := collision_box(course,"offset_hull_obstruction",Vector3(0.8,1,7),Vector3(0.1,2,0.8)); await frames(2)
	var offset_motion: Dictionary = actor.capture_motion()
	check(not actor.motion_fits(offset_motion).is_empty(),"offset actual capsule detects blocked restored destination")
	check(not actor.restore_motion(offset_motion).is_empty() and actor.capture_motion() == offset_motion,"offset-hull restore refusal atomic")
	offset_wall.queue_free(); hull.transform = original_hull; await frames(2)
	var narrow_support := collision_box(course,"offset_support_fixture",Vector3(10,0.5,0),Vector3(0.3,0.4,1))
	await fixture(course,Vector3(10,0.74,0)); course.set_paused(true)
	var supported_motion: Dictionary = actor.capture_motion()
	check(supported_motion.grounded,"offset support fixture begins on real native floor")
	hull.position.x = 0.85
	check(not actor.motion_fits(supported_motion).is_empty(),"shifted real hull refuses support located only under body origin")
	check(not actor.restore_motion(supported_motion).is_empty() and actor.capture_motion() == supported_motion,"missing shifted-hull support refusal atomic")
	hull.transform = original_hull; narrow_support.queue_free(); await frames(2)
	# Unrepresented collision types cannot generate superficially bound course saves.
	var unrepresented := StaticBody3D.new(); unrepresented.name = "unrepresented_hull"
	var cylinder := CylinderShape3D.new(); var collision := CollisionShape3D.new(); collision.shape = cylinder
	unrepresented.add_child(collision); course.add_child(unrepresented)
	check(course.snapshot().has("error") and not course.restore(original).is_empty(),"unsupported runtime shape refuses course save and load")
	unrepresented.queue_free(); await frames(2)
	# Snapshot replay invokes the original motion reducer once per real physics tick.
	await fixture(course,Vector3(0,0.04,4.65)); course.set_paused(true)
	var replay_start: Dictionary = course.snapshot(); actor.input_enabled = true; actor.set_physics_process(false); course.set_physics_process(false)
	var first: Array = []; var second: Array = []
	var first_error := false; var second_error := false
	for _i in range(50):
		await physics_frame
		first_error = first_error or not actor.step_motion(1.0/60.0,Vector2(0,-0.5),false).is_empty()
		first.append(observed_motion(actor))
	check(course.restore(replay_start).is_empty(),"original motion restore for identical stair replay")
	actor.input_enabled = true; actor.set_physics_process(false)
	for _i in range(50):
		await physics_frame
		second_error = second_error or not actor.step_motion(1.0/60.0,Vector2(0,-0.5),false).is_empty()
		second.append(observed_motion(actor))
	check(not first_error and not second_error,"both identical stair replay command streams admitted")
	# Native transform observations are float32; retained IDs, flags and ticks remain exact.
	check(first == second,"identical restored input stream reproduces complete native motion snapshots")
	# A blocked contact can retain commanded velocity; real travel remains zero.
	course.set_physics_process(true); await fixture(course,Vector3(6,0.04,4.8))
	Input.action_press("move_forward"); await frames(35); release(); course.set_paused(true)
	var proxy = actor.get_node("LocomotionProxy")
	var physical_before: Dictionary = observed_motion(actor); var proxy_phase: float = proxy.phase
	check(Vector2(actor.velocity.x,actor.velocity.z).length() > 1 and Vector2(actor.last_ground_displacement.x,actor.last_ground_displacement.z).length() < 0.00001,"wall presentation fixture retains drive while actual travel is zero")
	proxy._process(1.0/30)
	near(proxy.phase,proxy_phase,0.00001,"blocked drive cannot advance proxy walking phase")
	check(observed_motion(actor) == physical_before,"proxy sampling preserves native body, drive, timers and contacts")
	var blocked_start: Dictionary = course.snapshot(); var blocked_first: Array = []; var blocked_second: Array = []
	actor.input_enabled = true; actor.set_physics_process(false); course.set_physics_process(false)
	for _i in range(20):
		await physics_frame; actor.step_motion(1.0/60,Vector2(0,-0.5),false); blocked_first.append(observed_motion(actor))
	check(course.restore(blocked_start).is_empty(),"blocked-wall motion snapshot restores")
	actor.input_enabled = true; actor.set_physics_process(false)
	for _i in range(20):
		await physics_frame; actor.step_motion(1.0/60,Vector2(0,-0.5),false); blocked_second.append(observed_motion(actor))
	check(blocked_first == blocked_second,"blocked-wall save and identical-command replay reproduce physical state")
	check(M.point(blocked_second[-1].position).distance_to(M.point(blocked_start.motion.position)) < 0.002,"blocked-wall retained drive state never becomes fictitious travel")
	# The physics engine's last floor cache is not serialized. Restore must work from
	# both histories using the physically admitted saved contact, not that stale flag.
	course.set_physics_process(true); await fixture(course,Vector3(0,0.04,4.31),30); course.set_paused(true)
	actor.velocity = Vector3(0,0,-2.25)
	var toe: Dictionary = actor.capture_motion()
	check(not toe.has("error") and actor.motion_fits(toe).is_empty() and actor.is_on_floor(),"grounded toe snapshot begins with real floor history")
	actor.input_enabled = true; actor.set_physics_process(false); course.set_physics_process(false)
	var floor_history: Array = []; var air_history: Array = []
	for _i in range(12):
		await physics_frame; actor.step_motion(1.0/60,Vector2(0,-0.5),false); floor_history.append(observed_motion(actor))
	actor.clear_ground_contact(); actor.global_position = Vector3(0,3,4.31); actor.velocity = Vector3.ZERO
	actor._grounded = false; actor._coyote = 0; actor._buffer = 0
	await physics_frame; actor.step_motion(1.0/60,Vector2.ZERO,false)
	check(not actor.is_on_floor(),"second restore history has actual native floor cache false")
	check(actor.restore_motion(toe).is_empty(),"grounded toe restore admitted from native airborne history")
	for _i in range(12):
		await physics_frame; actor.step_motion(1.0/60,Vector2(0,-0.5),false); air_history.append(observed_motion(actor))
	check(floor_history == air_history,"grounded save replay independent of previous native floor cache")
	await fixture(course,Vector3(0,0.04,7),30); course.set_paused(true)
	var airborne: Dictionary = actor.capture_motion(); airborne.position = [0,0.03,7]
	airborne.velocity = [0,0,0]; airborne.grounded = false; airborne.coyote = 0; airborne.buffer = 0
	check(actor.is_on_floor() and actor.restore_motion(airborne).is_empty(),"airborne snapshot admitted from actual floor history")
	actor.input_enabled = true; actor.set_physics_process(false); course.set_physics_process(false)
	var from_floor: Array = []; var from_air: Array = []
	for _i in range(4):
		await physics_frame; actor.step_motion(1.0/60,Vector2.ZERO,false); from_floor.append(observed_motion(actor))
	actor.clear_ground_contact(); actor.global_position = Vector3(0,3,7); actor.velocity = Vector3.ZERO
	actor._grounded = false; actor._coyote = 0; actor._buffer = 0
	await physics_frame; actor.step_motion(1.0/60,Vector2.ZERO,false)
	check(not actor.is_on_floor() and actor.restore_motion(airborne).is_empty(),"same airborne snapshot admitted from actual air history")
	for _i in range(4):
		await physics_frame; actor.step_motion(1.0/60,Vector2.ZERO,false); from_air.append(observed_motion(actor))
	check(from_floor == from_air,"airborne replay independent of previous native floor cache")
	var qualified_geometry: String = course.geometry_digest(); var qualified_motor: String = course.motor_digest()
	var qualified_source: String = course.source_digest()
	await dispose(course)
	var packed: Node3D = preload("res://mechanics/ground_course.tscn").instantiate(); packed.save_path = isolated_slot
	root.add_child(packed); await frames(12); packed.set_paused(true)
	check(packed.geometry_digest() == qualified_geometry,"fresh packed scene reproduces exact authored collision digest")
	check(packed.motor_digest() == qualified_motor and packed.source_digest() == qualified_source,"fresh packed scene reproduces resolved tuning and source binding")
	await dispose(packed)

func run() -> void:
	check(Engine.physics_ticks_per_second == 60,"native runtime physics clock is 60Hz")
	await spatial_control_fixtures()
	await played_journey()
	await quarter_speed_journey()
	await fine_control_fixtures()
	await physical_fixtures()
	await save_fixtures()
	release()
	print("GROUND_CONTACT_METRICS: ",JSON.stringify(summary))
	print("GROUND_CONTACT_TESTS: ",passed," passed, ",failed," failed")
	quit(0 if failed == 0 else 1)
