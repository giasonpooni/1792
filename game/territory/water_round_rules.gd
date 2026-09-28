# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Pure finite-task reducer. Six units are an assigned task, not an aquifer capacity.
const VERSION := "gujranwala-water-round.v1"
const MODEL_ID := "household-water-round.v1"
const WELL := Vector3(24,0.14,15)
const STORE := Vector3(3,0.14,5)
const TOTAL := 6
const LOAD := 3
const DRAW_TICKS := 180
const MAX_EVENTS := 128
const CARRY_SPEED := 3.0
const Economy := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")

static func initial() -> Dictionary:
	return {"remaining":TOTAL,"carried":0,"stored":0,"phase":"ready","started_tick":-1,"completed_tick":-1}

static func near_site(p: Vector3, site: Vector3) -> bool:
	return Base.distance(p,site)<=3.0 and absf(p.y-site.y)<=0.65

static func apply(s: Dictionary, kind: String, tick: int, p: Vector3) -> String:
	# Admission runs on a detached candidate. The caller commits only a successful result.
	match kind:
		"draw":
			if s.phase!="ready" or s.remaining<LOAD: return "No empty carrier or unfinished allocation."
			if not near_site(p,WELL): return "Stand beside the well on foot."
			s.phase="drawing"
			s.started_tick=tick
		"cancel":
			if s.phase!="drawing" or tick>s.started_tick+DRAW_TICKS: return "No cancellable draw."
			s.phase="ready"
			s.started_tick=-1
		"filled":
			if s.phase!="drawing" or tick!=s.started_tick+DRAW_TICKS or not near_site(p,WELL): return "Draw has not completed at the well."
			s.remaining-=LOAD
			s.carried=LOAD
			s.phase="carrying"
			s.started_tick=-1
		"deposit":
			if s.phase!="carrying" or s.carried!=LOAD or not near_site(p,STORE): return "Carry the water back to the household store."
			s.stored+=s.carried
			s.carried=0
			s.phase="complete" if s.stored==TOTAL else "ready"
			if s.phase=="complete": s.completed_tick=tick
		_:
			return "Unsupported water-round operation."
	return ""

static func replay(events: Array) -> Dictionary:
	var s:=initial()
	for e in events: apply(s,e.kind,int(e.tick),Base.point(e.position))
	return s

static func validate(w: Variant, tick: int, earliest: int, p: Vector3, mounted: bool) -> String:
	if not w is Dictionary or w.size()!=5 or w.get("schema")!=VERSION or w.get("model_id")!=MODEL_ID: return "Malformed water round."
	if not Economy.whole(w.get("origin_tick"),earliest,tick): return "Water assignment precedes the allowance or is in the future."
	if not w.get("events") is Array or w.events.size()>MAX_EVENTS or not w.get("ledger") is Dictionary: return "Invalid water receipts."
	var expected:=initial()
	var prior:=int(w.origin_tick)
	for i in range(w.events.size()):
		var e: Variant=w.events[i]
		if not e is Dictionary or e.size()!=5 or e.get("actor_id")!="ranjit_singh": return "Invalid water-operation identity."
		if not Economy.whole(e.get("seq"),i+1,i+1) or not Economy.whole(e.get("tick"),prior,tick) or not e.get("kind") is String: return "Reordered or future water receipt."
		if not Base.valid_point(e.get("position")): return "Invalid water-operation pose."
		if e.kind=="draw" and i>MAX_EVENTS-3: return "A draw must reserve space for filling and deposit."
		var error:=apply(expected,e.kind,int(e.tick),Base.point(e.position))
		if not error.is_empty(): return error
		prior=int(e.tick)
	if not Economy._equal(expected,w.ledger): return "Water quantities or phase disagree with receipts."
	if expected.remaining+expected.carried+expected.stored!=TOTAL: return "Water transfer is not conserved."
	if expected.phase=="drawing":
		if tick>=expected.started_tick+DRAW_TICKS or not near_site(p,WELL) or mounted: return "Stale or displaced pending draw."
	if expected.carried>0 and mounted: return "Open water carriers cannot be mounted in this profile."
	return ""
