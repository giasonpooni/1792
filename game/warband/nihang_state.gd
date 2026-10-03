# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://commissions/commission_state.gd"
## Optional state on the original Home authority, original tick and whole-world save.
const Camp := preload("res://warband/nihang_rules.gd")

func nihang_camp() -> Dictionary:
	return _state.nihang_camp.duplicate(true) if _state.has("nihang_camp") else Camp.initial()

func nihang_active() -> bool:
	return _state.has("nihang_camp") and Camp.active(_state.nihang_camp.phase)

func nihang_address(speaker: String, phase: String=Names.BEFORE_ACCESSION, formal: bool=false) -> String:
	var established: bool=_state.has("nihang_camp") and _state.nihang_camp.phase!="unmet"
	return Names.relationship_address(speaker,Names.HERO_ID,established,phase,formal)

func camp_action(kind: String, contact: bool, grounded: bool) -> String:
	if kind not in Camp.WORDS: return "Unknown camp action."
	if stage() in ["active","caught"] or brawl_busy(): return "Finish the immediate danger before speaking with the camp."
	if kind.begins_with("invite") and (super._other_commitment() or carrying_workshop()): return "Settle your other undertaking before asking these riders to accompany you."
	var candidate:=nihang_camp()
	if candidate.events.size()>=Camp.MAX_EVENTS: return "This camp account has reached its bounded capacity."
	var event: Dictionary={"kind":kind,"tick":int(_state.childhood.tick),"position":coords(position()),
		"mounted":mounted(),"contact":contact,"grounded":grounded,"ride_gate":int(_state.childhood.ride_gate),"mounts":candidate.mounts.duplicate(true)}
	var error:=Camp.apply(candidate,event)
	if not error.is_empty(): return error
	candidate.events.append(event)
	error=Camp.validate(candidate,int(_state.childhood.tick))
	if error.is_empty(): _state.nihang_camp=candidate
	return error

func record_nihang_motion(mounts: Array, delta: float) -> String:
	if not nihang_active(): return "There is no active camp escort."
	var current: Dictionary=_state.nihang_camp
	if not Riding.finite_number(delta) or delta<=0 or delta>0.1 or current.motion_tick>=_state.childhood.tick: return "Camp motion requires one sample per advancing Home tick."
	if mounts.size()!=2: return "Camp roster changed."
	for i in range(2):
		if not Camp.valid_mount(mounts[i],i): return "Malformed camp mount observation."
		if Camp.RIDERS[i] not in current.selected:
			if mounts[i]!=current.mounts[i]: return "An uninvited rider moved."
			continue
		if distance(Camp.point(mounts[i].position),Camp.point(current.mounts[i].position))>Camp.SPEED*delta+0.08: return "Camp rider moved beyond its admitted motor step."
		if absf(float(mounts[i].position[1])-float(current.mounts[i].position[1]))>50*delta+0.1: return "Camp rider vertical step is out of bounds."
	current.mounts=mounts.duplicate(true)
	current.motion_tick=int(_state.childhood.tick)
	return ""

func _other_commitment() -> bool:
	return nihang_active() or super._other_commitment()

func begin_remounts() -> String:
	return "Return your camp companions before searching for the remounts." if nihang_active() else super.begin_remounts()

func remount_action(kind: String) -> String:
	return "Return your camp companions before searching for the remounts." if nihang_active() else super.remount_action(kind)

func commission_action(kind: String, option: String = "") -> String:
	return "Return your camp companions before arranging an instructor." if nihang_active() else super.commission_action(kind, option)

func begin_brawl() -> String:
	return "Return your camp companions before another outing." if nihang_active() else super.begin_brawl()

func begin_service() -> String:
	return "Settle the camp escort before arranging another service detail." if nihang_active() else super.begin_service()

func service_action(kind: String,arg: String="") -> String:
	return "Return your camp companions before dispatching a service detail." if nihang_active() and kind=="dispatch" else super.service_action(kind,arg)

func operate(kind: String,arg: String="") -> String:
	if nihang_active() and kind in ["accept_delivery","accept_escort"]: return "Return your camp companions before another undertaking."
	return super.operate(kind,arg)

func begin_water_round() -> String:
	return "Return your camp companions before taking water." if nihang_active() else super.begin_water_round()

func water_action(kind: String) -> String:
	return "Return your camp companions before taking water." if nihang_active() else super.water_action(kind)

func rest_watch() -> String:
	return "Return your camp companions before resting through a watch." if nihang_active() else super.rest_watch()

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed Home snapshot."
	var parent: Dictionary=value.duplicate(true);parent.erase("nihang_camp")
	var error:=super.validate(parent)
	if not error.is_empty() or not value.has("nihang_camp"): return error
	error=Camp.validate(value.nihang_camp,int(value.childhood.tick))
	if not error.is_empty(): return error
	for e in value.nihang_camp.events:
		if e.ride_gate>value.childhood.ride_gate: return "Camp receipt claims a future household riding lesson."
	if Camp.active(value.nihang_camp.phase):
		if value.has("remounts") and not value.remounts.ledger.resolved: return "Camp escort conflicts with the remount inquiry."
		if value.has("misl") and value.misl.ledger.has("commission") and Commission.committed(value.misl.ledger): return "Camp escort conflicts with the instructor's commission."
		if value.has("service") and Service.reserved(value.service.ledger): return "Camp escort conflicts with active service."
		if value.has("youth_brawl") and value.youth_brawl.ledger.phase!="reported": return "Camp escort conflicts with the bazaar outing."
		if value.has("misl") and (Craft.carrying(value.misl.ledger) or value.misl.ledger.delivery=="outbound" or value.misl.ledger.caravan=="active"): return "Camp escort conflicts with cargo."
		if value.has("water_round") and (value.water_round.ledger.carried>0 or value.water_round.ledger.phase=="drawing"): return "Camp escort conflicts with water custody."
	return ""

func journal() -> Array:
	var entries:=super.journal()
	for event in nihang_camp().events:
		entries.append({"id":"nihang_"+event.kind,"received_tick":int(event.tick),
			"source_id":Camp.RIDERS[0] if event.kind in ["care","turn"] else Camp.ELDER,
			"channel":"heard","text":Camp.WORDS[event.kind]})
	entries.sort_custom(func(a,b): return a.received_tick<b.received_tick)
	return entries
