# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Optional historical sequences have their own finite choice history. This model
## records narrative progress only; the scene admits proximity, sight, escort and
## native horse actions. It neither reads nor changes campaign saves or clocks.

const PATH := "res://history/punjab_chiefs_catalogue.json"
const SCHEMA := "1792.punjab-chiefs-progress.v1"
const MAX_CATALOGUE_BYTES := 1048576
const MAX_SEQUENCES := 32
const MAX_BEATS := 32
const MAX_CHOICES := 8
const MAX_FLAGS := 64
const SNAPSHOT_KEYS := ["schema", "sequence_id", "step_index", "flags", "choices"]

var _sequence: Dictionary = {}
var _sequence_id: String = ""
var _step_index: int = 0
var _flags: Dictionary = {}
var _choices: Array = []

# Return detached values so a UI query cannot rewrite the recorded history.
var sequence: Dictionary:
	get: return _sequence.duplicate(true)
var sequence_id: String:
	get: return _sequence_id
var step_index: int:
	get: return _step_index
var flags: Dictionary:
	get: return _flags.duplicate(true)
var choices: Array:
	get: return _choices.duplicate(true)

func catalogue() -> Array:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null or file.get_length() > MAX_CATALOGUE_BYTES: return []
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not data.get("sequences") is Array: return []
	var entries: Array = data.sequences
	if entries.is_empty() or entries.size() > MAX_SEQUENCES: return []
	var ids: Dictionary = {}
	for entry in entries:
		if not _valid_sequence(entry) or ids.has(entry.id): return []
		ids[entry.id] = true
	return entries.duplicate(true)

func start(id: String) -> String:
	var found := _find_sequence(id)
	if found.is_empty(): return "Unknown or invalid historical sequence."
	_sequence = found
	_sequence_id = id
	_step_index = 0
	_flags = {}
	_choices = []
	return ""

func current_beat() -> Dictionary:
	if _sequence.is_empty() or complete(): return {}
	return _sequence.beats[_step_index].duplicate(true)

func choose(choice_id: String) -> String:
	if not _valid_id(choice_id): return "Invalid historical choice."
	if _sequence.is_empty(): return "Begin a historical sequence first."
	if complete(): return "This historical sequence is complete."
	var beat: Dictionary = _sequence.beats[_step_index]
	if not _requirements_met(beat.get("requires_flags", []), _flags):
		return "The earlier narrative condition has not been met."
	var selected := _find_choice(beat, choice_id)
	if selected.is_empty(): return "That choice does not belong to the current beat."
	# Every mutation follows validation. A refused choice leaves progress intact.
	_apply_effects(_flags, selected.effects)
	_choices.append(choice_id)
	_step_index += 1
	return ""

func complete() -> bool:
	return not _sequence.is_empty() and _step_index == _sequence.beats.size()

func ending() -> String:
	if not complete(): return ""
	for item in _sequence.endings:
		if _requirements_met(item.requires_flags, _flags): return item.text
	return ""

func snapshot() -> Dictionary:
	return {"schema": SCHEMA, "sequence_id": _sequence_id, "step_index": _step_index,
		"flags": _flags.duplicate(true), "choices": _choices.duplicate(true)}

func restore(value: Variant) -> String:
	if not value is Dictionary or value.size() != SNAPSHOT_KEYS.size():
		return "Malformed historical progress."
	for key in SNAPSHOT_KEYS:
		if not value.has(key): return "Missing historical progress field."
	if not value.schema is String or value.schema != SCHEMA:
		return "Unsupported historical progress version."
	if not value.sequence_id is String or value.sequence_id.length() > 64:
		return "Invalid historical sequence identity."
	if not _whole_number(value.step_index, 0, MAX_BEATS): return "Invalid historical step."
	if not value.choices is Array or value.choices.size() > MAX_BEATS:
		return "Invalid historical choice history."
	if not _valid_flags(value.flags): return "Invalid historical flags."
	if int(value.step_index) != value.choices.size(): return "Historical step does not match its choices."
	if value.sequence_id.is_empty():
		if value.step_index != 0 or not value.flags.is_empty() or not value.choices.is_empty():
			return "Unstarted historical progress contains actions."
		_sequence = {}; _sequence_id = ""; _step_index = 0; _flags = {}; _choices = []
		return ""
	var found := _find_sequence(value.sequence_id)
	if found.is_empty(): return "Unknown or invalid historical sequence."
	if value.choices.size() > found.beats.size(): return "Historical sequence has too many choices."
	var replayed_flags: Dictionary = {}
	for index in range(value.choices.size()):
		var choice_id: Variant = value.choices[index]
		if not _valid_id(choice_id): return "Invalid recorded historical choice."
		var beat: Dictionary = found.beats[index]
		if not _requirements_met(beat.get("requires_flags", []), replayed_flags):
			return "Recorded history bypasses an earlier narrative condition."
		var selected := _find_choice(beat, choice_id)
		if selected.is_empty(): return "Recorded historical choice is out of order or unknown."
		_apply_effects(replayed_flags, selected.effects)
	if replayed_flags != value.flags: return "Historical flags do not match the recorded choices."
	# Commit only after the entire candidate has replayed and matched exactly.
	_sequence = found
	_sequence_id = value.sequence_id
	_step_index = int(value.step_index)
	_flags = replayed_flags
	_choices = value.choices.duplicate(true)
	return ""

