# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Three explicit Home physics fixtures, not a played route or historical geometry.
const Launch := preload("res://childhood/home_launch.gd")
const RidingFixture := preload("res://tests/test_riding_training.gd")
const CAMERA_AT := Vector3(13.8, 3.0, -1.4)
const CAMERA_TARGET := Vector3(8.85, 1.25, -5.0)
var failed := 0
var records: Array[Dictionary] = []
var output := ""
var home: Node3D
var chapter: Node3D
var camera: Camera3D
var caption: Label
var fixtures: Array[StaticBody3D] = []

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("MOUNT_CLEARANCE_RENDER: " + message)

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

func freeze_home() -> void:
	# Disable scripted motion, not Node.process_mode: bodies must stay registered.
	home.set_process(false)
	home.set_physics_process(false)
	for node in home.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)
		if node is CanvasLayer or node is Label3D: node.hide()

func observation() -> Dictionary:
	return {"avatar_pose":chapter.avatar.global_transform,
		"horse_pose":chapter.horse.global_transform,
		"avatar_velocity":chapter.avatar.velocity,
		"horse_velocity":chapter.horse.velocity,
		"horse_speed":chapter.horse.speed,
		"horse_stride":chapter.horse._stride,
		"avatar_layer":chapter.avatar.collision_layer,
		"avatar_mask":chapter.avatar.collision_mask,
		"horse_layer":chapter.horse.collision_layer,
		"horse_mask":chapter.horse.collision_mask,
		"avatar_shape":chapter.avatar.get_node("CollisionShape3D").shape.get_instance_id(),
		"horse_shape":chapter.horse.get_node("Hull").shape.get_instance_id()}

