extends SceneTree
## Actual scene capture. Setup uses UI commands; later travel is delegated physics.
## A separate tracking camera is only a render fixture, never saved campaign state.
const Scene := preload("res://world/house_sandbox.tscn")
var captures := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://companions-" + label + ".png") != OK:
		failures += 1

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await frames(4)
	scene.avatar.position = Vector3(0, 0.04, 3) # Command-table setup fixture only.
	await frames(2)
	scene._perform("petition", "begin")
	scene._perform("petition", "respect_claim")
	scene._perform("issue", "patrol")
	scene._perform("muster")
	await frames(3)
	scene._perform("play_commander")
	scene.avatar.pivot.rotation.y = -0.65
	await frames(15)
	await capture("mustered")
	scene._open_patrol()
	await capture("orders")
	scene._close_panel()
	scene._perform("return_to_darbar")
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.current = true
	var seen: Array[String] = []
	for _i in range(2600):
		var p: Vector3 = scene.campaign.actor_position("patrol_captain")
		camera.position = p + Vector3(10, 7, 12)
		camera.look_at(p + Vector3(0, 0.8, 1.5))
		var s: Dictionary = scene.campaign.snapshot()
		var label := ""
		if s.order.status == "completed": label = "report"
		elif s.companions.phase == "returning": label = "returning"
		elif s.order.visited.size() == 2: label = "outpost"
		elif s.order.visited.size() == 1: label = "village"
		if label != "" and label not in seen:
			seen.append(label)
			await capture(label)
		if label == "report": break
		await physics_frame
	if captures != 6 or failures != 0:
		failures += 1
		push_error("Companion captures did not complete the physical journey.")
	scene.queue_free()
	await process_frame
	print("COMPANION_RENDER: %d captures; %d failures" % [captures, failures])
	quit(1 if failures else 0)
