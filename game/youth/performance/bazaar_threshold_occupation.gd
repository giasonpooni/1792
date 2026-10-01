# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Site-specific threshold occupation. Presentation only: no navigation, economy, AI or save authority.
var records: Array[Dictionary]=[]
var roots: Dictionary={}
var mender_hand: Node3D
var clerk_hand: Node3D
var water_cover: Node3D
var _materials: Dictionary={}

func mat(color: Color) -> StandardMaterial3D:
	var key: String=color.to_html()
	if _materials.has(key): return _materials[key]
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=.98
	_materials[key]=material
	return material

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var cube:=BoxMesh.new()
	cube.size=size
	mesh.name=name
	mesh.mesh=cube
	mesh.position=pos
	mesh.material_override=mat(color)
	parent.add_child(mesh)
	return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments: int=12) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=segments
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=mat(color)
	parent.add_child(mesh)
	return mesh

func sphere(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=10
	shape.rings=6
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.scale=size
	mesh.material_override=mat(color)
	parent.add_child(mesh)
	return mesh

func ring(parent: Node3D,name: String,inner: float,outer: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=TorusMesh.new()
	shape.inner_radius=inner
	shape.outer_radius=outer
	shape.rings=12
	shape.ring_segments=8
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=mat(color)
	parent.add_child(mesh)
	return mesh

func remember(id: String,root: Node3D,kind: String,meaning: String,actor_present: bool) -> void:
	root.set_meta("threshold_habit_id",id)
	root.set_meta("gameplay_authority",false)
	root.set_meta("historical_claim",false)
	roots[id]=root
	records.append({
		"id":id,"kind":kind,"meaning":meaning,"actor_present":actor_present,
		"gameplay_authority":false,"historical_claim":false,
		"persistent_state":false,"randomizable":false
	})

func simple_seated_figure(parent: Node3D,name: String,pos: Vector3,coat: Color) -> Dictionary:
	var root:=Node3D.new()
	root.name=name
	root.position=pos
	parent.add_child(root)
	cylinder(root,"Torso",.19,.72,Vector3(0,.67,0),coat)
	sphere(root,"Head",Vector3(.19,.24,.19),Vector3(0,1.16,0),Color("a77f60"))
	cylinder(root,"LowerBody",.22,.42,Vector3(0,.27,0),Color("655c4d"))
	var hand:=Node3D.new()
	hand.name="WorkingHand"
	hand.position=Vector3(.20,.72,-.15)
	root.add_child(hand)
	cylinder(hand,"Forearm",.045,.30,Vector3(0,-.12,0),coat.lightened(.05))
	sphere(hand,"Hand",Vector3(.08,.09,.08),Vector3(0,-.30,0),Color("a77f60"))
	return {"root":root,"hand":hand}

func build(street: Node3D) -> void:
	name="BazaarThresholdOccupation"
	set_meta("classification","direct-craft-threshold-occupation")
	if street.thresholds.size()<8:
		push_error("Threshold occupation requires the complete authored street section.")
		return

	var mender_parent: Node3D=street.thresholds[0].get_parent()
	var mender_root:=Node3D.new()
	mender_root.name="ShadeMender"
	mender_root.position=Vector3(-.42,.18,.08)
	mender_parent.add_child(mender_root)
	box(mender_root,"PatchedMat",Vector3(.92,.025,.58),Vector3(0,.015,0),Color("8e7451"))
	box(mender_root,"MatPatch",Vector3(.24,.012,.18),Vector3(.26,.031,-.14),Color("b49a6e"))
	var mender:=simple_seated_figure(mender_root,"MenderFigure",Vector3(-.12,0,.05),Color("776654"))
	mender_hand=mender.hand
	box(mender_root,"WorkCloth",Vector3(.48,.035,.28),Vector3(.28,.34,-.08),Color("9c6f55"))
	var spool:=cylinder(mender_root,"ThreadSpool",.045,.10,Vector3(.43,.12,.16),Color("d2c399"),10)
	spool.rotation.z=PI/2
	remember("shade_mender",mender_root,"working_shade","A single worker habitually uses one shaded threshold for repair work rather than the open lane.",true)

	var water_parent: Node3D=street.thresholds[2].get_parent()
	var water_root:=Node3D.new()
	water_root.name="CoolingWaterPlace"
	water_root.position=Vector3(.36,.18,-.06)
	water_parent.add_child(water_root)
	var damp:=ring(water_root,"DampRing",.18,.205,Vector3(-.18,.018,.06),Color("4c473f"))
	damp.rotation.x=PI/2
	cylinder(water_root,"WaterJar",.18,.42,Vector3(-.18,.22,.06),Color("9b7752"),14)
	sphere(water_root,"WaterJarShoulder",Vector3(.22,.16,.22),Vector3(-.18,.44,.06),Color("9b7752"))
	water_cover=Node3D.new()
	water_cover.name="ClothCover"
	water_cover.position=Vector3(-.18,.55,.06)
	water_root.add_child(water_cover)
	box(water_cover,"Cover",Vector3(.34,.018,.34),Vector3.ZERO,Color("b8aa87"))
	cylinder(water_root,"InvertedCup",.075,.13,Vector3(.19,.09,.02),Color("8e7357"),12)
	remember("cooling_water_place",water_root,"object_habit","A shaded water vessel leaves a damp ring and an inverted cup; the user is absent.",false)

	var clerk_parent: Node3D=street.thresholds[4].get_parent()
	var clerk_root:=Node3D.new()
	clerk_root.name="CountingEdge"
	clerk_root.position=Vector3(.16,.18,.02)
	clerk_parent.add_child(clerk_root)
	box(clerk_root,"CountingBoard",Vector3(.72,.06,.42),Vector3(.12,.33,-.04),Color("69523b"))
	for i in range(3):
		cylinder(clerk_root,"Weight_%d"%i,.045+.012*i,.07,Vector3(-.08+.16*i,.39,-.03),Color("7d6c54"),10)
	cylinder(clerk_root,"WrappedWeight",.065,.075,Vector3(.48,.39,.02),Color("6e6253"),10)
	box(clerk_root,"WeightWrap",Vector3(.16,.035,.16),Vector3(.48,.43,.02),Color("9a8064"))
	var clerk:=simple_seated_figure(clerk_root,"CounterFigure",Vector3(-.30,0,.16),Color("5f6d68"))
	clerk_hand=clerk.hand
	remember("counting_edge",clerk_root,"working_edge","A counting surface and unequal weights occupy the edge while the central lane remains free.",true)

	var wait_parent: Node3D=street.thresholds[7].get_parent()
	var wait_root:=Node3D.new()
	wait_root.name="EmptyWaitingMat"
	wait_root.position=Vector3(-.18,.18,.04)
	wait_parent.add_child(wait_root)
	box(wait_root,"WaitingMat",Vector3(.95,.022,.48),Vector3(0,.012,0),Color("7f694a"))
	box(wait_root,"CompressedCorner",Vector3(.28,.010,.18),Vector3(-.29,.026,.11),Color("6a573f"))
	box(wait_root,"DifferentClothPatch",Vector3(.22,.012,.17),Vector3(.31,.027,-.10),Color("a98763"))
	var fold:=box(wait_root,"FoldedWrap",Vector3(.42,.12,.20),Vector3(.18,.10,.13),Color("766b5c"))
	fold.rotation.y=.10
	remember("empty_waiting_mat",wait_root,"unexplained_absence","One waiting place remains prepared but empty; the game does not explain who is expected.",false)

func activity_factor(phase: String) -> float:
	if phase=="fighting" or phase=="caught": return 0.0
	if phase=="challenged": return .18
	return 1.0

func sample(tick: int,phase: String) -> void:
	var t: float=float(tick)/60.0
	var work: float=activity_factor(phase)
	if is_instance_valid(mender_hand):
		mender_hand.rotation=Vector3(-.30+sin(t*3.1)*.24*work,0,.12*sin(t*1.7)*work)
	if is_instance_valid(clerk_hand):
		clerk_hand.rotation=Vector3(-.18+sin(t*2.2+1.2)*.18*work,.10*sin(t*.9)*work,0)
	if is_instance_valid(water_cover):
		water_cover.rotation.z=sin(t*.75)*.016

func activity_snapshot() -> Dictionary:
	return {
		"mender":mender_hand.rotation if is_instance_valid(mender_hand) else Vector3.ZERO,
		"clerk":clerk_hand.rotation if is_instance_valid(clerk_hand) else Vector3.ZERO,
		"cover":water_cover.rotation if is_instance_valid(water_cover) else Vector3.ZERO
	}

func record(id: String) -> Dictionary:
	for entry in records:
		if entry.id==id: return entry.duplicate(true)
	return {}
