# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch := preload("res://childhood/home_launch.gd")
const Home := preload("res://world/home_territory.tscn")
const PriorChapter := preload("res://geography/atlas_chapter.gd")
const Art := preload("res://presentation/home_art.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
var passed := 0
var failed := 0
func _initialize() -> void: run.call_deferred()
func check(condition: bool, label: String) -> void:
	if condition: passed+=1
	else: failed+=1;push_error("HOME_ART: "+label)
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var records: Array=[]
	for n in home.find_children("*","CollisionShape3D",true,false):
		var shape: Shape3D=n.shape
		records.append([n.get_instance_id(),n.global_transform,shape.get_rid(),n.disabled,n.get_parent().collision_layer,n.get_parent().collision_mask])
	return records
func key(chapter: Node3D, code: Key) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;chapter._unhandled_input(e)
func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Art.PATH))
	var original:=data.duplicate(true)
	check(Art.validate(data).is_empty(),"manifest admitted")
	check(data==original,"validation is read-only")
	for kind in ["schema","frame","year","georef","claim","source","seed","fraction","nan","preset","direction","bool","energy","color","limits"]:
		var bad:=data.duplicate(true)
		match kind:
			"schema": bad.schema="other"
			"frame": bad.frame="world-metres"
			"year": bad.year=1839
			"georef": bad.georeferenced=true
			"claim": bad.classification="historically_verified"
			"source": bad.evidence_ref="res://data/anthology.v1.json"
			"seed": bad.seed=true
			"fraction": bad.seed=0.5
			"nan": bad.seed=NAN
			"preset": bad.presets.erase("daylight")
			"direction": bad.presets.daylight.sun_rotation=[0,INF,0]
			"bool": bad.presets.daylight.ambient=true
			"energy": bad.presets.daylight.sun_energy=100
			"color": bad.presets.daylight.sky_top="not a color"
			"limits": bad.limits=[]
		check(not Art.validate(bad).is_empty(),"refuses "+kind)
	# Build the previous controller first, freeze it, and compare actual physics before/after art.
	var home:=Home.instantiate();var chapter:=PriorChapter.new();chapter.name="ChildhoodChapter";home.add_child(chapter)
	chapter.save_path="user://home-art-isolated-never-written.json"
	root.add_child(home);await frames()
	chapter._show_dialog("Test","",[["Return","resume"]])
	var state: Dictionary=chapter.model.snapshot();var bodies:=physical(home)
	var art:=Art.new();chapter.add_child(art)
	check(art.build(chapter).is_empty(),"bind to the actual prior Home")
	check(chapter.model.snapshot()==state,"build preserves world state")
	check(physical(home)==bodies,"build preserves every collider, layer and transform")
	check(not art.build(chapter).is_empty(),"duplicate build refuses")
	check(art.digest==FileAccess.get_sha256(Art.PATH),"manifest digest binding")
	check(art.kit.mesh_count>250 and art.kit.mesh_count<600,"bounded geometry count")
	check(art.kit.foliage_instances>500 and art.kit.foliage_instances<1500,"instanced foliage budget")
	for record in art._changes:
		check(is_instance_valid(record.node),"tracked original remains alive")
	art.sample(1200)
	var sample: Variant=art.kit.cloth_materials[0].get_shader_parameter("sampled_seconds")
	art.sample(1200);check(art.kit.cloth_materials[0].get_shader_parameter("sampled_seconds")==sample,"same tick same cloth sample")
	art.sample(60);check(art.kit.cloth_materials[0].get_shader_parameter("sampled_seconds")==1.0,"rewind resets visual sample")
	var prior: Dictionary=art.report();art.sample(-1);check(art.report()==prior,"negative tick refuses")
	for id in ["evening","golden_hour","daylight"]:
		check(art.set_preset(id).is_empty(),"preset admitted: "+id)
		check(chapter.model.snapshot()==state and physical(home)==bodies,"lighting is not time or simulation: "+id)
	prior=art.report();check(not art.set_preset("winter_1839").is_empty() and art.report()==prior,"unknown preset refuses atomically")
	for _i in range(3):
		art.set_enabled(false)
		for record in art._changes:
			check(record.node.mesh==record.old_mesh and record.node.material_override==record.old_material and record.node.scale==record.old_scale and record.node.layers==record.old_layers,"exact legacy visual restore")
		check(home.get_node("WorldEnvironment").environment==art._original_environment,"original environment resource retained")
		art.set_enabled(true)
		check(chapter.model.snapshot()==state and physical(home)==bodies,"repeated toggle preserves world")
	for route in chapter.fabric.manifest.routes:
		for i in range(route.points.size()-1):
			check(chapter._navigation.clear_segment(chapter.fabric.vector(route.points[i]),chapter.fabric.vector(route.points[i+1])),"protected swept route: "+route.id)
	var mesh: MeshInstance3D=chapter.avatar.get_node("MeshInstance3D")
	mesh.hide();art.sample(120);check(not art._hero_proxy.visible,"mounted/hidden avatar cannot double-render")
	art.set_enabled(false);art.set_enabled(true);check(not art._hero_proxy.visible,"toggle cannot reveal hidden rider")
	mesh.show();art.sample(120);check(art._hero_proxy.visible,"on-foot costume restored")
	# Trainer's original telegraph rotation still propagates through its child costume.
	var costume: Node3D=chapter.trainer.get_node("CostumeStudy")
	var basis_before: Basis=costume.global_basis
	chapter.trainer.rotation.z=-0.4
	check(not costume.global_basis.is_equal_approx(basis_before),"trainer telegraph transforms retained")
	chapter.trainer.rotation.z=0
	chapter.remove_child(art);art.queue_free();await frames()
	check(chapter.model.snapshot()==state and physical(home)==bodies,"component removal restores physical/world invariants")
	check(not chapter.avatar.has_node("ChildhoodCostumeStudy"),"component removal cleans external attachments")
	home.queue_free();await frames()
	# Exercise the new entry through real modal inputs and save/load, not a separate demo.
	home=Launch.make_world();chapter=home.get_node("ChildhoodChapter")
	chapter.save_path="user://home-art-qualified-isolated.json"
	root.add_child(home);await frames()
	check(chapter.art.enabled and not chapter._paused,"normal Home starts with art enabled")
	key(chapter,KEY_F7);check(chapter._art_open and chapter._paused,"F7 opens paused art control")
	state=chapter.model.snapshot();var tick: int=chapter.art.last_tick
	await frames(20)
	check(chapter.model.snapshot()==state and chapter.art.last_tick==tick,"paused world and cloth are frozen")
	key(chapter,KEY_F3);check(not is_instance_valid(chapter.atlas_panel),"art modal blocks competing atlas")
	chapter._menu_action("art:evening");chapter._menu_action("art:toggle")
	check(not chapter.art.enabled and chapter.art.preset=="evening" and chapter.model.snapshot()==state,"real buttons only change presentation")
	key(chapter,KEY_F7);check(not chapter._art_open and not chapter._paused,"F7 resumes")
	key(chapter,KEY_F4);check(not chapter._subjective,"F4 perception binding retained")
	key(chapter,KEY_F3);check(is_instance_valid(chapter.atlas_panel),"F3 atlas retained")
	chapter.close_atlas();key(chapter,KEY_F2);check(chapter._paused,"F2 notebook retained");chapter._resume()
	key(chapter,KEY_T);check(chapter._paused and chapter._panel_text.text.contains("YOUTH"),"T youth catalogue retained");chapter._resume()
	check(chapter.model.restore(Fixture.complete()).is_empty(),"inherited inquiry fixture still admitted")
	chapter._apply();chapter.open_art_study()
	state=chapter.model.snapshot()
	check(chapter.model.save_to(chapter.save_path).is_empty(),"existing save writer succeeds")
	var saved:=FileAccess.get_file_as_string(chapter.save_path)
	chapter._menu_action("art:toggle");chapter._menu_action("art:daylight")
	check(chapter.model.snapshot()==state and FileAccess.get_file_as_string(chapter.save_path)==saved,"visual switches cannot mutate saved world")
	var restore_error: String=chapter.model.restore(JSON.parse_string(saved))
	# JSON parses all numbers as floats; the inherited reader normalizes integral fields.
	check(restore_error.is_empty() and JSON.parse_string(JSON.stringify(chapter.model.snapshot(),"",true,true))==JSON.parse_string(JSON.stringify(state,"",true,true)),"existing save roundtrip unchanged")
	DirAccess.remove_absolute(chapter.save_path)
	var result: Dictionary=chapter.art.report();result.passed=passed;result.failed=failed
	var file:=FileAccess.open("user://home-art-tests.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(result,"\t"));file.close()
	home.queue_free();await frames()
	print("HOME_ART_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
