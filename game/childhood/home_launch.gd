extends RefCounted
## Compose a controller onto the original scene without changing its retained bytes.
const Home := preload("res://world/home_territory.tscn")
const Chapter := preload("res://history/childhood_intro_chapter.gd")

static func make_world() -> Node3D:
	var home: Node3D = Home.instantiate()
	var chapter := Chapter.new()
	chapter.name = "ChildhoodChapter"
	home.add_child(chapter)
	return home

static func enter(tree: SceneTree) -> void:
	var previous := tree.current_scene
	var world := make_world()
	# Actual menu entry opens the family story; construction-only tools stay inert.
	world.get_node("ChildhoodChapter").autoplay_intro=true
	if previous != null:
		tree.root.remove_child(previous)
		previous.queue_free()
	tree.root.add_child(world)
	tree.current_scene = world
