# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Pure presentation: samples the game-owned ledger/tick; never creates water or advances time.
const Rules := preload("res://territory/water_round_rules.gd")
var bucket: Node3D
var carried: Node3D
var tank_water: MeshInstance3D
var well_label: Label3D

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius*0.85
	shape.height=height
	mesh.mesh=shape
	mesh.position=at
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.85
	mesh.material_override=m
	parent.add_child(mesh)
	return mesh

func build(avatar: Node3D) -> void:
	bucket=Node3D.new()
	bucket.position=Rules.WELL+Vector3(0,0.6,0)
	add_child(bucket)
	_cylinder(bucket,Vector3.ZERO,0.28,0.5,Color("886b48"))
	carried=Node3D.new()
	carried.name="OpenWaterCarrier"
	avatar.add_child(carried)
	carried.position=Vector3(0.65,0.65,0)
	_cylinder(carried,Vector3.ZERO,0.23,0.5,Color("977347"))
	_cylinder(carried,Vector3(0,0.23,0),0.21,0.025,Color("65908e"))
	carried.hide()
	# Cosmetic household receptacle, not an added route obstacle or surveyed tank.
	var at:=Vector3(6,0.14,8.5)
	_cylinder(self,at+Vector3.UP*0.45,0.7,0.9,Color("ad8563"))
	tank_water=_cylinder(self,at+Vector3.UP*0.88,0.59,0.025,Color("65908e"))
	tank_water.hide()
	well_label=Label3D.new()
	well_label.position=Rules.WELL+Vector3.UP*3.2
	well_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	well_label.font_size=22
	well_label.pixel_size=0.003
	add_child(well_label)

func sample(w: Dictionary, tick: int) -> void:
	if not is_instance_valid(bucket): return
	well_label.visible=not w.is_empty()
	bucket.visible=not w.is_empty()
	if w.is_empty():
		carried.hide()
		tank_water.hide()
		return
	var s: Dictionary=w.ledger
	carried.visible=s.carried>0
	tank_water.visible=s.stored>0
	var phase: float=clampf(float(tick-s.started_tick)/Rules.DRAW_TICKS,0,1) if s.phase=="drawing" else 1.0
	bucket.position=Rules.WELL+Vector3(0,0.3+0.95*phase,0)
	well_label.text="Well [E] · raising %d%%"%int(phase*100) if s.phase=="drawing" else "Well [E] · household round"

static func status(w: Dictionary, tick: int) -> String:
	if w.is_empty(): return "Optional water round: ask the quartermaster after the allowance."
	var s: Dictionary=w.ledger
	var next: String
	match s.phase:
		"ready": next="Take the east lane around the courtyard wall to the well [E]."
		"drawing": next="Drawing: %d/%d ticks; leaving the well cancels without consuming water."%[tick-s.started_tick,Rules.DRAW_TICKS]
		"carrying": next="Carry the open vessel home; walking pace capped. Deposit with the quartermaster [E]."
		_: next="Round complete. Six assigned units delivered; no repeat payout."
	return "WATER ROUND · Store %d/6 · Carry %d/3 · Assignment remaining %d\n%s"%[s.stored,s.carried,s.remaining,next]
