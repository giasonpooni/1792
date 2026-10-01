# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
var passed:=0
var failed:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:failed+=1;push_error("MEMORY ANCHOR FAIL: "+label)
func frames(n: int=4) -> void:
	for _i in range(n):await physics_frame
	await process_frame
func run() -> void:
	var home: Node3D=Launch.make_world();var scene: Node3D=home.get_node("ChildhoodChapter");root.add_child(home);await frames(8)
	var director: Node=scene.bazaar_performance
	var anchors: Node3D=director.memory_anchors
	var street: Node3D=director.street_section
	check(is_instance_valid(anchors) and anchors.get_meta("classification","")=="direct-craft-memory-anchors","memory-anchor layer attached and explicitly classified")
	check(anchors.records.size()==6 and anchors.anchor_nodes.size()==6,"exactly six authored exceptions")
	var expected: Array[String]=["threshold_hand_polish","screen_repair","drain_replacement","tether_groove","measuring_notches","plaster_patch"]
	var ids: Array[String]=[]
	for raw in anchors.records:
		var entry: Dictionary=raw;ids.append(String(entry.id))
		check(entry.randomizable==false and entry.historical_claim==false and entry.gameplay_authority==false and entry.preserve_near_lod==true,"anchor policy retained "+String(entry.id))
		check(String(entry.meaning).length()>24 and String(entry.reference_logic).length()>24,"anchor meaning/provenance rationale retained "+String(entry.id))
		var node: Node=anchors.anchor_nodes[entry.id]
		check(is_instance_valid(node) and node.get_meta("memory_anchor_id","")==entry.id,"anchor node bound to record "+String(entry.id))
		check(not street.central_lane_clear((node as Node3D).global_position),"authored exception stays outside central movement lane "+String(entry.id))
	check(ids==expected,"stable authored memory-anchor order")
	check(anchors.find_children("*","CollisionShape3D",true,false).is_empty() and anchors.find_children("*","StaticBody3D",true,false).is_empty(),"memory anchors add no collision or static physics authority")
	var before: Dictionary=scene.model.snapshot();director.sample(false)
	check(scene.model.snapshot()==before,"memory-anchor presentation refresh changes no world state")
	check(anchors.record("screen_repair").id=="screen_repair" and anchors.record("unknown").is_empty(),"anchor lookup is bounded and stable")
	home.queue_free();await frames(3)
	print("WORLD_MEMORY_ANCHOR_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
