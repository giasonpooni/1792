extends Node3D
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Research-informed visual fabric over the existing collision world. No new state owner.
const CATALOG := "res://data/gujranwala_fabric.json"
const MASONRY := preload("res://architecture/gujranwala_masonry.gdshader")
const VERSION := "gujranwala-fabric.v1"
var _catalog: Dictionary={}
var _manifest: Dictionary={}
var _materials: Dictionary={}
var _built:=false
var _patches: Array=[]
var _mesh_count:=0

static func valid_catalog(value: Variant) -> bool:
	if not value is Dictionary or value.keys().size()!=6: return false
	for key in ["schema","year","sources","claims","elements","excluded"]:
		if not value.has(key): return false
	if value.schema!=VERSION or typeof(value.year) not in [TYPE_INT,TYPE_FLOAT] or value.year!=1792: return false
	if not value.sources is Array or value.sources.is_empty() or value.sources.size()>12: return false
	var ids: Array=[]
	for s in value.sources:
		if not s is Dictionary or not s.has_all(["id","title","url","locator","scope"]): return false
		for key in s:
			if not s[key] is String or s[key].is_empty() or s[key].length()>1500: return false
		if s.id in ids or not s.url.begins_with("https://"): return false
		ids.append(s.id)
	if not value.claims is Array or value.claims.is_empty() or value.claims.size()>16: return false
	var claims: Array=[]
	for c in value.claims:
		if not c is Dictionary or not c.has_all(["id","source_ids","observation","limit"]): return false
		if not c.id is String or c.id.is_empty() or c.id in claims: return false
		if not c.source_ids is Array or c.source_ids.is_empty(): return false
		for source in c.source_ids:
			if source not in ids: return false
		for key in ["observation","limit"]:
			if not c[key] is String or c[key].is_empty() or c[key].length()>1500: return false
		claims.append(c.id)
	if not value.elements is Array or value.elements.size()!=4: return false
	var elements: Array=[]
	for e in value.elements:
		if not e is Dictionary or not e.has_all(["id","title","claim_ids","choice","exact_1792"]): return false
		if not e.id is String or e.id in elements or e.id.is_empty() or typeof(e.exact_1792)!=TYPE_BOOL or e.exact_1792: return false
		if not e.title is String or e.title.is_empty() or not e.choice is String or e.choice.is_empty(): return false
		if not e.claim_ids is Array or e.claim_ids.is_empty(): return false
		for claim in e.claim_ids:
			if claim not in claims: return false
		elements.append(e.id)
	if not value.excluded is Array or value.excluded.is_empty(): return false
	for x in value.excluded:
		if not x is String or x.is_empty(): return false
	return true

func build(host: Node3D) -> String:
	if _built: return "Fabric already built; duplicate decoration refused."
	var file:=FileAccess.open(CATALOG,FileAccess.READ)
	if file==null or file.get_length()>32768: return "Missing or excessive architectural catalogue."
	var raw:=file.get_as_text()
	var value: Variant=JSON.parse_string(raw)
	if not valid_catalog(value): return "Invalid architectural evidence catalogue."
	_catalog=value.duplicate(true)
	_materials.wood=_solid(Color("51402c"))
	_materials.trim=_solid(Color("bfa37a"))
	_materials.trim.cull_mode=BaseMaterial3D.CULL_DISABLED
	_materials.shadow=_solid(Color("73513a"))
	_materials.clay=_solid(Color("ac6741"))
	_materials.plaster=_wall(0.83)
	_materials.brick=_wall(0.16)
	_paint_walls(host)
	# Attached blind bays: remain flush with the existing solid wall, NOT fake doors.
	for x in [-16,-10,-4,2,8,14]:
		_blind_bay(Vector3(x,0.14,11.72),4.5,2.40)
	_box(Vector3(38.1,0.16,0.68),Vector3(0,2.78,12),_materials.trim)
	for x in [-20,20]:
		_box(Vector3(0.64,0.16,19.1),Vector3(x,2.78,2),_materials.trim)
	# Timber beams dress the original stable roof; existing support collisions stay identical.
	for z in [-6.7,-5.2,-3.7,-2.2,-1.1]:
		_box(Vector3(6.1,0.17,0.14),Vector3(9,3.39,z),_materials.wood)
	# Remount yard blind arcade and stable detail follow its unchanged physical walls.
	for x in [-7,-2,3,8]: _blind_bay(Vector3(x,0.14,26.76),3.6,2.4)
	_box(Vector3(20.1,0.16,0.64),Vector3(0,2.78,27),_materials.trim)
	# Vessels sit ON the existing market counter, not in walking or mounted lanes.
	for i in range(4): _vessel(Vector3(-25.0+i*0.65,1.1,-17.6),0.14+0.02*(i%2))
	# Town fabric beyond the original physical test boundary: explicitly non-playable.
	for row in range(2):
		for column in range(6):
			_house(Vector3(-45.0-column*8.0,0.0,-29.0+row*15.0+float(column%2)*1.1),column+row*6)
	for i in range(4): _house(Vector3(38.0+i*9.0,0.0,39.0+float(i%2)*6.0),12+i)
	_manifest={"schema":VERSION,"catalog_sha256":raw.sha256_text(),"historical_class":"authored_reference_informed",
		"georeferenced":false,"exact_1792":false,"new_collision_shapes":0,"new_simulation_owners":0,
		"blind_bays":10,"background_houses":16,"material_replacements":_patches.size(),"mesh_instances":_mesh_count,
		"element_ids":_catalog.elements.map(func(e): return e.id),"verification_status":"not_verified"}
	_built=true
	return ""

