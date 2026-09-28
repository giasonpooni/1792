extends "res://tests/test_shah_road.gd"
## Explicit visual fixtures; real movement has a separate engine test.
const Setting := preload("res://territory/settlement/gujranwala_setting.gd")
var captures:=0
var capture_failures:=0
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	captures+=1
	if image.is_empty() or image.save_png("user://gujranwala-setting-"+label+".png")!=OK: capture_failures+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://gujranwala-setting-render-only.json"
	root.add_child(home)
	await frames(5)
	scene.avatar.pivot.rotation=Vector3(-0.14,PI,0)
	await capture("courtyard")
	ok(Pose.pose(scene.model,Vector3(10,0.14,4.5)),"store-front render fixture")
	scene._apply()
	scene.avatar.pivot.rotation=Vector3(-0.10,PI,0)
	await frames(3)
	await capture("store")
	ok(Pose.pose(scene.model,Setting.STORE_INSIDE),"interior render fixture")
	scene._apply()
	scene.avatar.pivot.rotation=Vector3(-0.08,0,0)
	await frames(5)
	await capture("interior")
	ok(Pose.pose(scene.model,Vector3(-15.5,0.14,6.5)),"well render fixture")
	scene._apply()
	scene.avatar.pivot.rotation=Vector3(-0.22,PI,0)
	await frames(3)
	await capture("well")
	scene._open_research()
	root.size=Vector2i(800,600)
	await frames(3)
	await capture("research-small")
	home.queue_free()
	await frames()
	print("GUJRANWALA_SETTING_RENDER: %d captures; %d failures"%[captures,capture_failures+failed])
	quit(1 if failed or capture_failures or captures!=5 else 0)
