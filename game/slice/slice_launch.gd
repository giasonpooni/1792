# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
const Home := preload("res://world/home_territory.tscn")
const Chapter := preload("res://slice/slice_chapter.gd")

static func make_world(mode: String="new") -> Node3D:
	var home: Node3D=Home.instantiate()
	var chapter:=Chapter.new();chapter.name="ChildhoodChapter";chapter.startup_mode=mode
	home.add_child(chapter)
	return home

static func enter(tree: SceneTree,mode: String="new") -> void:
	var previous:=tree.current_scene
	var world:=make_world(mode)
	if previous!=null:
		tree.root.remove_child(previous);previous.queue_free()
	tree.root.add_child(world);tree.current_scene=world
