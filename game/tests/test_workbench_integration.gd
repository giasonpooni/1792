# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_workshop.gd"
## Reuse inherited test helpers, not another player motor or workshop reducer.
const Bench := preload("res://workshops/accepted_workbench.gd")
const SLOT := "user://bench-integration-only.json"
var live: Node3D
var trace: Array=[]
var stages: Dictionary={}
var metrics: Dictionary={}
var epoch := 0
var last_tick := -1
var dropped := 0

func record_frame() -> void:
	if not is_instance_valid(live) or live._paused: return
	var tick: int=int(live.model.progress().tick)
	if tick==last_tick: return
	if tick<last_tick: epoch+=1
	last_tick=tick
	var contacts: Array=[]
	for i in range(live.avatar.get_slide_collision_count()):
		var body: Object=live.avatar.get_slide_collision(i).get_collider()
		if body==live.workshop_world.bench.get_node("ClearanceBody"): contacts.append("accepted_workbench")
	if trace.size()>=20000: dropped+=1;return
	trace.append({"sample":trace.size(),"epoch":epoch,"tick":tick,"position":Base.coords(live.avatar.global_position),
		"velocity":Base.coords(live.avatar.velocity),"phase":live.model.workshop_phase(),"bench_contacts":contacts,
		"carried_visible":live.workshop_world.carried.visible,"stock_tools":live.model.economy().ledger.stock.tools})

func make_fixture(p: Vector3) -> Node3D:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SLOT
	ok(scene.model.restore(Fixture.complete()),"completed inquiry fixture")
	ok(scene.model.begin_allowance(),"fixture allowance")
	ok(Pose.pose(scene.model,p),"explicit physical fixture placement")
	root.add_child(home);await frames(8)
	scene._paused=true;scene.avatar.set_physics_process(false)
	return home

func bounds_in(node: Node3D,frame: Node3D) -> AABB:
	var first:=true;var result:=AABB()
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		for s in range(mesh.mesh.get_surface_count()):
			for v in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				var p: Vector3=frame.to_local(mesh.to_global(v))
				if first: result=AABB(p,Vector3.ZERO);first=false
				else: result=result.expand(p)
	return result

func clear_capsule(scene,p: Vector3,motion:=Vector3.ZERO) -> bool:
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=scene.avatar.get_node("CollisionShape3D").shape
	q.collision_mask=1;q.exclude=[scene.avatar.get_rid()]
	q.transform.origin=p+Vector3(0,0.82,0)
	var space: PhysicsDirectSpaceState3D=scene.get_world_3d().direct_space_state
	if not space.intersect_shape(q,1).is_empty(): return false
	q.motion=motion
	var result:=space.cast_motion(q)
	return result.size()==2 and result[0]>0.9999

