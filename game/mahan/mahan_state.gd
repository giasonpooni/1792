extends RefCounted
## Isolated Mahan Singh field-command profile. Separate actor, save slot and memories.
## Does not extend childhood/Lahore authorities and never merges knowledge into Buddh.
## Recon reports mirror Lahore custody shape (observed_at / arrives_at / delivered) without
## rewriting command_state — player knowledge updates only on delivery.
const ACTOR_ID := "mahan_singh"
const PROFILE := "mahan.v1"
const SAVE_PATH := "user://1792-mahan-v1.json"
const LIMIT := 131072
const REPORT_DELAY := 120
const DISPATCH_COST := 1
const MARCH_COST := 2
const MARCH_TICKS := 30
const PROVISIONS_MAX := 12
const NODES := {
	"camp": Vector3(-3, 0.14, 2),
	"ford": Vector3(10, 0.14, -8),
	"ridge": Vector3(16, 0.14, -16)
}
const ADJACENT := {
	"camp": ["ford"],
	"ford": ["camp", "ridge"],
	"ridge": ["ford"]
}
const SITES := {
	"camp_table": Vector3(0, 0.14, 0),
	"camp": NODES.camp,
	"ford": NODES.ford,
	"ridge": NODES.ridge
}
# Authored fiction informed by late-campaign / delayed-report pattern; not quotations.
const SCOUT_TEXTS := {
	"ford": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "Riders returned from the ford after dark. The crossing is passable; opposite-bank watchfires were few, but they could not confirm the fort road beyond."
	},
	"ridge": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "The ridge detachment came in late. Dust hangs on the far road from the crest; the fort garrison itself remains unverified."
	}
}
const DECISIONS := {
	"advance_scouts": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I ordered the horse column forward along the reconnoitred path. The fort road remains uncertain; I am acting on delayed scout custody, not live sight."
	},
	"hold_for_corroboration": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I held the column at camp and waited for further corroboration. Delay preserves the horse line; delivered scout accounts still leave the fort unverified."
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
			"provisions": 10,
			"column_node": "camp",
			"known_nodes": ["camp"],
			"reports": [],
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
		return "march"
	if _delivered_count() > 0:
		return "decision"
	return "recon"

func column_node() -> String:
	return _state.mahan.column_node

func provisions() -> int:
	return int(_state.mahan.provisions)

func known_nodes() -> Array:
	return _state.mahan.known_nodes.duplicate()

func pending_reports() -> Array:
	var out: Array = []
	for report in _state.mahan.reports:
		if not report.delivered:
			out.append(report.duplicate(true))
	return out

func received_reports() -> Array:
	## Player-facing custody: only delivered reports. Mirrors Lahore received_reports().
	var out: Array = []
	for report in _state.mahan.reports:
		if report.delivered:
			out.append(report.duplicate(true))
	return out

func _delivered_count() -> int:
	var n := 0
	for report in _state.mahan.reports:
		if report.delivered:
			n += 1
	return n

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		if _state.mahan.tick >= 10000000:
			return
		_state.mahan.tick += 1
		var hours: float = 18.0 + _state.mahan.tick / 216000.0
		_state.game_time.day = 1 + int(hours / 24.0)
		_state.game_time.hour = fmod(hours, 24.0)
		_deliver_due_reports()

func _deliver_due_reports() -> void:
	for report in _state.mahan.reports:
		if report.delivered or _state.mahan.tick < report.arrives_at:
			continue
		report.delivered = true
		if report.target not in _state.mahan.known_nodes:
			_state.mahan.known_nodes.append(report.target)
		# Knowledge updates only on delivery — never while the courier is still out.
		_remember(report.id, report.source_id, report.channel, report.text)

func record_position(p: Vector3, delta: float) -> String:
	if not valid_point(coords(p)) or not is_finite(delta) or delta <= 0.0 or delta > 0.1:
		return "Invalid motion sample."
	var d := distance(position(), p)
	if d > 9.0 * delta + 0.08:
		return "Walking motion exceeded the declared bound."
	_state.mahan.walked = minf(120.0, _state.mahan.walked + d)
	_set_position(p)
	return ""

func _set_position(p: Vector3) -> void:
	_state.player.position = coords(p)
	_state.actors[ACTOR_ID].position = coords(p)

