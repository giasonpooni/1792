extends RefCounted
## Isolated Mahan Singh field-command profile. Separate actor, save slot and memories.
## Does not extend childhood/Lahore authorities and never merges knowledge into Buddh.
const ACTOR_ID := "mahan_singh"
const PROFILE := "mahan.v1"
const SAVE_PATH := "user://1792-mahan-v1.json"
const LIMIT := 131072
const SITES := {
	"camp_table": Vector3(0, 0.14, 0),
	"scout": Vector3(6, 0.14, -4),
	"column_mark": Vector3(-8, 0.14, 2)
}
# Authored fiction informed by the late-campaign / delayed-report pattern; not quotations.
const SCOUT_REPORT := {
	"source_id": "fictional_field_scout",
	"channel": "delayed_report",
	"text": "Riders reached the camp after dark. The fort road was held at dusk; they could not confirm whether the garrison still holds or has withdrawn."
}
const DECISIONS := {
	"advance_scouts": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I ordered a small scout detachment forward before the column moves. The fort road remains uncertain; I am acting on one delayed report."
	},
	"hold_for_corroboration": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I held the column and waited for a second account. Delay preserves the horse line; the fort road is still unverified."
	}
}
var _state: Dictionary

func _init() -> void:
	_state = _initial()

func _initial() -> Dictionary:
	var p := [0.0, 0.14, 2.0]
	return {
		"schema_version": "world-state.v1",
		"profile": PROFILE,
		"scenario_id": "mahan_field_command_interlude",
		"historical_class": "authored_source_informed_prototype",
		"game_time": {"year": 1790, "day": 1, "hour": 18.0},
		"player": {"character_id": ACTOR_ID, "position": p.duplicate(), "known_places": ["sukarchakia_field_camp"]},
		"actors": {ACTOR_ID: {"position": p.duplicate()}},
		"places": [{"id": "sukarchakia_field_camp", "disposition": "friendly"}],
		"relationships": [],
		"mahan": {
			"tick": 0,
			"walked": 0.0,
			"report_heard": false,
			"decision": "",
			"decision_tick": -1,
			"endpoint_acknowledged": false,
			"memories": []
		}
	}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func progress() -> Dictionary:
	return _state.mahan.duplicate(true)

func position() -> Vector3:
	return point(_state.player.position)

static func point(p: Array) -> Vector3:
	return Vector3(p[0], p[1], p[2])

static func coords(p: Vector3) -> Array:
	return [p.x, p.y, p.z]

static func distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func near(id: String, radius: float = 3.0) -> bool:
	return SITES.has(id) and distance(position(), SITES[id]) <= radius

func stage() -> String:
	var m: Dictionary = _state.mahan
	if m.endpoint_acknowledged:
		return "closed"
	if m.decision != "":
		return "endpoint"
	if m.report_heard:
		return "decision"
	return "await_report"

func advance() -> void:
	if _state.mahan.tick >= 10000000:
		return
	_state.mahan.tick += 1
	var hours: float = 18.0 + _state.mahan.tick / 216000.0
	_state.game_time.day = 1 + int(hours / 24.0)
	_state.game_time.hour = fmod(hours, 24.0)

func record_position(p: Vector3, delta: float) -> String:
	if not valid_point(coords(p)) or not is_finite(delta) or delta <= 0.0 or delta > 0.1:
		return "Invalid motion sample."
	var d := distance(position(), p)
	if d > 9.0 * delta + 0.08:
		return "Walking motion exceeded the declared bound."
	_state.mahan.walked = minf(40.0, _state.mahan.walked + d)
	_set_position(p)
	return ""

func _set_position(p: Vector3) -> void:
	_state.player.position = coords(p)
	_state.actors[ACTOR_ID].position = coords(p)

func hear_scout_report() -> String:
	if stage() != "await_report" or not near("scout"):
		return "Approach the delayed scout on foot at the camp edge."
	if _state.mahan.report_heard:
		return "This is the same delayed report, not new corroboration."
	_state.mahan.report_heard = true
	_remember("scout_report", SCOUT_REPORT.source_id, SCOUT_REPORT.channel, SCOUT_REPORT.text)
	return ""

func decide_column(choice: String) -> String:
	if stage() != "decision" or not near("camp_table"):
		return "Return to the camp table after hearing the scout."
	if not DECISIONS.has(choice):
		return "Unknown column order."
	if _state.mahan.decision != "":
		return "The column order is already given."
	_state.mahan.decision = choice
	_state.mahan.decision_tick = _state.mahan.tick
	var entry: Dictionary = DECISIONS[choice]
	_remember(choice, entry.source_id, entry.channel, entry.text)
	return ""

func acknowledge_fixed_endpoint() -> String:
	if stage() != "endpoint" or not near("camp_table"):
		return "Issue the column order at the table before closing this interlude beat."
	if _state.mahan.endpoint_acknowledged:
		return "The fixed historical endpoint is already recorded."
	_state.mahan.endpoint_acknowledged = true
	_remember(
		"fixed_endpoint",
		"authorial_frame",
		"campaign_frame",
		"This interlude ends here. Mahan Singh's historical death is fixed campaign history; the player's column order does not create an alternate-history survival branch."
	)
	return ""

func journal() -> Array:
	return _state.mahan.memories.duplicate(true)

func _remember(id: String, source: String, channel: String, text: String) -> void:
	_state.mahan.memories.append({
		"id": id,
		"source_id": source,
		"channel": channel,
		"received_tick": _state.mahan.tick,
		"text": text,
		"observer_id": ACTOR_ID
	})

