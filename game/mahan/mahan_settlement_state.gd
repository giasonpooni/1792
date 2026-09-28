extends "res://mahan/mahan_encounter_state.gd"
const SettlementValidate := preload("res://mahan/mahan_settlement_validate.gd")
## Mahan-only Gujranwala settlement observation greybox.
## Examine walls/gate/well/house markers when the column is at gujranwala_settlement
## (or after encounter advance_under_custody). Attributed memories only; sealed facts
## are not omniscience. Optional delayed local rumor via custody (player_knowledge
## false until delivered). No combat AI, no town economy sim, fixed endpoint unchanged.
const SETTLEMENT_NODE := "gujranwala_settlement"
const SETTLEMENT_DELAY := 70
const SETTLEMENT_MARKERS := {
	"walls": Vector3(-22, 0.14, 18),
	"gate": Vector3(-18, 0.14, 20),
	"well": Vector3(-20, 0.14, 22),
	"house": Vector3(-21, 0.14, 19)
}
const EXAMINE_TEXTS := {
	"walls": {
		"source_id": "self",
		"channel": "settlement_observation",
		"text": "I examined Gujranwala outer walls (sealed greybox observation; not a town plan)."
	},
	"gate": {
		"source_id": "self",
		"channel": "settlement_observation",
		"text": "I examined the settlement gate (local attributed observation; not omniscience)."
	},
	"well": {
		"source_id": "self",
		"channel": "settlement_observation",
		"text": "I marked the settlement well (sealed greybox fact; no town economy)."
	},
	"house": {
		"source_id": "self",
		"channel": "settlement_observation",
		"text": "I noted a household compound marker (place Gujranwala; household sukerchakia; not a Person)."
	}
}
const RUMOR_REQUEST_TEXT := {
	"source_id": "self",
	"channel": "settlement_choice",
	"text": "I requested delayed local settlement word (custody; not live omniscience)."
}
const LOCAL_RUMOR_TEXT := {
	"source_id": "fictional_settlement_courier",
	"channel": "delayed_settlement_rumor",
	"text": "Local courier returned late: hearth smoke toward the walled town; garhi unverified (sealed until delivery)."
}
const FACT_LOCAL_WORD := "local_hearth_word"

func _init() -> void:
	super._init()
	_ensure_settlement()

func _ensure_settlement() -> Dictionary:
	if not _state.mahan.has("settlement") or not _state.mahan.settlement is Dictionary:
		_state.mahan.settlement = _fresh_settlement()
	var sett: Dictionary = _state.mahan.settlement
	for key in ["examined", "rumors", "facts"]:
		if not sett.has(key):
			_state.mahan.settlement = _fresh_settlement()
			return _state.mahan.settlement
	return sett

func _fresh_settlement() -> Dictionary:
	return {
		"examined": [],
		"rumors": [],
		"facts": {
			FACT_LOCAL_WORD: {"player_knowledge": false}
		}
	}

func settlement() -> Dictionary:
	return _ensure_settlement().duplicate(true)

func settlement_marker(kind: String) -> Vector3:
	return SETTLEMENT_MARKERS.get(kind, Vector3.ZERO)

func settlement_marker_ids() -> Array:
	return SETTLEMENT_MARKERS.keys()

func examined_markers() -> Array:
	return _ensure_settlement().examined.duplicate()

func pending_settlement_rumors() -> Array:
	var out: Array = []
	for rumor in _ensure_settlement().rumors:
		if not rumor.delivered:
			out.append(rumor.duplicate(true))
	return out

func received_settlement_rumors() -> Array:
	var out: Array = []
	for rumor in _ensure_settlement().rumors:
		if rumor.delivered:
			out.append(rumor.duplicate(true))
	return out

func settlement_fact_known(fact_id: String) -> bool:
	var facts: Dictionary = _ensure_settlement().facts
	if not facts.has(fact_id):
		return false
	return bool(facts[fact_id].get("player_knowledge", false))

func near_settlement_marker(kind: String = "") -> bool:
	if kind != "":
		if not SETTLEMENT_MARKERS.has(kind):
			return false
		return position().distance_to(SETTLEMENT_MARKERS[kind]) <= 2.5
	for mid in SETTLEMENT_MARKERS:
		if position().distance_to(SETTLEMENT_MARKERS[mid]) <= 2.5:
			return true
	return false

