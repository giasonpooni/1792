# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends CharacterBody3D
## One shared motor: campaign ground movement and opt-in traversal qualification.
const Motion := preload("res://player/locomotion_rules.gd")
const Traversal := preload("res://player/traversal_probe.gd")
const ContactRecord := preload("res://player/traversal_record.gd")

@export var walk_speed := 4.5
@export var run_speed := 7.5
@export var acceleration := 18.0
@export var gravity_strength := 22.0
@export var mouse_sensitivity := 0.0025
@export var menu_shortcut := true
@export_enum("Legacy ground", "Isotropic v1") var movement_profile := 0
@export var traversal_enabled := false # Campaign saves remain grounded until migrated.
@export var gamepad_camera := false # Enabled in the course; campaign UI not yet gamepad-qualified.
var motion_mode_name := "ground"
var last_motion_event := ""
var last_traversal_kind := ""
var contact_target := Vector3.ZERO
var _coyote := 0.0
var _buffer := 0.0
var _jump_requested := false
var _vault_requested := false
var traversal_scope: Node # Assigned by the owning scene, never selected by save data.
var _route_record: Dictionary={}
var _route: Array[Vector3]=[]
var _route_index := 0
var _surface: StaticBody3D
var _surface_transform := Transform3D.IDENTITY
var _grounded := false
var _focused := true
var input_enabled := true
var external_speed_limit := INF # Optional game-owned load constraint; no default change.
@onready var pivot: Node3D = $CameraPivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())

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
	last_motion_event=""
	if not _focused: stick=Vector2.ZERO;jump=false;obstacle=false
	if not input_enabled: stick=Vector2.ZERO;jump=false;obstacle=false
	if not _route.is_empty(): return _step_traversal(delta)
	var on_floor: bool=is_on_floor() if not traversal_enabled else _grounded
	if traversal_enabled:
		_coyote=Motion.COYOTE_SECONDS if on_floor else maxf(0,_coyote-delta)
		_buffer=Motion.BUFFER_SECONDS if jump else maxf(0,_buffer-delta)
		if obstacle and on_floor and external_speed_limit==INF:
			var admission:=Traversal.plan(self,Motion.direction(Vector2(0,-1),pivot.rotation.y))
			if admission.error.is_empty():
				var contact_record:=ContactRecord.capture(admission)
				if not ContactRecord.bindings_fit(self,contact_record):
					last_motion_event="Traversal requires uniquely identified static supports.";return last_motion_event
				_route_record=contact_record
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
	# CharacterBody3D retains an internal previous-floor flag that is not a saved
	# gameplay state. Do not let that cache snap an explicitly airborne motor
	# after a contact path or fresh-process restore. Ground profiles are unchanged.
	var snap_length: float=floor_snap_length
	if traversal_enabled and not on_floor: floor_snap_length=0.0
	move_and_slide()
	floor_snap_length=snap_length
	_grounded=is_on_floor()
	if traversal_enabled:
		if _grounded:
			velocity.y=0
			if not on_floor: last_motion_event="land"
		motion_mode_name="ground" if _grounded else "air"
	return ""

func _step_traversal(delta: float) -> String:
	if not is_instance_valid(_surface) or _surface.global_transform!=_surface_transform or not ContactRecord.bindings_fit(self,_route_record):
		clear_traversal();motion_mode_name="air";velocity=Vector3.ZERO
		last_motion_event="Traversal surface changed; movement released.";return last_motion_event
	var target: Vector3=_route[_route_index]
	var movement:=global_position.direction_to(target)*minf(4.0*delta,global_position.distance_to(target))
	var collision:=move_and_collide(movement)
	if collision!=null:
		clear_traversal();motion_mode_name="air";velocity=Vector3.ZERO
		last_motion_event="Traversal interrupted by collision.";return last_motion_event
	if global_position.distance_to(target)<0.001:
		_route_index+=1
		if _route_index==_route.size():
			clear_traversal();motion_mode_name="air";velocity=Vector3.ZERO;last_motion_event="traversal_complete"
	return ""

func clear_traversal() -> void:
	_route.clear();_route_record.clear();_route_index=0;_surface=null
	contact_target=Vector3.ZERO;_grounded=false

func contact_frame() -> Dictionary:
	# Read-only presentation targets from the admitted support, never camera aim.
	if _route.is_empty() or not ContactRecord.bindings_fit(self,_route_record): return {}
	var forward:=Motion.point(_route_record.forward)
	var right:=forward.cross(Vector3.UP)
	var hands: Array=[]
	for side in [-1,1]:
		var p: Vector3=contact_target-forward*0.06+right*side*0.22
		var hit:=Traversal.ray(self,p+Vector3.UP*0.12,p-Vector3.UP*0.12)
		if not hit.is_empty() and hit.collider==_surface and hit.normal.y>=0.98:
			hands.append({"side":side,"target":hit.position+Vector3.UP*0.025})
	return {"kind":motion_mode_name,"forward":forward,"hands":hands,"segment":_route_index,"surface_id":_route_record.surface.id}

func capture_motion() -> Dictionary:
	var result: Dictionary={"schema":Motion.VERSION,"position":Motion.array(global_position),"velocity":Motion.array(velocity),
		"grounded":_grounded,"coyote":_coyote,"buffer":_buffer,"camera":Motion.array(pivot.rotation)}
	if not _route.is_empty():
		result.traversal=_route_record.duplicate(true);result.traversal.index=_route_index
	return result

func motion_fits(s: Variant) -> String:
	var error:=Motion.validate_snapshot(s)
	if not error.is_empty(): return error
	if not Traversal.clear_at(self,Motion.point(s.position)+Vector3.UP*0.003): return "Saved capsule is obstructed."
	if s.grounded and not Traversal.support(self,Motion.point(s.position)): return "Saved floor is missing."
	if s.has("traversal"): return ContactRecord.prepare(self,s).error
	return ""

func restore_motion(s: Variant) -> String:
	var error:=motion_fits(s)
	if not error.is_empty(): return error
	var prepared: Dictionary={}
	if s.has("traversal"):
		prepared=ContactRecord.prepare(self,s)
		if not prepared.error.is_empty(): return prepared.error
	# All validation precedes the first transform, timer or route mutation.
	clear_traversal()
	global_position=Motion.point(s.position);velocity=Motion.point(s.velocity);pivot.rotation=Motion.point(s.camera)
	_grounded=s.grounded;_coyote=s.coyote;_buffer=s.buffer;clear_motion_requests()
	motion_mode_name="ground" if _grounded else "air";last_motion_event=""
	if not prepared.is_empty():
		_route=prepared.plan.points;_route_index=int(prepared.record.index);_route_record=prepared.record
		_surface=prepared.plan.surface;_surface_transform=prepared.plan.surface_transform
		contact_target=prepared.plan.contact;motion_mode_name=prepared.plan.kind;last_traversal_kind=prepared.plan.kind
	return ""
