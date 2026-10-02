# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Isolated native ground-contact practice. The campaign Player owns all motion.
const Player := preload("res://player/player.tscn")
const Motion := preload("res://player/locomotion_rules.gd")
const Ground := preload("res://player/ground_contact.gd")
const LayoutPath := "res://mechanics/ground_course_layout.json"
const SAVE := "user://1792-ground-contact-course-v1.json"
const SOURCE_FILES := ["res://mechanics/ground_course.gd", "res://mechanics/ground_course.tscn", LayoutPath,
	"res://player/player.gd", "res://player/player.tscn", "res://player/ground_contact.gd",
	"res://player/locomotion_rules.gd", "res://player/traversal_probe.gd", "res://player/locomotion_proxy.gd"]
var avatar: CharacterBody3D
var tick := 0
var paused := false
var message := "Walk over the stairs, follow the incline, then return along the same path."
var hud: Label
var status: Label
var samples: Array = []
var save_path := SAVE

func layout() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(LayoutPath))

func source_digest() -> String:
	var source := ""
	for path in SOURCE_FILES:
		source += path + "\n" + FileAccess.get_file_as_string(path) + "\n"
	return source.sha256_text()

func _geometry(node: Node, items: Array) -> void:
	if node == avatar: return
	if node is CollisionObject3D:
		var record := {"path": str(get_path_to(node)), "type": node.get_class(),
			"transform": _transform(node.global_transform), "layer": node.collision_layer, "mask": node.collision_mask}
		if node is StaticBody3D:
			record["constant_linear_velocity"] = Motion.array(node.constant_linear_velocity)
			record["constant_angular_velocity"] = Motion.array(node.constant_angular_velocity)
		var shapes: Array = []
		for child in node.get_children():
			if child is CollisionShape3D:
				var shape: Dictionary = {"path": str(node.get_path_to(child)), "disabled": child.disabled,
					"transform": _transform(child.transform), "type": child.shape.get_class() if child.shape != null else "missing"}
				if child.shape != null:
					shape["margin"] = child.shape.margin
					shape["custom_solver_bias"] = child.shape.custom_solver_bias
				if child.shape is BoxShape3D: shape["size"] = Motion.array(child.shape.size)
				elif child.shape is CapsuleShape3D: shape["radius"] = child.shape.radius; shape["height"] = child.shape.height
				elif child.shape is SphereShape3D: shape["radius"] = child.shape.radius
				else: shape["unqualified_shape"] = true
				shapes.append(shape)
			record["shapes"] = shapes
		items.append(record)
	for child in node.get_children(): _geometry(child, items)

