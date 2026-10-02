extends SceneTree

const Houses := preload("res://campaign/house_command_state.gd")
const Legacy := preload("res://campaign/command_state.gd")
const Rules := preload("res://mounts/riding_rules.gd")
const Scene := preload("res://world/house_sandbox.tscn")
const SAVE := "user://riding-regression.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func ok(error: String, message: String) -> void:
	check(error.is_empty(), message + ": " + error)

func reject(model, operation: Callable, message: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(operation.call()).is_empty(), message + " refused")
	check(model.snapshot() == before, message + " leaves state unchanged")

func fresh():
	var model = Houses.new()
	model.enable_riding()
	return model

func mount(model) -> void:
	model.record_position(Rules.position(model.horse_state()) + Vector3.RIGHT * 1.8)
	ok(model.mount_horse(), "mount active character")

func _run() -> void:
	_test_rules()
	_test_saves()
	_test_commission()
	await _test_physics()
	await _test_geometry()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("RIDING_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_rules() -> void:
	var model = fresh()
	ok(model.validate(model.snapshot()), "initial extended world valid")
	var before: Dictionary = model.snapshot()
	model.enable_riding()
	check(model.snapshot() == before, "enabling twice does not recreate horse")
	var read: Dictionary = model.horse_state()
	read.position[0] = 20.0
	check(model.horse_state().position[0] == 8.0, "horse read cannot mutate authority")
	reject(model, model.mount_horse, "distant mount")
	reject(model, model.dismount_horse.bind(Vector3.ZERO), "unmounted dismount")
	mount(model)
	check(model.is_mounted() and model.horse_state().rider_id == "ranjit_singh", "Ranjit rides shared household horse")
	check(model.snapshot().resources == before.resources, "mounting grants no riders or resources")
	reject(model, model.mount_horse, "duplicate mount")
	reject(model, model.petition.bind("begin"), "mounted court negotiation")
	reject(model, model.play_commander, "mounted handover")
	var mounted: Dictionary = model.snapshot()
	model.record_position(Vector3(50, 0.2, 20))
	check(model.snapshot() == mounted, "walking projection cannot overwrite mounted position")
	var motion := {"position": [8.0, 0.04, -5.5], "yaw": 0.0, "speed": 5.0, "vertical_speed": 0.0, "grounded": true}
	ok(model.record_ride(motion, 0.1), "bounded mounted motion accepted")
	check(model.actor_position("ranjit_singh") == Vector3(8, 0.04, -5.5), "motion updates actor and horse together")
	reject(model, model.dismount_horse.bind(Vector3(9.8, 0.04, -5.5)), "moving dismount")
	for delta in [0.0, -0.1, 1.0, NAN]:
		reject(model, model.record_ride.bind(motion, delta), "invalid physics delta")
	var invalid: Dictionary = motion.duplicate(true)
	invalid.position = [50.0, 0.04, 10.0]
	reject(model, model.record_ride.bind(invalid, 0.1), "teleporting motion")
	invalid = motion.duplicate(true)
	invalid.speed = true
	reject(model, model.record_ride.bind(invalid, 0.1), "boolean speed")
	invalid = motion.duplicate(true)
	invalid.yaw = NAN
	reject(model, model.record_ride.bind(invalid, 0.1), "nonfinite yaw")
	motion.speed = 0.0
	ok(model.record_ride(motion, 0.1), "stop horse")
	reject(model, model.dismount_horse.bind(Vector3(35, 0.04, -5.5)), "distant dismount")
	reject(model, model.dismount_horse.bind(Vector3(9.8,2.05,-5.5)),"dismount above bounded slope envelope")
	reject(model, model.dismount_horse.bind(Vector3(NAN, 0, 0)), "nonfinite dismount")
	ok(model.dismount_horse(Vector3(9.8, 0.04, -5.5)), "stopped adjacent dismount")
	check(not model.is_mounted(), "dismount releases mounted executor")
	check(model.horse_state().position == [8.0, 0.04, -5.5], "horse does not follow player on dismount")
	ok(model.validate(model.snapshot()), "dismounted world valid")

func _test_saves() -> void:
	var model = fresh()
	mount(model)
	var motion := {"position": [8.0, 0.04, -5.4], "yaw": 0.25, "speed": 4.0, "vertical_speed": 0.0, "grounded": true}
	ok(model.record_ride(motion, 0.1), "moving save setup")
	ok(model.save_to(SAVE), "save mounted world")
	var loaded = fresh()
	ok(loaded.load_from(SAVE), "load mounted world")
	check(model.snapshot() == loaded.snapshot(), "whole mounted snapshot roundtrip")
	motion.position[2] = -5.8
	ok(model.record_ride(motion, 0.1), "original continuation")
	ok(loaded.record_ride(motion, 0.1), "loaded continuation")
	check(model.snapshot() == loaded.snapshot(), "same submitted motion produces same continuation")
	for key in ["id", "rider_id", "position", "yaw", "speed", "vertical_speed", "grounded"]:
		var bad: Dictionary = model.snapshot()
		bad.riding.horse.erase(key)
		reject(model, model.restore.bind(bad), "missing " + key)
	for value in [null, [], "invalid", {"schema_version": "riding.v99", "horse": {}}]:
		var bad: Dictionary = model.snapshot()
		bad.riding = value
		reject(model, model.restore.bind(bad), "invalid riding record")
	for pair in [["speed", -1], ["speed", 12], ["speed", true], ["yaw", INF], ["yaw", 4.0], ["grounded", 1], ["vertical_speed", 2.0], ["id", "horse_copy"], ["rider_id", "sada_kaur"], ["rider_id", "patrol_captain"], ["position", [0, 1]], ["position", [true, 0, 0]], ["position", [8, 0, -100]]]:
		var bad: Dictionary = model.snapshot()
		bad.riding.horse[pair[0]] = pair[1]
		reject(model, model.restore.bind(bad), "invalid horse " + pair[0])
	var bad: Dictionary = model.snapshot()
	bad.riding.horse.rider_id = ""
	reject(model, model.restore.bind(bad), "moving horse without rider")
	bad = model.snapshot()
	bad.riding.horse.position[0] += 1.0
	reject(model, model.restore.bind(bad), "rider horse pose mismatch")
	var legacy = Legacy.new()
	ok(loaded.restore(legacy.snapshot()), "original command save migration")
	check(not loaded.is_mounted() and loaded.horse_state() == Rules.initial().horse, "legacy import adds only parked horse")
	var preserved: Dictionary = loaded.snapshot()
	preserved.erase("riding")
	preserved.erase("house_conflict")
	check(preserved == legacy.snapshot(), "legacy campaign fields unchanged")
	var old_houses = Houses.new()
	old_houses.record_position(Vector3(0, 0.2, 3))
	ok(old_houses.petition("begin"), "legacy petition setup")
	ok(old_houses.petition("assert_authority"), "legacy rivalry setup")
	ok(loaded.restore(old_houses.snapshot()), "house-only save migration")
	check(loaded.house_state() == old_houses.house_state(), "riding import preserves political decision history")
	ok(loaded.save_to(SAVE), "replace earlier mounted save")
	ok(model.load_from(SAVE), "load unmounted replacement")
	check(not model.is_mounted(), "load releases prior mounted state")

func _test_commission() -> void:
	var model = fresh()
	model.record_position(Vector3(0, 0.2, 3))
	ok(model.petition("begin"), "hear house petition")
	ok(model.petition("defer"), "observation-only commission")
	ok(model.issue("patrol"), "allocate patrol once")
	ok(model.play_commander(), "captain keeps existing identity")
	mount(model)
	reject(model, model.return_to_darbar, "mounted captain cannot double-execute via delegation")
	reject(model, model.visit.bind("village"), "mounted observation")
	reject(model, model.resolve.bind("withdraw"), "mounted report handover")
	var parked: Dictionary = model.horse_state()
	ok(model.dismount_horse(Rules.position(parked) + Vector3.RIGHT * 1.8), "captain dismounts")
	ok(model.return_to_darbar(), "delegate on foot after dismount")
	model.advance(100)
	check(model.snapshot().order.status == "active", "horse does not bypass observation-only commission")
	check(model.horse_state().position == parked.position, "delegated captain leaves horse parked")
	ok(model.petition("reconcile"), "Ranjit revises commission")
	model.advance(4)
	check(model.received_house_report().is_empty(), "report remains delayed")
	model.advance(1)
	check(model.received_house_report().territory.passage == "permitted", "existing political outcome delivered")
	check(model.snapshot().resources.riders == 6, "riders released only once")
	check(model.horse_state().position == parked.position, "report arrival cannot teleport horse")
	ok(model.validate(model.snapshot()), "completed mounted-capable campaign valid")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func inputs(throttle: bool, steering: float = 0.0, fast: bool = false) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)
	if throttle:
		Input.action_press("move_forward")
	if steering < -0.04:
		Input.action_press("move_left", minf(absf(steering), 1.0))
	elif steering > 0.04:
		Input.action_press("move_right", minf(steering, 1.0))
	if fast:
		Input.action_press("sprint")

