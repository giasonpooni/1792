# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Authored ramp diagnostics with the shared bodies; no played-route claim.
const Horse := preload("res://mounts/horse.tscn")
const Player := preload("res://player/player.tscn")
const CAMERA_AT := Vector3(8.4, 5.8, 9.5)
const CAMERA_TARGET := Vector3(0.7, 1.0, 0.0)
var failed := 0
var output := ""
var records: Array[Dictionary] = []
var stage: Node3D
var camera: Camera3D
var caption: Label

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("DISMOUNT_CLEARANCE_RENDER: " + message)

func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func point(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw

func material(color: String) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color(color)
	surface.roughness = 0.9
	return surface

func observation(horse: CharacterBody3D, avatar: CharacterBody3D) -> Dictionary:
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	return {"horse_pose":horse.global_transform, "avatar_pose":avatar.global_transform,
		"horse_velocity":horse.velocity, "avatar_velocity":avatar.velocity,
		"horse_speed":horse.speed, "horse_stride":horse._stride,
		"horse_mask":horse.collision_mask, "avatar_mask":avatar.collision_mask,
		"horse_layer":horse.collision_layer, "avatar_layer":avatar.collision_layer,
		"avatar_shape":collider.shape.get_instance_id(), "avatar_child_transform":collider.transform,
		"horse_shape":horse.get_node("Hull").shape.get_instance_id()}

func plane_clearance(avatar: CharacterBody3D, normal: Vector3) -> float:
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	var capsule: CapsuleShape3D = collider.shape
	return collider.global_position.dot(normal) - capsule.radius - (capsule.height * 0.5 - capsule.radius) * normal.y

func capture(id: String, degrees: float, expected_clear: bool) -> void:
	var fixture := Node3D.new()
	fixture.name = "AuthoredDismountRamp"
	stage.add_child(fixture)
	var angle := deg_to_rad(degrees)
	var normal := Vector3(0, cos(angle), sin(angle))
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.1 / cos(angle)
	floor_body.rotation.x = angle
	var geometry := BoxShape3D.new()
	geometry.size = Vector3(14, 0.2, 14)
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = geometry
	floor_body.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = geometry.size
	floor_mesh.mesh = floor_box
	floor_mesh.material_override = material("968873")
	floor_body.add_child(floor_mesh)
	fixture.add_child(floor_body)
	var horse: CharacterBody3D = Horse.instantiate()
	horse.position.y = 0.8 * (1.0 / cos(angle) - 1.0) + 0.02
	fixture.add_child(horse)
	var avatar: CharacterBody3D = Player.instantiate()
	avatar.position = horse.position
	fixture.add_child(avatar)
	avatar.input_enabled = false
	# Disable callbacks, preserving registration of both real collision bodies.
	for node in fixture.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)
	avatar.collision_layer = 0
	avatar.collision_mask = 0
	avatar.get_node("MeshInstance3D").material_override = material("50c9bf")
	camera.make_current()
	await frames()
	var before := observation(horse, avatar)
	var landing: Variant = horse.dismount_position(avatar)
	var query_read_only: bool = observation(horse, avatar) == before
	var clear: bool = landing is Vector3
	check(query_read_only, id + " query preserves observed physical state")
	check(clear == expected_clear, id + " expected clearance result")
	var candidate_clearance: Variant = null
	var settled_clearance: Variant = null
	var maximum_rise := 0.0
	var grounded := false
	var floor_angle: Variant = null
	if clear:
		# Explicit diagnostic transfer; then the unchanged walking motor settles.
		avatar.global_position = landing
		avatar.collision_mask = 1
		avatar.collision_layer = 1
		avatar.velocity = Vector3.ZERO
		candidate_clearance = plane_clearance(avatar, normal)
		check(candidate_clearance >= -0.0002, id + " candidate does not penetrate the plane")
		for _i in range(45):
			await physics_frame
			check(avatar.step_motion(1.0 / 60.0, Vector2.ZERO, false).is_empty(), id + " shared walking step accepted")
			maximum_rise = maxf(maximum_rise, avatar.global_position.y - landing.y)
		grounded = avatar.is_on_floor()
		settled_clearance = plane_clearance(avatar, normal)
		floor_angle = rad_to_deg(avatar.get_floor_angle()) if grounded else null
		check(grounded, id + " actual walking motor settles grounded")
		check(settled_clearance >= -0.0002, id + " settled hull does not penetrate the plane")
		check(maximum_rise < 0.001, id + " no upward depenetration jump")
		check(grounded and absf(floor_angle - degrees) < 0.02, id + " actual floor angle matches ramp")
	else:
		check(observation(horse, avatar) == before, id + " refusal leaves both bodies unchanged")
	caption.text = "1792 / DISMOUNT CLEARANCE / %.0f° RAMP\n" % degrees
	caption.text += "EXIT ACCEPTED  •  shared walking motor settled grounded" if clear else "EXIT REFUSED  •  exceeds retained 40° horse slope limit"
	caption.text += "\nDiagnostic ramp • authored geometry • shared game bodies"
	var frozen := observation(horse, avatar)
	await frames(2)
	check(observation(horse, avatar) == frozen, id + " capture preserves frozen physical state")
	var pixels := root.get_texture().get_image()
	if pixels == null or pixels.is_empty():
		check(false, id + " nonempty frame")
		fixture.queue_free()
		await frames()
		return
	pixels.convert(Image.FORMAT_RGBA8)
	var filename := id + ".png"
	check(pixels.get_size() == Vector2i(1280, 720), id + " image dimensions")
	check(pixels.save_png(output.path_join(filename)) == OK, id + " image written")
	records.append({"id":id,"file":filename,"png_sha256":FileAccess.get_sha256(output.path_join(filename)),
		"rgba_sha256":digest(pixels.get_data()),"width":pixels.get_width(),"height":pixels.get_height(),
		"camera_position":point(CAMERA_AT),"camera_target":point(CAMERA_TARGET),"camera_fov":camera.fov,
		"camera_kind":"diagnostic_inspection","angle_degrees":degrees,"plane_normal":point(normal),
		"query_clear":clear,"expected_clear":expected_clear,"query_read_only":query_read_only,
		"landing":point(landing) if clear else null,"candidate_plane_clearance_m":candidate_clearance,
		"settled_grounded":grounded,"settled_plane_clearance_m":settled_clearance,"settled_floor_angle_degrees":floor_angle,
		"max_upward_correction":maximum_rise,"walking_motor_steps":45 if clear else 0,
		"horse_feet":point(horse.global_position),"avatar_feet":point(avatar.global_position),
		"transfer_kind":"explicit_diagnostic" if clear else "none","historical_geometry":false})
	fixture.queue_free()
	await frames()

