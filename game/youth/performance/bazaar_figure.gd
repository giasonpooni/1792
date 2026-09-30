# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original articulated supporting-character study; all transforms are visual only.
const Choreo := preload("res://youth/performance/bazaar_choreography.gd")
var torso: Node3D
var head: Node3D
var shoulders: Array[Node3D]=[]
var elbows: Array[Node3D]=[]
var hips: Array[Node3D]=[]
var knees: Array[Node3D]=[]
var eyes: Array[MeshInstance3D]=[]
var eye_origins: Array[Vector3]=[]
var palette: Dictionary={}
var pose_name := "idle"
var actor_index := 0
func joint(parent: Node3D,id: String,p: Vector3) -> Node3D:
	var node:=Node3D.new();node.name=id;node.position=p;parent.add_child(node);return node
func surface(color: Color) -> StandardMaterial3D:
	var key:=color.to_html()
	if palette.has(key): return palette[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.96;palette[key]=m;return m
func round_piece(parent: Node3D,size: Vector3,p: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.5;sphere.height=1;sphere.radial_segments=12;sphere.rings=6
	mesh.mesh=sphere;mesh.scale=size;mesh.position=p;mesh.material_override=surface(color);parent.add_child(mesh);return mesh
func tapered(parent: Node3D,top: float,bottom: float,height: float,p: Vector3,color: Color,depth: float=1.0) -> void:
	var mesh:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=top;c.bottom_radius=bottom;c.height=height;c.radial_segments=12
	mesh.mesh=c;mesh.position=p;mesh.scale.z=depth;mesh.material_override=surface(color);parent.add_child(mesh)
func build(index: int) -> void:
	actor_index=index
	var coat: Color=[Color("806255"),Color("747161"),Color("8c7765"),Color("a56c44"),Color("526c70")][index]
	var cloth: Color=[Color("b9a584"),Color("938968"),Color("cbc0a2"),Color("ddd0ac"),Color("bec6b6")][index]
	var skin:=Color("a77f60") if index%2==0 else Color("b38b69")
	var trousers:=Color("655c4d");var leather:=Color("433c30")
	torso=joint(self,"Torso",Vector3(0,.81,0))
	tapered(torso,.23,.28,.60,Vector3(0,.29,0),coat,.72)
	tapered(torso,.255,.255,.075,Vector3(0,.06,0),cloth,.74)
	tapered(torso,.13,.17,.10,Vector3(0,.605,0),cloth,.72)
	head=joint(torso,"Head",Vector3(0,.68,0))
	round_piece(head,Vector3(.26,.32,.26),Vector3(0,.07,-.006),skin)
	round_piece(head,Vector3(.32,.18,.30),Vector3(0,.255,.005),cloth)
	for y in [.22,.25,.28]:
		var band:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=.13;ring.outer_radius=.159;ring.rings=12;ring.ring_segments=8
		band.mesh=ring;band.scale=Vector3(1,.48,.94);band.position.y=y;band.material_override=surface(cloth.darkened(.12));head.add_child(band)
	round_piece(head,Vector3(.06,.095,.075),Vector3(0,.055,-.139),skin.lightened(.05))
	for x in [-.065,.065]:
		var eye:=round_piece(head,Vector3(.035,.018,.018),Vector3(x,.102,-.130),Color("322c25"));eyes.append(eye);eye_origins.append(eye.position)
		round_piece(head,Vector3(.049,.013,.018),Vector3(x,.135,-.124),Color("3f3427"))
	# Individual clothing accents, not religious/faction-rank uniforms.
	if index==4: round_piece(torso,Vector3(.12,.57,.08),Vector3(-.16,.27,-.175),cloth)
	for side in [-1,1]:
		var h:=joint(self,"Hip%d"%side,Vector3(side*.13,.81,0));hips.append(h)
		tapered(h,.115,.095,.38,Vector3(0,-.19,0),trousers)
		var k:=joint(h,"Knee",Vector3(0,-.38,0));knees.append(k)
		tapered(k,.095,.065,.35,Vector3(0,-.175,0),trousers)
		round_piece(k,Vector3(.18,.105,.29),Vector3(0,-.37,-.045),leather)
		var a:=joint(torso,"Shoulder%d"%side,Vector3(side*.265,.53,0));shoulders.append(a)
		tapered(a,.09,.07,.29,Vector3(0,-.145,0),coat)
		var e:=joint(a,"Elbow",Vector3(0,-.29,0));elbows.append(e)
		tapered(e,.07,.06,.26,Vector3(0,-.13,0),cloth)
		round_piece(e,Vector3(.115,.14,.12),Vector3(0,-.31,-.018),skin)
func sample(tick: int,speed: float,action: String,amount: float=0.0,speaking: bool=false) -> void:
	pose_name=action
	position=Vector3.ZERO
	var wave:=sin(float(tick)/60.0*8.5)*minf(speed/3.2,1)*.48
	torso.position=Vector3(0,.81,0);torso.rotation=Vector3.ZERO;head.rotation=Vector3.ZERO
	for i in range(2):
		hips[i].position.y=.81
		hips[i].rotation=Vector3(wave*(1 if i==0 else -1),0,0);knees[i].rotation=Vector3(maxf(0,-hips[i].rotation.x)*.5,0,0)
		shoulders[i].rotation=Vector3(-hips[i].rotation.x*.6,0,.08 if i==0 else -.08);elbows[i].rotation=Vector3(-.15,0,0)
	var choreo: Dictionary=Choreo.opponent(action,amount)
	if not choreo.is_empty():
		position=choreo.offset;torso.rotation=choreo.torso;head.rotation=choreo.head
		hips[0].rotation.x=choreo.hip_l;hips[1].rotation.x=choreo.hip_r
		knees[0].rotation.x=choreo.knee_l;knees[1].rotation.x=choreo.knee_r
	match action:
		"windup":
			shoulders[1].rotation=Vector3(-.8-1.9*Choreo.smooth(amount),-.35,-.25);elbows[1].rotation.x=-.8
			shoulders[0].rotation.x=-.7;elbows[0].rotation.x=-.6
		"strike":
			shoulders[1].rotation=Vector3(-2.7+1.45*Choreo.smooth(amount),.3,0);elbows[1].rotation.x=-.7+.6*Choreo.smooth(amount)
			shoulders[0].rotation.x=-.8
		"checked":
			shoulders[1].rotation.x=-1.3;elbows[1].rotation.x=-1.05
		"recover":
			shoulders[1].rotation.x=-1.2*(1-Choreo.smooth(amount))
		"brace":
			torso.rotation=Vector3(-.08*amount,.16*amount,0);head.rotation=Vector3(.03,-.20*amount,.06*amount)
			shoulders[0].rotation.x=-.55*amount;shoulders[1].rotation.x=-.7*amount;elbows[1].rotation.x=-.6*amount
		"watch":
			head.rotation.y=.28*amount;torso.rotation.y=.08*amount;shoulders[0].rotation.x=-.35*amount
		"urge":
			torso.rotation=Vector3(.05,-.12*amount,0);head.rotation.y=-.18*amount
			shoulders[0].rotation=Vector3(-.75*amount,0,-.12);elbows[0].rotation.x=-.85*amount
		"down":
			# A seated/crouched defeated figure, not a squashed capsule or ragdoll.
			torso.position.y=.55;torso.rotation.x=.42;head.rotation.x=.18
			for i in range(2): hips[i].position.y=.55;hips[i].rotation.x=-1.2;knees[i].rotation.x=1.4;shoulders[i].rotation.x=-.4;elbows[i].rotation.x=-1
		_:
			if speaking:
				head.rotation.z=.07*sin(float(tick)/13);shoulders[0].rotation.x=-.55;elbows[0].rotation.x=-.7

func apply_attention(yaw: float,pitch: float,eye_offset: Vector2,blink_amount: float) -> void:
	# Additive on the authored pose. The actor root/collider is never touched.
	head.rotation.x+=clampf(pitch,-.22,.22);head.rotation.y+=clampf(yaw,-.46,.46)
	for i in range(eyes.size()):
		eyes[i].position=eye_origins[i]+Vector3(eye_offset.x,eye_offset.y,0)
		eyes[i].scale.y=maxf(.12,1.0-.88*clampf(blink_amount,0,1))
