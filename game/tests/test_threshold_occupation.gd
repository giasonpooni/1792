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
		push_error("THRESHOLD OCCUPATION FAIL: "+label)

func frames(n: int=4) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func run() -> void:
	var home: Node3D=Launch.make_world()
	var scene: Node3D=home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(8)

	var director: Node=scene.bazaar_performance
	var occupation: Node3D=director.threshold_occupation
	var street: Node3D=director.street_section

	check(is_instance_valid(occupation) and occupation.get_meta("classification","")=="direct-craft-threshold-occupation","threshold occupation attached and explicitly classified")
	check(occupation.records.size()==4 and occupation.roots.size()==4,"exactly four authored threshold habits")
	var expected: Array[String]=["shade_mender","cooling_water_place","counting_edge","empty_waiting_mat"]
	var ids: Array[String]=[]
	for raw in occupation.records:
		var entry: Dictionary=raw
		ids.append(String(entry.id))
		check(entry.gameplay_authority==false and entry.historical_claim==false and entry.persistent_state==false and entry.randomizable==false,"habit policy retained "+String(entry.id))
		check(String(entry.meaning).length()>24,"habit retains authored meaning "+String(entry.id))
		var root_node: Node3D=occupation.roots[entry.id]
		check(not street.central_lane_clear(root_node.global_position),"habit remains at street edge "+String(entry.id))
	check(ids==expected,"stable threshold-habit order")
	check(occupation.record("empty_waiting_mat").actor_present==false and occupation.record("shade_mender").actor_present==true,"presence and absence are deliberate, not random")
	check(occupation.find_children("*","CollisionShape3D",true,false).is_empty() and occupation.find_children("*","StaticBody3D",true,false).is_empty(),"habits add no collision or static physics")

	var before: Dictionary=scene.model.snapshot()
	var journal_before: Array=scene.model.journal()
	occupation.sample(30,"invited")
	var invited_a: Dictionary=occupation.activity_snapshot()
	occupation.sample(75,"invited")
	var invited_b: Dictionary=occupation.activity_snapshot()
	check(invited_a.mender!=invited_b.mender and invited_a.clerk!=invited_b.clerk,"working-edge gestures visibly change over time")

	occupation.sample(30,"fighting")
	var fight_a: Dictionary=occupation.activity_snapshot()
	occupation.sample(75,"fighting")
	var fight_b: Dictionary=occupation.activity_snapshot()
	check(fight_a.mender==fight_b.mender and fight_a.clerk==fight_b.clerk,"fight phase stops work gestures without creating agent state")
	check(fight_a.cover!=fight_b.cover,"non-agent cloth cover can still move while work pauses")
	check(scene.model.snapshot()==before and scene.model.journal()==journal_before,"threshold habits change no world state or journal")

	home.queue_free()
	await frames(3)
	print("THRESHOLD_OCCUPATION_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
