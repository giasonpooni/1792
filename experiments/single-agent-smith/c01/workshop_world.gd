# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## A state-projected workplace. Props, pose and sound never own production or money.
const Craft := preload("res://workshops/workshop_rules.gd")
const Kit := preload("res://presentation/workshop_kit.gd")
var kit := Kit.new()
var smith_arm: Node3D
var coal: MeshInstance3D
var finished: Node3D
var carried: Node3D
var hammer_audio: AudioStreamPlayer3D
var last_tick := -1
var strike_count := 0
var _last_phase := ""

func build(avatar: Node3D) -> void:
	name="HouseholdWorkshop"
	set_meta("classification","original_connective_fiction_not_surveyed")
	var wood:=kit.surface("65503d",2)
	var steel:=kit.plain("555b5d",0.65)
	var earth:=kit.surface("9c7859")
	var base:=Node3D.new();base.position=Craft.SITE;add_child(base)
	# Sheltered west-side station; original Home colliders and routes are unchanged.
	kit.box(base,Vector3(0,0.01,0),Vector3(6,0.02,4.8),kit.surface("aa8b67",3))
	_solid(base,Vector3(0,0.31,-0.8),Vector3(0.68,0.62,0.64),wood)
	_solid(base,Vector3(0,0.74,-0.8),Vector3(1.05,0.24,0.44),steel)
	kit.ellipsoid(base,Vector3(0.5,0.78,-0.8),Vector3(0.45,0.14,0.28),steel)
	_solid(base,Vector3(-2.25,0.38,-1.4),Vector3(1.15,0.76,1.1),earth)
	coal=kit.box(base,Vector3(-2.25,0.775,-1.4),Vector3(0.85,0.035,0.8),kit.plain("292421"))
	_solid(base,Vector3(0.1,0.94,1.3),Vector3(2.0,0.14,0.75),wood)
	for x in [-0.75,0.95]:
		for z in [1.03,1.57]: kit.box(base,Vector3(x,0.43,z),Vector3(0.12,0.86,0.12),wood)
	for x in [-2.8,1.9]:
		kit.rod(base,Vector3(x,0,0),Vector3(x,2.75,0),0.06,wood)
	kit.rod(base,Vector3(-2.8,2.7,0),Vector3(1.9,2.7,0),0.065,wood)
	kit.canopy(base,Vector3(-0.45,2.68,0.1),Vector2(4.7,3.8),"b6a384","918267")
	kit.pot(base,Vector3(1.6,0,1.3),0.55)
	_construction_detail(base)
	_ember_detail()
	finished=Node3D.new();finished.position=Vector3(0.1,1.04,1.3);base.add_child(finished)
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

func _detail_batch(parent: Node3D, boxes: Array, glow: bool = false) -> void:
	# Original low-poly decorative joinery. One draw surface per batch, no colliders.
	# Small color variation is baked into vertices; there is no stochastic runtime.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),
		Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]
	var triangles := [0,2,1,0,3,2,4,5,6,4,6,7,0,1,5,0,5,4,
		3,7,6,3,6,2,0,4,7,0,7,3,1,2,6,1,6,5]
	for box in boxes:
		var at: Vector3 = box[0]
		var size: Vector3 = box[1]
		surface.set_color(Color(box[2]))
		for index in triangles:
			surface.add_vertex(at + corners[index] * size * 0.5)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	if glow:
		material.emission_enabled = true
		material.emission = Color("c75d1e")
		material.emission_energy_multiplier = 0.55
	kit.mesh_at(parent,surface.commit(),Vector3.ZERO,material)

func _construction_detail(base: Node3D) -> void:
	# Keep the four existing bodies/shapes and the workplace envelope exactly intact.
	# Details are presentation only, not new stock, fuel, interactables or history.
	var boxes: Array = []
	# Front and rear bench aprons, pegs, and three understated plank joints.
	for z in [0.98,1.62]:
		boxes.append([Vector3(0.1,0.81,z),Vector3(1.91,0.13,0.07),"58432f"])
		for x in [-0.75,0.95]:
			boxes.append([Vector3(x,0.83,z-0.041),Vector3(0.045,0.045,0.018),"332b24"])
	for z in [1.12,1.30,1.48]:
		boxes.append([Vector3(0.1,1.012,z),Vector3(1.94,0.005,0.014),"3d3127"])
	# Recessed-looking binding strips on the anvil stump, not larger collision.
	for y in [0.16,0.53]:
		for x in [-0.344,0.344]:
			boxes.append([Vector3(x,y,-0.8),Vector3(0.009,0.05,0.62),"403f3a"])
		for z in [-1.124,-0.476]:
			boxes.append([Vector3(0,y,z),Vector3(0.67,0.05,0.009),"403f3a"])
	# A small mortared curb breaks up the original featureless forge top.
	for i in range(5):
		var x := -2.70 + float(i)*0.225
		var pigment := "795b43" if i%2==0 else "886a4b"
		for z in [-1.87,-0.93]:
			boxes.append([Vector3(x,0.82,z),Vector3(0.215,0.14,0.16),pigment])
	for i in range(3):
		for x in [-2.77,-1.73]:
			boxes.append([Vector3(x,0.82,-1.63+float(i)*0.23),Vector3(0.13,0.14,0.22),"826449"])
	# Cloth edge hems add a legible silhouette without changing canopy timing/math.
	for z in [-1.795,1.995]:
		boxes.append([Vector3(-0.45,2.57,z),Vector3(4.66,0.055,0.018),"8e7757"])
	_detail_batch(base,boxes)

func _ember_detail() -> void:
	# Children inherit the original coal visibility; no extra lights/clock/particles.
	var dark: Array = []
	var hot: Array = []
	for i in range(5):
		for j in range(4):
			var x := (float(i)-2.0)*0.15
			var z := (float(j)-1.5)*0.16
			dark.append([Vector3(x,0.035,z),Vector3(0.115,0.055,0.12),"39302a"])
			if (i+j)%3==0:
				hot.append([Vector3(x+0.045,0.041,z+0.055),Vector3(0.04,0.025,0.045),"d27832"])
	_detail_batch(coal,dark)
	_detail_batch(coal,hot,true)

func _solid(parent: Node3D,at: Vector3,size: Vector3,material: Material) -> void:
	var body:=StaticBody3D.new();body.position=at;parent.add_child(body)
	kit.box(body,Vector3.ZERO,size,material)
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)

func _tools(parent: Node3D,wood: Material,steel: Material) -> void:
	for x in [-0.45,0.4]:
		kit.box(parent,Vector3(x,0,0),Vector3(0.12,0.08,0.62),wood)
		kit.box(parent,Vector3(x,0,-0.25),Vector3(0.32,0.12,0.15),steel)

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
	carried.get_node("ToolHeads").visible=phase=="tools"
	kit.sample(tick)
	if continuous and phase=="working" and cycle==0:
		hammer_audio.play();strike_count+=1
	elif tick<last_tick or phase!="working": hammer_audio.stop()
	last_tick=tick;_last_phase=phase

func _exit_tree() -> void:
	if is_instance_valid(carried): carried.queue_free()
