extends SceneTree
## Presentation/identity regression. Scene placements below are explicit UI fixtures, not route tests.
const Names := preload("res://characters/character_names.gd")
const Legacy := preload("res://campaign/command_state.gd")
const Houses := preload("res://campaign/house_command_state.gd")
const SAVE := "user://character-names-regression-only.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func labels(node: Node) -> String:
	var text := str(node.text) + "\n" if node is Label or node is Button else ""
	for child in node.get_children(): text += labels(child)
	return text

func _run() -> void:
	check(Names.HERO_ID == Legacy.RANJIT, "presentation preserves the original actor key")
	check(Names.player_name(Names.HERO_ID) == "Buddh Singh", "player's name is Buddh Singh")
	check(Names.player_name("patrol_captain", "Patrol captain (fictional)") == "Patrol captain (fictional)", "captain not renamed")
	check(Names.player_name("raj_kaur", "Raj Kaur") == "Raj Kaur", "antagonist not renamed")
	check(Names.address(Names.BEFORE_ACCESSION) == "Buddh Singh", "early public address")
	check(Names.address(Names.BEFORE_ACCESSION, true) == "Buddh Singh", "no early Maharaja title")
	check(Names.address(Names.AFTER_ACCESSION) == "Ranjit Singh", "later public address")
	check(Names.address(Names.AFTER_ACCESSION, true) == "Maharaja Ranjit Singh", "later formal address")
	check(Names.address("1801") == "", "calendar strings cannot imply accession")
	check(Names.address("") == "", "missing chapter does not imply accession")
	check(Names.address("unsupported", true) == "", "unknown chapter never grants title")
	for model in [Legacy.new(), Houses.new()]:
		var before: Dictionary = model.snapshot()
		var at: Vector3 = model.actor_position(Names.HERO_ID)
		check(before.actors[Names.HERO_ID].name == "Ranjit Singh", "legacy stored label remains readable")
		for _i in range(10):
			Names.player_name(model.actor_id(), before.actors[model.actor_id()].name)
			Names.address(Names.AFTER_ACCESSION)
		check(model.snapshot() == before, "repeated presentation is read-only")
		check(model.save_to(SAVE).is_empty(), "save with original schema")
		var restored = Legacy.new() if model.get_script() == Legacy else Houses.new()
		check(restored.load_from(SAVE).is_empty(), "read old-format snapshot without name migration")
		check(restored.actor_id() == Names.HERO_ID, "same actor after load")
		check(restored.snapshot().order.issuer_id == Names.HERO_ID, "same order issuer after load")
		check(restored.actor_position(Names.HERO_ID).is_equal_approx(at), "position retained")
		check(Names.player_name(restored.actor_id()) == "Buddh Singh", "old stored name cannot override display policy")
		check(not restored.snapshot().actors.has("buddh_singh"), "no duplicate hero identity")
	# Repeated scene creation/deletion checks nameplate lifecycle, inspired by engine-regression practice.
	for _i in range(3):
		var home = load("res://world/home_territory.tscn").instantiate()
		root.add_child(home)
		await frames()
		check(labels(home).contains("Buddh Singh"), "home nameplate is visible")
		check(not labels(home).contains("Ranjit"), "home has no future public name")
		check(home.get_node_or_null("Player/HomeIdentity/HomeIdentityPanel") != null, "home has one owned nameplate")
		home.queue_free()
		await frames(1)
	for resource in ["res://world/command_sandbox.tscn", "res://world/house_sandbox.tscn"]:
		var scene = load(resource).instantiate()
		root.add_child(scene)
		await frames()
		check(scene._hud.text.contains("Buddh Singh"), "Lahore player HUD keeps Buddh Singh")
		check(scene._public_protagonist_name(true) == "Maharaja Ranjit Singh", "Lahore explicitly declares later address")
		check(scene.avatar.get_node_or_null("HomeIdentity") == null, "no overlapping home nameplate in Lahore")
		if scene.has_method("_open_estate"):
			var before: Dictionary = scene.campaign.snapshot()
			scene._open_estate()
			check(labels(scene._choices).contains("Envoy: \"Maharaja Ranjit Singh"), "NPC addresses post-accession protagonist")
			check(scene.campaign.snapshot() == before, "reading public address cannot mutate campaign")
			scene._close_panel()
		# UI fixture at the table; all movement behavior remains in inherited physics tests.
		scene.avatar.position = Vector3(0, 0.04, 3)
		scene.campaign.record_position(scene.avatar.position)
		scene._perform("issue", "patrol")
		scene._perform("play_commander")
		check(scene.campaign.actor_id() == "patrol_captain", "character handover unchanged")
		check(not scene._hud.text.contains("Buddh Singh"), "captain HUD is not the protagonist's name")
		check(scene._active_player_name() == "Patrol captain (fictional)", "captain keeps own display")
		scene._perform("return_to_darbar")
		check(scene._hud.text.contains("Buddh Singh"), "return restores personal display without a new actor")
		check(scene.campaign.snapshot().order.issuer_id == Names.HERO_ID, "handover retains issuer identity")
		scene.queue_free()
		await frames(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("CHARACTER_NAMES_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
