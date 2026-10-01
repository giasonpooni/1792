# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Transient attention from current geometry and existing presentation context.
## No perception, knowledge, testimony, relationship or save authority.
const MAX_HEAD_YAW:=0.46
const MAX_HEAD_PITCH:=0.22
const MAX_EYE_YAW:=0.0035 # metres inside the existing 35 mm eye marker
const MAX_EYE_PITCH:=0.0020

static func angles(observer: Transform3D,target: Vector3) -> Vector2:
	var local: Vector3=observer.basis.inverse()*(target-observer.origin)
	if local.length_squared()<0.0001:return Vector2.ZERO
	var horizontal:=sqrt(local.x*local.x+local.z*local.z)
	var yaw:=atan2(-local.x,-local.z)
	var pitch:=atan2(local.y,horizontal) # Positive X rotation raises a -Z-facing head.
	return bounded_angles(Vector2(yaw,pitch))

static func blink(tick: int,identity: int) -> float:
	var cycle:=posmod(tick+identity*83,217+identity*11)
	if cycle>5:return 0.0
	return sin(PI*float(cycle)/5.0)

static func eyes(head_angles: Vector2) -> Vector2:
	return Vector2(clampf(-head_angles.x*.012,-MAX_EYE_YAW+1e-9,MAX_EYE_YAW-1e-9),
		clampf(head_angles.y*.009,-MAX_EYE_PITCH+1e-9,MAX_EYE_PITCH-1e-9))

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

static func eligible(observer: Transform3D,target: Vector3,reach: float=7.0) -> bool:
	# Authoring constraint on a glance, not a new gameplay visibility result.
	var local: Vector3=observer.basis.orthonormalized().inverse()*(target-observer.origin)
	return local.is_finite() and local.length_squared()>.0001 and local.length()<=reach and -local.z/local.length()>.15

static func listening_nod(tick: int,speech: Dictionary,identity: int) -> float:
	if speech.is_empty() or int(speech.get("actor",-1))==identity: return 0.0
	var duration: int=int(speech.get("duration",210))
	var start: int=int(speech.get("until",tick))-duration
	# Mela answers with a quick nod; Jiva waits, then makes a smaller one.
	var delay: int=42 if identity==3 else 78
	var progress: float=float(tick-start-delay)/24.0
	if progress<=0.0 or progress>=1.0: return 0.0
	return -sin(PI*progress)*(.045 if identity==3 else .026)

static func bounded_angles(value: Vector2) -> Vector2:
	# Vector2 uses float32 in this engine: keep the stored result inside the float64 cap.
	return Vector2(clampf(value.x,-MAX_HEAD_YAW+1e-7,MAX_HEAD_YAW-1e-7),clampf(value.y,-MAX_HEAD_PITCH+1e-7,MAX_HEAD_PITCH-1e-7))
