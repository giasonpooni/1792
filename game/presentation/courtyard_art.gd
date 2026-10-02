# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://presentation/home_art.gd"
## Reversible refinement of the existing Home appearance, never another game loop.
const Detail := preload("res://presentation/courtyard_detail.gd")
const Beauty := preload("res://presentation/gujranwala_beauty.gd")
var detail: Node3D
var beauty: Node3D
var refinement_enabled := true
func build(chapter: Node3D) -> String:
	var error := super.build(chapter)
	if not error.is_empty(): return error
	detail=Detail.new();detail.name="AuthoredCourtyard";add_child(detail)
	error=detail.build(chapter,self)
	if not error.is_empty(): return error
	detail.set_enabled(enabled and refinement_enabled)
	beauty=Beauty.new();beauty.name="GujranwalaBeautyPass";add_child(beauty);beauty.build(chapter)
	beauty.set_enabled(enabled and refinement_enabled);beauty.set_preset(preset)
	sample(int(chapter.model.progress().tick));return ""
func set_refinement(value: bool) -> void:
	refinement_enabled=value
	if is_instance_valid(detail): detail.set_enabled(enabled and value)
	if is_instance_valid(beauty): beauty.set_enabled(enabled and value)
func set_enabled(value: bool) -> void:
	if is_instance_valid(detail): detail.set_enabled(false)
	if is_instance_valid(beauty): beauty.set_enabled(false)
	super.set_enabled(value)
	if is_instance_valid(detail): detail.set_enabled(value and refinement_enabled)
	if is_instance_valid(beauty):
		beauty.set_enabled(value and refinement_enabled)
		beauty.set_preset(preset)
func set_preset(id: String) -> String:
	var error: String=super.set_preset(id)
	if not error.is_empty(): return error
	if is_instance_valid(beauty): beauty.set_preset(id)
	return ""

func sample(tick: int) -> void:
	super.sample(tick)
	if is_instance_valid(detail): detail.sample(tick)
	if is_instance_valid(beauty): beauty.sample(tick)
func _exit_tree() -> void:
	if is_instance_valid(detail): detail.set_enabled(false)
	if is_instance_valid(beauty): beauty.set_enabled(false)
	super._exit_tree()
