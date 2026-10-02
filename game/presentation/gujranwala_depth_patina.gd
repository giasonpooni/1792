# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Gujranwala depth/patina pass. Presentation only: no collision, navigation, economy or save authority.
var skyline_clusters: Array[Node3D]=[]
var parapets: Array[MeshInstance3D]=[]
var patina_patches: Array[MeshInstance3D]=[]
var hanging_cloth: Array[MeshInstance3D]=[]
var distant_foliage: Array[MeshInstance3D]=[]
var window_glows: Array[MeshInstance3D]=[]
var _materials: Dictionary={}
var preset: String="daylight"
var enabled := true

func material(color: Color,roughness: float=.96,emission: Color=Color.BLACK,energy: float=0.0) -> StandardMaterial3D:
	var key: String=color.to_html()+":"+str(roughness)+":"+emission.to_html()+":"+str(energy)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	if energy>0:
		m.emission_enabled=true
		m.emission=emission
		m.emission_energy_multiplier=energy
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

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments: int=16) -> MeshInstance3D:
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

func sphere(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=12
	shape.rings=7
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.scale=size
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func build(chapter: Node3D) -> void:
	name="GujranwalaDepthPatina"
	set_meta("classification","direct-craft-depth-patina")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	_build_parapet_rhythm()
	_build_skyline_clusters()
	_build_patina()
	_build_high_cloth()
	_build_distant_foliage()
	set_preset("daylight")
	sample(int(chapter.model.progress().tick))

func _build_parapet_rhythm() -> void:
	var root:=Node3D.new()
	root.name="PerimeterParapetRhythm"
	add_child(root)
	# North wall: low rhythm above the existing solid wall.
	for i in range(10):
		var x: float=-25.2+float(i)*5.6
		parapets.append(box(root,"NorthParapet%d"%i,Vector3(3.4,.42,.36),Vector3(x,3.22,28.72),Color("a89170")))
	# Side-wall accents are sparse so they frame rather than cage the courtyard.
	for side in [-1.0,1.0]:
		for i in range(5):
			var z: float=-20.0+float(i)*9.5
			parapets.append(box(root,"SideParapet",Vector3(.36,.42,3.2),Vector3(side*28.72,3.22,z),Color("9f886a")))

func _build_skyline_clusters() -> void:
	var positions: Array[Vector3]=[
		Vector3(-20.5,3.35,27.9),Vector3(20.5,3.35,27.9),
		Vector3(-27.8,3.35,5.5),Vector3(27.8,3.35,5.5)]
	for i in range(positions.size()):
		var root:=Node3D.new()
		root.name="PerimeterPavilionStudy%d"%i
		root.position=positions[i]
		add_child(root)
		skyline_clusters.append(root)
		var plaster:=Color("b7a27f")
		var timber:=Color("6e5742")
		for x in [-.72,.72]:
			for z in [-.50,.50]:
				cylinder(root,"Column",.075,1.65,Vector3(x,.83,z),timber,12)
		box(root,"Canopy",Vector3(1.95,.16,1.55),Vector3(0,1.72,0),plaster)
		box(root,"Cornice",Vector3(2.16,.10,1.74),Vector3(0,1.84,0),Color("9d7f5e"))
		cylinder(root,"Finial",.07,.42,Vector3(0,2.10,0),Color("7f654a"),12)
		var opening:=box(root,"DarkOpening",Vector3(.95,.66,.03),Vector3(0,.95,-.54),Color("4b443b"))
		window_glows.append(opening)

func _build_patina() -> void:
	var root:=Node3D.new()
	root.name="SelectiveWallPatina"
	add_child(root)
	var specs: Array=[
		[Vector3(-28.73,.72,-14.0),Vector3(.025,1.15,3.2),Color("8e816d")],
		[Vector3(-28.73,.55,5.0),Vector3(.025,.82,2.4),Color("96866e")],
		[Vector3(28.73,.64,-3.0),Vector3(.025,1.00,2.8),Color("897b67")],
		[Vector3(28.73,.48,16.0),Vector3(.025,.68,2.1),Color("9a896f")],
		[Vector3(-16.0,.62,28.73),Vector3(3.0,.92,.025),Color("927f67")],
		[Vector3(7.0,.50,28.73),Vector3(2.6,.70,.025),Color("9d8a71")],
		[Vector3(20.0,.78,28.73),Vector3(2.2,1.18,.025),Color("897963")],
		[Vector3(-5.0,2.05,28.70),Vector3(2.0,.50,.025),Color("b29d7b")]
	]
	for i in range(specs.size()):
		var patch:=box(root,"PatinaPatch%d"%i,specs[i][1],specs[i][0],specs[i][2])
		patch.rotation.z=.012*float((i%3)-1)
		patina_patches.append(patch)

func _build_high_cloth() -> void:
	var root:=Node3D.new()
	root.name="HighHouseholdCloth"
	add_child(root)
	var specs: Array=[
		[Vector3(-9.2,2.58,10.75),Color("a16d55"),-.025],
		[Vector3(-8.55,2.60,10.78),Color("718178"),.018],
		[Vector3(8.15,2.56,10.76),Color("b39a6e"),-.018],
		[Vector3(8.82,2.62,10.78),Color("875f52"),.026]
	]
	for i in range(specs.size()):
		var cloth:=box(root,"HighCloth%d"%i,Vector3(.46,.68,.025),specs[i][0],specs[i][1])
		cloth.rotation.z=specs[i][2]
		hanging_cloth.append(cloth)
	# Visual clotheslines remain above head height and have no collision.
	box(root,"LineLeft",Vector3(1.45,.018,.018),Vector3(-8.86,2.91,10.78),Color("62513f"))
	box(root,"LineRight",Vector3(1.45,.018,.018),Vector3(8.49,2.91,10.78),Color("62513f"))

func _build_distant_foliage() -> void:
	var root:=Node3D.new()
	root.name="DistantFoliage"
	add_child(root)
	var positions: Array[Vector3]=[
		Vector3(-25.5,4.2,25.0),Vector3(-12.0,4.5,27.3),Vector3(2.5,4.3,27.5),
		Vector3(15.0,4.55,27.0),Vector3(25.5,4.25,24.2),Vector3(-27.0,4.35,8.5),
		Vector3(27.0,4.40,7.5),Vector3(27.0,4.25,-10.0)]
	for i in range(positions.size()):
		distant_foliage.append(sphere(root,"Canopy%d"%i,Vector3(2.6,1.8,2.3),positions[i],Color("596c4e") if i%2==0 else Color("667654")))

func set_preset(id: String) -> void:
	preset=id
	var day:=material(Color("4b443b"),.95)
	var dusk:=material(Color("7d5a40"),.88,Color("e8a56a"),.55 if id=="golden_hour" else 1.15)
	for opening in window_glows:
		opening.material_override=day if id=="daylight" else dusk

func set_enabled(value: bool) -> void:
	enabled=value
	visible=value

func sample(tick: int) -> void:
	var t: float=float(tick)/60.0
	for i in range(hanging_cloth.size()):
		hanging_cloth[i].rotation.z=.022*sin(t*.48+i*.8)
	for i in range(distant_foliage.size()):
		distant_foliage[i].rotation.z=.008*sin(t*.27+i*.31)
