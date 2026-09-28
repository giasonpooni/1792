extends "res://territory/gujranwala_state.gd"
## One optional assignment in the inherited world; original ledger settles every reward.
const Road := preload("res://territory/road/road_rules.gd")
const ROAD_SAVE := "user://1792-shah-road-v1.json"

func has_road() -> bool:
	return _state.has("road_dispute")

func road() -> Dictionary:
	return _state.road_dispute.duplicate(true) if has_road() else {}

func accept_disputed_escort() -> String:
	if has_road(): return "This local road assignment was already accepted."
	# The inherited operation checks location, on-foot interaction, allocation and payment identity.
	var error:=super.operate("accept_escort")
	if not error.is_empty(): return error
	_state.road_dispute=Road.initial(int(_state.childhood.tick))
	return ""

func hear_roadkeeper() -> String:
	var error:=_at_roadkeeper()
	if not error.is_empty(): return error
	if _state.road_dispute.heard_tick>=0: return "You already heard this claim; repeating it is not corroboration."
	_state.road_dispute.heard_tick=int(_state.childhood.tick)
	return ""

func choose_road(choice: String) -> String:
	var error:=_at_roadkeeper()
	if not error.is_empty(): return error
	var r: Dictionary=_state.road_dispute
	if r.heard_tick<0 or r.choice!="" or choice not in Road.CHOICES: return "Hear the claim and choose one route once."
	r.choice=choice
	r.decision_tick=int(_state.childhood.tick)
	return ""

func receive_road_reply() -> String:
	var error:=_at_roadkeeper()
	if not error.is_empty(): return error
	var r: Dictionary=_state.road_dispute
	if r.choice!="seek_confirmation" or r.reply_received_tick>=0: return "No outstanding road inquiry."
	if int(_state.childhood.tick)<r.decision_tick+Road.REPLY_DELAY: return "The reply has not arrived. Time passes only while the world is unpaused."
	r.reply_received_tick=int(_state.childhood.tick)
	return ""

func _at_roadkeeper() -> String:
	if not has_road() or _state.misl.ledger.caravan!="active" or _state.road_dispute.visited.size()<2:
		return "Bring the assigned caravan to the checkpoint first."
	if mounted() or distance(position(),Road.SPEAKER)>3: return "Dismount and approach the roadkeeper."
	return ""

func record_merchant(motion: Dictionary, delta: float) -> String:
	if not has_road(): return super.record_merchant(motion,delta)
	if not valid_point(motion.get("position")): return "Invalid caravan pose."
	var r: Dictionary=_state.road_dispute
	var old:=point(_state.misl.merchant.position)
	if not Road.moving(r) and distance(old,point(motion.position))>0.001:
		return "The caravan must wait for its route decision or reply."
	var error:=super.record_merchant(motion,delta)
	if not error.is_empty(): return error
	if Road.moving(r) and distance(point(motion.position),Road.target(r))<=0.9:
		r.visited.append({"index":r.visited.size(),"tick":int(_state.childhood.tick),"position":motion.position.duplicate()})
	return ""

func operate(kind: String, arg: String="") -> String:
	if kind=="checkin" and has_road() and Road.phase(_state.road_dispute)!="arrived":
		return "Bring the caravan along its agreed route before check-in."
	var error:=super.operate(kind,arg)
	if error.is_empty() and kind=="checkin" and has_road():
		_state.road_dispute.completed_tick=int(_state.childhood.tick)
	return error

func journal() -> Array:
	var entries:=super.journal()
	if not has_road(): return entries
	var r: Dictionary=_state.road_dispute
	if r.heard_tick>=0:
		entries.append(_road_memory("road_claim",r.heard_tick,"fictional_roadkeeper","heard","The roadkeeper says another household claims this crossing. This is his assertion, not proof of ownership."))
	if r.decision_tick>=0:
		var statements: Dictionary={
			"recognize_claim":"I accepted the household's local passage claim. This obtained passage; it did not settle ownership of the surrounding land.",
			"seek_confirmation":"I asked for confirmation before accepting the claim. The carrier is waiting for an answer.",
			"bypass":"I chose the longer field route. The crossing's claim remains unresolved."}
		entries.append(_road_memory("road_choice",r.decision_tick,"self","decision",statements[r.choice]))
	if r.reply_received_tick>=0:
		entries.append(_road_memory("road_reply",r.reply_received_tick,"fictional_roadkeeper","heard","The roadkeeper relays permission for this load to pass today. I have not met the person who gave that permission."))
	if r.completed_tick>=0:
		entries.append(_road_memory("road_return",r.completed_tick,"self","observed","The carrier arrived and the home store received the load. No territory changed hands."))
	# Stable tie-breaker retains the established ordering of earlier entries.
	var indexed: Array=[]
	for i in range(entries.size()): indexed.append({"entry":entries[i],"index":i})
	indexed.sort_custom(func(a,b): return a.entry.received_tick<b.entry.received_tick if a.entry.received_tick!=b.entry.received_tick else a.index<b.index)
	return indexed.map(func(v): return v.entry)

func _road_memory(id: String, tick: int, source: String, channel: String, text: String) -> Dictionary:
	return {"id":id,"received_tick":tick,"source_id":source,"channel":channel,"text":text}

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed road/chapter state."
	var base: Dictionary=value.duplicate(true)
	base.erase("road_dispute")
	var error:=super.validate(base)
	if not error.is_empty(): return error
	return Road.validate(value.road_dispute,value) if value.has("road_dispute") else ""

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if not error.is_empty(): return error
	if has_road():
		for key in ["accepted_tick","heard_tick","decision_tick","reply_received_tick","completed_tick"]:
			_state.road_dispute[key]=int(_state.road_dispute[key])
		for v in _state.road_dispute.visited:
			v.index=int(v.index)
			v.tick=int(v.tick)
	return ""
