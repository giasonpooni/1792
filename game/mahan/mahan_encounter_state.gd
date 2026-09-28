extends "res://mahan/mahan_history_state.gd"
## Mahan-only Gujranwala ridge→settlement authored encounter stub.
## Greybox beat on fort_road / camp / settlement; delayed scout custody;
## player choices stay within the fixed historical endpoint (no alternate-history win).
## No combat AI; does not rewrite house_command_state or world_state.schema.json.
const ENCOUNTER_EVENT_ID := "mahan_gujranwala_ridge_settlement_approach"
const ENCOUNTER_DELAY := 80
const ENCOUNTER_NODES := ["gujranwala_fort_road", "gujranwala_camp", "gujranwala_settlement"]
const ENCOUNTER_MARKER := Vector3(-14, 0.14, 12)
const RESOLVE_CHOICES := ["hold_observe", "advance_under_custody"]
const CHOICE_TEXTS := {
	"hold_observe": {
		"source_id": "self",
		"channel": "encounter_choice",
		"text": "I held the horse column on the Gujranwala approach and observed the home-ground line from fort road toward the settlement. Observation does not invent a street survey, open combat, or alter the fixed historical endpoint."
	},
	"advance_under_custody": {
		"source_id": "self",
		"channel": "encounter_choice",
		"text": "I advanced the column under delivered approach custody toward Gujranwala staging ground. The choice stays inside the authored historical frame; there is no alternate-history survival win."
	}
}
const DISPATCH_TEXT := {
	"source_id": "self",
	"channel": "encounter_choice",
	"text": "I dispatched an approach scout along the ridge→settlement greybox path. Custody arrives on a delay clock; this is not live sight and does not rewrite Mahan's fixed endpoint."
}
const APPROACH_SCOUT_TEXT := {
	"source_id": "fictional_field_scout",
	"channel": "delayed_encounter_report",
	"text": "The approach scout returned late from the fort-road line. Dust and pack tracks run toward Gujranwala camp and the settlement beyond; the garhi motif remains unverified. Delayed custody only — not a combat resolution."
}

func _init() -> void:
	super._init()
	_ensure_encounter()

func _ensure_encounter() -> Dictionary:
	if not _state.mahan.has("encounter") or not _state.mahan.encounter is Dictionary:
		_state.mahan.encounter = _fresh_encounter()
	var enc: Dictionary = _state.mahan.encounter
	for key in ["active", "resolved", "choice", "scout_reports", "scout_dispatched"]:
		if not enc.has(key):
			_state.mahan.encounter = _fresh_encounter()
			return _state.mahan.encounter
	return enc

func _fresh_encounter() -> Dictionary:
	return {
		"active": false,
		"resolved": false,
		"choice": "",
		"scout_dispatched": false,
		"scout_reports": []
	}

func encounter() -> Dictionary:
	return _ensure_encounter().duplicate(true)

func encounter_marker() -> Vector3:
	return ENCOUNTER_MARKER

func encounter_nodes() -> Array:
	return ENCOUNTER_NODES.duplicate()

func pending_encounter_reports() -> Array:
	var out: Array = []
	for report in _ensure_encounter().scout_reports:
		if not report.delivered:
			out.append(report.duplicate(true))
	return out

func received_encounter_reports() -> Array:
	var out: Array = []
	for report in _ensure_encounter().scout_reports:
		if report.delivered:
			out.append(report.duplicate(true))
	return out

func near_encounter_marker() -> bool:
	return position().distance_to(ENCOUNTER_MARKER) <= 2.5

func encounter_available() -> String:
	## Empty string means the authored encounter may open; otherwise a refuse reason.
	if is_mounted():
		return "Dismount before opening the ridge→settlement encounter."
	if stage() != "march":
		return "Reach the march stage before the Gujranwala approach encounter."
	if _state.mahan.decision != "advance_scouts":
		return "The approach encounter applies while the horse column is advancing."
	var enc := _ensure_encounter()
	if enc.resolved:
		return "The ridge→settlement encounter stub is already resolved."
	var node: String = str(_state.mahan.column_node)
	if node not in ENCOUNTER_NODES:
		return "Stand the column on the Gujranwala fort road, camp, or settlement approach."
	if node not in _state.mahan.known_nodes:
		return "That Gujranwala node is not yet in delivered scout custody."
	if not near(node) and not near_encounter_marker() and not near("camp_table"):
		return "Stand with the column, at the encounter marker, or at the camp table."
	return ""

