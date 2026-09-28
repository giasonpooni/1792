extends "res://tests/test_shah_road.gd"
## Visual fixtures only. Actual full route journeys live in test_shah_road.gd.
var captures:=0
var capture_failures:=0
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	captures+=1
	if image.is_empty() or image.save_png("user://shah-road-"+label+".png")!=OK: capture_failures+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://shah-road-render-only.json"
	root.add_child(home)
	await frames(5)
	await capture("opening")
	home.queue_free()
	await frames(2)
	home=Launch.make_world()
	scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://shah-road-render-only.json"
	ok(scene.model.restore(checkpoint_fixture()),"declared checkpoint render fixture")
	root.add_child(home)
	await frames(5)
	look(scene,Road.SPEAKER)
	scene.avatar.pivot.rotation.x=-0.12
	await tap(scene,KEY_E)
	await capture("claim")
	root.size=Vector2i(800,600)
	await frames(3)
	await capture("claim-small")
	root.size=Vector2i(1280,720)
	await press(scene,"Use the longer")
	await frames(70)
	# Render the original authored reaction while the carrier starts its chosen route.
	scene.narration.rebase([])
	scene.narration.observe(["bypass_chosen"])
	await frames(3)
	look(scene,scene.merchant.global_position)
	scene.avatar.pivot.rotation.x=-0.20
	await capture("bypass")
	scene._open_narration()
	await capture("transcript")
	home.queue_free()
	await frames()
	print("SHAH_ROAD_RENDER: %d captures; %d failures"%[captures,capture_failures+failed])
	quit(1 if capture_failures or failed or captures!=5 else 0)
