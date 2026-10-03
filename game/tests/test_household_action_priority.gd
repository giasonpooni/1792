extends "res://tests/test_household_attention.gd"
## Explicit valid reducer fixtures; checks final production menu order, retained
## alternatives and native focus/clipping without claiming another played route.
const Bazaar := preload("res://youth/brawl_rules.gd")
const Priority := preload("res://presentation/household_action_priority.gd")

func dialog(model, speaker: String, expected: String, alternatives: Array, label: String) -> void:
	chapter._resume()
	accepted(chapter.model.restore(model.snapshot()), "valid action-order fixture: " + label)
	chapter._message = ""
	chapter._apply()
	var before: Dictionary = chapter.model.snapshot()
	if speaker == "home": chapter._open_quartermaster()
	else: chapter._open_market()
	await frames(6)
	var buttons: Array = chapter._actions.get_children()
	var first: Button = buttons[0]
	check(Priority.action_id(first) == expected, "accepted continuation is first: " + label)
	check(first.has_focus(), "accepted continuation owns keyboard focus: " + label)
	if expected in ["water:deposit", "smith:deliver", "service:debrief"]:
		check(not chapter._panel_text.text.contains("Four portions for the market"), "active handover replaces unrelated dispatch exposition: " + label)
	var ids: Array[String] = []
	for button in buttons: ids.append(Priority.action_id(button))
	for alternate in alternatives:
		check(str(alternate) in ids, "alternative remains available: " + label + "/" + str(alternate))
	check(chapter._journal_scroll.get_global_rect().encloses(first.get_global_rect()), "primary button fits visible small scroll window: " + label)
	check(root.get_visible_rect().encloses(first.get_global_rect()), "primary button fits small viewport: " + label)
	for _i in range(3): chapter._focus_household_continuation(speaker)
	check(chapter._actions.get_children() == buttons, "reordering is stable and preserves every button: " + label)
	check(chapter.model.snapshot() == before, "menu priority changes no game state: " + label)
	if OS.get_environment("HOUSEHOLD_ACTION_RENDER") == "1":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if check(not image.is_empty() and image.get_size() == Vector2i(800,450) and image.save_png("user://household-action-" + label + ".png") == OK, "native small dialog capture: " + label): captures += 1

func pre_allowance_bazaar():
	# Explicit detached companion-pose fixtures create a valid returning branch.
	# They prove menu priority, not another physically traversed bazaar journey.
	var model := Model.new()
	accepted(model.restore(Fixture.complete()), "pre-allowance completed inquiry")
	accepted(Pose.pose(model, Supply.MARKET), "pre-allowance market contact fixture")
	accepted(model.begin_brawl(), "bazaar invitation requires no household allowance")
	for destination in [Bazaar.RING, Bazaar.REGROUP, Supply.QUARTERMASTER]:
		var staged: Dictionary = model.snapshot()
		for friend in [3,4]: staged.youth_brawl.actors[friend].position = Base.coords(destination + Vector3(friend - 3,0,0))
		accepted(model.restore(staged), "explicit companion pose fixture")
		accepted(Pose.pose(model, destination), "explicit returning player pose fixture")
		if destination == Bazaar.RING:
			accepted(model.brawl_action("challenge"), "actual challenge receipt")
			accepted(model.brawl_action("leave"), "actual leave receipt")
		elif destination == Bazaar.REGROUP: accepted(model.brawl_action("regroup"), "actual regroup receipt")
	check(not model.has_economy() and model.brawl_phase() == "returning", "valid returning outing precedes allowance")
	return model

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HOUSEHOLD ACTION PRIORITY requires Xvfb/gl_compatibility for native focus/clipping qualification."); quit(2); return
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(800,450)
	home = Launch.make_world()
	chapter = home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(5)
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var model = pre_allowance_bazaar()
	await dialog(model, "home", "youth:report", ["econ:begin", "resume"], "bazaar-before-allowance")
	model = base_fixture(false)
	await dialog(model, "home", "econ:accept_delivery", ["smith:reserve", "water:begin", "service:begin", "resume"], "food-dispatch")
	accepted(model.operate("accept_delivery"), "accepted four-food contract")
	accepted(Pose.pose(model, Supply.MARKET), "explicit trader contact fixture")
	await dialog(model, "market", "econ:deliver", ["youth:invite", "econ:buy|food", "resume"], "food-handover")
	accepted(model.operate("deliver"), "same food receipt unlocks escort")
	accepted(model.operate("accept_escort"), "accepted return carrier")
	accepted(Pose.pose(model, Supply.QUARTERMASTER), "explicit home-alone fixture")
	await dialog(model, "home", "resume", ["econ:checkin", "water:begin", "smith:reserve"], "recover-carrier")
	var arrived: Dictionary = model.snapshot()
	arrived.misl.merchant.position = Base.coords(Supply.QUARTERMASTER + Vector3(-2,0,-1))
	arrived.misl.merchant.velocity = [0.0,0.0,0.0]
	accepted(model.restore(arrived), "explicit valid arrived-carrier fixture")
	await dialog(model, "home", "econ:checkin", ["water:begin", "service:begin", "smith:reserve", "resume"], "carrier-checkin")
	model = base_fixture(false)
	accepted(model.begin_water_round(), "accept actual two-load round")
	accepted(Pose.pose(model, Water.WELL), "explicit well contact fixture")
	accepted(model.water_action("draw"), "actual draw begins")
	for _i in range(Water.DRAW_TICKS): model.advance()
	accepted(Pose.pose(model, Water.STORE), "explicit full-water return fixture")
	await dialog(model, "home", "water:deposit", ["econ:accept_delivery", "service:begin", "smith:reserve", "resume"], "water-deposit")
	accepted(model.operate("accept_delivery"), "original state allows food contract while water is carried")
	await dialog(model, "home", "water:deposit", ["service:begin", "smith:reserve", "resume"], "water-before-food")
	model = base_fixture(true)
	for _i in range(Craft.WORK_TICKS): model.advance()
	accepted(Pose.pose(model, Craft.SITE), "explicit completed-smith contact fixture")
	accepted(model.workshop_action("collect"), "collect actual finished tool pair")
	accepted(Pose.pose(model, Supply.QUARTERMASTER), "explicit tool return fixture")
	await dialog(model, "home", "smith:deliver", ["econ:accept_delivery", "water:begin", "service:begin", "resume"], "tools-return")
	model = base_fixture(false)
	accepted(model.operate("hire", "guard"), "hire existing service guard")
	accepted(model.rest_watch(), "settle paid supplied watch")
	accepted(model.begin_service(), "hear service brief")
	accepted(Pose.pose(model, Service.SITES.market), "explicit local request fixture")
	accepted(model.service_action("hear", "market"), "receive actual request")
	accepted(Pose.pose(model, Supply.QUARTERMASTER), "explicit dispatch fixture")
	accepted(model.service_action("dispatch", "market"), "dispatch qualified guard")
	service_travel(model, Service.SITES.market)
	for _i in range(Service.SERVICE_TICKS): model.advance(); model.progress_service()
	service_travel(model, Service.home(int(model.service().ledger.slot)))
	check(model.service().ledger.stage == "awaiting_account", "guard returned before account offered")
	await dialog(model, "home", "service:debrief", ["econ:accept_delivery", "water:begin", "smith:reserve", "resume"], "guard-account")
	home.queue_free()
	await frames()
	print("HOUSEHOLD_ACTION_PRIORITY_TESTS: %d passed, %d failed; %d captures" % [passed, failed, captures])
	quit(1 if failed else 0)
