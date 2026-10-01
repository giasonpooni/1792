# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Transient performance interpolation; reads the existing tick, never advances it.
## Not game perception, a saved state, motion control or an autonomous target selector.
const Attention:=preload("res://youth/performance/bazaar_attention.gd")
var head:=Vector2.ZERO
var eye:=Vector2.ZERO
var tick_seen: int=-1

func reset() -> void:
	head=Vector2.ZERO;eye=Vector2.ZERO;tick_seen=-1

func sample(tick: int,desired: Vector2,has_target: bool,identity: int) -> Dictionary:
	if tick_seen<0 or tick<tick_seen:
		reset();tick_seen=tick
	if tick>tick_seen:
		var seconds: float=minf(float(tick-tick_seen)/60.0,.10)
		var aim: Vector2=desired if has_target else Vector2.ZERO
		# No wrap to a new target behind the actor. Selection has already refused it.
		aim=Attention.bounded_angles(aim)
		var speed: float=2.35 if identity==3 else 1.65 if identity==4 else 2.0
		head.x=move_toward(head.x,aim.x,seconds*speed)
		head.y=move_toward(head.y,aim.y,seconds*speed*.75)
		var eye_target: Vector2=Attention.eyes(aim-head) if has_target else Vector2.ZERO
		eye=eye.move_toward(eye_target,seconds*.08)
		tick_seen=tick
	# Same-tick refreshes cannot amplify the turn or keep an invalid target alive.
	if not has_target: eye=Vector2.ZERO
	return {"head":head,"eye":eye,"blink":Attention.blink(tick,identity+1)}

func snapshot() -> Dictionary:
	return {"head":[head.x,head.y],"eye":[eye.x,eye.y],"tick":tick_seen}

func restore(value: Dictionary) -> bool:
	# Used only by retained visual-observation playback; never written into game saves.
	if value.size()!=3 or not value.has("head") or not value.has("eye") or not value.has("tick"): return false
	for key in ["head","eye"]:
		if not value[key] is Array or value[key].size()!=2: return false
		for component in value[key]:
			if not (component is float or component is int) or not is_finite(float(component)): return false
	if not (value.tick is int or value.tick is float) or not is_finite(float(value.tick)) or float(value.tick)!=floor(float(value.tick)): return false
	var h:=Vector2(value.head[0],value.head[1]);var e:=Vector2(value.eye[0],value.eye[1])
	if absf(h.x)>Attention.MAX_HEAD_YAW or absf(h.y)>Attention.MAX_HEAD_PITCH or absf(e.x)>Attention.MAX_EYE_YAW or absf(e.y)>Attention.MAX_EYE_PITCH or value.tick < -1: return false
	head=h;eye=e;tick_seen=int(value.tick);return true
