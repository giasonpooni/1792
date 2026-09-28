extends Node3D
## Seeded compressed home cell. Authored anchors and traversable lanes, generated field relief.
## This is NOT a surveyed reconstruction, historical border or streamed Punjab.
const Rules := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
const ID := Rules.CELL_ID
const GENERATOR := "home-fields.v1"
var terrain_mesh: ArrayMesh
var manifest: Dictionary
var _noise := FastNoiseLite.new()

func _init() -> void:
	_noise.seed=Rules.SEED
	_noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency=0.06

func protected_lane(x: float,z: float) -> bool:
	# Retained lesson and escort routes stay flat; general sloped navigation is not claimed.
	if absf(x)<21.5 or z>-9: return true
	for p in [Rules.MARKET,Vector3(-24,0,-3)]:
		if Vector2(x,z).distance_to(Vector2(p.x,p.z))<5: return true
	return false

func height(x: float,z: float) -> float:
	if protected_lane(x,z): return 0.1
	var clearance := clampf((absf(x)-21.5)/3.0,0,1)*clampf((-z-9)/3.0,0,1)
	for p in [Rules.MARKET,Vector3(-24,0,-3)]:
		clearance*=clampf((Vector2(x,z).distance_to(Vector2(p.x,p.z))-5)/3.0,0,1)
	return 0.1+clearance*(0.11+0.10*_noise.get_noise_2d(x,z))

func build() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for iz in range(31):
		for ix in range(31):
			var x: float=-30+2*ix
			var z: float=-30+2*iz
			vertices.append(Vector3(x,height(x,z),z))
			normals.append(Vector3.UP)
			var strip: bool=int(floor((x+80)/6.0))%2==0
			colors.append(Color("748454") if strip else Color("81915b"))
	for z in range(30):
		for x in range(30):
			var i:=z*31+x
			indices.append_array(PackedInt32Array([i,i+1,i+31,i+1,i+32,i+31]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	terrain_mesh=ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.roughness=1
	terrain_mesh.surface_set_material(0,material)
	var visual:=MeshInstance3D.new()
	visual.mesh=terrain_mesh
	visual.position.y=0.008 # Avoid coplanar z-fighting with retained flat ground; collision uses original support.
	add_child(visual)
	var body:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	shape.shape=terrain_mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)
	manifest={"id":ID,"generator":GENERATOR,"seed":Rules.SEED,
		"frame":"gujranwala-compressed-local-metres","georeferenced":false,
		"historical_class":"authored","playable_extent":[-28,28,-28,28],
		"height_digest":vertices.to_byte_array().hex_encode().sha256_text(),
		"vertices":vertices.size(),"triangles":indices.size()/3}
	# Horizon is presentation only, never another active region.
	_box(Vector3(420,0.1,420),Vector3(0,-0.16,0),Color("65734c"))
	var rng:=RandomNumberGenerator.new()
	rng.seed=Rules.SEED
	for _i in range(55):
		var x:=rng.randf_range(-180,180)
		var z:=rng.randf_range(-180,180)
		if absf(x)<34 and absf(z)<34: continue
		var p:=Vector3(x,0,z)
		var h:=rng.randf_range(3,7)
		_box(Vector3(0.6,h,0.6),p+Vector3.UP*h/2,Color("695942"))
		_box(Vector3(3.7,h/2,3.4),p+Vector3.UP*h,Color("556746"))
	for z in [-24,-18,18,24,42,54]:
		_box(Vector3(390,0.05,0.18),Vector3(0,0.03,z),Color("99845c"))
	# Outside the playable wall: water strip suggests drainage, not a historical river.
	_box(Vector3(3,0.05,260),Vector3(-38,0.03,0),Color("759ca0"))
	_road(Vector3(0,0,-9),Vector3(-24,0,-11))
	_road(Vector3(-24,0,-11),Vector3(-24,0,-20))
	_road(Vector3(-24,0,-11),Vector3(-24,0,4))
	# Market stall and production yard: collision stays explicitly simple.
	_box(Vector3(4,0.2,3),Rules.MARKET+Vector3(0,3.0,-2.6),Color("ab8454"))
	_box(Vector3(3,1,1),Rules.MARKET+Vector3(0,0.6,-2.6),Color("906942"),true)
	for x in [-1.7,1.7]:
		_box(Vector3(0.13,3,0.13),Rules.MARKET+Vector3(x,1.5,-3.3),Color("69533e"),true)
	_box(Vector3(4,2,6),Vector3(-25,1.1,2),Color("b09872"),true)
	_box(Vector3(4.5,0.3,6.5),Vector3(-25,2.2,2),Color("715c43"))
	_box(Vector3(0.5,1.7,0.5),Rules.MARKET+Vector3(-1.4,0.85,0),Color("82716c"))
	_box(Vector3(0.5,1.7,0.5),Rules.QUARTERMASTER+Vector3(1,0.85,0),Color("72725e"))
	_label("Market [E]",Rules.MARKET+Vector3.UP*2.6)
	_label("Quartermaster [E]",Rules.QUARTERMASTER+Vector3.UP*2.6)

func _road(a: Vector3,b: Vector3) -> void:
	var node:=_box(Vector3(3.2,0.018,a.distance_to(b)),(a+b)/2+Vector3.UP*0.119,Color("ad956c"))
	node.look_at(b+Vector3.UP*0.119)

func _box(size: Vector3,at: Vector3,color: Color,collision: bool=false) -> Node3D:
	var n: Node3D=StaticBody3D.new() if collision else Node3D.new()
	n.position=at
	add_child(n)
	var mesh:=BoxMesh.new()
	mesh.size=size
	var v:=MeshInstance3D.new()
	v.mesh=mesh
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=1
	v.material_override=m
	n.add_child(v)
	if collision:
		var c:=CollisionShape3D.new()
		var s:=BoxShape3D.new()
		s.size=size
		c.shape=s
		n.add_child(c)
	return n

func _label(text: String,at: Vector3) -> void:
	var l:=Label3D.new()
	l.text=text
	l.position=at
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size=24
	l.pixel_size=0.003
	add_child(l)
