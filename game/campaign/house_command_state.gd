extends "res://campaign/command_state.gd"
## Extends the existing authority. All mutable data stays in its ONE _state.
## Deliberately bounded: one fictional estate petition, not a general social simulator.

const ROSTER_PATH := "res://data/antagonists.json"
const HOUSE_VERSION := "house-conflict.v1"
const PETITION_ID := "kanhaiya_road_claim_01"
const MAX_HOUSE_EVENTS := 8

func _init() -> void:
	super()
	_state.house_conflict = _initial_house_state()

func roster() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))

func biography(id: String) -> Dictionary:
	for person in roster().people:
		if person.id == id:
			return person.duplicate(true)
	return {}

func house_state() -> Dictionary:
	return _state.house_conflict.duplicate(true)

func petition(action: String) -> String:
	if actor_id() != RANJIT or not near_site("lahore_darbar"):
		return "Only Ranjit can negotiate at the Lahore command table."
	if _state.order.status in ["reporting", "completed"]:
		return "This patrol has already reported its decision."
	if action not in ["begin", "respect_claim", "assert_authority", "defer", "reconcile"]:
		return "Unknown house decision."
	var next: Dictionary = _state.house_conflict.duplicate(true)
	var error := _reduce_house(next, _house_event(action, RANJIT))
	if error.is_empty():
		_state.house_conflict = next
	return error

func _resolve(choice: String) -> String:
	var next: Dictionary = _state.house_conflict.duplicate(true)
	if next.phase != "dormant":
		if choice == "secure" and next.decision in ["", "defer"]:
			return "The estate petition permits observation only. Ranjit must settle the commission at the table, or the captain must withdraw."
		if choice in ["secure", "withdraw"]:
			var error := _reduce_house(next, _house_event("patrol_" + choice, CAPTAIN))
			if not error.is_empty():
				return error
	var base_error := super._resolve(choice)
	if not base_error.is_empty():
		return base_error
	_state.house_conflict = next
	return ""

func received_house_report() -> Dictionary:
	# Report delivery authority remains the ORIGINAL report, not another timer.
	var extra: Dictionary = _state.house_conflict.report
	if extra.is_empty():
		return {}
	for received in received_reports():
		if received.order_id == extra.order_id:
			return extra.duplicate(true)
	return {}

func validate(candidate: Variant) -> String:
	var base_error := super.validate(candidate)
	if not base_error.is_empty():
		return base_error
	# Explicit additive import of a legacy command-story save; the caller installs
	# an empty extension only AFTER the complete legacy state has passed validation.
	if not candidate.has("house_conflict"):
		return ""
	var p = candidate.house_conflict
	if not p is Dictionary or not p.get("history") is Array:
		return "Malformed house state."
	if p.history.size() > MAX_HOUSE_EVENTS:
		return "House history exceeds the bounded story."
	var expected := _initial_house_state()
	var last_tick := 0
	var issued_ids: Array = [""]
	for event in candidate.events:
		if event.kind == "order_issued":
			issued_ids.append(event.order_id)
	for item in p.history:
		var template := {"sequence": 0, "tick": 0, "kind": "", "actor_id": "", "order_id": "", "petition_id": ""}
		if not item is Dictionary or item.size() != template.size() or not _shape(item, template, "house_event").is_empty():
			return "Malformed house event."
		if not _whole(item.sequence, 1) or item.sequence != expected.history.size() + 1:
			return "Invalid house event sequence."
		if not _whole(item.tick, last_tick) or item.tick > candidate.campaign_tick:
			return "Invalid house event time."
		if item.order_id not in issued_ids or item.petition_id != PETITION_ID:
			return "Unbound house event."
		var error := _reduce_house(expected, item)
		if not error.is_empty():
			return error
		last_tick = int(item.tick)
	if not _same_value(p, expected):
		return "House state disagrees with its validated decision history."
	if expected.phase == "resolved":
		if candidate.order.status not in ["reporting", "completed"] or candidate.reports.size() != 1:
			return "House consequence has no resolved command."
		var report: Dictionary = candidate.reports[0]
		if report.order_id != expected.report.order_id or report.observed_at != expected.report.observed_at or report.outcome != expected.report.outcome:
			return "House and patrol evidence disagree."
	elif expected.phase != "dormant" and candidate.order.status in ["reporting", "completed"]:
		return "A resolved house commission is missing its consequence."
	return ""

