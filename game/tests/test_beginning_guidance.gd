# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Fresh player route: all progress comes from walking, looking and real E input.
## UI checks compare authority while paused; no fixture or saved pose is restored.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Guidance := preload("res://presentation/beginning_guidance.gd")
const Menu := preload("res://ui/main_menu.tscn")
var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> bool:
	if value: passed += 1
	else: failed += 1; push_error("BEGINNING GUIDANCE: " + label)
	return value

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func release_controls() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.pressed = true
	root.push_input(event, true)

func mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	root.push_input(event, true)

func face(target: Vector3) -> void:
	var offset: Vector3 = target - chapter.avatar.global_position
	var yaw := atan2(-offset.x, -offset.z)
	var turn := wrapf(yaw - chapter.avatar.pivot.rotation.y, -PI, PI)
	mouse(Vector2(-turn / chapter.avatar.mouse_sensitivity, 0))
	await process_frame
	check(absf(wrapf(chapter.avatar.pivot.rotation.y - yaw, -PI, PI)) < .01, "ordinary mouse input faces the next walk or interaction target")

func walk(target: Vector3, radius: float = .45) -> bool:
	release_controls(); await face(target)
	var best := Base.distance(chapter.avatar.global_position, target)
	var stalled := 0
	for _i in range(600):
		var distance := Base.distance(chapter.avatar.global_position, target)
		if distance <= radius:
			release_controls(); await frames(16)
			return check(Base.distance(chapter.avatar.global_position, target) < radius + 1.0, "native player motor reaches the route target")
		if distance < best - .03: best = distance; stalled = 0
		else: stalled += 1
		if stalled >= 100: break
		Input.action_press("move_forward"); await frames(1)
	release_controls()
	return check(false, "ordinary walking stalled at %s toward %s" % [chapter.avatar.global_position, target])

func physics_identity() -> Array:
	var result: Array = []
	for node in home.find_children("*", "CollisionShape3D", true, false):
		result.append([node.get_instance_id(), node.global_transform, node.shape.get_rid(), node.disabled, node.get_parent().collision_layer, node.get_parent().collision_mask])
	return result

func check_ui(task_fragment: String, marker_fragment: String = "") -> void:
	var hud: Node = chapter.art.detail.hud
	var before: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var bodies := physics_identity()
	for _i in range(4): Guidance.read(chapter); hud.sample()
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "guidance reads and HUD sampling have no canonical, journal or physics authority")
	check(hud.visible and hud.task.text.contains(task_fragment) and not hud.task.text.contains("\n"), "compact beginning shows one current objective: " + task_fragment)
	check(not chapter._hud.is_visible_in_tree() and not chapter._caption.is_visible_in_tree() and not chapter._narrator_label.is_visible_in_tree(), "single compact task and dialogue replace the three legacy text blocks")
	check(hud.words.text == chapter._message and hud.controls.text.contains("WASD") and hud.controls.text.contains("Mouse"), "actual remembered words and current movement controls remain available")
	if marker_fragment.is_empty():
		check(not chapter._marker.visible, "orientation has no premature target marker")
	else:
		check(chapter._marker.is_visible_in_tree() and chapter._marker.text.contains(marker_fragment), "named current marker survives its initially hidden orientation state: " + marker_fragment)

func modal_and_layout() -> void:
	var hud: Node = chapter.art.detail.hud
	key(KEY_J); await frames(3)
	check(chapter._paused and chapter._panel.is_visible_in_tree() and not hud.visible, "real journal input immediately suppresses compact beginning guidance")
	var before: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var bodies := physics_identity()
	await frames(8)
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "actual journal keeps whole Home authority frozen")
	key(KEY_ESCAPE); await frames(3)
	check(not chapter._paused and hud.visible and not chapter._hud.is_visible_in_tree(), "Escape resumes the single compact beginning objective")
	key(KEY_F7); await frames(3)
	check(chapter._paused and chapter._art_open and not hud.visible, "real F7 opens the paused art control without compact gameplay text")
	before = chapter.model.snapshot(); journal = chapter.model.journal(); bodies = physics_identity()
	for _i in range(2):
		chapter._menu_action("art:hud")
		check(not hud.visible and not chapter._hud.is_visible_in_tree(), "compact/original switch does not leak gameplay text over the art modal")
	await frames(8)
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "art modal and layout selection keep whole Home authority frozen")
	key(KEY_F7); await frames(3)
	check(not chapter._paused and hud.visible and not chapter._hud.is_visible_in_tree(), "real F7 returns to the single compact beginning objective")
	# Freeze only execution for layout/reference checks; do not forge story progress.
	var old_process := home.process_mode
	home.process_mode = Node.PROCESS_MODE_DISABLED
	before = chapter.model.snapshot(); journal = chapter.model.journal(); bodies = physics_identity()
	for size in [Vector2i(800, 600), Vector2i(1280, 720)]:
		root.size = size; hud.sample(); await frames(3); hud.sample(); await process_frame
		var screen := root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.bottom.get_global_rect()), "beginning text fits the %dx%d viewport" % [size.x, size.y])
		check(not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()), "beginning task and spoken words do not overlap after resize")
	hud.compact = false; hud.sample()
	check(not hud.visible and chapter._hud.is_visible_in_tree() and chapter._caption.is_visible_in_tree(), "classic mode restores retained task and speech labels")
	check(chapter._marker.is_visible_in_tree(), "classic mode retains the current lesson's dynamic marker")
	hud.compact = true; chapter._refresh()
	check(hud.visible and not chapter._hud.is_visible_in_tree() and chapter._marker.is_visible_in_tree(), "return to compact mode restores one objective and its current marker")
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "resize and HUD switches preserve authority and physical identities")
	home.process_mode = old_process

