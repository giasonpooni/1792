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
		push_error("GUJRANWALA ARMS CRAFT FAIL: "+label)

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
	var arms: Node3D=art.arms_craft
	check(is_instance_valid(arms) and arms.get_meta("classification","")=="direct-craft-arms-display","arms-craft niche attached and explicitly presentation-only")
	check(arms.display_roots.size()==1 and arms.longarms.size()==2,"single wall niche with paired long-arm studies")
	check(arms.blades.size()==3,"bounded curved-blade / compact-sidearm study count")
	check(arms.fittings.size()>=10 and arms.repair_cloth.size()>=2,"localized fitting/repair detail inventory present")
	check(arms.find_children("*","CollisionShape3D",true,false).is_empty() and arms.find_children("*","StaticBody3D",true,false).is_empty(),"arms-craft adds no collision/static physics")
	check(arms.find_children("*","NavigationRegion3D",true,false).is_empty(),"arms-craft adds no navigation authority")

	var niche: Node3D=arms.display_roots[0]
	for site in Model.SITES.values():
		check(Model.distance(Vector3(niche.global_position.x,.14,niche.global_position.z),site)>4.0,"arms niche clear of childhood lesson site")
	for gate in Model.GATES:
		check(Model.distance(Vector3(niche.global_position.x,.14,niche.global_position.z),gate)>4.0,"arms niche clear of riding gate")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()
	arms.sample(0)
	var cloth_a: Vector3=arms.repair_cloth[0].rotation
	arms.sample(90)
	check(arms.repair_cloth[0].rotation!=cloth_a,"repair cloth motion samples supplied chapter tick")

	art.set_refinement(false)
	check(not arms.visible,"F7 authored-refinement disable removes arms-craft niche")
	art.set_refinement(true)
	check(arms.visible,"F7 authored-refinement restore returns arms-craft niche")

	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"arms-craft sampling changes no campaign state or journal")

	home.queue_free()
	await frames(3)
	print("GUJRANWALA_ARMS_CRAFT_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
