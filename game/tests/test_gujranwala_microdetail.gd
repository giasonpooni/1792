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
		push_error("GUJRANWALA MICRODETAIL FAIL: "+label)

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
	var detail: Node3D=art.microdetail
	check(is_instance_valid(detail) and detail.get_meta("classification","")=="direct-craft-microdetail","microdetail attached and explicitly presentation-only")
	check(detail.upper_borders.size()==8 and detail.timber_reveals.size()==16,"bounded upper-border and timber-reveal inventory")
	check(detail.plinth_accents.size()==8 and detail.repair_fields.size()==10,"bounded plinth and selective-repair inventory")
	check(detail.wall_rings.size()==6 and detail.cords.size()==2,"sparse wall hardware inventory")
	check(detail.storage_roots.size()==2,"exactly two quiet storage corners")
	check(detail.find_children("*","CollisionShape3D",true,false).is_empty() and detail.find_children("*","StaticBody3D",true,false).is_empty(),"microdetail adds no collision or static physics")
	check(detail.find_children("*","NavigationRegion3D",true,false).is_empty(),"microdetail adds no navigation authority")

	for storage in detail.storage_roots:
		for site in Model.SITES.values():
			check(Model.distance(storage.global_position,site)>3.0,"storage corner stays clear of childhood lesson site")
		for gate in Model.GATES:
			check(Model.distance(storage.global_position,gate)>3.0,"storage corner stays clear of riding gate")
	for ring in detail.wall_rings:
		check(ring.global_position.y>1.5,"wall hardware stays above low route clutter")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()

	detail.sample(0)
	var cord_a: Vector3=detail.cords[0].rotation
	detail.sample(90)
	check(detail.cords[0].rotation!=cord_a,"hanging cord motion samples the supplied chapter tick")

	art.set_refinement(false)
	check(not detail.visible,"F7 authored-refinement disable removes microdetail layer")
	art.set_refinement(true)
	check(detail.visible,"F7 authored-refinement restore returns microdetail layer")

	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"microdetail sampling changes no campaign state or journal")

	home.queue_free()
	await frames(3)
	print("GUJRANWALA_MICRODETAIL_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
