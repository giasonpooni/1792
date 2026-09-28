extends SceneTree
## Explicit post-inquiry presentation fixtures, not full input-driven journeys.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Rules := preload("res://territory/misl_rules.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://gujranwala-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://gujranwala-render-only.json"
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home)
	await frames()
	scene.avatar.pivot.rotation=Vector3(-0.25,0,0)
	await capture("home")
	scene._open_quartermaster()
	await capture("allowance")
	scene._resume()
	ok(scene.model.begin_allowance())
	ok(scene.model.operate("hire","guard"))
	ok(scene.model.operate("accept_delivery"))
	ok(Pose.pose(scene.model,Rules.MARKET+Vector3(1,0,0)))
	scene._apply()
	scene.avatar.pivot.rotation=Vector3(-0.2,0.5,0)
	await frames()
	ok(scene.model.operate("deliver"))
	ok(scene.model.operate("accept_escort"))
	scene._sync_economy(true)
	scene._open_market()
	await capture("market")
	root.size=Vector2i(800,600)
	await frames()
	await capture("small-window")
	root.size=Vector2i(1280,720)
	scene._resume()
	await frames(80)
	await capture("caravan")
	scene._open_accounts()
	await capture("accounts")
	home.queue_free()
	await frames()
	print("GUJRANWALA_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=6 else 0)
