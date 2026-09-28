extends RefCounted
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
	"ridge": Vector3(16, 0.14, -16),
	"gujranwala_fort_road": Vector3(-10, 0.14, 8),
	"gujranwala_camp": Vector3(-16, 0.14, 14),
	"gujranwala_settlement": Vector3(-20, 0.14, 20)
}
const ADJACENT := {
	"camp": ["ford", "gujranwala_fort_road"],
	"ford": ["camp", "ridge"],
	"ridge": ["ford"],
	"gujranwala_fort_road": ["camp", "gujranwala_camp"],
	"gujranwala_camp": ["gujranwala_fort_road", "gujranwala_settlement"],
	"gujranwala_settlement": ["gujranwala_camp"]
}
const NODE_LABELS := {
	"camp": "field camp",
	"ford": "ford",
	"ridge": "ridge",
	"gujranwala_fort_road": "Gujranwala fort road",
	"gujranwala_camp": "Gujranwala camp",
	"gujranwala_settlement": "Gujranwala town"
}
const SITES := {
	"camp_table": Vector3(0, 0.14, 0),
	"camp": NODES.camp,
	"ford": NODES.ford,
	"ridge": NODES.ridge,
	"gujranwala_fort_road": NODES.gujranwala_fort_road,
	"gujranwala_camp": NODES.gujranwala_camp,
	"gujranwala_settlement": NODES.gujranwala_settlement
}
const SCOUT_TEXTS := {
	"ford": {"source_id": "fictional_field_scout", "channel": "delayed_report", "text": "Riders returned from the ford after dark. The crossing is passable; opposite-bank watchfires were few, but they could not confirm the fort road beyond."},
	"ridge": {"source_id": "fictional_field_scout", "channel": "delayed_report", "text": "The ridge detachment came in late. Dust hangs on the far road from the crest; the fort garrison itself remains unverified."},
	"gujranwala_fort_road": {"source_id": "fictional_field_scout", "channel": "delayed_report", "text": "The fort-road detachment returned. Tracks and pack dust run toward Gujranwala; the home settlement itself was not entered, and the garhi motif remains unverified from this approach."},
	"gujranwala_camp": {"source_id": "fictional_field_scout", "channel": "delayed_report", "text": "Riders reached the household staging ground outside Gujranwala. Hearth smoke rises toward the walled town; the column can stage here without claiming a surveyed street plan."},
	"gujranwala_settlement": {"source_id": "fictional_field_scout", "channel": "delayed_report", "text": "The town approach is open from the staging ground. Gujranwala remains Sukerchakia home-ground in delayed account only — this report does not invent a street survey or open a town combat map."}
}
const DECISIONS := {
	"advance_scouts": {"source_id": "self", "channel": "command_decision", "text": "I ordered the horse column forward along the reconnoitred path. The fort road remains uncertain; I am acting on delayed scout custody, not live sight."},
	"hold_for_corroboration": {"source_id": "self", "channel": "command_decision", "text": "I held the column at camp and waited for further corroboration. Delay preserves the horse line; delivered scout accounts still leave the fort unverified."}
}
static func node_label(node_id: String) -> String:
	return str(NODE_LABELS.get(node_id, node_id))
static func scout_targets() -> Array:
	return SCOUT_TEXTS.keys()
var _state: Dictionary
func _init() -> void:
	_state = _initial()
func _initial() -> Dictionary:
	var p := [0.0, 0.14, 2.0]
	return {"schema_version": "world-state.v1", "profile": PROFILE, "scenario_id": "mahan_field_command_interlude", "historical_class": "authored_source_informed_prototype", "game_time": {"year": 1790, "day": 1, "hour": 18.0}, "player": {"character_id": ACTOR_ID, "position": p.duplicate(), "known_places": ["sukarchakia_field_camp"]}, "actors": {ACTOR_ID: {"position": p.duplicate()}}, "places": [{"id": "sukarchakia_field_camp", "disposition": "friendly"}], "relationships": [], "mahan": {"tick": 0, "walked": 0.0, "provisions": 10, "column_node": "camp", "known_nodes": ["camp"], "reports": [], "decision": "", "decision_tick": -1, "endpoint_acknowledged": false, "memories": []}}
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
		_remember(report.id, report.source_id, report.channel, report.text)
