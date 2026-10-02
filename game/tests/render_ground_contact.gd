# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Draw retained native movement evidence without executing another movement attempt.
## The actual practice authority restores the actor, geometry and motor revision.
const CourseScene := preload("res://mechanics/ground_course.tscn")
const Motion := preload("res://player/locomotion_rules.gd")
const Ground := preload("res://player/ground_contact.gd")
const EVIDENCE := "ground-contact-journey.json"
const PIXELS := "ground-contact-journey.png"
const MAX_EVIDENCE_BYTES := 2097152
var passed := 0
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> bool:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("GROUND CONTACT RENDER FAIL: " + label)
	return value

func finish(course: Node3D = null) -> void:
	if course != null:
		course.queue_free()
	print("GROUND_CONTACT_RENDER: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func fields(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

func hex_identity(value: Variant, width: int) -> bool:
	if not value is String or value.length() != width: return false
	for letter in value:
		if not letter in "0123456789abcdef": return false
	return true

func decoded_numbers(value: Variant) -> Variant:
	# Godot's JSON transport decodes all numbers as doubles. Normalize only that
	# numeric representation; the retained values receive no epsilon or rounding.
	if typeof(value) == TYPE_INT: return float(value)
	if value is Array:
		var result: Array = []
		for item in value: result.append(decoded_numbers(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = decoded_numbers(value[key])
		return result
	return value

func canonical(value: Variant) -> String:
	return JSON.stringify(decoded_numbers(value), "", true, true)

func transported_snapshot(course: Node3D) -> Dictionary:
	var value: Dictionary = course.snapshot()
	# These three arrays originate in native float32 vectors. Reproduce the
	# capture's JSON decoding exactly, because Godot's decimal parser can differ
	# by one double ULP from the original float32 value. No tolerance is admitted.
	for key in ["position", "velocity", "camera"]:
		value.motion[key] = JSON.parse_string(JSON.stringify(value.motion[key], "", true, true))
	return value

func trace_error(journey: Variant, snapshot: Dictionary) -> String:
	if not fields(journey, ["trace", "summary"]): return "Malformed journey."
	if not journey.trace is Array or journey.trace.is_empty() or journey.trace.size() > 4096:
		return "Missing or oversized native movement trace."
	if not fields(journey.summary, ["journey", "ticks", "step_up_events", "ground_follow_events", "maximum_horizontal_per_tick", "maximum_step_adjustment", "grounded_ticks", "end_position"]):
		return "Malformed journey summary."
	var summary: Dictionary = journey.summary
	if summary.journey != "normal_spawn_input_only_stairs_and_incline_out_and_back": return "Unknown executed journey."
	for key in ["ticks", "step_up_events", "ground_follow_events", "grounded_ticks"]:
		if not Motion.finite(summary[key]) or summary[key] < 0 or summary[key] != floor(summary[key]):
			return "Invalid journey summary counter."
	if not Motion.finite(summary.maximum_horizontal_per_tick) or not Motion.finite(summary.maximum_step_adjustment) or not Motion.vector(summary.end_position, 100):
		return "Non-finite journey summary."
	var previous_tick := -1
	var previous: Dictionary = {}
	var up := 0; var down := 0; var grounded := 0
	var horizontal_max := 0.0; var rise_max := 0.0; var minimum_z := 100.0
	var nonfloor_run := 0
	var air_run := 0; var air_origin := 0.0
	var retained: Dictionary = {}
	for row in journey.trace:
		if not fields(row, ["tick", "position", "velocity", "grounded", "mode", "event", "rise"]):
			return "Malformed native movement sample."
		if not Motion.finite(row.tick) or row.tick < 1 or row.tick > 10000000 or row.tick != floor(row.tick) or row.tick != previous_tick + 1 and previous_tick != -1:
			return "Native movement samples must have consecutive positive ticks."
		if not Motion.vector(row.position, 100) or not Motion.vector(row.velocity, Motion.MAX_FALL) or not row.grounded is bool:
			return "Non-finite or malformed native movement observation."
		if Vector2(row.velocity[0], row.velocity[2]).length() > 7.5001 or row.velocity[1] > Motion.JUMP_SPEED:
			return "Native movement velocity exceeds the shared motor profile."
		if not row.mode is String or not row.mode in ["ground", "air", "step_contact"] or not row.event is String or not row.event in ["", "step_up", "ground_follow"]:
			return "Unknown ground movement mode or event."
		if not Motion.finite(row.rise) or absf(row.rise) > 0.350001:
			return "Invalid observed ground correction."
		if row.mode == "ground" and not row.grounded or row.mode == "air" and row.grounded or row.grounded and absf(row.velocity[1]) > 0.0001:
			return "Ground observation disagrees with its native mode or vertical velocity."
		if not row.grounded and row.mode == "step_contact":
			nonfloor_run += 1; air_run = 0
			if nonfloor_run > 60: return "Native stair contact exceeded its bounded one-second transfer."
		elif not row.grounded and row.mode == "air":
			if previous.is_empty(): return "Air sample has no preceding native ground observation."
			var p := Motion.point(row.position); var prior := Motion.point(previous.position)
			if air_run == 0:
				if previous.mode != "ground" or previous.velocity[2] <= 0:
					return "Air release did not originate in descending stair motion."
				air_origin = prior.y
			air_run += 1; nonfloor_run = 0
			if air_run > 12 or p.y > prior.y+0.0001 or row.velocity[1] > 0 or p.z < prior.z-0.0001 or p.z < 1.3 or p.z > 4.5 or air_origin-p.y > 0.202:
				return "Native gravity release exceeds the qualified descending stair bounds."
		elif not row.grounded:
			return "Qualified journey lost native support outside bounded contact or descending gravity."
		else:
			nonfloor_run = 0; air_run = 0
		if row.event == "step_up" and row.rise <= 0 or row.event == "ground_follow" and row.rise >= 0 or row.event == "" and row.rise != 0:
			return "Ground event disagrees with its observed correction."
		var p := Motion.point(row.position)
		if absf(p.x) >= 0.02 or p.y < -0.012 or p.y > 0.732: return "Native journey left its connected lane."
		if row.grounded: grounded += 1
		if row.event == "step_up": up += 1
		if row.event == "ground_follow": down += 1
		rise_max = maxf(rise_max, absf(row.rise))
		minimum_z = minf(minimum_z, p.z)
		if not previous.is_empty():
			var prior := Motion.point(previous.position)
			horizontal_max = maxf(horizontal_max, Vector2(p.x-prior.x, p.z-prior.z).length())
			if not row.event.is_empty() and row.rise != JSON.parse_string(JSON.stringify((p-prior).y, "", true, true)):
				return "Ground correction disagrees with actual consecutive native displacement."
		if row.tick == snapshot.tick: retained = row
		previous_tick = int(row.tick)
		previous = row
	var last: Dictionary = journey.trace.back()
	if retained.is_empty() or canonical(retained.position) != canonical(snapshot.motion.position) or canonical(retained.velocity) != canonical(snapshot.motion.velocity) or retained.grounded != snapshot.motion.grounded:
		return "Retained snapshot does not match its unique executed native sample."
	var transported_horizontal: Variant = JSON.parse_string(JSON.stringify(horizontal_max, "", true, true))
	if summary.ticks != journey.trace.size() or summary.step_up_events != up or summary.ground_follow_events != down or summary.grounded_ticks != grounded or summary.maximum_horizontal_per_tick != transported_horizontal or summary.maximum_step_adjustment != rise_max or canonical(summary.end_position) != canonical(last.position):
		return "Journey summary disagrees with the native trace."
	if up < 4 or down < 4 or horizontal_max > 2.25/60.0+0.002 or rise_max > 0.302 or journey.trace[0].position[2] < 6.5 or minimum_z > -6 or last.position[2] < 6.5:
		return "Native trace does not satisfy the qualified out-and-back route."
	return ""

func physical_trace_error(trace: Array, course: Node3D) -> String:
	# Probe the retained observations without moving the restored actor. The
	# full hull, gravity and collision masks come from the source-bound course.
	var actor: CharacterBody3D = course.avatar
	var previous: Dictionary = {}
	for row in trace:
		var p := Motion.point(row.position)
		var occupied := actor.global_transform; occupied.origin = p+Vector3.UP*0.003
		if not Ground.clear_at(actor, occupied): return "Retained native hull overlaps actual course geometry."
		if not row.grounded and row.mode == "air":
			if not previous.is_empty() and not previous.grounded and previous.mode == "air":
				var velocity := Motion.point(row.velocity); var previous_velocity := Motion.point(previous.velocity)
				if absf(velocity.y-(previous_velocity.y-actor.gravity_strength/60)) > 0.0001:
					return "Retained descending velocity does not follow the native gravity integrator."
			var query := PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.01, p-Vector3.UP*0.302, actor.collision_mask, [actor.get_rid()])
			var floor_hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
			if floor_hit.is_empty() or not floor_hit.collider is StaticBody3D or floor_hit.normal.y < cos(actor.floor_max_angle):
				return "Retained descending release has no nearby actual walkable static floor."
		previous = row
	return ""

func spatial_error(value: Variant) -> String:
	if not fields(value,["oblique_steps","turn_terrace","diagonal_ceiling","slope_control"]): return "Malformed spatial-control evidence."
	if not value.oblique_steps is Array or value.oblique_steps.size()!=5: return "Spatial evidence requires five declared oblique entries."
	var angles := [-45.0,-30.0,0.0,30.0,45.0]
	for index in range(angles.size()):
		var item: Variant=value.oblique_steps[index]
		if not fields(item,["degrees","ticks","end","air_ticks","maximum_contact_ticks","maximum_horizontal_per_tick"]):
			return "Malformed oblique entry evidence."
		if item.degrees!=angles[index] or not Motion.finite(item.ticks) or item.ticks<1 or item.ticks>180 or item.ticks!=floor(item.ticks):
			return "Unknown oblique angle or tick count."
		if not Motion.vector(item.end,100) or absf(item.end[1]-0.18)>0.012 or item.end[2]>=-2:
			return "Oblique entry did not finish on its qualified real tread."
		if item.air_ticks!=0 or not Motion.finite(item.maximum_contact_ticks) or item.maximum_contact_ticks<0 or item.maximum_contact_ticks>60 or item.maximum_contact_ticks!=floor(item.maximum_contact_ticks):
			return "Oblique entry exceeded its support or contact bounds."
		if not Motion.finite(item.maximum_horizontal_per_tick) or item.maximum_horizontal_per_tick>2.7/60.0+0.002:
			return "Oblique entry exceeded its commanded travel budget."
	var turn: Variant=value.turn_terrace
	if not fields(turn,["entry","high","returned","turn_air_ticks","down_air_ticks","maximum_down_air_run","step_up_events","maximum_horizontal_per_tick"]):
		return "Malformed turn-terrace evidence."
	if not Motion.vector(turn.entry,100) or turn.entry[2]>=-2 or absf(turn.entry[1]-0.18)>0.012:
		return "Turn terrace did not reach its first tread."
	if not Motion.vector(turn.high,100) or turn.high[0]<=12.5 or absf(turn.high[1]-0.30)>0.012:
		return "Perpendicular turn did not reach the higher terrace."
	if not Motion.vector(turn.returned,100) or turn.returned[0]>=10.5 or absf(turn.returned[1]-0.18)>0.012:
		return "Turn terrace did not return to lower support."
	for key in ["turn_air_ticks","down_air_ticks","maximum_down_air_run","step_up_events"]:
		if not Motion.finite(turn[key]) or turn[key]<0 or turn[key]!=floor(turn[key]): return "Invalid turn-terrace counter."
	if turn.turn_air_ticks!=0 or turn.down_air_ticks<1 or turn.maximum_down_air_run<1 or turn.maximum_down_air_run>12 or turn.step_up_events<2:
		return "Turn-terrace support, descent or rise evidence is outside bounds."
	if not Motion.finite(turn.maximum_horizontal_per_tick) or turn.maximum_horizontal_per_tick>2.7/60.0+0.002:
		return "Turn terrace exceeded its commanded travel budget."
	var ceiling: Variant=value.diagonal_ceiling
	if not fields(ceiling,["end","step_up_events"]) or not Motion.vector(ceiling.end,100): return "Malformed diagonal-ceiling evidence."
	if ceiling.end[1]>=0.02 or ceiling.end[2]<=-1 or ceiling.step_up_events!=0:
		return "Diagonal ceiling did not refuse the otherwise walkable rise."
	var slope: Variant=value.slope_control
	if not fields(slope,["stop","reverse","lateral","diagonal"]): return "Malformed slope-control evidence."
	if not fields(slope.stop,["start","stopped","settled","stop_distance","settled_drift"]): return "Malformed slope-stop evidence."
	if not Motion.vector(slope.stop.start,100) or not Motion.vector(slope.stop.stopped,100) or not Motion.vector(slope.stop.settled,100): return "Non-finite slope-stop position."
	if not Motion.finite(slope.stop.stop_distance) or slope.stop.stop_distance>=0.11 or not Motion.finite(slope.stop.settled_drift) or slope.stop.settled_drift>=0.002:
		return "Slope stopping or settled drift exceeded bounds."
	if not fields(slope.reverse,["end","air_ticks","maximum_horizontal_per_tick"]): return "Malformed slope-reverse evidence."
	if not fields(slope.lateral,["end","air_ticks","step_up_events","maximum_horizontal_per_tick"]): return "Malformed lateral-slope evidence."
	if not fields(slope.diagonal,["end","air_ticks","maximum_horizontal_per_tick"]): return "Malformed diagonal-slope evidence."
	for key in ["reverse","lateral","diagonal"]:
		var item: Variant=slope[key]
		if not Motion.vector(item.get("end"),100) or item.get("air_ticks")!=0 or not Motion.finite(item.get("maximum_horizontal_per_tick")) or item.maximum_horizontal_per_tick>2.7/60.0+0.002:
			return "Slope direction change exceeded support or travel bounds."
	if slope.reverse.end[2]<=-1.7 or slope.reverse.end[1]>=0.02: return "Slope reversal did not return to the lower floor."
	if slope.lateral.end[0]<=-5.4 or slope.lateral.end[1]<=0.3 or slope.lateral.get("step_up_events")!=0: return "Lateral slope evidence is outside bounds."
	if slope.diagonal.end[0]<=-5.4 or slope.diagonal.end[2]>=-2.8 or slope.diagonal.end[1]<=0.7: return "Diagonal slope evidence is outside bounds."
	return ""

func run() -> void:
	var directory := OS.get_environment("GROUND_CAPTURE_OUTPUT")
	if not check(not directory.is_empty() and DirAccess.dir_exists_absolute(directory), "executed-journey output directory exists"):
		finish(); return
	var path := directory.path_join(EVIDENCE)
	var file := FileAccess.open(path, FileAccess.READ)
	if not check(file != null and file.get_length() > 0 and file.get_length() <= MAX_EVIDENCE_BYTES, "retained evidence exists within the declared size bound"):
		if file != null: file.close()
		finish(); return
	var source_bytes := file.get_buffer(file.get_length()); file.close()
	var parsed: Variant = JSON.parse_string(source_bytes.get_string_from_utf8())
	if not check(fields(parsed, ["schema", "source_commit", "source_tree", "source_digest", "geometry_digest", "motor_digest", "physics_hz", "journey", "spatial_control", "snapshot"]) and parsed.get("schema") == "ground-contact-evidence.v1", "retained native evidence has the exact versioned field set"):
		finish(); return
	var record: Dictionary = parsed
	var commit := OS.get_environment("SOURCE_COMMIT")
	var tree := OS.get_environment("SOURCE_TREE")
	if not check(hex_identity(commit, 40) and hex_identity(tree, 40) and record.source_commit == commit and record.source_tree == tree, "executed evidence matches the required source commit and tree"):
		finish(); return
	if not check(hex_identity(record.source_digest, 64) and hex_identity(record.geometry_digest, 64) and hex_identity(record.motor_digest, 64) and Motion.finite(record.physics_hz) and record.physics_hz == 60 and Engine.physics_ticks_per_second == 60, "retained source, geometry, motor and physics timing identities are declared"):
		finish(); return
	if not check(fields(record.snapshot, ["schema", "course_id", "source_digest", "geometry_digest", "motor_digest", "physics_hz", "tick", "paused", "motion"]), "retained practice snapshot has the exact versioned fields"):
		finish(); return
	var snapshot: Dictionary = record.snapshot
	if not check(snapshot.schema == "ground-contact-course-save.v1" and snapshot.course_id == "ground-contact-course.v1" and snapshot.paused is bool and Motion.finite(snapshot.tick) and snapshot.tick > 0 and snapshot.tick == floor(snapshot.tick) and Motion.validate_snapshot(snapshot.motion).is_empty(), "retained practice snapshot declares valid native motion and time"):
		finish(); return
	if not check(snapshot.source_digest == record.source_digest and snapshot.geometry_digest == record.geometry_digest and snapshot.motor_digest == record.motor_digest and snapshot.physics_hz == record.physics_hz, "evidence identities agree with the retained practice authority"):
		finish(); return
	var error := trace_error(record.journey, snapshot)
	if not check(error.is_empty(), "retained native journey is structurally coherent: " + error):
		finish(); return
	error = spatial_error(record.spatial_control)
	if not check(error.is_empty(), "retained spatial-control evidence is within its declared bounds: " + error):
		finish(); return
	if not check(DisplayServer.get_name() != "headless", "native pixels require an actual display renderer"):
		finish(); return
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var course: Node3D = CourseScene.instantiate()
	course.paused = true
	course.set_physics_process(false)
	root.add_child(course)
	# _ready is synchronous. Disable the shared Player before any frame can advance.
	course.set_paused(true)
	course.save_path = directory.path_join("unwritten-render-slot.json")
	var before := canonical(snapshot)
	error = course.restore(snapshot)
	if not check(error.is_empty(), "actual course authority accepts the source-bound retained state: " + error):
		finish(course); return
	course.set_physics_process(false)
	course.avatar.set_physics_process(false)
	course.avatar.input_enabled = false
	course.avatar.get_node("LocomotionProxy").set_process(false)
	course.set_process_unhandled_input(false)
	course.avatar.set_process_unhandled_input(false)
	var native_before := canonical(course.snapshot())
	if not check(canonical(transported_snapshot(course)) == before, "native restore preserves the canonical decoded snapshot exactly"):
		finish(course); return
	error = physical_trace_error(record.journey.trace, course)
	if not check(error.is_empty(), "retained full hull and gravity observations fit the actual frozen course: " + error):
		finish(course); return
	await process_frame
	await process_frame
	if not check(canonical(course.snapshot()) == native_before and canonical(transported_snapshot(course)) == before, "startup preserves all native motion, camera and authority state"):
		finish(course); return
	var viewport_bounds := Rect2(Vector2.ZERO, Vector2(root.size))
	check(viewport_bounds.encloses(course.hud.get_global_rect()) and viewport_bounds.encloses(course.status.get_global_rect()), "practice HUD fits the required viewport")
	check(root.size == Vector2i(1280, 720) and DisplayServer.window_get_size() == Vector2i(1280, 720), "native display and viewport are exactly 1280 by 720")
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	if not check(pixels != null and not pixels.is_empty() and pixels.get_width() == 1280 and pixels.get_height() == 720, "actual course supplies the required native pixels"):
		finish(course); return
	check(canonical(course.snapshot()) == native_before and canonical(transported_snapshot(course)) == before, "rendering leaves the retained tick, position, velocity and camera unchanged")
	check(FileAccess.get_file_as_bytes(path) == source_bytes, "rendering preserves the exact executed evidence file bytes")
	if failed > 0:
		finish(course); return
	var temporary := directory.path_join(PIXELS + ".tmp")
	if not check(pixels.save_png(temporary) == OK, "native pixels encode successfully"):
		finish(course); return
	check(DirAccess.rename_absolute(temporary, directory.path_join(PIXELS)) == OK, "source-bound native screenshot is retained atomically beside its evidence")
	finish(course)
