extends RefCounted
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## One finite authored commission, reduced through the EXISTING household receipt stream.
const Economy := preload("res://territory/misl_rules.gd")
const VERSION := "gujranwala-smith.v1"
const SITE := Vector3(-46,0.14,-7)
const FEE := 4
const FUEL := 2
const OUTPUT := 2
const WORK_TICKS := 600
const CARRY_SPEED := 3.0
const PLAYER_ACTIONS := ["reserve","start","collect","deliver","refund"]
const WORDS := {
	"reserve":"Quartermaster: Take these two timber bundles and the workshop payment to the smith beyond the west gate. Bring both tool bundles back to our store.",
	"start":"Smith: The fuel and payment are here. I will finish your two tool bundles. Come back to this court to collect them.",
	"collect":"Smith: Both bundles are ready. They are now in your care; carry them back to the household store.",
	"deliver":"Quartermaster: Both bundles are back in stock. This is household property, not a personal cash reward.",
	"refund":"Quartermaster: The undelivered fuel and workshop payment are back. This commission is cancelled."}

static func phase(s: Dictionary) -> String:
	return str(s.workshop.phase) if s.has("workshop") else "unassigned"

static func carrying(s: Dictionary) -> bool:
	return phase(s) in ["fuel","tools"]

static func apply(s: Dictionary, kind: String, arg: String) -> String:
	if not kind.begins_with("smith."):
		if kind=="accept_delivery" and carrying(s): return "Return the workshop load before accepting food cargo."
		return Economy.apply(s,kind,arg)
	# Receipt tick is duplicated in this canonical decimal arg and cross-checked by validate.
	if not arg.is_valid_int() or str(arg.to_int())!=arg or not Economy.whole(arg.to_int(),0,10000000):
		return "Invalid workshop tick."
	var tick := arg.to_int()
	var action := kind.trim_prefix("smith.")
	if action=="reserve":
		if s.has("workshop"): return "This finite commission is already assigned or settled."
		if s.treasury<FEE or s.stock.timber<FUEL: return "Need four household coins and two timber bundles."
		if s.delivery=="outbound": return "Deliver the food cargo before taking a workshop load."
		s.treasury-=FEE;s.stock.timber-=FUEL
		s.workshop={"schema":VERSION,"phase":"fuel","reserved_tick":tick,"started_tick":-1,
			"ready_tick":-1,"picked_up_tick":-1,"settled_tick":-1,
			"fuel_carried":FUEL,"fuel_used":0,"tools_carried":0,"fee_held":FEE,"fee_paid":0}
		return ""
	if not s.has("workshop"): return "No workshop commission."
	var w: Dictionary=s.workshop
	if tick<int(w.reserved_tick): return "Workshop action predates its assignment."
	match action:
		"start":
			if w.phase!="fuel": return "Bring the assigned fuel to the smith first."
			if tick+WORK_TICKS>10000000: return "Too late in the bounded chapter clock to start this job."
			w.phase="working";w.started_tick=tick;w.fuel_carried=0;w.fuel_used=FUEL;w.fee_held=0;w.fee_paid=FEE
		"ready":
			if w.phase!="working" or tick!=int(w.started_tick)+WORK_TICKS: return "Workshop completion is clock-owned."
			w.phase="ready";w.ready_tick=tick
		"collect":
			if w.phase!="ready" or tick<int(w.ready_tick): return "No finished order to collect."
			if s.delivery=="outbound": return "Deliver your food cargo before collecting another load."
			w.phase="tools";w.tools_carried=OUTPUT;w.picked_up_tick=tick
		"deliver":
			if w.phase!="tools" or tick<int(w.picked_up_tick): return "No carried workshop tools to return."
			if Economy.stored(s)+OUTPUT>Economy.capacity(s): return "Need two free household store units. Keep the tools until there is room."
			s.stock.tools+=OUTPUT;s.favor=mini(100,s.favor+3)
			w.phase="complete";w.tools_carried=0;w.settled_tick=tick
		"refund":
			if w.phase!="fuel": return "Only undelivered fuel and payment can be returned."
			if Economy.stored(s)+FUEL>Economy.capacity(s): return "Need two free store units before returning the fuel."
			s.stock.timber+=FUEL;s.treasury+=FEE
			w.phase="cancelled";w.fuel_carried=0;w.fee_held=0;w.settled_tick=tick
		_: return "Unknown workshop action."
	return ""

static func validate(value: Variant, tick: int) -> String:
	var error:=Economy.validate(value,tick,apply)
	if not error.is_empty(): return error
	var due := -1
	for e in value.events:
		if due>=0 and int(e.tick)>=due:
			# Original upkeep settles before automatic workshop completion at the same tick.
			if not (e.kind=="watch" and int(e.tick)==due) and not (e.kind=="smith.ready" and int(e.tick)==due):
				return "Missing due workshop completion before a later transaction."
		if e.kind.begins_with("smith.") and e.arg!=str(int(e.tick)): return "Workshop receipt clock mismatch."
		if e.kind=="smith.start": due=int(e.tick)+WORK_TICKS
		if e.kind=="smith.ready": due=-1
	if due>=0 and tick>=due and value.events.size()<Economy.MAX_EVENTS: return "A due workshop completion is missing."
	return ""