func restore(candidate: Variant) -> String:
	var error := validate(candidate)
	if not error.is_empty():
		return error # Never install a partially valid snapshot.
	var next: Dictionary = candidate.duplicate(true)
	_normalize_counts(next)
	if not next.has("house_conflict"):
		next.house_conflict = _initial_house_state()
	else:
		# Rebuild derived integer scores after JSON's integer-to-float conversion.
		var normalized := _initial_house_state()
		for item in next.house_conflict.history:
			item.sequence = int(item.sequence)
			item.tick = int(item.tick)
			_reduce_house(normalized, item)
		next.house_conflict = normalized
	_state = next
	return ""

func _house_event(kind: String, actor: String) -> Dictionary:
	return {"sequence": _state.house_conflict.history.size() + 1,
		"tick": _state.campaign_tick, "kind": kind, "actor_id": actor,
		"order_id": _state.order.id, "petition_id": PETITION_ID}

func _initial_house_state() -> Dictionary:
	return {
		"schema_version": HOUSE_VERSION, "roster_version": "antagonist-roster.v1",
		"scenario_id": "fictional_lahore_estate_petition", "historical_class": "fictional_connective_material",
		"phase": "dormant", "decision": "", "history": [],
		"relations": {
			"sada_kaur": {"stance": "patron", "trust": 60, "grievance": 20, "autonomy": 85},
			"mehtab_kaur": {"stance": "dynastic_counterweight", "trust": 50, "grievance": 20, "autonomy": 60},
			"datar_kaur": {"stance": "ally", "trust": 65, "grievance": 10, "autonomy": 60}
		},
		"territory": {"military_presence": "none", "passage": "uncertain", "local_cooperation": 35,
			"revenue_claim": "kanhaiya_house", "revenue_status": "disputed", "annexed": false},
		"report": {}
	}

func _reduce_house(p: Dictionary, event: Dictionary) -> String:
	# All transitions are explicit authored rules, not estimates of historical motives.
	if p.history.size() >= MAX_HOUSE_EVENTS:
		return "House story event limit reached."
	var kind: String = event.kind
	var r: Dictionary = p.relations.sada_kaur
	if kind.begins_with("patrol_"):
		if kind not in ["patrol_secure", "patrol_withdraw"] or event.actor_id != CAPTAIN or event.order_id.is_empty():
			return "Invalid house consequence executor."
		if p.phase not in ["awaiting_response", "decided"]:
			return "There is no unresolved estate petition."
		var outcome := kind.trim_prefix("patrol_")
		if outcome == "secure" and p.decision not in ["respect_claim", "assert_authority", "reconcile"]:
			return "No authority to secure the road under this commission."
		if outcome == "secure":
			if p.decision == "assert_authority":
				p.territory.military_presence = "darbar_patrol"
				p.territory.passage = "contested"
				p.territory.local_cooperation = 20
				p.territory.revenue_status = "disputed"
			else:
				p.territory.military_presence = "joint_patrol"
				p.territory.passage = "permitted"
				p.territory.local_cooperation = 60
				p.territory.revenue_status = "recognized_local_claim"
		p.phase = "resolved"
		p.report = {"id": event.order_id + ".house-report", "order_id": event.order_id,
			"observer_id": CAPTAIN, "observed_at": event.tick,
			"arrives_at": event.tick + REPORT_DELAY, "outcome": outcome,
			"territory": p.territory.duplicate(true)}
	else:
		if event.actor_id != RANJIT:
			return "A house NPC or captain cannot issue Ranjit's concessions."
		match kind:
			"begin":
				if p.phase != "dormant":
					return "The envoy's petition has already been heard."
				p.phase = "awaiting_response"
				r.stance = "competing_patron"
			"respect_claim", "assert_authority", "defer":
				if p.phase != "awaiting_response":
					return "This petition already has instructions."
				p.phase = "decided"
				p.decision = kind
				if kind == "respect_claim":
					r.stance = "ally"
					r.trust = 70
					r.grievance = 15
				elif kind == "assert_authority":
					r.stance = "rival"
					r.trust = 40
					r.grievance = 65
				else:
					r.stance = "competing_patron"
					r.trust = 55
					r.grievance = 35
			"reconcile":
				if p.phase != "decided" or p.decision not in ["assert_authority", "defer"]:
					return "Only a disputed commission can be reconciled before reporting."
				p.decision = kind
				r.stance = "ally"
				r.trust = 60
				r.grievance = 25
			_:
				return "Unknown house event."
	p.history.append(event.duplicate(true))
	return ""

func _same_value(a: Variant, b: Variant) -> bool:
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return is_finite(float(a)) and is_finite(float(b)) and a == b
	if typeof(a) != typeof(b):
		return false
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for key in b:
			if not a.has(key) or not _same_value(a[key], b[key]):
				return false
	elif a is Array:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not _same_value(a[i], b[i]):
				return false
	else:
		return a == b
	return true
