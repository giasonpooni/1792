# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Pure presentation: samples the game-owned ledger/tick; never creates water or advances time.
const Rules := preload("res://territory/water_round_rules.gd")
var bucket: Node3D
var carried: Node3D
var tank_water: MeshInstance3D
var tank_shell: MeshInstance3D
var carried_water: MeshInstance3D
var carried_shell: MeshInstance3D
var well_label: Label3D
var bucket_water: MeshInstance3D

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, open_top: bool=false) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius*0.85
	shape.height=height
	shape.cap_top=not open_top
	mesh.mesh=shape
	mesh.position=at
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.85
	if open_top: m.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=m
	parent.add_child(mesh)
	return mesh

func build(avatar: Node3D) -> void:
	bucket=Node3D.new()
	bucket.position=Rules.WELL+Vector3(0,0.6,0)
	add_child(bucket)
	_cylinder(bucket,Vector3.ZERO,0.28,0.5,Color("886b48"),true)
	bucket_water=_cylinder(bucket,Vector3(0,0.22,0),0.245,0.025,Color("65908e"))
	bucket_water.hide()
	carried=Node3D.new()
	carried.name="OpenWaterCarrier"
	avatar.add_child(carried)
	carried.position=Vector3(0.65,0.65,0)
	carried_shell=_cylinder(carried,Vector3.ZERO,0.23,0.5,Color("977347"),true)
	carried_water=_cylinder(carried,Vector3(0,0.23,0),0.21,0.025,Color("65908e"))
	carried.hide()
	# Cosmetic household receptacle, not an added route obstacle or surveyed tank.
	var at:=Vector3(6.5,0.14,4)
	tank_shell=_cylinder(self,at+Vector3.UP*0.45,0.7,0.9,Color("ad8563"),true)
	tank_water=_cylinder(self,at+Vector3.UP*0.88,0.59,0.025,Color("65908e"))
	tank_water.hide()
	well_label=Label3D.new()
	well_label.position=Rules.WELL+Vector3.UP*3.2
	well_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	well_label.font_size=32
	well_label.pixel_size=0.007
	add_child(well_label)

func sample(w: Dictionary, tick: int) -> void:
	if not is_instance_valid(bucket): return
	well_label.visible=not w.is_empty()
	bucket.visible=not w.is_empty()
	if w.is_empty():
		carried.hide()
		tank_water.hide()
		bucket_water.hide()
		return
	var s: Dictionary=w.ledger
	carried.visible=s.carried>0
	tank_water.visible=s.stored>0
	tank_water.position.y=0.2+0.8*clampf(float(s.stored)/Rules.TOTAL,0,1)
	var phase: float=clampf(float(tick-s.started_tick)/Rules.DRAW_TICKS,0,1) if s.phase=="drawing" else 1.0
	bucket_water.visible=s.phase=="drawing" and phase>0.6
	bucket.position=Rules.WELL+Vector3(0,0.3+0.95*phase,0)
	well_label.text="Load %d of 2 · raising %d%%"%[int(s.stored)/Rules.LOAD+1,int(phase*100)] if s.phase=="drawing" else "Well [E] · " + ("round complete" if s.phase=="complete" else "one load left" if s.stored==3 else "household round")

static func status(w: Dictionary, tick: int) -> String:
	if w.is_empty(): return "Water round · Ask the quartermaster."
	var s: Dictionary=w.ledger
	var next: String
	match s.phase:
		"ready": next="East lane to the well [E]." if int(s.stored)==0 else "One more load from the east well [E]."
		"drawing": next="Raising %d%% · Stay beside the well; stepping away cancels."%clampi(int(100.0*(tick-s.started_tick)/Rules.DRAW_TICKS),0,100)
		"carrying": next="Walk the open load home · Quartermaster [E] to deposit."
		_: next="Both loads delivered."
	return "WATER · %d/2 loads home · %s"%[int(s.stored)/Rules.LOAD,next]
