# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original procedural camp study, no researched site or independent simulation.
const Rules := preload("res://warband/nihang_rules.gd")
const Figure := preload("res://youth/performance/bazaar_figure.gd")
const Sword := preload("res://presentation/service_sword.gd")
var elder: Node3D
var marker: Label3D
var halt_marker: Label3D

func piece(size: Vector3, at: Vector3, color: String) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box
	var material:=StandardMaterial3D.new();material.albedo_color=Color(color);material.roughness=.95
	mesh.material_override=material;mesh.position=at;add_child(mesh);return mesh

static func dress(figure: Node3D) -> void:
	# A restrained blue cloth study. Precise period tailoring remains art research.
	for material in figure.palette.values():
		if material.albedo_color==Color("526c70"): material.albedo_color=Color("294965")
	figure.round_piece(figure.head,Vector3(.33,.32,.31),Vector3(0,.30,.005),Color("294965"))
	figure.round_piece(figure.head,Vector3(.18,.21,.10),Vector3(0,-.10,-.09),Color("5b554e"))
	var sword:=Sword.new();sword.build();figure.torso.add_child(sword)
	sword.position=Vector3(.30,.18,.14);sword.rotation.x=-.15

func build() -> void:
	name="AuthoredNihangCamp"
	set_meta("historical_status","authored-reconstruction-unverified-site")
	piece(Vector3(7,.025,7),Rules.CAMP+Vector3(0,-.025,0),"998969")
	# Open shade at the edge of the existing yard; no shrine interior or new geography.
	for z in [-2.0,2.0]: piece(Vector3(.12,2.6,.12),Rules.CAMP+Vector3(-2.4,1.3,z),"66513a")
	var shade:=piece(Vector3(2.5,.04,4.2),Rules.CAMP+Vector3(-1.3,2.58,0),"b1a080");shade.rotation.z=-.08
	for i in range(3): piece(Vector3(.42,.22,.7),Rules.CAMP+Vector3(-2.0,.11,.5+i*.55),"a18c53")
	piece(Vector3(1.4,.28,.45),Rules.CAMP+Vector3(4,.16,2.8),"735f45")
	piece(Vector3(1.25,.025,.32),Rules.CAMP+Vector3(4,.31,2.8),"617777")
	piece(Vector3(1.3,.04,1.8),Rules.CAMP+Vector3(.8,.005,1.8),"7d5f43")
	elder=Figure.new();add_child(elder);elder.build(4,false);dress(elder)
	elder.position=Rules.CAMP;elder.rotation.y=PI/2
	var caption:=Label3D.new();caption.text="Camp elder [E]";caption.position=Rules.CAMP+Vector3.UP*2.1
	caption.font_size=22;caption.pixel_size=.002;caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(caption)
	marker=Label3D.new();marker.text="North practice marker [E]";marker.position=Rules.TURN+Vector3.UP*2
	marker.font_size=22;marker.pixel_size=.002;marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(marker)
	for x in [-1.8,1.8]: piece(Vector3(.1,1.5,.1),Rules.TURN+Vector3(x,.75,0),"aa9569")
	halt_marker=Label3D.new();halt_marker.text="Low ground · halt and count [E]";halt_marker.position=Rules.HALT+Vector3.UP*1.4
	halt_marker.font_size=22;halt_marker.pixel_size=.002;halt_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(halt_marker)
	# Two low stones make the agreed halt readable without adding collision or geography.
	for z in [-1.2,1.2]: piece(Vector3(.7,.16,.42),Rules.HALT+Vector3(0,.08,z),"766a56")

func sample(tick: int, phase: String, halt_pending: bool=false) -> void:
	elder.sample(tick,0,"idle");elder.position=Rules.CAMP
	halt_marker.visible=phase=="outbound" and halt_pending
	marker.visible=phase=="outbound" and not halt_pending