func dispatch_scout(target: String) -> String:
	if stage() != "recon" and stage() != "decision":
		return "Scout detachments are not available in this stage."
	if _state.mahan.decision != "":
		return "The column order is already given; no further detachments."
	if not near("camp_table"):
		return "Return to the camp table to dispatch a scout detachment."
	if not SCOUT_TEXTS.has(target):
		return "Unknown recon target."
	if _state.mahan.provisions < DISPATCH_COST:
		return "Insufficient provisions for a scout detachment."
	for report in _state.mahan.reports:
		if report.target == target:
			return "A detachment for that approach is already on the book."
	var authored: Dictionary = SCOUT_TEXTS[target]
	_state.mahan.provisions -= DISPATCH_COST
	_state.mahan.reports.append({
		"id": "scout_%s.report" % target,
		"target": target,
		"observer_id": "field_scout",
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + REPORT_DELAY,
		"delivered": false,
		"source_id": authored.source_id,
		"channel": authored.channel,
		"text": authored.text
	})
	return ""

func decide_column(choice: String) -> String:
	if stage() != "decision" or not near("camp_table"):
		return "Return to the camp table after a scout report has been delivered."
	if not DECISIONS.has(choice):
		return "Unknown column order."
	if _state.mahan.decision != "":
		return "The column order is already given."
	if _delivered_count() < 1:
		return "No delivered scout custody yet; knowledge has not arrived."
	_state.mahan.decision = choice
	_state.mahan.decision_tick = _state.mahan.tick
	var entry: Dictionary = DECISIONS[choice]
	_remember(choice, entry.source_id, entry.channel, entry.text)
	return ""

func march_to(next: String) -> String:
	if stage() != "march":
		return "Issue the column order before marching."
	if _state.mahan.decision != "advance_scouts":
		return "The column is held for corroboration; it does not leave camp."
	if not NODES.has(next):
		return "Unknown march destination."
	var current: String = _state.mahan.column_node
	if next not in ADJACENT.get(current, []):
		return "The column can only march to an adjacent authored node."
	if next not in _state.mahan.known_nodes:
		return "That approach is not yet in delivered scout custody."
	if not near(next):
		return "Walk the greybox path to the destination marker before committing the column."
	if _state.mahan.provisions < MARCH_COST:
		return "Insufficient provisions for the horse column to march."
	_state.mahan.provisions -= MARCH_COST
	_state.mahan.column_node = next
	_set_position(NODES[next])
	advance(MARCH_TICKS)
	_remember(
		"march_%s" % next,
		"self",
		"column_movement",
		"The horse column marched to the %s. Provisions were drawn down; the fort road remains a delayed-account problem, not live sight." % next
	)
	return ""

