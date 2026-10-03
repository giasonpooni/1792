# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native saved-pose checks against the actual horse capsule's upper envelope.
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
		push_error("HORSE HEADROOM: " + label)

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
	avatar.position = Vector3(8, 5, 8)
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
		"horse_ceiling":horse.is_on_ceiling(), "avatar_ceiling":avatar.is_on_ceiling(),
		"horse_floor_normal":horse.get_floor_normal(), "avatar_floor_normal":avatar.get_floor_normal(),
		"horse_mask":horse.collision_mask, "avatar_mask":avatar.collision_mask,
		"horse_layer":horse.collision_layer, "avatar_layer":avatar.collision_layer,
		"horse_shape_identity":hull.shape.get_instance_id(), "horse_child_transform":hull.transform,
		"horse_shape_radius":hull.shape.radius, "horse_shape_height":hull.shape.height,
		"horse_adapter_shape_identity":horse._hull.get_instance_id(),
		"horse_adapter_shape_radius":horse._hull.radius, "horse_adapter_shape_height":horse._hull.height,
		"horse_shape_disabled":hull.disabled,
		"avatar_shape_identity":walking_hull.shape.get_instance_id(), "avatar_child_transform":walking_hull.transform,
		"avatar_shape_radius":walking_hull.shape.radius, "avatar_shape_height":walking_hull.shape.height,
		"avatar_shape_disabled":walking_hull.disabled}

func qualify(horse: CharacterBody3D, avatar: CharacterBody3D, record: Dictionary, expected: bool, label: String) -> void:
	var before := observation(horse, avatar)
	var candidate := record.duplicate(true)
	var result: bool = horse.record_fits_world(record, avatar)
	check(result == expected, label)
	var repeated := true
	for _i in range(4):
		repeated = horse.record_fits_world(record, avatar) == result and repeated
	check(repeated, label + " is deterministic on repeated queries")
	check(record == candidate, label + " preserves the candidate record")
	check(observation(horse, avatar) == before, label + " preserves live state and collider identity, dimensions and transforms")

func settled_record(horse: CharacterBody3D) -> Dictionary:
	var sample: Dictionary = {}
	for _i in range(120):
		sample = horse.step(1.0 / 60.0, 0, 0, false, false, true)
		await physics_frame
	var record: Dictionary = Rules.initial().horse
	for key in sample: record[key] = sample[key]
	return record

func _settled_ceiling(underside: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -.1, 0), Vector3(20, .2, 20))
	box(world, Vector3(0, underside + .1, 0), Vector3(20, .2, 20))
	var pair := bodies(world, Vector3(0, .005, 0))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	await frames()
	var record := await settled_record(horse)
	var label := "horse beneath %.2fm ceiling" % underside
	check(record.grounded and horse.is_on_floor(), label + " actually settles on native ground")
	check(not horse.is_on_ceiling(), label + " does not contact the ceiling while settling")
	var hull: CollisionShape3D = horse.get_node("Hull")
	var actual_top: float = hull.global_position.y + hull.shape.height * .5
	check(actual_top < underside and actual_top > 3.19, label + " actual capsule fits below the ceiling")
	check(record.speed == 0.0 and record.vertical_speed == 0.0, label + " settles without residual movement")
	qualify(horse, avatar, record, true, label + " saved pose is admitted")
	horse.position = Vector3(8, 6, 8)
	avatar.position = Vector3(-8, 6, -8)
	await frames()
	qualify(horse, avatar, record, true, label + " candidate remains admitted when live bodies are elsewhere")
	world.queue_free()
	await frames()

func _grounded_obstructions() -> void:
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -.1, 0), Vector3(20, .2, 20))
	var pair := bodies(world, Vector3(0, .005, 0))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	await frames()
	var record := await settled_record(horse)
	check(record.grounded, "grounded obstruction fixture starts from a native settled pose")
	qualify(horse, avatar, record, true, "grounded query is admitted before switching query mode")
	var airborne := record.duplicate(true)
	airborne.position = [0.0, 6.0, 0.0]
	airborne.grounded = false
	airborne.rider_id = "ranjit_singh"
	airborne.vertical_speed = -1.0
	qualify(horse, avatar, airborne, true, "airborne query remains clear after grounded queries on the same body")
	qualify(horse, avatar, record, true, "grounded query remains supported after airborne queries on the same body")
	var obstruction := box(world, Vector3(0, 3.28, 0), Vector3(20, .2, 20))
	await frames()
	qualify(horse, avatar, record, false, "grounded capsule penetrating a ceiling at 3.18m is refused")
	obstruction.queue_free()
	await frames()
	obstruction = box(world, Vector3(.7, 1.6, 0), Vector3(.4, .4, .4))
	await frames()
	qualify(horse, avatar, record, false, "grounded capsule penetrating a side obstacle is refused")
	world.queue_free()
	await frames()

func _airborne_obstructions() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var pair := bodies(world, Vector3(8, 6, 8))
	var horse: CharacterBody3D = pair[0]
	var avatar: CharacterBody3D = pair[1]
	var record: Dictionary = Rules.initial().horse
	record.position = [0.0, 1.0, 0.0]
	record.grounded = false
	record.vertical_speed = -1.0
	record.rider_id = "ranjit_singh"
	await frames()
	qualify(horse, avatar, record, true, "clear airborne capsule needs no supporting floor")
	# This small block occupies the actual bottom 3cm, below the old lifted query.
	var obstruction := box(world, Vector3(0, 1.015, 0), Vector3(.1, .03, .1))
	await frames()
	qualify(horse, avatar, record, false, "airborne capsule overlapping a 3cm foot obstacle is refused")
	obstruction.queue_free()
	await frames()
	obstruction = box(world, Vector3(0, 4.34, 0), Vector3(20, .2, 20))
	await frames()
	qualify(horse, avatar, record, true, "airborne capsule with 4cm of actual headroom is admitted")
	obstruction.position.y = 4.28
	await frames()
	qualify(horse, avatar, record, false, "airborne capsule penetrating a ceiling at 4.18m is refused")
	obstruction.queue_free()
	await frames()
	obstruction = box(world, Vector3(.7, 2.6, 0), Vector3(.4, .4, .4))
	await frames()
	qualify(horse, avatar, record, false, "airborne capsule penetrating a side obstacle is refused")
	world.queue_free()
	await frames()

func _run() -> void:
	for underside in [3.21, 3.24, 3.26]:
		await _settled_ceiling(underside)
	await _grounded_obstructions()
	await _airborne_obstructions()
	print("HORSE_HEADROOM_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
