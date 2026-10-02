# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends CharacterBody3D
## One shared motor: campaign ground movement and opt-in traversal qualification.
const Motion := preload("res://player/locomotion_rules.gd")
const Traversal := preload("res://player/traversal_probe.gd")
const GroundContact := preload("res://player/ground_contact.gd")

@export var walk_speed := 4.5
@export var run_speed := 7.5
@export var acceleration := 18.0
@export var gravity_strength := 22.0
@export var mouse_sensitivity := 0.0025
@export var menu_shortcut := true
@export_enum("Legacy ground", "Isotropic v1") var movement_profile := 0
@export var traversal_enabled := false # Campaign saves remain grounded until migrated.
@export var gamepad_camera := false # Enabled in the course; campaign UI not yet gamepad-qualified.
@export var ground_contact_enabled := false # New static stairs stay opt-in until campaign-qualified.
@export_range(0.0,0.30,0.01) var step_height := 0.30
var last_ground_event := ""
var last_ground_rise := 0.0
var last_ground_displacement := Vector3.ZERO # Total observed tick travel, distinct from drive velocity.
var motion_mode_name := "ground"
var last_motion_event := ""
var last_traversal_kind := ""
var contact_target := Vector3.ZERO
var _coyote := 0.0
var _buffer := 0.0
var _jump_requested := false
var _vault_requested := false
var _route: Array[Vector3]=[]
var _route_index := 0
var _surface: StaticBody3D
var _surface_transform := Transform3D.IDENTITY
var _grounded := false
var _ground_step: Dictionary={} # At most one second; never serialized as ordinary motion.
var _focused := true
var input_enabled := true
var external_speed_limit := INF # Optional game-owned load constraint; no default change.
@onready var pivot: Node3D = $CameraPivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())
	if ground_contact_enabled:
		floor_snap_length=clampf(step_height,0.0,GroundContact.MAX_STEP)
		floor_stop_on_slope=true;floor_constant_speed=true

func ground_profile() -> Dictionary:
	var shape: CollisionShape3D=get_node_or_null("CollisionShape3D")
	var hull: Dictionary={}
	if shape!=null:
		var t: Transform3D=shape.transform
		hull={"local_transform":[Motion.array(t.basis.x),Motion.array(t.basis.y),Motion.array(t.basis.z),Motion.array(t.origin)],"disabled":shape.disabled}
		if shape.shape is CapsuleShape3D: hull.merge({"radius":shape.shape.radius,"height":shape.shape.height,"margin":shape.shape.margin,"custom_solver_bias":shape.shape.custom_solver_bias})
	return {"schema":GroundContact.VERSION,"enabled":ground_contact_enabled,"step_height":step_height,
		"floor_max_angle":floor_max_angle,"floor_snap_length":floor_snap_length,
		"floor_stop_on_slope":floor_stop_on_slope,"floor_constant_speed":floor_constant_speed,
		"up_direction":Motion.array(up_direction),"collision_mask":collision_mask,"safe_margin":safe_margin,"capsule":hull,
		"continuation_seconds":GroundContact.CONTINUATION_SECONDS}

func ground_contact_active() -> bool:
	return not _ground_step.is_empty()

func clear_ground_contact() -> void:
	_ground_step.clear();last_ground_event="";last_ground_rise=0.0;last_ground_displacement=Vector3.ZERO

func _slide_ground_observed(on_floor: bool) -> void:
	if not ground_contact_enabled or on_floor:
		move_and_slide();return
	# Native floor history is not part of the saved motion model. Airborne motion
	# must not inherit a previous pose's snap or floor-speed correction on restore.
	var snap:=floor_snap_length
	var constant_speed:=floor_constant_speed
	floor_snap_length=0.0;floor_constant_speed=false
	move_and_slide()
	floor_snap_length=snap;floor_constant_speed=constant_speed

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused=false;clear_motion_requests()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused=true

func clear_motion_requests() -> void:
	_jump_requested=false;_vault_requested=false

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if traversal_enabled:
		if event.is_action_pressed("traverse_jump") and not event.is_echo(): _jump_requested=true
		if event.is_action_pressed("traverse_obstacle") and not event.is_echo(): _vault_requested=true
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y = wrapf(pivot.rotation.y-event.relative.x*mouse_sensitivity,-PI,PI)
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -0.9, 0.5)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_F1 and menu_shortcut:
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var stick:=Input.get_vector("move_left","move_right","move_forward","move_backward") if input_enabled and _focused else Vector2.ZERO
	if gamepad_camera and input_enabled and _focused:
		var look:=Input.get_vector("look_left","look_right","look_up","look_down")
		pivot.rotation.y=wrapf(pivot.rotation.y-look.x*2.3*delta,-PI,PI)
		pivot.rotation.x=clampf(pivot.rotation.x-look.y*1.8*delta,-0.9,0.5)
	step_motion(delta,stick,Input.is_action_pressed("sprint"),_jump_requested,_vault_requested)
	clear_motion_requests()

