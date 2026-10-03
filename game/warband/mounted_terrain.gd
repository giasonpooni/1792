# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Local collision/support observations, not a terrain map or a second motor.
const SAMPLE := .3
const DROP := .30

static func ground(mount: CharacterBody3D, at: Vector3, excluded: Array[RID]) -> Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.55,at-Vector3.UP*.65,1,excluded)
	var hit:=mount.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and (hit.collider is CharacterBody3D or hit.collider is RigidBody3D): return {}
	return hit

static func inspect(mount: CharacterBody3D, direction: Vector3, reach: float,
		excluded: Array[RID]=[], collision_mask: int=0) -> Dictionary:
	var ignored: Array[RID]=excluded.duplicate();ignored.append(mount.get_rid())
	var start:=ground(mount,mount.global_position,ignored)
	if start.is_empty() or start.normal.y<cos(mount.floor_max_angle):
		return {"distance":0.0,"reason":"unsupported","rise":0.0}
	var previous: Vector3=start.position
	var normal: Vector3=start.normal
	var right:=direction.cross(Vector3.UP)
	var travelled:=0.0
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=mount.get_node("Hull").shape
	query.collision_mask=mount.collision_mask if collision_mask==0 else collision_mask
	query.exclude=ignored
	var space:=mount.get_world_3d().direct_space_state
	while travelled<reach-.001:
		var step:=minf(SAMPLE,reach-travelled)
		var ahead:=previous+direction*step
		var hit:=ground(mount,ahead,ignored)
		if hit.is_empty(): return {"distance":travelled,"reason":"edge","rise":previous.y-start.position.y}
		var change: float=hit.position.y-previous.y
		if hit.normal.y<cos(mount.floor_max_angle) or change>step*tan(mount.floor_max_angle)+.06 or change< -DROP:
			return {"distance":travelled,"reason":"steep","rise":previous.y-start.position.y}
		# Sample the footprint, so a supported centre alone cannot bridge a void.
		for side in [-.6,.6]:
			var support:=ground(mount,hit.position+right*side,ignored)
			if support.is_empty() or support.normal.y<cos(mount.floor_max_angle) or absf(support.position.y-hit.position.y)>.6*tan(mount.floor_max_angle)+.06:
				return {"distance":travelled,"reason":"edge","rise":previous.y-start.position.y}
		# Upright capsules sit above the centre ray on slopes. This lifts only the
		# query by the support geometry; the actual body still moves via its motor.
		var lift0: float=.8*(1.0/normal.y-1.0)+.08
		var lift1: float=.8*(1.0/hit.normal.y-1.0)+.08
		query.transform=Transform3D(Basis.IDENTITY,previous+Vector3.UP*(1.6+lift0))
		query.motion=hit.position-previous+Vector3.UP*(lift1-lift0)
		# Across a small flat ledge the rear of the hull still rests on the upper
		# tread. Sweep forward at that height; native snap/gravity performs the drop.
		# Sweeping diagonally down would mistake the tread itself for a wall.
		if change< -.06 and normal.y>.99 and hit.normal.y>.99: query.motion.y=0.0
		var sweep:=space.cast_motion(query)
		if sweep.size()!=2 or sweep[0]<.999:
			return {"distance":travelled+step*(sweep[0] if sweep.size()==2 else 0.0),"reason":"obstacle","rise":previous.y-start.position.y}
		travelled+=step;previous=hit.position;normal=hit.normal
	return {"distance":reach,"reason":"clear","rise":previous.y-start.position.y}

static func path_clear(mount: CharacterBody3D, goal: Vector3, excluded: Array[RID]) -> bool:
	var offset:=Vector3(goal.x-mount.position.x,0,goal.z-mount.position.z)
	if offset.length()<.05: return true
	# Local steering is deliberately bounded; longer routes retain the navigator.
	if offset.length()>12: return false
	return inspect(mount,offset.normalized(),offset.length(),excluded,1).reason=="clear"