func box(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "DiagnosticMountBlocker%d" % fixtures.size()
	body.position = at
	body.set_meta("classification", "diagnostic-fixture-not-historical-geometry")
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ac6144")
	material.roughness = 0.9
	visual.material_override = material
	body.add_child(visual)
	home.add_child(body)
	fixtures.append(body)

func centre_ray_clear() -> bool:
	var ray := PhysicsRayQueryParameters3D.create(chapter.avatar.global_position + Vector3.UP,
		chapter.horse.global_position + Vector3.UP * 1.4, chapter.avatar.collision_mask,
		[chapter.avatar.get_rid(), chapter.horse.get_rid()])
	return chapter.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func install_fixture(id: String) -> void:
	for body in fixtures: body.queue_free()
	fixtures.clear()
	await frames()
	var seed := RidingFixture.legacy_riding_seed()
	seed.player.position = [9.8, 0.14, -5.0]
	seed.actors.ranjit_singh.position = seed.player.position.duplicate()
	check(chapter.model.restore(seed).is_empty(), "legacy riding fixture restores: " + id)
	chapter._apply()
	chapter.avatar.pivot.rotation = Vector3(-0.2, PI / 2.0, 0)
	chapter.art.sample(int(chapter.model.progress().tick))
	freeze_home()
	if id == "narrow-gap":
		for z in [-0.30, 0.30]: box(Vector3(8.95, 1.5, -5.0 + z), Vector3(0.2, 3.0, 0.3))
	elif id == "low-barrier":
		box(Vector3(8.95, 0.35, -5.0), Vector3(0.2, 0.7, 3.0))
	camera.position = CAMERA_AT
	camera.look_at(CAMERA_TARGET)
	camera.make_current()
	await frames()
	check(chapter.horse.global_position.is_equal_approx(Vector3(8, 0.14, -5)), "declared horse fixture pose: " + id)
	check(chapter.avatar.global_position.is_equal_approx(Vector3(9.8, 0.14, -5)), "declared avatar fixture pose: " + id)

func capture(id: String, title: String, expected_clear: bool) -> void:
	await install_fixture(id)
	var state_before: Dictionary = chapter.model.snapshot()
	var physical_before := observation()
	var query_clear: bool = chapter.horse.clear_mount_path(chapter.avatar)
	var ray_clear := centre_ray_clear()
	check(ray_clear, "elevated centre ray remains clear: " + id)
	check(query_clear == expected_clear, "actual body query has expected result: " + id)
	check(chapter.model.snapshot() == state_before and observation() == physical_before, "query is read-only: " + id)
	caption.text = "1792 / MOUNT CLEARANCE / " + title + "\n" + \
		("BODY QUERY: CLEAR" if query_clear else "BODY QUERY: REFUSED") + \
		"  |  elevated centre ray: " + ("clear" if ray_clear else "blocked") + \
		"\nDiagnostic fixture; not historical geometry. Before mount transfer."
	await frames(2)
	check(chapter.model.snapshot() == state_before and observation() == physical_before, "capture preserves frozen state: " + id)
	var pixels := root.get_texture().get_image()
	if pixels == null or pixels.is_empty():
		check(false, "nonempty capture: " + id)
		return
	pixels.convert(Image.FORMAT_RGBA8)
	check(pixels.get_width() == 1280 and pixels.get_height() == 720, "capture dimensions: " + id)
	var filename := id + ".png"
	check(pixels.save_png(output.path_join(filename)) == OK, "write capture: " + id)
	# Execute the actual transfer after capture, so the clear image shows both bodies.
	chapter._toggle_mount()
	var mounted: bool = chapter.model.mounted()
	var state_unchanged: bool = chapter.model.snapshot() == state_before
	var physical_unchanged: bool = observation() == physical_before
	check(mounted == expected_clear, "actual Home mount action result: " + id)
	if not expected_clear:
		check(state_unchanged, "refusal preserves full authoritative state: " + id)
		check(physical_unchanged, "refusal preserves both physical poses: " + id)
	else:
		check(chapter.avatar.global_position == chapter.horse.global_position, "clear transfer uses the horse position")
		check(not chapter.avatar.is_physics_processing(), "clear transfer retains one mounted motion owner")
	check(chapter.model.progress().tick == state_before.childhood.tick, "mount action does not advance the clock: " + id)
	freeze_home()
	records.append({"id":id,"file":filename,"png_sha256":FileAccess.get_sha256(output.path_join(filename)),
		"rgba_sha256":digest(pixels.get_data()),"width":pixels.get_width(),"height":pixels.get_height(),
		"camera_position":point(CAMERA_AT),"camera_target":point(CAMERA_TARGET),"camera_fov":camera.fov,
		"camera_kind":"diagnostic_inspection","capture_timing":"before_mount_action",
		"avatar_feet_before":[9.8,0.14,-5.0],"horse_feet_before":[8.0,0.14,-5.0],
		"query_clear":query_clear,"expected_clear":expected_clear,"elevated_ray_clear":ray_clear,
		"action_mounted":mounted,"action_state_unchanged":state_unchanged,"action_physical_unchanged":physical_unchanged,
		"state_before_sha256":digest(JSON.stringify(state_before,"",true,true).to_utf8_buffer()),
		"state_after_sha256":digest(JSON.stringify(chapter.model.snapshot(),"",true,true).to_utf8_buffer()),
		"tick_before":state_before.childhood.tick,"tick_after":chapter.model.progress().tick,
		"fixture_collision_bodies":fixtures.size(),"historical_geometry":false})

func run() -> void:
	output = OS.get_environment("MOUNT_CAPTURE_OUTPUT")
	if output.is_empty():
		check(false, "MOUNT_CAPTURE_OUTPUT is required")
		quit(2)
		return
	check(not OS.get_environment("MOUNT_EXECUTION_ID").is_empty(), "execution identity supplied")
	check(DirAccess.make_dir_recursive_absolute(output) == OK, "output directory available")
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	home = Launch.make_world()
	chapter = home.get_node("ChildhoodChapter")
	chapter.save_path = output.path_join("unwritten-diagnostic-save.json")
	root.add_child(home)
	await frames(6)
	freeze_home()
	chapter.art.set_preset("daylight")
	camera = Camera3D.new()
	camera.fov = 45.0
	camera.far = 230.0
	home.add_child(camera)
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color("fff6e6"))
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(caption)
	await capture("narrow-gap", "0.30 m POST GAP", false)
	await capture("low-barrier", "0.70 m SOLID BARRIER", false)
	await capture("clear-approach", "CLEAR APPROACH", true)
	check(records.size() == 3, "exactly three captures")
	check(not FileAccess.file_exists(chapter.save_path), "diagnostic did not write a campaign save")
	var file := FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	check(file != null, "capture manifest writable")
	if file:
		file.store_string(JSON.stringify({"schema":"1792.mount-clearance-captures.v1",
			"operation_id":"1792.mount-clearance-diagnostic.v1",
			"execution_id":OS.get_environment("MOUNT_EXECUTION_ID"),
			"source_commit":OS.get_environment("MOUNT_SOURCE_COMMIT"),
			"source_hashes":{"mount_adapter":FileAccess.get_sha256("res://mounts/horse.gd"),
				"capture_script":FileAccess.get_sha256("res://tests/render_mount_clearance.gd")},
			"captures":records,"failures":failed,"engine":Engine.get_version_info().string,
			"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
			"historical_authentication":false,"played_route_claim":false,"hardware_performance_qualified":false},"\t",true,true))
		file.close()
	print("MOUNT_CLEARANCE_RENDER: %d captures; %d failures" % [records.size(), failed])
	home.queue_free()
	overlay.queue_free()
	await process_frame
	quit(1 if failed else 0)
