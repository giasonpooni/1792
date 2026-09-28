extends Node3D
## Greybox scene. Domain state owns actors, allocation, outcomes and reports.

const Names := preload("res://characters/character_names.gd")
# The existing Lahore sandbox is explicitly post-accession, not inferred from its toy calendar.
const NAME_PHASE := Names.AFTER_ACCESSION

const Campaign := preload("res://campaign/command_state.gd")
const PlayerScene := preload("res://player/player.tscn")
const SAVE_PATH := "user://1792-command-story-v1.json"
var campaign = Campaign.new()
var avatar: CharacterBody3D
var _shown_actor := ""
var _clock_accumulator := 0.0
var _hud: Label
var _journal: Label
var _modal: PanelContainer
var _choices: VBoxContainer
var _notice := "Walk to the courtyard table and press E to assign a patrol."
var _standins: Dictionary = {}

func _ready() -> void:
	_build_world()
	_build_ui()
	avatar = PlayerScene.instantiate()
	avatar.set("menu_shortcut", false)
	add_child(avatar)
	_apply_actor()
	_refresh_hud()

func _physics_process(delta: float) -> void:
	if _modal.visible:
		return # Explicit pause: no background simulation while a decision menu is open.
	campaign.record_position(avatar.global_position)
	_clock_accumulator += delta
	while _clock_accumulator >= 0.5:
		_clock_accumulator -= 0.5
		campaign.advance()
	_apply_actor()
	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E:
			if not _modal.visible:
				_interact()
		KEY_F5:
			_perform("save")
		KEY_F9:
			_perform("load")
		KEY_F1:
			_open_panel("Paused", "This is a separate development sandbox. Returning to the menu discards unsaved changes.", [
				["Resume", "close", ""], ["Save and resume", "save", ""], ["Main menu (discard unsaved progress)", "menu", ""]])
		KEY_ESCAPE:
			if _modal.visible:
				_close_panel()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_:
			return
	get_viewport().set_input_as_handled()

func _interact() -> void:
	campaign.record_position(avatar.global_position)
	var state: Dictionary = campaign.snapshot()
	if campaign.actor_id() == Campaign.RANJIT:
		if not campaign.near_site("lahore_darbar"):
			_notice = "Return to the courtyard table to issue or inspect commands."
			return
		var options: Array = []
		match state.order.status:
			"available":
				options = [["Assign scouts: 2 riders / 3 supplies / 10 coins", "issue", "scout"],
					["Assign patrol: 4 riders / 6 supplies / 20 coins", "issue", "patrol"]]
			"assigned":
				options = [["Play as the captain", "play_commander", ""], ["Delegate patrol", "delegate", ""],
					["Cancel before departure (full refund)", "cancel", ""]]
			"active":
				options = [["Take control of the deployed captain", "play_commander", ""]]
		options.append(["Close", "close", ""])
		_open_panel("Lahore · Road patrol", "Fictional command story: visit the village, inspect the outpost, then organize a patrol or withdraw.\n\nScouts gather information but cannot secure this road. A patrol requires at least three riders. Once deployed, coins and supplies are spent; riders return with the report.\n\nOrder: " + state.order.status, options)
	elif campaign.near_site("village") and state.order.visited.is_empty():
		_notice = _message(campaign.visit("village"), "Villagers report an insecure road. Continue to the outpost.")
	elif campaign.near_site("outpost"):
		if "outpost" not in state.order.visited:
			var error: String = campaign.visit("outpost")
			if not error.is_empty():
				_notice = error
				return
		_open_panel("Captain · Contested outpost", "The road is contested. Organizing a patrol improves local security; it does not annex the district.\n\nThis is a decision prototype, not a combat encounter.", [
			["Organize patrol (requires 3+ allocated riders)", "resolve", "secure"],
			["Withdraw and send a warning", "resolve", "withdraw"], ["Keep exploring", "close", ""]])
	else:
		_open_panel("Captain · Field command", "Follow the marked road: village first, then outpost.\n\nReturning to Lahore hands this SAME order to the delegated policy; the captain stays at the current location.", [
			["Return to Lahore and delegate", "return_to_darbar", ""],
			["Withdraw and report now", "resolve", "withdraw"], ["Continue on foot", "close", ""]])

func _perform(action: String, argument: String = "") -> void:
	var error := ""
	match action:
		"issue": error = campaign.issue(argument)
		"cancel": error = campaign.cancel()
		"play_commander": error = campaign.play_commander()
		"delegate": error = campaign.delegate()
		"return_to_darbar": error = campaign.return_to_darbar()
		"resolve": error = campaign.resolve(argument)
		"save":
			campaign.record_position(avatar.global_position)
			error = campaign.save_to(SAVE_PATH)
		"load":
			error = campaign.load_from(SAVE_PATH)
			if error.is_empty():
				_apply_actor(true)
				_clock_accumulator = 0.0
		"menu":
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
			return
	_notice = _message(error, "Saved." if action == "save" else "Loaded." if action == "load" else "Command updated.")
	_close_panel()
	_apply_actor()
	_refresh_hud()

func _message(error: String, success: String) -> String:
	return success if error.is_empty() else error

func _apply_actor(force: bool = false) -> void:
	var id: String = campaign.actor_id()
	if id != _shown_actor or force:
		avatar.global_position = campaign.actor_position(id)
		avatar.velocity = Vector3.ZERO
		_shown_actor = id
	for key in _standins:
		_standins[key].visible = key != id
		_standins[key].position = campaign.actor_position(key)

func _active_player_name() -> String:
	var id: String = campaign.actor_id()
	return Names.player_name(id, campaign.snapshot().actors[id].name)

func _public_protagonist_name(formal: bool = false) -> String:
	return Names.address(NAME_PHASE, formal)

