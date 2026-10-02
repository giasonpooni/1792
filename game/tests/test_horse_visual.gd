extends SceneTree
## Presentation contract checks: actual geometry, contact anchors and paused poses.
const Horse := preload("res://mounts/horse.tscn")
const Rules := preload("res://mounts/riding_rules.gd")
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

func _transforms(node: Node3D) -> Array:
	var result: Array = [node.transform]
	for child in node.get_children():
		if child is Node3D:
			result.append_array(_transforms(child))
	return result

func _count_colliders(node: Node) -> int:
	var count := 1 if node is CollisionObject3D or node is CollisionShape3D else 0
	for child in node.get_children():
		count += _count_colliders(child)
	return count

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 0.2, 100)
	floor_shape.shape = shape
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var horse = Horse.instantiate()
	world.add_child(horse)
	check(horse._rider.get_child_count() == 7, "legacy rider keeps all seven indexed pieces")
	check(not horse._rider.visible, "legacy rider remains hidden until mounted")
	check(horse._legs.size() == 4, "legacy leg hooks retained")
	check(is_equal_approx(horse._hull.radius, 0.8) and is_equal_approx(horse._hull.height, 3.2), "original collision hull retained")
	var visual: Node3D = horse.get_node("HorseVisual")
	check(not visual.is_processing() and not visual.is_physics_processing(), "visual has no independent frame executor")
	check(_count_colliders(visual) == 0, "visual contributes no physics or collision nodes")
	check(_count_colliders(horse) == 2, "horse retains exactly its original body and hull")
	check(visual.has_node("Trunk/Barrel") and visual.has_node("Trunk/Shoulder") and visual.has_node("Trunk/Haunch"), "rounded body masses present")
	check(visual.has_node("NeckAndHead/Muzzle") and visual.has_node("NeckAndHead/Nostril"), "muzzle and nostril geometry present")
	check(visual.has_node("NeckAndHead/ManeLock") and visual.has_node("Tail/TailLock"), "mane and tail have rendered locks")
	for label in ["FrontLeftLeg", "HindLeftLeg", "FrontRightLeg", "HindRightLeg"]:
		var leg: Node3D = visual.get_node(label)
		var joint := "Knee" if label.begins_with("Front") else "Hock"
		check(leg.has_node(joint + "/Cannon") and leg.has_node(joint + "/Hoof/HoofMass"), label + " has articulated lower limb and hoof")
		check(leg.get_node("UpperLeg").mesh is CapsuleMesh, label + " is rounded anatomy")
	var saddle: MeshInstance3D = visual.get_node("SaddleSeat")
	var seat_top := saddle.to_global(Vector3(0, saddle.mesh.size.y * 0.5, -saddle.position.z))
	check(horse.saddle_support_point().is_equal_approx(seat_top), "support contact lies on actual rendered saddle plane")
	check(horse.saddle_support_point().is_equal_approx(horse.to_global(Vector3(0, 1.72, 0))), "established support height and center retained")
	var bridles: Array[Vector3] = horse.bridle_points_world()
	check(bridles.size() == 2 and bridles[0].distance_to(bridles[1]) > 0.4, "two separately rendered bridle anchors")
	check(bridles[0].is_equal_approx(visual.get_node("NeckAndHead/BitRing").global_position), "left anchor follows actual bit ring")
	check(bridles[1].is_equal_approx(visual.get_node("NeckAndHead/BitRing2").global_position), "right anchor follows actual bit ring")
	var empty_record: Dictionary = Rules.initial().horse
	empty_record.position = [0.0, 0.04, 0.0]
	horse.apply_record(empty_record)
	check(not horse._rider.visible, "unmounted record preserves rider visibility")
	empty_record.rider_id = "ranjit_singh"
	horse.apply_record(empty_record)
	check(horse._rider.visible, "mounted record preserves rider visibility")
	for _i in range(3):
		await physics_frame
		horse.step(1.0 / 60.0, 0.0, 0.0, false, true, true)
	var rest := _transforms(visual)
	var sample_before: float = horse._stride
	for _i in range(5):
		await physics_frame
	check(_transforms(visual) == rest and horse._stride == sample_before, "without owner step the entire horse presentation remains frozen")
	var motion: Dictionary = {}
	for _i in range(80):
		await physics_frame
		motion = horse.step(1.0 / 60.0, 1.0, 0.0, false, true, false)
	check(horse._stride > sample_before and motion.speed > 0.0, "actual motor movement supplies gait phase")
	check(_transforms(visual) != rest, "moving sample articulates the rendered anatomy")
	check(motion.keys().size() == 5 and motion.has("position") and motion.has("yaw") and motion.has("speed") and motion.has("vertical_speed") and motion.has("grounded"), "visual introduces no new motion record field")
	var moving_pose := _transforms(visual)
	var held_stride: float = horse._stride
	for _i in range(5):
		await physics_frame
	check(_transforms(visual) == moving_pose and horse._stride == held_stride, "moving pose also freezes when the owner stops stepping")
	visual.sample(horse.speed, held_stride)
	check(_transforms(visual) == moving_pose, "identical motor sample reproduces identical local transforms")
	empty_record.speed = 0.0
	horse.apply_record(empty_record)
	check(visual.get_node("Trunk").position == Vector3.ZERO and visual.get_node("NeckAndHead").rotation == Vector3.ZERO, "record restoration immediately resets moving anatomy without an extra step")
	for label in ["FrontLeftLeg", "HindLeftLeg", "FrontRightLeg", "HindRightLeg"]:
		check(visual.get_node(label).rotation == Vector3.ZERO, label + " resets on restored stopped record")
	var local_contact: Vector3 = horse.to_local(horse.saddle_support_point())
	horse.position = Vector3(5, 0.04, 3)
	horse.rotation.y = 0.8
	check(horse.to_local(horse.saddle_support_point()).is_equal_approx(local_contact), "support contact transforms with owner without changing geometry")
	var bits: Array[Vector3] = horse.bridle_points_world()
	check(bits[0].is_equal_approx(visual.get_node("NeckAndHead/BitRing").global_position), "animated transformed bridle is still a rendered contact")
	visual.sample(0.0, held_stride)
	check(visual.get_node("Trunk").position == Vector3.ZERO, "stopped motor has no autonomous body bob")
	for _i in range(5):
		await physics_frame
	check(visual.get_node("Tail").rotation == Vector3.ZERO, "stopped tail has no unowned idle timer")
	world.queue_free()
	await process_frame
	print("HORSE_VISUAL_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
