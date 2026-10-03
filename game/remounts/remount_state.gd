extends "res://narrative/oral_memory/memory_state.gd"
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## One optional substate in the existing home authority; no new clock or money ledger.
const Remounts := preload("res://remounts/remount_rules.gd")
const REMOUNT_SAVE := "user://1792-remounts-v1.json"

func has_remounts() -> bool: return _state.has("remounts")
func remount_busy() -> bool: return has_remounts() and not _state.remounts.ledger.resolved

func _other_commitment() -> bool:
	return remount_busy() or super._other_commitment()
func remounts() -> Dictionary: return _state.remounts.duplicate(true) if has_remounts() else {}

func begin_remounts() -> String:
	if has_remounts(): return "The same investigation is already retained."
	if not has_economy() or aftermath_phase()!="complete" or mounted() or position().distance_to(Economy.QUARTERMASTER)>3:
		return "Hear the household allowance, then ask the quartermaster on foot."
	if super._other_commitment() or carrying_workshop(): return "Finish the active household task before searching for the remounts."
	_state.remounts={"schema":Remounts.VERSION,"origin_tick":int(_state.childhood.tick),"events":[],"ledger":Remounts.initial(),
		"runner":Remounts.agent("yard_runner",Remounts.RUNNER_START),"responder":Remounts.agent("yard_reserve",Remounts.POST)}
	return _remount_event("begin",{})

func remount_action(kind: String) -> String:
	if not has_remounts() or mounted(): return "Investigate on foot after speaking to the quartermaster."
	var sites: Dictionary={"introduction":Economy.MARKET,"permission":Remounts.OBSERVERS.yard_gatekeeper.position,
		"note":Remounts.NOTE,"horses":Remounts.HITCH,"resolve":Economy.QUARTERMASTER}
	if not sites.has(kind) or position().distance_to(sites[kind])>3: return "Reach the appropriate speaker or object on foot."
	return _remount_event(kind,{})

func begin_brawl() -> String:
	return "Give your remount account before leaving with the friends." if remount_busy() else super.begin_brawl()
func begin_service() -> String:
	return "Give your remount account before taking service." if remount_busy() else super.begin_service()
func service_action(kind: String,arg: String="") -> String:
	return "Give your remount account before taking service." if remount_busy() and kind=="dispatch" else super.service_action(kind,arg)
func begin_water_round() -> String:
	return "Give your remount account before carrying water." if remount_busy() else super.begin_water_round()
func water_action(kind: String) -> String:
	return "Give your remount account before carrying water." if remount_busy() and kind=="draw" else super.water_action(kind)
func operate(kind: String,arg: String="") -> String:
	return "Give your remount account before another delivery." if remount_busy() and kind in ["accept_delivery","accept_escort"] else super.operate(kind,arg)

func observe_yard(id: String,clear: bool,speed: float) -> String:
	if not has_remounts() or not Remounts.OBSERVERS.has(id) or not Economy.finite_number(speed) or speed<0 or speed>Riding.MAX_SPEED+0.1:
		return "Invalid observer sample."
	if not Remounts.in_yard(position()): return ""
	var sample:=Remounts.sense(id,position(),speed,clear)
	for kind in ["heard","seen","identified"]:
		if sample[kind] and _state.remounts.ledger.contacts[id][kind+"_tick"]<0:
			var at: Vector3=Remounts.HITCH if kind=="heard" else position()
			var error:=_remount_event(kind,{"observer":id,"place":coords(at)})
			if not error.is_empty(): return error
	return ""

func _remount_event(kind: String,detail: Dictionary) -> String:
	var m: Dictionary=_state.remounts
	if m.events.size()>=Remounts.MAX_EVENTS: return "Encounter event budget reached."
	var candidate: Dictionary=m.ledger.duplicate(true)
	var event: Dictionary={"seq":m.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,"detail":detail.duplicate(true)}
	var error:=Remounts.apply(candidate,event)
	if not error.is_empty(): return error
	m.events.append(event)
	m.ledger=candidate
	return ""

func record_remount_agent(role: String,motion: Dictionary,delta: float) -> String:
	if not has_remounts() or role not in ["runner","responder"] or not Economy.finite_number(delta) or delta<=0 or delta>0.1:
		return "Invalid encounter motion timestep."
	var m: Dictionary=_state.remounts
	var id: String="yard_runner" if role=="runner" else "yard_reserve"
	if not Remounts.valid_agent(motion,id): return "Invalid encounter agent record."
	var old: Dictionary=m[role]
	var moving: bool=m.ledger.report.stage in ["queued","in_transit"] if role=="runner" else m.ledger.response.stage in ["travelling","returning"]
	var horizontal:=distance(point(old.position),point(motion.position))
	if horizontal>Remounts.SPEED*delta+0.08 or (not moving and horizontal>0.001): return "Encounter agent moved outside its order or speed bound."
	if absf(motion.position[1]-old.position[1])>50*delta+0.08: return "Encounter agent vertical motion exceeded bounds."
	m[role]=motion.duplicate(true)
	return ""

