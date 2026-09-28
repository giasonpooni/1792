extends SceneTree
## Three rendered presentation fixtures; not a played accession or new historical scene.
var captures := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://names-" + label + ".png") != OK:
		failures += 1

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var home = load("res://world/home_territory.tscn").instantiate()
	root.add_child(home)
	for _i in range(5): await physics_frame
	await capture("home-buddh")
	home.queue_free()
	await process_frame
	var scene = load("res://world/house_sandbox.tscn").instantiate()
	root.add_child(scene)
	for _i in range(5): await physics_frame
	await capture("lahore-buddh")
	# Explicit presentation fixture at the table; not an input-driven journey.
	scene.avatar.position = Vector3(0, 0.04, 3)
	scene.campaign.record_position(scene.avatar.position)
	scene._open_estate()
	await capture("envoy-ranjit")
	scene.queue_free()
	await process_frame
	print("CHARACTER_NAMES_RENDER: %d captures; %d failures" % [captures, failures])
	quit(1 if failures or captures != 3 else 0)
