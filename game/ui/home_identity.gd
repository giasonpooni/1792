extends CanvasLayer
## Lightweight home-only nameplate on the existing player scene. No gameplay state.
const Names := preload("res://characters/character_names.gd")

func _ready() -> void:
	var location := get_parent().get_parent()
	if location == null or location.scene_file_path != "res://world/home_territory.tscn":
		queue_free() # Command scenes own their HUD; never draw two nameplates.
		return
	var panel := PanelContainer.new()
	panel.name = "HomeIdentityPanel"
	panel.position = Vector2(18, 18)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202827")
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var text := Label.new()
	text.name = "HomeIdentityText"
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", 19)
	text.text = "1792 · " + Names.player_name(Names.HERO_ID) + "\nSukerchakia home territory\n\nWASD move · Shift run · Mouse look · F1 menu"
	panel.add_child(text)
