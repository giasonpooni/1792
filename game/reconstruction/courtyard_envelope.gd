# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored prototype pier envelopes, not a survey or a new room.
const ORIGIN := Vector3(0,0.14,11.35)
static func attach(parent: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="CourtyardPierEnvelopes";parent.add_child(root)
	root.set_meta("classification","authored-collision-envelope")
	for i in range(9):
		var body:=StaticBody3D.new();body.name="Pier%d"%i;body.position=ORIGIN+Vector3(-17+i*4.25,0,0);root.add_child(body)
		for pair in [[Vector3(0,0.11,0),Vector3(0.46,0.22,0.46)],[Vector3(0,1.15,0),Vector3(0.40,2.10,0.40)],[Vector3(0,2.16,0),Vector3(0.54,0.14,0.46)]]:
			var shape:=BoxShape3D.new();shape.size=pair[1]
			var c:=CollisionShape3D.new();c.position=pair[0];c.shape=shape;body.add_child(c)
	return root
static func infill() -> ArrayMesh:
	var verts:=PackedVector3Array();var normals:=PackedVector3Array();var indices:=PackedInt32Array()
	for k in range(49):
		var x: float=-2.125+4.25*k/48.0
		var y: float=2.1+1.19*sqrt(maxf(0,1-pow(x/2.125,2)))
		verts.append(Vector3(x,y,.03));verts.append(Vector3(x,3.32,.03))
		normals.append(Vector3.FORWARD);normals.append(Vector3.FORWARD)
		if k<48:
			var j:=2*k;indices.append_array(PackedInt32Array([j,j+2,j+1,j+1,j+2,j+3]))
	var a: Array=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=verts;a[Mesh.ARRAY_NORMAL]=normals;a[Mesh.ARRAY_INDEX]=indices
	var m:=ArrayMesh.new();m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a);return m
