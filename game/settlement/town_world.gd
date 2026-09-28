extends Node3D
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Original procedural architectural blockout. No imported art or simulated town economy.
const Layout := preload("res://settlement/town_layout.gd")
var gates: Array[StaticBody3D]=[]
var landmarks: Dictionary={}
var compound_nodes: Dictionary={}
var _materials: Dictionary={}
var _open := false
var _gate_labels: Array[Label3D]=[]
var crop_instances := 0

func material(color: Color) -> StandardMaterial3D:
	var key:=color.to_html()
	if not _materials.has(key):
		var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.94
		_materials[key]=m
	return _materials[key]

func box(parent: Node3D,size: Vector3,at: Vector3,color: Color,solid: bool=false) -> Node3D:
	var n: Node3D=StaticBody3D.new() if solid else Node3D.new()
	n.position=at;parent.add_child(n)
	var v:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size
	v.mesh=mesh;v.material_override=material(color);n.add_child(v)
	if solid:
		var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;n.add_child(c)
	return n

func cylinder(parent: Node3D,at: Vector3,radius: float,height: float,color: Color,top: float=-1.0) -> MeshInstance3D:
	var v:=MeshInstance3D.new();var m:=CylinderMesh.new()
	m.bottom_radius=radius;m.top_radius=radius if top<0 else top;m.height=height;m.radial_segments=12
	v.mesh=m;v.position=at;v.material_override=material(color);parent.add_child(v)
	return v

func label(parent: Node3D,text: String,at: Vector3) -> Label3D:
	var l:=Label3D.new();l.text=text;l.position=at;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size=24;l.pixel_size=0.003;l.modulate=Color("f4e9cf")
	l.outline_size=7;l.visibility_range_end=20;parent.add_child(l)
	return l

func build() -> void:
	name="GujranwalaNeighbourhood"
	# Four edges of the earlier mission cell are preserved; only two declared exits change.
	_build_core_boundary()
	# Adjacent collision-supported terrain. No second ground at the old 60 x 60 footprint.
	box(self,Vector3(29,0.2,112),Vector3(-44.5,0,-25),Color("9a9866"),true)
	box(self,Vector3(59.0,0.2,51),Vector3(-0.5,0,-55.5),Color("a19b70"),true)
	for side in [Vector3(-59,1.1,-25),Vector3(29,1.1,-55.5)]:
		box(self,Vector3(0.7,2.2,112 if side.x<0 else 51),side,Color("66714c"),true)
	box(self,Vector3(88,2.2,0.7),Vector3(-15,1.1,-81),Color("66714c"),true)
	box(self,Vector3(29,2.2,0.7),Vector3(-44.5,1.1,29),Color("66714c"),true)
	for road in Layout.ROADS: _road(road[0],road[1],road[2])
	# Square is broad enough to walk round the well, not an automatic waypoint.
	box(self,Vector3(18,0.016,15),Vector3(-23,0.12,-42),Color("b3a07b"))
	for spec in Layout.COMPOUNDS: _compound(spec)
	_well()
	_pottery()
	_cloth()
	_grain()
	_stable()
	_bazaar()
	_fields()
	for p in [Vector3(-24,0,-34),Vector3(-31,0,-47),Vector3(5,0,-34),Vector3(-42,0,25),Vector3(-54,0,-28)]: _tree(p,3.8)
	# Small district signs; not a world-sized floating label or unexplored map reveal.
	for id in Layout.SITES:
		var site: Dictionary=Layout.SITES[id]
		var anchor:=Node3D.new();anchor.name=id;anchor.position=site.point;add_child(anchor)
		label(anchor,site.title+" [E]",Vector3.UP*2.4)
		landmarks[id]=anchor
	label(self,"North road · further country not built",Vector3(0,2,-78))
	set_open(false)

