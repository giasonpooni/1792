extends "res://mahan/mahan_orders_state.gd"
const HistoryValidate := preload("res://mahan/mahan_history_validate.gd")
## Mahan-only historical-event loader / knowledge fence.
## Loads authored stubs from res://mahan/data/; refuses player_knowledge unless
## the profile actor is a direct observer or a delayed report has delivered.
## Does not rewrite world_state.schema.json, house_command_state, or campaign authorities.
const HISTORY_DELAY_DEFAULT := 90
const AUTHORED_EVENT_PATHS := {
	"mahan_singh_death_fixed": "res://mahan/data/mahan_singh_death_fixed.json",
	"mahan_late_campaign_illness": "res://mahan/data/mahan_late_campaign_illness.json",
	"mahan_gujranwala_home_ground": "res://mahan/data/mahan_gujranwala_home_ground.json",
	"mahan_gujranwala_ridge_settlement_approach": "res://mahan/data/mahan_gujranwala_ridge_settlement_approach.json"
}
const AUTHORED_EVENT_IDS := [
	"mahan_singh_death_fixed",
	"mahan_late_campaign_illness",
	"mahan_gujranwala_home_ground",
	"mahan_gujranwala_ridge_settlement_approach"
]
const AUTHORED_LOCATION_PATHS := {
	"gujranwala_settlement": "res://mahan/data/locations/gujranwala_settlement.json",
	"gujranwala_garhi": "res://mahan/data/locations/gujranwala_garhi.json",
	"gujranwala_fort_road": "res://mahan/data/locations/gujranwala_fort_road.json",
	"gujranwala_camp": "res://mahan/data/locations/gujranwala_camp.json",
	"gujranwala_lahore_approach": "res://mahan/data/locations/gujranwala_lahore_approach.json",
	"sukarchakia_field_camp": "res://mahan/data/locations/sukarchakia_field_camp.json"
}
const FORBIDDEN_TOKENS := [
	"raj_kaur", "Raj Kaur", "phulkian", "Phulkian", "sandhawalia", "Sandhawalia"
]

var _catalog: Dictionary = {}
var _locations: Dictionary = {}

func _init() -> void:
	super._init()
	_load_locations()
	_load_catalog()
	_ensure_history()

func _load_catalog() -> void:
	_catalog.clear()
	for event_id in AUTHORED_EVENT_IDS:
		var path: String = str(AUTHORED_EVENT_PATHS[event_id])
		if not FileAccess.file_exists(path):
			push_error("Missing Mahan historical event: " + path)
			continue
		var text := FileAccess.get_file_as_string(path)
		var parser := JSON.new()
		if parser.parse(text) != OK:
			push_error("Malformed historical event JSON: " + path)
			continue
		if not parser.data is Dictionary:
			push_error("Historical event root must be an object: " + path)
			continue
		var err := HistoryValidate.validate_authored_event(parser.data)
		if not err.is_empty():
			push_error("Historical event rejected (%s): %s" % [event_id, err])
			continue
		var place_err := _validate_event_places(parser.data)
		if not place_err.is_empty():
			push_error("Historical event place refs rejected (%s): %s" % [event_id, place_err])
			continue
		_catalog[event_id] = parser.data


func _load_locations() -> void:
	_locations.clear()
	for loc_id in AUTHORED_LOCATION_PATHS.keys():
		var path: String = str(AUTHORED_LOCATION_PATHS[loc_id])
		if not FileAccess.file_exists(path):
			push_error("Missing Mahan historical location: " + path)
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			push_error("Malformed historical location JSON: " + path)
			continue
		var err := HistoryValidate.validate_authored_location(parser.data)
		if not err.is_empty():
			push_error("Historical location rejected (%s): %s" % [loc_id, err])
			continue
		if str(parser.data.location_id) != loc_id:
			push_error("Historical location id mismatch: " + path)
			continue
		_locations[loc_id] = parser.data

func authored_locations() -> Dictionary:
	return _locations.duplicate(true)

func authored_location(location_id: String) -> Dictionary:
	if not _locations.has(location_id):
		return {}
	return _locations[location_id].duplicate(true)

