extends Node3D
## Original procedural props and clock-driven work poses, not autonomous population AI.
const Craft := preload("res://workshops/workshop_rules.gd")
var smith_arm: Node3D
var potter_arm: Node3D
var loom_arm: Node3D
var wheel: Node3D
var coal: Node3D
var finished: Node3D
var carried: Node3D
var caption: Label3D
var _town: Node3D

func build(town: Node3D,avatar: Node3D) -> void:
	_town=town;name="TownWorkshops"
	var smith:=_person(Craft.SITE,Color("745747"),Color("d1b48c"))
	smith.name="TownSmith";smith_arm=smith.get_node("Arm")
	_town.box(smith_arm,Vector3(0.12,0.5,0.1),Vector3(0,-0.4,-0.08),Color("6e5139"))
	_town.box(smith_arm,Vector3(0.38,0.16,0.18),Vector3(0,-0.65,-0.08),Color("4f5558"))
	# Anvil and hearth have collision, placed out of the courtyard's open doorway.
	_town.box(self,Vector3(0.65,0.65,0.65),Craft.SITE+Vector3(0,0.325,-0.78),Color("7c6347"),true)
	_town.box(self,Vector3(1.05,0.25,0.42),Craft.SITE+Vector3(0,0.78,-0.78),Color("50585c"),true)
	_town.box(self,Vector3(0.32,0.13,0.32),Craft.SITE+Vector3(0.55,0.83,-0.78),Color("656668"))
	_town.box(self,Vector3(1.6,0.8,1.4),Craft.SITE+Vector3(-3,0.4,-1.8),Color("856653"),true)
	coal=_town.box(self,Vector3(1.15,0.05,0.95),Craft.SITE+Vector3(-3,0.83,-1.8),Color("c07438"))
	_town.box(self,Vector3(2.0,0.14,0.8),Craft.SITE+Vector3(0,0.92,1.6),Color("745d43"),true)
	for x in [-0.85,0.85]:
		for z in [-0.28,0.28]: _town.box(self,Vector3(0.12,0.85,0.12),Craft.SITE+Vector3(x,0.425,1.6+z),Color("745d43"))
	finished=Node3D.new();finished.position=Craft.SITE+Vector3(0,1.08,1.6);add_child(finished)
	for x in [-0.45,0.35]:
		_town.box(finished,Vector3(0.13,0.08,0.7),Vector3(x,0,0),Color("705436"))
		_town.box(finished,Vector3(0.4,0.12,0.14),Vector3(x,0,-0.29),Color("637078"))
	caption=_town.label(self,"Smith · household commission [E]",Craft.SITE+Vector3.UP*2.6)
	caption.font_size=40;caption.pixel_size=0.005
	# Other visible craftspeople are explicitly presentation-only on the same chapter clock.
	var potter:=_person(Vector3(-46.8,0.14,-44.0),Color("b59871"),Color("baa58b"))
	potter.name="PotterWorkPose";potter_arm=potter.get_node("Arm")
	wheel=Node3D.new();wheel.position=Vector3(-46.8,0.52,-44.8);add_child(wheel)
	_town.cylinder(wheel,Vector3.ZERO,0.47,0.12,Color("7c6250"))
	_town.cylinder(wheel,Vector3(0,0.27,0),0.19,0.45,Color("b78259"),0.13)
	_town.box(wheel,Vector3(0.6,0.02,0.04),Vector3(0,0.075,0),Color("ac8b65"))
	var weaver:=_person(Vector3(12.5,0.14,-59),Color("7d8c8a"),Color("c8b995"))
	weaver.name="ClothWorkPose";loom_arm=weaver.get_node("Arm")
	# The load is a projection of ledger custody; it is not a second inventory object.
	carried=Node3D.new();carried.name="WorkshopLoad";avatar.add_child(carried)
	carried.position=Vector3(0.42,0.82,0)
	for x in [-0.16,0.08]: _town.box(carried,Vector3(0.17,0.16,0.9),Vector3(x,0,0),Color("866346"))
	_town.box(carried,Vector3(0.45,0.03,0.14),Vector3(0,0.09,0),Color("c4ac7e"))

	var tool_heads:=Node3D.new();tool_heads.name="ToolHeads";carried.add_child(tool_heads)
	for x in [-0.16,0.08]: _town.box(tool_heads,Vector3(0.28,0.15,0.16),Vector3(x,0,-0.4),Color("637078"))

func _person(p: Vector3,cloth: Color,wrap: Color) -> Node3D:
	var person:=Node3D.new();person.position=p;add_child(person)
	for x in [-0.13,0.13]:
		_town.box(person,Vector3(0.18,0.68,0.2),Vector3(x,0.34,0),cloth)
		_town.box(person,Vector3(0.18,0.12,0.3),Vector3(x,0.06,-0.055),Color("584d43"))
	_town.cylinder(person,Vector3(0,1.0,0),0.3,0.65,cloth,0.22)
	_town.cylinder(person,Vector3(0,1.5,0),0.18,0.32,Color("ad8063"),0.17)
	_town.cylinder(person,Vector3(0,1.68,0.02),0.23,0.18,wrap,0.19)
	var arm:=Node3D.new();arm.name="Arm";arm.position=Vector3(0.25,1.22,0);person.add_child(arm)
	_town.box(arm,Vector3(0.16,0.53,0.18),Vector3(0,-0.265,0),cloth)
	_town.box(arm,Vector3(0.16,0.16,0.18),Vector3(0,-0.6,0),Color("ad8063"))
	_town.box(person,Vector3(0.17,0.6,0.18),Vector3(-0.29,1.0,0),cloth)
	return person

func sync(tick: int,phase: String) -> void:
	var swing: float=sin(TAU*float(tick%72)/72.0)
	smith_arm.rotation.x=0.75+0.5*swing if phase=="working" else 0.12
	potter_arm.rotation.x=0.52+0.1*sin(TAU*float(tick%180)/180.0)
	loom_arm.rotation.x=0.45+0.22*sin(TAU*float(tick%120)/120.0)
	wheel.rotation.y=TAU*float(tick%120)/120.0
	coal.visible=phase=="working"
	finished.visible=phase=="ready"
	carried.visible=phase in ["fuel","tools"]
	carried.get_node("ToolHeads").visible=phase=="tools"
	caption.text="Smith · household commission [E]"
