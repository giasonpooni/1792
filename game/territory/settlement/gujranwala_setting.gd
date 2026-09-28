extends Node3D
## Research-constrained feature vocabulary; every coordinate/dimension is authored.
## Static scene representation only: no gameplay authority, economy or character memory.
const RESEARCH_PATH := "res://territory/settlement/gujranwala_research.json"
var research: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RESEARCH_PATH))
const EARTH := preload("res://territory/settlement/earth_surface.gdshader")
const ID := "gujranwala-setting-geometry.v1"
const SEED := 179203
const STORE_DOOR := Vector3(10,0.14,7.3)
const STORE_INSIDE := Vector3(10,0.14,9.3)
const WELL := Vector3(-15.5,0.14,9)
const TROUGH := Vector3(15,0.14,-3)
var manifest: Dictionary={}
var _layout: Array=[]
var _environment: Environment
var haze_enabled := true
var _built := false
var _mud: ShaderMaterial

func build(chapter: Node3D) -> void:
	if _built: return
	_built=true
	_mud=ShaderMaterial.new()
	_mud.shader=EARTH
	_mud.set_shader_parameter("earth_color",Color("aa8058"))
	# Preserve the existing wall/camera/collision geometry while improving material.
	for child in chapter.get_children():
		for visual in child.get_children():
			if visual is MeshInstance3D and visual.mesh is BoxMesh:
				var size: Vector3=visual.mesh.size
				if size.is_equal_approx(Vector3(38,2.6,0.5)) or size.is_equal_approx(Vector3(0.5,2.6,19)):
					visual.material_override=_mud
	_store()
	_well()
	_trough()
	_market_details()
	_skyline()
	manifest={"id":ID,"seed":SEED,"research_id":research.id,
		"coordinate_basis":research.coordinate_basis,"surveyed":false,
		"layout_digest":JSON.stringify(_layout).sha256_text(),"pieces":_layout.size(),
		"traversable_interior":"household_store","horizon_is_playable":false}
	_environment=chapter.get_parent().get_node("WorldEnvironment").environment
	set_haze(true)
	chapter.get_parent().get_node("Sun").rotation_degrees=Vector3(-34,-42,0)
	chapter.get_parent().get_node("Sun").light_energy=0.9

func set_haze(enabled: bool) -> void:
	haze_enabled=enabled
	if _environment==null: return
	_environment.fog_enabled=enabled
	_environment.fog_density=0.0035
	_environment.fog_light_color=Color("b9aaa0")
	_environment.fog_sky_affect=0.15
	_environment.background_color=Color("adbbb8")

func _piece(id: String,size: Vector3,at: Vector3,color: Color,solid: bool=false,mud: bool=false) -> Node3D:
	var root: Node3D=StaticBody3D.new() if solid else Node3D.new()
	root.name=id
	root.position=at
	add_child(root)
	var visual:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	visual.mesh=mesh
	if mud: visual.material_override=_mud
	else:
		var material:=StandardMaterial3D.new()
		material.albedo_color=color
		material.roughness=0.95
		visual.material_override=material
	root.add_child(visual)
	if solid:
		var shape:=BoxShape3D.new()
		shape.size=size
		var collider:=CollisionShape3D.new()
		collider.shape=shape
		root.add_child(collider)
	_layout.append({"id":id,"size":[size.x,size.y,size.z],"position":[at.x,at.y,at.z],"solid":solid})
	return root

func _store() -> void:
	# Human-scale doorway in a U-shaped room; not the excavated footprint of a fort.
	_piece("StoreBack",Vector3(6,2.8,0.35),Vector3(10,1.5,11.25),Color.WHITE,true,true)
	for x in [7.15,12.85]:
		_piece("StoreSide"+str(x),Vector3(0.3,2.8,4),Vector3(x,1.5,9.3),Color.WHITE,true,true)
	for x in [8.0,12.0]:
		_piece("StoreFront"+str(x),Vector3(1.8,2.8,0.3),Vector3(x,1.5,7.3),Color.WHITE,true,true)
	_piece("StoreLintel",Vector3(2.2,0.25,0.38),Vector3(10,2.72,7.3),Color("62492f"),true)
	_piece("StoreRoof",Vector3(6.4,0.2,4.25),Vector3(10,3.0,9.3),Color("795b3c"),true)
	for x in [7.8,8.8,9.8,10.8,11.8,12.5]:
		_piece("RoofBeam"+str(x),Vector3(0.14,0.18,4.5),Vector3(x,2.84,9.3),Color("513c2c"))
	for i in range(6):
		_piece("StoreSack"+str(i),Vector3(0.7,0.6,0.6),Vector3(7.9+(i%2)*0.75,0.45,8.6+floori(i/2.0)*0.8),Color("baa376"),true)
	_piece("StoreRack",Vector3(0.45,1.0,2),Vector3(12.25,0.65,9.7),Color("654c33"),true)
	for i in range(5):
		_piece("StoredTimber"+str(i),Vector3(0.12,0.12,1.6),Vector3(12.2,1.1+i*0.12,9.7),Color("6a5034"))
	_label("Household store",Vector3(10,3.5,7.1))

