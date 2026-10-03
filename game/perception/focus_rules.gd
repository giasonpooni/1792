# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Transient observations and bounded estimates; never reads a future patrol route.
const RANGE := 18.0
const DWELL_TICKS := 45
const MEMORY_TICKS := 600
const MOTION_INTERVAL := 30
const PREDICTION_TICKS := 120
const MAX_OBSERVED_SPEED := 7.5
const SOUND_TICKS := 120
const KINDS := ["contact", "interaction", "clue", "ally", "threat"]

static func observation(id: String, label: String, kind: String, observer: String, at: Vector3, tick: int) -> Dictionary:
	return {"id":id,"label":label,"kind":kind,"observer_id":observer,"sensor_id":"character-eye",
		"position":[at.x,at.y,at.z],"seen_tick":tick,"expires_tick":tick+MEMORY_TICKS}

static func position(record: Dictionary) -> Vector3:
	var p: Array=record.position
	return Vector3(float(p[0]),float(p[1]),float(p[2]))

static func estimate(previous: Dictionary, current: Dictionary) -> Dictionary:
	if previous.id != current.id or previous.observer_id != current.observer_id: return {}
	if String(previous.get("sensor_id",""))!=String(current.get("sensor_id","")) or String(current.get("sensor_id","")).is_empty(): return {}
	var ticks: int=int(current.seen_tick)-int(previous.seen_tick)
	if ticks<MOTION_INTERVAL or ticks>MOTION_INTERVAL*2: return {}
	var velocity := (position(current)-position(previous))*60.0/float(ticks)
	velocity.y=0.0
	if not velocity.is_finite() or velocity.length()<0.15 or velocity.length()>MAX_OBSERVED_SPEED: return {}
	var end := position(current)+velocity*float(PREDICTION_TICKS)/60.0
	return {"position":[end.x,end.y,end.z],"origin_position":current.position.duplicate(),"from_ticks":[int(previous.seen_tick),int(current.seen_tick)],
		"expires_tick":int(current.seen_tick)+PREDICTION_TICKS,"kind":"estimate",
		"observer_id":current.observer_id,"sensor_id":current.sensor_id}

static func sound_sector(forward: Vector3, offset: Vector3) -> String:
	var angle := Vector2(forward.x,forward.z).angle_to(Vector2(offset.x,offset.z))
	var index := posmod(int(round(angle/(PI/4.0))),8)
	return ["ahead","ahead-right","right","behind-right","behind","behind-left","left","ahead-left"][index]

static func colour(kind: String) -> Color:
	return {"contact":Color("e0b77e"),"interaction":Color("d4d7cf"),"clue":Color("f1d184"),
		"ally":Color("8fc8e7"),"threat":Color("e69387")}.get(kind,Color.WHITE)

static func symbol(kind: String) -> String:
	return {"contact":"?","interaction":"E","clue":"*","ally":"+","threat":"!"}.get(kind,"?")
