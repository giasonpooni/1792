# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Opt-in static stairs on the shared CharacterBody. All probes use its real hull.
const VERSION := "ground_contact.v1"
const MAX_STEP := 0.30
const SUPPORT_REACH := 0.04
const EPSILON := 0.0001
const CONTINUATION_SECONDS := 1.0

static func profile_error(actor: CharacterBody3D,height: float) -> String:
	if not actor.get_collision_exceptions().is_empty(): return "The qualified ground profile has no collision exceptions."
	if not is_finite(height) or height<0 or height>MAX_STEP: return "Invalid static-step height."
	if not is_finite(actor.floor_snap_length) or actor.floor_snap_length<0 or actor.floor_snap_length>MAX_STEP+EPSILON: return "Invalid ground snap distance."
	if not is_finite(actor.floor_max_angle) or actor.floor_max_angle<=0 or actor.floor_max_angle>=PI*0.5: return "Invalid walkable slope angle."
	if not is_finite(actor.safe_margin) or actor.safe_margin<0 or actor.safe_margin>0.01: return "Invalid ground collision margin."
	if not actor.up_direction.is_finite() or absf(actor.up_direction.length()-1)>EPSILON: return "Invalid ground up direction."
	if actor.up_direction.distance_to(Vector3.UP)>EPSILON: return "The shared ground motor requires Y-up."
	if not actor.global_transform.is_finite() or capsule(actor)==null: return "Invalid ground capsule transform."
	var node:=capsule(actor)
	if not node.transform.is_finite(): return "Invalid ground capsule transform."
	var shape: CapsuleShape3D=node.shape
	if not is_finite(shape.radius) or not is_finite(shape.height) or shape.radius<=0 or shape.height<shape.radius*2: return "Invalid ground capsule dimensions."
	if not is_finite(shape.margin) or shape.margin<0 or not is_finite(shape.custom_solver_bias) or shape.custom_solver_bias<0: return "Invalid ground capsule contact parameters."
	return ""

static func capsule(actor: CharacterBody3D) -> CollisionShape3D:
	var node: CollisionShape3D=actor.get_node_or_null("CollisionShape3D")
	if node==null or node.disabled or not node.shape is CapsuleShape3D: return null
	var owners:=actor.get_shape_owners()
	if owners.size()!=1: return null
	var owner: int=owners[0]
	if actor.shape_owner_get_owner(owner)!=node or actor.is_shape_owner_disabled(owner): return null
	if actor.shape_owner_get_shape_count(owner)!=1 or actor.shape_owner_get_shape(owner,0)!=node.shape: return null
	if actor.shape_owner_get_transform(owner)!=node.transform: return null
	for child in actor.get_children():
		if child is CollisionShape3D and child!=node and not child.disabled and child.shape!=null: return null
		if child is CollisionPolygon3D and not child.disabled: return null
	# Nonuniformly scaled physics shapes have engine-dependent geometry. Refuse them.
	var basis: Basis=(actor.global_transform*node.transform).basis
	if not basis.is_conformal() or basis.y.length()<EPSILON: return null
	return node

static func excluded(actor: CharacterBody3D) -> Array[RID]:
	var result: Array[RID]=[actor.get_rid()]
	for body in actor.get_collision_exceptions(): result.append(body.get_rid())
	return result

static func surface_geometry(body: StaticBody3D) -> Array:
	var result: Array=[]
	for owner in body.get_shape_owners():
		var shapes: Array=[]
		for index in range(body.shape_owner_get_shape_count(owner)):
			var shape: Shape3D=body.shape_owner_get_shape(owner,index)
			var properties: Dictionary={}
			for field in shape.get_property_list():
				if not field.usage & PROPERTY_USAGE_STORAGE or field.type==TYPE_OBJECT or str(field.name).begins_with("resource_"): continue
				var value: Variant=shape.get(field.name)
				if value is Array or value is Dictionary: value=value.duplicate(true)
				elif typeof(value)>=TYPE_PACKED_BYTE_ARRAY: value=value.duplicate()
				properties[field.name]=value
			shapes.append({"rid":shape.get_rid(),"class":shape.get_class(),"properties":properties})
		result.append({"owner":owner,"transform":body.shape_owner_get_transform(owner),"disabled":body.is_shape_owner_disabled(owner),"shapes":shapes})
	return result

