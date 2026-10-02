extends "res://mahan/mahan_settlement_state.gd"
const GarhiValidate := preload("res://mahan/mahan_garhi_validate.gd")
## Mahan-only Gujranwala garhi (fort) landmark observation greybox.
## Examine rampart/gatehouse/bastion markers when settlement observation is unlocked
## (column at gujranwala_settlement / after advance_under_custody) or when standing near
## gujranwala_fort_road with settlement in delivered scout custody. Uses existing
## gujranwala_garhi location stub. Attributed memories only; optional delayed report
## (player_knowledge false until delivered). No combat AI, no siege map, fixed endpoint.
const GARHI_PLACE := "gujranwala_garhi"
const FORT_ROAD_NODE := "gujranwala_fort_road"
const GARHI_DELAY := 75
const GARHI_MARKERS := {
	"rampart": Vector3(-23.5, 0.14, 17.5),
	"gatehouse": Vector3(-19.5, 0.14, 18.5),
	"bastion": Vector3(-22.5, 0.14, 21.5)
}
const GARHI_EXAMINE_TEXTS := {
	"rampart": {
		"source_id": "self",
		"channel": "garhi_observation",
		"text": "I examined the Garhi Mahan Singh rampart motif from the approach (sealed greybox observation; not a surveyed fort plan)."
	},
	"gatehouse": {
		"source_id": "self",
		"channel": "garhi_observation",
		"text": "I marked the garhi gatehouse line near fort road and settlement (local attributed observation; place gujranwala_garhi; household sukerchakia)."
	},
	"bastion": {
		"source_id": "self",
		"channel": "garhi_observation",
		"text": "I noted a bastion corner on the garhi landmark (sealed fact; no combat AI; no siege map opens)."
	}
}
const GARHI_REPORT_REQUEST_TEXT := {
	"source_id": "self",
	"channel": "garhi_choice",
	"text": "I requested delayed word on the garhi landmark (custody; not live omniscience of the fort interior)."
}
const GARHI_DELAYED_REPORT_TEXT := {
	"source_id": "fictional_garhi_courier",
	"channel": "delayed_garhi_report",
	"text": "Courier returned late: garhi motif still stands as a named fort landmark inside Gujranwala; interior plan unverified (sealed until delivery)."
}
const FACT_GARHI_WORD := "garhi_landmark_word"

func _init() -> void:
	super._init()
	_ensure_garhi()

func _ensure_garhi() -> Dictionary:
	if not _state.mahan.has("garhi") or not _state.mahan.garhi is Dictionary:
		_state.mahan.garhi = _fresh_garhi()
	var g: Dictionary = _state.mahan.garhi
	for key in ["examined", "reports", "facts"]:
		if not g.has(key):
			_state.mahan.garhi = _fresh_garhi()
			return _state.mahan.garhi
	return g

func _fresh_garhi() -> Dictionary:
	return {
		"examined": [],
		"reports": [],
		"facts": {
			FACT_GARHI_WORD: {"player_knowledge": false}
		}
	}

func garhi() -> Dictionary:
	return _ensure_garhi().duplicate(true)

func garhi_marker(kind: String) -> Vector3:
	return GARHI_MARKERS.get(kind, Vector3.ZERO)

func garhi_marker_ids() -> Array:
	return GARHI_MARKERS.keys()

func examined_garhi_markers() -> Array:
	return _ensure_garhi().examined.duplicate()

func pending_garhi_reports() -> Array:
	var out: Array = []
	for report in _ensure_garhi().reports:
		if not report.delivered:
			out.append(report.duplicate(true))
	return out

func received_garhi_reports() -> Array:
	var out: Array = []
	for report in _ensure_garhi().reports:
		if report.delivered:
			out.append(report.duplicate(true))
	return out

func garhi_fact_known(fact_id: String) -> bool:
	var facts: Dictionary = _ensure_garhi().facts
	if not facts.has(fact_id):
		return false
	return bool(facts[fact_id].get("player_knowledge", false))

func near_garhi_marker(kind: String = "") -> bool:
	if kind != "":
		if not GARHI_MARKERS.has(kind):
			return false
		return position().distance_to(GARHI_MARKERS[kind]) <= 2.5
	for mid in GARHI_MARKERS:
		if position().distance_to(GARHI_MARKERS[mid]) <= 2.5:
			return true
	return false

