# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Bounded static-box contact records. No NodePaths, instance IDs or executable save data.
const M := preload("res://player/locomotion_rules.gd")
const Probe := preload("res://player/traversal_probe.gd")
const VERSION := "traversal-contact.v1"
const EPS := 0.0001 # Local metres; JSON/Vector3 roundtrip tolerance, not reach assistance.

static func fields(value: Variant,keys: Array) -> bool:
	if not value is Dictionary or value.size()!=keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func transform_array(t: Transform3D) -> Array:
	return [M.array(t.basis.x),M.array(t.basis.y),M.array(t.basis.z),M.array(t.origin)]

static func surface_id(body: StaticBody3D) -> String:
	var id: Variant=body.get_meta("traversal_id","")
	return id if id is String and not id.is_empty() and id.length()<=80 and id.is_valid_identifier() else ""

static func fingerprint(body: StaticBody3D) -> String:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or not body.is_inside_tree(): return ""
	# Moving platforms/conveyors and non-box contact shapes have not been qualified.
	if body.constant_linear_velocity!=Vector3.ZERO or body.constant_angular_velocity!=Vector3.ZERO: return ""
	var shapes: Array=[]
	for child in body.get_children():
		if child is CollisionShape3D:
			if not child.shape is BoxShape3D: return ""
			shapes.append([transform_array(child.transform),M.array(child.shape.size),child.shape.margin,child.disabled])
	if shapes.is_empty() or shapes.size()>8: return ""
	return JSON.stringify([transform_array(body.global_transform),shapes,body.collision_layer,body.collision_mask,body.get_meta("traversable",false)]).sha256_text()

static func bind(body: StaticBody3D) -> Dictionary:
	return {"id":surface_id(body),"digest":fingerprint(body)}

static func resolve(actor: CharacterBody3D,record: Variant) -> StaticBody3D:
	if not fields(record,["id","digest"]) or not record.id is String or not record.digest is String: return null
	if record.id.is_empty() or record.digest.length()!=64 or not is_instance_valid(actor.traversal_scope): return null
	var candidates: Array=actor.traversal_scope.find_children("*","StaticBody3D",true,false)
	if candidates.size()>256: return null
	var result: StaticBody3D=null
	for body in candidates:
		if surface_id(body)==record.id:
			if result!=null: return null # Ambiguous identity never chooses the first match.
			result=body
	if result==null or fingerprint(result)!=record.digest: return null
	return result

static func capture(plan: Dictionary) -> Dictionary:
	var points: Array=[]
	for point in plan.points: points.append(M.array(point))
	return {"schema":VERSION,"kind":plan.kind,"origin":M.array(plan.origin),"forward":M.array(plan.forward),
		"points":points,"index":0,"contact":M.array(plan.contact),"surface":bind(plan.surface),"landing":bind(plan.landing)}

static func bindings_fit(actor: CharacterBody3D,record: Dictionary) -> bool:
	return resolve(actor,record.get("surface"))!=null and resolve(actor,record.get("landing"))!=null

static func prepare(actor: CharacterBody3D,motion: Dictionary) -> Dictionary:
	var refused: Dictionary={"error":"Saved traversal contact, path or support is no longer valid."}
	var t: Variant=motion.get("traversal")
	if not fields(t,["schema","kind","origin","forward","points","index","contact","surface","landing"]): return refused
	if t.schema!=VERSION or t.kind not in ["vault","mantle"] or not M.vector(t.origin,100) or not M.vector(t.forward,1) or not M.vector(t.contact,100): return refused
	if not M.finite(t.index) or t.index!=floor(t.index) or t.index<0 or t.index>2: return refused
	if not t.points is Array or t.points.size()!=3: return refused
	for point in t.points:
		if not M.vector(point,100): return refused
	if not actor.traversal_enabled or actor.external_speed_limit!=INF: return refused
	if motion.grounded or M.point(motion.velocity)!=Vector3.ZERO or motion.coyote!=0 or motion.buffer!=0: return refused
	var surface:=resolve(actor,t.surface);var landing:=resolve(actor,t.landing)
	if surface==null or landing==null: return refused
	var origin:=M.point(t.origin);var forward:=M.point(t.forward)
	if absf(forward.y)>EPS or absf(forward.length()-1)>EPS: return refused
	if not Probe.clear_at(actor,origin+Vector3.UP*0.003) or not Probe.support(actor,origin): return refused
	# Recompute the original admission from code and current geometry. A save does not
	# get to introduce arbitrary waypoints or turn a mantle into an unrelated teleport.
	var plan:=Probe.plan_at(actor,origin,forward)
	if not plan.error.is_empty() or plan.kind!=t.kind or plan.surface!=surface or plan.landing!=landing: return refused
	if plan.contact.distance_to(M.point(t.contact))>EPS: return refused
	for i in range(3):
		if plan.points[i].distance_to(M.point(t.points[i]))>EPS: return refused
	var index:=int(t.index)
	var start: Vector3=origin if index==0 else plan.points[index-1]
	var target: Vector3=plan.points[index]
	var p:=M.point(motion.position)
	var segment:=target-start
	if segment.length_squared()<EPS*EPS:
		if p.distance_to(target)>EPS: return refused
	else:
		var fraction: float=clampf((p-start).dot(segment)/segment.length_squared(),0,1)
		if p.distance_to(start+segment*fraction)>EPS: return refused
	# Validate the remaining swept path too; do not mutate a body while validating.
	var prior:=p
	for i in range(index,3):
		var at: Vector3=plan.points[i];var transform:=actor.global_transform;transform.origin=prior
		if not Probe.clear_at(actor,at) or actor.test_move(transform,at-prior): return refused
		prior=at
	var canonical:=capture(plan);canonical.index=index
	return {"error":"","plan":plan,"record":canonical}