static func surface_unchanged(receipt: Dictionary) -> bool:
	return is_instance_valid(receipt.body) and receipt.body.global_transform==receipt.transform and surface_geometry(receipt.body)==receipt.geometry

static func hull_identity(actor: CharacterBody3D,height: float) -> Dictionary:
	var node:=capsule(actor)
	if node==null: return {}
	return {"shape":node.shape.get_rid(),"transform":node.transform,"radius":node.shape.radius,"height":node.shape.height,
		"margin":node.shape.margin,"custom_solver_bias":node.shape.custom_solver_bias,"safe_margin":actor.safe_margin,"up":actor.up_direction,"mask":actor.collision_mask,
		"exceptions":excluded(actor),"step_height":height,"floor_max_angle":actor.floor_max_angle,"floor_snap_length":actor.floor_snap_length}

static func clear_at(actor: CharacterBody3D,body_transform: Transform3D) -> bool:
	var node:=capsule(actor)
	if node==null: return false
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=node.shape;query.transform=body_transform*node.transform
	query.collision_mask=actor.collision_mask;query.exclude=excluded(actor)
	query.margin=0.0
	return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

static func sole_projection(actor: CharacterBody3D,up: Vector3) -> float:
	var node:=capsule(actor)
	if node==null: return INF
	var shape: CapsuleShape3D=node.shape
	var transform: Transform3D=actor.global_transform*node.transform
	var scale: float=transform.basis.y.length()
	var segment: float=maxf(shape.height*0.5-shape.radius,0.0)*scale
	return transform.origin.dot(up)-absf(transform.basis.y.normalized().dot(up))*segment-shape.radius*scale

static func contact_gap(actor: CharacterBody3D,body_transform: Transform3D,point: Vector3) -> float:
	var node:=capsule(actor)
	if node==null: return INF
	var shape: CapsuleShape3D=node.shape
	var transform: Transform3D=body_transform*node.transform
	var axis: Vector3=transform.basis.y
	var half_segment: float=maxf(shape.height*0.5-shape.radius,0.0)
	var a: Vector3=transform.origin-axis*half_segment
	var b: Vector3=transform.origin+axis*half_segment
	var segment:=b-a
	var along: float=clampf((point-a).dot(segment)/segment.length_squared(),0.0,1.0) if segment.length_squared()>EPSILON*EPSILON else 0.0
	return point.distance_to(a+segment*along)-shape.radius*axis.length()

static func still_static(hit: KinematicCollision3D) -> bool:
	for index in range(hit.get_collision_count()):
		var body: Object=hit.get_collider(index)
		if not body is StaticBody3D or body is AnimatableBody3D: return false
		if body.constant_linear_velocity.length_squared()>0 or body.constant_angular_velocity.length_squared()>0: return false
		if hit.get_collider_velocity(index).length_squared()>EPSILON*EPSILON: return false
	return hit.get_collision_count()>0

static func support(actor: CharacterBody3D,body_transform: Transform3D,reach: float=SUPPORT_REACH) -> KinematicCollision3D:
	return cast_support(actor,body_transform,reach,true)

static func cast_support(actor: CharacterBody3D,body_transform: Transform3D,reach: float,require_floor: bool) -> KinematicCollision3D:
	if capsule(actor)==null or actor.up_direction.length_squared()<0.99: return null
	var up:=actor.up_direction.normalized()
	var hit:=KinematicCollision3D.new()
	if not actor.test_move(body_transform,-up*reach,hit,actor.safe_margin,false,8): return null
	if not still_static(hit): return null
	for index in range(hit.get_collision_count()):
		if hit.get_normal(index).dot(up)<(cos(actor.floor_max_angle) if require_floor else EPSILON): return null
	return hit

