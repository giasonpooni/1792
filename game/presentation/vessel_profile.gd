# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original procedural earthenware shape study, not authenticated historical pottery.
## Returns only a mesh, centered inside the caller's former cylinder envelope.
const RADIAL_SEGMENTS := 24
const PROFILE_STEPS := 3
const VARIANT_COUNT := 3

static func build(radius: float, height: float, variant: int = 0) -> ArrayMesh:
	assert(is_finite(radius) and is_finite(height) and radius > 0.0 and height > 0.0)
	var id := posmod(variant, VARIANT_COUNT)
	var belly_offset: float = [0.0, 0.025, -0.025][id]
	var neck: float = [0.45, 0.475, 0.425][id]
	var lip: float = [0.52, 0.545, 0.495][id]
	# (radius fraction, height fraction). Monotone interpolation on each interval
	# retains the exact maximum belly radius and original bottom/top elevations.
	var outside: Array[Vector2] = [
		Vector2(0.36, 0.0), Vector2(0.43, 0.035), Vector2(0.56, 0.09),
		Vector2(0.85, 0.22), Vector2(1.0, 0.40 + belly_offset),
		Vector2(0.96, 0.57), Vector2(0.81, 0.69), Vector2(0.60, 0.80),
		Vector2(neck, 0.88), Vector2(neck, 0.93),
		Vector2(lip, 0.975), Vector2(lip * 0.98, 1.0)]
	var inside: Array[Vector2] = [
		Vector2(0.25, 0.11), Vector2(0.46, 0.16), Vector2(0.75, 0.27),
		Vector2(0.89, 0.40 + belly_offset), Vector2(0.86, 0.57),
		Vector2(0.71, 0.69), Vector2(0.50, 0.80),
		Vector2(neck - 0.105, 0.88), Vector2(neck - 0.105, 0.93),
		Vector2(lip - 0.105, 0.975), Vector2(lip * 0.98 - 0.10, 1.0)]
	var data := {
		"vertices": PackedVector3Array(), "normals": PackedVector3Array(),
		"uvs": PackedVector2Array(), "indices": PackedInt32Array()}
	_wall(data, outside, radius, height, false)
	_wall(data, inside, radius, height, true)
	_annulus(data, outside[-1].x * radius, inside[-1].x * radius, height * 0.5)
	_disk(data, outside[0].x * radius, -height * 0.5, false)
	_disk(data, inside[0].x * radius, (inside[0].y - 0.5) * height, true)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data.vertices
	arrays[Mesh.ARRAY_NORMAL] = data.normals
	arrays[Mesh.ARRAY_TEX_UV] = data.uvs
	arrays[Mesh.ARRAY_INDEX] = data.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.set_meta("classification", "original-procedural-vessel-study")
	mesh.set_meta("historical_claim", false)
	mesh.set_meta("gameplay_authority", false)
	return mesh

static func _slopes(profile: Array[Vector2]) -> Array[float]:
	var secants: Array[float] = []
	for i in range(profile.size() - 1):
		secants.append((profile[i + 1].x - profile[i].x) / (profile[i + 1].y - profile[i].y))
	var slopes: Array[float] = [secants[0]]
	for i in range(1, profile.size() - 1):
		var left := secants[i - 1]
		var right := secants[i]
		if left * right <= 0.0:
			slopes.append(0.0)
		else:
			# Weighted harmonic mean: shape-preserving cubic Hermite derivatives.
			var before := profile[i].y - profile[i - 1].y
			var after := profile[i + 1].y - profile[i].y
			var w1 := 2.0 * after + before
			var w2 := after + 2.0 * before
			slopes.append((w1 + w2) / (w1 / left + w2 / right))
	slopes.append(secants[-1])
	return slopes

