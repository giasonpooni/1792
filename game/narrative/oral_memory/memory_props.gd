# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original non-colliding rope study: a repaired loop and a visibly worn end.
static func strand(parent: Node3D,a: Vector3,b: Vector3,radius: float,color: Color) -> void:
	var mesh:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius;cylinder.bottom_radius=radius;cylinder.height=a.distance_to(b)
	cylinder.radial_segments=6;mesh.mesh=cylinder
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1.0
	mesh.material_override=material;mesh.position=(a+b)*.5
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized());parent.add_child(mesh)

static func build(parent: Node3D,at: Vector3) -> Node3D:
	var rope:=Node3D.new();rope.name="RepairedRopeStudy";rope.position=at;parent.add_child(rope)
	var flax:=Color("ad9365");var repair:=Color("ded0a5")
	for layer in range(3):
		for i in range(24):
			var angle:=TAU*float(i)/24.0;var next:=TAU*float(i+1)/24.0
			strand(rope,Vector3(cos(angle)*.23,.78+layer*.035,sin(angle)*.16),Vector3(cos(next)*.23,.78+layer*.035,sin(next)*.16),.018,flax)
	# A lighter binding crosses the same loop; material difference is visible,
	# while the trace still says nothing about permission or who handled it.
	for i in range(7):
		var z: float=-.065+float(i)*.019
		strand(rope,Vector3(.19,.855,z),Vector3(.26,.855,z),.012,repair)
	strand(rope,Vector3(-.22,.81,.04),Vector3(-.36,.79,.17),.020,flax)
	for i in range(5):
		strand(rope,Vector3(-.36,.79,.17),Vector3(-.42-float(i)*.012,.785,.13+float(i)*.025),.0045,flax.lightened(.12))
	return rope