func press_mount(scene) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F
	event.pressed = true
	scene._unhandled_input(event)
	await frames(2)

func drive_to(scene, target: Vector3, budget: int = 800) -> void:
	# Test driver presses the same gameplay actions. No position injection in the journey.
	var reached := false
	for _i in range(budget):
		var d: Vector3 = target - scene.horse.position
		d.y = 0.0
		if d.length() < 1.2 and scene.horse.speed < 0.3:
			reached = true
			break
		var wanted := atan2(-d.x, -d.z)
		var error := wrapf(wanted - scene.horse.rotation.y, -PI, PI)
		var stopping: float = scene.horse.speed * scene.horse.speed / 18.0 + 0.7
		inputs(absf(error) < 0.4 and d.length() > stopping, -error * 3.0)
		await physics_frame
	inputs(false)
	await frames(10)
	check(reached, "physics-driven ride reaches " + str(target) + " from " + str(scene.horse.position) + " notice=" + scene._notice)

func _test_physics() -> void:
	var scene = Scene.instantiate()
	scene.riding_save_path = SAVE + ".scene"
	check(scene.riding_save_path != scene.RIDING_SAVE, "scene tests never write the player save slot")
	root.add_child(scene)
	await frames(5)
	# Only setup fixtures reposition the avatar. The round trip below uses engine input.
	scene.avatar.position = scene.horse.position + Vector3.RIGHT * -1.8
	scene.avatar.velocity = Vector3.ZERO
	await frames(2)
	await press_mount(scene)
	check(scene.campaign.is_mounted(), "F mounts through visible scene")
	check(not scene.avatar.is_physics_processing() and scene.avatar.collision_layer == 0, "mounted walking controller/collider disabled")
	check(scene.horse.get_node("Hull") != null, "horse has physical collision hull")
	inputs(true, 0, true)
	await frames(20)
	var moving: Dictionary = scene.campaign.snapshot()
	check(scene.horse.position.z < -5.1 and scene.horse.speed > 0.5, "W moves horse through actual physics")
	await press_mount(scene)
	check(scene.campaign.is_mounted(), "F cannot dismount at speed")
	scene._open_houses()
	var paused: Dictionary = scene.campaign.snapshot()
	var paused_position: Vector3 = scene.horse.position
	await frames(10)
	check(scene.campaign.snapshot() == paused and scene.horse.position == paused_position, "modal pauses horse and campaign together")
	scene._close_panel()
	inputs(false)
	await frames(40)
	check(scene.horse.speed < 0.1, "release brakes to a stop")
	scene._perform("save")
	var saved: Dictionary = scene.campaign.snapshot()
	inputs(true)
	await frames(25)
	inputs(false)
	scene._perform("load")
	await frames(1)
	check(scene.campaign.is_mounted(), "F9 restores mounted mode")
	check(scene.horse.position.distance_to(Rules.position(saved.riding.horse)) < 0.1, "F9 restores persistent horse pose")
	check(not scene.avatar.is_physics_processing(), "load does not enable duplicate walking executor")
	await drive_to(scene, Vector3(0, 0, -10))
	await drive_to(scene, Vector3(-12, 0, -28))
	await drive_to(scene, Vector3(20, 0, -58))
	await press_mount(scene)
	check(not scene.campaign.is_mounted(), "F dismounts on clear ground")
	check(scene.avatar.is_physics_processing() and scene.avatar.collision_layer == 1, "walking control/collision restored")
	var left_at_outpost: Vector3 = scene.horse.position
	await frames(6)
	check(scene.horse.position == left_at_outpost, "unridden horse stays parked")
	await press_mount(scene)
	check(scene.campaign.is_mounted(), "same persistent horse remounts")
	await drive_to(scene, Vector3(-12, 0, -28))
	await drive_to(scene, Vector3(0, 0, -10))
	await drive_to(scene, Vector3(7, 0, -5))
	await press_mount(scene)
	check(not scene.campaign.is_mounted(), "physical round trip ends dismounted at home")
	ok(scene.campaign.validate(scene.campaign.snapshot()), "round-trip campaign remains valid")
	# An invalid file must not replace either simulation or presentation.
	var file := FileAccess.open(scene.riding_save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var before: Dictionary = scene.campaign.snapshot()
	var location: Vector3 = scene.horse.position
	scene._perform("load")
	await frames(1)
	check(scene.horse.position == location, "malformed load keeps visible horse")
	check(scene.campaign.horse_state() == before.riding.horse, "malformed load keeps authoritative horse")
	check(scene._notice.contains("Malformed"), "failed load gives visible reason")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.riding_save_path))
	inputs(false)
	scene.queue_free()
	await process_frame

