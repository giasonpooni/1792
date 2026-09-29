# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original market-corner dressing for the existing bazaar story.
## Presentation only: no collision, navigation, economy, interaction or historical-site claim.
const Brawl := preload("res://youth/brawl_rules.gd")
var awnings: Array[MeshInstance3D]=[]
var hanging: Array[MeshInstance3D]=[]
var lamps: Array[OmniLight3D]=[]
var vendor_roots: Array[Node3D]=[]
var _materials: Dictionary={}

func mat(color: Color, roughness: float=.92, emission: Color=Color.BLACK, energy: float=0.0) -> StandardMaterial3D:
	var key: String=color.to_html()+":"+str(roughness)+":"+emission.to_html()+":"+str(energy)
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=roughness
	if energy>0:
		m.emission_enabled=true;m.emission=emission;m.emission_energy_multiplier=energy
	_materials[key]=m;return m

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name
	var b:=BoxMesh.new();b.size=size;mesh.mesh=b;mesh.position=pos;mesh.material_override=mat(color)
	parent.add_child(mesh);return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments: int=12) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=name
	var c:=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=height;c.radial_segments=segments
	mesh.mesh=c;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh

func cloth(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color,rotation_y: float=0.0) -> MeshInstance3D:
	var mesh:=box(parent,name,size,pos,color);mesh.rotation.y=rotation_y;awnings.append(mesh);return mesh

func build() -> void:
	name="BazaarMarketCraft"
	position=Brawl.RING
	set_meta("classification","original-prototype-market-dressing")
	# Two shallow stall fronts frame the confrontation without narrowing the physical route.
	for side in [-1,1]:
		var stall:=Node3D.new();stall.name="Stall"+str(side);stall.position=Vector3(side*5.25,0,-.6);add_child(stall)
		box(stall,"Counter",Vector3(2.4,.78,.8),Vector3(0,.39,0),Color("6f5138"))
		for x in [-1.0,1.0]: box(stall,"Post",Vector3(.14,2.55,.14),Vector3(x,1.275,-.28),Color("493728"))
		box(stall,"Beam",Vector3(2.25,.14,.14),Vector3(0,2.45,-.28),Color("493728"))
		var awning:=cloth(stall,"Awning",Vector3(2.55,.06,1.55),Vector3(0,2.20,.22),Color("a56b49") if side<0 else Color("6e7d70"),side*.035)
		awning.rotation.x=-.10
		for i in range(5):
			var bundle:=cylinder(stall,"Basket"+str(i),.21,.26,Vector3(-.82+i*.40,.90,-.08),Color("8f7146"),10)
			bundle.rotation.x=PI/2
		for i in range(4):
			var strip:=box(stall,"HangingCloth"+str(i),Vector3(.28,.70,.025),Vector3(-.75+i*.50,1.52,-.47),Color("b58a5d") if side<0 else Color("799487"))
			hanging.append(strip)
	# Low trade goods and carrying poles define layers in the sightline, but stay outside the encounter lane.
	for i in range(7):
		var angle:=float(i)/7.0*TAU
		var r:=6.5
		var p:=Vector3(cos(angle)*r,.16,sin(angle)*r*.62)
		cylinder(self,"StorageBasket"+str(i),.34,.32,p,Color("80643e"),12)
	for z in [-3.6,3.4]:
		box(self,"CarryingPole",Vector3(3.5,.09,.09),Vector3(0,1.55,z),Color("4c3929"))
		for x in [-1.45,1.45]:
			var sack:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.5;s.height=1;s.radial_segments=10;s.rings=6
			sack.mesh=s;sack.position=Vector3(x,1.20,z);sack.scale=Vector3(.52,.70,.38);sack.material_override=mat(Color("a28d6b"));add_child(sack)
	# Three deliberately generic ambient market silhouettes. They do not represent historical people or speak.
	for i in range(3):
		var root:=Node3D.new();root.name="AmbientMarketFigure"+str(i)
		root.position=[Vector3(-6.3,0,-2.7),Vector3(6.1,0,2.2),Vector3(-5.8,0,3.5)][i];add_child(root);vendor_roots.append(root)
		cylinder(root,"Body",.22,1.05,Vector3(0,.72,0),Color("78695a") if i!=1 else Color("5b706f"),12)
		var head:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.19;sphere.height=.38;sphere.radial_segments=10;sphere.rings=6
		head.mesh=sphere;head.position=Vector3(0,1.42,0);head.material_override=mat(Color("a77f60"));root.add_child(head)
		var cloth_head:=cylinder(root,"HeadCloth",.22,.14,Vector3(0,1.61,0),Color("a98c68") if i!=2 else Color("70837a"),12)
		cloth_head.rotation.z=.05
	# Warm points are visual emphasis only; intensity is intentionally small.
	for p in [Vector3(-5.1,2.05,-.8),Vector3(5.1,2.05,-.8)]:
		var lamp:=OmniLight3D.new();lamp.position=p;lamp.light_color=Color("ffd2a0");lamp.light_energy=.42;lamp.omni_range=3.0;add_child(lamp);lamps.append(lamp)
		var ember:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.055;sphere.height=.11;sphere.radial_segments=8;sphere.rings=4
		ember.mesh=sphere;ember.material_override=mat(Color("8f552f"),.8,Color("ff9e54"),1.7);lamp.add_child(ember)

func sample(tick: int,active: bool) -> void:
	var t:=float(tick)/60.0
	for i in range(awnings.size()):
		awnings[i].rotation.z=sin(t*.78+i*.61)*.018
	for i in range(hanging.size()):
		hanging[i].rotation.z=sin(t*1.15+i*.7)*.035
	for i in range(vendor_roots.size()):
		vendor_roots[i].rotation.y=sin(t*.20+i*1.8)*.08
		vendor_roots[i].position.y=sin(t*1.3+i)*.006
	for lamp in lamps: lamp.light_energy=(.50 if active else .36)+sin(t*3.1+lamp.position.x)*.025
