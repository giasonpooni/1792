extends RefCounted
## Bounded flat-world navigation over actual static collision geometry.
## No terrain import, second simulation clock, teleport recovery or nav service.
const Rules := preload("res://patrol/companion_rules.gd")
var grid := AStarGrid2D.new()
var space: PhysicsDirectSpaceState3D
var exclude: Array[RID] = []
var built := false
var hull := CapsuleShape3D.new()

func _init() -> void:
	hull.radius = 0.42
	hull.height = 1.8
	grid.region = Rect2i(0, 0, 62, 62)
	grid.cell_size = Vector2(2, 2)
	grid.offset = Vector2(-61, -86)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()

func bind(world: World3D, ignored: Array[RID]) -> void:
	space = world.direct_space_state
	exclude = ignored

func rebuild() -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var clearance := BoxShape3D.new()
	clearance.size = Vector3(1.9, 1.7, 1.9)
	query.shape = clearance
	query.collision_mask = 1
	query.exclude = exclude
	for y in range(62):
		for x in range(62):
			var p := grid.get_point_position(Vector2i(x, y))
			query.transform.origin = Vector3(p.x, 1.05, p.y)
			grid.set_point_solid(Vector2i(x, y), not space.intersect_shape(query, 1).is_empty())
	built = true

func clear_segment(start: Vector3, end: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = hull
	query.collision_mask = 1
	query.exclude = exclude
	query.transform.origin = start + Vector3.UP * 1.0
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = Vector3(end.x - start.x, 0, end.z - start.z)
	var fraction := space.cast_motion(query)
	return fraction.size() == 2 and fraction[0] > 0.999

func waypoint(start: Vector3, goal: Vector3) -> Vector3:
	if not built:
		rebuild()
	if clear_segment(start, goal):
		return goal
	var a := _free_cell(start)
	var b := _free_cell(goal)
	if a.x < 0 or b.x < 0:
		return start
	var route := grid.get_point_path(a, b)
	# Skip visible nearby nodes to avoid corner wobble. A blocked route stops,
	# never snaps the body to a grid cell or invents a path through a wall.
	for i in range(mini(4, route.size()) - 1, -1, -1):
		var p := Vector3(route[i].x, start.y, route[i].y)
		if Rules.horizontal(start, p) > 0.25 and clear_segment(start, p):
			return p
	return start

func _free_cell(p: Vector3) -> Vector2i:
	var center := Vector2i(roundi((p.x - grid.offset.x) / 2.0), roundi((p.z - grid.offset.y) / 2.0))
	var best := Vector2i(-1, -1)
	var distance := INF
	for y in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			var id := Vector2i(x, y)
			if not grid.region.has_point(id) or grid.is_point_solid(id):
				continue
			var at := grid.get_point_position(id)
			var d := Vector2(p.x, p.z).distance_squared_to(at)
			if d < distance:
				best = id
				distance = d
	return best

func fits(record: Dictionary) -> bool:
	var p := Rules.point(record.position)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = hull
	query.collision_mask = 1
	query.exclude = exclude
	query.transform.origin = p + Vector3.UP * 0.95
	if not space.intersect_shape(query, 1).is_empty():
		return false
	var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p - Vector3.UP * 0.35, 1, exclude)
	var hit := space.intersect_ray(ray)
	return not hit.is_empty() and hit.normal.y > 0.8