func put_horse(scene, at: Vector3, mounted: bool = true, grounded: bool = true, yaw: float = 0.0) -> void:
	# Explicit spatial-test fixture, separate from the input-driven route test.
	var model = fresh()
	model.record_position(at)
	var state: Dictionary = model.snapshot()
	state.riding.horse.position = [at.x, at.y, at.z]
	state.riding.horse.yaw = yaw
	state.riding.horse.rider_id = "ranjit_singh" if mounted else ""
	state.riding.horse.grounded = grounded
	ok(scene.campaign.restore(state), "install geometry fixture")
	scene._apply_actor(true)

func slope_hit(scene,p: Vector3) -> Dictionary:
	var exclusions: Array[RID]=[scene.horse.get_rid(),scene.avatar.get_rid()]
	var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*12,p-Vector3.UP*12,1,exclusions)
	return scene.get_world_3d().direct_space_state.intersect_ray(ray)

func mounted_trace(scene,ticks: int) -> Dictionary:
	var start:Vector3=scene.horse.global_position;var prior:=start
	var air_ticks:=0;var longest_air:=0;var current_air:=0
	var maximum_horizontal:=0.0;var maximum_vertical:=0.0
	inputs(true)
	for _i in range(ticks):
		await physics_frame
		var delta:Vector3=scene.horse.global_position-prior
		maximum_horizontal=maxf(maximum_horizontal,Vector2(delta.x,delta.z).length())
		maximum_vertical=maxf(maximum_vertical,absf(delta.y))
		if scene.horse.is_on_floor(): current_air=0
		else:
			air_ticks+=1;current_air+=1;longest_air=maxi(longest_air,current_air)
		prior=scene.horse.global_position
	inputs(false)
	return {"start":start,"end":scene.horse.global_position,"air_ticks":air_ticks,
		"longest_air":longest_air,"maximum_horizontal_per_tick":maximum_horizontal,
		"maximum_vertical_per_tick":maximum_vertical,"grounded":scene.horse.is_on_floor()}

