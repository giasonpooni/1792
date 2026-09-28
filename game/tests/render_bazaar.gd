extends "res://tests/test_bazaar.gd"
## Explicit presentation fixtures. Physical journeys are qualified in test_bazaar.
var captures:=0
var capture_failures:=0
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	captures+=1
	if image.is_empty() or image.save_png("user://bazaar-"+label+".png")!=OK: capture_failures+=1

func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://bazaar-render-only.json"
	var s=heard()
	ok(Pose.pose(s,Bazaar.PACKING-Vector3(0,0,0.6)),"packing visual fixture")
	ok(scene.model.restore(s.snapshot()),"restore presentation state")
	root.add_child(home);await frames(5)
	look(scene,Bazaar.PACKING);scene.avatar.pivot.rotation.x=-0.15
	await tap(scene,KEY_E)
	await capture("packing")
	await press(scene,"Pack lot, protecting")
	# Explicit camera-location fixture, not claiming a played walk here.
	ok(Pose.pose(scene.model,Vector3(-12,0.14,-15)),"carrying presentation fixture")
	scene._apply();scene.avatar.pivot.rotation=Vector3(-0.2,1.7,0)
	await frames(5);await capture("carried")
	ok(Pose.pose(scene.model,Economy.MARKET+Vector3.RIGHT),"buyer presentation fixture")
	scene._apply();look(scene,Economy.MARKET)
	scene._open_terms();root.size=Vector2i(800,600)
	await frames(3);await capture("market-small")
	scene._resume();root.size=Vector2i(1280,720)
	var risk=heard();ok(Pose.pose(risk,Economy.QUARTERMASTER),"risk fixture")
	for role in ["worker","worker","guard","guard","guard"]:ok(risk.operate("hire",role),"risk staffing")
	ok(Pose.pose(risk,Bazaar.PACKING-Vector3(0,0,0.6)),"risk packing fixture")
	ok(scene.model.restore(risk.snapshot()),"restore risk fixture")
	scene._apply();look(scene,Bazaar.PACKING)
	scene._open_packing();await frames(3);await capture("reserve-risk")
	scene._open_research();await frames(3);await capture("research")
	home.queue_free();await frames()
	print("BAZAAR_RENDER: %d captures; %d failures"%[captures,capture_failures+failed])
	quit(1 if capture_failures or failed or captures!=5 else 0)
