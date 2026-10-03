# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native fixtures exercise saved-pose support using the retained horse motor.
const Horse := preload("res://mounts/horse.gd")
const Player := preload("res://player/player.tscn")
const Rules := preload("res://mounts/riding_rules.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSE GROUNDING: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return body

func bodies(world: Node3D, at: Vector3) -> Array:
	var horse := Horse.new()
	horse.position = at
	world.add_child(horse)
	var avatar: CharacterBody3D = Player.instantiate()
	avatar.position = Vector3(8, 3, 8)
	world.add_child(avatar)
	avatar.set_physics_process(false)
	avatar.collision_layer = 0
	avatar.collision_mask = 0
	return [horse, avatar]

func observation(horse: CharacterBody3D, avatar: CharacterBody3D) -> Dictionary:
	var hull: CollisionShape3D = horse.get_node("Hull")
	var walking_hull: CollisionShape3D = avatar.get_node("CollisionShape3D")
	return {"horse_pose":horse.global_transform, "avatar_pose":avatar.global_transform,
		"horse_velocity":horse.velocity, "avatar_velocity":avatar.velocity,
		"horse_speed":horse.speed, "horse_stride":horse._stride,
		"horse_grounded":horse.is_on_floor(), "avatar_grounded":avatar.is_on_floor(),
		"horse_floor_normal":horse.get_floor_normal(),
		"horse_mask":horse.collision_mask, "avatar_mask":avatar.collision_mask,
		"horse_layer":horse.collision_layer, "avatar_layer":avatar.collision_layer,
		"horse_shape_identity":hull.shape.get_instance_id(), "horse_child_transform":hull.transform,
		"avatar_shape_identity":walking_hull.shape.get_instance_id(), "avatar_child_transform":walking_hull.transform}

func qualify(horse: CharacterBody3D, avatar: CharacterBody3D, record: Dictionary, expected: bool, label: String) -> void:
	var before := observation(horse, avatar)
	var saved := record.duplicate(true)
	var result: bool = horse.record_fits_world(record, avatar)
	check(result == expected, label)
	var repeated := true
	for _i in range(4):
		repeated = horse.record_fits_world(record, avatar) == result and repeated
	check(repeated, label + " remains deterministic on repeated queries")
	check(record == saved, label + " preserves the candidate record")
	check(observation(horse, avatar) == before, label + " preserves live poses, velocities, grounding and shape identities")

func _settled_ramp(degrees: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var angle := deg_to_rad(degrees)
	var floor_body := box(world, Vector3(0, -.1 / cos(angle), 0), Vector3(20, .2, 20))
	floor_body.rotation.x = angle
	# Plane through origin; the motor, not the initial placement, establishes
	# the saved resting pose and grounding flag.
	var pair := bodies(world, Vector3(0, .8 * (1.0 / cos(angle) - 1.0) + .04, 0))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	await frames()
	var sample: Dictionary = {}
	for _i in range(120):
		sample = horse.step(1.0 / 60.0, 0, 0, false, false, true)
		await physics_frame
	var label := "%.1f degree motor-settled horse" % degrees
	check(sample.grounded and horse.is_on_floor(), label + " reports actual native support")
	check(absf(rad_to_deg(horse.get_floor_angle()) - degrees) < .02, label + " touches the declared ramp")
	check(sample.speed == 0.0 and sample.vertical_speed == 0.0, label + " is stopped without residual falling")
	var analytic_gap := .8 * (1.0 / cos(angle) - 1.0)
	var measured_gap := horse.global_position.y + tan(angle) * horse.global_position.z
	check(absf(measured_gap - analytic_gap) < .001, label + " agrees with independent capsule-plane support geometry")
	var record: Dictionary = Rules.initial().horse
	for key in sample: record[key] = sample[key]
	qualify(horse, avatar, record, true, label + " saved pose is admitted")
	# Loading validates the saved pose, even when the live body is elsewhere.
	horse.position = Vector3(4, 5, 4)
	avatar.position = Vector3(-4, 5, -4)
	await frames()
	qualify(horse, avatar, record, true, label + " remains admitted independently of the live bodies' poses")
	world.queue_free()
	await frames()

func _flat_allowance_and_obstructions() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := box(world, Vector3(0, -.1, 0), Vector3(20, .2, 20))
	var pair := bodies(world, Vector3(4, 4, 4))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	await frames()
	var record: Dictionary = Rules.initial().horse
	for height in [.04, .18, .199, .201, .25, 1.0]:
		record.position = [0.0, height, 0.0]
		qualify(horse, avatar, record, height <= .2, "flat saved feet at %.3fm respects retained .20m support allowance" % height)
	record.position = [0.0, .04, 0.0]
	var obstruction := box(world, Vector3(0, 1.6, 0), Vector3(.3, .3, .3))
	await frames()
	qualify(horse, avatar, record, false, "a grounded saved hull intersecting an obstacle is refused")
	record.grounded = false
	record.rider_id = "ranjit_singh"
	record.vertical_speed = -1.0
	qualify(horse, avatar, record, false, "an airborne saved hull still refuses overlap")
	obstruction.queue_free()
	floor_body.queue_free()
	await frames()
	record.grounded = true
	record.rider_id = ""
	record.vertical_speed = 0.0
	qualify(horse, avatar, record, false, "a clear grounded saved hull with no supporting floor is refused")
	record.grounded = false
	record.rider_id = "ranjit_singh"
	record.vertical_speed = -1.0
	qualify(horse, avatar, record, true, "a clear airborne saved hull retains its existing support-free admission")
	world.queue_free()
	await frames()

func _steep_support(degrees: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var angle := deg_to_rad(degrees)
	var floor_body := box(world, Vector3(0, -.1 / cos(angle), 0), Vector3(20, .2, 20))
	floor_body.rotation.x = angle
	var pair := bodies(world, Vector3(4, 5, 4))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	await frames()
	var record: Dictionary = Rules.initial().horse
	record.position = [0.0, .8 * (1.0 / cos(angle) - 1.0) + .04, 0.0]
	qualify(horse, avatar, record, false, "%.1f degree support exceeds the retained 40 degree horse floor limit" % degrees)
	world.queue_free()
	await frames()

func _run() -> void:
	for degrees in [0.0, 30.0, 35.0, 37.0, 38.0, 39.0, 39.9]:
		await _settled_ramp(degrees)
	await _flat_allowance_and_obstructions()
	await _steep_support(41.0)
	await _steep_support(50.0)
	print("HORSE_GROUNDING_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
