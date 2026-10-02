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
		push_error("GUJRANWALA BEAUTY FAIL: "+label)

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
	var beauty: Node3D=art.beauty
	check(is_instance_valid(beauty) and beauty.get_meta("classification","")=="direct-craft-beauty-pass","beauty pass attached and explicitly presentation-only")
	check(beauty.accent_panels.size()==16 and beauty.screens.size()==8,"veranda has bounded accent and jali-depth inventory")
	check(beauty.planters.size()==6 and beauty.practicals.size()==4,"six garden pockets and four practical lights")
	check(beauty.pottery.size()==6 and beauty.textiles.size()==4,"market still-life inventory is bounded")
	for planter in beauty.planters:
		for site in Model.SITES.values():
			check(Model.distance(planter.global_position,site)>3.0,"garden pocket stays clear of childhood lesson site")
		for gate in Model.GATES:
			check(Model.distance(planter.global_position,gate)>3.0,"garden pocket stays clear of riding gate")
	check(beauty.find_children("*","CollisionShape3D",true,false).is_empty() and beauty.find_children("*","StaticBody3D",true,false).is_empty(),"beauty pass adds no collision or static physics")
	check(beauty.find_children("*","NavigationRegion3D",true,false).is_empty(),"beauty pass adds no navigation authority")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()

	beauty.set_preset("daylight")
	check(beauty.practicals.all(func(l):return is_equal_approx(l.light_energy,0.0) and not l.visible),"daylight leaves practicals dark")
	beauty.set_preset("golden_hour")
	check(beauty.practicals.all(func(l):return l.light_energy>0 and l.light_energy<.5 and l.visible),"golden hour uses restrained practical light")
	beauty.set_preset("evening")
	check(beauty.practicals.all(func(l):return l.light_energy>.5 and l.visible),"evening strengthens practical lights")

	beauty.sample(0)
	var cloth_a: Vector3=beauty.textiles[0].rotation
	beauty.sample(90)
	var cloth_b: Vector3=beauty.textiles[0].rotation
	check(cloth_a!=cloth_b,"textile motion samples the supplied chapter tick")

	art.set_refinement(false)
	check(not beauty.visible and beauty.practicals.all(func(l):return not l.visible),"F7 authored-refinement disable removes beauty layer")
	art.set_refinement(true)
	beauty.set_preset("golden_hour")
	check(beauty.visible,"F7 authored-refinement restore returns beauty layer")
	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"beauty sampling changes no campaign state or journal")

	home.queue_free()
	await frames(3)
	print("GUJRANWALA_BEAUTY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
