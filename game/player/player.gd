extends CharacterBody3D
const InputProfile := preload("res://platform/input_profile.gd")
var managed_controller_look := false

@export var walk_speed := 4.5
@export var run_speed := 7.5
@export var acceleration := 18.0
@export var gravity_strength := 22.0
@export var mouse_sensitivity := 0.0025
@export var menu_shortcut := true
var input_enabled := true
var external_speed_limit := INF # Optional game-owned load constraint; no default change.
@onready var pivot: Node3D = $CameraPivot

func _ready() -> void:
	InputProfile.install()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y -= event.relative.x * mouse_sensitivity
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -0.9, 0.5)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_F1 and menu_shortcut:
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func controller_look(delta: float) -> float:
	if not is_finite(delta) or delta<=0 or delta>0.1: return 0.0
	var stick:=Input.get_vector("look_left","look_right","look_up","look_down")
	var yaw:=stick.x*float(InputProfile.settings.look_speed)*delta
	pivot.rotation.y-=yaw
	var vertical:=stick.y*(-1.0 if InputProfile.settings.invert_y else 1.0)
	pivot.rotation.x=clampf(pivot.rotation.x-vertical*float(InputProfile.settings.look_speed)*delta,-0.9,0.5)
	return yaw

func _physics_process(delta: float) -> void:
	if input_enabled and not managed_controller_look: controller_look(delta)
	var input_2d := Vector2.ZERO
	if input_enabled:
		input_2d = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := pivot.global_basis.x * input_2d.x + pivot.global_basis.z * input_2d.y
	direction.y = 0.0
	direction = direction.normalized() * input_2d.length() # Preserve analog magnitude and the original full-stick speed.
	var speed := minf(run_speed if Input.is_action_pressed("sprint") else walk_speed,external_speed_limit)
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity_strength * delta
	move_and_slide()
