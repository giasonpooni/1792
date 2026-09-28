extends Node3D
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Original greybox court: public gate, service gap, and walkable overlook.
## Compressed authored geometry, NOT a reconstruction or a streaming city system.
const Rules := preload("res://remounts/remount_rules.gd")
const Agent := preload("res://patrol/patrol_agent.gd")
const Horse := preload("res://mounts/horse.tscn")
const Riding := preload("res://mounts/riding_rules.gd")
var observers: Dictionary={}
var mounts: Array[Node3D]=[]
var note: Node3D

func build() -> void:
	_box(Vector3(21,0.025,11),Vector3(0,0.123,22),Color("b69b70"))
	# Open east gate (z19.5..24), west service gap (z23..25), north overlook.
	for part in [
		[Vector3(0.4,2.6,2.5),Vector3(10,1.4,18.25)],
		[Vector3(0.4,2.6,3),Vector3(10,1.4,25.5)],
		[Vector3(0.4,2.6,6),Vector3(-10,1.4,20)],
		[Vector3(0.4,2.6,2),Vector3(-10,1.4,26)],
		[Vector3(4,2.6,0.4),Vector3(-8,1.4,17)],
		[Vector3(10.5,2.6,0.4),Vector3(4.75,1.4,17)],
		[Vector3(20,2.6,0.4),Vector3(0,1.4,27)]]:
		_box(part[0],part[1],Color("b6926b"),true)
	# Screens interrupt sight but neither remove sound nor grant permission.
	_box(Vector3(6,2.35,0.25),Vector3(-5,1.31,24),Color("80674c"),true)
	_box(Vector3(0.25,2.5,2),Vector3(7,1.39,24.5),Color("987958"),true)
	_box(Vector3(6,0.2,3),Vector3(3.5,3.15,25),Color("715c45"))
	for x in [0.5,6.5]: _box(Vector3(0.15,3,0.15),Vector3(x,1.6,26),Color("5d4935"),true)
	# Low overlook is walkable using the existing controller; no new parkour controller.
	_ramp(Vector3(-3,0.12,14.0),Vector3(-3,1.62,17.0))
	_box(Vector3(3.2,0.2,1.4),Vector3(-3,1.52,17.7),Color("ad9674"),true)
	_ramp(Vector3(-3,1.62,18.4),Vector3(-3,0.12,22.2))
	_box(Vector3(1,0.65,0.5),Rules.NOTE+Vector3(0,0.32,0),Color("756047"),true)
	note=_box(Vector3(0.35,0.025,0.25),Rules.NOTE+Vector3.UP*0.67,Color("dfc49a"))
	for i in range(2):
		var h: CharacterBody3D=Horse.instantiate()
		add_child(h)
		var record: Dictionary=Riding.initial().horse
		record.position=[2.0+i*3,0.14,25]
		record.rider_id=""
		h.apply_record(record)
		h.collision_layer=2
		h.collision_mask=1
		mounts.append(h)
	for id in Rules.OBSERVERS:
		var a:=Agent.new()
		a.entity_id=id
		add_child(a)
		a.apply(Rules.agent(id,Rules.OBSERVERS[id].position))
		var forward: Vector3=Rules.OBSERVERS[id].forward
		a.rotation.y=atan2(-forward.x,-forward.z)
		a.caption.text="Gatekeeper [E]" if id=="yard_gatekeeper" else "Yard keeper"
		observers[id]=a
	_label("SOUTHERN YARD · AUTHORED TEST SPACE",Vector3(11,3.4,21))
	_label("Service passage",Vector3(-11,2.2,24))
	_label("Overlook",Vector3(-3,2.9,17.7))
	_label("Sealed tally [E]",Rules.NOTE+Vector3.UP*1.1)
	_label("Remounts [E]",Rules.HITCH+Vector3.UP*2.8)
	_label("Duty post",Rules.POST+Vector3.UP*2.8)
	_box(Vector3(3,0.15,3),Rules.POST+Vector3.UP*3,Color("786747"))
	sync(false,false)

func sync(active: bool,taken: bool) -> void:
	for a in observers.values():
		a.visible=active
		a.collision_layer=2 if active else 0
	for h in mounts:
		h.visible=active
		h.collision_layer=2 if active else 0
	if is_instance_valid(note): note.visible=active and not taken

func _ramp(a: Vector3,b: Vector3) -> void:
	var delta:=b-a
	var root:=_box(Vector3(3.2,0.2,delta.length()),(a+b)/2-Vector3.UP*0.1,Color("ad9674"),true)
	root.rotation.x=-atan2(delta.y,delta.z)

func _box(size: Vector3,at: Vector3,color: Color,solid: bool=false) -> Node3D:
	var root: Node3D=StaticBody3D.new() if solid else Node3D.new()
	root.position=at
	add_child(root)
	var visual:=MeshInstance3D.new()
	var mesh:=BoxMesh.new();mesh.size=size
	visual.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1
	visual.material_override=material
	root.add_child(visual)
	if solid:
		var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape
		root.add_child(c)
	return root

func _label(text: String,at: Vector3) -> void:
	var label:=Label3D.new();label.text=text;label.position=at
	label.font_size=24;label.pixel_size=0.0025;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
