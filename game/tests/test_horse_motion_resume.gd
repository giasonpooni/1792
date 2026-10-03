# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native fall continuation, with distinct real collision caches and one saved pose.
const Horse := preload("res://mounts/horse.gd")
const Rules := preload("res://mounts/riding_rules.gd")
const DT := 1.0 / 60.0
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSE MOTION RESUME: " + label)

func state_at(sample: Dictionary, x: float) -> Dictionary:
	var record: Dictionary = Rules.initial().horse
	for key in sample: record[key] = sample[key]
	record.position[0] = x
	record.rider_id = "ranjit_singh"
	return record

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, .2, 40)
	collider.shape = shape
	floor_body.position.y = -.1
	floor_body.add_child(collider)
	world.add_child(floor_body)
	var continuing := Horse.new()
	continuing.position = Vector3(-6, 14, 0)
	world.add_child(continuing)
	var reused := Horse.new()
	reused.position = Vector3(0, .04, 0)
	world.add_child(reused)
	await physics_frame
	for _i in range(60):
		reused.step(DT, 0, 0, false, false, true)
		await physics_frame
	check(reused.is_on_floor(), "reused native body really establishes floor contact")
	var saved_sample: Dictionary = {}
	for _i in range(18):
		saved_sample = continuing.step(DT, 0, 0, false, false, true)
		await physics_frame
	check(not saved_sample.grounded and saved_sample.vertical_speed < -6.0,
		"reference saved pose comes from an actual native fall")
	var original := saved_sample.duplicate(true)
	var record := state_at(saved_sample.duplicate(true), 0)
	var candidate := record.duplicate(true)
	reused.apply_record(record)
	check(reused.is_on_floor(), "apply_record leaves the old native floor cache as the regression trigger")
	check(reused.velocity.y == saved_sample.vertical_speed, "apply_record installs the saved downward speed")
	var fresh := Horse.new()
	world.add_child(fresh)
	await physics_frame
	fresh.apply_record(state_at(saved_sample.duplicate(true), 6))
	check(not fresh.is_on_floor(), "fresh native body has a different real contact cache")
	var first_reference: Dictionary = {}
	var first_reused: Dictionary = {}
	var first_fresh: Dictionary = {}
	var maximum_error := 0.0
	var all_grounding_equal := true
	var all_vertical_equal := true
	for tick in range(90):
		var reference: Dictionary = continuing.step(DT, 0, 0, false, false, true)
		var restored: Dictionary = reused.step(DT, 0, 0, false, false, true)
		var recreated: Dictionary = fresh.step(DT, 0, 0, false, false, true)
		if tick == 0:
			first_reference = reference.duplicate(true)
			first_reused = restored.duplicate(true)
			first_fresh = recreated.duplicate(true)
		maximum_error = maxf(maximum_error, absf(reference.position[1] - restored.position[1]))
		maximum_error = maxf(maximum_error, absf(reference.position[1] - recreated.position[1]))
		all_grounding_equal = all_grounding_equal and reference.grounded == restored.grounded and reference.grounded == recreated.grounded
		all_vertical_equal = all_vertical_equal and is_equal_approx(reference.vertical_speed, restored.vertical_speed) and is_equal_approx(reference.vertical_speed, recreated.vertical_speed)
		await physics_frame
	check(is_equal_approx(first_reused.vertical_speed, first_reference.vertical_speed),
		"first resumed fall keeps saved momentum and exactly one gravity update")
	check(is_equal_approx(first_fresh.vertical_speed, first_reference.vertical_speed),
		"fresh body also reproduces the first fall update")
	check(maximum_error <= .000002, "complete fall and landing path agrees across both contact caches")
	check(all_vertical_equal, "every downward-speed sample agrees through native landing")
	check(all_grounding_equal, "landing occurs on the same native physics tick")
	check(continuing.is_on_floor() and reused.is_on_floor() and fresh.is_on_floor(),
		"all three bodies really land on the native floor")
	check(record == candidate and saved_sample == original, "applying and resuming preserve supplied evidence records")
	print("HORSE_MOTION_RESUME_EVIDENCE: " + JSON.stringify({"saved":original,
		"first_reference":first_reference,"first_reused":first_reused,"first_fresh":first_fresh,
		"maximum_y_error":maximum_error,"all_grounding_equal":all_grounding_equal}))
	world.queue_free()
	await physics_frame
	print("HORSE_MOTION_RESUME_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
