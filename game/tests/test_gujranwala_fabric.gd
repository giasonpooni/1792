extends SceneTree
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
const Launch:=preload("res://childhood/home_launch.gd")
const Fabric:=preload("res://architecture/gujranwala_fabric.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(test: bool,label: String) -> void:
	if test: passed+=1
	else: failed+=1;push_error(label)
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func collisions(n: Node,found: Array) -> void:
	if n is CollisionShape3D:
		found.append([n.get_instance_id(),n.global_transform,n.shape.get_rid(),n.disabled])
	for c in n.get_children(): collisions(c,found)
func _run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Fabric.CATALOG))
	check(Fabric.valid_catalog(catalog),"curated catalogue accepted")
	for value in [null,[],{},true,"1792"]: check(not Fabric.valid_catalog(value),"malformed catalogue refused")
	var changed:=catalog.duplicate(true);changed.year=1801
	check(not Fabric.valid_catalog(changed),"no silent chronological shift")
	changed=catalog.duplicate(true);changed.sources[0].url="file:///private/data"
	check(not Fabric.valid_catalog(changed),"not an arbitrary local source reader")
	changed=catalog.duplicate(true);changed.sources.append(changed.sources[0].duplicate(true))
	check(not Fabric.valid_catalog(changed),"duplicate sources refused")
	changed=catalog.duplicate(true);changed.elements[0].exact_1792=true
	check(not Fabric.valid_catalog(changed),"unsupported precise reconstruction claim refused")
	changed=catalog.duplicate(true);changed.elements[0].exact_1792=0
	check(not Fabric.valid_catalog(changed),"boolean claim must be boolean")
	changed=catalog.duplicate(true);changed.elements[0].claim_ids=["missing"]
	check(not Fabric.valid_catalog(changed),"dangling claim refused")
	changed=catalog.duplicate(true);changed.claims[0].source_ids=["missing"]
	check(not Fabric.valid_catalog(changed),"dangling source refused")
	var home:=Launch.make_world();root.add_child(home);await frames()
	var scene=home.get_node("ChildhoodChapter")
	scene._paused=true;scene.avatar.set_physics_process(false)
	var before: Dictionary=scene.model.snapshot()
	var body_before: Array=[];collisions(home,body_before)
	var manifest: Dictionary=scene.fabric.manifest()
	check(manifest.blind_bays==10,"ten bound blind panels")
	check(manifest.background_houses==16,"sixteen background houses")
	check(manifest.material_replacements==10,"only ten existing masonry walls changed")
	check(manifest.new_collision_shapes==0,"no new collision graph")
	check(manifest.exact_1792==false and not manifest.georeferenced,"historical limits retained")
	check(manifest.verification_status=="not_verified","no verification authority")
	var copy: Dictionary=scene.fabric.manifest();copy.exact_1792=true
	check(not scene.fabric.manifest().exact_1792,"detached manifest")
	var count: int=scene.fabric.get_child_count()
	check(not scene.fabric.build(scene).is_empty(),"second build refused")
	check(scene.fabric.get_child_count()==count,"no duplicate nodes after refused build")
	var event:=InputEventKey.new();event.keycode=KEY_F2;event.pressed=true
	scene._unhandled_input(event);await frames(10)
	check(scene._paused and scene._panel.visible,"F2 uses existing modal pause")
	check(scene.model.snapshot()==before,"inspection creates no memory, tick, relation or money")
	check("OUTSIDE CHARACTER KNOWLEDGE" in scene._panel_text.text,"reader context is explicit")
	check("https://alqamarjournal.com/alqamar/article/view/1481" in scene._panel_text.text,"sources accessible as text")
	var body_after: Array=[];collisions(home,body_after)
	check(body_before==body_after,"inspection did not alter any collision")
	scene.fabric.remove_material_overrides();scene.fabric.queue_free();await frames()
	var body_removed: Array=[];collisions(home,body_removed)
	check(body_before==body_removed,"removing visual layer leaves identical physics nodes")
	check(scene.model.snapshot()==before,"removing visual layer leaves identical live state")
	home.queue_free();await frames()
	var again:=Launch.make_world();root.add_child(again);await frames()
	check(again.get_node("ChildhoodChapter").fabric.manifest()==manifest,"repeat build reproduces manifest")
	var f:=FileAccess.open("user://gujranwala-fabric-manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest,"  ",true,true));f.close()
	again.queue_free();await frames()
	print("GUJRANWALA_FABRIC_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