func geometry() -> void:
	var home=await make_fixture(Craft.SITE+Vector3(2.4,0,0));var scene=home.get_node("ChildhoodChapter")
	var bench: Node3D=scene.workshop_world.bench
	check(FileAccess.get_sha256(Bench.ASSET_PATH)==Bench.ASSET_SHA256,"exact accepted GLB retained")
	check(bench.position.is_equal_approx(Vector3(-46,.132,-5.4)) and bench.scale==Vector3.ONE,"placement with no visual scaling")
	var meshes: Array=bench.get_node("Visual").find_children("*","MeshInstance3D",true,false)
	check(meshes.size()==9,"actual glTF scene contains nine meshes")
	var triangles:=0
	for mesh in meshes:
		for s in range(mesh.mesh.get_surface_count()): triangles+=int(mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size()/3)
	check(triangles==108,"actual imported triangle count")
	var shape: BoxShape3D=bench.get_node("ClearanceBody/Shape").shape
	check(shape.size.is_equal_approx(Vector3(1.8,.9,.7)),"separate conservative game collision")
	check(bench.get_node("ClearanceBody").collision_layer==1,"collision admitted to original world mask")
	var extents:=bounds_in(bench.get_node("Visual"),bench)
	check(extents.position.distance_to(Vector3(-.9,0,-.35))<.00001 and extents.size.distance_to(Vector3(1.8,.9,.7))<.00001,"in-engine visual extents agree with accepted asset")
	check(scene.workshop_world.finished.get_parent()==bench,"finished stock projection attached to accepted bench")
	var tools:=bounds_in(scene.workshop_world.finished,bench)
	check(absf(tools.position.y-.905)<.00001,"finished tool undersides clear tabletop by five millimetres")
	check(not bench.is_processing() and not bench.is_physics_processing(),"bench has no independent clock")
	check(absf(scene.avatar.get_node("CollisionShape3D").shape.radius-.35)<.000001 and absf(scene.avatar.get_node("CollisionShape3D").shape.height-1.6)<.000001,"original full-height player capsule unchanged")
	var before: Dictionary=scene.model.snapshot()
	scene.workshop_world.sync(int(scene.model.progress().tick),scene.model.workshop_phase())
	check(scene.model.snapshot()==before,"visual projection creates no inventory or progress")
	var ring: Array[Vector3]=[]
	for offset in [Vector3(1.7,0,-1.2),Vector3(-1.7,0,-1.2),Vector3(-1.7,0,1.2),Vector3(1.7,0,1.2)]:
		ring.append(bench.position+offset)
	for i in range(4):
		check(clear_capsule(scene,ring[i]),"full capsule clear at ring corner "+str(i))
		check(clear_capsule(scene,ring[i],ring[(i+1)%4]-ring[i]),"full capsule swept-clear ring edge "+str(i))
	check(not clear_capsule(scene,bench.position),"standing within bench footprint refused")
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1
	q.exclude=[bench.get_node("ClearanceBody").get_rid()];q.transform=bench.get_node("ClearanceBody/Shape").global_transform
	check(scene.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"new bench does not overlap other static scene bodies")
	metrics.geometry={"asset_sha256":Bench.ASSET_SHA256,"parts":meshes.size(),"triangles":triangles,
		"min":Base.coords(extents.position),"size":Base.coords(extents.size),"position":Base.coords(bench.position),
		"tool_underside_y":tools.position.y,"ring":ring.map(func(p): return Base.coords(p))}
	home.queue_free();await frames(3)

func collisions() -> void:
	metrics.collisions=[]
	for offset in [Vector3(1.7,0,0),Vector3(-1.7,0,0),Vector3(0,0,1.2),Vector3(0,0,-1.2)]:
		var home=await make_fixture(Bench.PLACEMENT+offset);var scene=home.get_node("ChildhoodChapter")
		var bench: Node3D=scene.workshop_world.bench
		look(scene,Bench.PLACEMENT);scene._resume()
		Input.action_press("move_forward");Input.action_press("sprint")
		var seen:=false
		for _i in range(90):
			await physics_frame
			for j in range(scene.avatar.get_slide_collision_count()):
				seen=seen or scene.avatar.get_slide_collision(j).get_collider()==bench.get_node("ClearanceBody")
		Input.action_release("move_forward");Input.action_release("sprint");await frames(8)
		var local: Vector3=bench.to_local(scene.avatar.global_position)
		var outside: bool=local.x*signf(offset.x)>1.24 if offset.x!=0 else local.z*signf(offset.z)>.69
		check(seen and outside,"actual original sprint collides without crossing from "+str(offset))
		check(scene.avatar.is_on_floor() and scene.avatar.global_position.y<.15,"collision does not raise player onto tabletop")
		check(clear_capsule(scene,scene.avatar.global_position),"contact leaves a noninterpenetrating capsule")
		metrics.collisions.append({"start_offset":Base.coords(offset),"end_local":Base.coords(local),"bench_contact":seen,"outside":outside})
		home.queue_free();await frames(3)

