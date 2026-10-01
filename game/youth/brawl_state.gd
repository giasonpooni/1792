# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://misl/service_state.gd"
## Optional encounter inside the same saved home world, never a second clock.
const Brawl := preload("res://youth/brawl_rules.gd")
const BRAWL_SAVE := "user://1792-youth-bazaar-v1.json"
func has_brawl() -> bool: return _state.has("youth_brawl")
func brawl() -> Dictionary: return _state.youth_brawl.duplicate(true) if has_brawl() else {}
func brawl_phase() -> String: return _state.youth_brawl.ledger.phase if has_brawl() else "none"
func brawl_busy() -> bool: return brawl_phase() not in ["none","reported"]
func begin_brawl() -> String:
	if has_brawl() or aftermath_phase()!="complete" or mounted() or distance(position(),Economy.MARKET)>3:
		return "After the inquiry, meet the two friends at the market on foot."
	if service_reserved() or (has_water_round() and (_state.water_round.ledger.carried>0 or _state.water_round.ledger.phase=="drawing")) or (has_economy() and (_state.misl.ledger.caravan=="active" or _state.misl.ledger.delivery=="outbound")):
		return "Settle active service, carried water or caravan work before this outing."
	var candidate: Dictionary={"schema":Brawl.VERSION,"story_id":Brawl.STORY_ID,"variant":"authored_bazaar_v1","origin_tick":int(_state.childhood.tick),"events":[],"ledger":Brawl.initial(),"actors":Brawl.actors()}
	var e:=_brawl_receipt(candidate,"invite",-1)
	var error:=Brawl.apply(candidate.ledger,e)
	if not error.is_empty(): return error
	candidate.events.append(e);_state.youth_brawl=candidate
	return ""
func _brawl_receipt(s: Dictionary,kind: String,index: int) -> Dictionary:
	var poses: Array=[]
	for actor in s.actors: poses.append(actor.position.duplicate())
	return {"seq":s.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,"index":index,"at":coords(position()),"positions":poses}
func brawl_action(kind: String,index: int=-1) -> String:
	if not has_brawl() or mounted(): return "No on-foot bazaar episode."
	if kind not in ["challenge","stand","leave","parry","hit","counter","regroup","report"]: return "Unknown bazaar action."
	var s: Dictionary=_state.youth_brawl
	var limit: int=Brawl.MAX_EVENTS-3 if kind in ["parry","hit","counter"] else Brawl.MAX_EVENTS
	if s.events.size()>=limit: return "Bazaar receipt budget reached. Bring both friends to the home approach."
	var e:=_brawl_receipt(s,kind,index)
	var candidate: Dictionary=s.ledger.duplicate(true)
	var error:=Brawl.apply(candidate,e)
	if not error.is_empty(): return error
	s.ledger=candidate;s.events.append(e)
	return ""
func record_brawl_actor(index: int,record: Dictionary,delta: float,contact: bool) -> String:
	if not has_brawl() or index<0 or index>=5 or not Brawl.valid_actor(record,index) or not Economy.finite_number(delta) or delta<=0 or delta>0.1:
		return "Invalid bazaar actor motion."
	var s: Dictionary=_state.youth_brawl
	var active: bool=s.ledger.phase in ["invited","challenged","fighting","leaving","returning"] if index>=3 else s.ledger.phase=="fighting" and not s.ledger.down[index]
	var old:=point(s.actors[index].position)
	var moved:=distance(old,point(record.position))
	var allowed: bool=active and contact and distance(old,position())<=12
	if moved>Brawl.SPEED*delta+0.02 or (not allowed and moved>0.001) or absf(record.position[1]-s.actors[index].position[1])>50*delta+0.08:
		return "Bazaar actor cannot teleport or follow through lost contact."
	s.actors[index]=record.duplicate(true)
	return ""
func begin_allowance() -> String:
	return "Finish this outing before accepting household funds." if brawl_busy() else super.begin_allowance()
func mount() -> String:
	return "Finish the on-foot outing with your friends before mounting." if brawl_busy() else super.mount()
func rest_watch() -> String:
	return "Return with your friends before resting through a watch." if brawl_busy() else super.rest_watch()
func operate(kind: String,arg: String="") -> String:
	return "Finish this outing before another household transaction." if brawl_busy() else super.operate(kind,arg)
func begin_service() -> String:
	return "Finish this outing before assigning service." if brawl_busy() else super.begin_service()
func service_action(kind: String,arg: String="") -> String:
	return "Finish this outing before assigning service." if brawl_busy() else super.service_action(kind,arg)
func begin_water_round() -> String:
	return "Finish this outing before carrying water." if brawl_busy() else super.begin_water_round()
func water_action(kind: String) -> String:
	return "Finish this outing before carrying water." if brawl_busy() else super.water_action(kind)
func journal() -> Array:
	var out:=super.journal()
	if has_brawl(): out.append_array(_state.youth_brawl.ledger.memories.duplicate(true))
	var ranked: Array=[]
	for i in range(out.size()): ranked.append({"i":i,"m":out[i]})
	ranked.sort_custom(func(a,b):return a.m.received_tick<b.m.received_tick if a.m.received_tick!=b.m.received_tick else a.i<b.i)
	return ranked.map(func(item):return item.m)
func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed home world."
	var base: Dictionary=value.duplicate(true);base.erase("youth_brawl")
	var error:=super.validate(base)
	if not error.is_empty() or not value.has("youth_brawl"): return error
	if not value.has("aftermath") or value.aftermath.reported_tick<0: return "Bazaar before the household inquiry."
	var replay:=Brawl.replay(value.youth_brawl,int(value.childhood.tick))
	if not replay.error.is_empty(): return replay.error
	if value.youth_brawl.origin_tick<value.aftermath.reported_tick: return "Bazaar before completed inquiry."
	if replay.ledger.phase!="reported":
		if value.riding.horse.rider_id!="": return "Mounted bazaar participant."
		if value.has("service") and Service.reserved(value.service.ledger): return "Active service overlaps the friends' outing."
		if value.has("water_round") and (value.water_round.ledger.carried>0 or value.water_round.ledger.phase=="drawing"): return "Water cargo overlaps the friends' outing."
		if value.has("misl") and (value.misl.ledger.caravan=="active" or value.misl.ledger.delivery=="outbound"): return "Contract cargo overlaps the friends' outing."
	return ""
func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if error.is_empty() and has_brawl():
		var s: Dictionary=_state.youth_brawl;s.origin_tick=int(s.origin_tick)
		for e in s.events: e.seq=int(e.seq);e.tick=int(e.tick);e.index=int(e.index)
		s.ledger=Brawl.replay(s,int(_state.childhood.tick)).ledger
	return error
