# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit post-inquiry/placement fixtures, followed by real scene input and clock.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Rules := preload("res://territory/misl_rules.gd")
const Direction := preload("res://territory/water_round_story.gd")
const Attention := preload("res://presentation/story_attention.gd")
const WELL_STAND := Vector3(26,0.14,14)
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
func ok(error: String, label: String) -> void: check(error.is_empty(), label + ": " + error)
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene, site: Vector3) -> void:
	var d: Vector3 = site - scene.avatar.global_position
	scene.avatar.pivot.rotation.y = atan2(-d.x,-d.z)
func tap(scene, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)
	await frames(2)
func press(scene, prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix):
			button.pressed.emit()
			await frames(2)
			return
	check(false, "missing offered action: " + prefix)
func place(scene, site: Vector3, facing: Vector3) -> void:
	ok(Pose.pose(scene.model,site),"explicit placement fixture")
	scene._apply()
	await frames(4)
	look(scene,facing)
func _run() -> void:
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = "user://water-story-only.json"
	ok(scene.model.restore(Fixture.complete()),"explicit post-inquiry fixture")
	ok(scene.model.begin_allowance(),"existing allowance")
	root.add_child(home)
	await frames(5)
	look(scene,Water.STORE)
	await tap(scene,KEY_E)
	await press(scene,"Accept household water round")
	check(scene.model.has_water_round(),"offered assignment accepted near quartermaster")
	check(scene._message.begins_with("Quartermaster"),"nearby quartermaster gives practical assignment")
	var economy_before: Dictionary = scene.model.economy().ledger
	await place(scene,WELL_STAND,Water.WELL)
	await tap(scene,KEY_E)
	check(not scene._panel_text.text.contains("ticks") and not scene._panel_text.text.contains("units"),"well dialogue presents action rather than development metadata")
	var before_turn: Dictionary = scene.model.water_round()
	look(scene,scene.avatar.global_position+Vector3.RIGHT*3)
	await press(scene,"Draw one load")
	check(scene.model.water_round()==before_turn,"queued draw rechecks physical facing before mutation")
	look(scene,Water.WELL)
	await tap(scene,KEY_E)
	scene._open_journal()
	scene._menu_action("water:draw")
	await frames(2)
	check(scene.model.water_round()==before_turn,"replacing water dialog with journal clears its offered action scope")
	scene._resume()
	await tap(scene,KEY_E)
	await press(scene,"Draw one load")
	check(scene.model.water_round().ledger.phase == "drawing","first draw starts through offered action")
	check(Attention.reading_ticks(scene._message) <= Water.DRAW_TICKS,"draw cue fits before its completion beat")
	await frames(30)
	await tap(scene,KEY_E)
	var paused_tick: int = scene.model.progress().tick
	var paused_history: Array = scene.story_attention.history()
	await frames(190)
	check(scene.model.progress().tick == paused_tick,"well panel freezes existing draw clock")
	check(scene.model.water_round().ledger.phase == "drawing" and scene.model.water_round().ledger.carried == 0,"paused draw cannot create water")
	check(scene.story_attention.history() == paused_history,"paused wait does not announce a fill")
	await press(scene,"Cancel this draw")
	check(scene.model.water_round().ledger.remaining == 6 and scene.model.water_round().ledger.carried == 0,"cancel retains complete assignment")
	await tap(scene,KEY_E)
	await press(scene,"Draw one load")
	await frames(30)
	await tap(scene,KEY_F5)
	var saved_events: int = scene.model.water_round().events.size()
	await frames(185)
	var first_fill: String = scene._message
	check(scene.model.water_round().ledger.carried == 3,"live clock fills first carrier")
	check(first_fill == Direction.filled_line(scene.model.water_round()),"actual fill receives first weight reaction")
	check(scene.story_caption() == first_fill,"fill reaction is visible through attention queue")
	await tap(scene,KEY_F9)
	check(scene.model.water_round().ledger.phase == "drawing","ordinary F9 restores pending draw")
	check(scene.model.water_round().events.size() == saved_events,"reload replaces later completion receipt")
	check(scene._message != first_fill,"load does not pretend fill has just happened")
	await frames(185)
	check(scene.model.water_round().ledger.carried == 3,"restored clock fills once")
	check(scene._message == first_fill,"resumed draw gets the same first-load beat at completion")
	await place(scene,Water.STORE-Vector3(0,0,1),Water.STORE)
	await tap(scene,KEY_E)
	await press(scene,"Deposit carried water")
	check(scene.model.water_round().ledger.stored == 3,"first deposit accounts exactly one load")
	check(scene._message.begins_with("Quartermaster"),"deposit acknowledgment comes from nearby household speaker")
	var half_level: float = scene.water_view.tank_water.position.y
	check(scene.water_view.tank_water.visible and not scene.water_view.carried.visible,"first deposit transfers visible water")
	await place(scene,WELL_STAND,Water.WELL)
	await tap(scene,KEY_E)
	check(scene._panel_text.text.contains("same rope") and not scene._panel_text.text.contains("Stay beside"),"second interaction changes observation without repeating tutorial")
	await press(scene,"Draw one load")
	await frames(185)
	check(scene.model.water_round().ledger.carried == 3,"second live draw fills one load")
	check(scene._message != first_fill and scene._message.begins_with("Buddh"),"second load gives distinct personal observation")
	check(scene.water_view.well_label.text.contains("one load left"),"well describes remaining return")
	await place(scene,Water.STORE-Vector3(0,0,1),Water.STORE)
	await tap(scene,KEY_E)
	await press(scene,"Deposit carried water")
	check(scene.model.water_round().ledger.stored == 6 and scene.model.water_round().ledger.phase == "complete","two deposits finish exactly six units")
	check(scene.water_view.tank_water.position.y > half_level,"household vessel visibly rises from half to full")
	check(scene.model.economy().ledger == economy_before,"water story grants no coins or resource side reward")
	var complete: Dictionary = scene.model.water_round()
	scene._menu_action("water:deposit")
	await frames(2)
	check(scene.model.water_round() == complete,"closed-dialog callback cannot repeat deposit")
	await tap(scene,KEY_E)
	scene._menu_action("water:draw")
	await frames(2)
	check(scene.model.water_round() == complete,"unoffered water action cannot queue from another dialog")
	scene._resume()
	await tap(scene,KEY_F5)
	var saved_water: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scene.save_path)).water_round
	check(Rules._equal(saved_water.ledger,complete.ledger) and saved_water.events.size()==complete.events.size(),"saved file retains exact completed ledger and receipt count")
	await tap(scene,KEY_F9)
	check(Rules._equal(scene.model.water_round(),saved_water),"completed water receipts match actual serialized save after ordinary F9")
	check(not scene._message.begins_with("Quartermaster"),"completed reload does not repeat reward acknowledgment")
	check(scene._account_text().contains("180 existing") and scene._account_text().contains("original authored"),"mechanical quantities and fiction provenance remain in account view")
	# Direct fixture changes must refresh props without masquerading as live events.
	ok(scene.model.restore(Fixture.complete()),"explicit earlier state fixture")
	ok(scene.model.begin_allowance(),"fixture allowance")
	ok(scene.model.begin_water_round(),"fixture assignment")
	ok(Pose.pose(scene.model,WELL_STAND),"fixture at well")
	ok(scene.model.water_action("draw"),"fixture starts drawing")
	for _i in range(Water.DRAW_TICKS): scene.model.advance()
	scene._apply()
	scene._message = "Fixture rebound."
	await frames(3)
	check(scene._message == "Fixture rebound.","already filled fixture does not fabricate a live completion caption")
	check(scene.water_view.carried.visible,"already filled fixture still binds carried visual")
	DirAccess.remove_absolute(scene.save_path)
	home.queue_free()
	await frames()
	print("WATER_ROUND_STORY_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