func _build_core_boundary() -> void:
	# Walls divide the household/mission area from the wider authored settlement.
	box(self,Vector3(0.4,3,58),Vector3(29,1.5,0),Color("8d9870"),true)
	box(self,Vector3(58,3,0.4),Vector3(0,1.5,29),Color("8d9870"),true)
	# West gap z[-14,-8], north gap x[-4,4]. Original mission paths do not cross these walls.
	box(self,Vector3(0.4,3,15),Vector3(-29,1.5,-21.5),Color("b69c76"),true)
	box(self,Vector3(0.4,3,37),Vector3(-29,1.5,10.5),Color("b69c76"),true)
	for x in [-16.5,16.5]: box(self,Vector3(25,3,0.4),Vector3(x,1.5,-29),Color("b69c76"),true)
	for p in [Layout.WEST_GATE,Layout.NORTH_GATE]:
		var west: bool=p==Layout.WEST_GATE
		var size:=Vector3(0.35,3.2,6) if west else Vector3(8,3.2,0.35)
		var door: StaticBody3D=box(self,size,Vector3(p.x,1.7,p.z),Color("67533d"),true)
		door.name="WestGate" if west else "NorthGate";gates.append(door)
		box(self,Vector3(0.9,0.5,7.4) if west else Vector3(9.4,0.5,0.9),Vector3(p.x,4.2,p.z),Color("b09b78"),true)
		for side in [-1,1]:
			var post:=Vector3(p.x,2.15,p.z)+Vector3(0,0,side*3.6) if west else Vector3(p.x+side*4.5,2.15,p.z)
			box(self,Vector3(0.7,4.1,0.7),post,Color("c8b08a"),true)
		_gate_labels.append(label(self,"",Vector3(p.x,4.7,p.z)))

func set_open(value: bool) -> void:
	_open=value
	for gate in gates:
		gate.visible=not value;gate.collision_layer=0 if value else 1
	for l in _gate_labels:
		l.text="Town lanes · open" if value else "Town gate · finish the household inquiry"

func _road(a: Vector3,b: Vector3,width: float) -> void:
	var p: Vector3=(a+b)/2+Vector3.UP*0.124
	var n:=box(self,Vector3(width,0.018,a.distance_to(b)),p,Color("b49a70"))
	n.rotation.y=atan2(b.x-a.x,b.z-a.z)
	# Parallel worn wheel marks stay visual-only; no collider seam across a lane.
	for side in [-1,1]: box(n,Vector3(0.09,0.006,a.distance_to(b)),Vector3(side*width*0.23,0.012,0),Color("a18b68"))

