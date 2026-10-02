extends "res://mahan/mahan_chapter.gd"
## Mahan-only horse adapter. Base chapter and Lahore/house riding remain untouched.
const CavalryModel := preload("res://mahan/mahan_cavalry_state.gd")
const HorseScene := preload("res://mounts/horse.tscn")
const RidingRules := preload("res://mounts/riding_rules.gd")
var horse: CharacterBody3D
var _horse_label: Label3D
var _mount_requested := false

func _ready() -> void:
	# Allow logistics (or other) adapters to install their model before super._ready().
	if campaign == null or not campaign.has_method("enable_riding"):
		campaign = CavalryModel.new()
	campaign.enable_riding()
	super._ready()
	horse = HorseScene.instantiate()
	horse.name = "FieldHorse"
	add_child(horse)
	horse.apply_record(campaign.horse_state())
	_horse_label = Label3D.new()
	_horse_label.font_size = 42
	_horse_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_horse_label)
	_apply_mount(true)
	_notice = "E at the table for scouts. F near the field horse to mount."

func _physics_process(delta: float) -> void:
	if _paused or _modal.visible:
		_mount_requested = false
		return
	if _mount_requested:
		_mount_requested = false
		_toggle_mount()
	if not campaign.is_mounted():
		super._physics_process(delta)
		return
	var controls: bool = avatar.get("input_enabled")
	var motion: Dictionary = horse.step(
		delta,
		Input.get_action_strength("move_forward") if controls else 0.0,
		Input.get_axis("move_left", "move_right") if controls else 0.0,
		Input.is_action_pressed("sprint"), Input.is_key_pressed(KEY_CTRL),
		not controls or Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_SPACE)
	)
	var error: String = campaign.record_ride(motion, delta)
	if error.is_empty():
		campaign.advance()
	else:
		horse.apply_record(campaign.horse_state())
		_notice = error
	avatar.global_position = campaign.position()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F and not _modal.visible:
		_mount_requested = true
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9 and is_instance_valid(horse):
		if campaign.horse_state().is_empty():
			campaign.enable_riding()
		_apply_mount(true)

func _interact() -> void:
	if campaign.is_mounted():
		_notice = "Dismount (F when stopped) before orders or marker interactions."
		return
	super._interact()

func _toggle_mount() -> void:
	var error := ""
	if campaign.is_mounted():
		var h: Dictionary = campaign.horse_state()
		if h.speed > RidingRules.DISMOUNT_SPEED or not h.grounded:
			error = "Stop on solid ground before dismounting."
		else:
			var landing = horse.dismount_position(avatar)
			error = "No clear ground beside the horse." if landing == null else campaign.dismount_horse(landing)
	else:
		campaign.record_position(avatar.global_position, 1.0 / 60.0)
		error = campaign.mount_horse() if horse.clear_mount_path(avatar) else "A wall blocks the way to the horse."
	_notice = error if not error.is_empty() else ("Mounted. W forward | A/D steer | Shift canter | S/Space brake." if campaign.is_mounted() else "Dismounted. The field horse stays here.")
	if error.is_empty():
		_apply_mount(true)

func _apply_mount(force: bool = false) -> void:
	if not is_instance_valid(horse) or not is_instance_valid(avatar):
		return
	if force:
		horse.apply_record(campaign.horse_state())
	var mounted: bool = campaign.is_mounted()
	avatar.set_physics_process(not mounted)
	avatar.collision_layer = 0 if mounted else 1
	avatar.collision_mask = 0 if mounted else 1
	avatar.get_node("MeshInstance3D").visible = not mounted
	avatar.get_node("CameraPivot").position.y = 2.5 if mounted else 1.4
	avatar.get_node("CameraPivot/SpringArm3D").spring_length = 6.8 if mounted else 5.5
	if mounted:
		avatar.global_position = campaign.position()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud) or not is_instance_valid(_horse_label):
		return
	var h: Dictionary = campaign.horse_state()
	var mount := "mounted | %.1f m/s" % float(h.speed) if campaign.is_mounted() else "horse parked"
	_hud.text += "\nCavalry: %s | F mount/dismount | Household graph: %s" % [mount, CavalryModel.HOUSEHOLD_ID]
	_horse_label.position = RidingRules.position(h) + Vector3.UP * 3.6
	_horse_label.text = "" if campaign.is_mounted() else "Field horse [F]"
