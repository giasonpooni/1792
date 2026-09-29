# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Analytic, fixed-length two-bone positioning. All coordinates share one frame.
## Refuse unreachable targets; never lengthen limbs, move a body or claim a grip.
static func solve(root: Vector3,target: Vector3,pole: Vector3,upper: float,lower: float) -> Dictionary:
	var refused: Dictionary={"reachable":false}
	if not root.is_finite() or not target.is_finite() or not pole.is_finite(): return refused
	if not is_finite(upper) or not is_finite(lower) or upper<=0 or lower<=0: return refused
	var line:=target-root;var distance:=line.length()
	if distance<0.00001 or distance<absf(upper-lower)+0.00001 or distance>upper+lower-0.00001: return refused
	var direction:=line/distance
	var bend:=pole-root; bend-=direction*bend.dot(direction)
	if bend.length_squared()<0.000001:
		bend=direction.cross(Vector3.UP if absf(direction.y)<0.9 else Vector3.RIGHT)
	bend=bend.normalized()
	var along: float=(upper*upper-lower*lower+distance*distance)/(2.0*distance)
	var perpendicular:=sqrt(maxf(0,upper*upper-along*along))
	var elbow:=root+direction*along+bend*perpendicular
	return {"reachable":true,"elbow":elbow,"end":target}
