# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Material projection over declared craft meshes. No new geometry or game authority.
const SURFACE:=preload("res://presentation/craft_surface.gdshader")
const HEIGHT:=preload("res://assets/surfaces/plastered_wall_disp_1k.png")
const ROUGHNESS:=preload("res://assets/surfaces/plastered_wall_rough_1k.png")
var records: Array[Dictionary]=[]
var materials: Dictionary={}
var enabled:=false

func finish(mesh: MeshInstance3D,kind: int,horizontal: bool=false) -> void:
	if not mesh.material_override is StandardMaterial3D: return
	var old: StandardMaterial3D=mesh.material_override
	if old.emission_enabled or old.metallic>0.0: return
	var key:=old.albedo_color.to_html()+":"+str(kind)+":"+str(horizontal)
	if not materials.has(key):
		var material:=ShaderMaterial.new()
		material.shader=SURFACE
		material.set_shader_parameter("pigment",old.albedo_color)
		material.set_shader_parameter("finish",kind)
		material.set_shader_parameter("horizontal_grain",horizontal)
		material.set_shader_parameter("plaster_height",HEIGHT)
		material.set_shader_parameter("plaster_roughness",ROUGHNESS)
		materials[key]=material
	records.append({"node":mesh,"old":old,"new":materials[key],"kind":kind})

func build(art: Node3D) -> void:
	name="GujranwalaMaterialFidelity"
	set_meta("classification","original-material-appearance-study")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	for mesh in art.beauty.accent_panels: finish(mesh,0)
	for screen in art.beauty.screens:
		for mesh in screen.find_children("*","MeshInstance3D",true,false):
			# Repeated primitive names need not survive Godot's sibling-name allocation.
			if mesh.mesh is BoxMesh: finish(mesh,1,mesh.mesh.size.x>mesh.mesh.size.y)
	for mesh in art.beauty.pottery: finish(mesh,2)
	for mesh in art.beauty.textiles: finish(mesh,3)
	for mesh in art.depth_patina.parapets: finish(mesh,0)
	for mesh in art.depth_patina.patina_patches: finish(mesh,0)
	for mesh in art.depth_patina.hanging_cloth: finish(mesh,3)
	for pavilion in art.depth_patina.skyline_clusters:
		for mesh in pavilion.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh is CylinderMesh and mesh.mesh.height>1.0: finish(mesh,1)
			elif str(mesh.name) in ["Canopy","Cornice"]: finish(mesh,0)
	for mesh in art.microdetail.upper_borders: finish(mesh,0)
	for mesh in art.microdetail.plinth_accents: finish(mesh,0)
	for mesh in art.microdetail.repair_fields: finish(mesh,0)
	for mesh in art.microdetail.timber_reveals: finish(mesh,1)
	for corner in art.microdetail.storage_roots:
		for mesh in corner.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).begins_with("StorageJar"): finish(mesh,2)
			elif str(mesh.name) in ["RolledMat","FoldedCloth"]: finish(mesh,3)

func set_enabled(value: bool) -> void:
	enabled=value
	for record in records:
		if is_instance_valid(record.node): record.node.material_override=record.new if value else record.old

func _exit_tree() -> void:
	set_enabled(false)
