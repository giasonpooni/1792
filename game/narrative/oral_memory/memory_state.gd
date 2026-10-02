# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/riding_skill_state.gd"
## Extends the single active world. No second clock, save store, or historical truth state.
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const ORAL_SAVE := WORKSHOP_SAVE

func has_oral_memory() -> bool:
	return _state.has("oral_memory")

func oral_progress() -> Dictionary:
	return Memory.project(_state.oral_memory.events,Memory.content()) if has_oral_memory() else Memory.initial()

func oral_operation(kind: String, subject: String) -> String:
	var c:=Memory.content()
	var error:=Memory.content_error(c)
	if not error.is_empty(): return error
	if aftermath_phase()!="complete" or mounted(): return "Finish the household inquiry and dismount first."
	if brawl_busy(): return "Return with your friends before starting another story."
	if not Memory.OP_IDS.has(kind): return "Unsupported oral-memory operation."
	if kind!="compare" and not Memory.near(position(),Memory.site(kind,subject,c)): return "Return to the speaker or trace on foot."
	var s:=oral_progress()
	var candidate: Dictionary=_state.oral_memory.duplicate(true) if has_oral_memory() else {
		"schema":Memory.VERSION,"model_id":Memory.MODEL_ID,"content_digest":Memory.content_digest(),
		"origin_tick":int(_state.childhood.tick),"events":[]}
	if candidate.events.size()>=Memory.MAX_EVENTS: return "The bounded oral-memory receipt limit is reached."
	var e: Dictionary={"seq":candidate.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,
		"operation_id":Memory.OP_IDS[kind],"subject_id":subject,"parent_seq":Memory.parent_for(s,kind,subject),
		"actor_id":"ranjit_singh","position":coords(position())}
	error=Memory.apply(s,e,c)
	if not error.is_empty(): return error
	candidate.events.append(e)
	error=Memory.validate(candidate,int(_state.childhood.tick),int(_state.aftermath.reported_tick),c)
	if not error.is_empty(): return error
	_state.oral_memory=candidate # Only committed mutation; failed admission leaves the whole world alone.
	return ""

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed oral-memory world."
	var base: Dictionary=value.duplicate(true)
	base.erase("oral_memory")
	var error:=super.validate(base)
	if not error.is_empty() or not value.has("oral_memory"): return error
	if not value.has("aftermath") or value.aftermath.reported_tick<0: return "Oral memory predates the household inquiry."
	return Memory.validate(value.oral_memory,int(value.childhood.tick),int(value.aftermath.reported_tick),Memory.content())

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if not error.is_empty(): return error
	if has_oral_memory():
		_state.oral_memory.origin_tick=int(_state.oral_memory.origin_tick)
		for e in _state.oral_memory.events:
			for key in ["seq","tick","parent_seq"]: e[key]=int(e[key])
	return ""

func oral_journal() -> Array:
	# Whitelist discovered material, not the catalogue or narrator's perspective.
	var result: Array=[]
	if not has_oral_memory(): return result
	var c:=Memory.content()
	for e in _state.oral_memory.events:
		var text: String=""
		var channel: String="reflection"
		var source: String="ranjit_singh"
		match e.kind:
			"hear":
				var t: Dictionary=c.tellings[e.subject_id]
				text=t.text+"\nSource as told: "+" → ".join(t.lineage)
				channel=t.channel
				source=t.speaker_id
			"observe":
				text=c.trace.text
				channel="direct_observation"
			"compare": text="The quartermaster remembers permission; the trader repeats a claim of no permission. Their accounts differ. I do not have a verdict."
			"ask": text="I asked the quartermaster to remember again. Asking is not receiving an answer; I must return to hear it."
			"retell":
				channel="attributed_retelling"
				text="I told the neighbour what the quartermaster said, naming my source." if e.subject_id=="quartermaster_account" else "I told the neighbour both accounts and left their disagreement unresolved."
		result.append({"channel":channel,"source_id":source,"received_tick":int(e.tick),"text":text,"receipt_seq":int(e.seq)})
	return result

func journal() -> Array:
	var result:=super.journal()
	for row in oral_journal():
		var memory: Dictionary=row.duplicate(true)
		memory.erase("receipt_seq")
		result.append(memory)
	return result

func oral_view() -> Dictionary:
	var s:=oral_progress()
	var c:=Memory.content()
	var tellings: Array=[]
	var edges: Array=[]
	for id in s.heard:
		var t: Dictionary=c.tellings[id]
		tellings.append({"id":id,"speaker":t.speaker,"channel":t.channel,"text":t.text,
			"source_lineage":t.lineage.duplicate(),"root_id":t.root_id,"receipt_seq":s.heard[id].seq})
	for id in s.retellings:
		edges.append({"listener_id":"well_neighbour","subject_id":id,"parent_seq":s.retellings[id].parent_seq,
			"receipt_seq":s.retellings[id].seq,"received_tick":s.retellings[id].tick})
	return {"receipts":oral_journal(),"tellings":tellings,"trace":c.trace.text if s.trace_seq>0 else "",
		"compared":s.compared_seq>0,"distinct_reported_origins":Memory.roots(s,c).size(),"retellings":edges}

func listener_response(subject: String="") -> String:
	var s:=oral_progress()
	if subject=="quartermaster_account" and s.retellings.has(subject): return "Neighbour · I shall remember that it was the quartermaster's account you brought, not something you saw."
	if subject=="comparison" and s.retellings.has(subject): return "Neighbour · Then I shall keep the difference in the telling. I heard these accounts from you; I did not witness the borrowing."
	if s.retellings.has("comparison"): return "Neighbour · Then I shall keep the difference in the telling. I heard these accounts from you; I did not witness the borrowing."
	if s.retellings.has("quartermaster_account"): return "Neighbour · I shall remember that it was the quartermaster's account you brought, not something you saw."
	return "Neighbour · There is room for a story while the vessels fill. What have you heard?"