func main_menu_contract() -> void:
	var menu: Control = Menu.instantiate()
	root.add_child(menu); current_scene = menu; await frames(3)
	var begin: Button = menu.find_child("BeginChildhood", true, false)
	check(is_instance_valid(begin) and root.gui_get_focus_owner() == begin and begin.is_visible_in_tree(), "main menu focuses its visible childhood Begin action")
	var panel := begin.get_parent()
	var group_index := -1
	for node in panel.get_children():
		if node is Label and node.text == "DEVELOPMENT STUDIES": group_index = node.get_index()
	check(group_index > begin.get_index(), "development studies are visibly grouped after the primary beginning")
	var studies := 0
	for node in panel.get_children():
		if node is Button and node != begin:
			studies += 1
			check(node.get_index() > group_index, "retained study entry follows the development group")
	check(studies == 5, "all five existing development study entries remain available")
	begin.pressed.emit(); await frames(3)
	home = current_scene; chapter = home.get_node("ChildhoodChapter")
	check(home != menu and is_instance_valid(chapter.intro_session) and chapter.model.stage() == "orientation", "real Begin action opens the production family introduction before original Home play")
	check(chapter.model.progress().walked == 0.0 and chapter.model.progress().looked == 0.0 and chapter.model.journal().is_empty(), "menu entry invents no childhood progress or memories")
	current_scene = null; home.queue_free(); home = null; chapter = null; await frames(4)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("BEGINNING GUIDANCE requires a real display backend for native mouse capture; run with Xvfb/gl_compatibility.")
		quit(2); return
	root.content_scale_size = Vector2i.ZERO; root.size = Vector2i(1280, 720)
	root.disable_3d = true # This route qualifies native input/physics and UI, not pixels.
	release_controls(); await main_menu_contract()
	home = Launch.make_world(); root.add_child(home); chapter = home.get_node("ChildhoodChapter"); await frames(8)
	check(chapter.model.stage() == "orientation" and not chapter.model.progress().letter_seen and chapter.model.journal().is_empty(), "construction begins with a genuinely fresh orientation authority")
	check_ui("Explore")
	mouse(Vector2(160, 0)); mouse(Vector2(-160, 0))
	if not await walk(Vector3(-4.8, .14, 1.0)): await finish(); return
	if not await walk(Vector3(-5.2, .14, 2.0)): await finish(); return
	check(chapter.model.stage() == "letter" and chapter.model.progress().walked >= 5.0 and chapter.model.progress().looked >= .6, "ordinary walking and looking earn the first lesson transition")
	check_ui("sealed message", "Courier")
	await modal_and_layout()
	await face(Base.SITES.courier); key(KEY_E); await frames(3)
	check(chapter.model.progress().letter_seen and chapter.model.progress().heard.is_empty() and chapter.model.journal().size() == 1, "first real E collects only the sealed message")
	check_ui("courier's account", "Courier")
	key(KEY_E); await frames(3)
	check(chapter.model.progress().heard == ["courier"], "second real E hears only the courier's account")
	check_ui("steward", "Steward")
	if not await walk(Vector3(-10.6, .14, 4.0)): await finish(); return
	await face(Base.SITES.steward); key(KEY_E); await frames(3)
	check(chapter.model.stage() == "riding" and chapter.model.progress().heard == ["courier", "steward"], "actual steward interaction opens riding through the original reducer")
	check_ui("household horse", "Household horse")
	check(chapter.model.journal().map(func(memory): return memory.id) == ["letter", "courier", "steward"] and chapter.model.capabilities() == {"single_standing": false, "paired_standing": false, "mounted_matchlock": false}, "guidance exposes only actually earned memories and grants no advanced skill")
	await modal_and_layout()
	# Removing only this UI component restores field captions without touching art.
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var before: Dictionary = chapter.model.snapshot()
	var bodies := physics_identity()
	var hud: Node = chapter.art.detail.hud
	var captions: Array = hud._labels.duplicate()
	hud.get_parent().remove_child(hud); hud.queue_free(); await frames(3)
	check(chapter._hud.is_visible_in_tree() and chapter._caption.is_visible_in_tree(), "HUD component removal restores retained UI references")
	check(captions.all(func(record): return not is_instance_valid(record.node) or record.node.visible == record.visible), "HUD removal restores original static field-caption visibility")
	check(chapter._marker.is_visible_in_tree() and chapter.model.snapshot() == before and physics_identity() == bodies, "HUD removal preserves the current dynamic marker and whole Home authority")
	await finish()

func finish() -> void:
	release_controls(); current_scene = null
	if is_instance_valid(home): home.queue_free()
	home = null; chapter = null; await frames(4)
	print("BEGINNING_GUIDANCE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
