# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Reversible Gujranwala beauty layer. Presentation only; never gameplay or historical authority.
const CONTRACT_PATH := "res://data/art/gujranwala_beauty.v1.json"

var contract: Dictionary={}
var painted_spandrels: Array[MeshInstance3D]=[]
var jali_panels: Array[Node3D]=[]
var planted_tubs: Array[Node3D]=[]
var textile_drops: Array[MeshInstance3D]=[]
var threshold_lamps: Array[OmniLight3D]=[]
var well_stone_accents: Array[MeshInstance3D]=[]
var roofline_finials: Array[Node3D]=[]
var leaves: Array[MeshInstance3D]=[]
var _materials: Dictionary={}
var _chapter: Node3D
var _art: Node3D
var enabled:=true
var last_tick:=-1

func _material(key: String,color: Color,roughness: float=.96,emission: Color=Color.BLACK,energy: float=0.0) -> StandardMaterial3D:
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

func _box(parent: Node3D,name: String,size: Vector3,pos: Vector3,mat: Material) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=mat
	parent.add_child(mesh)
	return mesh

func _cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,mat: Material,segments: int=14) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=segments
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=mat
	parent.add_child(mesh)
	return mesh

func _sphere(parent: Node3D,name: String,size: Vector3,pos: Vector3,mat: Material) -> MeshInstance3D:
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
	mesh.material_override=mat
	parent.add_child(mesh)
	return mesh

func _load_contract() -> String:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not parsed is Dictionary: return "Missing Gujranwala beauty contract."
	if parsed.get("schema")!="1792.gujranwala-beauty.v1" or parsed.get("classification")!="original-authoring-study": return "Unknown beauty contract."
	if parsed.get("georeferenced")!=false or parsed.get("historically_verified")!=false: return "Beauty study cannot claim reconstruction authority."
	if not parsed.get("counts") is Dictionary or not parsed.get("palette") is Dictionary: return "Malformed beauty contract."
	contract=parsed.duplicate(true)
	return ""