func _well() -> void:
	# A closed central collider prevents falling through a decorative water surface.
	var body:=StaticBody3D.new()
	body.name="CourtyardWell"
	body.position=WELL
	add_child(body)
	var shape:=CylinderShape3D.new()
	shape.radius=1.1;shape.height=0.9
	var collider:=CollisionShape3D.new()
	collider.shape=shape;collider.position.y=0.45
	body.add_child(collider)
	_layout.append({"id":"well_collision","position":[WELL.x,WELL.y,WELL.z],"radius":1.1})
	for i in range(16):
		var angle: float=TAU*i/16.0
		var segment:=_piece("WellRim"+str(i),Vector3(0.3,0.8,0.43),WELL+Vector3(cos(angle),0.4,sin(angle)),Color.WHITE,false,true)
		segment.rotation.y=-angle
	for x in [-1.1,1.1]:
		_piece("WellPost"+str(x),Vector3(0.13,2.2,0.13),WELL+Vector3(x,1.1,0),Color("674c32"))
	_piece("WellCrossbar",Vector3(2.5,0.14,0.14),WELL+Vector3(0,2.1,0),Color("674c32"))
	_piece("WellRope",Vector3(0.025,1.45,0.025),WELL+Vector3(0,1.3,0),Color("c5b381"))
	_piece("WellWater",Vector3(1.35,0.02,1.35),WELL+Vector3.UP*0.2,Color("486767"))

func _trough() -> void:
	_piece("StableTrough",Vector3(1.1,0.5,2.7),TROUGH+Vector3.UP*0.25,Color("8b7963"),true)
	_piece("TroughWater",Vector3(0.88,0.02,2.4),TROUGH+Vector3.UP*0.51,Color("607876"))

func _market_details() -> void:
	for i in range(5):
		_piece("MarketSack"+str(i),Vector3(0.45,0.6,0.45),Vector3(-25.3+i*0.55,0.45,-19.2),Color("b99d6c"))
	_piece("MarketCloth",Vector3(2.7,0.035,0.7),Vector3(-24,1.28,-17.6),Color("976646"))

func _skyline() -> void:
	# Local RNG never consumes gameplay randomness. Entire backdrop is non-colliding.
	var rng:=RandomNumberGenerator.new();rng.seed=SEED
	for i in range(18):
		var side: float=-1.0 if i%2==0 else 1.0
		var x: float=side*rng.randf_range(36,55)
		var z: float=rng.randf_range(-14,29)
		var height: float=rng.randf_range(3,5.5)
		var width: float=rng.randf_range(4,7)
		_piece("Dwelling"+str(i),Vector3(width,height,5),Vector3(x,height/2,z),Color.WHITE,false,true)
		_piece("Roof"+str(i),Vector3(width+0.3,0.18,5.3),Vector3(x,height+0.09,z),Color("755b43"))
		_piece("Door"+str(i),Vector3(0.06,1.7,0.9),Vector3(x-side*(width/2+0.035),0.9,z),Color("483d30"))
		_piece("Window"+str(i),Vector3(0.06,0.5,0.6),Vector3(x-side*(width/2+0.035),2.3,z+1.5),Color("544330"))

func _label(text: String,at: Vector3) -> void:
	var label:=Label3D.new()
	label.text=text;label.position=at
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size=20;label.fixed_size=true;label.pixel_size=0.0015
	add_child(label)

func notes() -> String:
	var text: String="GUJRANWALA · RESEARCH / AUTHORING VIEW\n\nThis is a player-facing development notebook, not Buddh's knowledge. The 56 m home cell is not a surveyed city or historical border.\n\n"
	for source in research.sources:
		text+=source.title+"\n"+source.supports+"\nLimit: "+source.does_not_support+"\n\n"
	text+="BUILT NOW\nEnter the household store through its open doorway. Walk around the well and stable trough. All positions, dimensions, props, neighboring houses and shader/atmosphere settings are authored. The store is not a second production building; its visible sacks are not extra loot.\n\n"
	text+="NOT BACKDATED\n"+"\n".join(research.excluded_from_childhood_build)
	return text