func begin_ridge_settlement_encounter() -> String:
	var refuse := encounter_available()
	if not refuse.is_empty():
		return refuse
	var enc := _ensure_encounter()
	if enc.active:
		return ""
	enc.active = true
	## Observing the authored frame is allowed once the beat opens (direct observer).
	if not _ensure_history().events[ENCOUNTER_EVENT_ID].player_knowledge:
		var obs := observe_historical_event(ENCOUNTER_EVENT_ID)
		if not obs.is_empty() and obs != "This historical frame is already known.":
			enc.active = false
			return obs
	return ""

func _ensure_active() -> String:
	var enc := _ensure_encounter()
	if enc.resolved:
		return "The ridge→settlement encounter stub is already resolved."
	if enc.active:
		return ""
	return begin_ridge_settlement_encounter()

func dispatch_approach_scout() -> String:
	## Non-terminal: schedules delayed scout custody; resolve still required.
	var open_err := _ensure_active()
	if not open_err.is_empty():
		return open_err
	if is_mounted():
		return "Dismount before dispatching an approach scout."
	var enc := _ensure_encounter()
	if enc.scout_dispatched or not enc.scout_reports.is_empty():
		return "An approach scout is already on the book."
	enc.scout_dispatched = true
	enc.scout_reports.append({
		"id": "encounter_approach_scout.report",
		"target": "approach_scout",
		"observer_id": "field_scout",
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + ENCOUNTER_DELAY,
		"delivered": false,
		"source_id": APPROACH_SCOUT_TEXT.source_id,
		"channel": APPROACH_SCOUT_TEXT.channel,
		"text": APPROACH_SCOUT_TEXT.text
	})
	_remember("encounter_dispatch_approach_scout", DISPATCH_TEXT.source_id, DISPATCH_TEXT.channel, DISPATCH_TEXT.text)
	return ""

func choice_allowed(kind: String) -> String:
	if kind not in RESOLVE_CHOICES:
		return "Unknown encounter choice."
	if is_mounted():
		return "Dismount before making an encounter choice."
	var open_err := _ensure_active()
	if not open_err.is_empty():
		return open_err
	var enc := _ensure_encounter()
	if enc.resolved:
		return "The ridge→settlement encounter stub is already resolved."
	if kind == "advance_under_custody" and received_encounter_reports().is_empty():
		return "Advance under custody requires a delivered approach-scout report."
	return ""

func resolve_encounter_choice(kind: String) -> String:
	## Terminal choices stay inside the fixed historical endpoint — none alter death / survival.
	var refuse := choice_allowed(kind)
	if not refuse.is_empty():
		return refuse
	var enc := _ensure_encounter()
	var authored: Dictionary = CHOICE_TEXTS[kind]
	enc.choice = kind
	enc.resolved = true
	enc.active = false
	_remember("encounter_%s" % kind, authored.source_id, authored.channel, authored.text)
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.encounter = _ensure_encounter().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_encounter_reports()

func _deliver_due_encounter_reports() -> void:
	var enc := _ensure_encounter()
	for report in enc.scout_reports:
		if report.delivered or (not (_state.mahan.tick >= report.arrives_at)):
			continue
		report.delivered = true
		_remember(report.id, report.source_id, report.channel, report.text)

func _encounter_memory_id(id: String) -> bool:
	return str(id).begins_with("encounter_")

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan encounter snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var enc = m.get("encounter")
	var stripped_parent_path := false
	if enc == null:
		for memory in m.memories:
			if _encounter_memory_id(str(memory.id)):
				return "Mahan encounter envelope missing."
		enc = _fresh_encounter()
		stripped_parent_path = true
	elif not enc is Dictionary:
		return "Mahan encounter envelope missing."
	var ledger_err := _validate_encounter_ledger(
		value if not stripped_parent_path else {"mahan": {"encounter": enc, "tick": m.tick, "memories": [], "household_id": m.get("household_id", "sukerchakia")}},
		enc,
		stripped_parent_path
	)
	if not ledger_err.is_empty():
		return ledger_err
	var kept: Array = []
	var encounter_memories: Array = []
	for memory in m.memories:
		if _encounter_memory_id(str(memory.id)):
			encounter_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("encounter")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return _validate_encounter_memories(value, encounter_memories)

