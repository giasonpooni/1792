extends "res://campaign/command_state.gd"
## Extends the existing authority. All mutable data stays in its ONE _state.
## Deliberately bounded: one fictional estate petition, not a general social simulator.

const Riding := preload("res://mounts/riding_rules.gd")
const Companions := preload("res://patrol/companion_rules.gd")

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
	if has_companions() and _state.companions.pending_outcome != "":
		return "The field decision is committed. Return the patrol before revising its terms."
	if is_mounted():
		return "Dismount before negotiating at the table."
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
	if has_companions():
		return _begin_patrol_return(choice)
	return _commit_patrol_outcome(choice)

func _commit_patrol_outcome(choice: String) -> String:
	if is_mounted() and actor_id() == CAPTAIN:
		return "Dismount before resolving the patrol."
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
	if candidate.has("riding"):
		var riding_error := Riding.validate(candidate.riding, candidate)
		if not riding_error.is_empty():
			return riding_error
	if candidate.has("companions"):
		if not candidate.has("house_conflict"):
			return "Companions require the house-command profile."
		var companion_error := Companions.validate(candidate.companions, candidate)
		if not companion_error.is_empty():
			return companion_error
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
		var template := {"sequence": 0, "tick": 0, "kind": "", "actor_id": "", "order_id": "", "petition_id": "", "outpost_observed": false}
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
		if report.order_id != expected.report.order_id or report.observed_at != expected.report.observed_at or report.outcome != expected.report.outcome or ("outpost" in candidate.order.visited) != expected.report.outpost_observed:
			return "House and patrol evidence disagree."
	elif expected.phase != "dormant" and candidate.order.status in ["reporting", "completed"]:
		return "A resolved house commission is missing its consequence."
	return ""

func restore(candidate: Variant) -> String:
	var riding_was_enabled := _state.has("riding")
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
	if riding_was_enabled and not next.has("riding"):
		next.riding = Riding.initial()
	if next.has("riding"):
		Riding.normalize(next.riding)
	if next.has("companions"):
		Companions.normalize(next.companions)
	_state = next
	return ""

func _house_event(kind: String, actor: String) -> Dictionary:
	return {"sequence": _state.house_conflict.history.size() + 1,
		"tick": _state.campaign_tick, "kind": kind, "actor_id": actor,
		"order_id": _state.order.id, "petition_id": PETITION_ID,
		"outpost_observed": "outpost" in _state.order.visited}

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
		if outcome == "secure" and (not event.outpost_observed or p.decision not in ["respect_claim", "assert_authority", "reconcile"]):
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
			"outpost_observed": event.outpost_observed,
			"territory": p.territory.duplicate(true) if event.outpost_observed else null}
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


# Riding is opt-in so legacy domain-only consumers retain their exact snapshots.
# The Houses and rivals scene opts in; no additional world authority is created.
func enable_riding() -> void:
	if not _state.has("riding"):
		_state.riding = Riding.initial()

func horse_state() -> Dictionary:
	return _state.riding.horse.duplicate(true) if _state.has("riding") else {}

func is_mounted() -> bool:
	return _state.has("riding") and _state.riding.horse.rider_id != ""

func mount_horse() -> String:
	if not _state.has("riding") or is_mounted():
		return "No available household horse."
	var h: Dictionary = _state.riding.horse
	if actor_position(actor_id()).distance_to(Riding.position(h)) > Riding.MOUNT_DISTANCE:
		return "Walk closer to the household horse."
	if not h.grounded or h.speed != 0.0:
		return "The horse must be stopped on the ground."
	h.rider_id = actor_id()
	_state.actors[actor_id()].position = h.position.duplicate()
	_state.player.position = h.position.duplicate()
	return ""

func dismount_horse(landing: Vector3) -> String:
	if not is_mounted():
		return "You are not mounted."
	var h: Dictionary = _state.riding.horse
	if h.speed > Riding.DISMOUNT_SPEED or not h.grounded:
		return "Stop on solid ground before dismounting."
	if not landing.is_finite():
		return "No clear dismount position."
	var delta := landing - Riding.position(h)
	var horizontal := Vector2(delta.x, delta.z).length()
	if horizontal < 1.2 or horizontal > 2.8 or absf(delta.y) > Riding.MAX_DISMOUNT_VERTICAL:
		return "Dismount position is too far from the horse."
	h.rider_id = ""
	h.speed = 0.0
	h.vertical_speed = 0.0
	record_position(landing)
	return ""

