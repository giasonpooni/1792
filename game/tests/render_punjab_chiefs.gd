extends SceneTree
## Native production-camera inspection; no story progress or camera pose is seeded.
const Playable = preload("res://history/punjab_chiefs_playable.tscn")
const State = preload("res://history/punjab_chiefs_state.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var folder := "user://punjab-chiefs-images"
	DirAccess.make_dir_recursive_absolute(folder)
	for sequence in State.new().catalogue():
		var visit = Playable.instantiate()
		visit.configure(sequence.id)
		root.add_child(visit)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join(sequence.id+"-opening.png"))
		visit.begin_play()
		for i in range(10): await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join(sequence.id+"-play.png"))
		visit.queue_free()
		await process_frame
	print("PUNJAB_CHIEFS_IMAGES: ",ProjectSettings.globalize_path(folder))
	quit(0)
