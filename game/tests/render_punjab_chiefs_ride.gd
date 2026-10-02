extends "res://tests/test_punjab_chiefs_journeys.gd"
## Native movement reaches the two camera frames; this is not a posed mock-up.
func capture_frame(label: String) -> void:
	controls()
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var folder := "user://punjab-chiefs-images"
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"native frame retained")

func _run() -> void:
	root.size=Vector2i(1280,720)
	current_id="desi"
	scene=Playable.instantiate()
	scene.configure(current_id)
	root.add_child(scene)
	await frames(3)
	scene.begin_play()
	check(await walk_to(scene.target_position()),"native approach to Desi")
	check(scene.interact().is_empty(),"mount conversation admitted")
	await capture_frame("desi-conversation")
	scene._commit_choice(scene.model.current_beat().choices[0].id)
	scene._close()
	await frames(3)
	await capture_frame("desi-mounted")
	check(await ride_to(scene.target_position()),"native ride to first crossing")
	check(scene.interact().is_empty(),"crossing conversation admitted")
	await capture_frame("desi-crossing")
	controls()
	scene.queue_free()
	await process_frame
	print("PUNJAB_CHIEFS_RIDE_RENDER: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
