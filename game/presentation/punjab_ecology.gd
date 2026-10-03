# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Deterministic exterior habitat pockets on the existing Home; no simulation authority.
const Catalog := preload("res://reconstruction/ecology_catalog.gd")
var catalog := Catalog.new()
var season := "dry"
var enabled := true
var pockets: Dictionary = {}
var _plants: Array[Dictionary] = []
var _surfaces: Array[Dictionary] = []
var _waters: Array[Dictionary] = []
var _legacy: Array[Dictionary] = []

func _material(color: String, roughness: float = 1.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = roughness
	return result

func _mesh(parent: Node3D, label: String, shape: Mesh, at: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = shape
	node.position = at
	node.material_override = _material(color)
	parent.add_child(node)
	return node

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, label, shape, at, color)

func _oval(parent: Node3D, label: String, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = 1.0
	shape.bottom_radius = 1.0
	shape.height = 1.0
	shape.radial_segments = 28
	var node := _mesh(parent, label, shape, at, color)
	node.scale = Vector3(size.x/2, size.y, size.z/2)
	return node

func _soil(parent: Node3D, size: Vector2, rng: RandomNumberGenerator) -> MeshInstance3D:
	# Irregular feathered mud/soil edges blend into the retained horizon surface.
	var vertices := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var colors := PackedColorArray([Color(1,1,1,.58)])
	var indices := PackedInt32Array()
	var outline: Array[float] = []
	for i in range(32): outline.append(rng.randf_range(.86,1.0))
	for ring in range(2):
		for i in range(32):
			var angle := TAU*float(i)/32
			var scale_factor := outline[i]*(.70 if ring == 0 else 1.0)
			vertices.append(Vector3(cos(angle)*size.x*.5*scale_factor,0,sin(angle)*size.y*.5*scale_factor))
			normals.append(Vector3.UP)
			colors.append(Color(1,1,1,.50 if ring == 0 else 0.0))
	for i in range(32):
		var a := 1+i
		var b := 1+(i+1)%32
		indices.append_array(PackedInt32Array([0,b,a,a,b,b+32,a,b+32,a+32]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var shape := ArrayMesh.new()
	shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := _mesh(parent,"SoilPocket",shape,Vector3(0,-.15,0),"786e50")
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override.vertex_color_use_as_albedo = true
	node.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return node

func _crown(parent: Node3D, at: Vector3, size: Vector3) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 9
	shape.rings = 5
	var node := _mesh(parent, "UnresolvedFoliageForm", shape, at, "747950")
	node.scale = size
	_surfaces.append({"node":node, "color_key":"scrub_color"})
	return node

func _stem(parent: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius*0.55
	shape.bottom_radius = radius
	shape.height = from.distance_to(to)
	shape.radial_segments = 7
	var node := _mesh(parent, "BranchForm", shape, (from+to)/2, "65533e")
	var direction := (to-from).normalized()
	if not direction.is_equal_approx(Vector3.UP): node.quaternion = Quaternion(Vector3.UP, direction)

func _shrubs(parent: Node3D, size: Vector2, rng: RandomNumberGenerator, count: int, tall: bool = false) -> void:
	for _i in range(count):
		var at := Vector3(rng.randf_range(-size.x*.35, size.x*.35), 0, rng.randf_range(-size.y*.35, size.y*.35))
		var height := rng.randf_range(1.0, 1.5) if tall else rng.randf_range(.45, .95)
		_stem(parent, at, at+Vector3(0,height,0), .07)
		for arm in range(3):
			var angle := float(arm)*TAU/3+float(_i)
			var end := at+Vector3(cos(angle)*.52,height,sin(angle)*.52)
			_stem(parent, at+Vector3.UP*height*.35, end, .028)
			_crown(parent, end, Vector3(.85,.55,.75))

func _grass(parent: Node3D, size: Vector2, rng: RandomNumberGenerator, height: float, count: int, edge_only: bool = false) -> void:
	# Tapered, curved blades in one mesh batch; no processing nodes or collision bodies.
	var batch := MultiMeshInstance3D.new()
	batch.name = "GrassReedForms"
	var blade_surface := SurfaceTool.new()
	blade_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: Array[Vector3] = [Vector3(.025,0,0),Vector3(.09,.30,.02),Vector3(.06,.67,.07),Vector3(0,1,.18)]
	for i in range(sections.size()-1):
		var a: Vector3 = sections[i]
		var b: Vector3 = sections[i+1]
		var points: Array[Vector3] = [Vector3(-a.x,a.y,a.z),Vector3(a.x,a.y,a.z),Vector3(b.x,b.y,b.z),Vector3(-b.x,b.y,b.z)]
		for vertex in [0,1,2,0,2,3]: blade_surface.add_vertex(points[vertex])
	blade_surface.generate_normals()
	var mesh := blade_surface.commit()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count*3
	var transforms: Array[Transform3D] = []
	for _i in range(count):
		var center := Vector3(rng.randf_range(-size.x*.44,size.x*.44),0,rng.randf_range(-size.y*.44,size.y*.44))
		if edge_only and absf(center.x)<size.x*.38 and absf(center.z)<size.y*.38:
			center.z = (-1.0 if _i%2 else 1.0)*size.y*.42
		for blade in range(3):
			var h := height*rng.randf_range(.55,1.0)
			var yaw := rng.randf_range(0,TAU)
			var basis := Basis(Vector3.UP,yaw)*Basis(Vector3.FORWARD,.10*float(blade-1))
			basis = basis.scaled(Vector3(1,h,1))
			var transform := Transform3D(basis,center+Vector3(float(blade-1)*.12,-.17 if not edge_only else 0.0,0))
			transforms.append(transform)
			multimesh.set_instance_transform(transforms.size()-1,transform)
	batch.multimesh = multimesh
	batch.material_override = _material("a59d64")
	batch.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(batch)
	_plants.append({"node":batch,"transforms":transforms})

func _build_pocket(placement: Dictionary) -> void:
	var pocket := Node3D.new()
	pocket.name = placement.id
	var p: Array = placement.location.position
	pocket.position = Vector3(p[0],p[1],p[2])
	pocket.set_meta("placement_id",placement.id)
	pocket.set_meta("habitat_id",placement.habitat_id)
	pocket.set_meta("reconstruction_decision_id",placement.reconstruction_decision_id)
	pocket.set_meta("evidence_digest",catalog.digest)
	add_child(pocket)
	pockets[placement.id] = pocket
	var size := Vector2(placement.location.footprint[0],placement.location.footprint[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(placement.seed)
	var ground := _soil(pocket,size,rng)
	ground.visible = placement.habitat_id != "settlement_cultivated"
	_surfaces.append({"node":ground,"color_key":"soil_color"})
	match placement.habitat_id:
		"settlement_cultivated":
			# Surround the existing field_east instead of replacing its crops, well or actors.
			for z in [-size.y*.43,size.y*.43]:
				_box(pocket,"FieldBund",Vector3(0,.08,z),Vector3(size.x*.90,.10,.22),"ad986a")
			for x in [-size.x*.43,size.x*.43]:
				_box(pocket,"FieldBund",Vector3(x,.08,0),Vector3(.22,.10,size.y*.90),"ad986a")
			var tree_at := Vector3(-size.x*.29,0,size.y*.28)
			_stem(pocket,tree_at,tree_at+Vector3.UP*3.3,.18)
			for arm in range(4):
				var end := tree_at+Vector3(cos(float(arm)*TAU/4)*1.1,3.7,sin(float(arm)*TAU/4)*1.1)
				_stem(pocket,tree_at+Vector3.UP*2.0,end,.09)
				_crown(pocket,end,Vector3(2.3,1.6,2.3))
			# Short cut margins leave the original grain plot legible.
			_grass(pocket,size,rng,.24,60,true)
		"dry_scrub_grazing":
			_grass(pocket,size,rng,.7,110)
			_shrubs(pocket,size,rng,6)
			# A visual grazing track, with no pathfinding or road admission.
			_box(pocket,"GrazingTrace",Vector3(0,.025,0),Vector3(size.x*.9,.015,.75),"b3a07b")
		"riverine_thicket":
			_grass(pocket,size,rng,2.6,320)
			_shrubs(pocket,size,rng,4,true)
			_add_water(pocket,Vector3(size.x*.29,.045,0),Vector3(size.x*.22,.016,size.y*.88))
		"seasonal_wetland":
			_grass(pocket,size,rng,1.0,130)
			_add_water(pocket,Vector3(0,.045,0),Vector3(size.x*.82,.016,size.y*.82))

func _add_water(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var water := _oval(parent,"IllustrativeWaterExtent",at-Vector3.UP*.20,size,"697f79")
	water.material_override.roughness = .33
	_waters.append({"node":water,"base_scale":water.scale})

func build(chapter: Node3D) -> String:
	if not catalog.manifest.is_empty(): return "Ecology already built."
	var error := catalog.load_catalog()
	if not error.is_empty(): return error
	set_meta("classification","bounded_ecology_reconstruction")
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	for placement in catalog.manifest.placements: _build_pocket(placement)
	for node in chapter.cell.get_children():
		if node is Node3D and node.has_meta("legacy_ecology_placeholder"):
			_legacy.append({"node":node,"visible":node.visible})
	set_enabled(true)
	return set_season(catalog.manifest.default_season)

func set_season(id: String) -> String:
	if not catalog.manifest.get("season_profiles",{}).has(id): return "Unknown ecology season."
	var profile: Dictionary = catalog.manifest.season_profiles[id]
	for record in _plants:
		var batch: MultiMeshInstance3D = record.node
		batch.material_override.albedo_color = Color(profile.grass_color)
		batch.multimesh.visible_instance_count = int(record.transforms.size()*float(profile.vegetation_fraction))
		for i in range(record.transforms.size()):
			var transform: Transform3D = record.transforms[i]
			transform.basis = transform.basis.scaled(Vector3(1,profile.grass_height_scale,1))
			# Ground contact does not move when authored vegetation height changes.
			batch.multimesh.set_instance_transform(i,transform)
	for record in _surfaces:
		record.node.material_override.albedo_color = Color(profile[record.color_key])
	for record in _waters:
		record.node.scale = record.base_scale*Vector3(profile.water_extent,1,profile.water_extent)
		record.node.material_override.albedo_color = Color(profile.water_color)
	season = id
	return ""

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	for record in _legacy:
		if is_instance_valid(record.node): record.node.visible = false if value else record.visible

func _exit_tree() -> void:
	set_enabled(false)
