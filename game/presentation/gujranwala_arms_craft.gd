# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Decorative household arms-craft niche. No weapon mechanics, collision, inventory or historical authority.
var display_roots: Array[Node3D]=[]
var longarms: Array[Node3D]=[]
var blades: Array[Node3D]=[]
var fittings: Array[MeshInstance3D]=[]
var repair_cloth: Array[MeshInstance3D]=[]
var _materials: Dictionary={}
var enabled := true

func mat(color: Color,roughness: float=.86,metallic: float=0.0) -> StandardMaterial3D:
	var key: String=color.to_html()+":"+str(roughness)+":"+str(metallic)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
	_materials[key]=m
	return m

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,material: Material) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material
	parent.add_child(mesh)
	return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,material: Material,segments: int=14) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=segments
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material
	parent.add_child(mesh)
	return mesh

func _curved_piece(parent: Node3D,name: String,origin: Vector3,length: float,angle_step: float,material: Material,width: float=.06) -> Node3D:
	var root:=Node3D.new()
	root.name=name
	root.position=origin
	parent.add_child(root)
	for i in range(6):
		var seg:=box(root,"Segment%d"%i,Vector3(width,length/6.0,.035),Vector3(.045*i,-length*.083*i,0),material)
		seg.rotation.z=-angle_step*float(i)
	return root

func _build_longarm(parent: Node3D,name: String,pos: Vector3,mirror: float) -> Node3D:
	var dark:=mat(Color("3d352f"),.72,.18)
	var steel:=mat(Color("6c6a65"),.36,.78)
	var warm:=mat(Color("b58b43"),.34,.64)
	var wrap:=mat(Color("9b8060"),.98,0)
	var root:=Node3D.new()
	root.name=name
	root.position=pos
	root.rotation.z=.08*mirror
	parent.add_child(root)
	longarms.append(root)

	box(root,"LongDarkBarrel",Vector3(.07,1.75,.055),Vector3(0,.72,0),steel)
	var stock:=box(root,"CurvedStock",Vector3(.23,.72,.075),Vector3(-.10*mirror,-.42,0),dark)
	stock.rotation.z=.20*mirror
	fittings.append(box(root,"WarmTopBand",Vector3(.10,.16,.065),Vector3(0,1.58,0),warm))
	fittings.append(box(root,"WarmStockBand",Vector3(.27,.07,.08),Vector3(-.09*mirror,-.18,0),warm))
	fittings.append(box(root,"WarmEndCap",Vector3(.25,.10,.085),Vector3(-.17*mirror,-.77,0),warm))
	var cloth:=box(root,"RepairWrap",Vector3(.27,.20,.09),Vector3(-.12*mirror,-.61,.005),wrap)
	cloth.rotation.z=.05*mirror
	repair_cloth.append(cloth)
	for i in range(5):
		var inlay:=box(root,"Inlay%d"%i,Vector3(.018,.10,.082),Vector3(.032*mirror,.95-.22*i,.003),warm)
		inlay.rotation.z=.22*mirror
		fittings.append(inlay)
	return root

func _build_sheathed_sabre(parent: Node3D) -> Node3D:
	var root:=Node3D.new()
	root.name="SheathedCurvedBladeStudy"
	root.position=Vector3(.10,-.12,.05)
	parent.add_child(root)
	blades.append(root)
	var black:=mat(Color("282724"),.84,.05)
	var steel:=mat(Color("76736d"),.30,.82)
	var warm:=mat(Color("bd9347"),.32,.70)
	var pale:=mat(Color("d7c9a8"),.74,.02)
	var sheath:=_curved_piece(root,"DarkScabbard",Vector3(.25,.10,0),1.55,.018,black,.10)
	sheath.rotation.z=-.10
	var blade:=_curved_piece(root,"BladeEdgeStudy",Vector3(-.15,.14,.02),1.48,.020,steel,.055)
	blade.rotation.z=.07
	fittings.append(box(root,"ScabbardMouth",Vector3(.18,.11,.055),Vector3(.22,.12,.01),warm))
	fittings.append(box(root,"ScabbardTip",Vector3(.16,.12,.055),Vector3(.52,-1.16,.01),warm))
	var grip:=box(root,"PaleGrip",Vector3(.16,.42,.08),Vector3(-.22,.45,.02),pale)
	grip.rotation.z=.08
	fittings.append(box(root,"WarmGuard",Vector3(.38,.055,.08),Vector3(-.20,.24,.02),warm))
	return root

func _build_compact_pair(parent: Node3D) -> void:
	var steel:=mat(Color("686762"),.32,.80)
	var warm:=mat(Color("b78c46"),.36,.66)
	var pale:=mat(Color("d6c8aa"),.78,.02)
	for i in range(2):
		var root:=Node3D.new()
		root.name="CompactSidearmStudy%d"%i
		root.position=Vector3(-.70+.46*i,-.43,.04)
		root.rotation.z=(-.06 if i==0 else .07)
		parent.add_child(root)
		blades.append(root)
		var blade:=box(root,"CompactBlade",Vector3(.08,.72,.035),Vector3(0,-.27,0),steel)
		blade.rotation.z=.05*(-1 if i==0 else 1)
		var grip:=box(root,"PaleCurvedGrip",Vector3(.15,.30,.075),Vector3(.05,.25,0),pale)
		grip.rotation.z=.13*(-1 if i==0 else 1)
		fittings.append(box(root,"WarmMount",Vector3(.20,.08,.08),Vector3(.02,.08,0),warm))

func build(chapter: Node3D) -> void:
	name="GujranwalaArmsCraftNiche"
	set_meta("classification","direct-craft-arms-display")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)

	var root:=Node3D.new()
	root.name="HouseholdArmsCraftNiche"
	root.position=Vector3(18.72,1.62,8.4)
	root.rotation.y=-PI/2
	add_child(root)
	display_roots.append(root)

	var timber:=mat(Color("4d3d30"),.88,.06)
	var plaster:=mat(Color("b39f80"),.96,0)
	var cloth:=mat(Color("7e4d45"),.98,0)
	box(root,"BackingPanel",Vector3(2.65,2.55,.08),Vector3(0,0,.05),timber)
	box(root,"UpperPlasterFrame",Vector3(2.85,.16,.12),Vector3(0,1.34,.02),plaster)
	box(root,"LowerPlasterFrame",Vector3(2.85,.16,.12),Vector3(0,-1.34,.02),plaster)

	_build_longarm(root,"LongarmStudyLeft",Vector3(-.72,.05,-.02),-1.0)
	_build_longarm(root,"LongarmStudyRight",Vector3(.72,.05,-.02),1.0)
	_build_sheathed_sabre(root)
	_build_compact_pair(root)

	var tray:=box(root,"MaintenanceTray",Vector3(1.05,.08,.32),Vector3(0,-1.06,-.06),mat(Color("6a523c"),.90,0))
	tray.rotation.x=.02
	for i in range(3):
		fittings.append(cylinder(root,"SmallFitting%d"%i,.045+.008*i,.055,Vector3(-.28+.28*i,-.99,-.12),mat(Color("a67c3e"),.42,.55),10))
	var folded:=box(root,"RepairCloth",Vector3(.46,.08,.28),Vector3(.72,-1.02,-.10),cloth)
	folded.rotation.z=.04
	repair_cloth.append(folded)

func set_enabled(value: bool) -> void:
	enabled=value
	visible=value

func sample(tick: int) -> void:
	var t: float=float(tick)/60.0
	for i in range(repair_cloth.size()):
		repair_cloth[i].rotation.z=.035*sin(t*.42+i*.7)
