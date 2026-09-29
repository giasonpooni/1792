# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Metric exterior access component. Current box is qualification geometry, not a monument model.
const Rules := preload("res://geography/fortune_rules.gd")
var definition: Dictionary = {}
var volume: StaticBody3D

func build(site: Dictionary, allow_qualification: bool=false) -> String:
	if not definition.is_empty(): return "Exterior already built."
	var error := Rules.site_error(site)
	if not error.is_empty(): return error
	if site.classification!="synthetic:qualification" or not allow_qualification:
		return "Historical scenery needs an admitted period asset; qualification boxes cannot impersonate it."
	definition=site.duplicate(true)
	volume=StaticBody3D.new();volume.name="NonEnterableVolume";add_child(volume)
	var dimensions:=Vector3(site.size_m[0],site.size_m[1],site.size_m[2])
	volume.position.y=dimensions.y/2.0
	var shape:=BoxShape3D.new();shape.size=dimensions
	var collision:=CollisionShape3D.new();collision.shape=shape;volume.add_child(collision)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=dimensions;mesh.mesh=box
	var material:=StandardMaterial3D.new();material.albedo_color=Color("907c66");material.roughness=1
	mesh.material_override=material;volume.add_child(mesh)
	var marker:=MeshInstance3D.new();var disc:=CylinderMesh.new();disc.top_radius=0.55;disc.bottom_radius=0.55;disc.height=0.03
	marker.mesh=disc;marker.position=Vector3(site.prayer_at_m[0],site.prayer_at_m[1]+0.03,site.prayer_at_m[2]);add_child(marker)
	return ""

func access_error(actor: CharacterBody3D, forward: Vector3, frame_id: String, year: int, mounted: bool=false) -> String:
	if definition.is_empty() or not is_instance_valid(actor) or frame_id!=definition.frame_id: return "Unknown actor/site frame."
	if not is_inside_tree() or not actor.is_inside_tree() or actor.get_world_3d()!=get_world_3d(): return "Actor and site must share the current physics world."
	if not actor.is_on_floor(): return "Stand on the ground at the exterior point."
	if mounted or year<definition.from or year>=definition.until: return "Dismount at a site belonging to this period."
	# Authored transforms must not turn metric geometry into scaled scenery.
	if not global_basis.is_equal_approx(Basis.IDENTITY): return "Qualification exterior requires an unscaled, unrotated metric frame."
	var p: Vector3 = to_local(actor.global_position)
	if not p.is_finite() or not forward.is_finite(): return "Invalid physical position."
	if absf(p.x)<=definition.size_m[0]/2.0 and absf(p.z)<=definition.size_m[2]/2.0: return "Site interiors are not playable."
	var anchor:=Vector3(definition.prayer_at_m[0],definition.prayer_at_m[1],definition.prayer_at_m[2])
	if p.distance_to(anchor)>2.25 or absf(p.y-anchor.y)>0.3: return "Approach the exterior prayer point on the ground."
	var focus: Vector3 = to_global(anchor+Vector3(0,1.0,-1))
	var eye: Vector3 = actor.global_position+Vector3.UP*1.4
	if forward.normalized().dot(eye.direction_to(focus))<0.35: return "Face the exterior prayer point."
	var query:=PhysicsRayQueryParameters3D.create(eye,focus,1,[actor.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return "The prayer approach is obstructed."
	return ""

func pray(actor: CharacterBody3D, forward: Vector3, frame_id: String, year: int, state: Dictionary, sites: Dictionary, digest: String, tick: int, mounted: bool=false) -> Dictionary:
	var error:=access_error(actor,forward,frame_id,year,mounted)
	if not error.is_empty(): return {"error":error}
	# Recheck the scene's definition against the authority's catalogue at execution, not menu-open time.
	if not sites.has(definition.id) or sites[definition.id]!=definition: return {"error":"Scene/catalogue identity mismatch."}
	return Rules.append(state,{"kind":"prayer","site_id":definition.id,"year":year},sites,digest,tick)
