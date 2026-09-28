extends "res://mahan/mahan_orders_state.gd"
## Thin history adapter stub — full loader follows in subsequent push.
const HistoryValidate := preload("res://mahan/mahan_history_validate.gd")
const HISTORY_DELAY_DEFAULT := 90
const AUTHORED_EVENT_PATHS := {
	"mahan_singh_death_fixed": "res://mahan/data/mahan_singh_death_fixed.json",
	"mahan_late_campaign_illness": "res://mahan/data/mahan_late_campaign_illness.json",
	"mahan_gujranwala_home_ground": "res://mahan/data/mahan_gujranwala_home_ground.json"
}
const AUTHORED_EVENT_IDS := [
	"mahan_singh_death_fixed",
	"mahan_late_campaign_illness",
	"mahan_gujranwala_home_ground"
]
const AUTHORED_LOCATION_PATHS := {
	"gujranwala_settlement": "res://mahan/data/locations/gujranwala_settlement.json",
	"gujranwala_garhi": "res://mahan/data/locations/gujranwala_garhi.json",
	"gujranwala_fort_road": "res://mahan/data/locations/gujranwala_fort_road.json",
	"gujranwala_camp": "res://mahan/data/locations/gujranwala_camp.json",
	"gujranwala_lahore_approach": "res://mahan/data/locations/gujranwala_lahore_approach.json",
	"sukarchakia_field_camp": "res://mahan/data/locations/sukarchakia_field_camp.json"
}
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
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			continue
		if not HistoryValidate.validate_authored_event(parser.data).is_empty():
			continue
		if not _validate_event_places(parser.data).is_empty():
			continue
		_catalog[event_id] = parser.data

func _load_locations() -> void:
	_locations.clear()
	for loc_id in AUTHORED_LOCATION_PATHS.keys():
		var path: String = str(AUTHORED_LOCATION_PATHS[loc_id])
		if not FileAccess.file_exists(path):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			continue
		if not HistoryValidate.validate_authored_location(parser.data).is_empty():
			continue
		_locations[loc_id] = parser.data

func authored_locations() -> Dictionary:
	return _locations.duplicate(true)

func authored_location(location_id: String) -> Dictionary:
	return _locations.get(location_id, {}).duplicate(true) if _locations.has(location_id) else {}

func resolve_place_id(place_id: String) -> bool:
	return _locations.has(place_id)

func authored_catalog() -> Dictionary:
	return _catalog.duplicate(true)

func authored_event(event_id: String) -> Dictionary:
	return _catalog.get(event_id, {}).duplicate(true) if _catalog.has(event_id) else {}

func known_historical_events() -> Array:
	var out: Array = []
	var hist := _ensure_history()
	for event_id in hist.events.keys():
		if hist.events[event_id].get("player_knowledge", false) and _catalog.has(event_id):
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
	return _catalog.has(event_id) and actor_id in _catalog[event_id].knowledge.direct_observers

func observe_historical_event(event_id: String) -> String:
	return "History adapter incomplete on remote; use full history_state."

func request_historical_report(event_id: String) -> String:
	return "History adapter incomplete on remote; use full history_state."

func _ensure_history() -> Dictionary:
	if not _state.mahan.has("history") or not _state.mahan.history is Dictionary:
		_state.mahan.history = {"events": {}, "pending_reports": []}
		for event_id in _catalog.keys():
			_state.mahan.history.events[event_id] = {"player_knowledge": false, "observed": false}
	return _state.mahan.history

func _validate_event_places(event: Dictionary) -> String:
	var loc: Dictionary = event.location
	if not resolve_place_id(str(loc.place_id)):
		return "Unknown place_id"
	if loc.has("related_place_ids"):
		for rid in loc.related_place_ids:
			if not resolve_place_id(str(rid)):
				return "Unknown related_place_id"
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.history = _ensure_history().duplicate(true)
	return out

static func validate_authored_event(value: Variant) -> String:
	return HistoryValidate.validate_authored_event(value)

static func validate_authored_location(value: Variant) -> String:
	return HistoryValidate.validate_authored_location(value)
