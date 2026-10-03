# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Photo-informed visual additions within the existing courtyard composition.
## Dimensions and profiles are authored. No bodies, navigation, clock or save owner.
const EVIDENCE_PATH := "res://data/courtyard_fabric.v1.json"
const ORIGIN := Vector3(0, .14, 11.35)
var evidence_digest := ""
var evidence: Dictionary = {}
var shafts: Array[MeshInstance3D] = []
var groups: Array[MeshInstance3D] = []
var _built := false

func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var corners: Array[Vector3] = [a,b,c]
	if (b-a).cross(c-a).dot(normal)>=0: corners = [a,c,b]
	for p in corners:
		st.set_normal(normal)
		st.add_vertex(p)

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	# Godot front faces use clockwise winding; normals remain explicit.
	var corners: Array[Vector3] = [a,b,c,a,c,d]
	if (b-a).cross(c-a).dot(normal) > 0:
		corners = [a,c,b,a,d,c]
	for p in corners:
		st.set_normal(normal)
		st.add_vertex(p)

func box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var lo := center-size*.5
	var hi := center+size*.5
	quad(st,Vector3(lo.x,lo.y,lo.z),Vector3(hi.x,lo.y,lo.z),Vector3(hi.x,hi.y,lo.z),Vector3(lo.x,hi.y,lo.z),Vector3.FORWARD)
	quad(st,Vector3(lo.x,lo.y,hi.z),Vector3(hi.x,lo.y,hi.z),Vector3(hi.x,hi.y,hi.z),Vector3(lo.x,hi.y,hi.z),Vector3.BACK)
	quad(st,Vector3(lo.x,hi.y,lo.z),Vector3(hi.x,hi.y,lo.z),Vector3(hi.x,hi.y,hi.z),Vector3(lo.x,hi.y,hi.z),Vector3.UP)
	quad(st,Vector3(lo.x,lo.y,lo.z),Vector3(hi.x,lo.y,lo.z),Vector3(hi.x,lo.y,hi.z),Vector3(lo.x,lo.y,hi.z),Vector3.DOWN)
	quad(st,Vector3(lo.x,lo.y,lo.z),Vector3(lo.x,hi.y,lo.z),Vector3(lo.x,hi.y,hi.z),Vector3(lo.x,lo.y,hi.z),Vector3.LEFT)
	quad(st,Vector3(hi.x,lo.y,lo.z),Vector3(hi.x,hi.y,lo.z),Vector3(hi.x,hi.y,hi.z),Vector3(hi.x,lo.y,hi.z),Vector3.RIGHT)

func surface() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func finish(st: SurfaceTool, id: String, material: Material, photos: Array) -> MeshInstance3D:
	st.index()
	var mesh := MeshInstance3D.new()
	mesh.name = id
	mesh.mesh = st.commit()
	mesh.material_override = material
	mesh.set_meta("photo_ids",photos.duplicate())
	mesh.set_meta("evidence_digest",evidence_digest)
	mesh.set_meta("historically_authenticated",false)
	add_child(mesh)
	groups.append(mesh)
	return mesh

func profile(t: float) -> Vector2:
	# Five lobes on the existing ellipse. Not a traced or measured historic profile.
	return Vector2(1.89*cos(t),2.1+.89*sin(t)-.20*(1.0-absf(sin(5*t)))*sin(t))

func arch(st: SurfaceTool, x: float) -> void:
	for i in range(80):
		var t0 := PI*float(i)/80.0
		var t1 := PI*float(i+1)/80.0
		var inner0 := profile(t0)
		var inner1 := profile(t1)
		var outer0 := Vector2(1.89*cos(t0),2.1+.89*sin(t0)+.055)
		var outer1 := Vector2(1.89*cos(t1),2.1+.89*sin(t1)+.055)
		var a := Vector3(x+inner0.x,inner0.y,-.22)
		var b := Vector3(x+inner1.x,inner1.y,-.22)
		var c := Vector3(x+outer1.x,outer1.y,-.22)
		var d := Vector3(x+outer0.x,outer0.y,-.22)
		var depth := Vector3(0,0,.46)
		quad(st,a,b,c,d,Vector3.FORWARD)
		quad(st,a+depth,b+depth,c+depth,d+depth,Vector3.BACK)
		var inner_normal := Vector3(-(inner1.y-inner0.y),inner1.x-inner0.x,0).normalized()
		quad(st,a,b,b+depth,a+depth,inner_normal)
		var outer_normal := Vector3(outer1.y-outer0.y,-(outer1.x-outer0.x),0).normalized()
		quad(st,d,c,c+depth,d+depth,outer_normal)
		if i == 0: quad(st,a,d,d+depth,a+depth,Vector3.RIGHT)
		if i == 79: quad(st,b,c,c+depth,b+depth,Vector3.LEFT)

