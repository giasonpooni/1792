# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original reusable meshes/materials. No collision, actors, saves or historical admission.
const SURFACE := preload("res://presentation/handmade_surface.gdshader")
const CANOPY := preload("res://presentation/canopy.gdshader")
var materials: Dictionary = {}
var cloth_materials: Array[ShaderMaterial] = []
var mesh_count := 0
var foliage_instances := 0

func surface(color: String, finish: int = 0) -> ShaderMaterial:
	var key := color+":"+str(finish)
	if not materials.has(key):
		var m := ShaderMaterial.new(); m.shader=SURFACE
		m.set_shader_parameter("pigment",Color(color))
		m.set_shader_parameter("finish",finish)
		materials[key]=m
	return materials[key]

func plain(color: String, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "plain:"+color+":"+str(metallic)
	if not materials.has(key):
		var m:=StandardMaterial3D.new();m.albedo_color=Color(color)
		m.roughness=0.65 if metallic>0 else 0.94;m.metallic=metallic
		materials[key]=m
	return materials[key]

func mesh_at(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var v:=MeshInstance3D.new();v.mesh=mesh;v.position=at;v.material_override=material
	parent.add_child(v);mesh_count+=1
	return v

func box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var b:=BoxMesh.new();b.size=size
	return mesh_at(parent,b,at,material)

func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var b:=SphereMesh.new();b.radius=0.5;b.height=1.0;b.radial_segments=16;b.rings=8
	var v:=mesh_at(parent,b,at,material);v.scale=size
	return v

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var c:=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=a.distance_to(b);c.radial_segments=8
	var v:=mesh_at(parent,c,(a+b)/2.0,material)
	v.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	return v

func pot(parent: Node3D, at: Vector3, size: float, color: String="946748") -> Node3D:
	# A turned profile with an actual dark inner opening, not a closed cylinder.
	var root:=Node3D.new();root.position=at;parent.add_child(root)
	var profile: Array[Vector2]=[Vector2(0.15,0),Vector2(0.32,0.12),Vector2(0.37,0.38),Vector2(0.30,0.61),Vector2(0.19,0.70),Vector2(0.21,0.77),Vector2(0.17,0.77),Vector2(0.15,0.69),Vector2(0.24,0.55),Vector2(0.27,0.30),Vector2(0.12,0.12)]
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size()-1):
		for k in range(24):
			var points: Array[Vector3]=[]
			for pair in [[j,k],[j+1,k],[j+1,k+1],[j,k+1]]:
				var p: Vector2=profile[pair[0]]*size;var angle: float=TAU*pair[1]/24.0
				points.append(Vector3(p.x*cos(angle),p.y,p.x*sin(angle)))
			for i in [0,2,1,0,3,2]: s.add_vertex(points[i])
	s.generate_normals();mesh_at(root,s.commit(),Vector3.ZERO,plain(color))
	return root

func canopy(parent: Node3D, at: Vector3, span: Vector2, color: String="b6a07a", stripe: String="77765c") -> MeshInstance3D:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(8):
		for i in range(16):
			for p in [Vector2(i,j),Vector2(i+1,j+1),Vector2(i+1,j),Vector2(i,j),Vector2(i,j+1),Vector2(i+1,j+1)]:
				var uv: Vector2=p/Vector2(16,8);s.set_uv(uv)
				s.add_vertex(Vector3((uv.x-0.5)*span.x,-0.16*sin(PI*uv.x), (uv.y-0.5)*span.y))
	s.generate_normals()
	var m:=ShaderMaterial.new();m.shader=CANOPY;m.set_shader_parameter("cloth_color",Color(color));m.set_shader_parameter("stripe_color",Color(stripe))
	cloth_materials.append(m)
	return mesh_at(parent,s.commit(),at,m)

func shutter(parent: Node3D, at: Vector3, width: float = 1.05) -> void:
	var dark:=plain("39352c");var wood:=surface("76614a",2)
	box(parent,at,Vector3(width+0.18,1.22,0.06),dark)
	for i in range(6): box(parent,at+Vector3((i-2.5)*width/6,0,-0.045),Vector3(width/6-0.018,1.08,0.08),wood)
	for y in [-0.34,0.34]: box(parent,at+Vector3(0,y,-0.095),Vector3(width,0.065,0.03),dark)

func arch(parent: Node3D, center: Vector3, radius: float, rise: float, thickness: float) -> void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(28):
		var a: float=PI*i/28.0;var b: float=PI*(i+1)/28.0
		var verts: Array[Vector3]=[]
		for z in [-0.19,0.19]:
			for data in [[a,0.0],[b,0.0],[a,thickness],[b,thickness]]:
				verts.append(center+Vector3(cos(data[0])*(radius+data[1]),sin(data[0])*(rise+data[1]),z))
		for index in [0,1,2,1,3,2,4,6,5,5,6,7,0,4,1,1,4,5,2,3,6,3,7,6]: s.add_vertex(verts[index])
	s.generate_normals();mesh_at(parent,s.commit(),Vector3.ZERO,surface("b69c77"))

func crown(parent: Node3D, at: Vector3, size: Vector3, seed_value: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=true
	var sphere:=SphereMesh.new();sphere.radius=0.5;sphere.height=1;sphere.radial_segments=12;sphere.rings=6
	multimesh.mesh=sphere;multimesh.instance_count=18
	for i in range(18):
		var offset:=Vector3(rng.randf_range(-0.32,0.32),rng.randf_range(-0.26,0.26),rng.randf_range(-0.32,0.32))*size
		var scale_value:=size*Vector3(rng.randf_range(0.35,0.55),rng.randf_range(0.40,0.64),rng.randf_range(0.35,0.55))
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(scale_value),at+offset))
		multimesh.set_instance_color(i,Color("62764a").lerp(Color("899259"),rng.randf()))
	var v:=MultiMeshInstance3D.new();v.multimesh=multimesh
	var m:=StandardMaterial3D.new();m.vertex_color_use_as_albedo=true;m.vertex_color_is_srgb=true;m.roughness=1
	v.material_override=m;parent.add_child(v);foliage_instances+=18