func resolve_place_id(place_id: String) -> bool:
	return _locations.has(place_id)

func _ensure_history() -> Dictionary:
	if not _state.mahan.has("history") or not _state.mahan.history is Dictionary:
		_state.mahan.history = _fresh_history()
	var hist: Dictionary = _state.mahan.history
	for key in ["events", "pending_reports"]:
		if not hist.has(key):
			_state.mahan.history = _fresh_history()
			return _state.mahan.history
	# Ensure ledger rows exist for every catalogued event.
	for event_id in _catalog.keys():
		if not hist.events.has(event_id):
			hist.events[event_id] = _fresh_event_row()
	return hist

func _fresh_history() -> Dictionary:
	var events := {}
	for event_id in _catalog.keys():
		events[event_id] = _fresh_event_row()
	return {"events": events, "pending_reports": []}

func _fresh_event_row() -> Dictionary:
	return {"player_knowledge": false, "observed": false}

func history() -> Dictionary:
	return _ensure_history().duplicate(true)

func authored_catalog() -> Dictionary:
	return _catalog.duplicate(true)

func authored_event(event_id: String) -> Dictionary:
	if not _catalog.has(event_id):
		return {}
	return _catalog[event_id].duplicate(true)

func known_historical_events() -> Array:
	## Display fence: only events with runtime player_knowledge.
	var out: Array = []
	var hist := _ensure_history()
	for event_id in hist.events.keys():
		var row: Dictionary = hist.events[event_id]
		if row.get("player_knowledge", false) and _catalog.has(event_id):
			out.append(_catalog[event_id].duplicate(true))
	return out

func pending_historical_reports() -> Array:
	var out: Array = []
	for report in _ensure_history().pending_reports:
		if not report.delivered:
			out.append(report.duplicate(true))
	return out

func received_historical_reports() -> Array:
	var out: Array = []
	for report in _ensure_history().pending_reports:
		if report.delivered:
			out.append(report.duplicate(true))
	return out

func is_direct_observer(event_id: String, actor_id: String = ACTOR_ID) -> bool:
	if not _catalog.has(event_id):
		return false
	var observers: Array = _catalog[event_id].knowledge.direct_observers
	return actor_id in observers

func player_may_know(event_id: String) -> bool:
	## True when knowledge fence allows flipping player_knowledge for this profile actor.
	if not _catalog.has(event_id):
		return false
	if is_direct_observer(event_id):
		return true
	# Delivered delayed report already in ledger counts as earned knowledge.
	for report in _ensure_history().pending_reports:
		if str(report.event_id) == event_id and report.delivered and str(report.to) == ACTOR_ID:
			return true
	# Campaign-frame route with zero delay (fixed endpoint ack path).
	var routes: Array = _catalog[event_id].knowledge.report_routes
	for route in routes:
		if str(route.to) == ACTOR_ID and str(route.channel) == "campaign_frame":
			return true
	return false

func observe_historical_event(event_id: String) -> String:
	if not _catalog.has(event_id):
		return "Unknown historical event."
	if is_mounted():
		return "Dismount before consulting historical frames."
	if not is_direct_observer(event_id):
		return "Refuse: profile actor is not a direct observer of this event."
	var authored: Dictionary = _catalog[event_id]
	if authored.gameplay.intervention_scope not in ["observe", "report", "order_around"]:
		return "This historical event does not allow observe intervention."
	var hist := _ensure_history()
	var row: Dictionary = hist.events[event_id]
	if row.player_knowledge:
		return "This historical frame is already known."
	row.observed = true
	row.player_knowledge = true
	_remember(
		"history_%s" % event_id,
		"self",
		"historical_observe",
		"I recognized the authored historical frame '%s' from direct observation. Canon class: %s." % [
			event_id, authored.canon_class
		]
	)
	return ""

