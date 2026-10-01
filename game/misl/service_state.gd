# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/gujranwala_state.gd"
## One optional detail in the existing home state. Supply remains the only treasury.
const Service:=preload("res://misl/service_rules.gd")
const SERVICE_SAVE:="user://1792-sukerchakia-service-v1.json"
func has_service() -> bool: return _state.has("service")
func service() -> Dictionary: return _state.service.duplicate(true) if has_service() else {}
func service_reserved() -> bool: return has_service() and Service.reserved(_state.service.ledger)
func service_ready() -> bool: return service_reserved() and Service.ready(_state.misl.ledger,_state.service.ledger.slot)

func begin_service() -> String:
	if has_service(): return "The same household detail already exists."
	if not has_economy() or aftermath_phase()!="complete" or mounted() or distance(position(),Economy.QUARTERMASTER)>3:
		return "Finish the inquiry and hear the household allowance first."
	_state.service={"schema":Service.VERSION,"origin_tick":int(_state.childhood.tick),"events":[],"ledger":Service.initial(),"agent":Service.motion(-1)}
	return _service_post("begin","",position())

func service_action(kind: String,arg: String="") -> String:
	if not has_service() or mounted(): return "Hear the service brief and speak on foot."
	if kind not in ["hear","dispatch","debrief"]: return "Not a player service action."
	return _service_post(kind,arg,position())

func _service_post(kind: String,arg: String,at: Vector3) -> String:
	var s: Dictionary=_state.service
	if s.events.size()>=Service.MAX_EVENTS: return "Service receipt budget reached."
	var candidate: Dictionary=s.ledger.duplicate(true)
	var e: Dictionary={"seq":s.events.size()+1,"tick":int(_state.childhood.tick),"economy_seq":_state.misl.events.size(),"kind":kind,"arg":arg,"position":coords(at)}
	var error:=Service.apply(candidate,e,_state.misl.ledger)
	if not error.is_empty(): return error
	s.events.append(e);s.ledger=candidate
	if kind=="dispatch": s.agent=Service.motion(candidate.slot)
	if kind=="debrief": s.agent=Service.motion(-1)
	return ""

func operate(kind: String,arg: String="") -> String:
	if kind=="release_guard" and service_reserved() and _state.misl.ledger.guards-1<=_state.service.ledger.slot:
		return "This guard is committed to the service detail. Hear the returned account before release."
	return super.operate(kind,arg)

func rest_watch() -> String:
	if service_reserved() and _state.service.ledger.stage!="awaiting_account" and service_ready():
		return "An active service detail must travel on the existing clock. No fast-forwarded arrival."
	return super.rest_watch()

func record_service_motion(record: Dictionary,delta: float) -> String:
	if not service_reserved() or not Economy.finite_number(delta) or delta<=0 or delta>0.1: return "Invalid service-motion step."
	var s: Dictionary=_state.service
	if not Service.valid_motion(record,s.ledger.slot): return "Invalid service motion/identity."
	var moved:=distance(point(s.agent.position),point(record.position))
	var moving: bool=service_ready() and s.ledger.stage in ["outbound","returning"]
	if moved>Service.SPEED*delta+0.02 or (not moving and moved>0.001): return "Service motion exceeds the order or pace."
	if absf(record.position[1]-s.agent.position[1])>50*delta+0.08: return "Invalid service vertical movement."
	s.agent=record.duplicate(true)
	return ""

func progress_service() -> void:
	if not service_reserved(): return
	var s: Dictionary=_state.service
	var p:=point(s.agent.position)
	var tick:=int(_state.childhood.tick)
	if s.ledger.stage=="outbound" and service_ready() and distance(p,Service.SITES[s.ledger.active])<=1.7:
		_service_post("arrive","",p)
	elif s.ledger.stage=="attending" and service_ready() and tick>=s.ledger.onsite_tick+Service.SERVICE_TICKS:
		_service_post("finish","",p)
	elif s.ledger.stage=="returning" and distance(p,Service.home(s.ledger.slot))<=1.7:
		_service_post("home","",p)

func journal() -> Array:
	var entries:=super.journal()
	if has_service(): entries.append_array(_state.service.ledger.memories.duplicate(true))
	if not has_service(): return entries
	var ordered: Array=[]
	for i in range(entries.size()): ordered.append({"index":i,"record":entries[i]})
	ordered.sort_custom(func(a,b): return a.record.received_tick<b.record.received_tick if a.record.received_tick!=b.record.received_tick else a.index<b.index)
	return ordered.map(func(item): return item.record)

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed home state."
	var base: Dictionary=value.duplicate(true);base.erase("service")
	var error:=super.validate(base)
	if not error.is_empty() or not value.has("service"): return error
	if not value.has("misl"): return "Service without household supply authority."
	return Service.replay(value.service,value.misl,int(value.childhood.tick),_ledger_apply).error

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if error.is_empty() and has_service():
		var s: Dictionary=_state.service;s.origin_tick=int(s.origin_tick)
		for e in s.events:
			e.seq=int(e.seq);e.tick=int(e.tick);e.economy_seq=int(e.economy_seq)
		s.ledger=Service.replay(s,_state.misl,int(_state.childhood.tick),_ledger_apply).ledger
	return error