func manifest() -> Dictionary: return _manifest.duplicate(true)

func inspection_text() -> String:
	var lines: Array[String]=["RECONSTRUCTION NOTES · OUTSIDE CHARACTER KNOWLEDGE", "",
		"Playable 56 m test cell; not a surveyed map. F2 opens this authoring view, not a memory or a historical narrator.", ""]
	for e in _catalog.elements:
		lines.append(e.title+"\nAuthored choice: "+e.choice)
		for id in e.claim_ids:
			for c in _catalog.claims:
				if c.id==id: lines.append("Reference: "+c.observation+"\nLimit: "+c.limit)
		lines.append("")
	lines.append("NOT ADMITTED: "+", ".join(_catalog.excluded))
	for s in _catalog.sources: lines.append("\n"+s.title+"\n"+s.locator+"\n"+s.url)
	return "\n".join(lines)

func remove_material_overrides() -> void:
	# Allows a test to compare collision and state with visual fabric off and on.
	for patch in _patches:
		if is_instance_valid(patch[0]): patch[0].material_override=patch[1]
	_patches.clear()

func _paint_walls(n: Node) -> void:
	for child in n.get_children():
		if child==self: continue
		if child is MeshInstance3D and child.mesh is BoxMesh and child.get_parent() is StaticBody3D:
			var s: Vector3=child.mesh.size
			if is_equal_approx(s.y,2.6) and minf(s.x,s.z)<=0.51:
				_patches.append([child,child.material_override]);child.material_override=_materials.plaster
		_paint_walls(child)

func _solid(color: Color) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=0.95
	return material

func _wall(cover: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new();material.shader=MASONRY;material.set_shader_parameter("plaster_cover",cover)
	return material

func _box(size: Vector3,p: Vector3,material: Material) -> MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size
	return _visual(mesh,p,material)

func _visual(mesh: Mesh,p: Vector3,material: Material) -> MeshInstance3D:
	var visual:=MeshInstance3D.new();visual.mesh=mesh;visual.position=p;visual.material_override=material
	add_child(visual);_mesh_count+=1
	return visual

func _blind_bay(at: Vector3,width: float,height: float) -> void:
	# Shallow applied panelling: backing wall retains its original sight/collision semantics.
	_box(Vector3(width-0.5,height-0.3,0.025),at+Vector3(0,height/2,-0.012),_materials.shadow)
	for side in [-1,1]:
		_box(Vector3(0.20,height,0.055),at+Vector3(side*width/2,height/2,-0.03),_materials.trim)
		_box(Vector3(0.32,0.12,0.075),at+Vector3(side*width/2,0.09,-0.045),_materials.trim)
	_box(Vector3(width,0.13,0.10),at+Vector3(0,height+0.03,-0.05),_materials.trim)
	var radius: float=(width-0.65)/2.0
	var spring: float=height-0.82
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(40):
		var a: float=PI*float(i)/40.0
		var b: float=PI*float(i+1)/40.0
		# Five modest scallops are an authored approximation, not a measured arch profile.
		var aa:=Vector3(radius*cos(a),spring+0.72*sin(a)-0.07*absf(sin(a*5)),0)
		var bb:=Vector3(radius*cos(b),spring+0.72*sin(b)-0.07*absf(sin(b*5)),0)
		var outer_a:=aa+Vector3(cos(a)*0.10,0.10*sin(a),0)
		var outer_b:=bb+Vector3(cos(b)*0.10,0.10*sin(b),0)
		for v in [aa,outer_b,outer_a,aa,bb,outer_b]:
			st.set_normal(Vector3.FORWARD);st.add_vertex(v)
	_visual(st.commit(),at+Vector3(0,0,-0.04),_materials.trim)
	# Timber screen is blind; it is not a promised route through the solid wall.
	for i in range(7):
		_box(Vector3(0.055,spring-0.15,0.04),at+Vector3(-radius+0.18+float(i)*(2*radius-0.36)/6,(spring-0.15)/2+0.1,-0.045),_materials.wood)

func _vessel(at: Vector3,radius: float) -> void:
	var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2.4;mesh.radial_segments=10;mesh.rings=6
	_visual(mesh,at+Vector3.UP*radius,_materials.clay)
	var rim:=TorusMesh.new();rim.inner_radius=radius*0.35;rim.outer_radius=radius*0.6;rim.rings=10;rim.ring_segments=6
	_visual(rim,at+Vector3.UP*radius*2,_materials.trim)

func _house(at: Vector3,index: int) -> void:
	var h: float=3.6+float(index%3)*0.4
	_box(Vector3(6,h,7),at+Vector3.UP*h/2,_materials.plaster if index%2==0 else _materials.brick)
	_box(Vector3(6.3,0.16,7.3),at+Vector3.UP*h,_materials.trim)
	for x in [-2.85,2.85]: _box(Vector3(0.20,0.45,7),at+Vector3(x,h+0.25,0),_materials.plaster)
	for z in [-3.4,3.4]: _box(Vector3(6,0.45,0.20),at+Vector3(0,h+0.25,z),_materials.plaster)
	_box(Vector3(1.0,1.9,0.035),at+Vector3(0,0.95,3.515),_materials.wood)
	for x in [-1.9,1.9]: _box(Vector3(0.8,1.0,0.035),at+Vector3(x,2.2,3.515),_materials.wood)
	_box(Vector3(4.7,0.08,1.2),at+Vector3(0,2.6,4),_materials.wood)