static func has_support(actor: CharacterBody3D,body_transform: Transform3D) -> bool:
	var contact:=support(actor,body_transform,0.004)
	if contact!=null:
		var within_margin:=true
		for index in range(contact.get_collision_count()):
			within_margin=within_margin and contact_gap(actor,body_transform,contact.get_position(index))<=actor.safe_margin+EPSILON
		if within_margin: return true
	# At a stair toe the sweep can meet a steep corner before the real floor.
	# A shallow overlap of the same complete hull asks the physics server for its
	# deepest support instead; no smaller stand-in collider or centre ray is used.
	var node:=capsule(actor)
	if node==null: return false
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=node.shape;query.transform=body_transform*node.transform
	query.transform.origin-=actor.up_direction*0.004
	query.collision_mask=actor.collision_mask;query.exclude=excluded(actor)
	query.margin=0.0
	var hit:=actor.get_world_3d().direct_space_state.get_rest_info(query)
	if hit.is_empty() or hit.normal.dot(actor.up_direction)<cos(actor.floor_max_angle): return false
	if contact_gap(actor,body_transform,hit.point)>actor.safe_margin+EPSILON: return false
	var body: Object=instance_from_id(hit.collider_id)
	return body is StaticBody3D and not body is AnimatableBody3D and body.constant_linear_velocity==Vector3.ZERO and body.constant_angular_velocity==Vector3.ZERO and hit.linear_velocity.length_squared()<=EPSILON*EPSILON

static func plan(actor: CharacterBody3D,movement: Vector3,height: float,continuation: Dictionary={},grounded_observation: bool=false) -> Dictionary:
	var refusal: Dictionary={}
	if not is_finite(height) or height<=0 or height>MAX_STEP: return refusal
	if not movement.is_finite() or capsule(actor)==null: return refusal
	var up:=actor.up_direction.normalized()
	if actor.velocity.dot(up)>EPSILON or movement.length()<EPSILON or absf(movement.dot(up))>EPSILON: return refusal
	var original:=actor.global_transform
	var anchor: Transform3D=original
	var sole:=sole_projection(actor,up)
	if continuation.is_empty():
		if not grounded_observation or not has_support(actor,original): return refusal
	else:
		if continuation.elapsed>=CONTINUATION_SECONDS-EPSILON or movement.normalized().dot(continuation.direction)<0.95: return refusal
		if original.basis!=continuation.anchor.basis or hull_identity(actor,height)!=continuation.hull: return refusal
		for receipt in continuation.surfaces.values():
			if not surface_unchanged(receipt): return refusal
		var contact:=cast_support(actor,original,SUPPORT_REACH,false)
		if contact==null: return refusal
		var target_contact:=false
		for index in range(contact.get_collision_count()):
			if contact.get_collider(index)==continuation.surface: target_contact=true
			elif not continuation.surfaces.has(contact.get_collider(index).get_instance_id()): return refusal
		if not target_contact: return refusal
		anchor=continuation.anchor;sole=continuation.sole
	# Clearance tests retain the collision node's complete local transform.
	var separated:=original;separated.origin+=up*maxf(actor.safe_margin*2,0.002)
	if not clear_at(actor,separated): return refusal
	var front:=KinematicCollision3D.new()
	var front_blocked:=actor.test_move(original,movement,front,actor.safe_margin,false,8)
	if front_blocked and not still_static(front): return refusal
	if continuation.is_empty():
		var blocked:=false
		for index in range(front.get_collision_count()):
			if front.get_normal(index).dot(up)<cos(actor.floor_max_angle): blocked=true
		if not blocked: return refusal # Ordinary slopes stay with move_and_slide.
	# Reserve the engine's tiny initial floor-recovery margin inside the lift bound.
	var high: float=anchor.origin.dot(up)+maxf(height-actor.safe_margin*3,height*0.9)
	var lift_height: float=high-original.origin.dot(up)
	if lift_height<=EPSILON: return refusal
	var lifted:=original;lifted.origin+=up*lift_height
	if actor.test_move(original,up*lift_height,null,actor.safe_margin,false,8) or not clear_at(actor,lifted): return refusal
	var advanced:=lifted;advanced.origin+=movement
	if actor.test_move(lifted,movement,null,actor.safe_margin,false,8) or not clear_at(actor,advanced): return refusal
	var landing:=cast_support(actor,advanced,height+SUPPORT_REACH,false)
	if landing==null: return refusal
	var destination:=advanced;destination.origin+=landing.get_travel()
	var rise:= (destination.origin-original.origin).dot(up)
	if rise<=EPSILON or (destination.origin-anchor.origin).dot(up)>height+EPSILON: return refusal
	# The capsule can touch a high corner before its sole reaches that corner.
	# Bound the contacted surface itself, so repeated ticks cannot ratchet up a wall.
	for index in range(landing.get_collision_count()):
		if not continuation.is_empty() and landing.get_collider(index)!=continuation.surface: return refusal
		if landing.get_position(index).dot(up)-sole>height+EPSILON: return refusal
		# A sphere touching a sharp horizontal tread reports a diagonal corner
		# normal. Verify the actual surface just inside that corner independently;
		# the native body's floor flag still decides whether it is grounded.
		var at: Vector3=landing.get_position(index)+movement.normalized()*0.005
		var query:=PhysicsRayQueryParameters3D.create(at+up*0.01,at-up*0.02,actor.collision_mask,excluded(actor))
		var top:=actor.get_world_3d().direct_space_state.intersect_ray(query)
		if top.is_empty() or top.collider!=landing.get_collider(index) or top.normal.dot(up)<cos(actor.floor_max_angle): return refusal
		if top.position.dot(up)-sole>height+EPSILON: return refusal
	var clear_destination:=destination;clear_destination.origin+=up*maxf(actor.safe_margin*2,0.002)
	if not clear_at(actor,clear_destination): return refusal
	var surfaces: Dictionary={}
	for hit in [front,landing]:
		for index in range(hit.get_collision_count()):
			var body: StaticBody3D=hit.get_collider(index)
			surfaces[body.get_instance_id()]={"body":body,"transform":body.global_transform,"geometry":surface_geometry(body)}
	var retained: Dictionary={"anchor":anchor,"sole":sole,"surface":landing.get_collider(0),"direction":continuation.get("direction",movement.normalized()),"surfaces":surfaces,"hull":hull_identity(actor,height),"elapsed":continuation.get("elapsed",0.0)}
	return {"start":original,"points":[lifted.origin,advanced.origin,destination.origin],"movement":movement,"rise":rise,"height":height,"anchor":anchor,"surfaces":surfaces,"continuation":retained}

