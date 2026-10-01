# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends CanvasLayer
## Paused, read-only authoring view. Year selection grants no player knowledge or time travel.
signal closed
const Atlas := preload("res://geography/atlas.gd")
const MapView := preload("res://geography/atlas_map.gd")
var atlas := Atlas.new()
var panel: PanelContainer
var map_view: Control
var list: ItemList
var detail: RichTextLabel
var year_label: Label
var slider: HSlider
var year := 1792
var selected_id := "gujranwala"
var ids: Array = []
var close_button: Button

func _ready() -> void:
	layer=20
	var error:=atlas.load_catalogue()
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left=12;panel.offset_top=12;panel.offset_right=-12;panel.offset_bottom=-12
	add_child(panel)
	var margin:=MarginContainer.new()
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,10)
	panel.add_child(margin)
	var column:=VBoxContainer.new();margin.add_child(column)
	var title:=Label.new();title.text="1792 | HISTORICAL WORLD ATLAS";title.add_theme_font_size_override("font_size",20);column.add_child(title)
	var notice:=Label.new();notice.text="Research view - not Buddh's knowledge. 1 unit = 1 metre is the target; this is a map diagram."
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(notice)
	if not error.is_empty():
		notice.text=error;return
	var row:=HBoxContainer.new();column.add_child(row)
	year_label=Label.new();year_label.custom_minimum_size.x=140;row.add_child(year_label)
	slider=HSlider.new();slider.min_value=1200;slider.max_value=1873;slider.step=1;slider.value=year
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void: year=int(value);refresh())
	var split:=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(split)
	map_view=MapView.new();map_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical=Control.SIZE_EXPAND_FILL;map_view.catalogue=atlas.snapshot();split.add_child(map_view)
	map_view.selected.connect(select_place)
	list=ItemList.new();list.custom_minimum_size.x=195;list.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(list)
	for place in atlas.snapshot().places:
		ids.append(place.id);list.add_item(place.label+" ["+place.placement_class+"]")
	list.item_selected.connect(func(index: int) -> void: select_place(ids[index]))
	detail=RichTextLabel.new();detail.bbcode_enabled=false;detail.custom_minimum_size.y=96
	detail.scroll_active=true;detail.selection_enabled=true;column.add_child(detail)
	var bottom:=HBoxContainer.new();column.add_child(bottom)
	var legend:=Label.new();legend.size_flags_horizontal=Control.SIZE_EXPAND_FILL;legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	legend.text="252 missing macro cells | A: published point, accuracy unknown | C: authored research label | D: unlocated"
	legend.add_theme_font_size_override("font_size",12);bottom.add_child(legend)
	close_button=Button.new();close_button.text="Return (F3)";close_button.pressed.connect(func() -> void: closed.emit());bottom.add_child(close_button)
	select_place(selected_id);close_button.grab_focus()

func select_place(id: String) -> void:
	if atlas.place(id).is_empty(): return
	selected_id=id
	if is_instance_valid(list): list.select(ids.find(id))
	refresh()
func refresh() -> void:
	if not is_instance_valid(year_label): return
	year_label.text="Inspection year: %d"%year
	map_view.selected_id=selected_id;map_view.queue_redraw()
	var text:=atlas.summary(selected_id,year)
	var chapters: Array=[]
	for chapter in atlas.plan().campaigns:
		if year>=chapter.story_window[0] and year<chapter.story_window[1]: chapters.append(chapter.title)
	text+="\nEditorial campaign windows (not verified lifespans): "+", ".join(chapters)
	text+="\nNo surveyed footprints, heights, terrain tiles or religious-importance ratings admitted. Selecting a year does not change the game."
	detail.text=text
