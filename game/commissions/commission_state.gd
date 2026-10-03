# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://remounts/remount_state.gd"
## Adds physical execution to the existing money receipts. No autonomous income.
const Commission := preload("res://commissions/commission_rules.gd")
const COMMISSION_SAVE := WORKSHOP_SAVE
func commissioned() -> bool: return has_economy() and _state.misl.ledger.has("commission")
func commission() -> Dictionary: return _state.misl.ledger.commission.duplicate(true) if commissioned() else {}
func specialist() -> Dictionary: return _state.commission_actor.duplicate(true) if commissioned() else Commission.blank_actor()
func controlling_specialist() -> bool: return commissioned() and _state.misl.ledger.commission.controlled==Commission.SPECIALIST
func commission_busy() -> bool: return commissioned() and commission().phase in ["reserved","introduced","escorting"]
func commission_drilling() -> bool: return commissioned() and commission().lesson=="active"
func command_position() -> Vector3: return point(_state.commission_actor.position) if controlling_specialist() else position()
func _commission_commitment() -> bool:
	return commission_busy() or controlling_specialist() or commission_drilling()
func _other_commitment() -> bool:
	return _commission_commitment() or super._other_commitment()
func commission_action(kind: String,option: String="") -> String:
	if not has_economy() or aftermath_phase()!="complete" or mounted() or brawl_busy() or service_reserved() or remount_busy() or carrying_workshop(): return "Finish the active household task and speak on foot after the allowance."
	if _state.misl.ledger.caravan=="active" or _state.misl.ledger.cargo>0 or (has_water_round() and (_state.water_round.ledger.carried>0 or _state.water_round.ledger.phase=="drawing")): return "Settle the carried load or caravan first."
	if kind not in ["reserve","broker","engage","appoint","cancel","release_reserve","pay_arrears","dismiss","control","lesson_start"]: return "Not a player commission action."
	if kind=="reserve" and _state.misl.events.size()>Economy.MAX_EVENTS-10: return "Not enough receipt capacity for this bounded commission."
	return _commission_post(kind,option)
func _commission_post(kind: String,option: String="") -> String:
	var s: Dictionary=specialist()
	var d: Dictionary={"schema":Commission.VERSION,"actor":Commission.SPECIALIST if controlling_specialist() else Commission.HERO,
		"at":coords(command_position()),"companion":coords(position()) if controlling_specialist() else s.position,"option":option,"tick":int(_state.childhood.tick),"practice":s.practice}
	var error:=super._post("commission."+kind,JSON.stringify(d))
	if error.is_empty() and kind=="reserve": _state.commission_actor=Commission.blank_actor()
	if error.is_empty() and kind=="lesson_start": _state.commission_actor.last_practice_tick=int(_state.childhood.tick)
	return error
func _post(kind: String,arg: String) -> String:
	if kind.begins_with("commission."): return "Use a situated commission action."
	return super._post(kind,arg)
func operate(kind: String,arg: String="") -> String:
	if controlling_specialist(): return "Only the household principal may authorize this expenditure."
	if commissioned() and commission().lesson=="active" and kind=="release_guard" and _state.misl.ledger.guards-1<=commission().guard_slot: return "This guard is committed to the drill."
	if (commission_busy() or commission_drilling()) and kind in ["accept_delivery","accept_escort"]: return "Finish this commission journey before taking another load."
	return super.operate(kind,arg)
func begin_remounts() -> String:
	return "Settle the instructor's commission before searching the yard." if _commission_commitment() else super.begin_remounts()
func remount_action(kind: String) -> String:
	return "Settle the instructor's commission before searching the yard." if _commission_commitment() else super.remount_action(kind)
func workshop_action(action: String) -> String:
	return "Settle the instructor's commission before taking a workshop load." if _commission_commitment() else super.workshop_action(action)
func oral_operation(kind: String,subject: String) -> String:
	return "Return to Buddh's viewpoint before receiving his stories." if controlling_specialist() else super.oral_operation(kind,subject)
func gate_action(kind: String,contact: bool) -> String:
	return "Return to Buddh's viewpoint before changing his passage account." if controlling_specialist() else super.gate_action(kind,contact)
func training_access() -> String:
	return "Settle the active household commission before the remembered riding lesson." if _commission_commitment() or remount_busy() or carrying_workshop() or super._other_commitment() else super.training_access()
func record_specialist(record: Dictionary,delta: float,contact: bool) -> String:
	if not commissioned() or not _valid_actor(record,int(_state.childhood.tick)) or not Economy.finite_number(delta) or delta<=0 or delta>0.1: return "Invalid specialist motion."
	var prior: Dictionary=_state.commission_actor
	if prior.last_move_tick==int(_state.childhood.tick): return "One physical specialist movement per world tick."
	var old:=point(prior.position);var moved:=old.distance_to(point(record.position))
	var allowed: bool=controlling_specialist() or (commission().phase=="escorting" and contact and old.distance_to(position())<=10)
	if moved>4.5*delta+0.04 or (not allowed and moved>0.001): return "The specialist cannot teleport or follow through lost contact."
	if record.practice!=prior.practice or record.last_practice_tick!=prior.last_practice_tick: return "Motion cannot award training progress."
	record=record.duplicate(true);record.last_move_tick=int(_state.childhood.tick);_state.commission_actor=record
	return ""