func _validate_encounter_ledger(value: Dictionary, enc: Dictionary, stripped: bool) -> String:
	for key in ["active", "resolved", "choice", "scout_reports", "scout_dispatched"]:
		if not enc.has(key):
			return "Malformed encounter ledger."
	if typeof(enc.active) != TYPE_BOOL or typeof(enc.resolved) != TYPE_BOOL or typeof(enc.scout_dispatched) != TYPE_BOOL:
		return "Encounter flags must be boolean."
	if enc.active and enc.resolved:
		return "Encounter cannot be active and resolved."
	var choice := str(enc.choice)
	if choice != "" and choice not in RESOLVE_CHOICES:
		return "Unsupported encounter choice."
	if enc.resolved and choice == "":
		return "Resolved encounter requires a recorded choice."
	if not enc.resolved and choice != "":
		return "Encounter choice set before resolve."
	if not enc.scout_reports is Array:
		return "Malformed encounter scout reports."
	if enc.scout_reports.size() > 1:
		return "Only one approach scout may be on the book."
	if enc.scout_dispatched != (enc.scout_reports.size() == 1):
		return "Encounter scout_dispatched disagrees with scout_reports."
	var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
	for report in enc.scout_reports:
		if not report is Dictionary:
			return "Malformed encounter custody."
		for key in ["id", "target", "observer_id", "observed_at", "arrives_at", "delivered", "source_id", "channel", "text"]:
			if not report.has(key):
				return "Malformed encounter custody."
		if report.id != "encounter_approach_scout.report" or report.target != "approach_scout":
			return "Unsupported encounter scout identity."
		if report.observer_id != "field_scout":
			return "Encounter scout observer mismatch."
		if report.source_id != APPROACH_SCOUT_TEXT.source_id or report.channel != APPROACH_SCOUT_TEXT.channel or report.text != APPROACH_SCOUT_TEXT.text:
			return "Encounter scout text was rewritten."
		if report.arrives_at != report.observed_at + ENCOUNTER_DELAY:
			return "Invalid encounter scout delivery time."
		if report.observed_at != floor(report.observed_at) or report.observed_at < 0 or report.observed_at > tick:
			return "Invalid encounter observation time."
		var due: bool = tick >= report.arrives_at
		if report.delivered != due:
			return "Encounter delivery state disagrees with the clock."
	if stripped:
		return ""
	if str(value.mahan.get("household_id", "")) != "sukerchakia":
		return "Encounter slice requires sukerchakia household."
	return ""

func _validate_encounter_memories(value: Dictionary, encounter_memories: Array) -> String:
	var enc: Dictionary = value.mahan.encounter
	var expected: Array = []
	if enc.scout_dispatched:
		expected.append("encounter_dispatch_approach_scout")
	if str(enc.choice) != "":
		expected.append("encounter_%s" % enc.choice)
	for report in enc.scout_reports:
		if report.delivered:
			expected.append(report.id)
	if encounter_memories.size() != expected.size():
		return "Encounter memories disagree with encounter ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in encounter_memories:
		if not memory is Dictionary:
			return "Malformed encounter memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed encounter memory."
		if memory.observer_id != ACTOR_ID:
			return "Encounter memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid encounter memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if memory.id == "encounter_dispatch_approach_scout":
			if memory.source_id != DISPATCH_TEXT.source_id or memory.channel != DISPATCH_TEXT.channel or memory.text != DISPATCH_TEXT.text:
				return "Encounter dispatch memory was rewritten."
		elif str(memory.id).begins_with("encounter_") and not str(memory.id).ends_with(".report"):
			var kind := str(memory.id).trim_prefix("encounter_")
			if kind not in CHOICE_TEXTS:
				return "Unsupported encounter choice memory."
			var authored: Dictionary = CHOICE_TEXTS[kind]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Encounter choice memory was rewritten."
		elif memory.id == "encounter_approach_scout.report":
			if memory.source_id != APPROACH_SCOUT_TEXT.source_id or memory.channel != APPROACH_SCOUT_TEXT.channel or memory.text != APPROACH_SCOUT_TEXT.text:
				return "Delivered encounter scout memory was rewritten."
			var matched := false
			for report in enc.scout_reports:
				if report.id == memory.id and report.delivered and memory.received_tick == report.arrives_at:
					matched = true
			if not matched:
				return "Encounter scout memory tick disagrees with delivery custody."
		else:
			return "Unsupported encounter memory id."
	if not remaining.is_empty():
		return "Encounter memories disagree with encounter ledger."
	var parent_count: int = 0
	for memory in value.mahan.memories:
		if not _encounter_memory_id(str(memory.id)):
			parent_count += 1
	if value.mahan.memories.size() != parent_count + expected.size():
		return "Encounter journal size disagrees with experienced events."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var enc: Dictionary = core.mahan.encounter.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _encounter_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("encounter")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.encounter = {
		"active": bool(enc.active),
		"resolved": bool(enc.resolved),
		"choice": str(enc.choice),
		"scout_dispatched": bool(enc.scout_dispatched),
		"scout_reports": []
	}
	for report in enc.scout_reports:
		var copy: Dictionary = report.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.encounter.scout_reports.append(copy)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