func _find_sequence(id: String) -> Dictionary:
	if not _valid_id(id): return {}
	for entry in catalogue():
		if entry.id == id: return entry
	return {}

static func _find_choice(beat: Dictionary, id: String) -> Dictionary:
	for choice in beat.choices:
		if choice.id == id: return choice
	return {}

static func _apply_effects(target: Dictionary, effects: Dictionary) -> void:
	for key in effects: target[key] = effects[key]

static func _requirements_met(required: Array, values: Dictionary) -> bool:
	for key in required:
		if values.get(key, false) != true: return false
	return true

static func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 64: return false
	for character in value:
		if not "abcdefghijklmnopqrstuvwxyz0123456789_-".contains(character): return false
	return true

static func _valid_flags(value: Variant) -> bool:
	if not value is Dictionary or value.size() > MAX_FLAGS: return false
	for key in value:
		if not _valid_id(key) or not value[key] is bool: return false
	return true

static func _valid_requirements(value: Variant) -> bool:
	if not value is Array or value.size() > MAX_FLAGS: return false
	var seen: Dictionary = {}
	for key in value:
		if not _valid_id(key) or seen.has(key): return false
		seen[key] = true
	return true

static func _text(value: Variant, limit: int = 4096) -> bool:
	return value is String and not value.is_empty() and value.length() <= limit

static func _whole_number(value: Variant, low: int, high: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	return is_finite(float(value)) and value >= low and value <= high and floor(float(value)) == float(value)

static func _valid_sequence(value: Variant) -> bool:
	if not value is Dictionary or not _valid_id(value.get("id")): return false
	for key in ["title", "period", "role", "source_kind", "adaptation", "opening"]:
		if not _text(value.get(key)): return false
	# Source page representation belongs to the content catalogue, never progress.
	if not value.has("source_pages"): return false
	if not value.get("stations") is Array or value.stations.is_empty() or value.stations.size() > 64: return false
	var station_ids: Dictionary = {}
	for station in value.stations:
		if not station is Dictionary or not _valid_id(station.get("id")) or station_ids.has(station.id): return false
		if not _text(station.get("label"), 256) or not _text(station.get("kind"), 64): return false
		if not station.get("position") is Array or station.position.size() != 3: return false
		for number in station.position:
			if typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT: return false
			if not is_finite(float(number)) or absf(float(number)) > 10000: return false
		station_ids[station.id] = true
	if not value.get("beats") is Array or value.beats.is_empty() or value.beats.size() > MAX_BEATS: return false
	var beat_ids: Dictionary = {}
	var choice_ids: Dictionary = {}
	var flag_ids: Dictionary = {}
	for beat in value.beats:
		if not beat is Dictionary or not _valid_id(beat.get("id")) or beat_ids.has(beat.id): return false
		beat_ids[beat.id] = true
		if not beat.get("target") is String or not station_ids.has(beat.target): return false
		if not _text(beat.get("objective")) or not _text(beat.get("line")): return false
		if beat.get("mode") not in ["interact", "escort", "ride"]: return false
		if not _valid_requirements(beat.get("requires_flags", [])): return false
		if beat.has("min_ride_distance"):
			var distance: Variant = beat.min_ride_distance
			if typeof(distance) != TYPE_INT and typeof(distance) != TYPE_FLOAT: return false
			if not is_finite(float(distance)) or distance < 0 or distance > 10000: return false
		if not beat.get("choices") is Array or beat.choices.is_empty() or beat.choices.size() > MAX_CHOICES: return false
		for choice in beat.choices:
			if not choice is Dictionary or not _valid_id(choice.get("id")) or choice_ids.has(choice.id): return false
			choice_ids[choice.id] = true
			if not _text(choice.get("label"), 256) or not _text(choice.get("line")): return false
			if not _valid_flags(choice.get("effects")): return false
			for flag in choice.effects: flag_ids[flag] = true
	if flag_ids.size() > MAX_FLAGS: return false
	if not value.get("endings") is Array or value.endings.is_empty() or value.endings.size() > 32: return false
	var has_fallback := false
	for item in value.endings:
		if not item is Dictionary or not _valid_requirements(item.get("requires_flags")) or not _text(item.get("text")): return false
		if item.requires_flags.is_empty(): has_fallback = true
		for flag in item.requires_flags:
			if not flag_ids.has(flag): return false
	for beat in value.beats:
		for flag in beat.get("requires_flags", []):
			if not flag_ids.has(flag): return false
	return has_fallback
