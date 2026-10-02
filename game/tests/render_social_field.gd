# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Rendered fixture interactions, not a claim of an end-to-end human playthrough.
const World := preload("res://world/political_home.tscn")
const Campaign := preload("res://politics/political_state.gd")
const Profile := preload("res://politics/social_field_profile.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
var count := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func check(condition: bool, label: String) -> void:
	if not condition:
		failed += 1
		push_error("SOCIAL_FIELD_RENDER: "+label)
func frames() -> void:
	await physics_frame
	await process_frame
func freeze(scene) -> void:
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
func capture(scene, name: String, expected: String) -> void:
	check(Pose.pose(scene.campaign,Profile.SITES.fictional_market_keeper+Vector3.BACK*2).is_empty(),"market pose")
	scene._apply()
	freeze(scene)
	scene.avatar.pivot.rotation = Vector3.ZERO
	await frames()
	scene._interact()
	check(scene._paused and scene._panel_text.text.contains(expected),"dialogue reflects received state: "+name)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	count += 1
	check(not image.is_empty() and image.save_png("user://social-field-"+name+".png")==OK,"capture "+name)
	scene._resume()
	freeze(scene)
func _run() -> void:
	root.size = Vector2i(1280,720)
	var world := World.instantiate()
	root.add_child(world)
	await frames()
	var scene = world.get_node("ChildhoodChapter")
	freeze(scene)
	scene.save_path = "user://social-field-render-isolated.json"
	check(scene.campaign.restore(Fixture.complete()).is_empty(),"existing inquiry fixture")
	await capture(scene,"open","continues easily")
	check(Pose.pose(scene.campaign,Campaign.OUTPOSTS.bhangi+Vector3.BACK*2).is_empty(),"outpost pose")
	check(scene.campaign.order_political("raid","bhangi").is_empty(),"existing raid operation")
	for _i in range(720): scene.campaign.advance()
	await capture(scene,"guarded","greeting is brief")
	check(Pose.pose(scene.campaign,Campaign.MOTHER+Vector3.BACK*2).is_empty(),"household pose")
	check(scene.campaign.order_political("reparation","bhangi").is_empty(),"existing reparation operation")
	for _i in range(240): scene.campaign.advance()
	await capture(scene,"reassured","manner softens")
	world.queue_free()
	await frames()
	print("SOCIAL_FIELD_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=3 else 0)
