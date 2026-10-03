# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Optional specialist contract inside the existing supply ledger.
## Integer authored coins/portions, not historical salaries. No second treasury.
const Base := preload("res://childhood/childhood_state.gd")
const VERSION := "1792.specialist-commission.v1"
const HERO := "ranjit_singh"
const SPECIALIST := "fictional_local_drillmaster"
const HOME := Vector3(3,0.14,5)
const BROKER := Vector3(-24,0.14,-15)
const RECEPTION := Vector3(-24,0.14,-8)
const POST := Vector3(5,0.14,8)
const PRACTICE_TICKS := 180
const OFFERS := {
	"standard":{"budget":108,"agent":8,"travel":12,"signing":64,"reserve":24,"wage":12},
	"senior":{"budget":156,"agent":12,"travel":16,"signing":88,"reserve":40,"wage":20}}

static func whole(x: Variant,lo: int=0,hi: int=10000000) -> bool:
	return typeof(x) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(x)) and x==floor(x) and x>=lo and x<=hi
static func fields(v: Variant,keys: Array) -> bool:
	if not v is Dictionary or v.size()!=keys.size(): return false
	for k in keys:
		if not v.has(k): return false
	return true
static func near(a: Vector3,b: Vector3,r: float=3.0) -> bool:
	return a.is_finite() and b.is_finite() and a.distance_to(b)<=r and absf(a.y-b.y)<=0.65
static func payload(text: String) -> Dictionary:
	if text.length()>1400: return {}
	var d: Variant=JSON.parse_string(text)
	if not fields(d,["schema","actor","at","companion","option","tick","practice"]): return {}
	if d.schema!=VERSION or d.actor not in [HERO,SPECIALIST] or not d.option is String or not whole(d.tick) or not whole(d.practice,0,PRACTICE_TICKS): return {}
	if not Base.valid_point(d.at) or not Base.valid_point(d.companion): return {}
	return d
static func ready(s: Dictionary) -> bool:
	if not s.has("commission"): return false
	var c: Dictionary=s.commission
	# The active drill already debited its two portions at admission. It does
	# not need a third unallocated portion; a later failed watch still halts it.
	return c.phase=="appointed" and c.arrears==0 and c.fed and (c.lesson=="active" or s.stock.food>0)
static func committed(s: Dictionary) -> bool:
	return s.has("commission") and (s.commission.phase in ["reserved","introduced","escorting"] or s.commission.controlled==SPECIALIST or s.commission.lesson=="active")
static func carried(s: Dictionary) -> bool:
	return s.delivery=="outbound" or s.caravan=="active" or (s.has("workshop") and s.workshop.phase in ["fuel","tools"])
