# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends CanvasLayer
## Existing words and task state, in a reversible compact layout; no new knowledge.
var compact := true
var task: Label
var words: Label
var narrator: Label
var top: PanelContainer
var bottom: PanelContainer
var _chapter: Node3D
var _labels: Array[Dictionary]=[]
var _original: Array[Dictionary]=[]
func _label(size: int,color: Color) -> Label:
	var n:=Label.new();n.add_theme_font_size_override("font_size",size);n.add_theme_color_override("font_color",color)
	n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.mouse_filter=Control.MOUSE_FILTER_IGNORE;return n
func _panel() -> PanelContainer:
	var p:=PanelContainer.new();p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new();style.bg_color=Color(.055,.061,.053,.78)
	style.set_content_margin_all(12);style.set_corner_radius_all(3);p.add_theme_stylebox_override("panel",style);add_child(p);return p
func build(chapter: Node3D) -> void:
	_chapter=chapter;layer=15
	for n in [chapter._hud,chapter._caption,chapter._narrator_label]: _original.append({"node":n,"visible":n.visible})
	for n in chapter.get_parent().find_children("*","Label3D",true,false): _labels.append({"node":n,"visible":n.visible})
	top=_panel();var v:=VBoxContainer.new();v.add_theme_constant_override("separation",6);top.add_child(v)
	var title:=_label(11,Color("d7c8a1"));title.text="GUJRANWALA  /  HOUSEHOLD COMMISSION";v.add_child(title)
	task=_label(17,Color("ece8dc"));v.add_child(task);narrator=_label(13,Color("cbc6b4"));v.add_child(narrator)
	bottom=_panel();v=VBoxContainer.new();v.add_theme_constant_override("separation",6);bottom.add_child(v)
	words=_label(15,Color("eee9da"));v.add_child(words)
	var controls:=_label(11,Color("bcbcae"));controls.text="E  Speak    B  Accounts    J  Journal    F5 / F9  Save / Load    F7  Visual controls";v.add_child(controls)
	sample()
func sample() -> void:
	if not is_instance_valid(_chapter): return
	var eligible: bool=compact and _chapter.model.has_economy() and _chapter.model.workshop_phase() in ["fuel","working","ready","tools"] and not _chapter.model.brawl_busy()
	var active: bool=eligible and not _chapter._paused;visible=active
	if eligible:
		for r in _original:
			if is_instance_valid(r.node): r.node.hide()
	elif not _chapter._paused:
		for r in _original:
			if is_instance_valid(r.node): r.node.visible=r.visible
	if active:
		var size:=_chapter.get_viewport().get_visible_rect().size
		top.position=Vector2(18,18);top.size=Vector2(minf(370,size.x-36),0);bottom.size=Vector2(minf(760,size.x-36),0)
		task.text=_chapter.workshop_hint().replace(" [E]","");narrator.text=_chapter._narrator_label.text;narrator.visible=not narrator.text.is_empty()
		words.text=_chapter._message
		bottom.position=Vector2((size.x-bottom.size.x)*.5,size.y-bottom.get_combined_minimum_size().y-18)
	for r in _labels:
		if is_instance_valid(r.node): r.node.visible=r.visible and (not active or r.node.global_position.distance_to(_chapter.avatar.global_position)<6.5)
func _exit_tree() -> void:
	for r in _original+_labels:
		if is_instance_valid(r.node): r.node.visible=r.visible