func step_motion(delta: float,stick: Vector2,sprint: bool,jump: bool=false,obstacle: bool=false) -> String:
	# The course and headless tests call the same implementation, once per physics tick.
	if not is_finite(delta) or delta<=0 or delta>0.1 or not stick.is_finite(): return "Invalid motion input."
	if ground_contact_enabled:
		var ground_error:=GroundContact.profile_error(self,step_height)
		if not ground_error.is_empty(): return ground_error
	last_motion_event=""
	last_ground_event="";last_ground_rise=0.0;last_ground_displacement=Vector3.ZERO
	if not _focused: stick=Vector2.ZERO;jump=false;obstacle=false
	if not input_enabled: stick=Vector2.ZERO;jump=false;obstacle=false
	if not _route.is_empty(): return _step_traversal(delta)
	var on_floor: bool=is_on_floor() if not traversal_enabled and not ground_contact_enabled else _grounded
	if traversal_enabled:
		_coyote=Motion.COYOTE_SECONDS if on_floor else maxf(0,_coyote-delta)
		_buffer=Motion.BUFFER_SECONDS if jump else maxf(0,_buffer-delta)
		if obstacle and on_floor and external_speed_limit==INF:
			var admission:=Traversal.plan(self,Motion.direction(Vector2(0,-1),pivot.rotation.y))
			if admission.error.is_empty():
				_route=admission.points;_route_index=0;_surface=admission.surface
				_surface_transform=admission.surface_transform;contact_target=admission.contact
				motion_mode_name=admission.kind;last_traversal_kind=admission.kind
				velocity=Vector3.ZERO;_coyote=0;_buffer=0;_grounded=false
				return _step_traversal(delta)
			last_motion_event=admission.error
	var speed:=minf(run_speed if sprint else walk_speed,external_speed_limit)
	var heading:=Motion.direction(stick,pivot.rotation.y)
	if movement_profile==0:
		# Preserve qualified campaign response, including its axis-wise acceleration.
		# Only analog magnitude is restored; fully pressed legacy keys are unchanged.
		heading=pivot.global_basis.x*stick.x+pivot.global_basis.z*stick.y
		heading.y=0;heading=heading.normalized()*minf(stick.length(),1.0)
	var target:=heading*speed
	if not _ground_step.is_empty() and (not ground_contact_enabled or heading.length()<GroundContact.EPSILON or heading.normalized().dot(_ground_step.direction)<0.95 or jump or obstacle):
		_ground_step.clear()
	var rate: float=Motion.AIR_ACCELERATION if traversal_enabled and not on_floor else acceleration
	var lateral:=Motion.horizontal(velocity,target,rate,delta)
	if movement_profile==0:
		lateral=Vector3(move_toward(velocity.x,target.x,rate*delta),0,move_toward(velocity.z,target.z,rate*delta))
	velocity.x=lateral.x;velocity.z=lateral.z
	if traversal_enabled:
		if _buffer>0 and _coyote>0 and external_speed_limit==INF:
			velocity.y=Motion.JUMP_SPEED;_buffer=0;_coyote=0;on_floor=false;last_motion_event="jump"
		velocity.y=-0.01 if on_floor else maxf(-Motion.MAX_FALL,velocity.y-gravity_strength*delta)
	else:
		velocity.y=0.0 if on_floor else velocity.y-gravity_strength*delta
	var before:=global_position
	var stepped:=false
	var ground_admission: Dictionary={}
	if ground_contact_enabled and (on_floor or not _ground_step.is_empty()) and velocity.dot(up_direction)<=0:
		var command:=velocity-up_direction*velocity.dot(up_direction)
		ground_admission=GroundContact.plan(self,command*delta,step_height,_ground_step,on_floor)
		stepped=GroundContact.execute(self,ground_admission)
	if stepped:
		# Lateral movement is already consumed. Establish the native floor flag without
		# spending it again, then retain the commanded lateral velocity for next tick.
		var intended:=velocity
		velocity=-up_direction*0.01;_slide_ground_observed(on_floor)
		velocity=intended-up_direction*intended.dot(up_direction)
		last_ground_rise=(global_position-before).dot(up_direction);last_ground_event="step_up"
		_ground_step={} if is_on_floor() else ground_admission.continuation
		if not _ground_step.is_empty(): _ground_step.elapsed+=delta
	else:
		_ground_step.clear()
		var intended:=velocity
		_slide_ground_observed(on_floor)
		if ground_contact_enabled and on_floor:
			# A wall consumes displacement, not the commanded run-up. Otherwise the
			# engine's wall projection reduces each next stair attempt to one tiny
			# acceleration increment, which cannot reach walkable capsule support.
			velocity.x=intended.x;velocity.z=intended.z
		if ground_contact_enabled and on_floor and is_on_floor():
			var drop: float=(global_position-before).dot(up_direction)
			if drop < -0.005 and drop>=-step_height-GroundContact.EPSILON and GroundContact.has_support(self,global_transform):
				last_ground_rise=drop;last_ground_event="ground_follow"
	last_ground_displacement=global_position-before
	_grounded=is_on_floor()
	if traversal_enabled or ground_contact_enabled:
		if _grounded:
			velocity.y=0
			if not on_floor: last_motion_event="land"
		motion_mode_name="step_contact" if not _ground_step.is_empty() else ("ground" if _grounded else "air")
	return ""