func _geometry_error(node: Node) -> String:
	if node == avatar: return ""
	if node is CollisionObject3D and (not node is StaticBody3D or node is AnimatableBody3D): return "Practice saves require authored static collision bodies."
	if node is CollisionObject3D and not node.global_transform.is_finite(): return "Invalid practice collision transform."
	if node is CollisionObject3D:
		# Native shape owners can also be registered without scene collider children.
		# This bounded save profile refuses any geometry outside that authored map.
		var ownership: Dictionary = {}
		for owner_id in node.get_shape_owners():
			var owner: Object = node.shape_owner_get_owner(owner_id)
			if not owner is CollisionShape3D or owner.get_parent() != node: return "Unrepresented native practice shape owner."
			if node.shape_owner_get_shape_count(owner_id) != 1 or node.shape_owner_get_shape(owner_id,0) != owner.shape: return "Unrepresented native practice shape."
			if node.shape_owner_get_transform(owner_id) != owner.transform or node.is_shape_owner_disabled(owner_id) != owner.disabled: return "Native practice shape state differs from authored collider."
			ownership[owner] = ownership.get(owner,0)+1
		for child in node.get_children():
			if child is CollisionShape3D and ownership.get(child,0) != 1: return "Authored practice collider lacks exactly one native shape owner."
	if node is PhysicsBody3D and not node.get_collision_exceptions().is_empty(): return "Practice collision exceptions are outside this save profile."
	if node is StaticBody3D and (node.constant_linear_velocity != Vector3.ZERO or node.constant_angular_velocity != Vector3.ZERO): return "Moving practice collision is outside this save profile."
	if node is CollisionShape3D and not (node.shape is BoxShape3D or node.shape is CapsuleShape3D or node.shape is SphereShape3D): return "Unsupported practice collision shape."
	if node is CollisionShape3D:
		if not node.transform.is_finite() or not node.global_basis.is_conformal(): return "Invalid practice collision shape transform."
		if not is_finite(node.shape.margin) or node.shape.margin < 0: return "Invalid practice collision shape margin."
		if not is_finite(node.shape.custom_solver_bias) or node.shape.custom_solver_bias < 0: return "Invalid practice collision solver bias."
		if node.shape is BoxShape3D and (not node.shape.size.is_finite() or minf(node.shape.size.x,minf(node.shape.size.y,node.shape.size.z)) <= 0): return "Invalid practice box dimensions."
		if node.shape is SphereShape3D and (not is_finite(node.shape.radius) or node.shape.radius <= 0): return "Invalid practice sphere dimensions."
		if node.shape is CapsuleShape3D and (not is_finite(node.shape.radius) or not is_finite(node.shape.height) or node.shape.radius <= 0 or node.shape.height < node.shape.radius*2): return "Invalid practice capsule dimensions."
	for child in node.get_children():
		var error := _geometry_error(child)
		if not error.is_empty(): return error
	return ""

func _transform(value: Transform3D) -> Array:
	return [Motion.array(value.basis.x), Motion.array(value.basis.y), Motion.array(value.basis.z), Motion.array(value.origin)]

func geometry_digest() -> String:
	var items: Array = []
	_geometry(self, items)
	return JSON.stringify(items,"",true,true).sha256_text()

func motor_digest() -> String:
	var hull: CollisionShape3D = avatar.get_node("CollisionShape3D")
	return JSON.stringify({"ground": avatar.ground_profile(), "movement_profile": avatar.movement_profile,
		"traversal": avatar.traversal_enabled, "walk": avatar.walk_speed, "run": avatar.run_speed,
		"acceleration": avatar.acceleration, "gravity": avatar.gravity_strength, "max_slides": avatar.max_slides,
		"safe_margin": avatar.safe_margin, "floor_block_on_wall": avatar.floor_block_on_wall,
		"floor_stop_on_slope": avatar.floor_stop_on_slope, "floor_constant_speed": avatar.floor_constant_speed,
		"floor_snap_length": avatar.floor_snap_length, "floor_max_angle": avatar.floor_max_angle,
		"body_basis": [Motion.array(avatar.global_basis.x), Motion.array(avatar.global_basis.y), Motion.array(avatar.global_basis.z)],
		"up_direction": Motion.array(avatar.up_direction), "wall_min_slide_angle": avatar.wall_min_slide_angle,
		"slide_on_ceiling": avatar.slide_on_ceiling, "motion_mode": avatar.motion_mode,
		"platform_floor_layers": avatar.platform_floor_layers, "platform_wall_layers": avatar.platform_wall_layers,
		"platform_on_leave": avatar.platform_on_leave, "gamepad_camera": avatar.gamepad_camera,
		"mouse_sensitivity": avatar.mouse_sensitivity, "shape_disabled": hull.disabled,
		"collision_layer": avatar.collision_layer, "collision_mask": avatar.collision_mask,
		"shape_transform": _transform(hull.transform), "radius": hull.shape.radius,
		"height": hull.shape.height, "external_speed_limit": "unlimited" if avatar.external_speed_limit == INF else avatar.external_speed_limit},"",true,true).sha256_text()

