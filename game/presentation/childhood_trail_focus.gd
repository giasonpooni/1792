# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Resolve two known overlaps between later market dressing and the older trail.
## This is a fixed art-layout correction, never a proximity or stage-driven fade.
## Exact presentation roots move; the authoritative sites, camera and bodies do not.
const TARGETS := [
	{
		"path": "BazaarStreetSectionStudy/StreetBay_R_2",
		"script": "res://youth/performance/bazaar_street_section.gd",
		"position": Vector3(-15.36765, 0.14, -13.50296),
		"offset": Vector3(0.57, 0, 1.71),
		"shape": "RaisedThreshold"
	},
	{
		"path": "BazaarMarketCraft/StorageBasket6",
		"script": "res://youth/performance/bazaar_market_stage.gd",
		"position": Vector3(4.05268, 0.16, -3.15078),
		"offset": Vector3(2.4, 0, 0.3),
		"shape": ""
	}
]
var corrections: Array[Dictionary] = []
var _pending := [0, 1]
var _chapter: Node3D

func build(chapter: Node3D) -> void:
	if is_instance_valid(_chapter): return
	_chapter = chapter
	name = "TrailLayoutFocus"
	set_meta("classification", "original-presentation")
	set_meta("gameplay_authority", false)
	set_process(false)
	set_physics_process(false)
	sample()

func sample() -> void:
	if not is_instance_valid(_chapter) or _pending.is_empty(): return
	# Production builds these layers later than the lesson. Bind each once when
	# it exists; do not traverse the scene or reapply a transform every frame.
	for index in _pending.duplicate():
		var target: Dictionary = TARGETS[index]
		var node := _chapter.get_node_or_null(target.path) as Node3D
		if node == null: continue
		_pending.erase(index)
		if not _matches(node, target): continue
		corrections.append({"node": node, "transform": node.transform})
		node.position += target.offset

func _matches(node: Node3D, target: Dictionary) -> bool:
	var source: Script = node.get_parent().get_script()
	if source == null or source.resource_path != target.script: return false
	if node.position.distance_to(target.position) > 0.002: return false
	if node is CollisionObject3D or node is CollisionShape3D: return false
	if not node.find_children("*", "CollisionObject3D", true, false).is_empty(): return false
	if not node.find_children("*", "CollisionShape3D", true, false).is_empty(): return false
	var visual := node.get_node_or_null(target.shape) as MeshInstance3D if not target.shape.is_empty() else node as MeshInstance3D
	if visual == null: return false
	if target.shape == "RaisedThreshold":
		return visual.mesh is BoxMesh and visual.mesh.size.is_equal_approx(Vector3(2.2, 0.18, 1.25))
	return visual.mesh is CylinderMesh and is_equal_approx(visual.mesh.height, 0.32) and is_equal_approx(visual.mesh.top_radius, 0.34)

func _exit_tree() -> void:
	for record in corrections:
		if is_instance_valid(record.node): record.node.transform = record.transform