func access_and_saves() -> void:
	var state:=fresh()
	ok(state.workshop_action("reserve"),"access fixture reserves at home")
	ok(Pose.pose(state,Craft.SITE+Vector3(2.4,0,0)),"access fixture explicitly placed at smith")
	ok(state.workshop_action("start"),"access fixture start")
	for _i in range(Craft.WORK_TICKS): state.advance()
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SLOT
	ok(scene.model.restore(state.snapshot()),"ready-state fixture")
	root.add_child(home);await frames(8);look(scene,Craft.SITE)
	await tap(scene,KEY_E)
	check(scene._paused and scene._access("collect"),"visible bench and smith admit collection menu")
	var external:=Camera3D.new();home.add_child(external);external.current=true
	external.position=Vector3(-40,4,-3);external.look_at(Craft.SITE)
	# This obstruction blocks only the tabletop reach ray, not the higher smith eye.
	var eye: Vector3=scene.avatar.global_position+Vector3.UP*1.35
	var target: Vector3=scene.workshop_world.bench.get_node("CollectionPoint").global_position
	var wall=scene.town.box(scene,Vector3(.35,.8,.35),(eye+target)*.5,Color.GRAY,true)
	await frames(3)
	check(scene._access("start") and not scene._access("collect"),"bench reach independently blocked while smith remains visible")
	var before: Dictionary=scene.model.snapshot()
	# Real button callback, then its production tick dispatcher; no domain action bypass.
	for b in scene._actions.get_children():
		if b.text.contains("Collect two"): b.pressed.emit();break
	scene._physics_process(1.0/60)
	var after_refusal: Dictionary=scene.model.snapshot()
	metrics.access={"stale_collect_before":before,"stale_collect_after":after_refusal}
	check(after_refusal==before,"obstruction after menu refuses collection atomically")
	check(scene.model.workshop_phase()=="ready" and scene.workshop_world.finished.visible,"refused pickup leaves real custody at smith")
	check(root.get_camera_3d()==external,"third-person or inspection camera cannot authorize through-wall pickup")
	wall.queue_free();await frames(3);scene._open_smith()
	check(scene._access("collect"),"removing obstruction restores access, not automatic pickup")
	scene.avatar.pivot.rotation.y+=PI
	check(not scene._access("collect"),"facing away refuses collection")
	look(scene,Craft.SITE)
	scene.workshop_world.bench.get_node("Visual").hide()
	check(not scene._access("collect"),"hidden asset cannot authorize invisible collection")
	scene.workshop_world.bench.get_node("Visual").show()
	var ground: Dictionary=scene.model.snapshot()
	ok(Pose.pose(scene.model,scene.model.position()+Vector3.UP*2),"wrong-floor domain fixture")
	scene._apply();look(scene,Craft.SITE)
	check(not scene._access("start") and not scene._access("collect"),"wrong-floor interaction refused for smith and bench")
	ok(scene.model.restore(ground),"restore ground fixture");scene._apply();look(scene,Craft.SITE)
	var staged:=State.new();ok(staged.restore(ground),"safe snapshot fixture")
	ok(Pose.pose(staged,Bench.PLACEMENT),"domain permits coordinates; world will test collision")
	ok(staged.save_to(SLOT),"write domain-valid colliding test save")
	before=scene.model.snapshot();var pose_before: Vector3=scene.avatar.global_position
	scene._load()
	check(scene.model.snapshot()==before and scene.avatar.global_position==pose_before,"load inside bench refuses before any state or transform promotion")
	check(scene._message.contains("standing room"),"blocked save gives explicit spatial refusal")
	scene._open_smith();ok(scene.model.save_to(SLOT),"write valid bench-side save")
	scene._load()
	check(scene.model.workshop_phase()=="ready" and scene.workshop_world.finished.visible,"valid save restores output on same bench")

	home.queue_free();await frames(3)

func move_to(scene,p: Vector3) -> void:
	var arrived:=false
	for _i in range(2400):
		if Base.distance(scene.avatar.global_position,p)<.14: arrived=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(10)
	if not arrived: print("BENCH ROUTE STOP ",scene.avatar.global_position," -> ",p," / ",scene._message)
	check(arrived,"input route reached "+str(p))

