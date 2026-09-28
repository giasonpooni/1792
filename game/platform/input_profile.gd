# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Public semantic actions. Settings are presentation preferences, never character state.
const Storage := preload("res://platform/local_storage.gd")
const SETTINGS_PATH := "user://1792-controller-settings.v1.json"
const DEFAULTS := {"schema":"cg.controller-settings.v1","deadzone":0.2,"look_speed":2.4,"invert_y":false}
const BINDINGS_PATH := "user://1792-controller-bindings.v1.json"
const BINDINGS_SCHEMA := "cg.controller-bindings.v1"
# Confirm/back/pause/stories and analog axes stay recoverable in this bounded editor.
const BUTTON_DEFAULTS := {"interact":JOY_BUTTON_X,"mount":JOY_BUTTON_Y,
	"guard":JOY_BUTTON_LEFT_SHOULDER,"strike":JOY_BUTTON_RIGHT_SHOULDER,
	"cautious":JOY_BUTTON_LEFT_STICK,"escort_order":JOY_BUTTON_DPAD_UP,
	"ride_slow":JOY_BUTTON_DPAD_DOWN,"open_accounts":JOY_BUTTON_DPAD_LEFT,
	"open_research":JOY_BUTTON_DPAD_RIGHT}
const BUTTON_NAMES := {JOY_BUTTON_X:"X",JOY_BUTTON_Y:"Y",JOY_BUTTON_LEFT_SHOULDER:"LB",
	JOY_BUTTON_RIGHT_SHOULDER:"RB",JOY_BUTTON_LEFT_STICK:"L3",JOY_BUTTON_RIGHT_STICK:"R3",
	JOY_BUTTON_DPAD_UP:"D-pad up",JOY_BUTTON_DPAD_DOWN:"D-pad down",
	JOY_BUTTON_DPAD_LEFT:"D-pad left",JOY_BUTTON_DPAD_RIGHT:"D-pad right"}
const ACTION_NAMES := {"interact":"Interact / listen","mount":"Mount / dismount",
	"guard":"Guard (hold)","strike":"Counter","cautious":"Quiet approach (hold)",
	"escort_order":"Escort follow / hold","ride_slow":"Lower riding gait",
	"open_accounts":"Household accounts","open_research":"Research notebook"}
static var bindings: Dictionary=BUTTON_DEFAULTS.duplicate()
static var bindings_warning:=""
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
	# Confirm/cancel are UI-only and cannot be reassigned by the gameplay editor.
	_button("ui_accept",JOY_BUTTON_A);_button("ui_cancel",JOY_BUTTON_B)
	_button("ui_up",JOY_BUTTON_DPAD_UP);_button("ui_down",JOY_BUTTON_DPAD_DOWN)
	_button("ui_left",JOY_BUTTON_DPAD_LEFT);_button("ui_right",JOY_BUTTON_DPAD_RIGHT)
	if FileAccess.file_exists(SETTINGS_PATH): settings_warning=load_preferences(SETTINGS_PATH)
	_apply_deadzones()
	if FileAccess.file_exists(BINDINGS_PATH): bindings_warning=load_bindings(BINDINGS_PATH)
	_apply_bindings()

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

static func validate_bindings(value: Variant) -> String:
	if not value is Dictionary or value.size()!=2 or value.get("schema")!=BINDINGS_SCHEMA:
		return "Invalid gameplay-button layout identity."
	if not value.get("buttons") is Dictionary or value.buttons.size()!=BUTTON_DEFAULTS.size():
		return "The layout must retain every declared gameplay action."
	var used: Array=[]
	for action in BUTTON_DEFAULTS:
		var code: Variant=value.buttons.get(action)
		if not code is int and not code is float: return "Button codes must be whole numbers."
		if not is_finite(float(code)) or float(code)!=floorf(float(code)) or not BUTTON_NAMES.has(int(code)):
			return "That control is reserved or outside the supported gameplay buttons."
		if int(code) in used: return "Two gameplay actions cannot share a button. Use the explicit swap."
		used.append(int(code))
	return ""

static func binding_record() -> Dictionary:
	return {"schema":BINDINGS_SCHEMA,"buttons":bindings.duplicate()}

