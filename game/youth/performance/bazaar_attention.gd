# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Transient attention from current geometry and existing presentation context.
## No perception, knowledge, testimony, relationship or save authority.
# Vector components use the same precision as the returned Vector2, including at limits.
const HEAD_LIMIT := Vector2(.46,.22)
const EYE_LIMIT := Vector2(.006,.003)
const MAX_HEAD_YAW := HEAD_LIMIT.x
const MAX_HEAD_PITCH := HEAD_LIMIT.y
const MAX_EYE_YAW := EYE_LIMIT.x
const MAX_EYE_PITCH := EYE_LIMIT.y

static func angles(observer: Transform3D,target: Vector3) -> Vector2:
	var local: Vector3=observer.basis.inverse()*(target-observer.origin)
	if local.length_squared()<0.0001 or local.z>=-.01:return Vector2.ZERO
	var horizontal:=sqrt(local.x*local.x+local.z*local.z)
	var yaw:=atan2(-local.x,-local.z)
	var pitch:=atan2(local.y,horizontal)
	return Vector2(clampf(yaw,-MAX_HEAD_YAW,MAX_HEAD_YAW),clampf(pitch,-MAX_HEAD_PITCH,MAX_HEAD_PITCH))

static func blink(tick: int,identity: int) -> float:
	var cycle:=posmod(tick+identity*83,217+identity*11)
	if cycle>5:return 0.0
	return sin(PI*float(cycle)/5.0)

static func eyes(head_angles: Vector2) -> Vector2:
	return Vector2(clampf(-head_angles.x*.012,-MAX_EYE_YAW,MAX_EYE_YAW),
		clampf(head_angles.y*.010,-MAX_EYE_PITCH,MAX_EYE_PITCH))

static func hero_target(phase: String,speech: Dictionary,youths: Array,brawl: Dictionary,avatar_position: Vector3) -> Variant:
	if not speech.is_empty():
		var actor:=int(speech.get("actor",-1))
		if actor>=0 and actor<youths.size():return youths[actor].global_position+Vector3.UP*1.35
	if phase in ["challenged","fighting"] and not brawl.is_empty():
		var best:=-1;var distance:=INF
		for i in range(3):
			if brawl.ledger.down[i]:continue
			var d:=avatar_position.distance_squared_to(youths[i].global_position)
			if d<distance:distance=d;best=i
		if best>=0:return youths[best].global_position+Vector3.UP*1.35
	if phase=="returning" and youths.size()>=5:
		return (youths[3].global_position+youths[4].global_position)*.5+Vector3.UP*1.3
	return null

static func figure_target(index: int,phase: String,speech: Dictionary,youths: Array,avatar_position: Vector3,brawl: Dictionary) -> Variant:
	if index<0 or index>=youths.size():return null
	if not speech.is_empty():
		var speaker:=int(speech.get("actor",-1))
		if speaker==index:return avatar_position+Vector3.UP*1.35
		if speaker>=0 and speaker<youths.size():return youths[speaker].global_position+Vector3.UP*1.35
	if index<3:
		if phase in ["challenged","fighting"]:return avatar_position+Vector3.UP*1.35
		if phase=="returning" and not brawl.is_empty() and brawl.ledger.down[index]:return youths[3].global_position+Vector3.UP*1.3
	else:
		if phase=="challenged":return youths[0].global_position+Vector3.UP*1.35
		if phase=="fighting":
			var active:=0
			for i in range(3):
				if not brawl.ledger.down[i]:active=i;break
			return youths[active].global_position+Vector3.UP*1.35
		if phase in ["invited","leaving","returning"]:return avatar_position+Vector3.UP*1.35
	return null