func _refresh_hud() -> void:
	var s: Dictionary = campaign.snapshot()
	var resources: Dictionary = s.resources
	var mission := "Assign a patrol at the courtyard table."
	if s.order.status == "assigned":
		mission = "Press E at the table: play, delegate, or cancel."
	elif s.order.status == "active":
		mission = "Village → outpost → decision. E interacts near markers."
	elif s.order.status == "reporting":
		mission = "A messenger is travelling. Lahore does not yet know the outcome."
	elif s.order.status == "completed":
		mission = "Story complete. The result persists; replay cannot duplicate its rewards."
	_hud.text = "1792 · LAHORE COMMAND SANDBOX (fictional, 1801)\n%s  |  Order: %s / %s  |  Minute: %d\nAvailable: %d riders · %d supplies · %d coins\n%s\n\n%s\nWASD / Shift / Mouse · E interact · F5 save · F9 load · F1 menu" % [
		_active_player_name(), s.order.status, s.order.mode,
		int(s.campaign_tick), int(resources.riders), int(resources.supplies), int(resources.treasury), mission, _notice]
	var reports: Array = campaign.received_reports()
	_journal.text = "LAHORE · RECEIVED REPORTS\n\nNo new report received."
	if not reports.is_empty():
		var report: Dictionary = reports.back()
		var security := "Unknown (outpost not observed)"
		if report.road_security != null:
			security = "%.0f%%" % (report.road_security * 100)
		_journal.text = "LAHORE · RECEIVED REPORT\n\n%s\nSource: patrol captain\nObserved: minute %d\nArrived: minute %d\nReported road security: %s\n\nThis is local security, not territorial ownership." % [
			report.outcome, int(report.observed_at), int(report.arrives_at), security]

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(18, 16)
	_hud.size = Vector2(880, 270)
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_hud)
	_journal = Label.new()
	_journal.position = Vector2(930, 20)
	_journal.size = Vector2(330, 260)
	_journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal.add_theme_color_override("font_shadow_color", Color.BLACK)
	_journal.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_journal)
	_modal = PanelContainer.new()
	_modal.position = Vector2(285, 190)
	_modal.custom_minimum_size = Vector2(710, 0)
	layer.add_child(_modal)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 12)
	_modal.add_child(_choices)
	_modal.hide()

func _open_panel(title: String, description: String, actions: Array) -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 26)
	_choices.add_child(heading)
	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 680
	_choices.add_child(body)
	for action in actions:
		var button := Button.new()
		button.text = action[0]
		button.custom_minimum_size.y = 40
		button.pressed.connect(_perform.bind(action[1], action[2]))
		_choices.add_child(button)
	_modal.show()
	avatar.set("input_enabled", false)
	avatar.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_panel() -> void:
	_modal.hide()
	avatar.set("input_enabled", true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("819393")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("ebdebe")
	environment.environment.ambient_light_energy = 0.7
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.shadow_enabled = true
	add_child(sun)
	_box(Vector3(130, 1, 130), Vector3(0, -0.5, -25), Color("6b7849"), true)
	# Nonhistorical, compressed blockout: command courtyard, village, outpost.
	_box(Vector3(26, 0.12, 24), Vector3(0, 0.02, 0), Color("b79a6b"))
	_box(Vector3(26, 3, 1), Vector3(0, 1.5, 12), Color("ac8560"), true)
	_box(Vector3(1, 3, 24), Vector3(-13, 1.5, 0), Color("ac8560"), true)
	_box(Vector3(1, 3, 24), Vector3(13, 1.5, 0), Color("ac8560"), true)
	_box(Vector3(3, 1.2, 1.5), Vector3(0, 0.6, 0), Color("624b39"), true)
	_road(Vector3(0, 0.1, -10), Vector3(-12, 0.1, -28))
	_road(Vector3(-12, 0.1, -28), Vector3(20, 0.1, -58))
	for offset in [Vector3(-8, 0, 0), Vector3(8, 0, 4), Vector3(-7, 0, -9)]:
		_box(Vector3(6, 4, 5), Vector3(-12, 2, -28) + offset, Color("bb996c"), true)
	_box(Vector3(14, 3, 1), Vector3(20, 1.5, -64), Color("937655"), true)
	_box(Vector3(2, 6, 2), Vector3(27, 3, -58), Color("937655"), true)
	for site in campaign.snapshot().places:
		var p: Array = site.position
		_label(site.name + "\n[E]", Vector3(p[0], 3.2, p[2]))
		_box(Vector3(1, 0.1, 1), Vector3(p[0], 0.12, p[2]), Color("e2ba68"))
	for id in campaign.snapshot().actors:
		var standin := Node3D.new()
		add_child(standin)
		var mesh := MeshInstance3D.new()
		mesh.mesh = CapsuleMesh.new()
		mesh.position.y = 0.9
		standin.add_child(mesh)
		_standins[id] = standin
	# Guardrails keep the prototype finite; they are not historical borders.
	for x in [-64, 64]:
		_box(Vector3(1, 8, 130), Vector3(x, 4, -25), Color("526144"), true)
	for z in [-89, 39]:
		_box(Vector3(130, 8, 1), Vector3(0, 4, z), Color("526144"), true)

func _box(size: Vector3, at: Vector3, color: Color, collision: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	visual.material_override = material
	root.add_child(visual)
	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		root.add_child(shape)
	add_child(root)
	return root

func _road(start: Vector3, end: Vector3) -> void:
	var center := (start + end) * 0.5
	var road := _box(Vector3(4, 0.04, start.distance_to(end)), center, Color("a28d67"))
	road.look_at(end, Vector3.UP)

func _label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	add_child(label)
