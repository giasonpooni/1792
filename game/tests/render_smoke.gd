extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://world/command_sandbox.tscn").instantiate()
	root.add_child(scene)
	for _i in range(20):
		await process_frame
	await capture("command-courtyard.png")
	scene.avatar.global_position = Vector3(0, 0.2, 2)
	scene._interact()
	await capture("command-table.png")
	scene._perform("issue", "patrol")
	scene._perform("play_commander")
	await capture("command-captain.png")
	scene.avatar.global_position = Vector3(-12, 0.2, -28)
	scene._interact()
	scene.avatar.global_position = Vector3(20, 0.2, -58)
	scene._interact()
	scene._perform("resolve", "secure")
	scene.campaign.advance(4)
	scene._refresh_hud()
	await capture("command-report.png")
	root.remove_child(scene)
	scene.queue_free()
	await process_frame
	print("RENDER_SMOKE: 4 captures attempted; %d failures" % failures)
	quit(0 if failures == 0 else 1)

func capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.is_empty() or image.save_png("user://" + filename) != OK:
		failures += 1
		push_error("Capture failed: " + filename)
