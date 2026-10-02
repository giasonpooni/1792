extends RefCounted
## Compose the Mahan interlude (cavalry + logistics + politics + orders + history + encounter + settlement + garhi landmark) onto its own camp scene without touching childhood/Lahore bytes.
const Camp := preload("res://world/mahan_camp.tscn")
const Chapter := preload("res://mahan/mahan_garhi_chapter.gd")

static func make_world() -> Node3D:
	var camp: Node3D = Camp.instantiate()
	var chapter := Chapter.new()
	chapter.name = "MahanChapter"
	camp.add_child(chapter)
	return camp

static func enter(tree: SceneTree) -> void:
	var previous := tree.current_scene
	var world := make_world()
	if previous != null:
		tree.root.remove_child(previous)
		previous.queue_free()
	tree.root.add_child(world)
	tree.current_scene = world
