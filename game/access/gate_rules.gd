# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Bounded, authored gate authority inside the existing Home world.
## Witness/contact booleans are admitted runtime observations, not authenticated history.
## Control memory and the player's received journal have separate delivery boundaries.
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Fields := preload("res://misl/service_rules.gd")
const VERSION := "1792.household-gate-passage.v1"
const GATE_ID := "household_threshold_03"
const GUARD_ID := "fictional_household_gate_keeper"
const AUTHORITY := "sukerchakia_household"
const ANCHOR := Base.GATES[2]
const GUARD := ANCHOR + Vector3(2.25,0,-0.25)
const LANE_HALF_WIDTH := 1.9
const STANDING_HEIGHT := 0.75
const POSITION_EPSILON := 0.000001 # Vector3 coordinates use float32; this bounds representation rounding.
const LOCAL_DISTANCE := 3.0
const RUSH_SPEED := 5.0 # Authored metres/second, shared by foot and horse crossings.
const MAX_EVENTS := 64
const PLAYER_ACTIONS := ["request","check","account","reconcile"]

static func initial() -> Dictionary:
	return {"permit":false,"challenge":false,"challenge_heard":false,
		"witnessed_conduct":"","crossings":0,"memories":[]}

static func begin(tick: int) -> Dictionary:
	return {"schema":VERSION,"gate_id":GATE_ID,"guard_id":GUARD_ID,
		"authority":AUTHORITY,"historical_class":"authored_gameplay_fixture",
		"origin_tick":tick,"events":[],"ledger":initial()}

static func whole(value: Variant,lo: int=0,hi: int=10000000) -> bool:
	return Supply.finite_number(value) and value==floor(value) and value>=lo and value<=hi

static func crossing(before: Vector3,after: Vector3) -> bool:
	# Half-open sides count a plane landing once, independent of frame subdivision.
	if not ((before.z<ANCHOR.z and after.z>=ANCHOR.z) or (before.z>=ANCHOR.z and after.z<ANCHOR.z)):
		return false
	var fraction: float=(ANCHOR.z-before.z)/(after.z-before.z)
	var intersection:=before.lerp(after,fraction)
	# Rooftop travel and side routes are not passage through this central opening.
	return absf(intersection.x-ANCHOR.x)<=LANE_HALF_WIDTH+POSITION_EPSILON and absf(intersection.y-ANCHOR.y)<=STANDING_HEIGHT+POSITION_EPSILON

static func _remember(s: Dictionary,e: Dictionary,source: String,channel: String,text: String) -> void:
	s.memories.append({"id":"gate-passage-%d"%int(e.seq),"received_tick":int(e.tick),
		"source_id":source,"channel":channel,"text":text})

static func _account(s: Dictionary) -> String:
	match s.witnessed_conduct:
		"rushed_unpermitted": return "I saw you rush the central household passage without a passage agreement."
		"rushed": return "I saw you rush the central household passage despite our agreement to pass at a walk."
		"unpermitted": return "I saw you cross the central household passage without a passage agreement."
	return "I have no unsettled witnessed passage to account for."

