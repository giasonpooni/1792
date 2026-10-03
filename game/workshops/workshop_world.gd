# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## A state-projected workplace. Props, pose and sound never own production or money.
const Craft := preload("res://workshops/workshop_rules.gd")
const Kit := preload("res://presentation/workshop_kit.gd")
var kit := Kit.new()
var smith_arm: Node3D
var coal: MeshInstance3D
var finished: Node3D
var unfinished: Node3D
var waiting_blanks: Array[Node3D]=[]
var active_blank: Node3D
var carried: Node3D
var hammer_audio: AudioStreamPlayer3D
var last_tick := -1
var strike_count := 0
var _last_phase := ""

func build(avatar: Node3D) -> void:
	name="HouseholdWorkshop"
	set_meta("classification","original_connective_fiction_not_surveyed")
	var wood:=kit.surface("715640",2)
	var steel:=kit.plain("5b6060",0.45)
	var earth:=kit.surface("9c7859")
	var base:=Node3D.new();base.position=Craft.SITE;add_child(base)
	# Sheltered west-side station; original Home colliders and routes are unchanged.
	kit.box(base,Vector3(0,0.01,0),Vector3(6,0.02,4.8),kit.surface("aa8b67",3))
	_solid(base,Vector3(0,0.31,-0.8),Vector3(0.68,0.62,0.64),wood)
	_solid(base,Vector3(0,0.74,-0.8),Vector3(1.05,0.24,0.44),steel)
	kit.ellipsoid(base,Vector3(0.5,0.78,-0.8),Vector3(0.45,0.14,0.28),steel)
	_solid(base,Vector3(-2.25,0.38,-1.4),Vector3(1.15,0.76,1.1),earth)
	coal=kit.box(base,Vector3(-2.25,0.775,-1.4),Vector3(0.85,0.035,0.8),kit.plain("d97b38"))
	_solid(base,Vector3(0.1,0.94,1.3),Vector3(2.0,0.14,0.75),wood)
	for x in [-0.75,0.95]:
		for z in [1.03,1.57]: kit.box(base,Vector3(x,0.43,z),Vector3(0.12,0.86,0.12),wood)
	for x in [-2.8,1.9]:
		kit.rod(base,Vector3(x,0,0),Vector3(x,2.75,0),0.06,wood)
	kit.rod(base,Vector3(-2.8,2.7,0),Vector3(1.9,2.7,0),0.065,wood)
	kit.canopy(base,Vector3(-0.45,2.68,0.1),Vector2(4.7,3.8),"b49a73","7b6553")
	kit.pot(base,Vector3(1.6,0,1.3),0.55)
	# The same bench carries the setup and payoff: raw heads, then handled tools,
	# then the space left behind by collection. These props never grant inventory.
	unfinished=Node3D.new();unfinished.name="UnfinishedPair";unfinished.position=Vector3(0.1,1.04,1.3);base.add_child(unfinished)
	var raw_steel:=kit.plain("454a4b",0.25)
	for x in [-0.45,0.4]:
		var blank:=Node3D.new();blank.position.x=x;unfinished.add_child(blank)
		_blank(blank,raw_steel);waiting_blanks.append(blank)
	active_blank=Node3D.new();active_blank.name="BlankOnAnvil";active_blank.position=Vector3(0.12,0.895,-0.8);base.add_child(active_blank)
	_blank(active_blank,kit.plain("9a6950",0.25))
	finished=Node3D.new();finished.name="FinishedPair";finished.position=Vector3(0.1,1.04,1.3);base.add_child(finished)
	_tools(finished,wood,steel)
	# Original articulated costume proxy, not a researched named artisan or production rig.
	var person:=Node3D.new();person.name="FictionalSmith";base.add_child(person)
	var cloth:=kit.surface("746f62",4);var skin:=kit.plain("a87a59")
	for x in [-0.13,0.13]:
		kit.ellipsoid(person,Vector3(x,0.39,0),Vector3(0.22,0.7,0.25),cloth)
		kit.ellipsoid(person,Vector3(x,0.07,-0.06),Vector3(0.23,0.14,0.34),wood)
	kit.ellipsoid(person,Vector3(0,0.95,0),Vector3(0.62,0.72,0.37),cloth)
	kit.box(person,Vector3(0,0.79,-0.215),Vector3(0.45,0.52,0.05),kit.surface("70513e",4))
	kit.ellipsoid(person,Vector3(0,1.53,0),Vector3(0.33,0.38,0.3),skin)
	kit.ellipsoid(person,Vector3(0,1.68,0.02),Vector3(0.46,0.25,0.38),kit.surface("c2b195",4))
	for x in [-0.065,0.065]: kit.ellipsoid(person,Vector3(x,1.56,-0.146),Vector3(0.025,0.025,0.016),kit.plain("302c26"))
	kit.ellipsoid(person,Vector3(0,1.45,-0.15),Vector3(0.17,0.09,0.08),kit.plain("44362a"))
	kit.rod(person,Vector3(-0.28,1.22,0),Vector3(-0.31,0.74,-0.18),0.095,cloth)
	smith_arm=Node3D.new();smith_arm.position=Vector3(0.24,1.23,0);person.add_child(smith_arm)
	kit.rod(smith_arm,Vector3.ZERO,Vector3(0,-0.45,-0.2),0.09,cloth)
	kit.ellipsoid(smith_arm,Vector3(0,-0.5,-0.21),Vector3(0.17,0.17,0.18),skin)
	kit.rod(smith_arm,Vector3(0,-0.43,-0.16),Vector3(0,-0.51,-0.78),0.038,wood)
	kit.box(smith_arm,Vector3(0,-0.51,-0.78),Vector3(0.32,0.16,0.17),steel)
	var label:=Label3D.new();label.text="Smith [E] · household tools";label.position=Vector3(-0.3,3.05,0)
	label.font_size=25;label.pixel_size=0.0025;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;base.add_child(label)
	carried=Node3D.new();carried.name="WorkshopLoad";carried.position=Vector3(0.5,0.75,-0.15);avatar.add_child(carried)
	for x in [-0.16,0.08]: kit.box(carried,Vector3(x,0,0),Vector3(0.16,0.15,0.75),wood)
	kit.box(carried,Vector3(0,0.09,0),Vector3(0.43,0.035,0.14),kit.surface("c4ad81",4))
	var heads:=Node3D.new();heads.name="ToolHeads";carried.add_child(heads)
	for x in [-0.16,0.08]: kit.box(heads,Vector3(x,0,-0.34),Vector3(0.28,0.13,0.14),steel)
	hammer_audio=AudioStreamPlayer3D.new();hammer_audio.name="OriginalSyntheticHammer"
	hammer_audio.stream=_strike_stream();hammer_audio.position=Craft.SITE+Vector3(0,0.9,-0.8)
	hammer_audio.volume_db=-15;hammer_audio.max_distance=16;add_child(hammer_audio)
	sample(0,"unassigned",-1)

