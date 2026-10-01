# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Six deliberately non-random architectural/material exceptions.
## Presentation only: no collision, route, economy, journal or historical-evidence authority.
var records: Array[Dictionary]=[]
var anchor_nodes: Dictionary={}
var _materials: Dictionary={}

func mat(color: Color) -> StandardMaterial3D:
	var key: String=color.to_html()
	if _materials.has(key): return _materials[key]
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.98
	_materials[key]=material;return material

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var cube:=BoxMesh.new();cube.size=size
	mesh.name=name;mesh.mesh=cube;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=12
	mesh.name=name;mesh.mesh=shape;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh

func ring(parent: Node3D,name: String,inner: float,outer: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var shape:=TorusMesh.new();shape.inner_radius=inner;shape.outer_radius=outer;shape.rings=12;shape.ring_segments=8
	mesh.name=name;mesh.mesh=shape;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh

func remember(id: String,node: Node3D,meaning: String,reference_logic: String) -> void:
	node.set_meta("memory_anchor_id",id);node.set_meta("randomizable",false);node.set_meta("historical_claim",false)
	anchor_nodes[id]=node
	records.append({"id":id,"node_path":str(node.get_path()),"meaning":meaning,"reference_logic":reference_logic,
		"randomizable":false,"historical_claim":false,"gameplay_authority":false,"preserve_near_lod":true})

func build(street: Node3D) -> void:
	name="BazaarMemoryAnchors";set_meta("classification","direct-craft-memory-anchors")
	if street.thresholds.size()<8 or street.upper_screens.size()<8 or street.drains.size()<2:
		push_error("Memory anchors require the complete authored street section.");return

	# 1. Threshold polished by repeated hand/foot contact: one side only.
	var threshold_parent: Node3D=street.thresholds[1].get_parent()
	var polish:=box(threshold_parent,"ThresholdHandPolish",Vector3(.42,.014,.30),Vector3(.62,.194,-.47),Color("c0a37b"))
	remember("threshold_hand_polish",polish,"One habitual side of the threshold reads smoother/lighter than the rest.","B-tier continuity photographs support threshold/use wear; placement is fictional direct craft.")

	# 2. One screen slat has newer wood and a slightly different section.
	var screen_parent: Node3D=street.upper_screens[2].get_parent()
	var replacement:=box(screen_parent,"ReplacementScreenSlat",Vector3(.065,.66,.062),Vector3(.36,3.03,-.018),Color("8b6a49"))
	remember("screen_repair",replacement,"A replaced screen member remains visibly newer instead of perfectly matched.","B-tier architectural continuity supports repair/replace vocabulary; exact repair is fictional.")

	# 3. A short drain repair uses a different stone/material age.
	var drain: MeshInstance3D=street.drains[0]
	var patch:=box(self,"ReplacedDrainStone",Vector3(.24,.038,1.15),drain.position+Vector3(0,.018,0),Color("7d7060"));patch.rotation.y=drain.rotation.y
	remember("drain_replacement",patch,"A short drainage repair interrupts otherwise continuous edge wear.","Street photographs motivate drainage/repair language; no claim this exact repair existed.")

	# 4. Tether post with two localized rope-contact grooves.
	var tether_parent: Node3D=street.thresholds[3].get_parent()
	var post:=cylinder(tether_parent,"TetherPost",.105,1.15,Vector3(1.32,.575,-.44),Color("6b5138"))
	var groove_a:=ring(tether_parent,"TetherGrooveA",.096,.108,Vector3(1.32,.63,-.44),Color("3d3025"));groove_a.rotation.x=PI/2
	var groove_b:=ring(tether_parent,"TetherGrooveB",.096,.108,Vector3(1.32,.70,-.44),Color("3d3025"));groove_b.rotation.x=PI/2
	post.set_meta("associated_grooves",[groove_a.get_path(),groove_b.get_path()])
	remember("tether_groove",post,"The tether point is worn in two narrow bands rather than uniformly distressed.","Daily-life animal references motivate localized rope wear; placement is fictional.")

	# 5. Uneven hand-cut measuring marks on one shop edge.
	var measure_parent: Node3D=street.thresholds[5].get_parent()
	var marks:=Node3D.new();marks.name="MeasuringNotches";measure_parent.add_child(marks)
	for i in range(6):
		var x: float=-.48+float(i)*.18
		var depth: float=.045+float(i%3)*.012
		var notch:=box(marks,"Notch_%d"%i,Vector3(.018,.018,depth),Vector3(x,.199,-.565),Color("47382b"));notch.rotation.y=.08*float((i%2)*2-1)
	remember("measuring_notches",marks,"A short sequence of irregular marks records repeated measuring at one working edge.","Market/occupation corpus supports edge work; meaning remains deliberately modest and fictional.")

	# 6. One upper facade patch remains a different plaster age.
	var plaster_parent: Node3D=street.upper_screens[6].get_parent()
	var plaster:=box(plaster_parent,"LaterPlasterPatch",Vector3(.62,.42,.018),Vector3(-.48,3.12,-.012),Color("c2ad8a"));plaster.rotation.z=.018
	remember("plaster_patch",plaster,"A later repair remains legible instead of being normalized into one perfect facade material.","B-tier surviving architecture supports layered repairs; exact patch is fictional.")

func record(id: String) -> Dictionary:
	for entry in records:
		if entry.id==id:return entry.duplicate(true)
	return {}
