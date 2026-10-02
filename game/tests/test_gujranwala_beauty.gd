# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
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

	var beauty: Node3D=scene.art.beauty
	check(is_instance_valid(beauty),"beauty layer attached to the existing Home art stack")
	check(beauty.get_meta("classification","")=="original-authoring-study","beauty layer explicitly remains an authoring study")
	check(beauty.get_meta("historically_verified",true)==false and beauty.get_meta("georeferenced",true)==false,"beauty layer carries no reconstruction authority")
	check(beauty.find_children("*","CollisionShape3D",true,false).is_empty() and beauty.find_children("*","StaticBody3D",true,false).is_empty(),"beauty layer adds no collision or static physics")

	var report: Dictionary=beauty.report()
	check(report.painted_spandrels==8 and report.jali_panels==6,"facade color and screen rhythm match bounded contract")
	check(report.planted_tubs==4 and report.textile_drops==5,"planting and textile depth match bounded contract")
	check(report.threshold_lamps==4 and report.well_stone_accents==8 and report.roofline_finials==6,"lamps, well accents and roofline detail match bounded contract")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()
	var actor_before: Transform3D=scene.avatar.global_transform

	beauty.sample(30,"daylight")
	check(beauty.threshold_lamps.all(func(l):return is_zero_approx(l.light_energy)),"daylight leaves threshold lamps dark")
	var cloth_before: float=beauty.textile_drops[0].rotation.z
	beauty.sample(90,"golden_hour")
	check(beauty.threshold_lamps.all(func(l):return l.light_energy>0.0 and l.light_energy<.3),"golden hour uses restrained warm threshold light")
	check(not is_equal_approx(beauty.textile_drops[0].rotation.z,cloth_before),"textile depth responds subtly to the existing clock")
	beauty.sample(150,"evening")
	check(beauty.threshold_lamps.all(func(l):return l.light_energy>.6 and l.light_energy<.8),"evening threshold light remains bounded")

	beauty.set_enabled(false)
	check(not beauty.visible and beauty.threshold_lamps.all(func(l):return is_zero_approx(l.light_energy)),"art switch removes the entire beauty layer and its light")
	beauty.set_enabled(true)
	beauty.sample(180,"daylight")

	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"beauty sampling changes no campaign state or journal")
	check(scene.avatar.global_transform==actor_before,"beauty layer never moves the authoritative player body")

	home.queue_free()
	await frames(3)
	print("GUJRANWALA_BEAUTY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