static func _wall(data: Dictionary, profile: Array[Vector2], radius: float, height: float, inward: bool) -> void:
	var slopes := _slopes(profile)
	var first: int = data.vertices.size()
	var rings := 0
	for i in range(profile.size() - 1):
		var interval := profile[i + 1].y - profile[i].y
		for j in range(PROFILE_STEPS + (1 if i == profile.size() - 2 else 0)):
			var t := float(j) / PROFILE_STEPS
			var t2 := t * t
			var t3 := t2 * t
			var r := (2.0 * t3 - 3.0 * t2 + 1.0) * profile[i].x + (t3 - 2.0 * t2 + t) * interval * slopes[i] + (-2.0 * t3 + 3.0 * t2) * profile[i + 1].x + (t3 - t2) * interval * slopes[i + 1]
			var derivative := ((6.0 * t2 - 6.0 * t) * profile[i].x + (3.0 * t2 - 4.0 * t + 1.0) * interval * slopes[i] + (-6.0 * t2 + 6.0 * t) * profile[i + 1].x + (3.0 * t2 - 2.0 * t) * interval * slopes[i + 1]) / interval
			var y := lerpf(profile[i].y, profile[i + 1].y, t)
			for k in range(RADIAL_SEGMENTS + 1):
				var radial := _radial(k)
				var normal := Vector3(radial.x * height, -radius * derivative, radial.y * height).normalized()
				if inward:
					normal = -normal
				_vertex(data, Vector3(radial.x * r * radius, (y - 0.5) * height, radial.y * r * radius), normal, Vector2(float(k) / RADIAL_SEGMENTS, y))
			rings += 1
	for row in range(rings - 1):
		for k in range(RADIAL_SEGMENTS):
			var a := first + row * (RADIAL_SEGMENTS + 1) + k
			var b := a + RADIAL_SEGMENTS + 1
			_quad(data, a, b, b + 1, a + 1, inward)

static func _annulus(data: Dictionary, outer: float, inner: float, y: float) -> void:
	var first: int = data.vertices.size()
	for radius in [outer, inner]:
		for k in range(RADIAL_SEGMENTS + 1):
			var radial := _radial(k)
			_vertex(data, Vector3(radial.x * radius, y, radial.y * radius), Vector3.UP, Vector2(0.5, 0.5) + radial * (radius / outer * 0.5))
	for k in range(RADIAL_SEGMENTS):
		var a := first + k
		var b := a + RADIAL_SEGMENTS + 1
		_quad(data, a, b, b + 1, a + 1, false)

static func _disk(data: Dictionary, radius: float, y: float, upward: bool) -> void:
	var first: int = data.vertices.size()
	var normal := Vector3.UP if upward else Vector3.DOWN
	_vertex(data, Vector3(0.0, y, 0.0), normal, Vector2(0.5, 0.5))
	for k in range(RADIAL_SEGMENTS + 1):
		var radial := _radial(k)
		_vertex(data, Vector3(radial.x * radius, y, radial.y * radius), normal, Vector2(0.5, 0.5) + radial * 0.5)
	for k in range(RADIAL_SEGMENTS):
		if upward:
			data.indices.append_array(PackedInt32Array([first, first + k + 1, first + k + 2]))
		else:
			data.indices.append_array(PackedInt32Array([first, first + k + 2, first + k + 1]))

static func _radial(segment: int) -> Vector2:
	# Duplicate the UV seam while retaining exactly coincident geometric vertices.
	var angle := TAU * float(segment % RADIAL_SEGMENTS) / RADIAL_SEGMENTS
	return Vector2(cos(angle), sin(angle))

static func _vertex(data: Dictionary, point: Vector3, normal: Vector3, uv: Vector2) -> void:
	data.vertices.append(point)
	data.normals.append(normal)
	data.uvs.append(uv)

static func _quad(data: Dictionary, a: int, b: int, c: int, d: int, flip: bool) -> void:
	# Godot uses clockwise front faces, opposite the ordinary cross-product normal.
	if flip:
		data.indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	else:
		data.indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