func _solid(parent: Node3D,at: Vector3,size: Vector3,material: Material) -> void:
	var body:=StaticBody3D.new();body.position=at;parent.add_child(body)
	kit.box(body,Vector3.ZERO,size,material)
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)

func _tools(parent: Node3D,wood: Material,steel: Material) -> void:
	for x in [-0.45,0.4]:
		kit.box(parent,Vector3(x,0,0),Vector3(0.12,0.08,0.62),wood)
		kit.box(parent,Vector3(x,0,-0.25),Vector3(0.32,0.12,0.15),steel)

func _blank(parent: Node3D,steel: Material) -> void:
	# Unhafted stock: a broad head and a short rough tang, visibly unlike the
	# long wooden handles on the finished pair. No historical tool-type claim.
	kit.box(parent,Vector3(0,0,-0.1),Vector3(0.31,0.065,0.30),steel)
	kit.box(parent,Vector3(0,0,0.14),Vector3(0.14,0.06,0.19),steel)

static func _strike_stream() -> AudioStreamWAV:
	# Original damped partials: a prototype cue, not an authentic historical recording.
	var bytes:=PackedByteArray();bytes.resize(7056*2)
	for i in range(7056):
		var t:=float(i)/22050.0
		var wave:=0.38*exp(-t*28.0)*(sin(TAU*710.0*t)+0.4*sin(TAU*1710.0*t)+0.2*sin(TAU*2780.0*t))
		bytes.encode_s16(i*2,int(clampf(wave,-1.0,1.0)*32767.0))
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.stereo=false;stream.data=bytes
	return stream

func sample(tick: int,phase: String,started_tick: int) -> void:
	if not is_instance_valid(smith_arm): return
	var continuous:=last_tick>=0 and tick==last_tick+1 and _last_phase=="working"
	var elapsed:=maxi(0,tick-started_tick)
	var cycle:=posmod(elapsed,72)
	smith_arm.rotation.x=0.68*(1.0-cos(TAU*float(cycle)/72.0)) if phase=="working" else 0.15
	coal.visible=phase=="working";finished.visible=phase=="ready";carried.visible=phase in ["fuel","tools"]
	unfinished.visible=phase in ["unassigned","fuel","working"]
	waiting_blanks[0].visible=phase!="working"
	waiting_blanks[1].visible=true
	active_blank.visible=phase=="working"
	carried.get_node("ToolHeads").visible=phase=="tools"
	kit.sample(tick)
	if continuous and phase=="working" and cycle==0:
		hammer_audio.play();strike_count+=1
	elif tick<last_tick or phase!="working": hammer_audio.stop()
	last_tick=tick;_last_phase=phase

func _exit_tree() -> void:
	if is_instance_valid(carried): carried.queue_free()