func shaft(st: SurfaceTool, center: Vector2) -> void:
	var levels: Array[Vector2] = [Vector2(.36,.080),Vector2(.40,.085),Vector2(.47,.077),Vector2(1.82,.068),Vector2(1.89,.084),Vector2(1.96,.084)]
	for j in range(levels.size()-1):
		for k in range(24):
			var a0 := TAU*float(k)/24.0
			var a1 := TAU*float(k+1)/24.0
			var low: Vector2 = levels[j]
			var high: Vector2 = levels[j+1]
			var a := Vector3(center.x+low.y*cos(a0),low.x,center.y+low.y*sin(a0))
			var b := Vector3(center.x+low.y*cos(a1),low.x,center.y+low.y*sin(a1))
			var c := Vector3(center.x+high.y*cos(a1),high.x,center.y+high.y*sin(a1))
			var d := Vector3(center.x+high.y*cos(a0),high.x,center.y+high.y*sin(a0))
			var mid := (a0+a1)*.5
			quad(st,a,b,c,d,Vector3(cos(mid),(low.y-high.y)/(high.x-low.x),sin(mid)).normalized())
	for index in [0,levels.size()-1]:
		var level: Vector2 = levels[index]
		var normal := Vector3.DOWN if index==0 else Vector3.UP
		var at := Vector3(center.x,level.x,center.y)
		for k in range(24):
			var a0 := TAU*float(k)/24.0
			var a1 := TAU*float(k+1)/24.0
			triangle(st,at,at+Vector3(level.y*cos(a0),0,level.y*sin(a0)),at+Vector3(level.y*cos(a1),0,level.y*sin(a1)),normal)

func build(detail: Node3D) -> String:
	if _built: return "Courtyard fabric already attached."
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVIDENCE_PATH))
	if not parsed is Dictionary or parsed.get("schema") != "1792.courtyard-fabric.v1" or parsed.get("historically_authenticated") != false or parsed.get("gameplay_authority") != false:
		return "Invalid courtyard fabric evidence."
	evidence = parsed
	evidence_digest = FileAccess.get_sha256(EVIDENCE_PATH)
	position = ORIGIN
	set_meta("classification","photo-informed-original-detail")
	set_meta("evidence_digest",evidence_digest)
	set_meta("historically_authenticated",false)
	set_meta("gameplay_authority",false)
	var plaster: Material = detail.material(Color("baae96"),0)
	# Authored warm trim tone makes the profile readable; not a dated finish claim.
	var trim: Material = detail.material(Color("a99a82"),0)
	var reveal := surface()
	var panels := surface()
	var inset := surface()
	var timber := surface()
	for i in range(8):
		var x := -14.875+float(i)*4.25
		arch(reveal,x)
		for side in [-1.0,1.0]:
			var px: float = x+side*1.40
			box(inset,Vector3(px,2.27,.353),Vector3(.66,.35,.016))
			for dx in [-.35,.35]: box(panels,Vector3(px+dx,2.27,.29),Vector3(.045,.43,.065))
			for y in [2.065,2.475]: box(panels,Vector3(px,y,.29),Vector3(.745,.04,.065))
	finish(reveal,"CuspedArchReveals",trim,["HAV01","HAV03","HAV06"])
	finish(panels,"RecessPanelFrames",plaster,["HAV03","HAV06"])
	finish(inset,"RecessPanelFaces",detail.material(Color("a99c86"),0),["HAV03","HAV06"])
	for i in range(9):
		var st := surface()
		for dx in [-.075,.075]:
			for dz in [-.11,.11]: shaft(st,Vector2(dx,dz))
		var mesh := finish(st,"GroupedShafts%d"%i,trim,["HAV03","HAV06"])
		mesh.position.x = -17.0+float(i)*4.25
		shafts.append(mesh)
	# Longitudinal bearers below the existing transverse rafters.
	for z in [-.72,.90]: box(timber,Vector3(0,3.225,z),Vector3(34.46,.18,.17))
	finish(timber,"TimberBearers",detail.material(Color("68513e"),2),["HAV03"])
	_built = true
	return ""