func mounted_trace_record(result: Dictionary) -> Dictionary:
	var start:Vector3=result.start;var end:Vector3=result.end
	return {"start":[start.x,start.y,start.z],"end":[end.x,end.y,end.z],
		"air_ticks":result.air_ticks,"longest_air":result.longest_air,
		"maximum_horizontal_per_tick":result.maximum_horizontal_per_tick,
		"maximum_vertical_per_tick":result.maximum_vertical_per_tick,"grounded":result.grounded}

func _test_compound_geometry(scene) -> void:
	# Two static 15-degree faces meet at each seam. These are measurements of
	# the existing body, not a globally enabled terrain profile.
	var crest:Array[Node3D]=[
		scene._box(Vector3(8,0.3,10),Vector3(52,1.267,5),Color.GRAY,true),
		scene._box(Vector3(8,0.3,10),Vector3(52,1.267,15),Color.GRAY,true)]
	crest[0].rotation.x=deg_to_rad(-15.0);crest[1].rotation.x=deg_to_rad(15.0)
	await frames(4)
	var start_hit:Dictionary=slope_hit(scene,Vector3(52,5,1))
	put_horse(scene,start_hit.position+Vector3.UP*0.2,true,true,PI)
	inputs(false);await frames(12)
	var crest_result:Dictionary=await mounted_trace(scene,230)
	check(crest_result.end.z>20.4 and crest_result.air_ticks==0 and crest_result.grounded,"mounted input crosses the convex crest without losing native support")
	check(crest_result.maximum_horizontal_per_tick<=6.5/60.0+0.003,"convex crest stays within the inherited trot budget")
	for body in crest: body.queue_free()
	await frames(3)
	var trough:Array[Node3D]=[
		scene._box(Vector3(8,0.3,10),Vector3(52,1.267,5),Color.GRAY,true),
		scene._box(Vector3(8,0.3,10),Vector3(52,1.267,15),Color.GRAY,true)]
	trough[0].rotation.x=deg_to_rad(15.0);trough[1].rotation.x=deg_to_rad(-15.0)
	await frames(4);start_hit=slope_hit(scene,Vector3(52,5,1))
	put_horse(scene,start_hit.position+Vector3.UP*0.2,true,true,PI)
	inputs(false);await frames(12)
	var trough_result:Dictionary=await mounted_trace(scene,220)
	check(trough_result.end.z>19.3 and trough_result.grounded,"mounted input crosses the seam and both faces of the concave trough")
	check(trough_result.air_ticks<=3 and trough_result.longest_air<=3 and trough_result.maximum_vertical_per_tick<0.07,"sharp trough transition remains a bounded native contact change")
	check(trough_result.maximum_horizontal_per_tick<=6.5/60.0+0.003,"concave trough stays within the inherited trot budget")
	for body in trough: body.queue_free()
	await frames(3)
	var platform:Node3D=scene._box(Vector3(8,0.4,10),Vector3(52,2,5),Color.GRAY,true)
	await frames(4);start_hit=slope_hit(scene,Vector3(52,6,2))
	put_horse(scene,start_hit.position+Vector3.UP*0.04,true,true,PI)
	inputs(false);await frames(12)
	var drop_result:Dictionary=await mounted_trace(scene,160)
	check(drop_result.air_ticks>=20 and drop_result.longest_air==drop_result.air_ticks,"unsupported drop edge detaches into one real gravity interval")
	check(drop_result.end.z>14.5 and drop_result.end.y<0.02 and drop_result.grounded,"mounted body lands on the native lower floor after the drop")
	check(drop_result.maximum_horizontal_per_tick<=6.5/60.0+0.003 and drop_result.maximum_vertical_per_tick<0.16,"drop travel remains within horizontal and gravity bounds")
	print("RIDING_COMPOUND_METRICS: ",JSON.stringify({"crest":mounted_trace_record(crest_result),
		"trough":mounted_trace_record(trough_result),"drop":mounted_trace_record(drop_result)}))
	put_horse(scene,Vector3(30,0.04,0),true,true)
	platform.queue_free();await frames(3)