func settlement_observation_available() -> String:
	## Empty string means the observation beat may open.
	if is_mounted():
		return "Dismount before examining the Gujranwala settlement."
	if stage() != "march":
		return "Reach the march stage before settlement observation."
	var enc := encounter()
	var at_settlement: bool = str(_state.mahan.column_node) == SETTLEMENT_NODE
	var after_advance: bool = bool(enc.resolved) and str(enc.choice) == "advance_under_custody"
	if not at_settlement and not after_advance:
		return "Stand the column at Gujranwala settlement, or resolve the approach encounter by advancing under custody."
	if SETTLEMENT_NODE not in _state.mahan.known_nodes:
		return "Gujranwala settlement is not yet in delivered scout custody."
	if not near(SETTLEMENT_NODE) and not near_settlement_marker() and not near("camp_table"):
		return "Stand at the settlement, a settlement marker, or the camp table."
	return ""

func examine_settlement_marker(kind: String) -> String:
	if kind not in SETTLEMENT_MARKERS:
		return "Unknown settlement marker."
	if is_mounted():
		return "Dismount before examining a settlement marker."
	var refuse := settlement_observation_available()
	if not refuse.is_empty():
		return refuse
	if not near(SETTLEMENT_NODE) and not near_settlement_marker(kind):
		return "Stand at the settlement or beside the %s marker." % kind
	var sett := _ensure_settlement()
	if kind in sett.examined:
		return "That settlement marker is already examined."
	var authored: Dictionary = EXAMINE_TEXTS[kind]
	sett.examined.append(kind)
	_remember("settlement_examine_%s" % kind, authored.source_id, authored.channel, authored.text)
	return ""

func request_local_settlement_rumor() -> String:
	## Non-terminal: schedules delayed local rumor; player_knowledge stays false until delivery.
	if is_mounted():
		return "Dismount before requesting local settlement word."
	var refuse := settlement_observation_available()
	if not refuse.is_empty():
		return refuse
	var sett := _ensure_settlement()
	if not sett.rumors.is_empty():
		return "A local settlement rumor is already on the book."
	if settlement_fact_known(FACT_LOCAL_WORD):
		return "Local settlement hearth-word is already known."
	sett.rumors.append({
		"id": "settlement_local_rumor.report",
		"target": FACT_LOCAL_WORD,
		"observer_id": "settlement_courier",
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + SETTLEMENT_DELAY,
		"delivered": false,
		"source_id": LOCAL_RUMOR_TEXT.source_id,
		"channel": LOCAL_RUMOR_TEXT.channel,
		"text": LOCAL_RUMOR_TEXT.text
	})
	_remember("settlement_request_local_rumor", RUMOR_REQUEST_TEXT.source_id, RUMOR_REQUEST_TEXT.channel, RUMOR_REQUEST_TEXT.text)
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.settlement = _ensure_settlement().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_settlement_rumors()

func _deliver_due_settlement_rumors() -> void:
	var sett := _ensure_settlement()
	for rumor in sett.rumors:
		if rumor.delivered or (not (_state.mahan.tick >= rumor.arrives_at)):
			continue
		rumor.delivered = true
		_remember(rumor.id, rumor.source_id, rumor.channel, rumor.text)
		var fact_id := str(rumor.target)
		if sett.facts.has(fact_id):
			sett.facts[fact_id].player_knowledge = true

func _settlement_memory_id(id: String) -> bool:
	return str(id).begins_with("settlement_")

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan settlement snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var sett = m.get("settlement")
	var stripped_parent_path := false
	if sett == null:
		for memory in m.memories:
			if _settlement_memory_id(str(memory.id)):
				return "Mahan settlement envelope missing."
		sett = _fresh_settlement()
		stripped_parent_path = true
	elif not sett is Dictionary:
		return "Mahan settlement envelope missing."
	var ledger_err := SettlementValidate.validate_ledger(self, 
		value if not stripped_parent_path else {"mahan": {"settlement": sett, "tick": m.tick, "memories": [], "household_id": m.get("household_id", "sukerchakia")}},
		sett,
		stripped_parent_path
	)
	if not ledger_err.is_empty():
		return ledger_err
	var kept: Array = []
	var settlement_memories: Array = []
	for memory in m.memories:
		if _settlement_memory_id(str(memory.id)):
			settlement_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("settlement")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return SettlementValidate.validate_memories(self, value, settlement_memories)

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var sett: Dictionary = core.mahan.settlement.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _settlement_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("settlement")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.settlement = {
		"examined": [],
		"rumors": [],
		"facts": {
			FACT_LOCAL_WORD: {"player_knowledge": bool(sett.facts[FACT_LOCAL_WORD].player_knowledge)}
		}
	}
	for kind in sett.examined:
		_state.mahan.settlement.examined.append(str(kind))
	for rumor in sett.rumors:
		var copy: Dictionary = rumor.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.settlement.rumors.append(copy)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
