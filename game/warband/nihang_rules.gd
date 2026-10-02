# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored childhood camp. This finite contract is neither an army nor a historical claim.
const Names := preload("res://characters/character_names.gd")
const Ride := preload("res://mounts/riding_rules.gd")
const SCHEMA := "nihang-companionship.v1"
const ELDER := "fictional_nihang_elder"
const RIDERS := ["fictional_nihang_veteran", "fictional_nihang_companion"]
const CAMP := Vector3(19, 0.14, -18)
const HORSE_LINES := [Vector3(23, 0.14, -18), Vector3(18, 0.14, -22)]
const TURN := Vector3(3, 0.14, -25)
const MAX_EVENTS := 12
const SPEED := 6.0
const WORDS := {
	"meet": "Buddh, your father knows these riders. Come to the horse lines; we will begin with the animal that carries you.",
	"care": "Little rider, look at the bridle, the girth and the horse's footing before you ask for speed. Bring the horse home with the same care.",
	"invite_one": "Buddh, one of us will ride with you to the north practice marker and back. This is our undertaking together; keep within calling distance.",
	"invite_two": "Buddh, both riders will accompany you to the north practice marker and back. Wait for one another. We return together.",
	"turn": "Little rider, we have reached the marker together. Turn for the camp and bring everyone back.",
	"return": "Buddh, everyone is home. You kept the undertaking. Sit with us when the horses have rested.",
	"cancel": "Buddh, we are all back at the camp. We can leave the practice ride unfinished today."
}

static func initial() -> Dictionary:
	var mounts: Array = []
	for i in range(2):
		var p: Vector3 = HORSE_LINES[i]
		mounts.append({"id": RIDERS[i], "position": [p.x,p.y,p.z], "yaw": 0.0,
			"speed": 0.0, "vertical_speed": 0.0, "grounded": true})
	return {"schema_version": SCHEMA, "phase": "unmet", "selected": [],
		"events": [], "mounts": mounts, "motion_tick": -1}

static func active(phase: String) -> bool:
	return phase in ["outbound", "returning"]

static func point(value: Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])

static func fields(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size()!=keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func whole(value: Variant, minimum: int = 0) -> bool:
	return Ride.finite_number(value) and value>=minimum and value<=10000000 and value==floor(value)

static func valid_point(value: Variant) -> bool:
	return Ride.valid_position(value) and absf(value[0])<=28.5 and absf(value[2])<=28.5 and value[1]>=0.0 and value[1]<=4.0

static func valid_mount(value: Variant, index: int) -> bool:
	if not fields(value,["id","position","yaw","speed","vertical_speed","grounded"]): return false
	if value.id!=RIDERS[index] or not valid_point(value.position) or not value.grounded is bool: return false
	for key in ["yaw","speed","vertical_speed"]:
		if not Ride.finite_number(value[key]): return false
	return absf(value.yaw)<=PI and value.speed>=0 and value.speed<=SPEED+.001 and value.vertical_speed>=-50 and value.vertical_speed<=0 and (not value.grounded or value.vertical_speed==0)

static func together(selected: Array, mounts: Array, center: Vector3, radius: float) -> bool:
	for id in selected:
		var m: Dictionary=mounts[RIDERS.find(id)]
		if not m.grounded or point(m.position).distance_to(center)>radius: return false
	return true

static func apply(state: Dictionary, event: Dictionary) -> String:
	var kind: String=event.kind
	var p:=point(event.position)
	if kind not in WORDS: return "Unknown camp undertaking."
	if not event.contact or not event.grounded: return "Speak from nearby, clear standing ground."
	if kind=="care":
		if p.distance_to(HORSE_LINES[0])>3.0 or event.mounted: return "Inspect the veteran's horse on foot at the horse lines."
	elif kind=="turn":
		if p.distance_to(TURN)>3.0 or not event.mounted: return "Reach the north practice marker on horseback."
	elif p.distance_to(CAMP)>3.0 or event.mounted:
		return "Dismount beside the camp elder."
	match kind:
		"meet":
			if state.phase!="unmet": return "You have already met these riders."
			state.phase="acquainted"
		"care":
			if state.phase!="acquainted": return "Meet the camp elder before the horse lesson."
			state.phase="prepared"
		"invite_one", "invite_two":
			if state.phase!="prepared": return "Finish the horse-care conversation before arranging this ride."
			if event.ride_gate<1: return "Complete the first household riding gate before inviting an escort."
			state.selected=[RIDERS[0]] if kind=="invite_one" else RIDERS.duplicate()
			state.phase="outbound"
		"turn":
			if state.phase!="outbound": return "There is no outward camp ride to complete."
			if not together(state.selected,event.mounts,p,7.0): return "Wait at the marker for every invited rider."
			state.phase="returning"
		"return", "cancel":
			if state.phase!="returning" and (kind!="cancel" or state.phase!="outbound"): return "There is no matching camp undertaking to settle."
			if not together(state.selected,event.mounts,CAMP,7.0): return "Bring every invited rider back to the camp."
			for id in state.selected:
				if event.mounts[RIDERS.find(id)].speed>0.15: return "Wait for the escort's horses to stop."
			state.phase="complete" if kind=="return" else "cancelled"
	return ""

static func validate(value: Variant, home_tick: int) -> String:
	if not fields(value,initial().keys()) or value.schema_version!=SCHEMA: return "Malformed camp profile."
	if not value.phase is String or not value.selected is Array or not value.events is Array or not value.mounts is Array or value.mounts.size()!=2 or not whole(value.motion_tick,-1): return "Malformed camp state."
	if value.events.size()>MAX_EVENTS or value.motion_tick>home_tick: return "Camp history or motion exceeds the Home clock."
	for i in range(2):
		if not valid_mount(value.mounts[i],i): return "Invalid camp rider pose or identity."
	var replay:=initial()
	var last:=-1
	for e in value.events:
		if not fields(e,["kind","tick","position","mounted","grounded","contact","ride_gate","mounts"]) or not e.kind is String or not whole(e.tick) or e.tick<last or e.tick>home_tick or not valid_point(e.position): return "Invalid camp event identity, time or position."
		if not e.mounted is bool or not e.grounded is bool or not e.contact is bool or not whole(e.ride_gate) or e.ride_gate>3 or not e.mounts is Array or e.mounts.size()!=2: return "Malformed camp observation."
		for i in range(2):
			if not valid_mount(e.mounts[i],i): return "Invalid camp event rider observation."
		var error:=apply(replay,e)
		if not error.is_empty(): return error
		last=int(e.tick)
	if value.phase!=replay.phase or value.selected!=replay.selected: return "Camp agreement differs from its received events."
	if value.selected.is_empty():
		if value.mounts!=initial().mounts or value.motion_tick!=-1: return "Uninvited riders cannot acquire travel state."
	else:
		if value.motion_tick>=0 and value.motion_tick<value.events[2].tick: return "Riders moved before their invitation."
		for i in range(2):
			if RIDERS[i] not in value.selected and value.mounts[i]!=initial().mounts[i]: return "An unselected rider left the camp."
	if value.phase in ["complete","cancelled"]:
		if not together(value.selected,value.mounts,CAMP,7.0): return "Settled companions are missing from camp."
		if value.mounts!=value.events[-1].mounts: return "Settled rider poses differ from check-in."
	return ""