func acknowledge_fixed_endpoint() -> String:
	if stage() != "march":
		return "Issue the column order before closing this interlude beat."
	if not near(_state.mahan.column_node) and not near("camp_table"):
		return "Stand with the column or at the camp table to close the beat."
	if _state.mahan.endpoint_acknowledged:
		return "The fixed historical endpoint is already recorded."
	_state.mahan.endpoint_acknowledged = true
	_remember(
		"fixed_endpoint",
		"authorial_frame",
		"campaign_frame",
		"This interlude ends here. Mahan Singh's historical death is fixed campaign history; the player's column order and marches do not create an alternate-history survival branch."
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
	if m.walked < 0.0 or m.walked > 120.0:
		return "Invalid walk total."
	if m.provisions != floor(m.provisions) or m.provisions < 0 or m.provisions > PROVISIONS_MAX:
		return "Invalid provisions stub."
	if m.column_node not in NODES:
		return "Unknown column node."
	if m.known_nodes.is_empty() or m.known_nodes[0] != "camp":
		return "Camp must remain the first known node."
	var seen_nodes := {}
	for node_id in m.known_nodes:
		if node_id not in NODES or seen_nodes.has(node_id):
			return "Invalid known-node set."
		seen_nodes[node_id] = true
	if m.column_node not in m.known_nodes:
		return "Column stands on an unknown node."
	var hours: float = 18.0 + m.tick / 216000.0
	if value.game_time.year != 1790 or value.game_time.day != 1 + int(hours / 24.0) or absf(value.game_time.hour - fmod(hours, 24.0)) > 1e-10:
		return "Clock does not agree with the scenario tick."
	if m.decision_tick != floor(m.decision_tick) or m.decision_tick < -1 or m.decision_tick > m.tick:
		return "Invalid decision time."
	if m.decision not in ["", "advance_scouts", "hold_for_corroboration"]:
		return "Unknown column order."
	if (m.decision != "") != (m.decision_tick >= 0):
		return "Decision and decision tick disagree."
	var delivered := 0
	var pending_targets := {}
	var delivered_targets := {}
	for report in m.reports:
		if not _shape(report, {
			"id": "", "target": "", "observer_id": "", "observed_at": 0, "arrives_at": 0,
			"delivered": false, "source_id": "", "channel": "", "text": ""
		}):
			return "Malformed scout report custody."
		if report.target not in SCOUT_TEXTS or report.id != "scout_%s.report" % report.target:
			return "Unsupported scout report identity."
		if report.observer_id != "field_scout":
			return "Scout observer mismatch."
		if report.observed_at != floor(report.observed_at) or report.observed_at < 0 or report.observed_at > m.tick:
			return "Invalid report observation time."
		if report.arrives_at != report.observed_at + REPORT_DELAY:
			return "Invalid report delivery time."
		var authored: Dictionary = SCOUT_TEXTS[report.target]
		if report.source_id != authored.source_id or report.channel != authored.channel or report.text != authored.text:
			return "Attributed scout report was rewritten."
		var due: bool = m.tick >= report.arrives_at
		if report.delivered != due:
			return "Report delivery state disagrees with the clock."
		if pending_targets.has(report.target) or delivered_targets.has(report.target):
			return "Duplicate scout target on the book."
		if report.delivered:
			delivered += 1
			delivered_targets[report.target] = true
			if report.target not in m.known_nodes:
				return "Delivered recon target missing from known nodes."
		else:
			pending_targets[report.target] = true
	if m.decision != "" and delivered < 1:
		return "Column order before delivered scout custody."
	if m.endpoint_acknowledged and m.decision == "":
		return "Endpoint before column order."
	if m.decision == "hold_for_corroboration" and m.column_node != "camp":
		return "Held column cannot leave camp."
	# Provisions accounting: start 10, minus dispatch and marches.
	var expected_prov: int = 10 - m.reports.size() * DISPATCH_COST
	var march_memories: int = 0
	for memory in m.memories:
		if str(memory.id).begins_with("march_"):
			march_memories += 1
	expected_prov -= march_memories * MARCH_COST
	if m.provisions != expected_prov:
		return "Provisions stub disagrees with dispatches and marches."
	var expected: Array = []
	for report in m.reports:
		if report.delivered:
			expected.append(report.id)
	if m.decision != "":
		expected.append(m.decision)
	for memory in m.memories:
		if str(memory.id).begins_with("march_"):
			expected.append(memory.id)
	if m.endpoint_acknowledged:
		expected.append("fixed_endpoint")
	if m.memories.size() != expected.size():
		return "Memory and experienced events disagree."
	var prior := -1
	var remaining: Array = expected.duplicate()
	for memory in m.memories:
		if not _shape(memory, {"id": "", "source_id": "", "channel": "", "received_tick": 0, "text": "", "observer_id": ""}):
			return "Malformed Mahan memory."
		if memory.observer_id != ACTOR_ID:
			return "Mahan memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or memory.received_tick < prior or memory.received_tick > m.tick:
			return "Duplicate, future or unsupported memory."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if str(memory.id).begins_with("scout_") and str(memory.id).ends_with(".report"):
			var target := str(memory.id).trim_prefix("scout_").trim_suffix(".report")
			if not SCOUT_TEXTS.has(target):
				return "Unsupported delivered scout memory."
			var scout: Dictionary = SCOUT_TEXTS[target]
			if memory.source_id != scout.source_id or memory.channel != scout.channel or memory.text != scout.text:
				return "Delivered scout memory was rewritten."
			# Delivery tick must equal arrives_at for that report.
			var matched := false
			for report in m.reports:
				if report.id == memory.id and report.delivered and memory.received_tick == report.arrives_at:
					matched = true
			if not matched:
				return "Scout memory tick disagrees with delivery custody."
		elif DECISIONS.has(memory.id):
			var authored_d: Dictionary = DECISIONS[memory.id]
			if memory.source_id != authored_d.source_id or memory.channel != authored_d.channel or memory.text != authored_d.text:
				return "Command decision memory was rewritten."
			if m.decision_tick != memory.received_tick:
				return "Decision and memory ticks disagree."
		elif str(memory.id).begins_with("march_"):
			if memory.source_id != "self" or memory.channel != "column_movement":
				return "March memory was rewritten."
			var dest := str(memory.id).trim_prefix("march_")
			if dest not in NODES or dest not in m.known_nodes:
				return "March memory to unknown node."
			if m.decision != "advance_scouts":
				return "March memory without advance order."
		elif memory.id == "fixed_endpoint":
			if memory.source_id != "authorial_frame" or memory.channel != "campaign_frame":
				return "Endpoint frame was rewritten."
		else:
			return "Unsupported Mahan memory id."
	if not remaining.is_empty():
		return "Memory and experienced events disagree."
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
	_state.mahan.provisions = int(_state.mahan.provisions)
	for memory in _state.mahan.memories:
		memory.received_tick = int(memory.received_tick)
	for report in _state.mahan.reports:
		report.observed_at = int(report.observed_at)
		report.arrives_at = int(report.arrives_at)
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