func build(chapter: Node3D,art: Node3D) -> String:
	if not contract.is_empty(): return "Beauty layer already built."
	var error:=_load_contract()
	if not error.is_empty(): return error
	_chapter=chapter
	_art=art
	name="GujranwalaBeautyStudy"
	set_meta("classification","original-authoring-study")
	set_meta("historically_verified",false)
	set_meta("georeferenced",false)

	var lime:=_material("lime",Color(contract.palette.lime_plaster))
	var saffron:=_material("saffron",Color(contract.palette.faded_saffron))
	var green:=_material("green",Color(contract.palette.indigo_green))
	var timber:=_material("timber",Color(contract.palette.carved_timber))
	var stone:=_material("stone",Color(contract.palette.stone))
	var leaf_dark:=_material("leaf_dark",Color(contract.palette.leaf_dark))
	var leaf_light:=_material("leaf_light",Color(contract.palette.leaf_light))
	var cloth_a:=_material("cloth_a",Color("a97b56"))
	var cloth_b:=_material("cloth_b",Color("6f7c72"))
	var cloth_c:=_material("cloth_c",Color("c0ad82"))
	var glow:=_material("lamp_glow",Color("5e4934"),.72,Color(contract.palette.lamp_warm),1.3)

	# Eight shallow painted spandrels sit flush with the existing veranda bays.
	for i in range(8):
		var x: float=-14.875+float(i)*4.25
		var panel:=_box(self,"PaintedSpandrel%d"%i,Vector3(2.15,.24,.025),Vector3(x,2.86,11.78),saffron if i%3==0 else green if i%3==1 else lime)
		panel.rotation.z=.008*float((i%2)*2-1)
		painted_spandrels.append(panel)

	# Six nonblocking jali studies sit flush against existing side-wall faces.
	for side in [-1.0,1.0]:
		for j in range(3):
			var root:=Node3D.new()
			root.name="JaliStudy_%s_%d"%["L" if side<0 else "R",j]
			root.position=Vector3(side*19.72,2.05,-5.0+float(j)*5.1)
			root.rotation.y=PI/2
			add_child(root)
			for x in [-.48,-.24,0.0,.24,.48]:
				_box(root,"Vertical",Vector3(.035,1.18,.035),Vector3(x,0,0),timber)
			for y in [-.42,-.14,.14,.42]:
				_box(root,"Horizontal",Vector3(1.10,.035,.035),Vector3(0,y,0),timber)
			jali_panels.append(root)

	# Four planted tubs remain visually soft and close to perimeter walls.
	var tub_positions: Array[Vector3]=[Vector3(-15.8,.18,7.2),Vector3(15.6,.18,7.0),Vector3(-15.5,.18,-6.6),Vector3(15.4,.18,-6.8)]
	for i in range(4):
		var root:=Node3D.new()
		root.name="CourtyardPlant%d"%i
		root.position=tub_positions[i]
		add_child(root)
		_cylinder(root,"Tub",.34,.42,Vector3(0,.21,0),stone,16)
		_cylinder(root,"Stem",.055,1.15,Vector3(0,.88,0),timber,10)
		for k in range(7):
			var angle: float=float(k)/7.0*TAU
			var leaf:=_sphere(root,"Leaf%d"%k,Vector3(.22,.09,.12),Vector3(cos(angle)*.26,1.18+.05*(k%2),sin(angle)*.26),leaf_light if k%2 else leaf_dark)
			leaf.rotation.y=-angle
			leaves.append(leaf)
		planted_tubs.append(root)

	# Five textile drops add depth and color beneath the long veranda without closing passages.
	var cloths: Array[Material]=[cloth_a,cloth_b,cloth_c,cloth_b,cloth_a]
	for i in range(5):
		var cloth:=_box(self,"VerandaTextile%d"%i,Vector3(.58,.95,.025),Vector3(-8.5+float(i)*4.2,2.06,11.69),cloths[i])
		textile_drops.append(cloth)

	# Four tiny threshold lamps are bounded presentation lights, strongest only in evening preset.
	for x in [-12.75,-4.25,4.25,12.75]:
		var root:=Node3D.new()
		root.name="ThresholdLamp"
		root.position=Vector3(x,2.28,11.55)
		add_child(root)
		_box(root,"Bracket",Vector3(.08,.30,.08),Vector3(0,.08,0),timber)
		_sphere(root,"LampBody",Vector3(.12,.16,.12),Vector3(0,-.12,-.08),glow)
		var light:=OmniLight3D.new()
		light.name="WarmThresholdGlow"
		light.position=Vector3(0,-.12,-.10)
		light.light_color=Color(contract.palette.lamp_warm)
		light.light_energy=0.0
		light.omni_range=3.8
		light.shadow_enabled=false
		root.add_child(light)
		threshold_lamps.append(light)

	# Eight small stone accents around the existing household well increase material contrast only.
	var well: Node3D=chapter.fabric.get_node_or_null("household_well")
	if well!=null:
		for i in range(8):
			var angle: float=float(i)/8.0*TAU
			var accent:=_box(well,"WellStoneAccent%d"%i,Vector3(.31,.08,.16),Vector3(cos(angle)*.80,.52,sin(angle)*.80),stone)
			accent.rotation.y=-angle
			well_stone_accents.append(accent)

	# Six low finials break the roofline without introducing traversable height.
	for i in range(6):
		var root:=Node3D.new()
		root.name="RooflineFinial%d"%i
		root.position=Vector3(-15.5+float(i)*6.2,4.05,11.62)
		add_child(root)
		_cylinder(root,"Base",.11,.18,Vector3.ZERO,stone,12)
		_sphere(root,"Cap",Vector3(.17,.12,.17),Vector3(0,.15,0),lime)
		roofline_finials.append(root)

	set_enabled(true)
	sample(int(chapter.model.progress().tick),String(art.get("preset")))
	return ""

func set_enabled(value: bool) -> void:
	enabled=value
	visible=value
	for light in threshold_lamps:
		if is_instance_valid(light) and not value: light.light_energy=0.0

func sample(tick: int,preset: String) -> void:
	if tick<0: return
	last_tick=tick
	if not enabled: return
	var t: float=float(tick)/60.0
	for i in range(textile_drops.size()):
		textile_drops[i].rotation.z=sin(t*.72+float(i)*.71)*.018
	for i in range(leaves.size()):
		leaves[i].rotation.z=sin(t*.54+float(i)*.37)*.025
	var target_energy: float=.0
	if preset=="golden_hour": target_energy=.22
	elif preset=="evening": target_energy=.72
	for i in range(threshold_lamps.size()):
		threshold_lamps[i].light_energy=target_energy*(.96+.04*sin(t*2.7+float(i)))

func report() -> Dictionary:
	return {
		"schema":"1792.gujranwala-beauty-observation.v1",
		"enabled":enabled,
		"sampled_tick":last_tick,
		"painted_spandrels":painted_spandrels.size(),
		"jali_panels":jali_panels.size(),
		"planted_tubs":planted_tubs.size(),
		"textile_drops":textile_drops.size(),
		"threshold_lamps":threshold_lamps.size(),
		"well_stone_accents":well_stone_accents.size(),
		"roofline_finials":roofline_finials.size(),
		"historically_verified":false,
		"georeferenced":false,
		"gameplay_authority":false
	}