func progress_drill(contact: bool) -> void:
	if not commissioned() or commission().lesson!="active" or not contact or not Commission.ready(_state.misl.ledger): return
	if _state.misl.ledger.duty_guards<=commission().guard_slot: return
	var a: Dictionary=_state.commission_actor;var tick:=int(_state.childhood.tick)
	if a.last_practice_tick==tick or tick<=commission().lesson_start: return
	if not Commission.near(position(),Commission.HOME,4) or not Commission.near(point(a.position),Commission.HOME,4): return
	a.practice=mini(Commission.PRACTICE_TICKS,a.practice+1);a.last_practice_tick=tick
	if a.practice==Commission.PRACTICE_TICKS: _commission_post("lesson_finish")
func rest_watch() -> String:
	if commission_busy() or controlling_specialist() or (commissioned() and commission().lesson=="active"): return "A physical commission or drill cannot be completed by resting."
	return super.rest_watch()
func mount() -> String:
	if commission_busy() or controlling_specialist() or (commissioned() and commission().lesson=="active"): return "This commission journey is on foot; finish or regroup first."
	return super.mount()
func begin_brawl() -> String:
	return "Settle the commission before the friends' outing." if commission_busy() or controlling_specialist() or commission_drilling() else super.begin_brawl()
func begin_service() -> String:
	return "Settle the commission before assigning a detail." if commission_busy() or controlling_specialist() or commission_drilling() else super.begin_service()
func service_action(kind: String,arg: String="") -> String:
	return "Settle the commission before assigning a detail." if commission_busy() or controlling_specialist() or (commissioned() and commission().lesson=="active") else super.service_action(kind,arg)
func begin_water_round() -> String:
	return "Settle the commission before carrying water." if commission_busy() or controlling_specialist() or commission_drilling() else super.begin_water_round()
func water_action(kind: String) -> String:
	return "Settle the commission before carrying water." if commission_busy() or controlling_specialist() or commission_drilling() else super.water_action(kind)
static func _valid_actor(a: Variant,tick: int) -> bool:
	if not Commission.fields(a,["id","position","yaw","velocity","practice","last_practice_tick","last_move_tick"]): return false
	return a.id==Commission.SPECIALIST and Base_valid(a.position,a.velocity,a.yaw) and Commission.whole(a.practice,0,Commission.PRACTICE_TICKS) and Commission.whole(a.last_practice_tick,-1,tick) and Commission.whole(a.last_move_tick,-1,tick)
static func Base_valid(p: Variant,v: Variant,y: Variant) -> bool:
	return valid_point(p) and (v is Array and v.size()==3 and v.all(func(n):return Economy.finite_number(n)) and v[1]>=-50 and v[1]<=0 and Vector2(v[0],v[2]).length()<=4.501) and Economy.finite_number(y) and absf(y)<=PI
func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed commissioned home state."
	var base: Dictionary=value.duplicate(true);base.erase("commission_actor")
	var error:=super.validate(base)
	if not error.is_empty(): return error
	var has_contract: bool=value.has("misl") and value.misl.ledger.has("commission")
	if value.has("commission_actor")!=has_contract: return "Contract and physical specialist identity disagree."
	if not has_contract: return ""
	var a: Variant=value.commission_actor;var c: Dictionary=value.misl.ledger.commission
	if not _valid_actor(a,int(value.childhood.tick)): return "Invalid specialist record."
	if c.phase in ["reserved","introduced","cancelled"] and point(a.position).distance_to(Commission.RECEPTION)>0.001: return "Unaccepted candidate has travelled."
	if c.phase!="appointed" and c.controlled!=Commission.HERO: return "Unappointed viewpoint."
	if c.lesson=="none" and (a.practice!=0 or a.last_practice_tick!=-1): return "Training without a funded session."
	if c.lesson!="none" and (a.practice>int(value.childhood.tick)-c.lesson_start or a.last_practice_tick<c.lesson_start): return "Training precedes its funded duration."
	if c.lesson=="complete" and a.practice!=Commission.PRACTICE_TICKS: return "Missing executed drill."
	if c.lesson=="active" and value.misl.ledger.guards<=c.guard_slot: return "Drill pupil was released."
	var committed: bool=c.phase in ["reserved","introduced","escorting"] or c.controlled==Commission.SPECIALIST or c.lesson=="active"
	if committed:
		if value.riding.horse.rider_id!="" or value.misl.ledger.cargo>0 or value.misl.ledger.caravan=="active" or value.has("youth_brawl") and value.youth_brawl.ledger.phase!="reported" or value.has("service") and Service.reserved(value.service.ledger):
			return "Commission overlaps an incompatible active task."
		if value.has("water_round") and (value.water_round.ledger.carried>0 or value.water_round.ledger.phase=="drawing"):
			return "Commission overlaps a carried water task."
		if value.has("remounts") and not value.remounts.ledger.resolved: return "Commission overlaps the remount inquiry."
		if value.misl.ledger.has("workshop") and value.misl.ledger.workshop.phase in ["fuel","tools"]: return "Commission overlaps workshop cargo."
	return ""
func journal() -> Array:
	# No automatic transfer of Buddh's observations to a newly controlled officer.
	var who: String=Commission.SPECIALIST if controlling_specialist() else Commission.HERO
	var out: Array=[] if controlling_specialist() else super.journal()
	if has_economy():
		for e in _state.misl.events:
			if not e.kind.begins_with("commission."): continue
			var d:=Commission.payload(e.arg)
			if d.actor!=who: continue
			out.append({"id":"commission-"+str(e.seq),"received_tick":int(e.tick),"source_id":who,"channel":"performed",
				"text":"I took part in: "+e.kind.trim_prefix("commission.").replace("_"," ")+". This is an authored local service agreement."})
	out.sort_custom(func(a,b):return a.received_tick<b.received_tick)
	return out

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if error.is_empty() and commissioned():
		for key in ["practice","last_practice_tick","last_move_tick"]:
			_state.commission_actor[key]=int(_state.commission_actor[key])
	return error
