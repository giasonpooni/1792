# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native dialog views: invitation fixture; optional exchanges from retained
## successful input-driven journeys. No alternative cinematic player camera.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Supply := preload("res://territory/misl_rules.gd")
var failed:=0
var count:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func check(value: bool,label: String) -> void:
	if not value: failed+=1;push_error(label)
func look(scene,site: Vector3) -> void:
	var d: Vector3=site-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func capture(name: String,scene) -> void:
	await frames(4);await RenderingServer.frame_post_draw
	check(scene._panel.visible,"dialog visible in "+name)
	check(scene._actions.get_global_rect().end.y<=root.size.y,"continue action remains inside "+name)
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.save_png("user://bazaar-story-"+name+".png")==OK,"native capture "+name)
	count+=1
func _run() -> void:
	var record: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bazaar-story-return.json"))
	if not record is Dictionary or record.get("failed",1)!=0:
		push_error("Successful recorded bazaar story journeys required");quit(1);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	check(scene.model.restore(Fixture.complete()).is_empty(),"explicit invitation fixture")
	check(Pose.pose(scene.model,Supply.MARKET+Vector3(1,0,1)).is_empty(),"explicit market pose")
	root.add_child(home);await frames(8)
	look(scene,Supply.MARKET);scene._interact()
	await capture("invitation",scene)
	for outcome in ["stood_ground","withdrew","walked_away"]:
		root.size=Vector2i(800,450) if outcome in ["stood_ground","walked_away"] else Vector2i(1280,720)
		scene._resume()
		check(scene.model.restore(record.snapshots[outcome]).is_empty(),"recorded return pose "+outcome)
		scene._apply();await frames(6);look(scene,Supply.QUARTERMASTER)
		scene._open_return_exchange()
		check(scene._panel_text.text.begins_with("ON THE WAY HOME"),"actual local exchange opens "+outcome)
		await capture(outcome,scene)
	home.queue_free();await frames()
	print("BAZAAR_STORY_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed else 0)
