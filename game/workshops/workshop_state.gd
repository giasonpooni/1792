# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://youth/brawl_state.gd"
## PR21's finite commission on the active youth/service/water authority.
## Custody lives in the existing misl ledger and uses its existing receipt stream.
const Craft := preload("res://workshops/workshop_rules.gd")
const WORKSHOP_SAVE := "user://1792-home-workshop-v2.json"

func workshop_phase() -> String:
	return Craft.phase(_state.misl.ledger) if has_economy() else "unassigned"

func workshop() -> Dictionary:
	return _state.misl.ledger.workshop.duplicate(true) if workshop_phase()!="unassigned" else {}

func carrying_workshop() -> bool:
	return workshop_phase() in ["fuel","tools"]

func _other_commitment() -> bool:
	return brawl_busy() or service_reserved() or (has_water_round() and (_state.water_round.ledger.carried>0 or _state.water_round.ledger.phase=="drawing")) or (has_economy() and (_state.misl.ledger.caravan=="active" or _state.misl.ledger.delivery=="outbound"))

func workshop_action(action: String) -> String:
	if not has_economy() or aftermath_phase()!="complete": return "Finish the inquiry and hear the household allowance first."
	if action not in Craft.PLAYER_ACTIONS: return "Workshop completion belongs to the existing clock."
	if mounted() or _other_commitment(): return "Dismount and settle active cargo, service or the friends' outing first."
	var at: Vector3=Craft.SITE if action in ["start","collect"] else Economy.QUARTERMASTER
	# Full 3D distance: standing above a speaker is not local access.
	if position().distance_to(at)>3.0: return "Reach the appropriate speaker before changing custody."
	if action=="reserve" and _state.misl.events.size()>Economy.MAX_EVENTS-6: return "Too little receipt capacity for another commission."
	return _post("smith."+action,str(int(_state.childhood.tick)))

func operate(kind: String,arg: String="") -> String:
	if kind.begins_with("smith."): return "Use the local workshop conversation."
	if carrying_workshop() and kind in ["accept_delivery","accept_escort"]: return "Return the workshop load before another delivery."
	return super.operate(kind,arg)

func advance() -> void:
	var previous: int=int(_state.childhood.tick)
	super.advance() # Water, service and upkeep retain their original common clock.
	if int(_state.childhood.tick)==previous: return
	if workshop_phase()=="working" and int(_state.childhood.tick)==int(workshop().started_tick)+Craft.WORK_TICKS:
		_post("smith.ready",str(int(_state.childhood.tick)))

func mount() -> String:
	return "Return the workshop load before mounting." if carrying_workshop() else super.mount()

func record_position(p: Vector3,delta: float) -> String:
	if carrying_workshop() and (not is_finite(delta) or delta<=0 or delta>0.1 or distance(position(),p)>Craft.CARRY_SPEED*delta+0.08):
		return "Carry the workshop load at a walk."
	return super.record_position(p,delta)

func begin_brawl() -> String:
	return "Return the workshop load before the friends' outing." if carrying_workshop() else super.begin_brawl()

func begin_service() -> String:
	return "Return the workshop load before arranging service." if carrying_workshop() else super.begin_service()

func service_action(kind: String,arg: String="") -> String:
	return "Return the workshop load before arranging service." if carrying_workshop() else super.service_action(kind,arg)

func begin_water_round() -> String:
	return "Return the workshop load before taking water." if carrying_workshop() else super.begin_water_round()

func water_action(kind: String) -> String:
	return "Return the workshop load before taking water." if carrying_workshop() else super.water_action(kind)

func _ledger_apply(ledger: Dictionary,kind: String,arg: String) -> String:
	return Craft.apply(ledger,kind,arg)

func _ledger_validate(value: Variant,tick: int) -> String:
	return Craft.validate(value,tick)

func _ledger_replay(events: Array) -> Dictionary:
	return Economy.replay(events,Craft.apply)

func validate(value: Variant) -> String:
	var error:=super.validate(value)
	if not error.is_empty(): return error
	if value.has("misl") and Craft.carrying(value.misl.ledger):
		if value.riding.horse.rider_id!="" or value.misl.ledger.delivery=="outbound" or value.misl.ledger.caravan=="active": return "Workshop load conflicts with riding or contracted cargo."
		if value.has("youth_brawl") and value.youth_brawl.ledger.phase!="reported": return "Workshop load conflicts with the friends' outing."
		if value.has("service") and Service.reserved(value.service.ledger): return "Workshop load conflicts with active service."
		if value.has("water_round") and (value.water_round.ledger.carried>0 or value.water_round.ledger.phase=="drawing"): return "Workshop load conflicts with water custody."
	return ""

func journal() -> Array:
	var entries:=super.journal()
	if not has_economy(): return entries
	for e in _state.misl.events:
		if not e.kind.begins_with("smith."): continue
		var action: String=e.kind.trim_prefix("smith.")
		if not Craft.WORDS.has(action): continue # Remote readiness is not delivered knowledge.
		entries.append({"id":"workshop_"+action,"received_tick":int(e.tick),"source_id":"fictional_home_smith" if action in ["start","collect"] else "quartermaster","channel":"heard","text":Craft.WORDS[action]})
	var ordered: Array=[]
	for i in range(entries.size()): ordered.append({"index":i,"record":entries[i]})
	ordered.sort_custom(func(a,b): return a.record.received_tick<b.record.received_tick if a.record.received_tick!=b.record.received_tick else a.index<b.index)
	return ordered.map(func(item): return item.record)
