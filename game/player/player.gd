extends CharacterBody3D

@export var walk_speed := 4.5
@export var run_speed := 7.5
@export var acceleration := 18.0
@export var gravity_strength := 22.0

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var basis := global_transform.basis
	var direction := (basis.x * input_2d.x + basis.z * input_2d.y)
	direction.y = 0.0
	direction = direction.normalized()

	var target_speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := direction * target_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0

	move_and_slide()