func _test_slope_geometry(scene) -> void:
	# Deliberate native fixture only: this does not enable uneven terrain globally.
	var ramp:Node3D=scene._box(Vector3(8,0.3,16),Vector3(45,5.2,-20),Color.GRAY,true)
	ramp.rotation.x=deg_to_rad(-30.0)
	await frames(4)
	var low:Dictionary=slope_hit(scene,Vector3(45,8,-22.5))
	var middle:Dictionary=slope_hit(scene,Vector3(45,8,-20))
	check(not low.is_empty() and not middle.is_empty() and middle.normal.y>=cos(deg_to_rad(40.0)),"authored horse slope has admitted native support")
	put_horse(scene,low.position+Vector3.UP*0.16,true,true,PI)
	inputs(false);await frames(12)
	var start:Vector3=scene.horse.global_position;var prior:=start
	var air_ticks:=0;var maximum_horizontal:=0.0
	inputs(true)
	for _i in range(50):
		await physics_frame
		air_ticks+=int(not scene.horse.is_on_floor())
		maximum_horizontal=maxf(maximum_horizontal,Vector2(scene.horse.global_position.x-prior.x,scene.horse.global_position.z-prior.z).length())
		prior=scene.horse.global_position
	inputs(false)
	var powered_end:Vector3=scene.horse.global_position
	for _i in range(50): await physics_frame
	var stopped:Vector3=scene.horse.global_position
	var uphill_air_ticks:=air_ticks;var uphill_maximum:=maximum_horizontal
	var uphill_stop_distance:=stopped.distance_to(powered_end)
	check(air_ticks==0 and scene.horse.is_on_floor(),"mounted uphill travel and braking retain native slope support")
	check(powered_end.z>start.z+0.8 and powered_end.y>start.y+0.4,"mounted input produces real uphill displacement")
	check(maximum_horizontal<=6.5/60.0+0.003,"mounted slope travel stays within the trot command budget")
	check(stopped.distance_to(powered_end)<1.1 and scene.horse.speed<0.1,"mounted slope release brakes to a bounded stop")
	put_horse(scene,middle.position+Vector3.UP*0.16,true,true,PI)
	inputs(false);await frames(12)
	start=scene.horse.global_position;air_ticks=0;maximum_horizontal=0.0;prior=start
	inputs(true,0.55)
	for _i in range(45):
		await physics_frame
		air_ticks+=int(not scene.horse.is_on_floor())
		maximum_horizontal=maxf(maximum_horizontal,Vector2(scene.horse.global_position.x-prior.x,scene.horse.global_position.z-prior.z).length())
		prior=scene.horse.global_position
	inputs(false);await frames(45)
	var turn_end:Vector3=scene.horse.global_position;var turn_air_ticks:=air_ticks;var turn_maximum:=maximum_horizontal
	check(air_ticks==0 and scene.horse.is_on_floor(),"mounted turn remains supported on the real slope")
	check(absf(scene.horse.global_position.x-start.x)>0.15 and scene.horse.global_position.z>start.z+0.4,"mounted steering changes direction while climbing")
	check(maximum_horizontal<=6.5/60.0+0.003 and scene.horse.speed<0.1,"slope turn and stop respect the inherited travel budget")
	put_horse(scene,middle.position+Vector3.UP*0.16,true,true,0.0)
	inputs(false);await frames(12)
	var open_landing=scene.horse.dismount_position(scene.avatar)
	check(open_landing!=null and absf(open_landing.x-45.0)>1.5,"actual actor hull finds a clear contour-side slope landing")
	var walls:Array[Node3D]=[
		scene._box(Vector3(0.25,5,4),Vector3(43.75,5.2,-20),Color.GRAY,true),
		scene._box(Vector3(0.25,5,4),Vector3(46.25,5.2,-20),Color.GRAY,true)]
	await frames(3)
	var longitudinal_landing=scene.horse.dismount_position(scene.avatar)
	check(longitudinal_landing!=null and absf(longitudinal_landing.x-45.0)<0.2 and absf(longitudinal_landing.z+20.0)>1.5,"blocked sides use a vertically bounded uphill/downhill dismount exit")
	put_horse(scene,middle.position+Vector3.UP*0.16,true,true,PI)
	inputs(false);await frames(12)
	var downhill_landing=scene.horse.dismount_position(scene.avatar)
	check(downhill_landing!=null and downhill_landing.z<-21.5 and downhill_landing.y<middle.position.y,"reversed horse heading finds the bounded downhill dismount exit")
	await press_mount(scene)
	check(not scene.campaign.is_mounted(),"actual F transition dismounts onto admitted sloped support / "+scene._notice+" / "+str(scene.campaign.horse_state()))
	await frames(12)
	check(scene.avatar.is_on_floor(),"dismounted actor settles on native sloped support")
	for wall in walls: wall.queue_free()
	await frames(3)
	await press_mount(scene)
	check(scene.campaign.is_mounted(),"actual actor hull remounts across the clear slope path / "+scene._notice+" / "+str(scene.avatar.global_position))
	check(scene.horse.record_fits_world(scene.campaign.horse_state(),scene.avatar),"mounted slope pose passes native collision and support persistence checks")
	var saved_slope:Dictionary=scene.campaign.snapshot();scene._perform("save")
	scene.horse.global_position+=Vector3.RIGHT*3.0
	scene._perform("load");await frames(2)
	check(scene._notice=="Loaded. Horse, rider, patrol and house decisions restored." and scene.campaign.is_mounted(),"source authority reloads the mounted slope record")
	check(scene.horse.global_position.distance_to(Rules.position(saved_slope.riding.horse))<0.1,"slope reload restores the retained physical horse pose")
	print("RIDING_SLOPE_METRICS: ",JSON.stringify({"angle_degrees":30,"uphill_air_ticks":uphill_air_ticks,
		"uphill_maximum_horizontal_per_tick":uphill_maximum,"uphill_stop_distance":uphill_stop_distance,
		"turn_air_ticks":turn_air_ticks,"turn_maximum_horizontal_per_tick":turn_maximum,"turn_end":[turn_end.x,turn_end.y,turn_end.z],
		"open_landing":[open_landing.x,open_landing.y,open_landing.z],
		"uphill_landing":[longitudinal_landing.x,longitudinal_landing.y,longitudinal_landing.z],
		"downhill_landing":[downhill_landing.x,downhill_landing.y,downhill_landing.z]}))
	put_horse(scene,Vector3(30,0.04,0),true,true)
	ramp.queue_free();await frames(3)

