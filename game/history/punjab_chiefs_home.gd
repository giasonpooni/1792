# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Additive runnable composition. The original launcher and its Home remain intact.
const HomeLaunch := preload("res://childhood/home_launch.gd")
const Entry := preload("res://history/punjab_chiefs_entry.gd")

func _ready() -> void:
	var home := HomeLaunch.make_world()
	home.name = "RetainedHousehold"
	home.get_node("ChildhoodChapter").autoplay_intro = true
	var entry := Entry.new()
	entry.name = "PunjabChiefsStoryBench"
	home.add_child(entry)
	add_child(home)