func record_ride(motion: Dictionary, delta: float) -> String:
	if not is_mounted() or not is_finite(delta) or delta <= 0.0 or delta > 0.25:
		return "No valid mounted physics step."
	if motion.size() != 5:
		return "Malformed horse motion."
	var next: Dictionary = _state.riding.duplicate(true)
	for key in ["position", "yaw", "speed", "vertical_speed", "grounded"]:
		if not motion.has(key):
			return "Incomplete horse motion."
		next.horse[key] = motion[key]
	if not Riding.valid_position(next.horse.position):
		return "Invalid horse position."
	var travelled := Riding.position(next.horse) - Riding.position(_state.riding.horse)
	if Vector2(travelled.x, travelled.z).length() > Riding.MAX_SPEED * delta + 0.1 or absf(travelled.y) > Riding.MAX_FALL * delta + 0.1:
		return "Horse step exceeds the movement envelope."
	var candidate := {"player": {"character_id": actor_id(), "position": next.horse.position},
		"actors": {}, "order": _state.order}
	candidate.actors[actor_id()] = {"position": next.horse.position}
	var error := Riding.validate(next, candidate)
	if not error.is_empty():
		return error
	_state.riding = next
	_state.actors[actor_id()].position = candidate.player.position.duplicate()
	_state.player.position = candidate.player.position.duplicate()
	return ""

func record_position(position: Vector3) -> void:
	if not is_mounted():
		super.record_position(position)

func play_commander() -> String:
	var error: String = "Dismount before taking the captain's viewpoint." if is_mounted() else super.play_commander()
	if error.is_empty() and has_companions() and _state.companions.phase == "mustered":
		_state.companions.phase = "outbound"
	return error

func return_to_darbar() -> String:
	return "Dismount before delegating the captain." if is_mounted() else super.return_to_darbar()

func visit(site_id: String) -> String:
	if has_companions() and _state.companions.phase == "returning":
		return "Field decision recorded. Return to the courtyard now."
	return "Dismount before speaking at this location." if is_mounted() else super.visit(site_id)

func resolve(choice: String) -> String:
	return "Dismount before resolving the patrol." if is_mounted() else super.resolve(choice)


# The physical patrol is opt-in at the existing table, after allocation and before
# departure. Older saves and the earlier abstract patrol keep their exact rules.
func has_companions() -> bool:
	return _state.has("companions")

func companion_state() -> Dictionary:
	return _state.companions.duplicate(true) if has_companions() else {}

func muster_patrol() -> String:
	if is_mounted() or actor_id() != RANJIT or not near_site("lahore_darbar"):
		return "Muster as Ranjit, on foot at the command table."
	if _state.order.status != "assigned" or has_companions():
		return "Assign a patrol, then muster its companions once before departure."
	_state.companions = Companions.initial(_state.order, actor_position(CAPTAIN))
	_event("patrol_mustered", RANJIT)
	return ""

func cancel() -> String:
	var error: String = super.cancel()
	if error.is_empty():
		_state.erase("companions")
	return error

func delegate() -> String:
	if is_mounted():
		return "Dismount before delegating."
	var error: String = super.delegate()
	if error.is_empty() and has_companions():
		_state.companions.phase = "outbound"
	return error

func command_companions(instruction: String) -> String:
	if not has_companions() or _state.order.status != "active" or actor_id() != CAPTAIN:
		return "Take the active captain's viewpoint to command companions."
	if instruction not in ["follow", "hold"]:
		return "Unknown companion order."
	if _state.companions.instruction == instruction:
		return "The patrol already has that instruction."
	for member in _state.companions.members:
		if Companions.horizontal(Companions.point(member.position), actor_position(CAPTAIN)) > Companions.CALL_RADIUS:
			return "A trooper is out of calling range. Ride or walk closer before regrouping."
	_state.companions.instruction = instruction
	_event("companions_" + instruction, CAPTAIN)
	return ""

func assembled_at(point: Vector3, radius: float = Companions.ASSEMBLY_RADIUS) -> int:
	var count := 0
	if has_companions():
		for member in _state.companions.members:
			if Companions.horizontal(Companions.point(member.position), point) <= radius and absf(member.position[1] - point.y) < 0.8:
				count += 1
	return count

