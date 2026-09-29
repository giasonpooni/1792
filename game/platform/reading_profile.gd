# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Local presentation preferences. Never serialized into a character save.
const SCHEMA := "cg.reading-settings.v1"
const PATH := "user://1792-reading-settings.v1.json"
const LIMIT := 4096
const SIZES := [100,125,150,200]
const DEFAULTS := {"schema":SCHEMA,"text_percent":100,"high_contrast":false,"narrator_captions":true}
const Storage := preload("res://platform/local_storage.gd")
static var _settings: Dictionary=DEFAULTS.duplicate(true)
static var _installed:=false
static var warning:=""

static func snapshot() -> Dictionary:
	return _settings.duplicate(true)

static func install(path: String=PATH) -> void:
	if _installed: return
	_installed=true
	if FileAccess.file_exists(path): warning=load_preferences(path)

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.size()!=DEFAULTS.size() or value.get("schema")!=SCHEMA:
		return "Unknown reading-settings format."
	var size: Variant=value.get("text_percent")
	if (not size is int and not size is float) or not is_finite(float(size)) or float(size)<100 or float(size)>200 or float(size)!=floor(float(size)) or int(size) not in SIZES:
		return "Text size must be 100, 125, 150 or 200 percent."
	for key in ["high_contrast","narrator_captions"]:
		if not value.get(key) is bool: return "Reading preferences require boolean switches."
	return ""

static func _valid_path(path: String) -> bool:
	# One local preferences filename, not a path supplied by game or platform content.
	return path.begins_with("user://") and path.trim_prefix("user://").is_valid_filename() and path.ends_with(".json")

static func set_preferences(value: Dictionary, path: String=PATH, transport: RefCounted=null) -> String:
	var error:=validate(value)
	if not error.is_empty(): return error
	if not _valid_path(path): return "Reading preferences require a local JSON filename."
	var store: RefCounted=Storage.new() if transport==null else transport
	if not store.has_method("write_bytes"): return "Reading preference storage is unavailable."
	var candidate:=value.duplicate(true)
	candidate.text_percent=int(candidate.text_percent)
	var result: Variant=store.write_bytes(path,JSON.stringify(candidate).to_utf8_buffer(),LIMIT)
	if not result is String: return "Reading preference storage returned an invalid result."
	if not result.is_empty(): return result
	_settings=candidate # Persist before apply; a refused write never changes presentation.
	warning=""
	return ""

static func load_preferences(path: String=PATH, transport: RefCounted=null) -> String:
	if not _valid_path(path): return "Reading preferences require a local JSON filename."
	var store: RefCounted=Storage.new() if transport==null else transport
	if not store.has_method("read_bytes"): return "Reading preference storage is unavailable."
	var result: Variant=store.read_bytes(path,LIMIT)
	if not result is Dictionary or not result.get("error") is String: return "Reading preference storage returned an invalid result."
	if not result.error.is_empty(): return result.error
	if not result.get("bytes") is PackedByteArray or result.bytes.size()>LIMIT: return "Reading preferences exceed their byte budget."
	var parser:=JSON.new()
	if parser.parse(result.bytes.get_string_from_utf8())!=OK: return "Malformed reading preferences."
	var error:=validate(parser.data)
	if not error.is_empty(): return error
	_settings=parser.data.duplicate(true)
	_settings.text_percent=int(_settings.text_percent)
	warning=""
	return ""

static func proposal(action: String) -> Dictionary:
	var result:=snapshot()
	match action:
		"reading_size": result.text_percent=SIZES[(SIZES.find(result.text_percent)+1)%SIZES.size()]
		"reading_contrast": result.high_contrast=not result.high_contrast
		"reading_narration": result.narrator_captions=not result.narrator_captions
		"reading_reset": result=DEFAULTS.duplicate(true)
		_: return {} # Unknown operations never become an implicit reset.
	return result

static func description(note: String="") -> String:
	return (note+"\n\n" if not note.is_empty() else "")+\
		"Text size: %d%%\nHigh-contrast menus: %s\nShah Muhammad captions: %s\n\n"%[_settings.text_percent,"On" if _settings.high_contrast else "Off","On" if _settings.narrator_captions else "Off"]+\
		"Size applies to the title, home menus and dialogue. Live HUD and world labels retain their current size; use Read current messages in the home menu for a larger paused view.\n\n"+\
		"Right stick or mouse wheel scrolls long text; D-pad moves between buttons. NPC dialogue stays visible until you continue. Narrator captions are original English development text, not historical quotations or recorded audio.\n\n"+\
		"These preferences never change vision, knowledge, story progress or controller bindings. No screen-reader or console accessibility certification is claimed."

static func actions(back: String) -> Array:
	return [["Cycle text size (100–200%)","reading_size"],["Toggle high-contrast menus","reading_contrast"],
		["Toggle Shah Muhammad captions","reading_narration"],["Reset reading preferences","reading_reset"],["Back",back]]