func person(parent: Node3D, at: Vector3, cloth: String, height: float = 1.7) -> Node3D:
	# Proportioned costume proxy. No historical likeness, face performance or independent AI.
	var root:=Node3D.new();root.position=at;root.scale=Vector3.ONE*height/1.7;parent.add_child(root)
	var linen:=surface(cloth,4);var skin:=plain("987355");var shoe:=plain("43362b")
	for x in [-0.12,0.12]:
		rod(root,Vector3(x,0.1,0),Vector3(x,0.72,0),0.085,linen)
		ellipsoid(root,Vector3(x,0.09,-0.07),Vector3(0.19,0.14,0.33),shoe)
	var tunic:=CylinderMesh.new();tunic.top_radius=0.20;tunic.bottom_radius=0.26;tunic.height=0.72;tunic.radial_segments=16
	mesh_at(root,tunic,Vector3(0,0.96,0),linen)
	for x in [-1,1]:
		rod(root,Vector3(x*0.20,1.27,0),Vector3(x*0.29,0.98,-0.01),0.085,linen)
		rod(root,Vector3(x*0.29,0.98,-0.01),Vector3(x*0.27,0.78,-0.05),0.058,skin)
	ellipsoid(root,Vector3(0,1.50,0),Vector3(0.25,0.31,0.25),skin)
	ellipsoid(root,Vector3(0,1.65,0.015),Vector3(0.30,0.15,0.29),surface("c8b58d",4))
	box(root,Vector3(0,1.05,-0.20),Vector3(0.40,0.08,0.05),surface("75654d",4))
	return root

func sample(tick: int) -> void:
	var seconds:=float(posmod(tick,216000))/60.0
	for material in cloth_materials: material.set_shader_parameter("sampled_seconds",seconds)
