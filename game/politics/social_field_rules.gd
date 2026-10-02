# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Pure, bounded actor-belief projection. The existing politics reducer owns delivery.
## Scores are authored game variables, not probabilities or validated social science.
const VERSION := "social-field.v1"
const MAX_MEMORY := 128
const HORIZON := 7200

static func validate_profiles(profiles: Dictionary, subjects: Array) -> String:
	if profiles.is_empty() or profiles.size()>32 or subjects.is_empty() or subjects.size()>32: return "Invalid social graph capacity."
	var unique: Dictionary = {}
	for subject in subjects:
		if not subject is String or subject.is_empty() or subject.length()>128 or unique.has(subject): return "Invalid social subject."
		unique[subject] = true
	for id in profiles:
		if not id is String or id.is_empty() or id.length()>128: return "Invalid observer identity."
		var p: Variant = profiles[id]
		if not p is Dictionary or p.size()!=4: return "Malformed observer profile."
		if p.get("faction") not in subjects or not p.get("node") is String or p.node.is_empty(): return "Unresolved social link."
		if not _whole(p.get("delay")) or p.delay>3600: return "Invalid local route delay."
		if typeof(p.get("reliability")) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(p.reliability)) or p.reliability<=0 or p.reliability>1: return "Invalid authored reliability."
	return ""

static func initial(profiles: Dictionary, subjects: Array) -> Dictionary:
	if not validate_profiles(profiles,subjects).is_empty(): return {}
	var out := {"version":VERSION, "subjects":subjects.duplicate(), "actors":{}}
	for id in profiles:
		out.actors[id] = {"memory":{}, "forgotten_through":-1}
	return out

static func route(report: Dictionary, profiles: Dictionary) -> Array:
	# Returned receipts enter the SAME world queue, never a second timer or scheduler.
	var out: Array = []
	if report.kind not in ["raid", "incursion", "reparation"]: return out
	for id in profiles:
		var profile: Dictionary = profiles[id]
		if profile.faction != report.recipient: continue
		var local := report.duplicate(true)
		local.id = str(report.id)+":local:"+str(id)
		local.observer_id = id
		local.parent_receipt_id = report.id
		local.received_tick = int(report.received_tick)+int(profile.delay)
		local.confidence = float(report.confidence)*float(profile.reliability)
		local.path = [str(report.recipient)+":report_node", str(profile.node)]
		out.append(local)
	return out

static func receive(state: Dictionary, receipt: Dictionary, tick: int) -> String:
	# Admission validates before mutation. A repeated root is not independent evidence.
	for key in ["id", "event_id", "observer_id", "accused", "kind", "strength", "confidence", "source_id", "sent_tick", "received_tick", "parent_receipt_id", "path"]:
		if not receipt.has(key): return "Missing local receipt field."
	for key in ["id", "event_id", "observer_id", "accused", "kind", "source_id", "parent_receipt_id"]:
		if not receipt[key] is String or receipt[key].is_empty() or receipt[key].length()>256: return "Invalid local receipt identity."
	if not state.actors.has(receipt.observer_id): return "Unknown local observer."
	if receipt.accused not in state.subjects or receipt.kind not in ["raid", "incursion", "reparation"]: return "Unknown local claim."
	if not _whole(receipt.sent_tick) or not _whole(receipt.received_tick) or receipt.sent_tick>receipt.received_tick or receipt.received_tick>tick: return "Premature or malformed local receipt."
	for key in ["strength", "confidence"]:
		if typeof(receipt[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(receipt[key])) or receipt[key]<=0.0 or receipt[key]>1.0: return "Invalid local evidence weight."
	if not receipt.path is Array or receipt.path.size()!=2: return "Missing local communication path."
	for node in receipt.path:
		if not node is String or node.is_empty() or node.length()>256: return "Invalid local communication node."
	var actor: Dictionary = state.actors[receipt.observer_id]
	var root := str(receipt.event_id)+":"+str(receipt.kind)
	if actor.memory.has(root):
		var previous: Dictionary = actor.memory[root]
		if previous.accused != receipt.accused or previous.strength != receipt.strength or previous.sent_tick != receipt.sent_tick:
			return "Conflicting claim under an existing event root."
		if float(receipt.confidence)<=float(previous.confidence): return "" # Idempotent/correlated relay.
	elif int(receipt.sent_tick)<=int(actor.forgotten_through):
		return "Evidence is older than the retained memory window."
	var next: Dictionary = actor.memory.duplicate(true)
	# New evidence may replace confidence, but does not refresh an old incident's age.
	next[root] = receipt.duplicate(true)
	var floor_tick: int = int(actor.forgotten_through)
	while next.size()>MAX_MEMORY:
		var oldest: int = tick
		for item in next.values(): oldest = mini(oldest,int(item.sent_tick))
		# Evict the whole oldest time cohort; a tie must not depend on dictionary order.
		for key in next.keys():
			if int(next[key].sent_tick)==oldest: next.erase(key)
		floor_tick = maxi(floor_tick,oldest)
	actor.memory = next
	actor.forgotten_through = floor_tick
	return ""

static func sample(state: Dictionary, observer: String, subject: String, tick: int) -> Dictionary:
	if not state.actors.has(observer) or subject not in state.subjects or tick<0: return {}
	var field := {"trust":0.55, "grievance":0.0, "fear":0.0, "attention":0.0, "obligation":0.0}
	var roots: Array = []
	var memory: Dictionary = state.actors[observer].memory
	var ordered: Array = memory.keys()
	ordered.sort()
	for key in ordered:
		var item: Dictionary = memory[key]
		if item.accused!=subject or int(item.received_tick)>tick: continue
		var age: int = tick-int(item.sent_tick)
		if age<0 or age>=HORIZON: continue
		var weight := float(item.strength)*float(item.confidence)*(1.0-float(age)/HORIZON)
		roots.append(item.event_id)
		field.attention += weight
		if item.kind in ["raid", "incursion"]:
			field.grievance += weight
			field.trust -= 0.5*weight
			field.fear += 0.2*weight
		else:
			field.grievance -= weight
			field.trust += 0.6*weight
			field.obligation += 0.5*weight
	for key in field: field[key] = clampf(float(field[key]),0.0,1.0)
	var stance := "guarded" if field.grievance>=0.18 else "reassured" if field.trust>=0.60 and field.obligation>=0.12 else "reserved" if field.attention>=0.07 else "open"
	return {"observer_id":observer, "subject":subject, "tick":tick, "field":field, "stance":stance, "event_roots":roots}

static func _whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and value>=0 and value==floor(value)
