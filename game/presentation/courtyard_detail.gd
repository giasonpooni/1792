# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Appearance projection. The existing chapter owns every body, clock and receipt.
const BAY := preload("res://assets/courtyard/courtyard_bay.glb")
const CHILD := preload("res://assets/courtyard/childhood_costume.glb")
const SURFACE := preload("res://presentation/courtyard_surface.gdshader")
const SURFACE_MAPS := {0:[preload("res://assets/surfaces/plastered_wall_diff_1k.png"),preload("res://assets/surfaces/plastered_wall_disp_1k.png"),preload("res://assets/surfaces/plastered_wall_rough_1k.png")],3:[preload("res://assets/surfaces/dirt_diff_1k.png"),preload("res://assets/surfaces/dirt_disp_1k.png"),preload("res://assets/surfaces/dirt_rough_1k.png")]}
const HUD := preload("res://presentation/courtyard_hud.gd")
const Envelope := preload("res://reconstruction/courtyard_envelope.gd")
const Fabric := preload("res://presentation/courtyard_fabric.gd")
const BUILD_PATH := "res://assets/courtyard/build.json"
const ASSET_HASHES := {"courtyard_bay.glb":"196ee691fe7dc05759a8e5372a9e3938777ddac24278d870753fa9e272dbb1e0","childhood_costume.glb":"26462a9eba66eb872f94639c3d961f0b2517cd42c10beefaab3634c8caefac70"}
var enabled := false
var last_tick := -1
var source_skeleton: Skeleton3D
var target_skeleton: Skeleton3D
var child_root: Node3D
var hud: CanvasLayer
var records: Array[Dictionary]=[]
var hidden_meshes: Array[Dictionary]=[]
var bone_map: Array[Dictionary]=[]
var _materials: Dictionary={}
var _art: Node3D
var _chapter: Node3D
var _loaded := false
var close_camera := true
var _camera: Camera3D
var _arm: SpringArm3D
var _camera_original: Dictionary
var _bay_count := 0
var _carried_origin: Transform3D
var fabric: Node3D
static func validate_receipt(v: Variant) -> String:
	if not v is Dictionary or v.get("schema")!="1792.blender-courtyard.v1": return "Unknown Blender receipt."
	if v.get("georeferenced")!=false or v.get("historically_verified")!=false or v.get("classification")!="original-authoring-study": return "Incorrect reconstruction claim."
	if not v.get("assets") is Array or v.assets.size()!=2: return "Expected two approved assets."
	var seen: Array=[]
	for a in v.assets:
		if not a is Dictionary or not a.get("file") is String: return "Malformed asset."
		if not ASSET_HASHES.has(a.file) or a.file in seen or a.get("sha256")!=ASSET_HASHES[a.file]: return "Unapproved or duplicate asset."
		seen.append(a.file)
	return ""
func material(color: Color,kind: int) -> ShaderMaterial:
	var key:=color.to_html()+str(kind)
	if _materials.has(key): return _materials[key]
	var m:=ShaderMaterial.new();m.shader=SURFACE;m.set_shader_parameter("base_color",color);m.set_shader_parameter("material_kind",kind)
	if SURFACE_MAPS.has(kind):
		m.set_shader_parameter("use_scanned",true)
		for i in range(3): m.set_shader_parameter(["surface_diffuse","surface_height","surface_roughness"][i],SURFACE_MAPS[kind][i])
	_materials[key]=m;return m