func _compound(spec: Dictionary) -> void:
	var n:=Node3D.new();n.name=spec.id;n.position=spec.at;n.rotation.y=spec.yaw
	add_child(n);compound_nodes[spec.id]=n
	var w: float=spec.size.x;var d: float=spec.size.y;var h:=3.2
	var plaster: Color=spec.color;var timber:=Color("67503b");var brick:=Color("986f52")
	box(n,Vector3(w,0.016,d),Vector3(0,0.124,0),Color("b8a17a"))
	# Lateral/rear occupied volumes, open middle, actual accessible front doorway.
	box(n,Vector3(w,h,2.8),Vector3(0,h/2+0.1,-d/2+1.4),plaster,true)
	for x in [-w/2+0.7,w/2-0.7]: box(n,Vector3(1.4,h,d),Vector3(x,h/2+0.1,0),plaster,true)
	var flank: float=(w-3.6)/2
	for side in [-1,1]:
		box(n,Vector3(flank,h,0.45),Vector3(side*(1.8+flank/2),h/2+0.1,d/2),plaster,true)
		box(n,Vector3(flank,0.45,0.5),Vector3(side*(1.8+flank/2),0.325,d/2),brick)
	box(n,Vector3(4.0,0.35,0.75),Vector3(0,3.05,d/2),timber,true)
	for x in [-1.9,1.9]: box(n,Vector3(0.18,2.7,0.65),Vector3(x,1.45,d/2),timber)
	# Flat rear roof + parapets; no claim the surviving haveli had this exact configuration.
	box(n,Vector3(w+0.3,0.22,3.6),Vector3(0,3.42,-d/2+1.3),Color("9e8b6c"),true)
	for x in [-w/2,w/2]: box(n,Vector3(0.24,0.55,3.7),Vector3(x,3.76,-d/2+1.3),plaster)
	box(n,Vector3(w,0.55,0.24),Vector3(0,3.76,-d/2-0.25),plaster)
	# Recess-like timber door panels and latticed windows on the inner rear wall.
	for x in [-w*0.29,0,w*0.29]:
		box(n,Vector3(1.0,1.8,0.08),Vector3(x,1.15,-d/2+2.85),timber)
		box(n,Vector3(1.25,0.16,0.14),Vector3(x,2.13,-d/2+2.86),brick)
		for bar in range(5): box(n,Vector3(0.055,0.6,0.08),Vector3(x-0.4+bar*0.2,2.58,-d/2+2.9),timber)
	# Open verandah: roof, posts and shadow, with walkable clearance below.
	box(n,Vector3(w-2.8,0.15,2.4),Vector3(0,2.85,-d/2+4),Color("a38e6f"))
	for x in [-w/2+2,w/2-2]: cylinder(n,Vector3(x,1.4,-d/2+5),0.12,2.6,timber)
	# Scattered lower brick courses are instanced, not thousands of collision bodies.
	var mesh:=BoxMesh.new();mesh.size=Vector3(0.45,0.13,0.065)
	var transforms: Array[Transform3D]=[]
	for row in range(3):
		for i in range(int(w/0.52)):
			var x: float=-w/2+0.3+i*0.52+fmod(row,2)*0.18
			if absf(x)<2.0 or x>w/2-0.2: continue
			transforms.append(Transform3D(Basis.IDENTITY,Vector3(x,0.25+row*0.18,d/2+0.255)))
	_instances(n,mesh,transforms,brick)

func _instances(parent: Node3D,mesh: Mesh,transforms: Array[Transform3D],color: Color) -> void:
	var m:=MultiMesh.new();m.transform_format=MultiMesh.TRANSFORM_3D;m.mesh=mesh;m.instance_count=transforms.size()
	for i in range(transforms.size()): m.set_instance_transform(i,transforms[i])
	var v:=MultiMeshInstance3D.new();v.multimesh=m;v.material_override=material(color);parent.add_child(v)

func _well() -> void:
	var p: Vector3=Layout.SITES.well.point
	# Ring assembled from collision-bearing segments, not an open fall into unsupported terrain.
	for i in range(12):
		var angle: float=TAU*i/12
		var n:=box(self,Vector3(0.72,0.85,0.42),p+Vector3(sin(angle)*1.25,0.43,cos(angle)*1.25),Color("aa987c"),true)
		n.rotation.y=angle
	cylinder(self,p+Vector3.UP*0.2,1.05,0.08,Color("51686a"))
	cylinder(self,p+Vector3.UP*1.65,0.018,2.2,Color("82765a"))
	for side in [-1,1]: box(self,Vector3(0.18,2.8,0.18),p+Vector3(0,1.4,side*1.7),Color("75634a"),true)
	box(self,Vector3(0.2,0.18,3.7),p+Vector3.UP*2.8,Color("75634a"))
	cylinder(self,p+Vector3(1.9,0.25,0.8),0.3,0.5,Color("a07957"),0.24)

func _pottery() -> void:
	var p: Vector3=Layout.SITES.potter.point
	for i in range(8):
		var at: Vector3=p+Vector3((i%4)*0.75-1.1,0.4,-1.4-floori(i/4.0)*0.8)
		cylinder(self,at,0.28,0.65,Color("b1764d"),0.22)
	cylinder(self,Vector3(-51,0.9,-48),1.1,1.6,Color("95694c"),0.75)
	cylinder(self,Vector3(-51,1.9,-48),0.4,0.55,Color("70533e"),0.3)
	box(self,Vector3(2.4,0.15,1.5),p+Vector3(1,0.8,-1),Color("826344"),true)

