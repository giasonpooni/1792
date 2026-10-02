# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Reversible Gujranwala beauty pass. Appearance only: no collision, navigation, economy or save authority.
var accent_panels: Array[MeshInstance3D]=[]
var screens: Array[Node3D]=[]
var planters: Array[Node3D]=[]
var pottery: Array[MeshInstance3D]=[]
var textiles: Array[MeshInstance3D]=[]
var practicals: Array[OmniLight3D]=[]
var foliage: Array[MeshInstance3D]=[]
var _materials: Dictionary={}
var preset: String="daylight"
var enabled := true

func surface(color: Color,roughness: float=.96,metallic: float=0.0,emission: Color=Color.BLACK,energy: float=0.0) -> StandardMaterial3D:
	var key: String=color.to_html()+":"+str(roughness)+":"+str(metallic)+":"+emission.to_html()+":"+str(energy)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
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
	mesh.material_override=surface(color)
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
	mesh.material_override=surface(color)
	parent.add_child(mesh)
	return mesh

func sphere(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=14
	shape.rings=8
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.scale=size
	mesh.material_override=surface(color)
	parent.add_child(mesh)
	return mesh

func torus(parent: Node3D,name: String,inner: float,outer: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=TorusMesh.new()
	shape.inner_radius=inner
	shape.outer_radius=outer
	shape.rings=16
	shape.ring_segments=10
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=surface(color)
	parent.add_child(mesh)
	return mesh

func build(chapter: Node3D) -> void:
	name="GujranwalaBeautyPass"
	set_meta("classification","direct-craft-beauty-pass")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	_build_veranda_accents()
	_build_garden_pockets()
	_build_market_still_life()
	_build_practicals()
	set_preset("daylight")
	sample(int(chapter.model.progress().tick))

func _build_veranda_accents() -> void:
	var root:=Node3D.new()
	root.name="VerandaBeauty"
	add_child(root)
	for i in range(8):
		var x: float=-14.875+float(i)*4.25
		accent_panels.append(box(root,"PaintedBand%d"%i,Vector3(3.15,.13,.035),Vector3(x,3.03,11.72),Color("b78f66")))
		accent_panels.append(box(root,"InsetField%d"%i,Vector3(2.55,.52,.025),Vector3(x,2.66,11.70),Color("c7b394")))
		var screen:=Node3D.new()
		screen.name="JaliDepth%d"%i
		screen.position=Vector3(x,1.60,11.67)
		root.add_child(screen)
		screens.append(screen)
		for sx in [-.72,-.48,-.24,0.0,.24,.48,.72]:
			box(screen,"Vertical",Vector3(.035,1.02,.035),Vector3(sx,0,0),Color("70563f"))
		for sy in [-.36,-.12,.12,.36]:
			box(screen,"Horizontal",Vector3(1.55,.035,.035),Vector3(0,sy,0),Color("70563f"))
		var medallion:=torus(screen,"Medallion",.13,.17,Vector3(0,0,-.025),Color("9d7451"))
		medallion.rotation.x=PI/2

func _build_garden_pockets() -> void:
	var positions: Array[Vector3]=[
		Vector3(-18.0,.14,9.2),Vector3(-18.0,.14,0.0),Vector3(18.0,.14,10.5),
		Vector3(18.0,.14,1.5),Vector3(-18.0,.14,-10.0),Vector3(18.0,.14,-9.0)]
	for i in range(positions.size()):
		var root:=Node3D.new()
		root.name="GardenPocket%d"%i
		root.position=positions[i]
		add_child(root)
		planters.append(root)
		cylinder(root,"LowPlanter",.62,.22,Vector3(0,.11,0),Color("8d7254"),18)
		cylinder(root,"Soil",.53,.05,Vector3(0,.245,0),Color("514434"),18)
		for j in range(3):
			var angle: float=float(j)/3.0*TAU+float(i)*.33
			var stalk:=cylinder(root,"Stalk%d"%j,.035,.66,Vector3(cos(angle)*.18,.56,sin(angle)*.18),Color("58704e"),10)
			stalk.rotation.z=.05*sin(angle)
			foliage.append(sphere(root,"LeafMass%d"%j,Vector3(.45,.34,.38),Vector3(cos(angle)*.22,.89,sin(angle)*.22),Color("667d57") if (i+j)%2==0 else Color("738561")))
		for j in range(3):
			foliage.append(sphere(root,"Flower%d"%j,Vector3(.08,.06,.08),Vector3(-.18+.18*j,.96,.16-.11*j),Color("aa6c52") if i%2==0 else Color("c19a65")))

func _build_market_still_life() -> void:
	var root:=Node3D.new()
	root.name="MarketBeauty"
	add_child(root)
	var pot_positions: Array[Vector3]=[
		Vector3(-26.1,1.15,-17.75),Vector3(-25.55,1.10,-17.92),Vector3(-24.95,1.13,-17.72),
		Vector3(-24.25,1.08,-17.94),Vector3(-23.58,1.14,-17.70),Vector3(-22.95,1.07,-17.90)]
	for i in range(pot_positions.size()):
		pottery.append(cylinder(root,"Vessel%d"%i,.16+.025*(i%3),.30+.05*(i%2),pot_positions[i],Color("9f704c") if i%2==0 else Color("7d6b58"),16))
		var rim:=torus(root,"Rim%d"%i,.13+.02*(i%3),.16+.02*(i%3),pot_positions[i]+Vector3.UP*(.17+.025*(i%2)),Color("b7865b"))
		rim.rotation.x=PI/2
	for i in range(3):
		textiles.append(box(root,"FoldedTextile%d"%i,Vector3(.70,.08,.42),Vector3(-24.65+i*.55,1.08+i*.085,-18.15),[Color("9f694f"),Color("66786e"),Color("b49b6a")][i]))
	var hanging:=box(root,"HangingTextile",Vector3(.48,.92,.025),Vector3(-22.55,2.02,-18.18),Color("93614d"))
	hanging.rotation.z=.03
	textiles.append(hanging)
	cylinder(root,"LowBasin",.36,.10,Vector3(-17.4,.19,8.9),Color("786b5a"),20)
	var water:=cylinder(root,"WaterSurface",.31,.015,Vector3(-17.4,.25,8.9),Color("667f86"),20)
	water.material_override=surface(Color("6f8f96"),.18,.10)

func _build_practicals() -> void:
	var positions: Array[Vector3]=[Vector3(-12.75,2.25,10.9),Vector3(-4.25,2.25,10.9),Vector3(4.25,2.25,10.9),Vector3(12.75,2.25,10.9)]
	for i in range(positions.size()):
		var lamp:=OmniLight3D.new()
		lamp.name="WarmPractical%d"%i
		lamp.position=positions[i]
		lamp.light_color=Color("ffd09c")
		lamp.light_energy=0.0
		lamp.omni_range=3.4
		lamp.shadow_enabled=false
		add_child(lamp)
		var glow:=sphere(lamp,"LampGlow",Vector3(.12,.12,.12),Vector3.ZERO,Color("be7545"))
		glow.material_override=surface(Color("9d5c36"),.9,0,Color("ffae68"),1.4)
		practicals.append(lamp)

func set_preset(id: String) -> void:
	preset=id
	var energy: float={"daylight":0.0,"golden_hour":.28,"evening":.72}.get(id,0.0)
	for lamp in practicals:
		lamp.light_energy=energy
		lamp.visible=enabled and energy>0.0

func set_enabled(value: bool) -> void:
	enabled=value
	visible=value
	for lamp in practicals:
		lamp.visible=value and lamp.light_energy>0.0

func sample(tick: int) -> void:
	var t: float=float(tick)/60.0
	for i in range(textiles.size()):
		textiles[i].rotation.z=(.018+.008*(i%2))*sin(t*.55+i*.9)
	for i in range(foliage.size()):
		foliage[i].rotation.z=.018*sin(t*.72+i*.37)
	for i in range(planters.size()):
		planters[i].rotation.y=.003*sin(t*.21+i)