static func binding_proposal(action: String, code: int) -> Dictionary:
	if not BUTTON_DEFAULTS.has(action) or not BUTTON_NAMES.has(code):
		return {"error":"Unknown action or reserved button."}
	var candidate:=binding_record()
	var old: int=int(bindings[action])
	var other: String=""
	for key in bindings:
		if key!=action and bindings[key]==code:
			other=key
			candidate.buttons[key]=old
	candidate.buttons[action]=code
	var error:=validate_bindings(candidate)
	if not error.is_empty(): return {"error":error}
	var summary: String="%s: %s → %s"%[ACTION_NAMES[action],BUTTON_NAMES[old],BUTTON_NAMES[code]]
	if not other.is_empty(): summary+="\n%s: %s → %s"%[ACTION_NAMES[other],BUTTON_NAMES[code],BUTTON_NAMES[old]]
	return {"error":"","record":candidate,"summary":summary,"swapped_action":other}

static func set_bindings(value: Dictionary, path: String=BINDINGS_PATH) -> String:
	var error:=validate_bindings(value)
	if not error.is_empty(): return error
	# Save first. A failed write never leaves an unsaved map installed in this process.
	error=Storage.new().write_bytes(path,JSON.stringify(value).to_utf8_buffer(),4096)
	if not error.is_empty(): return error
	_commit_bindings(value)
	return ""

static func load_bindings(path: String=BINDINGS_PATH) -> String:
	var result:=Storage.new().read_bytes(path,4096)
	if not result.error.is_empty(): return result.error
	var parser:=JSON.new()
	if parser.parse(result.bytes.get_string_from_utf8())!=OK: return "Malformed gameplay-button layout JSON."
	var error:=validate_bindings(parser.data)
	if not error.is_empty(): return error
	_commit_bindings(parser.data)
	return ""

static func _commit_bindings(value: Dictionary) -> void:
	bindings=value.buttons.duplicate()
	for action in bindings: bindings[action]=int(bindings[action])
	_apply_bindings()

static func _apply_bindings() -> void:
	release_gameplay()
	for action in bindings:
		# Preserve original keyboard/mouse bindings, analog axes and every UI action.
		if not InputMap.has_action(action): InputMap.add_action(action)
		Input.action_release(action)
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton: InputMap.action_erase_event(action,event)
		_button(action,int(bindings[action]))

static func button_name(action: String) -> String:
	return str(BUTTON_NAMES[bindings[action]]) if bindings.has(action) else "Unknown"

static func hints() -> String:
	return "Xbox-style controls · Left stick move · Right stick look / scroll text\n"+\
		"%s interact · %s mount · %s guard · %s counter · RT run / faster gait\n"%[button_name("interact"),button_name("mount"),button_name("guard"),button_name("strike")]+\
		"LT brake · %s quiet approach · %s slower gait\n"%[button_name("cautious"),button_name("ride_slow")]+\
		"%s escort · %s accounts · %s research\n"%[button_name("escort_order"),button_name("open_accounts"),button_name("open_research")]+\
		"View stories · Menu journal/pause · A confirm · B back\n"+\
		"Gameplay buttons can be reassigned below. A/B, Menu/View, sticks and triggers stay fixed. Keyboard/mouse remain available."

static func controller_text(text: String) -> String:
	# Control presentation only: never run this on testimony, source IDs or the evidence ledger.
	# Stage replacements so swapped button labels cannot cascade into other replacements.
	var pairs: Array=[
		["WASD / Mouse","Left stick / Right stick"],["[WASD]","[Left stick]"],["[mouse]","[Right stick]"],
		["[hold C + E]","[hold %s + %s]"%[button_name("cautious"),button_name("interact")]],
		["[look + E]","[look + %s]"%button_name("interact")],["[hold Q]","[hold %s]"%button_name("guard")],
		["[left click]","[%s]"%button_name("strike")],["[click]","[%s]"%button_name("strike")],
		["[E]","[%s]"%button_name("interact")],["[F]","[%s]"%button_name("mount")],["[Q]","[%s]"%button_name("guard")],
		["F horse",button_name("mount")+" horse"],["E speak",button_name("interact")+" speak"],
		["B accounts",button_name("open_accounts")+" accounts"],["F5/F9 save/load","Menu save/load"],["J journal","Menu journal"],
		["B: supplies",button_name("open_accounts")+": supplies"],["B: oral accounts",button_name("open_accounts")+": oral accounts"],
		["F2:",button_name("open_research")+":"],["F7:","View:"],["E:",button_name("interact")+":"],
		["R checkpoint","Menu checkpoint"],["R restores","Menu restores"],["[G toggles","["+button_name("escort_order")+" toggles"]]
	for i in range(pairs.size()): text=text.replace(pairs[i][0],"\u0001binding%d\u0002"%i)
	for i in range(pairs.size()): text=text.replace("\u0001binding%d\u0002"%i,pairs[i][1])
	return text