func _ready() -> void:
	process_physics_priority = 1 # Observes the Player; never advances its motor.
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("81939d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("e0e6e8"); env.ambient_light_energy = 0.45
	environment.environment = env; add_child(environment)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48,-25,0); sun.light_energy = 0.9; sun.shadow_enabled = true; add_child(sun)
	for item in layout().boxes: build_box(item)
	label("STAIRS  /  UP AND DOWN", Vector3(0,2.8,2))
	label("INCLINE  /  UP AND DOWN", Vector3(0,2.6,-2.8))
	label("RETURN", Vector3(0,2.2,-6.5))
	label("HIGH RISER", Vector3(6,2.7,3))
	label("LOW CEILING", Vector3(-6,2.7,3))
	label("CURB AND DROP", Vector3(6,1.9,-2))
	avatar = Player.instantiate(); avatar.name = "Player"
	avatar.movement_profile = 1; avatar.traversal_enabled = true; avatar.ground_contact_enabled = true
	avatar.gamepad_camera = true; avatar.menu_shortcut = false; avatar.position = Motion.point(layout().spawn)
	add_child(avatar); avatar.get_node("HomeIdentity").hide(); avatar.get_node("MeshInstance3D").hide()
	var proxy := preload("res://player/locomotion_proxy.gd").new(); proxy.name = "LocomotionProxy"; avatar.add_child(proxy)
	var camera_hull := SphereShape3D.new(); camera_hull.radius = 0.18; avatar.get_node("CameraPivot/SpringArm3D").shape = camera_hull
	var canvas := CanvasLayer.new(); add_child(canvas)
	var panel := PanelContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 14; panel.offset_right = -14; panel.offset_top = 12; canvas.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	panel.add_child(margin); hud = Label.new(); hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_theme_font_size_override("font_size",18); margin.add_child(hud)
	var bottom := PanelContainer.new(); bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 14; bottom.offset_right = -14; bottom.offset_top = -72; bottom.offset_bottom = -12; canvas.add_child(bottom)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.add_theme_font_size_override("font_size",17); bottom.add_child(status)
	refresh()

