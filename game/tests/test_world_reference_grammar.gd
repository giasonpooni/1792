# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
const Street:=preload("res://youth/performance/bazaar_street_section.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Brawl:=preload("res://youth/brawl_rules.gd")
var passed:=0
var failed:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:failed+=1;push_error("REFERENCE GRAMMAR FAIL: "+label)
func frames(n: int=4) -> void:
	for _i in range(n):await physics_frame
	await process_frame
func run() -> void:
	var home: Node3D=Launch.make_world();var scene: Node3D=home.get_node("ChildhoodChapter");root.add_child(home);await frames(8)
	var street: Node3D=scene.bazaar_performance.street_section
	check(is_instance_valid(street),"reference-derived street section attached to existing Home")
	check(street.get_meta("classification","")=="reference-derived-presentation-study","street study is explicitly non-authoritative")
	check(street.thresholds.size()==8 and street.awnings.size()==8 and street.upper_screens.size()==8 and street.drains.size()==2,"bounded authored street-section inventory")
	check(street.find_children("*","CollisionShape3D",true,false).is_empty() and street.find_children("*","StaticBody3D",true,false).is_empty(),"street section adds no collision or route authority")
	var before: Dictionary=scene.model.snapshot();for tick in [0,60,180,360]:street.sample(tick)
	check(scene.model.snapshot()==before,"street shade sampling changes no world state")
	var start:=Supply.MARKET;var finish:=Brawl.RING
	for i in range(11):
		var p:=start.lerp(finish,float(i)/10.0)
		check(street.central_lane_clear(p),"existing center route remains inside declared clear lane sample "+str(i))
	for threshold in street.thresholds:
		check(not street.central_lane_clear(threshold.global_position),"raised edge threshold stays outside central lane")
	for drain in street.drains:
		check(not street.central_lane_clear(drain.global_position),"drain occupies margin, not central circulation")
	home.queue_free();await frames(3)
	print("WORLD_REFERENCE_GRAMMAR_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
