# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
const Meshes:=preload("res://presentation/equipment_mesh.gd")
const Mail:=preload("res://presentation/mail_aventail.gd")

static func shield(fitted: bool=false) -> Node3D:
	var root:=Node3D.new()
	root.name="RoundShield"
	root.set_meta("historical_claim",false)
	var dark:=Meshes.material("414949",.55,.55)
	var trim:=Meshes.material("b39152",.72,.4) if fitted else Meshes.material("636c6b",.7,.45)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Front faces +Z. Shallow dished shell with a separate back and edge.
	for face in [0.0,-.008]:
		for ring in range(10):
			for j in range(48):
				var a:=TAU*j/48.0
				var b:=TAU*(j+1)/48.0
				var r0:=.245*ring/10.0
				var r1:=.245*(ring+1)/10.0
				var points: Array[Vector3]=[]
				for v in [Vector2(r0,a),Vector2(r1,a),Vector2(r1,b),Vector2(r0,b)]:
					points.append(Vector3(v.x*cos(v.y),v.x*sin(v.y),.052*(1-pow(v.x/.245,2))+face))
				if face==0: Meshes.quad(st,points[3],points[2],points[1],points[0])
				else: Meshes.quad(st,points[0],points[1],points[2],points[3])
	Meshes.part(root,"DishedShell",Meshes.finish(st),dark)
	var rim:=Meshes.torus(root,"Rim",.245,.007,Vector3.ZERO,trim)
	rim.rotation.x=PI/2
	for i in range(4):
		var angle:=i*PI/2
		var boss:=Meshes.sphere(root,"Boss%d"%i,.026,Vector3(.113*cos(angle),.113*sin(angle),.046),trim)
		boss.scale.z=.65
	for x in [-.065,.065]:
		var grip:=Meshes.torus(root,"BackGripLeft" if x<0 else "BackGripRight",.057,.007,Vector3(x,0,-.015),Meshes.material("4b3830"))
		grip.rotation.z=PI/2
	var anchor:=Node3D.new()
	anchor.name="GripAnchor"
	anchor.position=Vector3(.065,0,-.045)
	root.add_child(anchor)
	return root

static func helmet() -> Node3D:
	var root:=Node3D.new()
	root.name="DomedHelmet"
	root.set_meta("historical_claim",false)
	var steel:=Meshes.material("606b6b",.72,.43)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		for j in range(32):
			var points: Array[Vector3]=[]
			for v in [Vector2(i,j),Vector2(i+1,j),Vector2(i+1,j+1),Vector2(i,j+1)]:
				var phi: float=v.x/12.0*PI/2
				var theta: float=v.y/32.0*TAU
				points.append(Vector3(.115*cos(phi)*cos(theta),.15*sin(phi),.13*cos(phi)*sin(theta)))
			# Godot's clockwise front faces must point away from the head.
			Meshes.quad(st,points[3],points[2],points[1],points[0])
	Meshes.part(root,"RigidShell",Meshes.finish(st),steel)
	var rim:=Meshes.torus(root,"Rim",.12,.006,Vector3.ZERO,steel)
	rim.scale.z=1.09
	var spike:=CylinderMesh.new()
	spike.top_radius=0
	spike.bottom_radius=.014
	spike.height=.072
	spike.radial_segments=12
	Meshes.part(root,"Finial",spike,steel,Vector3(0,.179,0))
	var mail:=Mail.new()
	root.add_child(mail)
	mail.build()
	return root