func _begin_patrol_return(choice: String) -> String:
	if _state.order.status != "active" or _state.companions.phase != "outbound" or (is_mounted() and actor_id() == CAPTAIN):
		return "No uncommitted dismounted patrol is available."
	if choice not in ["secure", "withdraw"]:
		return "Unknown patrol decision."
	if choice == "secure":
		if _state.order.visited != ["village", "outpost"] or _state.order.allocation.riders < 3:
			return "Observe both sites with the four-person patrol before securing the road."
		var p: Array = place("outpost").position
		if Companions.horizontal(actor_position(CAPTAIN), Companions.point(p)) > 4.0 or assembled_at(Companions.point(p)) < 2:
			return "Regroup at the outpost: the captain and at least two troopers must be present."
		var politics: Dictionary = _state.house_conflict
		if politics.phase != "dormant" and politics.decision not in ["respect_claim", "assert_authority", "reconcile"]:
			return "Observation-only commission. Settle it in Lahore or withdraw."
	_state.companions.phase = "returning"
	_state.companions.pending_outcome = choice
	_state.companions.decision_tick = _state.campaign_tick
	# A hold order is not silently discarded. Recall the group before returning.
	_event("patrol_return_requested:" + choice, CAPTAIN)
	return ""

func finish_patrol() -> String:
	if not has_companions() or _state.companions.phase != "returning" or _state.order.status != "active":
		return "There is no returning physical patrol."
	if is_mounted() and actor_id() == CAPTAIN:
		return "Dismount before checking the patrol in."
	if Companions.horizontal(actor_position(CAPTAIN), Companions.HOME) > 3.5 or assembled_at(Companions.HOME) != _state.companions.members.size():
		return "Bring the captain and every companion back to the courtyard first."
	var error := _commit_patrol_outcome(_state.companions.pending_outcome)
	if error.is_empty():
		_state.companions.phase = "reporting"
		_state.companions.return_tick = _state.campaign_tick
		for member in _state.companions.members:
			member.velocity = [0.0, 0.0, 0.0]
	return error

func patrol_destination() -> Vector3:
	if has_companions() and _state.companions.phase == "returning":
		return Companions.HOME
	var site_id := "village" if _state.order.visited.is_empty() else "outpost"
	return Companions.point(place(site_id).position)

func _delegate_tick() -> void:
	if not has_companions():
		super._delegate_tick()
		return
	# Physical adapters move the captain and troopers. No second position step
	# occurs in the abstract policy; headless callers without physics simply wait.
	if _state.companions.phase == "returning":
		finish_patrol()
		return
	if _state.order.visited.size() == 2:
		_resolve("secure" if _state.order.allocation.riders >= 3 else "withdraw")
		return
	if Companions.horizontal(actor_position(CAPTAIN), patrol_destination()) <= 1.2:
		_visit("village" if _state.order.visited.is_empty() else "outpost")

func advance(ticks: int = 1) -> void:
	super.advance(ticks)
	if has_companions() and _state.order.status == "completed":
		_state.companions.phase = "completed"

func record_patrol_motion(id: String, motion: Dictionary, delta: float) -> String:
	if not has_companions() or _state.order.status != "active" or not is_finite(delta) or delta <= 0.0 or delta > 0.25:
		return "No valid companion physics step."
	if not Companions.valid_member(motion, id):
		return "Invalid patrol motion."
	var previous := Vector3.ZERO
	var member_index := -1
	if id == CAPTAIN:
		if _state.order.mode != "delegated":
			return "Manual captain position belongs to the player controller."
		previous = actor_position(CAPTAIN)
	else:
		for i in range(_state.companions.members.size()):
			if _state.companions.members[i].id == id:
				member_index = i
		if member_index < 0:
			return "Unknown allocated companion."
		previous = Companions.point(_state.companions.members[member_index].position)
	var next := Companions.point(motion.position)
	if Companions.horizontal(previous, next) > Companions.SPEED * delta + 0.03 or absf(previous.y - next.y) > 50.0 * delta + 0.03:
		return "Patrol motion exceeds the physical movement envelope."
	if member_index < 0:
		_state.actors[CAPTAIN].position = motion.position.duplicate()
	else:
		_state.companions.members[member_index] = motion.duplicate(true)
	return ""
