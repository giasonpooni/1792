# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("MATERIAL FIDELITY: "+label)
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var result: Array=[]
	for node in home.find_children("*","CollisionShape3D",true,false):
		result.append([node.get_instance_id(),node.global_transform,node.shape.get_rid(),node.disabled])
	return result
func geometry(home: Node3D) -> Array:
	var result: Array=[]
	for node in home.find_children("*","MeshInstance3D",true,false):
		result.append([node.get_instance_id(),node.mesh,node.transform])
	return result
func run() -> void:
	var home:=Launch.make_world()
	root.add_child(home)
	await frames(8)
	var scene=home.get_node("ChildhoodChapter")
	scene.open_art_study()
	var art: Node3D=scene.art
	var layer: Node3D=art.material_fidelity
	check(layer.get_meta("historical_claim",true)==false and layer.get_meta("gameplay_authority",true)==false,"explicit appearance boundary")
	check(layer.records.size()==222,"only 222 declared existing craft meshes receive finishes")
	check(layer.get_child_count()==0,"material projection creates no geometry or physics nodes")
	var state: Dictionary=scene.model.snapshot()
	var journal: Array=scene.model.journal()
	var bodies:=physical(home)
	var meshes:=geometry(home)
	var unaffected: Array=[]
	for opening in art.depth_patina.window_glows: unaffected.append(opening.material_override)
	var water: MeshInstance3D=art.beauty.get_node("MarketBeauty/WaterSurface")
	var water_material:=water.material_override
	check(water_material is StandardMaterial3D,"reflective basin retains its existing material")
	for record in layer.records:
		check(record.node.material_override==record.new and record.new is ShaderMaterial,"declared finish applied")
		check(record.new.get_shader_parameter("pigment")==record.old.albedo_color,"authored pigment preserved")
	for i in range(3):
		art.set_refinement(false)
		check(not layer.enabled and layer.records.all(func(r):return r.node.material_override==r.old),"F7 restores every original material reference")
		art.set_refinement(true)
		check(layer.enabled and layer.records.all(func(r):return r.node.material_override==r.new),"F7 reapplies every declared finish")
		art.set_enabled(false)
		check(not layer.enabled and layer.records.all(func(r):return r.node.material_override==r.old),"greybox restores original materials")
		art.set_enabled(true)
		check(layer.enabled and layer.records.all(func(r):return r.node.material_override==r.new),"authored mode reapplies materials")
		check(physical(home)==bodies and geometry(home)==meshes,"material lifecycle preserves all geometry and collision references")
		check(scene.model.snapshot()==state and scene.model.journal()==journal,"material lifecycle preserves canonical state and journal")
	check(water.material_override==water_material,"water material never intercepted")
	for i in range(unaffected.size()):
		check(art.depth_patina.window_glows[i].material_override==unaffected[i],"daylight opening material never intercepted")
	for preset in ["golden_hour","evening","daylight"]:
		check(art.set_preset(preset).is_empty(),"inherited light preset remains supported")
		check(layer.records.all(func(r):return r.node.material_override==r.new),"lighting never replaces craft finishes")
	check(physical(home)==bodies and scene.model.snapshot()==state,"preset cycle preserves physical/domain state")
	home.queue_free()
	await frames(4)
	print("GUJRANWALA_MATERIAL_FIDELITY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
