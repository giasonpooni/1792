extends "res://mahan/mahan_chapter.gd"
const CavalryModel := preload("res://mahan/mahan_cavalry_state.gd")

func _ready() -> void:
	# Allow logistics (or other) adapters to install their model before super._ready().
	if campaign == null or not campaign.has_method("enable_riding"):
		campaign = CavalryModel.new()
	campaign.enable_riding()
	super._ready()
	_marker(campaign.position() + Vector3(0.9, 0.0, 0.2), Color("3a7a4a"), "Mount")

func _refresh_panels() -> void:
	super._refresh_panels()
	var mounted: bool = campaign.is_mounted()
	var can_toggle: bool = campaign.near("camp_table") or campaign.near(campaign.column_node())
	_panel("Riding", "Mounted: %s\nToggle only at camp table or column." % ("yes" if mounted else "no"), Vector2(16, 292))
	_btn("Dismount" if mounted else "Mount", Vector2(16, 360), not can_toggle, _toggle_riding)

func _toggle_riding() -> void:
	var err: String = campaign.dismount() if campaign.is_mounted() else campaign.mount()
	if not err.is_empty():
		status.text = err
		return
	status.text = "Dismounted." if not campaign.is_mounted() else "Mounted — walk path restricted until dismount."
	_refresh_panels()
