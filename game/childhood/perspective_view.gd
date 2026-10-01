extends RefCounted
## Read-only finite belief projection. Receives memories, never whole-world state.
## Likelihoods are authored gameplay tuning, not historical or calibrated statistics.
const LIKELIHOODS := {
	"steward": [0.75, 0.25],
	"courier": [0.30, 0.70],
	"assault": [0.05, 0.95]
}

static func project(memories: Array, tick: int) -> Dictionary:
	if tick < 0: return {"status": "REFUSED", "reason": "invalid_clock"}
	var weights := [0.5, 0.5]
	var used: Array = []
	var prior_tick := -1
	var seen: Dictionary = {}
	for memory in memories:
		if not memory is Dictionary or not memory.has_all(["id", "source_id", "channel", "received_tick", "text"]):
			return {"status": "REFUSED", "reason": "malformed_memory"}
		var received = memory.received_tick
		if not received is float and not received is int:
			return {"status": "REFUSED", "reason": "invalid_clock"}
		if not is_finite(float(received)) or received != floor(received) or received < 0 or received < prior_tick or received > tick or seen.has(memory.id):
			return {"status": "REFUSED", "reason": "future_duplicate_or_unordered_memory"}
		prior_tick = int(received)
		seen[memory.id] = true
		if not LIKELIHOODS.has(memory.id): continue
		var likelihood: Array = LIKELIHOODS[memory.id]
		for i in range(2): weights[i] *= likelihood[i]
		var total: float = weights[0] + weights[1]
		for i in range(2): weights[i] /= total
		used.append({"memory_id": memory.id, "source_id": memory.source_id,
			"received_tick": received, "age_ticks": tick - int(received)})
	return {"schema": "1792.perspective-view.v1", "status": "PROJECTED",
		"hypotheses": ["trail_clear", "riders_nearby"], "weights": weights,
		"received_evidence": used, "tick": tick, "clock_id": "1792.childhood.tick",
		"cause_identity": null, "likelihood_class": "authored_gameplay_tuning",
		"calibrated_probability": false, "conditional_independence_assumed": true,
		"report_age_behavior": "retained_without_decay", "canonical_state_mutated": false}

static func impression(view: Dictionary) -> String:
	if view.status != "PROJECTED": return "I cannot form a working impression from these memories."
	if view.received_evidence.is_empty(): return "I have no report about the trail yet."
	if view.weights[1] > 0.70: return "There may be riders nearby. I still do not know who sent them."
	if view.weights[1] < 0.30: return "The report suggests the trail was clear. It does not tell me what lies there now."
	return "The accounts leave the trail uncertain."
