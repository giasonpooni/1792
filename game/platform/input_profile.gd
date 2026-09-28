# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Public semantic actions. Settings are presentation preferences, never character state.
const Storage := preload("res://platform/local_storage.gd")
const SETTINGS_PATH := "user://1792-controller-settings.v1.json"
const DEFAULTS := {"schema":"cg.controller-settings.v1","deadzone":0.2,"look_speed":2.4,"invert_y":false}
const HELD := ["move_left","move_right","move_forward","move_backward","sprint","guard","cautious","ride_slow","ride_brake",
	"look_left","look_right","look_up","look_down"]
static var settings: Dictionary=DEFAULTS.duplicate()
static var installed:=false
static var settings_warning:=""

static func install() -> void:
	if installed: return
	installed=true
	# Additive: original physical WASD/Shift events remain in project.godot.
	for action in ["move_left","move_right","move_forward","move_backward","sprint"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_key("interact",KEY_E);_key("mount",KEY_F);_key("save_game",KEY_F5);_key("load_game",KEY_F9)
	_key("retry_checkpoint",KEY_R);_key("escort_order",KEY_G);_key("open_journal",KEY_J)
	_key("pause_game",KEY_F1);_key("pause_game",KEY_ESCAPE);_key("toggle_framing",KEY_F4)
	_key("open_memories",KEY_F7);_key("open_accounts",KEY_B);_key("open_research",KEY_F2)
	_key("guard",KEY_Q);_key("cautious",KEY_C);_key("ride_slow",KEY_CTRL);_key("ride_brake",KEY_SPACE)
	var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT
	_add("strike",mouse)
	_button("interact",JOY_BUTTON_X);_button("mount",JOY_BUTTON_Y)
	_button("pause_game",JOY_BUTTON_START);_button("open_memories",JOY_BUTTON_BACK)
	_button("guard",JOY_BUTTON_LEFT_SHOULDER);_button("strike",JOY_BUTTON_RIGHT_SHOULDER)
	_button("cautious",JOY_BUTTON_LEFT_STICK);_button("ride_slow",JOY_BUTTON_DPAD_DOWN)
	_button("escort_order",JOY_BUTTON_DPAD_UP);_button("open_accounts",JOY_BUTTON_DPAD_LEFT)
	_button("open_research",JOY_BUTTON_DPAD_RIGHT)
	_axis("move_left",JOY_AXIS_LEFT_X,-1);_axis("move_right",JOY_AXIS_LEFT_X,1)
	_axis("move_forward",JOY_AXIS_LEFT_Y,-1);_axis("move_backward",JOY_AXIS_LEFT_Y,1)
	_axis("look_left",JOY_AXIS_RIGHT_X,-1);_axis("look_right",JOY_AXIS_RIGHT_X,1)
	_axis("look_up",JOY_AXIS_RIGHT_Y,-1);_axis("look_down",JOY_AXIS_RIGHT_Y,1)
	_axis("sprint",JOY_AXIS_TRIGGER_RIGHT,1);_axis("ride_brake",JOY_AXIS_TRIGGER_LEFT,1)
	# Confirm/cancel are UI-only. X never doubles as confirm or attack.
	_button("ui_accept",JOY_BUTTON_A);_button("ui_cancel",JOY_BUTTON_B)
	_button("ui_up",JOY_BUTTON_DPAD_UP);_button("ui_down",JOY_BUTTON_DPAD_DOWN)
	_button("ui_left",JOY_BUTTON_DPAD_LEFT);_button("ui_right",JOY_BUTTON_DPAD_RIGHT)
	if FileAccess.file_exists(SETTINGS_PATH): settings_warning=load_preferences(SETTINGS_PATH)
	_apply_deadzones()

static func _add(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
static func _key(action: String, code: Key) -> void:
	var event:=InputEventKey.new();event.keycode=code;_add(action,event)
static func _button(action: String, code: JoyButton) -> void:
	var event:=InputEventJoypadButton.new();event.device=-1;event.button_index=code;_add(action,event)
static func _axis(action: String, code: JoyAxis, value: float) -> void:
	var event:=InputEventJoypadMotion.new();event.device=-1;event.axis=code;event.axis_value=value;_add(action,event)
static func _apply_deadzones() -> void:
	for action in HELD:
		if InputMap.has_action(action): InputMap.action_set_deadzone(action,float(settings.deadzone))

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.size()!=DEFAULTS.size() or value.get("schema")!=DEFAULTS.schema: return "Invalid controller settings identity."
	if not value.get("invert_y") is bool: return "Invalid vertical-look preference."
	for key in ["deadzone","look_speed"]:
		if not value.get(key) is float and not value.get(key) is int: return "Controller settings must be finite numbers."
		if not is_finite(float(value[key])): return "Controller settings must be finite numbers."
	if value.deadzone<0.1 or value.deadzone>0.45 or value.look_speed<0.5 or value.look_speed>6.0: return "Controller settings exceed supported bounds."
	return ""

static func set_preferences(value: Dictionary, path: String=SETTINGS_PATH) -> String:
	var error:=validate(value)
	if not error.is_empty(): return error
	error=Storage.new().write_bytes(path,JSON.stringify(value).to_utf8_buffer(),4096)
	if not error.is_empty(): return error
	settings=value.duplicate(true)
	_apply_deadzones()
	return ""

static func load_preferences(path: String=SETTINGS_PATH) -> String:
	var result:=Storage.new().read_bytes(path,4096)
	if not result.error.is_empty(): return result.error
	var parser:=JSON.new()
	if parser.parse(result.bytes.get_string_from_utf8())!=OK: return "Malformed controller settings JSON."
	var error:=validate(parser.data)
	if not error.is_empty(): return error
	settings=parser.data.duplicate(true)
	_apply_deadzones()
	return ""

static func release_gameplay() -> void:
	for action in HELD:
		if InputMap.has_action(action): Input.action_release(action)

static func hints() -> String:
	return "Xbox-style layout · Left stick move · Right stick look / scroll text\nX interact · Y mount · LB guard · RB counter · RT run / faster gait\nLT brake · L3 hold for quiet approach · D-pad down slower gait\nD-pad up escort · left accounts · right research\nView remembered stories · Menu journal/pause · A confirm · B back\nKeyboard and mouse remain available. No gamepad remapping editor yet."

static func controller_text(text: String) -> String:
	# Translate only known control labels, never testimony or a character's source ID.
	for pair in [["WASD / Mouse","Left stick / Right stick"],["F horse","Y horse"],["E speak","X speak"],
		["B accounts","D-pad left accounts"],["F5/F9 save/load","Menu save/load"],["J journal","Menu journal"],
		["[E]","[X]"],["B: supplies","D-pad left: supplies"],["B: oral accounts","D-pad left: oral accounts"],
		["F2:","D-pad right:"],["F7:","View:"],["E:","X:"]]:
		text=text.replace(pair[0],pair[1])
	return text
