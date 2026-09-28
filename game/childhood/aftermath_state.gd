extends "res://childhood/childhood_state.gd"
## Additive household aftermath in the SAME _state. No second clock or resource ledger.
## All dialogue, the guard and this investigation are authored, not historical testimony.
const AFTER_SAVE := "user://1792-childhood-aftermath-v1.json"
const MOTHER := Vector3(-5, 0.14, 9)
const CLUE := Vector3(8, 0.14, -13)
const ESCORT_HOME := Vector3(-9, 0.14, 8)
const AgentRules := preload("res://patrol/companion_rules.gd")
const AFTER_ACCOUNTS := {
	"return_steward": {"source_id":"fictional_steward", "channel":"testimony", "text":"I can bring your account to the household. I did not see the attack; the morning note was no promise about your return."},
	"return_courier": {"source_id":"fictional_courier", "channel":"testimony", "text":"I heard riders beyond the grove. I cannot tell you whether they were with the man who attacked you."},
	"protection_offer": {"source_id":"raj_kaur", "channel":"spoken_offer", "text":"Buddh, you came back alive. Take a household guard if you go again. Tell me what you saw, not what fear names for you."},
	"household_escort": {"source_id":"self", "channel":"decision", "text":"I agreed to take the household guard. I gain company, but my inquiry now has a witness chosen by the household."},
	"independent_inquiry": {"source_id":"self", "channel":"decision", "text":"I chose to examine the bend alone. The household withholds its guard; the account I bring back will be mine to defend."},
	"bend_trace": {"source_id":"self", "channel":"observed", "text":"Fresh hoof marks cross the earlier trail beside the bend. They do not name a rider or the person behind the attack."},
	"oral_return": {"source_id":"self", "channel":"spoken_report", "text":"I told Raj Kaur what I saw at the bend. The riders, the assailant and any person who sent him remain unidentified."}
}

func _init() -> void:
	super._init()
	_state.aftermath = _after_initial()

func _after_initial() -> Dictionary:
	return {"schema_version":"aftermath.v1", "heard":[], "offer_heard":false,
		"decision":"", "decision_tick":-1, "clue_tick":-1, "reported_tick":-1,
		"escort":{"id":"fictional_household_guard", "active":false, "instruction":"hold",
			"position":coords(ESCORT_HOME), "yaw":0.0, "velocity":[0.0,0.0,0.0]}, "memories":[]}

func aftermath() -> Dictionary:
	return _state.aftermath.duplicate(true)

func aftermath_phase() -> String:
	if stage() != "escaped": return "dormant"
	var a: Dictionary = _state.aftermath
	if a.reported_tick >= 0: return "complete"
	if a.clue_tick >= 0: return "return"
	if not a.decision.is_empty(): return "inspect"
	if a.offer_heard: return "choice"
	return "accounts"

func household_disposition() -> String:
	match _state.aftermath.decision:
		"household_escort": return "Guarded cooperation"
		"independent_inquiry": return "Strained independence"
	return "Protection not yet negotiated"

func hear_return(speaker: String) -> String:
	var key := "return_" + speaker
	if speaker not in ["steward","courier"] or stage() != "escaped" or mounted() or not near(speaker):
		return "Return to this speaker on foot after surviving the ambush."
	if key in _state.aftermath.heard: return "This is the same witness, not independent corroboration."
	_state.aftermath.heard.append(key)
	_after_remember(key)
	return ""

func hear_offer() -> String:
	if stage() != "escaped" or mounted() or distance(position(), MOTHER) > 3.0:
		return "Approach Raj Kaur in the courtyard on foot."
	if _state.aftermath.heard.size() != 2: return "Hear the steward and courier before answering the household."
	if _state.aftermath.offer_heard: return "The offer is already remembered."
	_state.aftermath.offer_heard = true
	_after_remember("protection_offer")
	return ""

