# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Visual breadcrumbs from bazaar toward home; no navigation or objective authority.
const Brawl:=preload("res://youth/brawl_rules.gd")
var marks: Array[MeshInstance3D]=[]
func build() -> void:
	name="BazaarDepartureStudy"
	var start:=Brawl.RING;var finish:=Brawl.REGROUP
	for i in range(1,6):
		var p:=start.lerp(finish,float(i)/6.0);p.y=.025
		var mesh:=MeshInstance3D.new();mesh.name="RoadWear"+str(i)
		var plane:=PlaneMesh.new();plane.size=Vector2(1.1,.34);mesh.mesh=plane;mesh.position=p
		mesh.rotation.y=atan2(finish.x-start.x,finish.z-start.z)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.22,0.17,0.12,.18);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.roughness=1
		mesh.material_override=mat;add_child(mesh);marks.append(mesh)
func sample(tick: int,active: bool) -> void:
	for i in range(marks.size()):
		var m:=marks[i];m.visible=active
		if active:m.scale=Vector3.ONE*(1.0+.025*sin(float(tick)/45.0+i))