func progress_remount_messages() -> void:
	if not has_remounts(): return
	var m: Dictionary=_state.remounts
	var s: Dictionary=m.ledger
	var tick: int=int(_state.childhood.tick)
	if s.report.stage=="queued" and tick>=s.report.opened_tick+Remounts.PICKUP_DELAY and distance(point(m.runner.position),Remounts.OBSERVERS[s.report.sender].position)<=2.2:
		_remount_event("collect",{"position":m.runner.position})
	elif s.report.stage=="in_transit" and tick>=s.report.collected_tick+Remounts.REPORT_DELAY and distance(point(m.runner.position),Remounts.POST)<=2.2:
		_remount_event("deliver",{"position":m.runner.position})
	s=m.ledger
	if s.response.stage=="travelling" and distance(point(m.responder.position),point(s.response.target))<=2.2:
		_remount_event("response_arrive",{"position":m.responder.position})
	elif s.response.stage=="returning" and distance(point(m.responder.position),Remounts.POST)<=2.2:
		_remount_event("response_home",{"position":m.responder.position})

func advance() -> void:
	super.advance()
	if has_remounts():
		var r: Dictionary=_state.remounts.ledger.response
		if r.stage=="searching" and int(_state.childhood.tick)>=r.arrived_tick+Remounts.SEARCH_TICKS:
			_remount_event("response_return",{})

func rest_watch() -> String:
	if has_remounts() and (_state.remounts.ledger.report.stage in ["queued","in_transit"] or _state.remounts.ledger.response.stage in ["travelling","searching","returning"]):
		return "An encounter message or search is active. Let the physical agents finish before resting."
	return super.rest_watch()

func journal() -> Array:
	var entries:=super.journal()
	if has_remounts(): entries.append_array(_state.remounts.ledger.memories.duplicate(true))
	var ordered: Array=[]
	for i in range(entries.size()): ordered.append({"index":i,"record":entries[i]})
	ordered.sort_custom(func(a,b): return a.record.received_tick<b.record.received_tick if a.record.received_tick!=b.record.received_tick else a.index<b.index)
	return ordered.map(func(item): return item.record)

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed home world."
	var base: Dictionary=value.duplicate(true)
	base.erase("remounts")
	var error:=super.validate(base)
	if not error.is_empty() or not value.has("remounts"): return error
	if not value.has("misl"): return "Investigation predates the allowance."
	error=Remounts.validate(value.remounts,int(value.childhood.tick))
	if not error.is_empty(): return error
	if value.remounts.origin_tick<value.misl.origin_tick: return "Investigation predates the allowance."
	if not value.remounts.ledger.resolved:
		if value.has("youth_brawl") and value.youth_brawl.ledger.phase!="reported": return "An active friends' outing overlaps the remount inquiry."
		if value.has("service") and Service.reserved(value.service.ledger): return "Active service overlaps the remount inquiry."
		if value.has("water_round") and (value.water_round.ledger.carried>0 or value.water_round.ledger.phase=="drawing"): return "Water custody overlaps the remount inquiry."
		if value.misl.ledger.caravan=="active" or value.misl.ledger.delivery=="outbound": return "Household cargo overlaps the remount inquiry."
		if value.misl.ledger.has("workshop") and value.misl.ledger.workshop.phase in ["fuel","tools"]: return "Workshop cargo overlaps the remount inquiry."
	return ""

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if error.is_empty() and has_remounts():
		var m: Dictionary=_state.remounts
		m.origin_tick=int(m.origin_tick)
		for e in m.events:
			e.tick=int(e.tick);e.seq=int(e.seq)
		m.ledger=Remounts.replay(m.events,m.origin_tick,int(_state.childhood.tick)).ledger
	return error

func remount_trace() -> Dictionary:
	if not has_remounts(): return {}
	return {"schema":"1792.remounts-trace.v1","scope":"developer_inspection_not_player_knowledge",
		"export_id":"export-"+Crypto.new().generate_random_bytes(16).hex_encode(),
		"operation_id":"1792.remounts.inspect.v1","clock":{"source":"childhood.tick","hz":60,"tick":int(_state.childhood.tick)},
		"character_id":Names.HERO_ID,"historical_class":"authored_fictional_encounter",
		"encounter":remounts(),"verification_id":null,"verification_status":"not_verified"}