func run() -> void:
	output = OS.get_environment("DISMOUNT_CAPTURE_OUTPUT")
	if output.is_empty():
		check(false, "DISMOUNT_CAPTURE_OUTPUT is required")
		quit(2)
		return
	check(not OS.get_environment("DISMOUNT_EXECUTION_ID").is_empty(), "execution identity supplied")
	check(DirAccess.make_dir_recursive_absolute(output) == OK, "output directory available")
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("263845")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e5eced")
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-55, -30, 0)
	sunlight.light_energy = 1.2
	sunlight.shadow_enabled = true
	stage.add_child(sunlight)
	camera = Camera3D.new()
	camera.position = CAMERA_AT
	camera.fov = 44
	stage.add_child(camera)
	camera.look_at(CAMERA_TARGET)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	var panel := ColorRect.new()
	panel.color = Color("192831")
	panel.size = Vector2(1280, 116)
	overlay.add_child(panel)
	caption = Label.new()
	caption.position = Vector2(28, 18)
	caption.add_theme_font_size_override("font_size", 23)
	caption.add_theme_color_override("font_color", Color("f0e8d7"))
	overlay.add_child(caption)
	await capture("flat-ground", 0.0, true)
	await capture("slope-35", 35.0, true)
	await capture("steep-45", 45.0, false)
	check(records.size() == 3, "exactly three captures")
	var hashes := {}
	for path in ["mounts/horse.gd", "mounts/horse.tscn", "mounts/horse_visual.gd", "player/player.gd", "player/player.tscn", "player/locomotion_rules.gd", "tests/render_dismount_clearance.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var file := FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	check(file != null, "capture manifest writable")
	if file:
		file.store_string(JSON.stringify({"schema":"1792.dismount-clearance-captures.v1",
			"operation_id":"1792.dismount-clearance-diagnostic.v1","execution_id":OS.get_environment("DISMOUNT_EXECUTION_ID"),
			"source_commit":OS.get_environment("DISMOUNT_SOURCE_COMMIT"),"source_hashes":hashes,
			"captures":records,"failures":failed,"engine":Engine.get_version_info().string,
			"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
			"historical_authentication":false,"played_route_claim":false,"hardware_performance_qualified":false},"\t",true,true))
		file.close()
	print("DISMOUNT_CLEARANCE_RENDER: %d captures; %d failures" % [records.size(), failed])
	stage.queue_free()
	overlay.queue_free()
	await process_frame
	quit(1 if failed else 0)
