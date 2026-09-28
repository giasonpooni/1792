# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Conservative static-surface vault/mantle admission. No transform writes here.
const HEIGHT_MIN := 0.35
const HEIGHT_MAX := 1.45
const REACH := 1.15
const CLEARANCE := 0.06

static func ray(actor: CharacterBody3D,a: Vector3,b: Vector3) -> Dictionary:
	var q:=PhysicsRayQueryParameters3D.create(a,b,actor.collision_mask,[actor.get_rid()])
	return actor.get_world_3d().direct_space_state.intersect_ray(q)

static func clear_at(actor: CharacterBody3D,feet: Vector3) -> bool:
	var q:=PhysicsShapeQueryParameters3D.new()
	q.shape=actor.get_node("CollisionShape3D").shape
	q.transform=actor.global_transform
	q.transform.origin=feet+Vector3.UP*0.8
	q.exclude=[actor.get_rid()];q.collision_mask=actor.collision_mask
	return actor.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

static func support(actor: CharacterBody3D,feet: Vector3) -> bool:
	var hit:=ray(actor,feet+Vector3.UP*0.08,feet-Vector3.UP*0.15)
	return not hit.is_empty() and hit.normal.y>=cos(actor.floor_max_angle)

static func plan(actor: CharacterBody3D,forward: Vector3) -> Dictionary:
	var refusal: Dictionary={"error":"Face a marked low obstacle with clear approach and landing space."}
	if forward.length()<0.99: return refusal
	var p:=actor.global_position
	var front:=ray(actor,p+Vector3.UP*0.4,p+Vector3.UP*0.4+forward*REACH)
	if front.is_empty() or not front.collider is StaticBody3D or not front.collider.get_meta("traversable",false): return refusal
	# Do not infer handholds from art, slanted sides or unmarked walls.
	if front.normal.dot(-forward)<0.90: return refusal
	var sample: Vector3=front.position+forward*0.10
	var top:=ray(actor,Vector3(sample.x,p.y+HEIGHT_MAX+0.2,sample.z),Vector3(sample.x,p.y+0.05,sample.z))
	if top.is_empty() or top.collider!=front.collider or top.normal.y<0.98: return refusal
	var height: float=top.position.y-p.y
	if height<HEIGHT_MIN or height>HEIGHT_MAX: return refusal
	var kind: String="mantle"
	var destination: Vector3=top.position+forward*0.48+Vector3.UP*CLEARANCE
	# A thin low rail may be vaulted only when its far edge and landing exist.
	if height<=0.8:
		for i in range(1,10):
			var beyond: Vector3=front.position+forward*(0.1*i)
			var check:=ray(actor,Vector3(beyond.x,top.position.y+0.15,beyond.z),Vector3(beyond.x,p.y+0.1,beyond.z))
			if check.is_empty() or check.collider!=front.collider:
				var far: Vector3=beyond+forward*0.60
				var ground:=ray(actor,Vector3(far.x,p.y+0.2,far.z),Vector3(far.x,p.y-0.3,far.z))
				if ground.is_empty() or ground.normal.y<0.98: return refusal
				kind="vault";destination=ground.position+Vector3.UP*CLEARANCE;break
		if kind!="vault": return refusal
	if not clear_at(actor,destination) or not support(actor,destination): return refusal
	# Conservative rectangular lift/cross/lower. Every segment sweeps the real hull.
	var high: float=top.position.y+CLEARANCE
	var points: Array[Vector3]=[Vector3(p.x,high,p.z),Vector3(destination.x,high,destination.z),destination]
	var prior:=p
	for target in points:
		var t:=actor.global_transform;t.origin=prior
		if not clear_at(actor,target) or actor.test_move(t,target-prior): return {"error":"The body path or overhead clearance is blocked."}
		prior=target
	return {"error":"","kind":kind,"points":points,"surface":front.collider,"surface_transform":front.collider.global_transform,"contact":top.position}
