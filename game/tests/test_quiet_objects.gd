# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## One setup followed by input-driven object visits. Extra hostile-access fixtures are labelled.
const Detail := preload("res://youth/details/quiet_objects.gd")
var captures: Dictionary={}
var opened: Array=[]
func _initialize() -> void: run.call_deferred()
func capture(scene: Node3D,id: String,page: String) -> void:
	captures[id+"-"+page]={"state":scene.model.snapshot(),"at":Base.coords(scene.avatar.global_position),
		"pivot":Base.coords(scene.avatar.pivot.rotation),"detail":id,"page":page,
		"object_rotation":Base.coords(scene.quiet_objects.turnables[id].rotation),"text":scene._panel_text.text}
func test_object(scene: Node3D,id: String,at: Vector3) -> void:
	await walk(scene,at);look(scene,Detail.RECORDS[id].at)
	check(scene.quiet_objects.access(id),"physical near/facing/access "+id)
	await tap(scene,KEY_V)
	check(scene._paused and scene.quiet_objects.active_id==id,"input opens actual object "+id)
	var before: Dictionary=scene.model.snapshot();var pose: Vector3=scene.avatar.global_position
	await frames(25)
	check(scene.model.snapshot()==before,"inspection freezes existing game clock "+id)
	capture(scene,id,"first")
	await press(scene,"Turn it over")
	check(is_equal_approx(scene.quiet_objects.turnables[id].rotation.x,PI),"turn shows actual underside "+id)
	check(scene.model.snapshot()==before and scene.avatar.global_position==pose,"turning visual object changes no saved state "+id)
	capture(scene,id,"turn")
	await press(scene,"Notice the small work")
	check(scene._panel_text.text.contains(Detail.RECORDS[id].notice),"specific close observation "+id)
	check(scene.model.snapshot()==before,"noticing creates no money or inventory "+id)
	await press(scene,"Leave it as found")
	check(scene.quiet_objects.turnables[id].rotation==Vector3.ZERO and scene.quiet_objects.active_id.is_empty(),"put back on exit "+id)
	opened.append(id)
func run() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path="user://quiet-object-journey.json"
	ok(scene.model.restore(Fixture.complete()),"only initial completed-inquiry fixture")
	root.add_child(home);await frames(8)
	await test_object(scene,"cloth",Vector3(-10,0,7.4))
	await test_object(scene,"rein",Vector3(-6,0,7.4))
	# Reopen at an actual reachable point, then introduce an explicitly labelled obstruction fixture.
	look(scene,Detail.REIN);await tap(scene,KEY_V)
	var before: Dictionary=scene.model.snapshot()
	var wall_mesh=scene._box(Vector3(2,2,.15),Vector3(-6,1,8.15),Color.GRAY,true)
	await frames(4)
	check(not scene.quiet_objects.access("rein"),"late obstruction blocks object action")
	scene._menu_action("quiet:turn");scene.quiet_objects.step()
	check(scene.quiet_objects.active_id.is_empty() and scene.quiet_objects.turnables.rein.rotation==Vector3.ZERO,"stale menu cannot turn occluded object")
	check(scene.model.snapshot()==before,"late refusal atomic before resumed tick")
	wall_mesh.get_parent().queue_free();await frames(4)
	var p: Vector3=scene.avatar.global_position
	scene.avatar.global_position.y+=3
	check(not scene.quiet_objects.access("rein"),"wrong floor cannot inspect")
	scene.avatar.global_position=p
	look(scene,Detail.REIN+Vector3(0,0,-6))
	check(not scene.quiet_objects.access("rein"),"facing away cannot inspect")
	# Back to input-driven travel; no position/progress injection on this route.
	for destination in [Vector3(2,0,-10),Vector3(-13,0,-11),Vector3(-23,0,-13)]:await walk(scene,destination)
	look(scene,Supply.MARKET);await tap(scene,KEY_E);await press(scene,"Walk with Mela")
	check(scene.model.brawl_phase()=="invited","existing companion invitation used")
	await walk(scene,Vector3(-21.8,0,-13.1));await frames(90)
	await test_object(scene,"pan",Vector3(-21.8,0,-13.1))
	look(scene,Detail.PAN);await tap(scene,KEY_V)
	check(scene.quiet_objects.friends_here(),"both actual companions present for fable")
	before=scene.model.snapshot()
	await press(scene,"Hear Mela's ending")
	check(scene._panel_text.text.contains(Detail.TALE),"Mela tells the unnamed-king fable")
	capture(scene,"pan","tale")
	await press(scene,"Ask Jiva for another ending")
	check(scene._panel_text.text.contains(Detail.OTHER_END),"Jiva's materially different ending")
	check(scene.model.snapshot()==before,"fable creates no future historical knowledge or reward")
	capture(scene,"pan","other")
	# A stale button is refused if a companion loses contact after the page was opened.
	var friend_pose: Transform3D=scene.youths[4].global_transform
	scene.youths[4].global_position+=Vector3(15,0,0)
	scene._menu_action("quiet:tale");scene.quiet_objects.step()
	check(scene.quiet_objects.active_id.is_empty(),"absent friend cannot deliver queued conversation")
	check(scene.model.snapshot()==before,"lost-contact refusal adds no event")
	scene.youths[4].global_transform=friend_pose
	await frames(4)
	look(scene,Detail.PAN);await tap(scene,KEY_V);await press(scene,"Turn it over")
	# F9 uses the normal whole-world route; no transient inspection state is serialized.
	scene.model.save_to(scene.save_path);scene._load(scene.save_path)
	check(scene.quiet_objects.active_id.is_empty() and scene.quiet_objects.turnables.pan.rotation==Vector3.ZERO,"load closes and resets the inspection copy")
	before=scene.model.snapshot();scene._menu_action("quiet:tale");scene.quiet_objects.step()
	check(scene.model.snapshot()==before and scene.quiet_objects.active_id.is_empty(),"out-of-menu forged action ignored")
	check(opened==["cloth","rein","pan"],"all three details physically visited")
	# Real collision exists under large visible surfaces, not walk-through furniture.
	check(scene.quiet_objects.find_children("*","StaticBody3D",true,false).size()==3,"three declared static stand colliders")
	var report: Dictionary={"schema":"1792.quiet-objects-journey.v1","passed":passed,"failed":failed,"captures":captures,
		"opened":opened,"final":scene.model.snapshot(),"setup":"one completed-inquiry setup; wrong-floor, late-wall and absent-friend fixtures explicitly separate",
		"historically_authenticated":false,"new_inventory_items":0,"user_portrait":"creative reference only, image not embedded or licensed by this test"}
	var file:=FileAccess.open("user://quiet-objects-journey.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	home.queue_free();await frames(4)
	print("QUIET_OBJECT_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
