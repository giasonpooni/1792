# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Fabric := preload("res://reconstruction/district_fabric.gd")
const Narrator := preload("res://narrative/shah_observer.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const State := preload("res://territory/gujranwala_state.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(condition: bool,label: String) -> void:
	if condition: passed+=1
	else:
		failed+=1
		push_error("FAIL: "+label)
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func _run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Fabric.PATH))
	check(Fabric.validate(data).is_empty(),"manifest admitted")
	var original:=data.duplicate(true)
	Fabric.validate(data)
	check(data==original,"admission never edits evidence")
	var bad:=data.duplicate(true)
	bad.features[0].earliest_year=1835
	check(not Fabric.validate(bad).is_empty(),"future architecture refused")
	bad=data.duplicate(true);bad.features[0].id="sheranwala_baradari"
	check(not Fabric.validate(bad).is_empty(),"disputed pavilion not silently admitted")
	bad=data.duplicate(true);bad.features[0].id="mahan_singh_samadhi"
	check(not Fabric.validate(bad).is_empty(),"later memorial excluded")
	bad=data.duplicate(true);bad.features[0].claim_ids=["unknown"]
	check(not Fabric.validate(bad).is_empty(),"missing feature evidence refused")
	bad=data.duplicate(true);bad.features[0].position=[NAN,0,0]
	check(not Fabric.validate(bad).is_empty(),"nonfinite placement refused")
	bad=data.duplicate(true);bad.georeferenced=true
	check(not Fabric.validate(bad).is_empty(),"invented georeference refused")
	bad=data.duplicate(true);bad.features.append(bad.features[0].duplicate(true))
	check(not Fabric.validate(bad).is_empty(),"duplicate feature identity refused")
	bad=data.duplicate(true);bad.claims[0].source_ids=["unknown"]
	check(not Fabric.validate(bad).is_empty(),"unresolved historical source refused")
	bad=data.duplicate(true);bad.exclusions=[]
	check(not Fabric.validate(bad).is_empty(),"exclusions cannot be stripped")
	bad=data.duplicate(true);bad.extent=[-90,90,-90,90]
	check(not Fabric.validate(bad).is_empty(),"existing simulation frame retained")
	bad=data.duplicate(true);bad.routes=[]
	check(not Fabric.validate(bad).is_empty(),"protected routes required")
	bad=data.duplicate(true);bad.extent=[-28,28,-28,28]
	check(Fabric.validate(bad).is_empty(),"integer and JSON-float bounds agree")
	bad=data.duplicate(true);bad.extent=[-28,28.5,-28,28]
	check(not Fabric.validate(bad).is_empty(),"numeric normalization does not widen bounds")
	var model:=State.new()
	var narrator:=Narrator.new()
	var before:=model.snapshot()
	check(narrator.observe(before).contains("Shah Muhammad"),"authored narrator present")
	check(model.snapshot()==before,"narrator never mutates world")
	check(before.player.known_places==["sukerchakia_home"],"research does not grant map knowledge")
	check(Narrator.key_for({})=="","unrelated snapshots cannot narrate")
	check(model.restore(Fixture.complete()).is_empty(),"explicit completed-inquiry fixture")
	check(model.begin_allowance().is_empty(),"same authority grants allowance")
	before=model.snapshot()
	check(Narrator.key_for(before)=="allowance","narration depends on admitted state")
	narrator.observe(before)
	check(before==model.snapshot(),"allowance narration cannot spend resources")
	narrator.rebind(before)
	check(narrator.observe(before)=="","load does not replay old cue")
	var future:=before.duplicate(true)
	future.childhood.tick+=1000
	future.misl.ledger.caravan="complete" # presentation-only fixture, not an admitted game save
	check(narrator.observe(future).contains("provisions"),"return presentation fixture")
	check(narrator.observe(before)=="","rewind suppresses future cue")
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://reconstruction-isolated-test.json"
	check(scene.model.restore(Fixture.complete()).is_empty(),"scene uses inherited state")
	root.add_child(home)
	await frames()
	check(scene.fabric.built_features.size()==data.features.size(),"all approved features built")
	check(not scene.fabric.has_node("mahan_singh_samadhi"),"excluded monument has no node")
	check(not scene.fabric.has_node("sheranwala_baradari"),"disputed monument has no node")
	check(scene.fabric.get_node("household_veranda").get_meta("claim_ids")==["courtyard_vocabulary"],"mesh retains evidence reference")
	check(not scene.fabric.build().is_empty(),"build is not duplicated")
	check(scene.fabric.digest==FileAccess.get_file_as_string(Fabric.PATH).sha256_text(),"rendered manifest identity")
	for route in data.routes:
		for i in range(route.points.size()-1):
			check(scene._navigation.clear_segment(Fabric.vector(route.points[i]),Fabric.vector(route.points[i+1])),"swept route remains clear: "+route.id+"/"+str(i))
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(24,3,15),Vector3(24,-1,15),1)
	var hit: Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit.position.y-1.1)<0.02,"well has actual collision")
	var captured: Dictionary=scene.model.snapshot()
	scene.fabric.update_from_tick(450)
	var at: Vector3=scene.fabric.get_node("fictional_market_porter").position
	scene.fabric.update_from_tick(450)
	check(scene.fabric.get_node("fictional_market_porter").position==at,"ambient sampling is repeatable")
	check(scene.model.snapshot()==captured,"ambient presentation has no state authority")
	check(not captured.actors.has("fictional_market_porter"),"ambient figure is not a covert game agent")
	var event:=InputEventKey.new()
	event.keycode=KEY_F2;event.pressed=true
	scene._unhandled_input(event)
	check(scene._paused and scene._panel_text.text.contains("not Buddh"),"research view is explicit and paused")
	captured=scene.model.snapshot()
	await frames(15)
	check(scene.model.snapshot()==captured,"research notebook freezes existing clock")
	check(scene._panel_text.text.contains(scene.fabric.digest),"notebook binds exact content")
	scene._resume()
	var audit: Dictionary={"schema":"1792.reconstruction-observation.v1","evidence_kind":"synthetic_validation",
		"operation_id":"gujranwala-layout-and-narration-conformance.v1","model_id":data.id,
		"manifest_sha256":scene.fabric.digest,"source_commit":OS.get_environment("GITHUB_SHA"),
		"engine":Engine.get_version_info().string,"passed":passed,"failed":failed,
		"historical_truth_verified":false,"georeferenced":false}
	var file:=FileAccess.open("user://gujranwala-reconstruction-audit.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(audit,"\t"));file.close()
	else: check(false,"write retained observation")
	home.queue_free()
	await frames()
	print("RECONSTRUCTION_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
