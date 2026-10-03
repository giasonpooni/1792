# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Qualifies the existing motor on synthetic broad ramps, not historical terrain.
## Setup places the horse once; acceleration, travel and braking use step() only.

const Horse := preload("res://mounts/horse.gd")
const Rules := preload("res://mounts/riding_rules.gd")
const DT := 1.0 / 60.0
const TRAVEL_TICKS := 600
const SAMPLE_TICKS := 180
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

func _run() -> void:
	for angle in [0.0, 20.0, 35.0]:
		for direction in ["up", "down", "across"]:
			await _measure(angle, direction)
	print("HORSE_SLOPE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _measure(angle: float, direction: String) -> void:
	var label := "%s degrees %s" % [angle, direction]
	var world := Node3D.new()
	root.add_child(world)
	var ramp := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(300, 1, 300)
	collider.shape = shape
	ramp.add_child(collider)
	ramp.rotation.x = deg_to_rad(angle)
	# Top plane passes through the origin. Bounds stay far from every journey.
	ramp.position = -ramp.transform.basis.y * 0.5
	world.add_child(ramp)
	var horse := Horse.new()
	horse.position = Vector3(0, 0.8 * (1.0 / cos(deg_to_rad(angle)) - 1.0) + 0.04, 0)
	horse.rotation.y = 0.0 if direction == "up" else PI if direction == "down" else PI / 2.0
	world.add_child(horse)
	await physics_frame
	for _i in range(30):
		horse.step(DT, 0.0, 0.0, false, false, false)
		await physics_frame
	check(horse.is_on_floor() and horse.speed == 0.0, label + " settles stopped on the floor")
	var last: Vector3 = horse.position
	var path_length := 0.0
	var speed_sum := 0.0
	var grounded_samples := 0
	var valid_motion := true
	for i in range(TRAVEL_TICKS):
		var motion: Dictionary = horse.step(DT, 1.0, 0.0, true, false, false)
		valid_motion = valid_motion and _bounded(motion)
		if i >= TRAVEL_TICKS - SAMPLE_TICKS:
			path_length += horse.position.distance_to(last)
			speed_sum += motion.speed
			if motion.grounded:
				grounded_samples += 1
		last = horse.position
		await physics_frame
	var path_rate := path_length / (SAMPLE_TICKS * DT)
	var mean_speed := speed_sum / SAMPLE_TICKS
	check(absf(mean_speed - Rules.MAX_SPEED) < 0.001, label + " retains the canter cap during sustained travel")
	check(absf(path_rate - Rules.MAX_SPEED) < 0.05, label + " actual three-dimensional path speed matches the cap")
	check(grounded_samples == SAMPLE_TICKS, label + " stays grounded throughout the measured journey")
	var brake_start: Vector3 = horse.position
	var brake_ticks := 0
	for _i in range(120):
		var motion: Dictionary = horse.step(DT, 0.0, 0.0, true, false, true)
		valid_motion = valid_motion and _bounded(motion)
		brake_ticks += 1
		await physics_frame
		if horse.speed < 0.001:
			break
	var braking_distance := brake_start.distance_to(horse.position)
	check(valid_motion, label + " all travel and braking records retain finite bounded motion")
	check(brake_ticks >= 73 and brake_ticks <= 75, label + " brakes from 11 m/s within the qualified time")
	check(absf(braking_distance - 6.63) < 0.08, label + " braking distance remains consistent on the incline")
	check(horse.speed < 0.001 and horse.is_on_floor(), label + " finishes stopped and grounded")
	print("HORSE_SLOPE_METRIC: " + JSON.stringify({"angle": angle, "direction": direction,
		"mean_stored_speed": mean_speed, "path_rate": path_rate, "grounded_samples": grounded_samples,
		"braking_ticks": brake_ticks, "braking_distance": braking_distance}))
	world.queue_free()
	await physics_frame

func _bounded(motion: Dictionary) -> bool:
	return is_finite(motion.speed) and motion.speed >= 0.0 and motion.speed <= Rules.MAX_SPEED \
		and is_finite(motion.vertical_speed) and motion.vertical_speed <= 0.0 \
		and motion.vertical_speed >= -Rules.MAX_FALL \
		and (not motion.grounded or motion.vertical_speed == 0.0) \
		and Vector3(motion.position[0], motion.position[1], motion.position[2]).is_finite()