func _cloth() -> void:
	var p: Vector3=Layout.SITES.cloth.point
	for side in [-1,1]: box(self,Vector3(0.14,2.3,0.14),p+Vector3(side,1.15,-0.65),Color("63513e"),true)
	for h in [0.4,2.3]: box(self,Vector3(2.1,0.13,0.14),p+Vector3(0,h,-0.65),Color("63513e"))
	box(self,Vector3(1.75,1.55,0.035),p+Vector3(0,1.35,-0.65),Color("756383"))
	for i in range(7): box(self,Vector3(0.09,1.5,0.02),p+Vector3(-0.75+i*0.25,1.35,-0.625),Color("ccbb90"))

func _grain() -> void:
	for i in range(9):
		cylinder(self,Vector3(-17+(i%3)*0.75,0.65,-65-floori(i/3.0)*0.8),0.34,1.05,Color("c9b585"),0.25)
	box(self,Vector3(3.0,1.2,1.8),Vector3(-10,0.7,-65),Color("8b7151"),true)
	box(self,Vector3(3.3,0.15,2.1),Vector3(-10,1.4,-65),Color("a58e64"))

func _stable() -> void:
	for z in [-69,-65]:
		box(self,Vector3(3.5,0.3,0.4),Vector3(-49,1.25,z),Color("775c40"),true)
		for x in [-50.5,-47.5]: box(self,Vector3(0.2,1.4,0.2),Vector3(x,0.8,z),Color("775c40"),true)
	cylinder(self,Vector3(-44,0.45,-63),0.65,0.6,Color("9b845c"),0.65)

func _bazaar() -> void:
	var colors: Array[Color]=[Color("a65e44"),Color("a89666"),Color("596b79"),Color("826b81")]
	for i in range(6):
		var x: float=-31+i*8.4
		var p:=Vector3(x,0,-48)
		# Broad open lane at -42 and -53; counter/canopy row lies between them.
		box(self,Vector3(4.4,0.12,3.2),p+Vector3.UP*2.65,colors[i%4])
		box(self,Vector3(3.6,0.8,0.7),p+Vector3(0,0.55,0),Color("876443"),true)
		for side in [-1,1]: cylinder(self,p+Vector3(side*2,1.4,-1.1),0.07,2.6,Color("694f38"))
		for item in range(4): cylinder(self,p+Vector3(-1.1+item*0.65,1.1,0),0.2,0.35,Color("c4a15d"),0.15)

func _tree(p: Vector3,height: float) -> void:
	cylinder(self,p+Vector3.UP*(height*0.4),0.18,height*0.8,Color("796449"),0.12)
	var shape:=SphereMesh.new();shape.radius=height*0.45;shape.height=height*0.8;shape.radial_segments=10;shape.rings=5
	var v:=MeshInstance3D.new();v.mesh=shape;v.position=p+Vector3.UP*height;v.material_override=material(Color("667c46"));add_child(v)

func _fields() -> void:
	# Local orchard outside the buildings, and field strips at the western edge.
	for z in [-70.0,-77.0]:
		for x in [6.0,12.0,19.0,25.0]: _tree(Vector3(x,0,z),3.3)
	var rng:=RandomNumberGenerator.new();rng.seed=Layout.SEED
	var mesh:=BoxMesh.new();mesh.size=Vector3(0.1,0.35,0.07)
	var transforms: Array[Transform3D]=[]
	for iz in range(60):
		for ix in range(6):
			var p:=Vector3(-57.0+ix*0.38,0.3,-78.0+iz*1.65)
			p.x+=rng.randf_range(-0.04,0.04);p.z+=rng.randf_range(-0.07,0.07)
			transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-0.3,0.3)),p))
	crop_instances=transforms.size();_instances(self,mesh,transforms,Color("858a49"))