func _step_traversal(delta: float) -> String:
	if not is_instance_valid(_surface) or _surface.global_transform!=_surface_transform:
		_route.clear();motion_mode_name="air";velocity=Vector3.ZERO
		last_motion_event="Traversal surface changed; movement released.";return last_motion_event
	var target: Vector3=_route[_route_index]
	var before:=global_position
	var movement:=global_position.direction_to(target)*minf(4.0*delta,global_position.distance_to(target))
	var collision:=move_and_collide(movement)
	last_ground_displacement=global_position-before
	if collision!=null:
		_route.clear();motion_mode_name="air";velocity=Vector3.ZERO
		last_motion_event="Traversal interrupted by collision.";return last_motion_event
	if global_position.distance_to(target)<0.001:
		_route_index+=1
		if _route_index==_route.size():
			_route.clear();motion_mode_name="air";velocity=Vector3.ZERO;last_motion_event="traversal_complete"
	return ""

func capture_motion() -> Dictionary:
	if ground_contact_enabled:
		var profile_error:=GroundContact.profile_error(self,step_height)
		if not profile_error.is_empty(): return {"error":profile_error}
	# A committed vault/mantle is short but has unsaved contact/path state.
	if not _route.is_empty(): return {"error":"Finish the vault or mantle before saving."}
	if not _ground_step.is_empty(): return {"error":"Finish the stair contact before saving."}
	return {"schema":Motion.VERSION,"position":Motion.array(global_position),"velocity":Motion.array(velocity),
		"grounded":_grounded,"coyote":_coyote,"buffer":_buffer,"camera":Motion.array(pivot.rotation)}

func motion_fits(s: Variant) -> String:
	var error:=Motion.validate_snapshot(s)
	if not error.is_empty(): return error
	if ground_contact_enabled:
		error=GroundContact.profile_error(self,step_height)
		if not error.is_empty(): return error
		var body:=global_transform;body.origin=Motion.point(s.position)
		var separated:=body;separated.origin+=up_direction*0.003
		if not GroundContact.clear_at(self,separated): return "Saved capsule is obstructed."
		if s.grounded and not GroundContact.has_support(self,body): return "Saved static floor is missing."
		return ""
	if not Traversal.clear_at(self,Motion.point(s.position)+Vector3.UP*0.003): return "Saved capsule is obstructed."
	if s.grounded and not Traversal.support(self,Motion.point(s.position)): return "Saved floor is missing."
	return ""

func restore_motion(s: Variant) -> String:
	var error:=motion_fits(s)
	if not error.is_empty(): return error
	global_position=Motion.point(s.position);velocity=Motion.point(s.velocity);pivot.rotation=Motion.point(s.camera)
	_grounded=s.grounded;_coyote=s.coyote;_buffer=s.buffer;_route.clear();_ground_step.clear();clear_motion_requests()
	if ground_contact_enabled and _grounded and not is_on_floor():
		# Reconstruct an engine cache from this admitted physical pose. The query's
		# internal snap cannot replace the exact serialized position or drive state.
		var retained_transform:=global_transform
		var retained_velocity:=velocity
		apply_floor_snap()
		global_transform=retained_transform;velocity=retained_velocity
	motion_mode_name="ground" if _grounded else "air";last_motion_event=""
	last_ground_event="";last_ground_rise=0.0;last_ground_displacement=Vector3.ZERO;return ""