static func apply(s: Dictionary,e: Dictionary) -> String:
	if not Fields.fields(e,["seq","tick","kind","before","after","delta","witnessed","authorized","mounted","speed","grounded","contact"]):
		return "Malformed household gate receipt."
	if not whole(e.seq,1,MAX_EVENTS) or not whole(e.tick) or not e.kind is String or not Base.valid_point(e.before) or not Base.valid_point(e.after):
		return "Invalid household gate receipt identity, time or position."
	for key in ["witnessed","authorized","mounted","grounded","contact"]:
		if not e[key] is bool: return "Invalid household gate observation flag."
	if not Supply.finite_number(e.delta) or not Supply.finite_number(e.speed) or e.speed<0:
		return "Invalid household gate motion values."
	# Authorization is reduced from the prior ledger; a caller cannot assert it.
	if e.authorized!=s.permit: return "Gate authorization differs from its receipt prefix."
	var before:=Base.point(e.before)
	var after:=Base.point(e.after)
	if e.kind=="cross":
		if e.contact or e.delta<=0 or e.delta>0.1 or not crossing(before,after): return "Not a bounded central gate crossing."
		var travelled: float=Base.distance(before,after)
		var limit: float=Base.Riding.MAX_SPEED if e.mounted else 9.0
		if travelled>limit*e.delta+0.08 or e.speed>limit+(0.08/e.delta if not e.mounted else 0.0):
			return "Gate crossing exceeds inherited travel bounds."
		if not e.mounted and absf(e.speed-travelled/e.delta)>0.000001:
			return "Walking gate speed differs from its admitted motion."
		var rushed: bool=maxf(float(e.speed),travelled/e.delta)>RUSH_SPEED
		var misconduct: bool=rushed or not e.authorized
		s.permit=false;s.crossings+=1 # One crossing consumes one agreement, witnessed or not.
		if e.witnessed and misconduct:
			s.challenge=true;s.challenge_heard=false
			s.witnessed_conduct="rushed_unpermitted" if rushed and not e.authorized else "rushed" if rushed else "unpermitted"
		# The player knows their own passage, but is not told whether a guard saw it.
		_remember(s,e,"self","observed","I crossed the central household passage "+("on horseback." if e.mounted else "on foot."))
		return ""
	if e.kind not in PLAYER_ACTIONS: return "Unknown household gate action."
	if e.mounted or not e.contact or e.witnessed or before!=after or e.delta!=0 or e.speed!=0 or not e.grounded or before.distance_to(GUARD)>LOCAL_DISTANCE or absf(before.y-GUARD.y)>STANDING_HEIGHT:
		return "Speak to the gate keeper on foot through local, unobstructed contact."
	match e.kind:
		"request":
			if s.challenge:
				s.challenge_heard=true
				_remember(s,e,GUARD_ID,"spoken_account",_account(s)+" Hear this account before asking us to settle it.")
			else:
				s.permit=true
				_remember(s,e,GUARD_ID,"spoken_permission","You may use this passage once. Keep to a controlled pace between the markers.")
		"check":
			if s.challenge: s.challenge_heard=true
			_remember(s,e,GUARD_ID,"spoken_account",_account(s) if s.challenge else "Your single passage agreement is still available." if s.permit else "Ask me locally before your next central passage.")
		"account":
			if s.challenge: s.challenge_heard=true
			_remember(s,e,GUARD_ID,"spoken_account",_account(s))
		"reconcile":
			if not s.challenge or not s.challenge_heard: return "Hear the gate keeper's unsettled account before reconciliation."
			s.challenge=false;s.challenge_heard=false;s.witnessed_conduct="";s.permit=true
			_remember(s,e,GUARD_ID,"spoken_permission","We have settled the passage account. Use the central household passage once, at a walk.")
	return ""

static func replay(value: Variant,tick: int) -> Dictionary:
	if not Fields.fields(value,["schema","gate_id","guard_id","authority","historical_class","origin_tick","events","ledger"]):
		return {"error":"Malformed household gate record."}
	if value.schema!=VERSION or value.gate_id!=GATE_ID or value.guard_id!=GUARD_ID or value.authority!=AUTHORITY or value.historical_class!="authored_gameplay_fixture":
		return {"error":"Unsupported household gate identity or authority."}
	if not whole(value.origin_tick,0,tick) or not value.events is Array or value.events.is_empty() or value.events.size()>MAX_EVENTS:
		return {"error":"Invalid gate origin or finite receipt budget."}
	var s:=initial()
	var prior:=int(value.origin_tick)
	var last_crossing: int=-1
	for n in range(value.events.size()):
		var e: Variant=value.events[n]
		if not e is Dictionary or not whole(e.get("tick"),prior,tick) or e.get("seq")!=n+1:
			return {"error":"Unordered household gate receipt."}
		if n==0 and (e.get("kind")!="request" or e.tick!=value.origin_tick):
			return {"error":"Gate passage must begin with a received local request."}
		if e.get("kind")=="cross":
			if int(e.tick)==last_crossing: return {"error":"Duplicate gate crossing in one simulation tick."}
			last_crossing=int(e.tick)
		var error:=apply(s,e)
		if not error.is_empty(): return {"error":error}
		prior=int(e.tick)
	if not Supply._equal(value.ledger,s): return {"error":"Gate permission, challenge or received journal differs from receipts."}
	return {"error":"","ledger":s}
