# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
const Model:=preload("res://childhood/childhood_state.gd")
var passed:=0
var failed:=0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool,label: String) -> void:
	if value:
		passed+=1
	else:
		failed+=1
		push_error("GUJRANWALA DEPTH FAIL: "+label)

func frames(n: int=4) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func run() -> void:
	var home: Node3D=Launch.make_world()
	var scene: Node3D=home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(8)

	var art: Node3D=scene.art
	var depth: Node3D=art.depth_patina
	check(is_instance_valid(depth) and depth.get_meta("classification","")=="direct-craft-depth-patina","depth/patina pass attached and classified")
	check(depth.parapets.size()==20,"bounded parapet rhythm inventory")
	check(depth.skyline_clusters.size()==4 and depth.window_glows.size()==4,"four skyline/pavilion studies with four distant openings")
	check(depth.patina_patches.size()==8,"eight selective patina patches")
	check(depth.hanging_cloth.size()==4 and depth.distant_foliage.size()==8,"bounded cloth and foliage depth inventory")
	check(depth.find_children("*","CollisionShape3D",true,false).is_empty() and depth.find_children("*","StaticBody3D",true,false).is_empty(),"depth pass adds no collision or static physics")
	check(depth.find_children("*","NavigationRegion3D",true,false).is_empty(),"depth pass adds no navigation authority")

	for cluster in depth.skyline_clusters:
		var p: Vector3=cluster.global_position
		check(p.y>=3.3 and (absf(p.x)>=20.0 or p.z>=24.0),"skyline cluster remains above/peripheral to playable court")
		for site in Model.SITES.values():
			check(Model.distance(Vector3(p.x,.14,p.z),site)>4.0,"skyline cluster remains clear of childhood lesson site")
	for cloth in depth.hanging_cloth:
		check(cloth.global_position.y>2.3,"household cloth remains above ordinary body height")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()

	depth.set_preset("daylight")
	check(depth.window_glows.all(func(w):return not (w.material_override as StandardMaterial3D).emission_enabled),"daylight keeps distant openings dark")
	depth.set_preset("golden_hour")
	check(depth.window_glows.all(func(w):return (w.material_override as StandardMaterial3D).emission_enabled),"golden hour warms distant openings")

	depth.sample(0)
	var cloth_a: Vector3=depth.hanging_cloth[0].rotation
	var foliage_a: Vector3=depth.distant_foliage[0].rotation
	depth.sample(90)
	check(depth.hanging_cloth[0].rotation!=cloth_a,"high cloth moves from supplied chapter tick")
	check(depth.distant_foliage[0].rotation!=foliage_a,"distant foliage moves from supplied chapter tick")

	art.set_refinement(false)
	check(not depth.visible,"F7 refinement disable removes depth layer")
	art.set_refinement(true)
	check(depth.visible,"F7 refinement restore returns depth layer")

	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"depth/patina sampling changes no campaign state or journal")

	home.queue_free()
	await frames(3)
	print("GUJRANWALA_DEPTH_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
