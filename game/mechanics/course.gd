# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Developer fixture using the actual game Player scene and motor, not a second controller.
const Player := preload("res://player/player.tscn")
const Motion := preload("res://player/locomotion_rules.gd")
const LayoutPath := "res://mechanics/course_layout.json"
const SAVE := "user://1792-locomotion-course-v1.json"
var avatar: CharacterBody3D
var tick := 0
var paused := false
var message := "Follow the central lane: vault, mantle, jump the gap, then walk through the exit gate."
var hud: Label
var status: Label
var samples: Array=[]
var save_path := SAVE

func layout() -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(LayoutPath))
func geometry_digest() -> String:
	return (FileAccess.get_file_as_string(LayoutPath)+FileAccess.get_file_as_string("res://mechanics/course.gd")).sha256_text()
func motor_digest() -> String:
	var text: String=""
	for path in ["res://player/player.gd","res://player/locomotion_rules.gd","res://player/traversal_probe.gd","res://player/player.tscn"]: text+=FileAccess.get_file_as_string(path)
	return (text+JSON.stringify([avatar.movement_profile,avatar.traversal_enabled,avatar.walk_speed,avatar.run_speed,avatar.acceleration,avatar.gravity_strength,avatar.floor_max_angle,avatar.floor_snap_length])).sha256_text()

func _ready() -> void:
	process_physics_priority=1 # Observe after the shared Player motor at priority zero.
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("87969f")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e0e6e8");env.ambient_light_energy=0.3
	environment.environment=env;add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-25,0);sun.light_energy=0.8;sun.shadow_enabled=true;add_child(sun)
	for item in layout().boxes: build_box(item)
	label("01   LOW VAULT  [V]",Vector3(0,2.2,0))
	label("02   MANTLE  [V]",Vector3(3,3.2,-5))
	label("03   2.5 m GAP  [SPACE]",Vector3(-3,3.5,-10))
	label("04   EXIT",Vector3(0,4.2,-18))
	label("LOW CEILING",Vector3(-9,2.8,3))
	label("UNMARKED / TOO HIGH",Vector3(9,3.2,4))
	label("30 DEGREE SLOPE",Vector3(9,3.6,-5))
	avatar=Player.instantiate();avatar.name="Player";avatar.movement_profile=1;avatar.traversal_enabled=true;avatar.gamepad_camera=true;avatar.menu_shortcut=false
	add_child(avatar);avatar.get_node("HomeIdentity").hide()
	avatar.get_node("MeshInstance3D").hide()
	var proxy:=preload("res://player/locomotion_proxy.gd").new();proxy.name="LocomotionProxy";avatar.add_child(proxy)
	# Test the same retained spring-arm camera. No extra per-frame camera executor.
	var camera_hull:=SphereShape3D.new();camera_hull.radius=0.18
	avatar.get_node("CameraPivot/SpringArm3D").shape=camera_hull
	var canvas:=CanvasLayer.new();add_child(canvas)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);panel.offset_left=14;panel.offset_right=-14;panel.offset_top=12
	canvas.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	panel.add_child(margin)
	hud=Label.new();hud.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hud.add_theme_font_size_override("font_size",18);margin.add_child(hud)
	var bottom:=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left=14;bottom.offset_right=-14;bottom.offset_top=-80;bottom.offset_bottom=-12;canvas.add_child(bottom)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",17);bottom.add_child(status)
	reset_course()

func build_box(item: Dictionary) -> StaticBody3D:
	var body:=StaticBody3D.new();body.name=item.id;body.position=Motion.point(item.at)
	body.rotation.x=deg_to_rad(item.get("rotate_x_degrees",0));body.set_meta("traversable",item.traversable)
	var shape:=BoxShape3D.new();shape.size=Motion.point(item.size)
	var collider:=CollisionShape3D.new();collider.shape=shape;body.add_child(collider)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=shape.size;mesh.mesh=box
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("c8b88a") if item.traversable else Color("697983")
	mat.roughness=0.95;mesh.material_override=mat;body.add_child(mesh);add_child(body);return body

func label(text: String,at: Vector3) -> void:
	var node:=Label3D.new();node.text=text;node.position=at;node.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	node.font_size=32;node.pixel_size=0.008;node.modulate=Color("f8f4e7");add_child(node)

func reset_course() -> void:
	avatar._route.clear();avatar.global_position=Motion.point(layout().spawn);avatar.velocity=Vector3.ZERO
	avatar._grounded=false;avatar._coyote=0;avatar._buffer=0;avatar.clear_motion_requests()
	avatar.pivot.rotation=Vector3(-0.2094395,0,0);avatar.motion_mode_name="air";avatar.last_motion_event=""
	tick=0;samples.clear();set_paused(false);message="New practice run. No campaign progress or story save is changed."

