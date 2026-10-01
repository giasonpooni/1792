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
		push_error("GATE MATERIAL FAIL: "+label)

func frames(n: int=4) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func run() -> void:
	var home: Node3D=Launch.make_world()
	var scene: Node3D=home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(8)

	var passage: Node3D=scene.gate_passage
	check(is_instance_valid(passage.wear_root),"threshold wear is attached to the existing gate passage")
	check(passage.wear_root.get_meta("classification","")=="static-material-continuity","wear remains explicitly presentation-only")
	check(passage.wear_root.get_meta("gameplay_authority",true)==false and passage.wear_root.get_meta("historical_claim",true)==false,"wear claims neither gameplay nor historical authority")
	check(int(passage.wear_root.get_meta("detail_budget_meshes",-1))==4,"material continuity keeps a four-mesh detail budget")
	check(passage.wear_root.find_children("*","MeshInstance3D",true,false).size()==4,"exactly four static wear meshes are authored")
	check(passage.wear_root.find_children("*","CollisionShape3D",true,false).is_empty() and passage.wear_root.find_children("*","StaticBody3D",true,false).is_empty(),"wear adds no collision or static physics")
	check(passage.records.size()==5,"material continuity does not expand the existing gate social-record contract")

	var before: Dictionary=scene.model.snapshot()
	var actor_before: Transform3D=scene.avatar.global_transform
	var gate: Vector3=Model.GATES[2]
	var initial: Dictionary=passage.passage_state()
	passage.sample(60,gate+Vector3(0,0,2.5),true,"riding")
	var mounted: Dictionary=passage.passage_state()
	passage.sample(90,gate+Vector3(0,0,2.5),true,"caught")
	var caught: Dictionary=passage.passage_state()

	for key in ["threshold_wear_position","wheel_scuff_outer_position","wheel_scuff_inner_position","cart_rest_wear_position"]:
		check(initial[key]==mounted[key] and mounted[key]==caught[key],"material mark remains static across social phase: "+key)

	check(scene.model.snapshot()==before,"material continuity mutates no campaign state")
	check(scene.avatar.global_transform==actor_before,"material continuity never moves or rotates the authoritative player body")

	home.queue_free()
	await frames(3)
	print("GATE_MATERIAL_CONTINUITY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
