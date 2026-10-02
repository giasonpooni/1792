# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Household-gate passage direction. Presentation only: no rank, AI, collision, route or save authority.
const LANE_HALF_WIDTH := 1.9
var anchor := Vector3.ZERO
var guard_root: Node3D
var guard_hand: Node3D
var porter_root: Node3D
var porter_base := Vector3.ZERO
var cart_root: Node3D
var pack_root: Node3D
var marker_cloth: Node3D
var crossing_left: Node3D
var crossing_right: Node3D
var crossing_left_edge:=Vector3(-2.72,0,-.72)
var crossing_right_edge:=Vector3(2.72,0,.72)
var records: Array[Dictionary]=[]
var _materials: Dictionary={}

func material(color: Color) -> StandardMaterial3D:
	var key: String=color.to_html()
	if _materials.has(key): return _materials[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.98
	_materials[key]=m
	return m

func box(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func cylinder(parent: Node3D,name: String,radius: float,height: float,pos: Vector3,color: Color,segments: int=12) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=segments
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func sphere(parent: Node3D,name: String,size: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var shape:=SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=10
	shape.rings=6
	mesh.name=name
	mesh.mesh=shape
	mesh.position=pos
	mesh.scale=size
	mesh.material_override=material(color)
	parent.add_child(mesh)
	return mesh

func remember(id: String,node: Node3D,meaning: String) -> void:
	node.set_meta("gate_passage_id",id)
	node.set_meta("gameplay_authority",false)
	node.set_meta("historical_claim",false)
	records.append({
		"id":id,
		"meaning":meaning,
		"gameplay_authority":false,
		"historical_claim":false,
		"persistent_state":false
	})

func build(at: Vector3) -> void:
	name="HouseholdGatePassageStudy"
	anchor=at
	position=at
	set_meta("classification","direct-craft-gate-passage")
	set_meta("historical_claim",false)

	# Right-side household guard: gesture only, never a blocking body.
	guard_root=Node3D.new()
	guard_root.name="GateGuardStudy"
	guard_root.position=Vector3(2.25,0,-.25)
	add_child(guard_root)
	cylinder(guard_root,"GuardBody",.19,1.05,Vector3(0,.72,0),Color("59646a"))
	sphere(guard_root,"GuardHead",Vector3(.18,.22,.18),Vector3(0,1.40,0),Color("a77f60"))
	guard_hand=Node3D.new()
	guard_hand.name="SignalArm"
	guard_hand.position=Vector3(-.18,1.08,-.02)
	guard_root.add_child(guard_hand)
	cylinder(guard_hand,"SignalForearm",.045,.48,Vector3(0,-.20,0),Color("59646a"))
	sphere(guard_hand,"SignalHand",Vector3(.075,.09,.075),Vector3(0,-.47,0),Color("a77f60"))
	remember("gate_guard",guard_root,"One guard marks the threshold and uses a small hand signal when a mounted rider approaches.")

	# Left-side porter: shifts outward slightly instead of becoming a pathfinding agent.
	porter_root=Node3D.new()
	porter_root.name="WaitingPorterStudy"
	porter_base=Vector3(-2.38,0,.28)
	porter_root.position=porter_base
	add_child(porter_root)
	cylinder(porter_root,"PorterBody",.20,.98,Vector3(0,.68,0),Color("7a6853"))
	sphere(porter_root,"PorterHead",Vector3(.18,.22,.18),Vector3(0,1.35,0),Color("b28a68"))
	box(porter_root,"ShoulderBundle",Vector3(.54,.36,.32),Vector3(-.28,.93,.08),Color("94784f"))
	remember("waiting_porter",porter_root,"A waiting porter yields a little more space to a horse without becoming authoritative crowd AI.")

	# Tucked handcart: permanently placed outside the declared passage lane.
	cart_root=Node3D.new()
	cart_root.name="TuckedHandcart"
	cart_root.position=Vector3(3.35,0,1.10)
	add_child(cart_root)
	box(cart_root,"CartBed",Vector3(1.35,.20,.72),Vector3(0,.54,0),Color("71553d"))
	for x in [-.54,.54]:
		var wheel:=cylinder(cart_root,"Wheel",.28,.08,Vector3(x,.29,0),Color("493a2c"),14)
		wheel.rotation.z=PI/2
	box(cart_root,"CartHandle",Vector3(.10,.10,1.50),Vector3(0,.55,-.90),Color("5b4633"))
	remember("tucked_cart",cart_root,"A handcart is already pulled to the edge rather than visually owning the gate opening.")

	# Left rear bundle: a reason for waiting that does not invent a transaction.
	pack_root=Node3D.new()
	pack_root.name="WaitingPack"
	pack_root.position=Vector3(-3.10,0,1.12)
	add_child(pack_root)
	box(pack_root,"WrappedPack",Vector3(.72,.54,.56),Vector3(0,.30,0),Color("9b8665"))
	box(pack_root,"Tie",Vector3(.08,.60,.62),Vector3(0,.34,0),Color("5f4b38"))
	remember("waiting_pack",pack_root,"A wrapped load explains the porter’s pause without creating a delivery, inventory or merchant contract.")

	# A modest cloth marker provides motion even when people go still.
	marker_cloth=Node3D.new()
	marker_cloth.name="GateClothMarker"
	marker_cloth.position=Vector3(2.72,2.10,.05)
	add_child(marker_cloth)
	box(marker_cloth,"Cloth",Vector3(.42,.62,.035),Vector3.ZERO,Color("8b6649"))
	remember("cloth_marker",marker_cloth,"A small cloth marker gives the threshold wind response without implying a royal standard.")

	# Sparse crossing figures: presentation only. They are allowed into the lane only while Buddh is distant.
	crossing_left=_crossing_figure("CrossingCarrierLeft",crossing_left_edge,Color("776652"),Color("9c835e"),true)
	remember("crossing_carrier_left",crossing_left,"A generic cloth carrier may cross the quiet opening, but clears back to the left edge as Buddh approaches.")
	crossing_right=_crossing_figure("CrossingCarrierRight",crossing_right_edge,Color("5e6c69"),Color("8f744f"),false)
	remember("crossing_carrier_right",crossing_right,"A generic basket carrier may cross from the opposite edge, but yields outward before close passage.")

func _crossing_figure(id: String,edge: Vector3,coat: Color,load_color: Color,left_load: bool) -> Node3D:
	var root:=Node3D.new()
	root.name=id
	root.position=edge
	add_child(root)
	cylinder(root,"Body",.18,.92,Vector3(0,.64,0),coat)
	sphere(root,"Head",Vector3(.17,.21,.17),Vector3(0,1.28,0),Color("aa8262"))
	if left_load:
		box(root,"FoldedLoad",Vector3(.48,.18,.34),Vector3(-.25,.86,.02),load_color)
	else:
		var basket:=cylinder(root,"Basket",.20,.22,Vector3(.24,.82,.02),load_color,12)
		basket.rotation.z=PI/2
	return root

func _traffic_cross_x(tick: int,start_left: bool) -> float:
	# Eight-second sparse loop with long edge dwell; no separate simulation clock.
	var cycle: float=fmod(float(tick),480.0)/480.0
	var p: float=0.0
	if cycle<.22:
		p=0.0
	elif cycle<.48:
		p=(cycle-.22)/.26
	elif cycle<.70:
		p=1.0
	elif cycle<.96:
		p=1.0-(cycle-.70)/.26
	else:
		p=0.0
	var a: float=-2.72 if start_left else 2.72
	var b: float=2.72 if start_left else -2.72
	return lerpf(a,b,p)

func _planar_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))

func sample(tick: int,player_position: Vector3,mounted: bool,stage: String) -> void:
	if not is_instance_valid(guard_root): return
	var distance: float=_planar_distance(player_position,anchor)
	var nearness: float=clampf((7.0-distance)/4.0,0.0,1.0)
	var active: float=0.0 if stage=="caught" else 1.0
	var mounted_clearance: float=nearness*(1.0 if mounted else .35)*active
	var clear_radius: float=9.0 if mounted else 6.5
	var traffic_clearance: float=clampf((clear_radius-distance)/2.6,0.0,1.0)*active

	# A readable but deliberately small hand signal.
	guard_hand.rotation=Vector3(-1.02*mounted_clearance,0,-.08*mounted_clearance)

	# Yield outward, never into the lane.
	porter_root.position=porter_base+Vector3(-.46*mounted_clearance,0,0)
	porter_root.rotation.y=.10*nearness*active

	# Sparse traffic may cross only while Buddh is distant. As he approaches, each figure returns to its own edge.
	if is_instance_valid(crossing_left) and is_instance_valid(crossing_right):
		var left_cross:=Vector3(_traffic_cross_x(tick,true),0,crossing_left_edge.z)
		var right_cross:=Vector3(_traffic_cross_x(tick,false),0,crossing_right_edge.z)
		crossing_left.position=left_cross.lerp(crossing_left_edge,traffic_clearance)
		crossing_right.position=right_cross.lerp(crossing_right_edge,traffic_clearance)
		if stage=="caught":
			crossing_left.position=crossing_left_edge
			crossing_right.position=crossing_right_edge

	# The cart and pack remain where they were placed; they are not fake agents.
	cart_root.rotation.y=.02*sin(float(tick)/95.0)
	pack_root.rotation.y=.015*sin(float(tick)/120.0+1.1)

	# Wind/material motion is independent of social attention.
	marker_cloth.rotation.z=.045*sin(float(tick)/37.0)

func passage_state() -> Dictionary:
	return {
		"guard_hand":guard_hand.rotation if is_instance_valid(guard_hand) else Vector3.ZERO,
		"porter_position":porter_root.position if is_instance_valid(porter_root) else Vector3.ZERO,
		"cart_position":cart_root.position if is_instance_valid(cart_root) else Vector3.ZERO,
		"pack_position":pack_root.position if is_instance_valid(pack_root) else Vector3.ZERO,
		"cloth_rotation":marker_cloth.rotation if is_instance_valid(marker_cloth) else Vector3.ZERO,
		"crossing_left":crossing_left.position if is_instance_valid(crossing_left) else Vector3.ZERO,
		"crossing_right":crossing_right.position if is_instance_valid(crossing_right) else Vector3.ZERO
	}

func central_lane_clear(local_position: Vector3) -> bool:
	return absf(local_position.x)<=LANE_HALF_WIDTH and absf(local_position.z)<=2.8
