extends "res://tests/test_house_conflict.gd"
## Additional audit regressions; runs the unchanged 253-assertion suite afterward.

func _run() -> void:
	var model = setup("defer", "scout")
	ok(model.play_commander(), "unobserved withdrawal setup")
	ok(model.resolve("withdraw"), "unobserved withdrawal accepted")
	check(model.house_state().report.territory == null, "withdrawal cannot report unobserved territorial conditions")
	check(not model.house_state().report.outpost_observed, "report records observation limit")
	check(model.received_house_report().is_empty(), "unknown report still has delivery delay")
	ok(model.save_to(SAVE), "save unobserved report in transit")
	var loaded = Houses.new()
	ok(loaded.load_from(SAVE), "restore unobserved report in transit")
	model.advance(4)
	loaded.advance(4)
	check(model.snapshot() == loaded.snapshot(), "unknown report continues identically after load")
	check(model.received_house_report().territory == null, "delivery cannot invent observations")
	var forged: Dictionary = model.snapshot()
	forged.house_conflict.history.back().outpost_observed = true
	forged.house_conflict.report.outpost_observed = true
	forged.house_conflict.report.territory = forged.house_conflict.territory.duplicate(true)
	bad_save(model, forged, "self-consistent political evidence without actual outpost observation")
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	ok(scene.campaign.restore(model.snapshot()), "UI unknown report fixture")
	scene._refresh_hud()
	check(scene._journal.text.contains("Territorial conditions: unknown"), "UI marks territorial report unknown")
	check(scene._field_sign.text == "", "unobserved report does not update distant field sign")
	scene._open_houses()
	check(not scene._hud.visible and not scene._journal.visible, "modal cannot overlap HUD text")
	scene._close_panel()
	check(scene._hud.visible and scene._journal.visible, "closing restores HUD and journal")
	scene.queue_free()
	await process_frame
	await super._run()
