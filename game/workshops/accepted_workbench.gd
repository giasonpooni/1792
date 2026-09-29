# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## The GLB is a visual artifact. This scene owns its separate game collision/access.
## No process callback, stock, clock, save state, or authoring tool dependency.
const ASSET_PATH := "res://assets/props/workbench.glb"
const ASSET_SHA256 := "60ea4b4657f9c73d12c956e20498e99afa0f892a7b3167ecb033c53d3ec50736"
const PLACEMENT := Vector3(-46,0.132,-5.4)

func can_collect(actor: CharacterBody3D) -> bool:
	if not is_visible_in_tree() or not $Visual.is_visible_in_tree(): return false
	# Preserve the existing conversation-scale reach, but not wrong-floor pickup.
	if absf(actor.global_position.y-global_position.y)>0.35: return false
	var target: Vector3=$CollectionPoint.global_position
	if actor.global_position.distance_to(target)>3.6: return false
	var eye: Vector3=actor.global_position+Vector3.UP*1.35
	var query:=PhysicsRayQueryParameters3D.create(eye,target,1,[actor.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
