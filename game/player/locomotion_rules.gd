# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Pure shared motor math. Units are local metres, seconds and radians.
const VERSION := "locomotion.v1"
const JUMP_SPEED := 7.5
const AIR_ACCELERATION := 6.0
const COYOTE_SECONDS := 0.10
const BUFFER_SECONDS := 0.12
const MAX_FALL := 50.0

static func finite(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))

static func vector(value: Variant,limit: float) -> bool:
	if not value is Array or value.size()!=3: return false
	for number in value:
		if not finite(number) or absf(number)>limit: return false
	return true

static func array(p: Vector3) -> Array: return [p.x,p.y,p.z]
static func point(p: Array) -> Vector3: return Vector3(p[0],p[1],p[2])

static func direction(stick: Vector2,yaw: float) -> Vector3:
	# Preserve analog strength. Build the horizontal basis from yaw, not pitch.
	return Basis(Vector3.UP,yaw)*Vector3(stick.x,0,stick.y).limit_length(1.0)

static func horizontal(current: Vector3,target: Vector3,rate: float,dt: float) -> Vector3:
	return Vector3(current.x,0,current.z).move_toward(target,rate*dt)

static func validate_snapshot(s: Variant) -> String:
	if not s is Dictionary or s.size() not in [7,8]: return "Malformed motion snapshot."
	for key in ["schema","position","velocity","grounded","coyote","buffer","camera"]:
		if not s.has(key): return "Missing motion field."
	if s.size()==8 and (not s.has("traversal") or not s.traversal is Dictionary): return "Unknown motion extension."
	if s.schema!=VERSION or not vector(s.position,100) or not vector(s.velocity,MAX_FALL) or not vector(s.camera,100): return "Unknown or non-finite motion."
	if not s.grounded is bool or not finite(s.coyote) or not finite(s.buffer): return "Invalid motion timers."
	if s.coyote<0 or s.coyote>COYOTE_SECONDS or s.buffer<0 or s.buffer>BUFFER_SECONDS: return "Motion timer outside profile."
	if Vector2(s.velocity[0],s.velocity[2]).length()>7.5001 or s.velocity[1]>JUMP_SPEED: return "Velocity exceeds the course profile."
	if s.grounded and absf(s.velocity[1])>0.0001: return "Grounded motion has vertical velocity."
	if s.camera[0]<-0.9 or s.camera[0]>0.5 or absf(s.camera[1])>PI or s.camera[2]!=0: return "Invalid camera pose."
	return ""