func garhi_observation_available() -> String:
	## Empty string means the landmark beat may open.
	if is_mounted():
		return "Dismount before examining the Gujranwala garhi landmark."
	if stage() != "march":
		return "Reach the march stage before garhi observation."
	if not resolve_place_id(GARHI_PLACE):
		return "Gujranwala garhi location stub is missing from the history place graph."
	var enc := encounter()
	var at_settlement: bool = str(_state.mahan.column_node) == SETTLEMENT_NODE
	var at_fort_road: bool = str(_state.mahan.column_node) == FORT_ROAD_NODE
	var after_advance: bool = bool(enc.resolved) and str(enc.choice) == "advance_under_custody"
	if not at_settlement and not at_fort_road and not after_advance:
		return "Stand the column at Gujranwala settlement or fort road, or resolve the approach encounter by advancing under custody."
	if SETTLEMENT_NODE not in _state.mahan.known_nodes and FORT_ROAD_NODE not in _state.mahan.known_nodes:
		return "Gujranwala approach nodes are not yet in delivered scout custody."
	if not near(SETTLEMENT_NODE) and not near(FORT_ROAD_NODE) and not near_garhi_marker() and not near("camp_table"):
		return "Stand at the settlement, fort road, a garhi marker, or the camp table."
	return ""

func examine_garhi_marker(kind: String) -> String:
	if kind not in GARHI_MARKERS:
		return "Unknown garhi marker."
	if is_mounted():
		return "Dismount before examining a garhi marker."
	var refuse := garhi_observation_available()
	if not refuse.is_empty():
		return refuse
	if not near(SETTLEMENT_NODE) and not near(FORT_ROAD_NODE) and not near_garhi_marker(kind):
		return "Stand at the settlement, fort road, or beside the %s marker." % kind
	var g := _ensure_garhi()
	if kind in g.examined:
		return "That garhi marker is already examined."
	var authored: Dictionary = GARHI_EXAMINE_TEXTS[kind]
	g.examined.append(kind)
	_remember("garhi_examine_%s" % kind, authored.source_id, authored.channel, authored.text)
	return ""

func request_delayed_garhi_report() -> String:
	## Non-terminal: schedules delayed garhi report; player_knowledge stays false until delivery.
	if is_mounted():
		return "Dismount before requesting delayed garhi word."
	var refuse := garhi_observation_available()
	if not refuse.is_empty():
		return refuse
	var g := _ensure_garhi()
	if not g.reports.is_empty():
		return "A delayed garhi report is already on the book."
	if garhi_fact_known(FACT_GARHI_WORD):
		return "Garhi landmark word is already known."
	g.reports.append({
		"id": "garhi_landmark_report.report",
		"target": FACT_GARHI_WORD,
		"observer_id": "garhi_courier",
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + GARHI_DELAY,
		"delivered": false,
		"source_id": GARHI_DELAYED_REPORT_TEXT.source_id,
		"channel": GARHI_DELAYED_REPORT_TEXT.channel,
		"text": GARHI_DELAYED_REPORT_TEXT.text
	})
	_remember("garhi_request_delayed_report", GARHI_REPORT_REQUEST_TEXT.source_id, GARHI_REPORT_REQUEST_TEXT.channel, GARHI_REPORT_REQUEST_TEXT.text)
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.garhi = _ensure_garhi().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_garhi_reports()

func _deliver_due_garhi_reports() -> void:
	var g := _ensure_garhi()
	for report in g.reports:
		if report.delivered or (not (_state.mahan.tick >= report.arrives_at)):
			continue
		report.delivered = true
		_remember(report.id, report.source_id, report.channel, report.text)
		var fact_id := str(report.target)
		if g.facts.has(fact_id):
			g.facts[fact_id].player_knowledge = true

func _garhi_memory_id(id: String) -> bool:
	return str(id).begins_with("garhi_")

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan garhi snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var g = m.get("garhi")
	var stripped_parent_path := false
	if g == null:
		for memory in m.memories:
			if _garhi_memory_id(str(memory.id)):
				return "Mahan garhi envelope missing."
		g = _fresh_garhi()
		stripped_parent_path = true
	elif not g is Dictionary:
		return "Mahan garhi envelope missing."
	var ledger_err := GarhiValidate.validate_ledger(self,
		value if not stripped_parent_path else {"mahan": {"garhi": g, "tick": m.tick, "memories": [], "household_id": m.get("household_id", "sukerchakia")}},
		g,
		stripped_parent_path
	)
	if not ledger_err.is_empty():
		return ledger_err
	var kept: Array = []
	var garhi_memories: Array = []
	for memory in m.memories:
		if _garhi_memory_id(str(memory.id)):
			garhi_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("garhi")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return GarhiValidate.validate_memories(self, value, garhi_memories)

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var g: Dictionary = core.mahan.garhi.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _garhi_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("garhi")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.garhi = {
		"examined": [],
		"reports": [],
		"facts": {
			FACT_GARHI_WORD: {"player_knowledge": bool(g.facts[FACT_GARHI_WORD].player_knowledge)}
		}
	}
	for kind in g.examined:
		_state.mahan.garhi.examined.append(str(kind))
	for report in g.reports:
		var copy: Dictionary = report.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.garhi.reports.append(copy)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
