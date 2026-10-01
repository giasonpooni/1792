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
		push_error("GATE PASSAGE FAIL: "+label)

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
	check(is_instance_valid(passage),"gate passage attached to existing Home chapter")
	check(passage.get_meta("classification","")=="direct-craft-gate-passage","passage is explicitly presentation-only")
	check(passage.records.size()==5,"five bounded gate-direction records")
	check(passage.find_children("*","CollisionShape3D",true,false).is_empty() and passage.find_children("*","StaticBody3D",true,false).is_empty(),"gate direction adds no collision or static physics")

	var ids: Array[String]=[]
	for raw in passage.records:
		var entry: Dictionary=raw
		ids.append(String(entry.id))
		check(entry.gameplay_authority==false and entry.historical_claim==false and entry.persistent_state==false,"record retains non-authoritative boundary "+String(entry.id))
	check(ids==["gate_guard","waiting_porter","tucked_cart","waiting_pack","cloth_marker"],"stable authored passage record order")

	for node in [passage.guard_root,passage.porter_root,passage.cart_root,passage.pack_root]:
		check(not passage.central_lane_clear((node as Node3D).position),"staged gate object stays outside central lane "+String((node as Node3D).name))

	var before: Dictionary=scene.model.snapshot()
	var actor_before: Transform3D=scene.avatar.global_transform
	var gate: Vector3=Model.GATES[2]

	passage.sample(0,gate+Vector3(0,0,9),false,"riding")
	var far: Dictionary=passage.passage_state()
	passage.sample(30,gate+Vector3(0,0,2.5),false,"riding")
	var near_foot: Dictionary=passage.passage_state()
	passage.sample(60,gate+Vector3(0,0,2.5),true,"riding")
	var near_mounted: Dictionary=passage.passage_state()

	check(absf(near_foot.guard_hand.x)>absf(far.guard_hand.x),"near foot passage produces a small readable guard gesture")
	check(absf(near_mounted.guard_hand.x)>absf(near_foot.guard_hand.x),"mounted approach produces stronger practical clearance gesture")
	check(near_mounted.porter_position.x<near_foot.porter_position.x and near_foot.porter_position.x<=far.porter_position.x,"porter yields only outward as clearance increases")
	check(near_mounted.cart_position==far.cart_position and near_mounted.pack_position==far.pack_position,"cart and pack do not become fake moving agents")
	check(near_mounted.cloth_rotation!=far.cloth_rotation,"material marker can move independently of social choreography")

	passage.sample(90,gate+Vector3(0,0,2.5),true,"caught")
	var caught: Dictionary=passage.passage_state()
	check(caught.guard_hand==Vector3.ZERO and caught.porter_position==passage.porter_base,"caught phase clears social gesture without moving route props")

	check(scene.model.snapshot()==before,"gate choreography mutates no campaign state")
	check(scene.avatar.global_transform==actor_before,"gate choreography never moves or rotates the authoritative player body")

	home.queue_free()
	await frames(3)
	print("GATE_PASSAGE_DIRECTION_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