func decide_protection(choice: String) -> String:
	if aftermath_phase() != "choice" or mounted() or distance(position(), MOTHER) > 3.0:
		return "Answer the outstanding offer beside Raj Kaur on foot."
	if choice not in ["household_escort","independent_inquiry"]: return "Unknown protection agreement."
	var a: Dictionary = _state.aftermath
	a.decision = choice
	a.decision_tick = _state.childhood.tick
	a.escort.active = choice == "household_escort"
	a.escort.instruction = "follow" if a.escort.active else "hold"
	_after_remember(choice)
	return ""

func order_escort(instruction: String) -> String:
	var a: Dictionary = _state.aftermath
	if not a.escort.active or aftermath_phase() not in ["inspect","return"]:
		return "No deployed household escort."
	if instruction not in ["follow","hold"]: return "Unknown escort order."
	if distance(position(), point(a.escort.position)) > 10.0: return "The guard is beyond calling distance; return within 10 metres."
	a.escort.instruction = instruction
	return ""

func record_escort(motion: Dictionary, delta: float) -> String:
	var a: Dictionary = _state.aftermath
	if not a.escort.active or not is_finite(delta) or delta <= 0 or delta > 0.1: return "No valid escort motion executor."
	if not AgentRules.valid_member(motion, a.escort.id) or not valid_point(motion.position): return "Invalid escort pose."
	var d := distance(point(a.escort.position),point(motion.position))
	if d > AgentRules.SPEED * delta + 0.08: return "Escort motion exceeds the declared bound."
	if a.escort.instruction == "hold" and d > 0.001: return "Held escort cannot move horizontally."
	for key in ["position","yaw","velocity"]: a.escort[key] = motion[key].duplicate() if motion[key] is Array else motion[key]
	return ""

func inspect_bend() -> String:
	if aftermath_phase() != "inspect" or mounted() or distance(position(), CLUE) > 3.0:
		return "Return to the bend and examine it on foot."
	if _state.aftermath.escort.active and distance(point(_state.aftermath.escort.position),CLUE) > 6.0:
		return "You agreed to bring the guard. Regroup before examining the bend together."
	_state.aftermath.clue_tick = _state.childhood.tick
	_after_remember("bend_trace")
	return ""

func report_home() -> String:
	if aftermath_phase() != "return" or mounted() or distance(position(),MOTHER) > 3.0:
		return "Bring your observed account back to Raj Kaur on foot."
	var a: Dictionary = _state.aftermath
	if a.escort.active and distance(point(a.escort.position),MOTHER) > 7.0:
		return "Wait for the household guard to return before closing the inquiry."
	a.reported_tick = _state.childhood.tick
	a.escort.active = false
	a.escort.instruction = "hold"
	a.escort.velocity = [0.0,0.0,0.0]
	_after_remember("oral_return")
	return ""

func _after_remember(id: String) -> void:
	var entry: Dictionary = AFTER_ACCOUNTS[id].duplicate(true)
	entry.id = id
	entry.received_tick = _state.childhood.tick
	_state.aftermath.memories.append(entry)

