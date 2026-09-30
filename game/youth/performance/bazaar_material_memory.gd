# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Hand-authored object wear and repair. Decorative only: no inventory, collision or evidence authority.
const Dialogue:=preload("res://youth/performance/bazaar_material_dialogue.gd")
var details: Array[Dictionary]=[]
var _materials: Dictionary={}
func mat(color: Color,roughness:=.96) -> StandardMaterial3D:
	var key:=color.to_html()+":"+str(roughness)
	if _materials.has(key):return _materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=roughness;_materials[key]=m;return m
func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=size;mesh.mesh=b;mesh.name=name;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh
func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments:=12) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=height;c.radial_segments=segments
	mesh.mesh=c;mesh.name=name;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh
func ring(parent: Node3D,name: String,inner: float,outer: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var t:=TorusMesh.new();t.inner_radius=inner;t.outer_radius=outer;t.rings=16;t.ring_segments=10
	mesh.mesh=t;mesh.name=name;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh
func build() -> void:
	name="HandWorkedLives";set_meta("classification","original-fictional-material-memory")
	_build_basket();_build_cloth();_build_cup()
func add_detail(id: String,position: Vector3,focus: Vector3,root: Node3D) -> void:
	var record:=Dialogue.record(id);record.merge({"id":id,"position":position,"focus":focus,"root":root})
	details.append(record)
func _build_basket() -> void:
	var root:=Node3D.new();root.name="PaleRepairBasket";root.position=Vector3(-21.25,0,-12.05);add_child(root)
	for y in [.12,.22,.32,.42]:
		var r:=ring(root,"OldWickerRing",.25,.285,Vector3(0,y,0),Color("765b39"));r.rotation.x=PI/2
	for i in range(8):
		var a:=float(i)/8*TAU
		var strip:=box(root,"OldWeave",Vector3(.035,.48,.055),Vector3(cos(a)*.255,.25,sin(a)*.255),Color("6b5135"));strip.rotation.y=-a
	for i in range(3):
		var pale:=box(root,"PaleRepair"+str(i),Vector3(.045,.37,.06),Vector3(.235-i*.012,.26,-.11+i*.105),Color("b99d6b"));pale.rotation.z=.08*(i-1)
	var handle:=ring(root,"HandPolishedHandle",.30,.325,Vector3(0,.53,0),Color("a88758"));handle.rotation.x=PI/2
	for i in range(3):box(root,"SavedOffcut",Vector3(.18,.025,.035),Vector3(-.10+i*.10,.035,.22),Color("b99d6b")).rotation.y=.2*i
	add_detail("pale_repair",root.position,root.position+Vector3(0,.34,0),root)
func _build_cloth() -> void:
	var root:=Node3D.new();root.name="HiddenColourCloth";root.position=Vector3(-19.8,.76,-12.15);add_child(root)
	var colors=[Color("9e664a"),Color("59756b"),Color("b39b6e")]
	for i in range(3):
		box(root,"Fold"+str(i),Vector3(.72,.055,.43),Vector3(0,i*.06,0),colors[i])
	box(root,"FadedEdge",Vector3(.72,.012,.07),Vector3(0,.145,-.18),Color("c2aa82"))
	for i in range(9):
		var stitch:=box(root,"RepairStitch"+str(i),Vector3(.025,.015,.065),Vector3(-.28+i*.07,.178,-.02),Color("ded2ad"));stitch.rotation.y=.18
	for i in range(2):
		cylinder(root,"ThreadSpool"+str(i),.055,.12,Vector3(.46,.06+i*.03,.12-i*.22),[Color("d4c79f"),Color("6f7d68")][i],10).rotation.z=PI/2
	add_detail("hidden_colour",root.position,root.position+Vector3(0,.12,0),root)
func _build_cup() -> void:
	var root:=Node3D.new();root.name="KeptPlace";root.position=Vector3(-15.55,.58,-14.65);add_child(root)
	box(root,"Board",Vector3(1.25,.08,.54),Vector3(0,0,0),Color("624831"))
	for i in range(3):
		var stain:=ring(root,"OldCupRing"+str(i),.085,.095,Vector3(-.32+i*.28,.048,.04 if i%2==0 else -.06),Color("3f342a"));stain.rotation.x=PI/2
	var cup:=cylinder(root,"NickedCup",.105,.23,Vector3(.34,.15,.02),Color("a58b68"),16)
	var inside:=cylinder(root,"CupInterior",.086,.008,Vector3(.34,.269,.02),Color("443a32"),16)
	box(root,"RimNick",Vector3(.055,.03,.025),Vector3(.405,.273,-.055),Color("443a32")).rotation.y=.6
	var cloth:=box(root,"RolledCloth",Vector3(.46,.12,.16),Vector3(-.38,.11,-.10),Color("887159"));cloth.rotation.y=.18
	add_detail("kept_place",root.position,root.position+Vector3(.25,.15,0),root)
func nearest(position: Vector3,max_distance:=1.9) -> Dictionary:
	var best: Dictionary={};var distance:=max_distance
	for detail in details:
		var d:=position.distance_to(detail.position)
		if d<distance:distance=d;best=detail
	return best.duplicate(true)
func record(id: String) -> Dictionary:
	for detail in details:
		if detail.id==id:return detail.duplicate(true)
	return {}
