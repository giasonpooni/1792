extends SceneTree
## Explicit delivery/escort presentation fixtures, not an input-driven campaign.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Rules := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
var count := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func frames(n: int = 5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed += 1; push_error(error)
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	count += 1
	if picture.is_empty() or picture.save_png("user://delivery-story-" + label + ".png") != OK: failed += 1
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home)
	await frames()
	ok(scene.model.begin_allowance())
	scene._sync_economy(true)
	scene._open_quartermaster()
	await capture("briefing")
	scene._resume()
	ok(scene.model.operate("accept_delivery"))
	scene._sync_economy(true)
	scene.avatar.pivot.rotation = Vector3(-0.2, 0, 0)
	await frames()
	await capture("four-portions")
	ok(Pose.pose(scene.model, Rules.MARKET + Vector3(1, 0, 1)))
	scene._apply()
	scene._open_market()
	root.size = Vector2i(800, 600)
	await frames()
	await capture("market-small")
	root.size = Vector2i(1280, 720)
	scene._resume()
	ok(scene.model.operate("deliver"))
	ok(scene.model.operate("accept_escort"))
	# Clearly staged near-store fixture; no teleport completion is performed.
	var staged: Dictionary = scene.model.snapshot()
	staged.misl.merchant.position = Base.coords(Rules.QUARTERMASTER + Vector3(-2, 0, -1))
	staged.misl.merchant.velocity = [0.0, 0.0, 0.0]
	ok(scene.model.restore(staged))
	ok(Pose.pose(scene.model, Rules.QUARTERMASTER + Vector3(0,0,-1)))
	scene._apply()
	await frames()
	scene._open_quartermaster()
	await capture("carrier-arrival")
	scene._resume()
	ok(scene.model.operate("checkin"))
	scene._sync_economy(true)
	scene.avatar.pivot.rotation = Vector3(-0.2, 0, 0)
	await frames()
	await capture("carrier-unloaded")
	home.queue_free()
	await frames()
	print("DELIVERY_STORY_RENDER: %d captures; %d failures" % [count, failed])
	quit(1 if failed or count != 5 else 0)
