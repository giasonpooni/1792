extends RefCounted
## Authored local-road assignment. It owns no money, cargo, actor or clock.
const VERSION := "caravan-road-dispute.v1"
const Economy := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
const SPEAKER := Vector3(-16,0.14,-9.2)
const BOOM := Vector3(-12,1.05,-11.5)
const REPLY_DELAY := 600 # Ten active seconds, not historical courier travel calibration.
const APPROACH := [Vector3(-22,0.14,-12),Vector3(-16,0.14,-12)]
const DIRECT := [Vector3(-10,0.14,-12),Vector3(2,0.14,-10),Vector3(3,0.14,4)]
const BYPASS := [Vector3(-17,0.14,-20),Vector3(-7,0.14,-20),Vector3(-7,0.14,-12),Vector3(2,0.14,-10),Vector3(3,0.14,4)]
const CHOICES := ["recognize_claim","seek_confirmation","bypass"]

static func initial(tick: int) -> Dictionary:
	return {"schema":VERSION,"caravan_id":Economy.CARAVAN_ID,"accepted_tick":tick,
		"visited":[],"heard_tick":-1,"choice":"","decision_tick":-1,
		"reply_received_tick":-1,"completed_tick":-1}

static func permitted(r: Dictionary) -> bool:
	return r.choice=="recognize_claim" or (r.choice=="seek_confirmation" and r.reply_received_tick>=0)

static func route(r: Dictionary) -> Array:
	var points: Array=APPROACH.duplicate()
	if r.choice=="bypass": points.append_array(BYPASS)
	elif permitted(r): points.append_array(DIRECT)
	return points

static func phase(r: Dictionary) -> String:
	if r.completed_tick>=0: return "complete"
	if r.visited.size()<APPROACH.size(): return "approaching"
	if r.heard_tick<0: return "hear_claim"
	if r.choice=="": return "choose"
	if r.choice=="seek_confirmation" and r.reply_received_tick<0: return "await_reply"
	return "arrived" if r.visited.size()==route(r).size() else "travelling"

static func target(r: Dictionary) -> Vector3:
	var points:=route(r)
	return points[mini(r.visited.size(),points.size()-1)]

static func moving(r: Dictionary) -> bool:
	return phase(r) in ["approaching","travelling"]

static func validate(value: Variant, world: Dictionary) -> String:
	if not value is Dictionary or value.size()!=9: return "Malformed disputed-road record."
	for key in initial(0):
		if not value.has(key): return "Missing disputed-road field."
	if value.schema!=VERSION or value.caravan_id!=Economy.CARAVAN_ID: return "Wrong road or caravan identity."
	var tick: int=int(world.childhood.tick)
	for key in ["accepted_tick","heard_tick","decision_tick","reply_received_tick","completed_tick"]:
		if not Economy.whole(value[key],0 if key=="accepted_tick" else -1,tick): return "Invalid road event time."
	if not value.choice is String or value.choice not in ["","recognize_claim","seek_confirmation","bypass"]: return "Unknown road decision."
	if not value.visited is Array or value.visited.size()>7: return "Invalid route receipts."
	for waypoint in value.visited:
		if not waypoint is Dictionary or not waypoint.has("tick") or not Economy.whole(waypoint.tick,0,tick): return "Invalid route waypoint shape/time."
	if not world.has("misl"): return "Road assignment without the existing supply ledger."
	var accepts: Array=world.misl.events.filter(func(e): return e.kind=="accept_escort")
	if accepts.size()!=1 or accepts[0].tick!=value.accepted_tick: return "Road assignment is not bound to its caravan acceptance."
	if world.misl.ledger.caravan not in ["active","complete"]: return "Road assignment without an allocated caravan."
	if value.visited.size()<2 and (value.heard_tick>=0 or value.choice!=""): return "Claim/decision before reaching the checkpoint."
	if value.heard_tick>=0:
		if value.heard_tick<value.accepted_tick or value.heard_tick<value.visited[1].get("tick",tick+1): return "Claim heard before arrival."
	if (value.choice!="")!=(value.decision_tick>=0): return "Decision and its time disagree."
	if value.choice!="" and (value.heard_tick<0 or value.decision_tick<value.heard_tick): return "Choice before hearing the claim."
	if value.reply_received_tick>=0:
		if value.choice!="seek_confirmation" or value.reply_received_tick<value.decision_tick+REPLY_DELAY: return "Reply before the inquiry or its delivery delay."
	var points:=route(value)
	if value.visited.size()>points.size(): return "Travel through an unresolved checkpoint."
	var prior: int=int(value.accepted_tick)
	for i in range(value.visited.size()):
		var v: Variant=value.visited[i]
		if not v is Dictionary or v.size()!=3 or not v.has("index") or not v.has("tick") or not v.has("position"): return "Malformed route waypoint receipt."
		if not Economy.whole(v.index,0,6) or v.index!=i or not Economy.whole(v.tick,prior,tick) or not Base.valid_point(v.position): return "Reordered or invalid route waypoint."
		if Base.distance(Base.point(v.position),points[i])>0.95: return "Waypoint receipt is outside its arrival radius."
		if i>=2:
			var release_tick: int=int(value.reply_received_tick if value.choice=="seek_confirmation" else value.decision_tick)
			if release_tick<0 or v.tick<release_tick: return "Caravan passed before permission/route selection."
		prior=int(v.tick)
	if phase(value) in ["hear_claim","choose","await_reply","arrived"]:
		var stop: Vector3=points.back()
		if Base.distance(Base.point(world.misl.merchant.position),stop)>0.95: return "Stopped caravan moved away from its last arrival receipt."
	var completed: bool=world.misl.ledger.caravan=="complete"
	if completed!=(value.completed_tick>=0): return "Road completion and economic check-in disagree."
	if completed:
		if value.choice=="" or value.visited.size()!=points.size() or value.completed_tick<prior: return "Completion before the physical route."
		var checkins: Array=world.misl.events.filter(func(e): return e.kind=="checkin")
		if checkins.size()!=1 or checkins[0].tick!=value.completed_tick: return "Road completion is not its actual supply receipt."
	return ""
