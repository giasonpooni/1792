# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://presentation/home_art.gd"
## Reversible refinement of the existing Home appearance, never another game loop.
const Detail := preload("res://presentation/courtyard_detail.gd")
var detail: Node3D
var refinement_enabled := true
func build(chapter: Node3D) -> String:
	var error := super.build(chapter)
	if not error.is_empty(): return error
	detail=Detail.new();detail.name="AuthoredCourtyard";add_child(detail)
	error=detail.build(chapter,self)
	if not error.is_empty(): return error
	detail.set_enabled(enabled and refinement_enabled)
	sample(int(chapter.model.progress().tick));return ""
func set_refinement(value: bool) -> void:
	refinement_enabled=value
	if is_instance_valid(detail): detail.set_enabled(enabled and value)
func set_enabled(value: bool) -> void:
	if is_instance_valid(detail): detail.set_enabled(false)
	super.set_enabled(value)
	if is_instance_valid(detail): detail.set_enabled(value and refinement_enabled)
func sample(tick: int) -> void:
	super.sample(tick)
	if is_instance_valid(detail): detail.sample(tick)
func _exit_tree() -> void:
	if is_instance_valid(detail): detail.set_enabled(false)
	super._exit_tree()
