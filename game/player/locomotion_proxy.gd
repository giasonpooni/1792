# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Procedural skeleton with bounded two-bone hand contact. Presentation only.
const IK := preload("res://player/two_bone_ik.gd")
var grips: Array=[]
var skeleton: Skeleton3D
var actor: CharacterBody3D
var phase := 0.0
var bones: Dictionary={}

func _ready() -> void:
	actor=get_parent()
	skeleton=Skeleton3D.new();skeleton.name="ProxySkeleton";add_child(skeleton)
	bone("pelvis","",Vector3(0,0.8,0))
	bone("spine","pelvis",Vector3(0,0.15,0))
	bone("head","spine",Vector3(0,0.45,0))
	for side in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		bone("upper_leg"+suffix,"pelvis",Vector3(side*0.13,0,0))
		bone("lower_leg"+suffix,"upper_leg"+suffix,Vector3(0,-0.36,0))
		bone("upper_arm"+suffix,"spine",Vector3(side*0.25,0.30,0))
		bone("forearm"+suffix,"upper_arm"+suffix,Vector3(0,-0.28,0))
		piece("upper_leg"+suffix,Vector3(0.15,0.34,0.17),Vector3(0,-0.18,0),Color("465861"))
		piece("lower_leg"+suffix,Vector3(0.13,0.32,0.15),Vector3(0,-0.17,0),Color("465861"))
		piece("lower_leg"+suffix,Vector3(0.17,0.10,0.27),Vector3(0,-0.35,-0.055),Color("29343c"))
		piece("upper_arm"+suffix,Vector3(0.13,0.26,0.14),Vector3(0,-0.14,0),Color("c2b287"))
		piece("forearm"+suffix,Vector3(0.115,0.26,0.12),Vector3(0,-0.14,0),Color("b79d7a"))
		piece("forearm"+suffix,Vector3(0.12,0.08,0.12),Vector3(0,-0.28,0),Color("cdb38f"))
	piece("pelvis",Vector3(0.4,0.23,0.24),Vector3(0,0.05,0),Color("465861"))
	piece("spine",Vector3(0.42,0.42,0.26),Vector3(0,0.20,0),Color("c2b287"))
	piece("head",Vector3(0.27,0.29,0.27),Vector3(0,0.1,0),Color("b79d7a"))
	# Direction marker on the face, not an attempt at a historical likeness.
	piece("head",Vector3(0.12,0.06,0.025),Vector3(0,0.14,-0.143),Color("27343d"))

	skeleton.reset_bone_poses()

func bone(id: String,parent: String,offset: Vector3) -> void:
	var index:=skeleton.get_bone_count();skeleton.add_bone(id);bones[id]=index
	if not parent.is_empty(): skeleton.set_bone_parent(index,bones[parent])
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,offset))

func piece(id: String,size: Vector3,offset: Vector3,color: Color) -> void:
	var attachment:=BoneAttachment3D.new();attachment.bone_name=id;skeleton.add_child(attachment)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.position=offset
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.95;mesh.material_override=mat;attachment.add_child(mesh)

func _process(delta: float) -> void:
	update_pose(delta)

func update_pose(delta: float) -> void:
	grips.clear()
	var contact: Dictionary=actor.contact_frame()
	var speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
	var climbing: bool=actor.motion_mode_name in ["vault","mantle"]
	if speed>0.15 and not climbing: rotation.y=atan2(-actor.velocity.x,-actor.velocity.z)
	elif climbing and not contact.is_empty(): rotation.y=atan2(-contact.forward.x,-contact.forward.z)
	phase=fmod(phase+speed*delta*3.5,TAU)
	var stride:=minf(speed/7.5,1.0)*0.65
	if actor.motion_mode_name=="air" or climbing: stride=0
	for side in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		for id in ["upper_arm"+suffix,"forearm"+suffix]:
			skeleton.reset_bone_pose(bones[id])
		var swing: float=sin(phase+(PI if side<0 else 0))*stride
		skeleton.set_bone_pose_rotation(bones["upper_leg"+suffix],Quaternion(Vector3.RIGHT,swing if not climbing else -0.5))
		skeleton.set_bone_pose_rotation(bones["lower_leg"+suffix],Quaternion(Vector3.RIGHT,maxf(0,-swing)*0.6))
		skeleton.set_bone_pose_rotation(bones["upper_arm"+suffix],Quaternion(Vector3.RIGHT,1.6 if climbing else -swing*0.65))
		skeleton.set_bone_pose_rotation(bones["forearm"+suffix],Quaternion(Vector3.RIGHT,-0.35))

	if not climbing or contact.is_empty(): return
	for hand in contact.hands:
		var suffix: String="L" if hand.side<0 else "R"
		var upper: int=bones["upper_arm"+suffix];var lower: int=bones["forearm"+suffix]
		var shoulder: Vector3=skeleton.get_bone_global_pose(upper).origin
		var target: Vector3=skeleton.to_local(hand.target)
		var pole:=shoulder+Vector3(hand.side*0.35,0.4,0.2)
		var solution:=IK.solve(shoulder,target,pole,0.28,0.28)
		if not solution.reachable: continue
		# Do not put an arm through an intervening wall to meet an otherwise reachable lip.
		var shoulder_world:=skeleton.to_global(shoulder)
		var elbow_world:=skeleton.to_global(solution.elbow)
		var probe=actor.Traversal
		if not probe.ray(actor,shoulder_world,elbow_world).is_empty() or not probe.ray(actor,elbow_world,hand.target).is_empty(): continue
		skeleton.set_bone_global_pose(upper,Transform3D(Basis(Quaternion(Vector3.DOWN,(solution.elbow-shoulder).normalized())),shoulder))
		skeleton.set_bone_global_pose(lower,Transform3D(Basis(Quaternion(Vector3.DOWN,(target-solution.elbow).normalized())),solution.elbow))
		var actual:=skeleton.to_global(skeleton.get_bone_global_pose(lower)*Vector3(0,-0.28,0))
		grips.append({"side":hand.side,"target":hand.target,"actual":actual,"error":actual.distance_to(hand.target),"surface_id":contact.surface_id})