static func apply(s: Dictionary,kind: String,arg: String) -> String:
	var d:=payload(arg)
	if d.is_empty(): return "Malformed commission instruction."
	if carried(s): return "Settle the carried household load before a commission action."
	var at:=Base.point(d.at);var companion:=Base.point(d.companion)
	if kind=="commission.reserve":
		if s.has("commission") or not OFFERS.has(d.option) or d.actor!=HERO or not near(at,HOME): return "Choose one available commission at the quartermaster."
		var o: Dictionary=OFFERS[d.option]
		if s.treasury<o.budget: return "Insufficient uncommitted household funds. Earn or contribute funds first."
		s.treasury-=o.budget
		s.commission={"schema":VERSION,"offer":d.option,"specialist":SPECIALIST,"phase":"reserved","controlled":HERO,
			"escrow":o.budget,"spent":0,"arrears":0,"fed":true,"lesson":"none","lesson_start":-1,"guard_slot":-1}
		return ""
	if not s.has("commission"): return "No authorized commission."
	var c: Dictionary=s.commission;var o: Dictionary=OFFERS[c.offer]
	if d.actor!=c.controlled: return "This instruction belongs to the active character only."
	if kind not in ["commission.control","commission.lesson_start","commission.lesson_finish"] and d.actor!=HERO:
		return "The instructor cannot authorize sovereign funds or read the household accounts."
	match kind:
		"commission.broker":
			if d.option!="" or c.phase!="reserved" or not near(at,BROKER): return "Carry the authorization to the market agent."
			c.escrow-=o.agent;c.spent+=o.agent;c.phase="introduced"
		"commission.engage":
			if d.option!="" or c.phase!="introduced" or not near(at,RECEPTION) or not near(companion,RECEPTION): return "Meet the introduced candidate at the receiving yard."
			c.escrow-=o.travel;c.spent+=o.travel;c.phase="escorting"
		"commission.appoint":
			if d.option!="" or c.phase!="escorting" or not near(at,HOME) or not near(companion,HOME,4): return "Return together to the quartermaster to sign the service agreement."
			c.escrow-=o.signing;c.spent+=o.signing;c.phase="appointed"
		"commission.cancel":
			if d.option!="" or c.phase not in ["reserved","introduced"] or not near(at,HOME): return "Cancel at home before accepting the candidate's travel."
			s.treasury+=c.escrow;c.escrow=0;c.phase="cancelled"
		"commission.release_reserve":
			if d.option!="" or c.phase!="appointed" or c.escrow==0 or not near(at,HOME): return "No unspent reserve to release here."
			s.treasury+=c.escrow;c.escrow=0
		"commission.pay_arrears":
			if d.option!="" or c.arrears==0 or not near(at,HOME): return "No specialist arrears to settle here."
			if s.treasury<c.arrears: return "Not enough uncommitted funds to settle specialist arrears."
			c.spent+=c.arrears;s.treasury-=c.arrears;c.arrears=0
		"commission.dismiss":
			if d.option!="" or c.phase!="appointed" or c.lesson=="active" or not near(at,HOME) or not near(companion,HOME,4): return "Settle the drill and dismiss the present instructor at home."
			s.treasury+=c.escrow;c.escrow=0;c.phase="dismissed" # Arrears remain payable.
		"commission.control":
			if c.phase!="appointed" or d.option not in [HERO,SPECIALIST] or d.option==c.controlled: return "That viewpoint is unavailable."
			# A supplied lesson can later lose pay or food at the ordinary watch.
			# Returning to the principal allows those liabilities to be addressed;
			# the paid work and its pupil reservation remain in the same ledger.
			if c.lesson=="active" and d.option!=HERO: return "Return to Buddh's viewpoint to settle the active drill first."
			if not near(at,HOME,4) or not near(companion,HOME,4): return "Regroup at the household before changing viewpoint."
			c.controlled=d.option # No money, items, knowledge or body coordinates move.
		"commission.lesson_start":
			if d.option!="" or not ready(s) or c.lesson!="none" or not near(at,HOME,4) or not near(companion,HOME,4): return "A present, paid and supplied instructor is required."
			if s.guards<1 or s.duty_guards<s.guards: return "Hire and provision a guard for the drill first."
			if s.stock.food<2 or s.stock.tools<1: return "The drill needs two food portions and one tool unit."
			if d.tick+PRACTICE_TICKS>10000000: return "Too late in the bounded chapter clock to begin the drill."
			s.stock.food-=2;s.stock.tools-=1;c.lesson="active";c.lesson_start=int(d.tick);c.guard_slot=s.guards-1
		"commission.lesson_finish":
			if d.option!="" or not ready(s) or c.lesson!="active" or s.duty_guards<=c.guard_slot or d.practice!=PRACTICE_TICKS or d.tick<c.lesson_start+PRACTICE_TICKS or not near(at,HOME,4) or not near(companion,HOME,4): return "The funded drill has not been physically completed."
			c.lesson="complete"
		_: return "Unknown commission operation."
	return ""

static func upkeep(s: Dictionary) -> void:
	if not s.has("commission") or s.commission.phase!="appointed": return
	var c: Dictionary=s.commission;var due: int=OFFERS[c.offer].wage
	# Existing household payroll settles first. Reserve is exclusively wage money.
	var reserved:=mini(c.escrow,due);c.escrow-=reserved;due-=reserved;c.spent+=reserved
	var paid:=mini(s.treasury,due);s.treasury-=paid;c.spent+=paid;c.arrears+=due-paid
	c.fed=s.stock.food>=1;s.stock.food=maxi(0,s.stock.food-1)

static func blank_actor() -> Dictionary:
	return {"id":SPECIALIST,"position":Base.coords(RECEPTION),"yaw":0.0,"velocity":[0.0,0.0,0.0],"practice":0,"last_practice_tick":-1,"last_move_tick":-1}
static func budget(s: Dictionary) -> Dictionary:
	var base_wages: int=s.workers+2*s.guards
	var wage: int=OFFERS[s.commission.offer].wage if s.has("commission") and s.commission.phase=="appointed" else 0
	var held: int=s.commission.escrow if s.has("commission") else 0
	var debt: int=s.arrears+(s.commission.arrears if s.has("commission") else 0)
	return {"available":s.treasury,"reserved":held,"arrears":debt,"next_wages":base_wages+wage,
		"next_unreserved_wages":base_wages+maxi(0,wage-held),"food":1+s.workers+s.guards+(1 if wage>0 else 0),"feed":2*s.horses}
