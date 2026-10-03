# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit spatial fixtures qualify a discrete transfer, not a played journey.
const Horse := preload("res://mounts/horse.gd")
const Player := preload("res://player/player.tscn")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("DISMOUNT CLEARANCE: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	collider.shape = geometry
	body.add_child(collider)
	parent.add_child(body)
	return body

func observation(horse: CharacterBody3D, avatar: CharacterBody3D) -> Dictionary:
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	return {"horse_pose":horse.global_transform, "avatar_pose":avatar.global_transform,
		"horse_velocity":horse.velocity, "avatar_velocity":avatar.velocity,
		"horse_speed":horse.speed, "horse_stride":horse._stride,
		"horse_mask":horse.collision_mask, "avatar_mask":avatar.collision_mask,
		"horse_layer":horse.collision_layer, "avatar_layer":avatar.collision_layer,
		"avatar_shape_identity":collider.shape.get_instance_id(),
		"avatar_child_transform":collider.transform,
		"horse_shape_identity":horse.get_node("Hull").shape.get_instance_id()}

func plane_clearance(avatar: CharacterBody3D, normal: Vector3) -> float:
	# Exact support for the retained upright capsule in these planar fixtures.
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	var capsule: CapsuleShape3D = collider.shape
	var center: Vector3 = collider.global_position
	return center.dot(normal) - capsule.radius - (capsule.height * .5 - capsule.radius) * normal.y

func _ramp(degrees: float, first_side_blocked: bool = false) -> void:
	var label := "%.0f degree ramp%s" % [degrees, " with first exit blocked" if first_side_blocked else ""]
	var world := Node3D.new()
	root.add_child(world)
	var angle := deg_to_rad(degrees)
	# Plane through origin; slope runs along z so the first +/-x exits have
	# equal height. The floor's finite edges are well beyond every exit.
	var floor_body := box(world, Vector3(0, -.1 / cos(angle), 0), Vector3(20, .2, 20))
	floor_body.rotation.x = angle
	var normal := Vector3(0, cos(angle), sin(angle))
	var horse := Horse.new()
	horse.position = Vector3(0, .8 * (1.0 / cos(angle) - 1.0) + .04, 0)
	world.add_child(horse)
	var avatar: CharacterBody3D = Player.instantiate()
	avatar.position = horse.position
	world.add_child(avatar)
	avatar.set_physics_process(false)
	# Both existing owning scenes suppress the walking body's mask and layer
	# while mounted; the dismount query must still inspect layer-one scenery.
	avatar.collision_mask = 0
	avatar.collision_layer = 0
	if first_side_blocked: box(world, Vector3(1.8, 1.0, 0), Vector3(.55, 2.0, .8))
	await frames()
	var before := observation(horse, avatar)
	var landing: Variant = horse.dismount_position(avatar)
	for _i in range(5): horse.dismount_position(avatar)
	check(observation(horse, avatar) == before, label + " query preserves poses, masks, velocities and shape identities")
	if degrees > 40.0:
		check(landing == null, label + " exceeds the retained horse slope limit")
	else:
		check(landing is Vector3, label + " provides a physically clear supported destination")
		if landing is Vector3:
			check(landing.x < -1.7 if first_side_blocked else landing.x > 1.7, label + " respects exit ordering and obstruction fallback")
			check(absf(landing.z) < .0001, label + " uses a same-height cross-slope exit")
			avatar.position = landing
			var separation := plane_clearance(avatar, normal)
			check(separation >= -.0002, label + " candidate actual capsule does not penetrate its supporting plane")
			check(separation < .06, label + " candidate retains bounded floor clearance")
			# Simulate the unchanged walking hull at the accepted pose. A successful
			# query must settle onto this actual slope without a depenetration jump.
			avatar.collision_layer = 1
			avatar.collision_mask = 1
			var maximum_rise := 0.0
			for _i in range(30):
				avatar.velocity = Vector3.DOWN * .5
				avatar.move_and_slide()
				maximum_rise = maxf(maximum_rise, avatar.position.y - landing.y)
				await physics_frame
			check(avatar.is_on_floor(), label + " accepted actual hull settles grounded in native physics")
			check(absf(rad_to_deg(avatar.get_floor_angle()) - degrees) < .02, label + " native support has the declared floor angle")
			check(plane_clearance(avatar, normal) >= -.0002, label + " settled actual hull does not penetrate the plane")
			check(maximum_rise < .001, label + " needs no upwards depenetration correction")
	world.queue_free()
	await frames()

func _hull_integrity() -> void:
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -.1, 0), Vector3(20, .2, 20))
	var horse := Horse.new()
	horse.position = Vector3(0, .04, 0)
	world.add_child(horse)
	var avatar: CharacterBody3D = Player.instantiate()
	avatar.position = horse.position
	world.add_child(avatar)
	avatar.set_physics_process(false)
	avatar.collision_layer = 0
	avatar.collision_mask = 0
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	# A unique fixture resource prevents shape edits changing the packed scene.
	collider.shape = collider.shape.duplicate()
	var capsule: CapsuleShape3D = collider.shape
	await frames()
	check(horse.dismount_position(avatar) is Vector3, "mounted mask-zero avatar retains a clear flat-ground exit")
	var overlap := box(world, Vector3(0, .8, .25), Vector3(.2, .5, .2))
	await frames()
	var before := observation(horse, avatar)
	check(horse.dismount_position(avatar) == null, "an initially intersecting exit hull is refused before cast_motion can ignore it")
	check(observation(horse, avatar) == before, "initial-overlap refusal preserves all observed physical state")
	overlap.queue_free()
	await frames()
	capsule.height = 2.6
	collider.position.y = 1.3
	var ceiling := box(world, Vector3(0, 2.2, 0), Vector3(8, .2, 8))
	await frames()
	before = observation(horse, avatar)
	check(horse.dismount_position(avatar) == null, "actual 2.6m hull cannot dismount below a 2.1m ceiling")
	check(observation(horse, avatar) == before, "changed-hull ceiling refusal preserves shape identity and physical state")
	ceiling.queue_free()
	capsule.height = 1.6
	collider.position.y = .8
	await frames()
	collider.disabled = true
	check(horse.dismount_position(avatar) == null, "disabled walking hull cannot authorize a dismount")
	check(horse.dismount_position(avatar, true) is Vector3, "explicit seated adapter can qualify its retained disabled walking hull")
	var seated_blocker := box(world, Vector3(0, .8, .25), Vector3(.2, .5, .2))
	await frames()
	check(horse.dismount_position(avatar, true) == null, "retained disabled hull still refuses an intersecting seated transfer")
	seated_blocker.queue_free()
	await frames()
	collider.disabled = false
	collider.shape = null
	check(horse.dismount_position(avatar) == null, "missing walking shape cannot authorize a dismount")
	collider.shape = capsule
	collider.name = "UnavailableWalkingHull"
	check(horse.dismount_position(avatar) == null, "missing walking collider cannot authorize a dismount")
	collider.name = "CollisionShape3D"
	await frames()
	check(horse.dismount_position(avatar) is Vector3, "restoring the retained hull restores flat-ground dismount admission")
	world.queue_free()
	await frames()

func _run() -> void:
	for degrees in [0.0, 20.0, 30.0, 35.0, 39.0, 41.0, 50.0]:
		await _ramp(degrees)
	await _ramp(0.0, true)
	await _ramp(35.0, true)
	await _hull_integrity()
	print("DISMOUNT_CLEARANCE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
