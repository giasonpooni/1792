# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original visual vignettes along the existing market-to-confrontation walk.
## No collision, navigation, inventory, testimony, AI schedule or historical-site claim.
const Brawl:=preload("res://youth/brawl_rules.gd")
var merchant: Node3D
var helper: Node3D
var animal: Node3D
var animal_head: Node3D
var animal_tail: Node3D
var cart: Node3D
var cart_wheels: Array[MeshInstance3D]=[]
var cloth_bundle: Node3D
var _materials: Dictionary={}

func material(color: Color,roughness: float=.95) -> StandardMaterial3D:
	var key:=color.to_html()+":"+str(roughness)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=roughness;_materials[key]=m;return m

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name;var b:=BoxMesh.new();b.size=size
	mesh.mesh=b;mesh.position=pos;mesh.material_override=material(color);parent.add_child(mesh);return mesh

func sphere(parent: Node3D,name: String,scale: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name;var s:=SphereMesh.new();s.radius=.5;s.height=1;s.radial_segments=10;s.rings=6
	mesh.mesh=s;mesh.scale=scale;mesh.position=pos;mesh.material_override=material(color);parent.add_child(mesh);return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name;var c:=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=height;c.radial_segments=10
	mesh.mesh=c;mesh.position=pos;mesh.material_override=material(color);parent.add_child(mesh);return mesh

func person(name: String,pos: Vector3,coat: Color,cloth: Color) -> Node3D:
	var root:=Node3D.new();root.name=name;root.position=pos;add_child(root)
	cylinder(root,"Body",.21,1.02,Vector3(0,.69,0),coat)
	sphere(root,"Head",Vector3(.38,.46,.38),Vector3(0,1.40,0),Color("a77f60"))
	cylinder(root,"HeadCloth",.22,.13,Vector3(0,1.61,0),cloth)
	var arm:=Node3D.new();arm.name="WorkingArm";arm.position=Vector3(.24,1.03,0);root.add_child(arm)
	var upper:=cylinder(arm,"UpperArm",.055,.34,Vector3(0,-.17,0),coat);upper.rotation.z=-.14
	var fore:=cylinder(arm,"Forearm",.05,.31,Vector3(.05,-.43,-.02),cloth);fore.rotation.z=-.38
	sphere(arm,"Hand",Vector3(.12,.14,.12),Vector3(.11,-.61,-.02),Color("a77f60"))
	return root

func build() -> void:
	name="BazaarInhabitedApproach";set_meta("classification","original-prototype-ambient-vignettes")
	# Goods handling, offset from the walking line between the existing market and confrontation.
	merchant=person("BasketMerchantStudy",Vector3(-21.7,0,-10.9),Color("765d49"),Color("ae8f68"))
	merchant.rotation.y=-1.1
	helper=person("ClothHelperStudy",Vector3(-20.3,0,-11.5),Color("66766c"),Color("c2ae8a"))
	helper.rotation.y=1.15
	for i in range(4):
		var basket:=cylinder(self,"ApproachBasket"+str(i),.28,.30,Vector3(-21.35+i*.45,.15,-12.0),Color("846842"))
		basket.rotation.x=PI/2
	cloth_bundle=Node3D.new();cloth_bundle.name="FoldedClothStudy";cloth_bundle.position=Vector3(-20.75,.82,-11.75);add_child(cloth_bundle)
	for i in range(3): box(cloth_bundle,"Fold"+str(i),Vector3(.62,.07,.36),Vector3(0,i*.065,0),[Color("ad7553"),Color("70887b"),Color("bca77d")][i])
	# Tethered pack-animal silhouette: visual study only, outside the physical lane.
	animal=Node3D.new();animal.name="TetheredPackAnimalStudy";animal.position=Vector3(-17.9,0,-14.0);animal.rotation.y=.65;add_child(animal)
	sphere(animal,"Body",Vector3(1.15,.72,.50),Vector3(0,1.02,0),Color("5f4937"))
	var neck:=cylinder(animal,"Neck",.16,.72,Vector3(.66,1.35,-.03),Color("5f4937"));neck.rotation.z=-.62
	animal_head=Node3D.new();animal_head.name="Head";animal_head.position=Vector3(.92,1.62,-.03);animal.add_child(animal_head)
	sphere(animal_head,"Skull",Vector3(.50,.38,.34),Vector3.ZERO,Color("604938"))
	for z in [-.13,.13]: box(animal_head,"Ear",Vector3(.08,.24,.07),Vector3(.02,.22,z),Color("4e3d30"))
	for x in [-.62,.62]:
		for z in [-.27,.27]:
			var leg:=cylinder(animal,"Leg",.065,.86,Vector3(x,.47,z),Color("4b3b2f"));leg.rotation.z=.02*x
	animal_tail=Node3D.new();animal_tail.name="Tail";animal_tail.position=Vector3(-1.05,1.20,0);animal.add_child(animal_tail)
	var tail:=box(animal_tail,"TailVisual",Vector3(.08,.62,.08),Vector3(-.02,-.28,0),Color("3e3129"));tail.rotation.z=.25
	box(self,"TetherPost",Vector3(.10,1.25,.10),Vector3(-16.85,.625,-13.35),Color("4b392a"))
	var tether:=box(self,"TetherStudy",Vector3(1.45,.025,.025),Vector3(-17.35,.88,-13.55),Color("645341"));tether.rotation.y=-.36
	# Cart/loading edge creates a final layer before the confrontation but remains outside it.
	cart=Node3D.new();cart.name="StationaryCartStudy";cart.position=Vector3(-14.7,0,-15.0);cart.rotation.y=-.18;add_child(cart)
	box(cart,"Bed",Vector3(2.45,.30,1.08),Vector3(0,.75,0),Color("674c35"))
	for x in [-.92,.92]:
		var wheel:=MeshInstance3D.new();wheel.name="Wheel";var c:=CylinderMesh.new();c.top_radius=.52;c.bottom_radius=.52;c.height=.10;c.radial_segments=14
		wheel.mesh=c;wheel.position=Vector3(x,.52,.59);wheel.rotation.x=PI/2;wheel.material_override=material(Color("3f3329"));cart.add_child(wheel);cart_wheels.append(wheel)
		var opposite:=wheel.duplicate();opposite.position.z=-.59;cart.add_child(opposite);cart_wheels.append(opposite)
	for i in range(3): sphere(cart,"LoadSack"+str(i),Vector3(.62,.48,.44),Vector3(-.65+i*.65,1.08,0),Color("9a8668"))

func sample(tick: int,phase: String) -> void:
	var t:=float(tick)/60.0
	var pre_conflict:=phase in ["invited","challenged"]
	var work:=1.0 if pre_conflict else .45
	merchant.rotation.z=.018*sin(t*1.1)
	helper.rotation.z=-.015*sin(t*.95+.8)
	var merchant_arm: Node3D=merchant.get_node("WorkingArm");merchant_arm.rotation=Vector3(-.22-.18*sin(t*1.4)*work,0,.12*sin(t*.7))
	var helper_arm: Node3D=helper.get_node("WorkingArm");helper_arm.rotation=Vector3(-.35-.12*sin(t*1.1+.9)*work,0,-.10*sin(t*.8))
	cloth_bundle.rotation.y=.025*sin(t*.5)
	animal_head.rotation=Vector3(.025*sin(t*.8),.13*sin(t*.36),.035*sin(t*.52))
	animal_tail.rotation.z=.22*sin(t*.92)+.12
	for i in range(cart_wheels.size()): cart_wheels[i].rotation.y=.018*sin(t*.35+i)
	# Nobody flees or starts a simulation when fighting begins; background work simply stills.
	if phase=="fighting":
		merchant_arm.rotation.x=-.18;helper_arm.rotation.x=-.20
