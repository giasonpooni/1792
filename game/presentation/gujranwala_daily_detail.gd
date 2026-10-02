# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Static construction/use studies fitted to existing surfaces. No game authority.
const Kit := preload("res://presentation/workshop_kit.gd")
const Rules := preload("res://territory/misl_rules.gd")
var kit := Kit.new()
var door_hardware: Array[MeshInstance3D] = []
var threshold_wear: Array[MeshInstance3D] = []
var baskets: Array[MeshInstance3D] = []
var well_fittings: Array[MeshInstance3D] = []
var well_body: MeshInstance3D
var original_well_mesh: CylinderMesh
var fitted_well_mesh: CylinderMesh
var enabled := true
var _built := false

func _batch() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	return surface

func _append(surface: SurfaceTool, mesh: Mesh, at: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	surface.append_from(mesh, 0, Transform3D(Basis.from_euler(rotation), at))

func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _ring(inner: float, outer: float, segments: int = 24) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = segments
	mesh.ring_segments = 6
	return mesh

func _rod(surface: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	mesh.rings = 1
	surface.append_from(mesh, 0, Transform3D(Basis(Quaternion(Vector3.UP, (b-a).normalized())), (a+b)/2.0))

func _finish(surface: SurfaceTool, label: String, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = at
	mesh.mesh = surface.commit()
	mesh.material_override = material
	add_child(mesh)
	return mesh

func build(chapter: Node3D, art: Node3D) -> String:
	if _built: return "Daily detail already built."
	var bays: Array[Node3D] = []
	for i in range(8):
		var bay: Node3D = art.detail.get_node_or_null("AuthoredBay%d" % i)
		if bay == null: return "Daily detail requires the retained authored courtyard bays."
		bays.append(bay)
	var well: Node3D = chapter.fabric.get_node_or_null("household_well")
	if well == null: return "Daily detail requires the retained household well."
	for mesh in well.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is CylinderMesh and is_equal_approx(mesh.mesh.height, 1.0) and is_equal_approx(mesh.mesh.top_radius, 1.25):
			well_body = mesh
			break
	if well_body == null: return "Daily detail requires the retained solid well cylinder."
	original_well_mesh = well_body.mesh
	fitted_well_mesh = original_well_mesh.duplicate()
	# Reversible inward visual fit exposes course edges inside the unchanged collision hull.
	fitted_well_mesh.top_radius = 1.225
	fitted_well_mesh.bottom_radius = 1.225
	name = "GujranwalaDailyDetail"
	set_meta("classification", "original-construction-and-use-study")
	set_meta("historical_claim", false)
	set_meta("gameplay_authority", false)
	for i in range(bays.size()):
		var origin := to_local(bays[i].global_position)
		_build_door(origin, i)
		if i in [0, 2, 3, 5, 7]: _build_wear(origin, i)
	_build_baskets()
	_build_well(to_local(well.global_position))
	_built = true
	return ""

func _build_door(origin: Vector3, index: int) -> void:
	var surface := _batch()
	for side in [-1.0, 1.0]:
		var x: float = side*.13
		_append(surface, _box(Vector3(.060, .10, .018)), Vector3(x, 1.36, .251))
		_append(surface, _box(Vector3(.024, .028, .045)), Vector3(x, 1.345, .220))
		_append(surface, _ring(.034, .052, 16), Vector3(x, 1.29, .195), Vector3(PI/2, 0, 0))
	# Three latched leaves, with the remaining doors kept visually quiet.
	if index in [1, 4, 6]:
		_append(surface, _box(Vector3(.27, .028, .020)), Vector3(.01, .92, .228))
		for x in [-.085, .105]:
			_append(surface, _box(Vector3(.030, .067, .028)), Vector3(x, .92, .217))
	var mesh := _finish(surface, "DoorHardware%d" % index, origin, kit.plain("49443a", .55))
	mesh.set_meta("anchor", "AuthoredBay%d" % index)
	door_hardware.append(mesh)

func _build_wear(origin: Vector3, index: int) -> void:
	# A thin irregular patch on the existing threshold, not a raised step/decal in a lane.
	var surface := _batch()
	var points: Array[Vector3] = []
	for i in range(18):
		var angle: float = TAU*i/18.0
		var irregular: float = 1.0 + .055*sin(i*2.1+index*.8)
		points.append(Vector3(cos(angle)*(.68+.025*(index%3))*irregular, .161, .20+sin(angle)*.125*irregular))
	for i in range(points.size()):
		for vertex in [Vector3(0, .161, .20), points[i], points[(i+1)%points.size()]]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(vertex)
	var mesh := _finish(surface, "ThresholdWear%d" % index, origin, kit.plain("a89577"))
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_meta("anchor", "AuthoredBay%d" % index)
	threshold_wear.append(mesh)

func _build_baskets() -> void:
	# Counter top is MARKET + (0, 1.1, -2.6), with the retained 3 x 1 metre footprint.
	var counter := Rules.MARKET + Vector3(0, 1.10, -2.6)
	var positions: Array[Vector3] = [Vector3(-1.16, 0, -.36), Vector3(1.0, 0, .37)]
	for index in range(positions.size()):
		var radius: float = .125 if index == 0 else .115
		var height: float = .16 if index == 0 else .14
		var surface := _batch()
		# Open lattice: the spaces between strips are actual geometry gaps.
		for row in range(7):
			var y: float = .014 + row*(height-.020)/6.0
			var r: float = lerpf(radius*.67, radius, y/height)
			_append(surface, _ring(r-.005, r+.005), Vector3(0, y, 0))
		for i in range(18):
			var angle: float = TAU*i/18.0
			for section in range(3):
				var ya: float = .008+section*(height-.008)/3.0
				var yb: float = .008+(section+1)*(height-.008)/3.0
				var a := Vector3(cos(angle)*lerpf(radius*.67, radius, ya/height), ya, sin(angle)*lerpf(radius*.67, radius, ya/height))
				var b := Vector3(cos(angle)*lerpf(radius*.67, radius, yb/height), yb, sin(angle)*lerpf(radius*.67, radius, yb/height))
				_rod(surface, a, b, .0032)
		_append(surface, _ring(radius-.009, radius+.006, 32), Vector3(0, height, 0))
		var floor_mesh := CylinderMesh.new()
		floor_mesh.top_radius = radius*.66
		floor_mesh.bottom_radius = radius*.66
		floor_mesh.height = .008
		floor_mesh.radial_segments = 24
		floor_mesh.rings = 1
		_append(surface, floor_mesh, Vector3(0, .004, 0))
		var mesh := _finish(surface, "OpenBasket%d" % index, counter+positions[index], kit.plain("9b815a" if index == 0 else "8b7657"))
		mesh.set_meta("anchor", "retained-market-counter")
		baskets.append(mesh)

func _build_well(origin: Vector3) -> void:
	var masonry := _batch()
	# All radial detail stays within the existing 1.25 m solid well footprint.
	for y in [.27, .55, .83]:
		_append(masonry, _ring(1.205, 1.247, 48), Vector3(0, y, 0))
	_append(masonry, _ring(1.10, 1.248, 64), Vector3(0, 1.0, 0))
	well_fittings.append(_finish(masonry, "WellMasonryCourses", origin, kit.surface("a38a65", 1)))
	var wheel := _batch()
	# The supplied rope meets the back tangent of this static sheave study.
	_append(wheel, _ring(.105, .18, 32), Vector3(0, 2.60, .18), Vector3(0, 0, PI/2))
	for i in range(6):
		var angle: float = TAU*i/6.0
		_rod(wheel, Vector3(0, 2.60, .18), Vector3(0, 2.60+cos(angle)*.13, .18+sin(angle)*.13), .009)
	well_fittings.append(_finish(wheel, "WellTimberSheave", origin, kit.surface("75614a", 2)))
	var metal := _batch()
	_rod(metal, Vector3(-.10, 2.60, .18), Vector3(.10, 2.60, .18), .018)
	for x in [-.060, .060]:
		_append(metal, _box(Vector3(.018, .19, .040)), Vector3(x, 2.68, .18))
	well_fittings.append(_finish(metal, "WellAxleAndHangers", origin, kit.plain("49443a", .55)))
	for mesh in well_fittings: mesh.set_meta("anchor", "household_well")

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if is_instance_valid(well_body): well_body.mesh = fitted_well_mesh if value else original_well_mesh

func _exit_tree() -> void:
	set_enabled(false)
