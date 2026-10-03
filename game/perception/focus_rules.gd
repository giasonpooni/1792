# Copyright (c) 2026 Notation Systems Inc. / Notations Gaming.
# All rights reserved.
extends RefCounted
## Transient observations and bounded estimates; never reads a future patrol route.
const RANGE := 18.0
const DWELL_TICKS := 45
const RETAINED_NOTICE_TICKS := 90
const MEMORY_TICKS := 600
const MOTION_INTERVAL := 30
const PREDICTION_TICKS := 120
const MAX_OBSERVED_SPEED := 7.5
const MOTION_CONTRADICTION_DISTANCE := 0.35
const MOTION_DIRECTION_MIN_DISTANCE := 0.005
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

static func supports(prediction: Dictionary, previous: Dictionary, current: Dictionary) -> bool:
	# Retain an estimate only while new consecutive eye samples support it. This
	# compares observed positions; it never reads an actor velocity or route.
	if previous.get("id")!=current.get("id"): return false
	if previous.get("observer_id")!=current.get("observer_id") or previous.get("sensor_id")!=current.get("sensor_id"): return false
	if prediction.get("observer_id")!=current.get("observer_id") or prediction.get("sensor_id")!=current.get("sensor_id"): return false
	var source_ticks: Variant=prediction.get("from_ticks")
	if not source_ticks is Array or source_ticks.size()!=2: return false
	var previous_tick:=int(previous.get("seen_tick",-1))
	var current_tick:=int(current.get("seen_tick",-1))
	var source_tick:=int(source_ticks[1])
	if current_tick!=previous_tick+1 or current_tick<=source_tick or current_tick>=int(prediction.get("expires_tick",-1)): return false
	var projected:=position(prediction)-position({"position":prediction.get("origin_position",[])})
	projected.y=0.0
	if not projected.is_finite() or projected.length()<=0.0: return false
	var observed:=position(current)-position(previous)
	observed.y=0.0
	if observed.length()>=MOTION_DIRECTION_MIN_DISTANCE and observed.normalized().dot(projected.normalized())<=0.0: return false
	var elapsed:=float(current_tick-source_tick)/float(PREDICTION_TICKS)
	var expected:=position({"position":prediction.origin_position})+projected*elapsed
	var error:=position(current)-expected
	error.y=0.0
	return error.length()<=MOTION_CONTRADICTION_DISTANCE

static func estimate_label(prediction: Dictionary) -> String:
	var source_ticks: Variant=prediction.get("from_ticks")
	if not source_ticks is Array or source_ticks.size()!=2: return "estimated"
	var interval:=maxi(0,int(source_ticks[1])-int(source_ticks[0]))
	return "estimated · %.1fs sample" % (float(interval)/60.0)

static func observation_state(age_ticks: int, current: bool) -> String:
	# Report completed time only. A just-lost sample must not be rounded up to
	# one second, and a current eye sample stays distinct from retained memory.
	var age:=maxi(0,age_ticks)
	if current and age==0: return "observed now"
	if age<60: return "last seen <1s ago"
	return "last seen %ds ago" % int(age/60)

static func sound_sector(forward: Vector3, offset: Vector3) -> String:
	var angle := Vector2(forward.x,forward.z).angle_to(Vector2(offset.x,offset.z))
	var index := posmod(int(round(angle/(PI/4.0))),8)
	return ["ahead","ahead-right","right","behind-right","behind","behind-left","left","ahead-left"][index]

static func colour(kind: String) -> Color:
	return {"contact":Color("e0b77e"),"interaction":Color("d4d7cf"),"clue":Color("f1d184"),
		"ally":Color("8fc8e7"),"threat":Color("e69387")}.get(kind,Color.WHITE)

static func symbol(kind: String) -> String:
	return {"contact":"?","interaction":"E","clue":"*","ally":"+","threat":"!"}.get(kind,"?")
