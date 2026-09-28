# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node
## Scene-local input/lifecycle presentation. Holds no world state and advances no clock.
const Profile := preload("res://platform/input_profile.gd")
signal interrupted(reason: String)
signal device_changed
var focused:=true
var last_device:=-1
var using_gamepad:=false
var scroll_target: ScrollContainer
var _scroll_fraction:=0.0

func _ready() -> void:
	Profile.install()
	Input.joy_connection_changed.connect(_connection_changed)

func _input(event: InputEvent) -> void:
	if not focused:
		get_viewport().set_input_as_handled()
		return
	var meaningful: bool=event is InputEventJoypadButton and event.pressed
	if event is InputEventJoypadMotion: meaningful=absf(event.axis_value)>float(Profile.settings.deadzone)
	if meaningful:
		last_device=event.device
		if not using_gamepad:
			using_gamepad=true;device_changed.emit()
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		if using_gamepad:
			using_gamepad=false;device_changed.emit()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: set_focus(false)
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: set_focus(true)

func set_focus(value: bool) -> void:
	if focused==value: return
	focused=value
	if not value:
		Profile.release_gameplay()
		interrupted.emit("Application focus lost. Resume deliberately when ready.")
	# Returning focus never resumes a world or replays a queued operation.

func _connection_changed(device: int, connected: bool) -> void:
	if connected or device!=last_device: return
	Profile.release_gameplay()
	last_device=-1
	interrupted.emit("The last-used controller disconnected. Reconnect or use the keyboard, then resume.")

func _process(delta: float) -> void:
	if not focused or not is_instance_valid(scroll_target) or not scroll_target.is_visible_in_tree(): return
	var amount:=Input.get_axis("look_up","look_down")*540.0*delta+_scroll_fraction
	var whole:=int(amount)
	_scroll_fraction=amount-whole
	scroll_target.scroll_vertical+=whole

static func focus_buttons(container: Node, scroll: ScrollContainer=null) -> void:
	var buttons: Array[Button]=[]
	for child in container.get_children():
		if child is Button and child.visible and not child.disabled: buttons.append(child)
	if buttons.is_empty(): return
	for i in range(buttons.size()):
		var button: Button=buttons[i]
		button.focus_mode=Control.FOCUS_ALL
		button.focus_neighbor_top=button.get_path_to(buttons[(i-1+buttons.size())%buttons.size()])
		button.focus_neighbor_bottom=button.get_path_to(buttons[(i+1)%buttons.size()])
		button.focus_next=button.focus_neighbor_bottom
		button.focus_previous=button.focus_neighbor_top
		if scroll!=null: scroll.follow_focus=true
	var current:=container.get_viewport().gui_get_focus_owner()
	if current==null or not container.is_ancestor_of(current): buttons[0].grab_focus()
