# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Equipment carried by the existing articulated figure; no actor or physics authority.
const Figure:=preload("res://youth/performance/bazaar_figure.gd")
const Sword:=preload("res://presentation/service_sword.gd")
const Defence:=preload("res://presentation/service_defence.gd")
const Meshes:=preload("res://presentation/equipment_mesh.gd")
const MAX_TICK:=10000000
var figure: Node3D
var sidearm: Node3D
var shield: Node3D
var helmet: Node3D
var signal_arm: Node3D
var shield_socket: Node3D
var hip_socket: Node3D
var head_socket: Node3D
var suspension: Array[Dictionary]=[]
var signal_amount:=0.0

func socket(parent: Node3D,id: String,at: Vector3) -> Node3D:
	var node:=Node3D.new()
	node.name=id
	node.position=at
	parent.add_child(node)
	return node

func build() -> void:
	name="GateGuardStudy"
	set_meta("gameplay_authority",false)
	set_meta("historical_claim",false)
	figure=Figure.new()
	figure.name="ArticulatedFigure"
	add_child(figure)
	figure.build(4,false)
	signal_arm=figure.shoulders[0]
	hip_socket=socket(figure.torso,"SwordSocket",Vector3(.30,.20,.12))
	sidearm=Sword.new()
	sidearm.build()
	sidearm.rotation.x=-.18
	hip_socket.add_child(sidearm)
	var leather:=Meshes.material("49382c",0,.85)
	var belt:=Meshes.cylinder(figure.torso,"SwordBelt",.268,.055,Vector3(0,.19,0),leather)
	belt.scale.z=.73
	var buckle:=BoxMesh.new()
	buckle.size=Vector3(.055,.042,.012)
	Meshes.part(figure.torso,"BeltBuckle",buckle,Meshes.material("777566",.6,.48),Vector3(0,.19,-.200))
	for i in range(2):
		var ring: Node3D=sidearm.scabbard.get_node("SuspensionRing%d"%i)
		var start:=Vector3(.260,.19,.044) if i==0 else Vector3(.230,.19,.100)
		var anchor:=socket(figure.torso,"BeltAnchor%d"%i,start)
		var end: Vector3=(hip_socket.transform*sidearm.transform*sidearm.scabbard.transform*ring.transform).origin
		var y: Vector3=(end-start).normalized()
		var z:=Vector3.RIGHT.cross(y).normalized()
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(.021,start.distance_to(end),.007)
		var strap:=Meshes.part(figure.torso,"SuspensionStrap%d"%i,mesh,leather,(start+end)/2)
		strap.basis=Basis(y.cross(z),y,z)
		suspension.append({"strap":strap,"anchor":anchor,"ring":ring})
	shield_socket=socket(figure.elbows[1],"ShieldSocket",figure.hands[1].position)
	# Shield +X follows the forearm; its front faces away from the body.
	shield_socket.basis=Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT)
	shield=Defence.shield()
	shield.position=-shield.get_node("GripAnchor").position
	shield_socket.add_child(shield)
	head_socket=socket(figure.head,"HelmetSocket",Vector3(0,.15,0))
	helmet=Defence.helmet()
	helmet.rotation.y=PI
	helmet.scale=Vector3.ONE*1.13
	head_socket.add_child(helmet)
	sample_pose(0,0.0)

func sample_pose(tick: int,amount: float) -> bool:
	if tick<0 or tick>MAX_TICK or not is_finite(amount) or amount<0 or amount>1 or not is_instance_valid(figure): return false
	signal_amount=amount
	signal_arm.rotation=Vector3(1.02*amount,0,-.05*amount)
	figure.elbows[0].rotation=Vector3(.10+.60*amount,0,0)
	figure.shoulders[1].rotation=Vector3(.12+.10*amount,0,-.12)
	figure.elbows[1].rotation=Vector3(.92+.18*amount,0,0)
	helmet.get_node("MailAventail").sample_tick(tick,.20)
	return true
