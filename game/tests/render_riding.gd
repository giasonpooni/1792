extends SceneTree

const Scene := preload("res://world/house_sandbox.tscn")
const Rules := preload("res://mounts/riding_rules.gd")
var captures := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func ok(error: String) -> void:
	if not error.is_empty():
		failures += 1
		push_error(error)

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://riding-" + label + ".png") != OK:
		failures += 1

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	scene.avatar.position = Vector3(5, 0.04, -2)
	scene.campaign.record_position(scene.avatar.position)
	scene.avatar.pivot.rotation.y = -0.3
	scene._refresh_hud()
	await capture("stable")
	scene.campaign.record_position(Vector3(6.2, 0.04, -5))
	ok(scene.campaign.mount_horse())
	scene._apply_actor(true)
	scene.avatar.pivot.rotation.y = 0.7
	scene._refresh_hud()
	await capture("mounted")
	ok(scene.campaign.dismount_horse(Vector3(6.2, 0.04, -5)))
	scene.campaign.record_position(Vector3(0, 0.2, 3))
	ok(scene.campaign.petition("begin"))
	ok(scene.campaign.petition("assert_authority"))
	ok(scene.campaign.issue("patrol"))
	ok(scene.campaign.play_commander())
	# An explicit render fixture, not a claim that screenshot capture playtested travel.
	var state: Dictionary = scene.campaign.snapshot()
	state.riding.horse.position = [20.0, 0.04, -57.0]
	state.actors.patrol_captain.position = [18.2, 0.04, -57.0]
	state.player.position = state.actors.patrol_captain.position.duplicate()
	ok(scene.campaign.restore(state))
	ok(scene.campaign.mount_horse())
	scene._apply_actor(true)
	scene._refresh_hud()
	await capture("captain-outpost")
	ok(scene.campaign.dismount_horse(Vector3(18.2, 0.04, -57)))
	scene.campaign.record_position(Vector3(-12, 0.2, -28))
	ok(scene.campaign.visit("village"))
	scene.campaign.record_position(Vector3(20, 0.2, -58))
	ok(scene.campaign.visit("outpost"))
	scene._apply_actor(true)
	scene.avatar.set_physics_process(false)
	scene._refresh_hud()
	await capture("parked")
	ok(scene.campaign.resolve("secure"))
	scene.campaign.advance(4)
	scene._apply_actor(true)
	scene.avatar.set_physics_process(false)
	scene._refresh_hud()
	await capture("report")
	scene.queue_free()
	await process_frame
	print("RIDING_RENDER: %d captures; %d failures" % [captures, failures])
	quit(1 if failures else 0)