func journal() -> Array:
	var entries := super.journal()
	entries.append_array(_state.aftermath.memories.duplicate(true))
	# Explicit tie order: inherited memories first, then the aftermath event sequence.
	# Godot sort stability is not relied upon; same-tick messages are not alphabetized.
	var ordered: Array = []
	for i in range(entries.size()): ordered.append({"record":entries[i],"index":i})
	ordered.sort_custom(func(a, b): return a.record.received_tick < b.record.received_tick if a.record.received_tick != b.record.received_tick else a.index < b.index)
	return ordered.map(func(item): return item.record)

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed childhood snapshot."
	var base: Dictionary = value.duplicate(true)
	base.erase("aftermath")
	var error := super.validate(base)
	if not error.is_empty(): return error
	if not value.has("aftermath"): return "" # Explicit old-profile migration; never infer events.
	var a: Variant = value.aftermath
	var seed := _after_initial()
	if not _shape(a,seed) or a.schema_version != seed.schema_version: return "Malformed aftermath snapshot."
	for key in ["decision_tick","clue_tick","reported_tick"]:
		if not AgentRules.whole(a[key],-1) or a[key] > value.childhood.tick: return "Invalid aftermath time."
	if a.heard not in [[],["return_steward"],["return_courier"],["return_steward","return_courier"],["return_courier","return_steward"]]:
		return "Unknown or duplicate return testimony."
	if a.offer_heard and a.heard.size() != 2: return "Offer before the two return accounts."
	if a.decision not in ["","household_escort","independent_inquiry"]: return "Unknown agreement."
	if (a.decision_tick >= 0) != (a.decision != "") or (a.decision != "" and not a.offer_heard): return "Decision before offer."
	if a.clue_tick >= 0 and (a.decision_tick < 0 or a.clue_tick < a.decision_tick): return "Clue before decision."
	if a.reported_tick >= 0 and (a.clue_tick < 0 or a.reported_tick < a.clue_tick): return "Report before observation."
	var e: Dictionary = a.escort
	var record := {"id":e.id,"position":e.position,"yaw":e.yaw,"velocity":e.velocity}
	if not AgentRules.valid_member(record,seed.escort.id) or not valid_point(e.position): return "Invalid household escort."
	if e.instruction not in ["follow","hold"]: return "Invalid escort instruction."
	if e.active != (a.decision == "household_escort" and a.reported_tick < 0): return "Escort deployment and agreement disagree."
	if not e.active and (e.instruction != "hold" or point(e.velocity) != Vector3.ZERO): return "Inactive escort must be stationary."
	if a.decision != "household_escort" and (not point(e.position).is_equal_approx(ESCORT_HOME) or e.yaw != 0.0): return "Undeployed guard has moved."
	var expected: Array = a.heard.duplicate()
	if a.offer_heard: expected.append("protection_offer")
	if a.decision != "": expected.append(a.decision)
	if a.clue_tick >= 0: expected.append("bend_trace")
	if a.reported_tick >= 0: expected.append("oral_return")
	if a.memories.size() != expected.size(): return "Aftermath memories disagree with progress."
	if value.childhood.ambush.status != "escaped" and (not expected.is_empty() or e.active): return "Aftermath before survival."
	var prior: int = int(value.childhood.ambush.end_tick)
	for index in range(a.memories.size()):
		var m: Variant = a.memories[index]
		if not _shape(m,{"id":"","source_id":"","channel":"","received_tick":0,"text":""}): return "Malformed aftermath memory."
		if m.id != expected[index] or not AgentRules.whole(m.received_tick,prior) or m.received_tick > value.childhood.tick:
			return "Reordered or future aftermath memory."
		var authored: Dictionary = AFTER_ACCOUNTS[m.id]
		if m.source_id != authored.source_id or m.channel != authored.channel or m.text != authored.text: return "Aftermath testimony was rewritten."
		var tick_field: String = "decision_tick" if m.id == a.decision else "clue_tick" if m.id == "bend_trace" else "reported_tick" if m.id == "oral_return" else ""
		if not tick_field.is_empty() and a[tick_field] != m.received_tick: return "Event and memory ticks disagree."
		prior = int(m.received_tick)
	return ""

func restore(value: Variant) -> String:
	var error := super.restore(value)
	if not error.is_empty(): return error
	if not _state.has("aftermath"): _state.aftermath = _after_initial()
	for key in ["decision_tick","clue_tick","reported_tick"]: _state.aftermath[key] = int(_state.aftermath[key])
	for memory in _state.aftermath.memories: memory.received_tick = int(memory.received_tick)
	return ""

func save_to(path: String = AFTER_SAVE) -> String:
	return super.save_to(path)

func load_from(path: String = AFTER_SAVE) -> String:
	return super.load_from(path)
