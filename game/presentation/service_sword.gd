# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Authored morphology, not measured historical dimensions or a combat solver.
## The same blade and hilt move through an arc; the independent scabbard stays attached.
const Meshes:=preload("res://presentation/equipment_mesh.gd")
const RADIUS:=1.12
const ARC:=.78
const BLADE_WIDTH:=.042
const BLADE_THICKNESS:=.005
const SEGMENTS:=40
var sword: Node3D
var scabbard: Node3D
var fraction:=0.0
var fitted:=false

static func centreline(angle: float) -> Vector3:
	return Vector3(0,-RADIUS*sin(angle),RADIUS*(1.0-cos(angle)))

static func section(angle: float, side: int, sides: int, width: float, thickness: float) -> Vector3:
	var phase:=TAU*float(side)/float(sides)
	return centreline(angle)+Vector3.RIGHT*(cos(phase)*thickness)+Vector3(0,sin(angle),cos(angle))*(sin(phase)*width)

static func sweep(start: float, end: float, width: float, thickness: float, blade: bool=false) -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides:=4 if blade else 12
	for i in range(SEGMENTS):
		var u0:=float(i)/SEGMENTS
		var u1:=float(i+1)/SEGMENTS
		var a0:=lerpf(start,end,u0)
		var a1:=lerpf(start,end,u1)
		var taper0:=maxf(.002,1.0-pow(u0,7)) if blade else 1.0
		var taper1:=maxf(.002,1.0-pow(u1,7)) if blade else 1.0
		for j in range(sides):
			Meshes.quad(st,section(a0,j,sides,width*taper0,thickness*taper0),section(a1,j,sides,width*taper1,thickness*taper1),section(a1,j+1,sides,width*taper1,thickness*taper1),section(a0,j+1,sides,width*taper0,thickness*taper0))
	# Both blade ends close. The scabbard's throat remains open.
	if blade:
		for j in range(sides):
			Meshes.triangle(st,centreline(start),section(start,j,sides,width,thickness),section(start,j+1,sides,width,thickness))
			Meshes.triangle(st,centreline(end),section(end,j+1,sides,width*.002,thickness*.002),section(end,j,sides,width*.002,thickness*.002))
	return Meshes.finish(st)

func build(decorated: bool=false) -> void:
	fitted=decorated
	name="ServiceSword"
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	var steel:=Meshes.material("879598",.8,.32)
	var iron:=Meshes.material("393d3d",.65,.48)
	var trim:=Meshes.material("b39152",.72,.38) if fitted else iron
	var leather:=Meshes.material("302c29",0,.88)
	sword=Node3D.new()
	sword.name="Sword"
	add_child(sword)
	Meshes.part(sword,"Blade",sweep(0,ARC,BLADE_WIDTH/2,BLADE_THICKNESS/2,true),steel)
	var guard:=Meshes.cylinder(sword,"Crossguard",.011,.20,Vector3(0,.012,0),trim)
	guard.rotation.x=PI/2
	for z in [-.10,.10]:
		Meshes.sphere(sword,"QuillonLeft" if z<0 else "QuillonRight",.013,Vector3(0,.012,z),trim)
	Meshes.cylinder(sword,"Grip",.017,.118,Vector3(0,.083,0),leather)
	Meshes.cylinder(sword,"LowerFerrule",.019,.013,Vector3(0,.027,0),trim)
	Meshes.cylinder(sword,"UpperFerrule",.019,.013,Vector3(0,.142,0),trim)
	var pommel:=Meshes.sphere(sword,"Pommel",.025,Vector3(0,.157,-.006),trim)
	pommel.scale=Vector3(.65,.8,1.35)
	for i in range(8):
		Meshes.torus(sword,"GripBinding%d"%i,.0174,.001,Vector3(0,.039+i*.012,0),iron)
	scabbard=Node3D.new()
	scabbard.name="Scabbard"
	add_child(scabbard)
	Meshes.part(scabbard,"Cover",sweep(0,ARC+.018,.028,.011),leather)
	Meshes.part(scabbard,"Throat",sweep(0,.023,.030,.013),trim)
	Meshes.part(scabbard,"Chape",sweep(ARC-.07,ARC+.018,.029,.012),trim)
	for i in range(2):
		var angle:=.105+i*.26
		Meshes.part(scabbard,"SuspensionBand%d"%i,sweep(angle-.011,angle+.011,.030,.013),trim)
		var ring:=Meshes.torus(scabbard,"SuspensionRing%d"%i,.018,.003,centreline(angle)+Vector3(0,sin(angle),cos(angle))*.045,trim)
		ring.rotation.z=PI/2
	# Cap only the toe, leaving a real dark opening at the throat.
	var toe:=Meshes.sphere(scabbard,"Toe",.027,centreline(ARC+.018),trim)
	toe.scale=Vector3(.43,.45,1.0)
	toe.rotation.x=-ARC
	sample_draw(0.0)

func sample_draw(value: float) -> bool:
	if not is_finite(value) or value<0.0 or value>1.0 or not is_instance_valid(sword): return false
	fraction=value
	# Rotate about the common circle centre. Unlike linear translation, this keeps
	# the portion still inside the curved sheath on the original centreline.
	var basis:=Basis(Vector3.RIGHT,(ARC+.06)*fraction)
	var centre:=Vector3(0,0,RADIUS)
	sword.transform=Transform3D(basis,centre-basis*centre)
	return true

func presentation_state() -> String:
	if fraction==0.0: return "SHEATHED"
	if fraction==1.0: return "DRAWN"
	return "DRAWING" # Reversible scrub pose, not an authoritative action or clock.