func request_historical_report(event_id: String) -> String:
	if not _catalog.has(event_id):
		return "Unknown historical event."
	if is_mounted():
		return "Dismount before requesting a historical report."
	var authored: Dictionary = _catalog[event_id]
	var routes: Array = authored.knowledge.report_routes
	var route: Dictionary = {}
	for candidate in routes:
		if str(candidate.to) == ACTOR_ID and str(candidate.channel) != "campaign_frame":
			route = candidate
			break
	if route.is_empty():
		return "No delayed report route reaches this profile actor."
	var hist := _ensure_history()
	if hist.events[event_id].player_knowledge:
		return "This historical frame is already known."
	for report in hist.pending_reports:
		if str(report.event_id) == event_id and not report.delivered:
			return "A historical report for this event is already pending."
	var delay: int = int(authored.knowledge.propagation_delay)
	if delay < 0:
		delay = HISTORY_DELAY_DEFAULT
	hist.pending_reports.append({
		"id": "history_%s.report" % event_id,
		"event_id": event_id,
		"observer_id": str(route.from),
		"from": str(route.from),
		"to": ACTOR_ID,
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + delay,
		"delivered": false,
		"channel": str(route.channel),
		"text": "Courier report on authored historical frame '%s' (%s). Not a primary-source quotation." % [
			event_id, authored.canon_class
		]
	})
	return ""

func acknowledge_fixed_endpoint() -> String:
	var err := super.acknowledge_fixed_endpoint()
	if not err.is_empty():
		return err
	var death_id := "mahan_singh_death_fixed"
	if _catalog.has(death_id) and player_may_know(death_id):
		var hist := _ensure_history()
		hist.events[death_id].player_knowledge = true
		hist.events[death_id].observed = false
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.history = _ensure_history().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_historical_reports()

func _deliver_due_historical_reports() -> void:
	var hist := _ensure_history()
	for report in hist.pending_reports:
		if report.delivered or (not (_state.mahan.tick >= report.arrives_at)):
			continue
		report.delivered = true
		var event_id: String = str(report.event_id)
		if hist.events.has(event_id):
			hist.events[event_id].player_knowledge = true
		_remember(report.id, report.from, report.channel, report.text)

func _history_memory_id(id: String) -> bool:
	return str(id).begins_with("history_")


func _validate_event_places(event: Dictionary) -> String:
	var loc: Dictionary = event.location
	var place_id := str(loc.place_id)
	if not resolve_place_id(place_id):
		return "Unknown place_id (no location stub): %s" % place_id
	if loc.has("related_place_ids"):
		for rid in loc.related_place_ids:
			if not resolve_place_id(str(rid)):
				return "Unknown related_place_id: %s" % rid
	return ""



static func validate_authored_event(value: Variant) -> String:
	return HistoryValidate.validate_authored_event(value)

static func validate_authored_location(value: Variant) -> String:
	return HistoryValidate.validate_authored_location(value)

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan history snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var hist = m.get("history")
	var stripped_parent_path := false
	if hist == null:
		for memory in m.memories:
			if _history_memory_id(str(memory.id)):
				return "Mahan history envelope missing."
		hist = _fresh_history()
		stripped_parent_path = true
	elif not hist is Dictionary:
		return "Mahan history envelope missing."
	var ledger_err := _validate_history_ledger(value if not stripped_parent_path else {"mahan": {"history": hist, "tick": m.tick, "memories": []}}, hist)
	if not ledger_err.is_empty():
		return ledger_err
	var kept: Array = []
	var history_memories: Array = []
	for memory in m.memories:
		if _history_memory_id(str(memory.id)):
			history_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("history")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return _validate_history_memories(value, history_memories)

