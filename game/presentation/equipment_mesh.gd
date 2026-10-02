# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Small native mesh helpers for the authored equipment study. Metres throughout.

static func material(color: String, metal: float=0.0, rough: float=.65) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=Color(color)
	result.metallic=metal
	result.roughness=rough
	return result

static func part(parent: Node3D, id: String, mesh: Mesh, surface: Material, at: Vector3=Vector3.ZERO) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.name=id
	node.mesh=mesh
	node.material_override=surface
	node.position=at
	parent.add_child(node)
	return node

static func cylinder(parent: Node3D, id: String, radius: float, height: float, at: Vector3, surface: Material) -> MeshInstance3D:
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=16
	return part(parent,id,mesh,surface,at)

static func sphere(parent: Node3D, id: String, radius: float, at: Vector3, surface: Material) -> MeshInstance3D:
	var mesh:=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2
	mesh.radial_segments=20
	mesh.rings=10
	return part(parent,id,mesh,surface,at)

static func torus(parent: Node3D, id: String, radius: float, tube: float, at: Vector3, surface: Material) -> MeshInstance3D:
	var mesh:=TorusMesh.new()
	mesh.inner_radius=radius-tube
	mesh.outer_radius=radius+tube
	mesh.rings=32
	mesh.ring_segments=8
	return part(parent,id,mesh,surface,at)

static func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	triangle(st,a,b,c)
	triangle(st,a,c,d)

static func finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	st.index()
	return st.commit()
