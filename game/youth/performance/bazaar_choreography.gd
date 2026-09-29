# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored presentation curves over existing combat events. Never authors a hit, guard or movement receipt.
const CONTACT_WINDOW := 20
const FRIEND_REACTION_WINDOW := 34
static func smooth(value: float) -> float:
	var x:=clampf(value,0.0,1.0);return x*x*(3.0-2.0*x)
static func opponent(action: String,amount: float) -> Dictionary:
	var a:=smooth(amount)
	match action:
		"windup":
			return {"offset":Vector3(-.035*a,0,.105*a),"torso":Vector3(.055*a,-.40*a,-.04*a),
				"hip_l":.34*a,"hip_r":-.22*a,"knee_l":.20*a,"knee_r":.40*a,
				"head":Vector3(.02*a,.12*a,-.025*a)}
		"strike":
			return {"offset":Vector3(.025*a,0,-.19*a),"torso":Vector3(.15,.42*a,-.05),
				"hip_l":-.44*a,"hip_r":.31*a,"knee_l":.54*a,"knee_r":.08*a,
				"head":Vector3(-.025,.08*a,.03)}
		"checked":
			return {"offset":Vector3(0,0,.085),"torso":Vector3(-.15,-.25,.065),
				"hip_l":-.19,"hip_r":.23,"knee_l":.12,"knee_r":.30,"head":Vector3(.06,.20,.08)}
		"recover":
			var r:=1.0-a
			return {"offset":Vector3(0,0,-.065*r),"torso":Vector3(.03,.25*r,0),
				"hip_l":-.18*r,"hip_r":.12*r,"knee_l":.18*r,"knee_r":.10*r,"head":Vector3.ZERO}
	return {}
static func recent_event(events: Array,tick: int,kinds: Array[String]) -> Dictionary:
	for i in range(events.size()-1,-1,-1):
		var event: Dictionary=events[i];var elapsed:=tick-int(event.tick)
		if elapsed<0: continue
		if elapsed>FRIEND_REACTION_WINDOW: break
		if String(event.kind) in kinds: return {"kind":String(event.kind),"elapsed":elapsed,"index":int(event.get("index",-1))}
	return {}
static func friend_pose(events: Array,tick: int,friend_index: int) -> Dictionary:
	var event:=recent_event(events,tick,["parry","hit","counter"])
	if event.is_empty(): return {}
	var p:=float(event.elapsed)/FRIEND_REACTION_WINDOW
	var pulse:=sin(PI*clampf(p,0,1))
	if event.kind=="hit":
		return {"action":"brace","amount":pulse,"look":-1.0 if friend_index==3 else 1.0}
	if event.kind=="counter":
		return {"action":"urge","amount":pulse,"look":1.0 if friend_index==3 else -.6}
	return {"action":"watch","amount":pulse,"look":.65 if friend_index==3 else -.65}
static func contact_pose(events: Array,tick: int) -> Dictionary:
	var event:=recent_event(events,tick,["parry","counter","hit"])
	if event.is_empty() or int(event.elapsed)>CONTACT_WINDOW:return {}
	var p:=float(event.elapsed)/CONTACT_WINDOW
	return {"kind":event.kind,"amount":sin(PI*clampf(p,0,1)),"index":event.index}