func _test_geometry() -> void:
	var scene = Scene.instantiate()
	scene.riding_save_path = SAVE + ".scene"
	check(scene.riding_save_path != scene.RIDING_SAVE, "scene tests never write the player save slot")
	root.add_child(scene)
	await frames(3)
	put_horse(scene, Vector3(30, 0.04, 0))
	var wall: Node3D = scene._box(Vector3(8, 3, 0.3), Vector3(30, 1.5, -4), Color.GRAY, true)
	await frames(3)
	inputs(true, 0, true)
	await frames(110)
	inputs(false)
	check(scene.horse.position.z > -3.3 and scene.horse.position.z < -2.7, "horse stops in front of a solid wall")
	check(scene.horse.speed < 0.1, "wall collision stores actual stopped speed")
	ok(scene.campaign.validate(scene.campaign.snapshot()), "collision result remains valid")
	wall.queue_free()
	await frames(2)
	put_horse(scene, Vector3(30, 0.04, 0))
	var ring: Array[Node3D] = []
	for x in [-1.5, 1.5]:
		ring.append(scene._box(Vector3(0.25, 3, 4), Vector3(30 + x, 1.5, 0), Color.GRAY, true))
	for z in [-1.5, 1.5]:
		ring.append(scene._box(Vector3(4, 3, 0.25), Vector3(30, 1.5, z), Color.GRAY, true))
	await frames(3)
	check(scene.horse.dismount_position(scene.avatar) == null, "capsule sweep rejects all exits through a thin wall")
	await press_mount(scene)
	check(scene.campaign.is_mounted() and scene._notice.contains("No clear"), "blocked dismount keeps rider mounted and explains why")
	ring[1].queue_free()
	await frames(3)
	var avatar_hull: CollisionShape3D=scene.avatar.get_node("CollisionShape3D")
	var original_hull_transform:=avatar_hull.transform
	avatar_hull.position.y+=1.0
	var offset_blocker: Node3D=scene._box(Vector3(8,0.2,8),Vector3(30,2.1,0),Color.GRAY,true)
	await frames(3)
	var offset_landing=scene.horse.dismount_position(scene.avatar)
	check(offset_landing==null,"dismount clearance uses the actor's actual local hull transform / "+str(offset_landing))
	avatar_hull.transform=original_hull_transform;offset_blocker.queue_free()
	await frames(3)
	await press_mount(scene)
	check(not scene.campaign.is_mounted(), "one clear exit permits safe dismount")
	var barrier: Node3D = scene._box(Vector3(0.1,0.5,3),Vector3(30.95,0.25,0),Color.GRAY,true)
	await frames(3)
	await press_mount(scene)
	check(not scene.campaign.is_mounted() and scene._notice.contains("wall"), "actual avatar hull cannot mount through a low wall missed by an eye ray")
	barrier.queue_free()
	for i in [0, 2, 3]:
		ring[i].queue_free()
	await frames(3)
	put_horse(scene, Vector3(30, 2, 0), true, false)
	await press_mount(scene)
	check(scene.campaign.is_mounted(), "airborne dismount refused")
	await frames(60)
	check(scene.campaign.horse_state().grounded and scene.horse.position.y < 0.1, "gravity lands mounted horse on floor")
	await _test_slope_geometry(scene)
	await _test_compound_geometry(scene)
	# Valid JSON/domain state but impossible world placement: must refuse before commit.
	var bad: Dictionary = scene.campaign.snapshot()
	bad.riding.horse.position = [0.0, 0.04, 0.0] # Existing command table, not free ground.
	bad.player.position = bad.riding.horse.position.duplicate()
	bad.actors.ranjit_singh.position = bad.player.position.duplicate()
	ok(scene.campaign.validate(bad), "spatially impossible fixture is structurally well formed")
	var file := FileAccess.open(scene.riding_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(bad, "", true, true))
	file.close()
	var original: Dictionary = scene.campaign.horse_state()
	scene._perform("load")
	await frames(1)
	check(scene.campaign.horse_state() == original, "intersecting loaded horse never replaces live state")
	check(scene._notice.contains("intersects scenery"), "spatial load refusal is visible")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.riding_save_path))
	inputs(false)
	scene.queue_free()
	await process_frame
