# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Bounded geometry and transient observation rules for the Home hawk scout.
## This is an authored gameplay abstraction, not a historical claim about falconry practice.

const VERSION := "1792.hawk-scout.v1"
const MAX_RADIUS := 52.0
const MIN_ALTITUDE := 5.0
const MAX_ALTITUDE := 24.0
const GLIDE_SPEED := 3.2
const CRUISE_SPEED := 11.0
const FAST_SPEED := 17.0
const CLIMB_SPEED := 7.0
const TAG_RANGE := 42.0
const TAG_FOV_DOT := 0.72
const TAG_TTL_TICKS := 1800 # 30 seconds on the existing 60 Hz chapter clock.

static func bound_position(origin: Vector3, candidate: Vector3) -> Vector3:
	var bounded := candidate
	bounded.y = clampf(candidate.y, origin.y + MIN_ALTITUDE, origin.y + MAX_ALTITUDE)
	var planar := Vector2(candidate.x - origin.x, candidate.z - origin.z)
	if planar.length() > MAX_RADIUS:
		planar = planar.normalized() * MAX_RADIUS
		bounded.x = origin.x + planar.x
		bounded.z = origin.z + planar.y
	return bounded

static func view_score(eye: Vector3, forward: Vector3, target: Vector3) -> float:
	if not eye.is_finite() or not forward.is_finite() or not target.is_finite():
		return -1.0
	if forward.length_squared() < 0.000001:
		return -1.0
	var offset := target - eye
	var distance := offset.length()
	if distance < 0.05 or distance > TAG_RANGE:
		return -1.0
	var facing := forward.normalized().dot(offset / distance)
	if facing < TAG_FOV_DOT:
		return -1.0
	# Prefer the centre of the view, then nearer targets.
	return facing * 2.0 - distance / TAG_RANGE

static func observation(target_id: String, label: String, position: Vector3, tick: int) -> Dictionary:
	return {
		"id": target_id,
		"label": label,
		"position": [position.x, position.y, position.z],
		"seen_tick": tick,
		"expires_tick": tick + TAG_TTL_TICKS
	}

static func observation_position(value: Dictionary) -> Vector3:
	var p: Array = value.position
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

static func valid_observation(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 5:
		return false
	if not value.get("id") is String or String(value.id).is_empty():
		return false
	if not value.get("label") is String:
		return false
	if typeof(value.get("seen_tick")) not in [TYPE_INT, TYPE_FLOAT] or typeof(value.get("expires_tick")) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if int(value.expires_tick) <= int(value.seen_tick):
		return false
	var p: Variant = value.get("position")
	if not p is Array or p.size() != 3:
		return false
	for n in p:
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(n):
			return false
	return true