func set_paused(value: bool) -> void:
	paused=value;avatar.input_enabled=not value;avatar.set_physics_process(not value);avatar.clear_motion_requests()
	avatar.get_node("LocomotionProxy").set_process(not value)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index==6: set_paused(not paused);get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE: set_paused(not paused)
		KEY_R: reset_course()
		KEY_F5: message=save_course()
		KEY_F9: message=load_course()
		KEY_F1: get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_: return
	get_viewport().set_input_as_handled();refresh()

func _physics_process(_delta: float) -> void:
	if paused: return
	tick+=1
	if not avatar.last_motion_event.is_empty(): message={"land":"Landed. Follow the gold obstacles toward the exit.","jump":"Airborne. Preserve enough run-up to cross the gap.","traversal_complete":"Obstacle cleared. Continue to the next station."}.get(avatar.last_motion_event,avatar.last_motion_event)
	samples.append({"tick":tick,"position":Motion.array(avatar.global_position),"velocity":Motion.array(avatar.velocity),"mode":avatar.motion_mode_name,"event":avatar.last_motion_event})
	if samples.size()>4096: samples.pop_front()
	if avatar.global_position.y < -5: reset_course();message="Outside the course. Practice reset; campaign saves remain untouched."
	refresh()

func refresh() -> void:
	if not is_instance_valid(hud): return
	var speed:=Vector2(avatar.velocity.x,avatar.velocity.z).length()
	hud.text="1792  /  MOVEMENT QUALIFICATION  /  NOT A STORY CHAPTER\nWASD or left stick · Shift / L3 run · Mouse / right stick look · Space / A jump · V / X vault or mantle\nEsc / Start pause · R reset · F5/F9 course save/load · F1 menu"
	status.text=("PAUSED  |  " if paused else "")+"%s  |  %.2f m/s  |  height %.2f m  |  tick %d\n%s"%[avatar.motion_mode_name.to_upper(),speed,avatar.global_position.y,tick,message]

func snapshot() -> Dictionary:
	var motion: Dictionary=avatar.capture_motion()
	if motion.has("error"): return motion
	return {"schema":"locomotion-course-save.v1","course_id":"locomotion-course.v1","geometry_digest":geometry_digest(),"motor_digest":motor_digest(),"physics_hz":60,"tick":tick,"motion":motion}

func validate(s: Variant) -> String:
	if not s is Dictionary or s.size()!=7: return "Malformed course save."
	for key in ["schema","course_id","geometry_digest","motor_digest","physics_hz","tick","motion"]:
		if not s.has(key): return "Missing course field."
	if s.schema!="locomotion-course-save.v1" or s.course_id!="locomotion-course.v1" or s.geometry_digest!=geometry_digest() or s.motor_digest!=motor_digest(): return "This save belongs to another course or motor revision."
	if s.physics_hz!=60 or Engine.physics_ticks_per_second!=60 or not Motion.finite(s.tick) or s.tick<0 or s.tick>10000000 or s.tick!=floor(s.tick): return "Invalid course timing."
	var error:=Motion.validate_snapshot(s.motion)
	if not error.is_empty(): return error
	var p:=Motion.point(s.motion.position)
	if absf(p.x)>18 or p.z < -29 or p.z>13 or p.y < -2.1 or p.y>5: return "Saved position is outside the course."
	return avatar.motion_fits(s.motion)

func restore(s: Variant) -> String:
	var error:=validate(s)
	if not error.is_empty(): return error
	# Validate everything before replacing either the body or course observation time.
	error=avatar.restore_motion(s.motion)
	if not error.is_empty(): return error
	tick=int(s.tick);samples.clear();return ""

func save_course() -> String:
	var s:=snapshot()
	if s.has("error"): return s.error
	var error:=validate(s)
	if not error.is_empty(): return error
	var file:=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null: return "Cannot create course save."
	file.store_string(JSON.stringify(s));file.flush();var write_error:=file.get_error();file.close()
	if write_error!=OK: return "Course save write failed; previous save retained."
	var replaced:=DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	return "Course motion saved, including airborne velocity." if replaced==OK else "Cannot replace course save; previous save retained."

func load_course() -> String:
	var file:=FileAccess.open(save_path,FileAccess.READ)
	if file==null: return "No course save at this slot."
	if file.get_length()>8192: file.close();return "Oversized course save refused."
	var candidate: Variant=JSON.parse_string(file.get_as_text());file.close()
	var error:=restore(candidate)
	return "Course motion restored; campaign state was not loaded or changed." if error.is_empty() else error