func replace(v: MeshInstance3D,m: Material) -> void: records.append({"node":v,"old":v.material_override,"new":m})
func hide_mesh(v: MeshInstance3D) -> void: hidden_meshes.append({"node":v,"layers":v.layers})
func build(chapter: Node3D,art: Node3D) -> String:
	if _loaded: return "Courtyard detail already attached."
	_chapter=chapter;_art=art
	var receipt: Variant=JSON.parse_string(FileAccess.get_file_as_string(BUILD_PATH));var error:=validate_receipt(receipt)
	if not error.is_empty(): return error
	for a in receipt.assets:
		if FileAccess.get_sha256(BUILD_PATH.get_base_dir().path_join(str(a.file)))!=a.sha256: return "Asset content differs from receipt."
	for v in chapter.get_parent().find_children("*","MeshInstance3D",true,false):
		if v.mesh==chapter.cell.terrain_mesh: replace(v,material(Color("918875"),3))
		elif v.mesh is BoxMesh:
			var s: Vector3=v.mesh.size;var p: Vector3=v.global_position
			if s.y<.21 and s.x>3 and s.z>2 and p.y<.31: replace(v,material(Color("918875"),3))
			elif s.y>2 and (s.x>8 or s.z>8) and absf(p.x)<29 and absf(p.z)<29: replace(v,material(Color("c0b29a"),0))
	var old: Node3D=art.get_node("VerandaKit")
	for v in old.find_children("*","MeshInstance3D",true,false): hide_mesh(v)
	for i in range(8):
		var bay: Node3D=BAY.instantiate();bay.name="AuthoredBay%d"%i;add_child(bay);bay.position=old.position+Vector3(-17+(i+.5)*4.25,0,0)
		_style_import(bay);_bay_count+=1
		var fill:=MeshInstance3D.new();fill.mesh=Envelope.infill();fill.material_override=material(Color("baae96"),0);bay.add_child(fill)
		var back:=MeshInstance3D.new();var panel:=BoxMesh.new();panel.size=Vector3(4.25,3.35,.03);back.mesh=panel;back.position=Vector3(0,1.675,.43);back.material_override=material(Color("baae96"),0);bay.add_child(back)
	fabric=Fabric.new();fabric.name="PhotoInformedFabric";add_child(fabric)
	error=fabric.build(self)
	if not error.is_empty(): return error
	source_skeleton=art._hero_proxy.skeleton
	for v in art._hero_proxy.find_children("*","MeshInstance3D",true,false): hide_mesh(v)
	child_root=CHILD.instantiate();child_root.name="FittedChildhoodCostume";art._hero_proxy.add_child(child_root)
	var rigs:=child_root.find_children("*","Skeleton3D",true,false)
	if rigs.size()!=1: return "Expected one imported skeleton."
	target_skeleton=rigs[0]
	for i in range(target_skeleton.get_bone_count()):
		var id:=target_skeleton.get_bone_name(i);var s:=source_skeleton.find_bone(id)
		if s<0: return "Unmapped imported bone: "+id
		bone_map.append({"target":i,"source":s,"source_inverse":source_skeleton.get_bone_global_rest(s).affine_inverse(),"target_rest":target_skeleton.get_bone_global_rest(i)})
	_style_import(child_root);_carried_origin=chapter.workplace.carried.transform
	_arm=chapter.avatar.get_node("CameraPivot/SpringArm3D");_camera=_arm.get_node("Camera3D");_camera_original={"length":_arm.spring_length,"fov":_camera.fov}
	set_camera(true);hud=HUD.new();hud.name="CourtyardReadableHUD";add_child(hud);hud.build(chapter)
	_loaded=true;set_meta("classification","original-authoring-study");set_meta("georeferenced",false);return ""
func _style_import(root: Node3D) -> void:
	var kinds: Dictionary={"lime_plaster":0,"worn_plinth":5,"old_timber":2,"painted_shutter":2,"brick":1,"child_cotton":4,"child_trousers":4,"child_sash":4,"child_leather":2}
	for v in root.find_children("*","MeshInstance3D",true,false):
		for i in range(v.mesh.get_surface_count()):
			var m: Material=v.mesh.surface_get_material(i)
			if m is StandardMaterial3D and kinds.has(m.resource_name): v.set_surface_override_material(i,material(m.albedo_color,kinds[m.resource_name]))
func set_camera(value: bool) -> void:
	close_camera=value
	if is_instance_valid(_arm): _arm.spring_length=6.8 if _chapter.model.mounted() else (3.5 if value else _camera_original.length)
	if is_instance_valid(_camera): _camera.fov=62.0 if value else _camera_original.fov
func set_enabled(value: bool) -> void:
	if not _loaded: return
	enabled=value;visible=value
	for r in records:
		if is_instance_valid(r.node): r.node.material_override=r.new if value else r.old
	for r in hidden_meshes:
		if is_instance_valid(r.node): r.node.layers=0 if value else r.layers
	if is_instance_valid(child_root): child_root.visible=value
	if is_instance_valid(_chapter) and is_instance_valid(_chapter.workplace): _chapter.workplace.carried.transform=_carried_origin
func sample(tick: int) -> void:
	if not _loaded or tick<0: return
	last_tick=tick;set_camera(close_camera);hud.sample()
	if not enabled: return
	# Idle orientation follows the existing look, including after position-only legacy saves.
	if Vector2(_chapter.avatar.velocity.x,_chapter.avatar.velocity.z).length()<.15: _art._hero_proxy.rotation.y=_chapter.avatar.pivot.rotation.y
	var desired: Dictionary={}
	for b in bone_map: desired[b.target]=source_skeleton.get_bone_global_pose(b.source)*b.source_inverse*b.target_rest
	for b in bone_map:
		var parent:=target_skeleton.get_bone_parent(b.target);var pose: Transform3D=desired[b.target]
		if parent>=0: pose=desired[parent].affine_inverse()*pose
		# Godot's bone pose is parent-local, not a rest-relative offset.
		target_skeleton.set_bone_pose_position(b.target,pose.origin);target_skeleton.set_bone_pose_rotation(b.target,pose.basis.get_rotation_quaternion());target_skeleton.set_bone_pose_scale(b.target,pose.basis.get_scale())
	if _chapter.model.carrying_workshop():
		var hand: Transform3D=target_skeleton.global_transform*target_skeleton.get_bone_global_pose(target_skeleton.find_bone("forearmR"))
		_chapter.workplace.carried.global_position=hand*Vector3(0,-.31,-.025);_chapter.workplace.carried.global_basis=_art._hero_proxy.global_basis
	else: _chapter.workplace.carried.transform=_carried_origin
func _exit_tree() -> void:
	set_camera(false);set_enabled(false)
	if is_instance_valid(child_root): child_root.queue_free()
