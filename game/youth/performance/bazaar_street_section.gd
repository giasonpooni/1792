# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Reference-derived street-section study: visual depth only, never route authority.
const Supply:=preload("res://territory/misl_rules.gd")
const Brawl:=preload("res://youth/brawl_rules.gd")
const LANE_HALF_WIDTH:=2.6
const EDGE_OFFSET:=4.15
var thresholds: Array[MeshInstance3D]=[]
var upper_screens: Array[MeshInstance3D]=[]
var awnings: Array[MeshInstance3D]=[]
var drains: Array[MeshInstance3D]=[]
var _materials: Dictionary={}
func mat(color: Color) -> StandardMaterial3D:
	var key:=color.to_html()
	if _materials.has(key):return _materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.98;_materials[key]=m;return m
func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var cube:=BoxMesh.new();cube.size=size;mesh.mesh=cube;mesh.name=name;mesh.position=pos;mesh.material_override=mat(color);parent.add_child(mesh);return mesh
func _basis() -> Dictionary:
	var start:=Supply.MARKET;var finish:=Brawl.RING
	var forward:=finish-start;forward.y=0;forward=forward.normalized()
	var side:=Vector3(-forward.z,0,forward.x)
	return {"start":start,"finish":finish,"forward":forward,"side":side}
func build() -> void:
	name="BazaarStreetSectionStudy";set_meta("classification","reference-derived-presentation-study")
	set_meta("reference_contract","dense_edges_dynamic_center")
	var g:=_basis();var start: Vector3=g.start;var finish: Vector3=g.finish;var forward: Vector3=g.forward;var side: Vector3=g.side
	for sign in [-1.0,1.0]:
		var drain_center: Vector3=(start+finish)*.5+side*(sign*(LANE_HALF_WIDTH+.18));drain_center.y=.135
		var drain:=box(self,"EdgeDrain",Vector3(.18,.025,start.distance_to(finish)),drain_center,Color("554b3d"));drain.rotation.y=atan2(forward.x,forward.z);drains.append(drain)
		for bay in range(4):
			var t:=.16+float(bay)*.225
			var center:=start.lerp(finish,t)+side*(sign*EDGE_OFFSET);center.y=.14
			var root:=Node3D.new();root.name="StreetBay_%s_%d"%["L" if sign<0 else "R",bay];root.position=center;root.rotation.y=atan2(forward.x,forward.z);add_child(root)
			var threshold:=box(root,"RaisedThreshold",Vector3(2.2,.18,1.25),Vector3(0,.09,0),Color("9a8261"));thresholds.append(threshold)
			box(root,"ThresholdWear",Vector3(.9,.012,.32),Vector3(0,.188,-.47),Color("725e47"))
			for x in [-.95,.95]:box(root,"Post",Vector3(.13,2.45,.13),Vector3(x,1.32,.26),Color("70563d"))
			box(root,"Lintel",Vector3(2.1,.16,.16),Vector3(0,2.46,.26),Color("70563d"))
			var awning:=box(root,"ShadeAwning",Vector3(2.25,.055,1.15),Vector3(0,2.15,-.20),Color("876b4f") if bay%2==0 else Color("6f7668"));awning.rotation.x=-.08*sign;awnings.append(awning)
			var upper:=box(root,"UpperProjection",Vector3(2.45,1.05,.72),Vector3(0,3.05,.36),Color("ad9677"));upper_screens.append(upper)
			for x in [-.72,-.36,0,.36,.72]:box(root,"ScreenSlat",Vector3(.045,.65,.055),Vector3(x,3.03,-.015),Color("67533e"))
			box(root,"UpperShadeLine",Vector3(2.5,.09,.82),Vector3(0,3.62,.36),Color("6e5740"))
func sample(tick: int) -> void:
	var time:=float(tick)/60.0
	for i in range(awnings.size()):awnings[i].rotation.z=sin(time*.72+i*.53)*.012
func central_lane_clear(point: Vector3) -> bool:
	var g:=_basis();var start: Vector3=g.start;var forward: Vector3=g.forward;var side: Vector3=g.side
	var local:=point-start
	var along:=local.dot(forward);var lateral:=absf(local.dot(side))
	return along>=-.5 and along<=start.distance_to(Brawl.RING)+.5 and lateral<=LANE_HALF_WIDTH
