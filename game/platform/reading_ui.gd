# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Style selected title/modal controls only. No world nodes, state queries or input executor.
const Profile := preload("res://platform/reading_profile.gd")
const META := "cg_reading_original"

static func _remember(control: Control) -> Dictionary:
	if control.has_meta(META): return control.get_meta(META)
	var original: Dictionary={"styles":{},"colors":{}}
	if control is Label or control is Button:
		original.font_size=control.get_theme_font_size("font_size")
		original.font_override=control.has_theme_font_size_override("font_size")
		for color in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
			original.colors[color]=control.get_theme_color(color) if control.has_theme_color_override(color) else null
	if control is PanelContainer: original.styles.panel=control.get_theme_stylebox("panel") if control.has_theme_stylebox_override("panel") else null
	if control is Button:
		for style in ["normal","hover","pressed","focus","disabled"]:
			original.styles[style]=control.get_theme_stylebox(style) if control.has_theme_stylebox_override(style) else null
	control.set_meta(META,original)
	return original

static func apply(root: Node) -> void:
	if not is_instance_valid(root): return
	var p:=Profile.snapshot()
	var nodes: Array[Node]=[root]
	while not nodes.is_empty():
		var node: Node=nodes.pop_back()
		nodes.append_array(node.get_children())
		if not node is Control or (not node is Label and not node is Button and not node is PanelContainer): continue
		var original:=_remember(node)
		if original.has("font_size"):
			var size:=int(round(float(original.font_size)*p.text_percent/100.0))
			if p.text_percent==100 and not original.font_override: node.remove_theme_font_size_override("font_size")
			else: node.add_theme_font_size_override("font_size",size)
			if node is Button: node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		for color in original.colors:
			if p.high_contrast: node.add_theme_color_override(color,Color("bdbdbd") if color=="font_disabled_color" else Color.WHITE)
			elif original.colors[color]==null: node.remove_theme_color_override(color)
			else: node.add_theme_color_override(color,original.colors[color])
		for style in original.styles:
			if p.high_contrast:
				var box:=StyleBoxFlat.new()
				box.bg_color=Color.BLACK
				box.content_margin_left=16;box.content_margin_right=16
				box.content_margin_top=12;box.content_margin_bottom=12
				box.border_color=Color("ffe080") if style=="focus" else Color("999999")
				box.set_border_width_all(3 if style=="focus" else 1)
				if style=="focus": box.draw_center=false
				node.add_theme_stylebox_override(style,box)
			elif original.styles[style]==null: node.remove_theme_stylebox_override(style)
			else: node.add_theme_stylebox_override(style,original.styles[style])

static func reveal_focus_after_layout(container: Control, scroll: ScrollContainer) -> void:
	# Font changes schedule container sorting. A pre-sort focus request can point to
	# the old rectangle; correct it once after layout, never every frame while reading.
	if not is_instance_valid(container) or not container.is_inside_tree() or container.has_meta("cg_reading_focus_pending"): return
	container.set_meta("cg_reading_focus_pending",true)
	var tree:=container.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(container): return
	container.remove_meta("cg_reading_focus_pending")
	if not container.is_inside_tree() or not container.is_visible_in_tree() or not is_instance_valid(scroll): return
	var focus:=container.get_viewport().gui_get_focus_owner()
	if focus is Control and focus.is_visible_in_tree() and container.is_ancestor_of(focus):
		scroll.ensure_control_visible(focus)
