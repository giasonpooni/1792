extends RefCounted
## Compose a controller onto the original scene without changing its retained bytes.
const Home := preload("res://world/home_territory.tscn")
const Chapter := preload("res://narrative/oral_memory/memory_chapter.gd")

static func make_world() -> Node3D:
	var home: Node3D = Home.instantiate()
	var chapter := Chapter.new()
	chapter.name = "ChildhoodChapter"
	home.add_child(chapter)
	return home

static func enter(tree: SceneTree) -> void:
	var previous := tree.current_scene
	var world := make_world()
	if previous != null:
		tree.root.remove_child(previous)
		previous.queue_free()
	tree.root.add_child(world)
	tree.current_scene = world

static func enter_saved(tree: SceneTree, path: String, expected_digest: String, save_path: String,
		provider: RefCounted, still_allowed: Callable) -> String:
	# The title has no active gameplay world. Prepare a frozen candidate and qualify
	# its real collision space before replacing the current scene. No time catch-up.
	if tree.current_scene==null or tree.current_scene.scene_file_path!="res://ui/main_menu.tscn":
		return "Title Continue requires the title scene; use the active chapter's load operation."
	var recovery:=preload("res://platform/save_recovery.gd")
	var reader:=Chapter.MemoryState.new()
	reader.platform_services=provider
	var selected:=recovery.read_selected(reader,path,expected_digest)
	if not selected.error.is_empty(): return selected.error
	if not still_allowed.call(): return "Continue cancelled. Select the saved chapter again."
	var previous:=tree.current_scene
	var world:=make_world()
	var chapter=world.get_node("ChildhoodChapter")
	chapter.save_path=save_path
	chapter.model.platform_services=provider
	chapter._paused=true
	var error: String=chapter.model.restore(selected.snapshot)
	if not error.is_empty():
		world.free()
		return error
	tree.root.add_child(world)
	# Do not use PROCESS_MODE_DISABLED: CollisionObject3D would leave physics space.
	# Freeze callbacks individually while retaining registered collision geometry.
	var frozen: Array=[]
	var nodes: Array[Node]=[world]
	while not nodes.is_empty():
		var node: Node=nodes.pop_back()
		nodes.append_array(node.get_children())
		frozen.append([node,node.is_processing(),node.is_physics_processing(),node.is_processing_input(),node.is_processing_unhandled_input()])
		node.set_process(false);node.set_physics_process(false)
		node.set_process_input(false);node.set_process_unhandled_input(false)
	# Hide the candidate's presentation while physics registers its collision shapes.
	world.hide()
	for node in chapter.get_children():
		if node is CanvasLayer: node.hide()
	for _i in range(2): await tree.physics_frame
	if not still_allowed.call() or tree.current_scene!=previous:
		error="Continue cancelled by interruption. Select the saved chapter again."
	else:
		error=chapter._candidate_error(chapter.model)
		if error.is_empty(): error=recovery.read_selected(reader,path,expected_digest).error
	if not error.is_empty():
		world.queue_free()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		return error
	chapter.narrator.rebind(chapter.model.snapshot())
	chapter._clear_pending_actions()
	if previous!=null:
		tree.root.remove_child(previous)
		previous.queue_free()
	tree.current_scene=world
	world.show()
	for node in chapter.get_children():
		if node is CanvasLayer: node.show()
	for entry in frozen:
		var node: Node=entry[0]
		node.set_process(entry[1]);node.set_physics_process(entry[2])
		node.set_process_input(entry[3]);node.set_process_unhandled_input(entry[4])
	chapter._show_dialog("SAVED CHAPTER RESTORED", "Your complete saved chapter is ready. No progress was merged and no file was overwritten. Resume deliberately.",[["Resume","resume"]])
	return ""