static func execute(actor: CharacterBody3D,admission: Dictionary) -> bool:
	if admission.is_empty() or actor.global_transform!=admission.start: return false
	for receipt in admission.surfaces.values():
		if not surface_unchanged(receipt): return false
	var original:=actor.global_transform
	for index in range(admission.points.size()):
		var point: Vector3=admission.points[index]
		var motion:=point-actor.global_position
		# Admission already swept the actor's configured safety margin. Committing
		# that clear path at zero extra margin prevents a touching stair corner from
		# adding an uncommanded lateral recovery during the next vertical lift.
		actor.move_and_collide(motion,false,0.0,false,8)
		var residual:=actor.global_position-point
		var up:=actor.up_direction.normalized()
		var recovered_floor: bool=index==0 and residual.dot(up)>=0 and residual.dot(up)<=actor.safe_margin*2+EPSILON and (residual-up*residual.dot(up)).length()<=EPSILON and (actor.global_position-admission.anchor.origin).dot(up)<=admission.height+EPSILON
		if residual.length()>EPSILON and not recovered_floor:
			actor.global_transform=original;return false
	var displacement:=actor.global_position-original.origin
	var up:=actor.up_direction.normalized()
	var lateral:=displacement-up*displacement.dot(up)
	if lateral.distance_to(admission.movement)>EPSILON or cast_support(actor,actor.global_transform,SUPPORT_REACH,false)==null:
		actor.global_transform=original;return false
	return true
