# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Gujranwala eye-level craft detail. Presentation only; no collision, navigation or world-state authority.
const VesselProfile := preload("res://presentation/vessel_profile.gd")
var upper_borders: Array[MeshInstance3D]=[]
var timber_reveals: Array[MeshInstance3D]=[]
var plinth_accents: Array[MeshInstance3D]=[]
var repair_fields: Array[MeshInstance3D]=[]
var wall_rings: Array[MeshInstance3D]=[]
var cords: Array[MeshInstance3D]=[]
var storage_roots: Array[Node3D]=[]
var _materials: Dictionary={}
var enabled := true

func material(color: Color,roughness: float=.96,metallic: float=0.0) -> StandardMaterial3D:
	var key: String=color.to_html()+":"+str(roughness)+":"+str(metallic)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
	_materials[key]=m
	return m

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments: int=14) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=segments
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func torus(parent: Node3D,name: String,inner: float,outer: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=TorusMesh.new()
	shape.inner_radius=inner
	shape.outer_radius=outer
	shape.rings=14
	shape.ring_segments=8
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material(color,.72,.12)
	parent.add_child(mesh)
	return mesh

func build(chapter: Node3D) -> void:
	name="GujranwalaMicrodetail"
	set_meta("classification","direct-craft-microdetail")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	_build_bay_detail()
	_build_repairs()
	_build_wall_fixtures()
	_build_storage_corners()
	sample(int(chapter.model.progress().tick))

func _build_bay_detail() -> void:
	var root:=Node3D.new()
	root.name="BayMicrodetail"
	add_child(root)
	for i in range(8):
		var x: float=-14.875+float(i)*4.25
		upper_borders.append(box(root,"UpperBorder%d"%i,Vector3(2.75,.055,.025),Vector3(x,3.22,11.69),Color("9f7754")))
		plinth_accents.append(box(root,"PlinthAccent%d"%i,Vector3(2.85,.075,.030),Vector3(x,.42,11.68),Color("9a8262")))
		for side in [-1.0,1.0]:
			timber_reveals.append(box(root,"TimberReveal",Vector3(.055,1.32,.040),Vector3(x+side*1.27,1.55,11.665),Color("66503c")))

func _build_repairs() -> void:
	var root:=Node3D.new()
	root.name="SelectiveRepairFields"
	add_child(root)
	var specs: Array=[
		[Vector3(-18.62,1.05,6.0),Vector3(.030,.65,1.60),Color("b39f81")],
		[Vector3(-18.62,1.45,-7.0),Vector3(.030,.90,1.25),Color("aa9679")],
		[Vector3(18.62,.90,3.0),Vector3(.030,.50,1.80),Color("b8a487")],
		[Vector3(18.62,1.60,-11.0),Vector3(.030,.75,1.10),Color("a99477")],
		[Vector3(-10.5,1.10,11.685),Vector3(1.25,.55,.020),Color("b9a78b")],
		[Vector3(2.6,1.52,11.685),Vector3(1.05,.68,.020),Color("a99578")],
		[Vector3(12.9,.92,11.685),Vector3(1.40,.42,.020),Color("baa88d")],
		[Vector3(-18.62,2.20,9.2),Vector3(.030,.40,.95),Color("9f896e")],
		[Vector3(18.62,2.05,12.0),Vector3(.030,.38,.88),Color("9e8870")],
		[Vector3(17.2,2.42,11.685),Vector3(.82,.28,.020),Color("c0ad91")]
	]
	for i in range(specs.size()):
		var patch:=box(root,"RepairField%d"%i,specs[i][1],specs[i][0],specs[i][2])
		patch.rotation.z=.008*float((i%3)-1)
		repair_fields.append(patch)

func _build_wall_fixtures() -> void:
	var root:=Node3D.new()
	root.name="WallFixtureMicrodetail"
	add_child(root)
	var xs: Array[float]=[-13.8,-8.4,-2.9,3.2,8.8,14.0]
	for i in range(xs.size()):
		var ring:=torus(root,"WallRing%d"%i,.075,.095,Vector3(xs[i],1.72,11.62),Color("76614c"))
		ring.rotation.x=PI/2
		wall_rings.append(ring)
		if i in [1,4]:
			var cord:=box(root,"HangingCord%d"%i,Vector3(.025,.54,.025),Vector3(xs[i],1.43,11.60),Color("6a513a"))
			cords.append(cord)

func _build_storage_corners() -> void:
	var positions: Array[Vector3]=[Vector3(-17.3,.14,9.65),Vector3(17.6,.14,10.3)]
	for i in range(positions.size()):
		var root:=Node3D.new()
		root.name="QuietStorageCorner%d"%i
		root.position=positions[i]
		add_child(root)
		storage_roots.append(root)
		for j in range(3):
			var vessel := cylinder(root,"StorageJar%d"%j,.15+.025*j,.30+.045*(j%2),Vector3(-.34+.32*j,.17,.02+.10*(j%2)),Color("8e6a4b") if (i+j)%2==0 else Color("7b6d5a"),14)
			vessel.mesh = VesselProfile.build(.15+.025*j,.30+.045*(j%2),i*3+j)
		var mat_roll:=box(root,"RolledMat",Vector3(.58,.15,.20),Vector3(.30,.12,-.30),Color("897252"))
		mat_roll.rotation.y=.22 if i==0 else -.18
		box(root,"FoldedCloth",Vector3(.45,.09,.32),Vector3(-.28,.12,-.33),Color("8b6557") if i==0 else Color("687a70"))

func set_enabled(value: bool) -> void:
	enabled=value
	visible=value

func sample(tick: int) -> void:
	var t: float=float(tick)/60.0
	for i in range(cords.size()):
		cords[i].rotation.z=.018*sin(t*.62+i*1.7)