static func valid_point(p: Variant) -> bool:
	if not p is Array or p.size() != 3:
		return false
	for value in p:
		if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)):
			return false
	return absf(p[0]) <= 28.0 and absf(p[2]) <= 28.0 and p[1] >= -0.5 and p[1] <= 10.0

func _shape(value: Variant, reference: Variant) -> bool:
	if reference is Dictionary:
		if not value is Dictionary or value.size() != reference.size():
			return false
		for key in reference:
			if not value.has(key) or not _shape(value[key], reference[key]):
				return false
		return true
	if reference is Array:
		return value is Array
	if typeof(reference) in [TYPE_FLOAT, TYPE_INT]:
		return typeof(value) in [TYPE_FLOAT, TYPE_INT] and is_finite(float(value))
	return typeof(value) == typeof(reference)

func validate(value: Variant) -> String:
	var seed := _initial()
	if not _shape(value, seed):
		return "Malformed Mahan snapshot."
	for key in ["schema_version", "profile", "scenario_id", "historical_class", "places", "relationships"]:
		if value[key] != seed[key]:
			return "Unsupported Mahan identity or static data."
	if value.player.character_id != ACTOR_ID or value.player.known_places != ["sukarchakia_field_camp"]:
		return "Unknown protagonist or invented map knowledge."
	if not value.actors.has(ACTOR_ID) or value.actors.size() != 1:
		return "Mahan profile admits only its own actor."
	if not valid_point(value.player.position) or value.actors[ACTOR_ID].position != value.player.position:
		return "Invalid or inconsistent protagonist pose."
	var m: Dictionary = value.mahan
	if m.tick != floor(m.tick) or m.tick < 0 or m.tick > 10000000:
		return "Invalid Mahan simulation clock."
	if m.walked < 0.0 or m.walked > 40.0:
		return "Invalid walk total."
	var hours: float = 18.0 + m.tick / 216000.0
	if value.game_time.year != 1790 or value.game_time.day != 1 + int(hours / 24.0) or absf(value.game_time.hour - fmod(hours, 24.0)) > 1e-10:
		return "Clock does not agree with the scenario tick."
	if m.decision_tick != floor(m.decision_tick) or m.decision_tick < -1 or m.decision_tick > m.tick:
		return "Invalid decision time."
	if m.decision not in ["", "advance_scouts", "hold_for_corroboration"]:
		return "Unknown column order."
	if (m.decision != "") != (m.decision_tick >= 0):
		return "Decision and decision tick disagree."
	if m.decision != "" and not m.report_heard:
		return "Column order before scout report."
	if m.endpoint_acknowledged and m.decision == "":
		return "Endpoint before column order."
	var expected: Array = []
	if m.report_heard:
		expected.append("scout_report")
	if m.decision != "":
		expected.append(m.decision)
	if m.endpoint_acknowledged:
		expected.append("fixed_endpoint")
	if m.memories.size() != expected.size():
		return "Memory and experienced events disagree."
	var prior := -1
	for memory in m.memories:
		if not _shape(memory, {"id": "", "source_id": "", "channel": "", "received_tick": 0, "text": "", "observer_id": ""}):
			return "Malformed Mahan memory."
		if memory.observer_id != ACTOR_ID:
			return "Mahan memory must stay attributed to mahan_singh."
		if memory.id not in expected or memory.received_tick != floor(memory.received_tick) or memory.received_tick < prior or memory.received_tick > m.tick:
			return "Duplicate, future or unsupported memory."
		expected.erase(memory.id)
		prior = int(memory.received_tick)
		if memory.id == "scout_report":
			if memory.source_id != SCOUT_REPORT.source_id or memory.channel != SCOUT_REPORT.channel or memory.text != SCOUT_REPORT.text:
				return "Attributed scout report was rewritten."
		elif DECISIONS.has(memory.id):
			var authored: Dictionary = DECISIONS[memory.id]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Command decision memory was rewritten."
			if m.decision_tick != memory.received_tick:
				return "Decision and memory ticks disagree."
		elif memory.id == "fixed_endpoint":
			if memory.source_id != "authorial_frame" or memory.channel != "campaign_frame":
				return "Endpoint frame was rewritten."
		else:
			return "Unsupported Mahan memory id."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	_state = value.duplicate(true)
	_state.game_time.year = int(_state.game_time.year)
	_state.game_time.day = int(_state.game_time.day)
	_state.game_time.hour = float(_state.game_time.hour)
	_state.mahan.tick = int(_state.mahan.tick)
	_state.mahan.decision_tick = int(_state.mahan.decision_tick)
	_state.mahan.walked = float(_state.mahan.walked)
	for memory in _state.mahan.memories:
		memory.received_tick = int(memory.received_tick)
	for i in range(3):
		_state.player.position[i] = float(_state.player.position[i])
		_state.actors[ACTOR_ID].position[i] = float(_state.actors[ACTOR_ID].position[i])
	return ""

func save_to(path: String = SAVE_PATH) -> String:
	var error := validate(_state)
	if not error.is_empty():
		return error
	var text := JSON.stringify(_state, "", true, true)
	if text.to_utf8_buffer().size() > LIMIT:
		return "Save too large."
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return "Cannot open temporary save."
	f.store_string(text)
	f.flush()
	var result := f.get_error()
	f.close()
	if result != OK:
		return "Save write failed."
	result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	return "" if result == OK else "Save replacement failed."

func load_from(path: String = SAVE_PATH) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "No Mahan save found."
	if f.get_length() > LIMIT:
		f.close()
		return "Save too large."
	var text := f.get_as_text()
	f.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return "Malformed Mahan JSON."
	return restore(parser.data)
