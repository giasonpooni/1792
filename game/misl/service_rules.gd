# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## A bounded, fictional household service detail. Not a historical muster strength.
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const VERSION := "sukerchakia-service.v1"
const MAX_EVENTS := 32
const SERVICE_TICKS := 120 # Two playable seconds, not historical duty duration.
const SPEED := 2.4
const SITES := {"market":Vector3(-23,0.14,-13),"well":Vector3(24,0.14,10)}
const NAMES := {"market":"Western market loading place","well":"Eastern well approach"}
const ACCOUNTS := {
	"market":"The loading place was clear when I attended. I spoke to the handler; this does not establish the safety of the whole road.",
	"well":"I attended the well approach and heard the water carrier's request. That account does not establish ownership of the land."}

static func home(slot: int) -> Vector3: return Vector3(-2+slot*2,0.14,10.5)
static func identity(slot: int) -> String: return "household_guard_slot_%d" % slot
static func motion(slot: int) -> Dictionary:
	return {"id":identity(slot),"position":Base.coords(home(slot)),"yaw":0.0,"velocity":[0.0,0.0,0.0]}
static func initial() -> Dictionary:
	return {"heard":[],"completed":[],"active":"","slot":-1,"stage":"idle","onsite_tick":-1,"memories":[]}
static func reserved(s: Dictionary) -> bool: return s.stage!="idle"
static func ready(economy: Dictionary, slot: int) -> bool:
	return economy.guards>slot and economy.duty_guards>slot and economy.arrears==0 and economy.food_shortfall==0
static func fields(value: Variant,names: Array) -> bool:
	if not value is Dictionary or value.size()!=names.size(): return false
	for key in names:
		if not value.has(key): return false
	return true

static func apply(s: Dictionary, e: Dictionary, economy: Dictionary) -> String:
	var kind: String=e.kind
	var arg: String=e.arg
	var at:=Base.point(e.position)
	var tick:=int(e.tick)
	if kind not in ["hear","dispatch"] and arg!="": return "Unexpected service argument."
	if kind in ["begin","dispatch","debrief"] and Base.distance(at,Supply.QUARTERMASTER)>3: return "Speak to the quartermaster on foot."
	match kind:
		"begin": pass
		"hear":
			if not SITES.has(arg) or arg in s.heard: return "Hear each local request once."
			if Base.distance(at,SITES[arg])>3: return "Visit the actual speaker."
			s.heard.append(arg)
			s.memories.append({"id":"service-request-"+arg,"source_id":"fictional_"+arg+"_speaker","channel":"spoken_request",
				"received_tick":tick,"text":"A local representative asks for a household guard to attend the "+NAMES[arg]+". A request is not a land or revenue claim."})
		"dispatch":
			if arg not in s.heard or arg in s.completed or reserved(s): return "One active detail; hear the request before committing anyone."
			var slot:=int(economy.guards)-1
			if slot<0 or not ready(economy,slot): return "Hire a guard and complete a supplied, paid watch before dispatch."
			s.slot=slot;s.active=arg;s.stage="outbound";s.onsite_tick=-1
		"arrive":
			if s.stage!="outbound" or not ready(economy,s.slot) or Base.distance(at,SITES[s.active])>1.7: return "Guard has not physically reached the service site."
			s.stage="attending";s.onsite_tick=tick
		"finish":
			if s.stage!="attending" or tick<s.onsite_tick+SERVICE_TICKS or not ready(economy,s.slot) or Base.distance(at,SITES[s.active])>1.7:
				return "The supplied local attendance is not complete."
			s.stage="returning"
		"home":
			if s.stage!="returning" or Base.distance(at,home(s.slot))>1.7: return "Guard must physically return home."
			s.stage="awaiting_account"
		"debrief":
			if s.stage!="awaiting_account": return "No returned guard is ready to give an account."
			s.memories.append({"id":"service-account-"+s.active,"source_id":identity(s.slot),"channel":"spoken_account",
				"received_tick":tick,"text":ACCOUNTS[s.active]})
			s.completed.append(s.active);s.active="";s.slot=-1;s.stage="idle";s.onsite_tick=-1
		_: return "Unknown service event."
	return ""

static func valid_motion(value: Variant,slot: int) -> bool:
	if not fields(value,["id","position","yaw","velocity"]) or value.id!=identity(slot): return false
	return Base.valid_point(value.position) and Supply.valid_velocity(value.velocity) and Supply.finite_number(value.yaw) and absf(value.yaw)<=PI and Vector2(value.velocity[0],value.velocity[2]).length()<=SPEED+0.01

static func replay(value: Variant, supply: Dictionary, now: int, reducer: Callable=Callable()) -> Dictionary:
	if not fields(value,["schema","origin_tick","events","ledger","agent"]) or value.schema!=VERSION: return {"error":"Unsupported service record."}
	if not Supply.whole(value.origin_tick,int(supply.origin_tick),now) or not value.events is Array or value.events.is_empty() or value.events.size()>MAX_EVENTS:
		return {"error":"Invalid service start/event budget."}
	# Recover the SAME supply ledger at each exact receipt prefix. No cloned treasury.
	var economies: Array=[Supply.initial()]
	for receipt in supply.events:
		var next: Dictionary=economies[-1].duplicate(true)
		var error: String=reducer.call(next,receipt.kind,receipt.arg) if reducer.is_valid() else Supply.apply(next,receipt.kind,receipt.arg)
		if not error.is_empty(): return {"error":error}
		economies.append(next)
	var state:=initial()
	var prior_tick:=int(value.origin_tick)
	var prior_seq:=0
	for i in range(value.events.size()):
		var e: Variant=value.events[i]
		if not fields(e,["seq","tick","economy_seq","kind","arg","position"]) or not e.kind is String or not e.arg is String or not Base.valid_point(e.position):
			return {"error":"Malformed service receipt."}
		if not Supply.whole(e.seq,1) or e.seq!=i+1 or not Supply.whole(e.tick,prior_tick,now) or not Supply.whole(e.economy_seq,prior_seq,supply.events.size()):
			return {"error":"Service receipts are not ordered."}
		var n:=int(e.economy_seq)
		if n>0 and supply.events[n-1].tick>e.tick: return {"error":"Service used future supply information."}
		if n<supply.events.size() and supply.events[n].tick<e.tick: return {"error":"Service hid preceding supply receipts."}
		if reserved(state):
			for j in range(prior_seq,n+1):
				if economies[j].guards<=state.slot: return {"error":"Reserved guard was released while away."}
		if i==0 and (e.kind!="begin" or e.tick!=value.origin_tick): return {"error":"Service start is unbound."}
		if i>0 and e.kind=="begin": return {"error":"Service cannot begin twice."}
		var error:=apply(state,e,economies[n])
		if not error.is_empty(): return {"error":error}
		prior_tick=int(e.tick);prior_seq=n
	if reserved(state):
		for j in range(prior_seq,economies.size()):
			if economies[j].guards<=state.slot: return {"error":"Reserved guard no longer exists."}
	if not Supply._equal(state,value.ledger): return {"error":"Service outcome differs from receipts."}
	if not valid_motion(value.agent,state.slot if reserved(state) else -1): return {"error":"Invalid service agent."}
	var p:=Base.point(value.agent.position)
	if state.stage=="attending" and Base.distance(p,SITES[state.active])>1.7: return {"error":"Attending guard left the service site."}
	if state.stage=="awaiting_account" and Base.distance(p,home(state.slot))>1.7: return {"error":"Returned guard is not home."}
	return {"error":"","ledger":state}