func _validate_history_ledger(value: Dictionary, hist: Dictionary) -> String:
	if not hist.has("events") or not hist.has("pending_reports"):
		return "Malformed history ledger."
	if not hist.events is Dictionary or not hist.pending_reports is Array:
		return "Malformed history collections."
	for event_id in hist.events.keys():
		if event_id not in AUTHORED_EVENT_IDS:
			return "Unknown history ledger event."
		var row = hist.events[event_id]
		if not row is Dictionary or not row.has("player_knowledge") or not row.has("observed"):
			return "Malformed history event row."
		if typeof(row.player_knowledge) != TYPE_BOOL or typeof(row.observed) != TYPE_BOOL:
			return "History knowledge flags must be boolean."
		if row.player_knowledge:
			if not _catalog.has(event_id):
				return "player_knowledge set for missing catalog event."
			var allowed := false
			if is_direct_observer(event_id) and (row.observed or _has_delivered_history_report(hist, event_id) or _has_campaign_frame_route(event_id)):
				allowed = true
			if _has_delivered_history_report(hist, event_id):
				allowed = true
			if _has_campaign_frame_route(event_id) and value.mahan.get("endpoint_acknowledged", false):
				allowed = true
			if is_direct_observer(event_id) and row.observed:
				allowed = true
			if not allowed:
				return "Refuse player_knowledge=true when not observer and no delivered report."
	var seen_pending := {}
	var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
	for report in hist.pending_reports:
		if not report is Dictionary:
			return "Malformed historical custody."
		for key in ["id", "event_id", "observer_id", "from", "to", "observed_at", "arrives_at", "delivered", "channel", "text"]:
			if not report.has(key):
				return "Malformed historical custody."
		var event_id: String = str(report.event_id)
		if event_id not in AUTHORED_EVENT_IDS or not _catalog.has(event_id):
			return "Unsupported historical report event."
		if report.id != "history_%s.report" % event_id:
			return "Historical report id mismatch."
		if str(report.to) != ACTOR_ID:
			return "Historical report must target mahan_singh."
		var authored: Dictionary = _catalog[event_id]
		var delay: int = int(authored.knowledge.propagation_delay)
		if report.arrives_at != report.observed_at + delay:
			return "Invalid historical report delivery time."
		if report.observed_at != floor(report.observed_at) or report.observed_at < 0 or report.observed_at > tick:
			return "Invalid historical observation time."
		var due: bool = tick >= report.arrives_at
		if report.delivered != due:
			return "Historical delivery state disagrees with the clock."
		if seen_pending.has(event_id):
			return "Duplicate historical report target."
		seen_pending[event_id] = true
		if report.delivered and hist.events.has(event_id) and not hist.events[event_id].player_knowledge:
			return "Delivered historical report without player_knowledge."
	return ""

func _has_delivered_history_report(hist: Dictionary, event_id: String) -> bool:
	for report in hist.pending_reports:
		if str(report.event_id) == event_id and report.delivered:
			return true
	return false

func _has_campaign_frame_route(event_id: String) -> bool:
	if not _catalog.has(event_id):
		return false
	for route in _catalog[event_id].knowledge.report_routes:
		if str(route.to) == ACTOR_ID and str(route.channel) == "campaign_frame":
			return true
	return false

func _validate_history_memories(value: Dictionary, history_memories: Array) -> String:
	var hist: Dictionary = value.mahan.history
	var expected: Array = []
	for event_id in hist.events.keys():
		var row: Dictionary = hist.events[event_id]
		if row.observed and is_direct_observer(event_id):
			expected.append("history_%s" % event_id)
	for report in hist.pending_reports:
		if report.delivered:
			expected.append(report.id)
	if history_memories.size() != expected.size():
		return "History memories disagree with history ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in history_memories:
		if not memory is Dictionary:
			return "Malformed history memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed history memory."
		if memory.observer_id != ACTOR_ID:
			return "History memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid history memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
	if not remaining.is_empty():
		return "History memories disagree with history ledger."
	var parent_count: int = 0
	for memory in value.mahan.memories:
		if not _history_memory_id(str(memory.id)):
			parent_count += 1
	if value.mahan.memories.size() != parent_count + expected.size():
		return "History journal size disagrees with experienced events."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var hist: Dictionary = core.mahan.history.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _history_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("history")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.history = {
		"events": {},
		"pending_reports": []
	}
	for event_id in hist.events.keys():
		var row: Dictionary = hist.events[event_id]
		_state.mahan.history.events[event_id] = {
			"player_knowledge": bool(row.player_knowledge),
			"observed": bool(row.observed)
		}
	for report in hist.pending_reports:
		var copy: Dictionary = report.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.history.pending_reports.append(copy)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