func integrated_journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SLOT
	ok(scene.model.restore(Fixture.complete()),"journey has only completed-inquiry setup before launch")
	root.add_child(home);await frames(8)
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Accept the limited")
	stages.initial=scene.model.snapshot();live=scene;physics_frame.connect(record_frame)
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Commission two")
	for p in [Vector3(2,0,-10),Vector3(-24,0,-11),Vector3(-35,0,-11),Vector3(-38,0,-7),Vector3(-43.6,0,-7)]: await move_to(scene,p)
	var ring: Array=metrics.geometry.ring
	# Actual complete circuit while carrying the existing timber/payment, no position injection.
	for p in ring: await move_to(scene,Base.point(p))
	await move_to(scene,Base.point(ring[0]))
	check(scene.model.workshop_phase()=="fuel" and scene.workshop_world.carried.visible,"loaded circuit preserves fuel custody")
	look(scene,Craft.SITE);await tap(scene,KEY_E);await button(scene,"Hand over")
	check(scene.model.workshop_phase()=="working","existing situated handover still executes")
	await tap(scene,KEY_F5);var start_tick: int=int(scene.model.workshop().started_tick)
	await frames(30);await tap(scene,KEY_F9)
	check(scene.model.workshop().started_tick==start_tick,"working save does not restart production")
	for _i in range(Craft.WORK_TICKS+5): await physics_frame
	check(scene.model.workshop_phase()=="ready" and scene.workshop_world.finished.visible,"finished bundles rest on new bench")
	stages.ready=scene.model.snapshot()
	look(scene,Craft.SITE);await tap(scene,KEY_E)
	var paused: Dictionary=scene.model.snapshot();await frames(20)
	check(scene.model.snapshot()==paused,"bench-side dialogue freezes original state and clock")
	await button(scene,"Collect two")
	check(scene.model.workshop_phase()=="tools" and not scene.workshop_world.finished.visible,"collection transfers visual custody once")
	stages.carried=scene.model.snapshot()
	await tap(scene,KEY_F5);var saved_position: Vector3=scene.model.position()
	await move_to(scene,Base.point(ring[3]));await tap(scene,KEY_F9)
	check(scene.model.position().distance_to(saved_position)<.02 and scene.model.workshop_phase()=="tools","load restores safe bench-side player and cargo together")
	# Return circuit with produced tools; authoring did not grant extra household stock.
	for p in [ring[1],ring[2],ring[3],ring[0]]: await move_to(scene,Base.point(p))
	for p in [Vector3(-43.6,0,-7),Vector3(-38,0,-7),Vector3(-38,0,-11),Vector3(-24,0,-11),Vector3(2,0,-10),Vector3(3,0,4)]: await move_to(scene,p)
	look(scene,Economy.QUARTERMASTER);await tap(scene,KEY_E);await button(scene,"Return the two")
	check(scene.model.workshop_phase()=="complete" and scene.model.economy().ledger.stock.tools==4,"original household stock credited exactly once after actual return")
	stages.delivered=scene.model.snapshot()
	check(scene.model.economy().ledger.purse==stages.initial.misl.ledger.purse,"bench integration adds no personal money")
	ok(scene.model.validate(scene.model.snapshot()),"played integration state validates with original workshop rules")
	physics_frame.disconnect(record_frame);live=null
	home.queue_free();await frames(3)

func _run() -> void:
	await geometry();await collisions();await access_and_saves();await integrated_journey()
	check(dropped==0 and trace.size()>500,"bounded per-tick trace retained without truncation")
	var output: Dictionary={"schema":"1792.accepted-bench-gameplay.v1","execution_id":Crypto.new().generate_random_bytes(16).hex_encode(),"operation_id":"workshop-bench-integration.v1",
		"engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,
		"journey_setup":"one completed-inquiry snapshot before launch; no subsequent position/progress injection except whole-world F9 restores",
		"physical_fixtures":"explicit initial pose per collision/clearance fixture; original controller executes movement",
		"passed":passed,"failed":failed,"metrics":metrics,"stages":stages,"trace":trace,"dropped":dropped,
		"human_playtest":false,"game_release":false}
	var file:=FileAccess.open("user://bench-integration-gameplay.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"",true,true));file.close()
	print("BENCH_EVIDENCE: ",ProjectSettings.globalize_path("user://bench-integration-gameplay.json"))
	for path in [SLOT,SLOT+".tmp",SLOT+".checkpoint.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("BENCH_INTEGRATION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