func build_box(item: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = item.id; body.position = Motion.point(item.at)
	body.rotation.x = deg_to_rad(item.get("rotate_x_degrees",0)); body.set_meta("traversable", false)
	var shape := BoxShape3D.new(); shape.size = Motion.point(item.size)
	var collider := CollisionShape3D.new(); collider.name = "CollisionShape3D"; collider.shape = shape; body.add_child(collider)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = shape.size; mesh.mesh = box
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("c6b78b") if str(item.id).begins_with("stair") or item.id == "incline" else Color("6c7e87")
	mat.roughness = 0.95; mesh.material_override = mat; body.add_child(mesh); add_child(body); return body

func label(text: String, at: Vector3) -> void:
	var node := Label3D.new(); node.text = text; node.position = at; node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.font_size = 32; node.pixel_size = 0.008; node.modulate = Color("f8f4e7"); add_child(node)

func reset_course() -> void:
	# Reset is an explicit new attempt, distinct from continuous play and load.
	avatar._route.clear(); avatar.clear_ground_contact(); avatar.global_position = Motion.point(layout().spawn); avatar.velocity = Vector3.ZERO
	avatar._grounded = false; avatar._coyote = 0; avatar._buffer = 0; avatar.clear_motion_requests()
	avatar.pivot.rotation = Vector3(-0.2094395,0,0); avatar.motion_mode_name = "air"; avatar.last_motion_event = ""
	tick = 0; samples.clear(); set_paused(false); message = "New practice attempt. Walk up the stairs and return over the incline."

func set_paused(value: bool) -> void:
	paused = value; avatar.input_enabled = not value; avatar.set_physics_process(not value); avatar.clear_motion_requests()
	avatar.get_node("LocomotionProxy").set_process(not value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED; refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START: set_paused(not paused); get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE: set_paused(not paused)
		KEY_R: reset_course()
		KEY_F5: message = save_course()
		KEY_F9: message = load_course()
		KEY_F1: get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_: return
	get_viewport().set_input_as_handled(); refresh()

func _physics_process(_delta: float) -> void:
	if paused: return
	tick += 1
	samples.append({"tick": tick, "position": Motion.array(avatar.global_position), "velocity": Motion.array(avatar.velocity),
		"grounded": avatar.is_on_floor(), "mode": avatar.motion_mode_name, "event": avatar.last_ground_event, "rise": avatar.last_ground_rise})
	if samples.size() > 4096: samples.pop_front()
	if avatar.global_position.y < -4: reset_course(); message = "Outside the practice ground. New attempt."
	refresh()

func refresh() -> void:
	if not is_instance_valid(hud): return
	hud.text = "1792  /  FOOTING PRACTICE\nWASD or left stick move · Shift / L3 run · Mouse / right stick look · Space / A jump\nEsc / Start pause · R new attempt · F5/F9 practice save/load · F1 menu"
	status.text = ("PAUSED  |  " if paused else "") + message

func snapshot() -> Dictionary:
	var geometry_error := _geometry_error(self)
	if not geometry_error.is_empty(): return {"error": geometry_error}
	var motor_error := Ground.profile_error(avatar,avatar.step_height)
	if not motor_error.is_empty(): return {"error": motor_error}
	var motion: Dictionary = avatar.capture_motion()
	if motion.has("error"): return motion
	return {"schema": "ground-contact-course-save.v1", "course_id": "ground-contact-course.v1",
		"source_digest": source_digest(), "geometry_digest": geometry_digest(), "motor_digest": motor_digest(),
		"physics_hz": 60, "tick": tick, "paused": paused, "motion": motion}

func validate(s: Variant) -> String:
	var geometry_error := _geometry_error(self)
	if not geometry_error.is_empty(): return geometry_error
	var motor_error := Ground.profile_error(avatar,avatar.step_height)
	if not motor_error.is_empty(): return motor_error
	if not s is Dictionary or s.size() != 9: return "Malformed practice save."
	for key in ["schema","course_id","source_digest","geometry_digest","motor_digest","physics_hz","tick","paused","motion"]:
		if not s.has(key): return "Missing practice field."
	if s.schema != "ground-contact-course-save.v1" or s.course_id != "ground-contact-course.v1": return "Unknown practice save."
	if s.source_digest != source_digest() or s.geometry_digest != geometry_digest() or s.motor_digest != motor_digest(): return "Practice ground or motor revision changed."
	if not s.paused is bool or not Motion.finite(s.physics_hz) or s.physics_hz != 60 or Engine.physics_ticks_per_second != 60: return "Invalid practice timing."
	if not Motion.finite(s.tick) or s.tick < 0 or s.tick > 10000000 or s.tick != floor(s.tick): return "Invalid practice time."
	var error := Motion.validate_snapshot(s.motion)
	if not error.is_empty(): return error
	var p := Motion.point(s.motion.position)
	if absf(p.x) > 14 or p.z < -12 or p.z > 12 or p.y < -3.1 or p.y > 5: return "Saved position is outside the practice ground."
	return avatar.motion_fits(s.motion)

func restore(s: Variant) -> String:
	var error := validate(s)
	if not error.is_empty(): return error
	error = avatar.restore_motion(s.motion)
	if not error.is_empty(): return error
	tick = int(s.tick); samples.clear(); set_paused(s.paused); return ""

func save_course() -> String:
	var s := snapshot()
	if s.has("error"): return s.error
	var error := validate(s)
	if not error.is_empty(): return error
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null: return "Cannot create practice save."
	file.store_string(JSON.stringify(s,"",true,true)); file.flush(); var write_error := file.get_error(); file.close()
	if write_error != OK: return "Practice write failed; previous save retained."
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	return "Practice saved." if result == OK else "Cannot replace practice save; previous save retained."

func load_course() -> String:
	var file := FileAccess.open(save_path,FileAccess.READ)
	if file == null: return "No practice save at this slot."
	if file.get_length() > 8192: file.close(); return "Oversized practice save refused."
	var candidate: Variant = JSON.parse_string(file.get_as_text()); file.close()
	var error := restore(candidate)
	return "Practice restored." if error.is_empty() else error
