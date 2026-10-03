extends SceneTree
## Explicit presentation fixtures, not evidence of another played journey.
const Launch := preload("res://childhood/home_launch.gd")
const Story := preload("res://childhood/aftermath_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const SAVE := "user://aftermath-render-only.json"
var captures := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func frames(count: int = 4) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://aftermath-"+label+".png") != OK: failures += 1
func check(error: String) -> void:
	if not error.is_empty():
		failures += 1
		push_error(error)
func _run() -> void:
	root.size = Vector2i(1280,720)
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	check(scene.model.restore(Fixture.survived()))
	root.add_child(home)
	await frames()
	for speaker in ["steward","courier"]:
		check(Fixture.pose(scene.model,Base.SITES[speaker]+Vector3.RIGHT*1.5))
		check(scene.model.hear_return(speaker))
	check(Fixture.pose(scene.model,Story.MOTHER+Vector3(0,0,-2)))
	scene._apply()
	scene.avatar.pivot.rotation = Vector3(-0.22,PI,0)
	check(scene.model.hear_offer())
	scene._protection_dialog()
	await capture("protection-offer")
	root.size = Vector2i(800,600)
	await frames()
	await capture("small-window")
	root.size = Vector2i(1280,720)
	await frames()
	scene._run_after_action("household_escort")
	scene.avatar.pivot.rotation = Vector3(-0.22,PI,0)
	await frames(100)
	await capture("escort-courtyard")
	# Direct pose fixtures for the returned-account presentation; physics journey is a separate test.
	var s: Dictionary = scene.model.snapshot()
	s.player.position = Base.coords(Story.CLUE+Vector3(0,0,1.8))
	s.actors[Base.Names.HERO_ID].position = s.player.position.duplicate()
	s.aftermath.escort.position = Base.coords(Story.CLUE+Vector3(1.5,0,2.0))
	check(scene.model.restore(s))
	check(scene.model.inspect_bend())
	s = scene.model.snapshot()
	s.player.position = Base.coords(Story.MOTHER+Vector3(0,0,-2))
	s.actors[Base.Names.HERO_ID].position = s.player.position.duplicate()
	s.aftermath.escort.position = Base.coords(Story.MOTHER+Vector3(2,0,-2))
	check(scene.model.restore(s))
	scene._apply()
	scene.avatar.pivot.rotation = Vector3(-0.22,PI,0)
	scene._interact_aftermath()
	await capture("report-preview")
	scene._resume()
	check(scene.model.report_home())
	scene._apply()
	scene._open_journal()
	await capture("oral-report")
	scene._show_dialog("ATTEMPT ENDED","This is the recovery panel. The checkpoint restores the whole earlier chapter: position, lesson progress, damage and known accounts.\n\nCheckpoint saved: before the return-path ambush.",
		[["Restore checkpoint [R]","retry"],["Load manual save","load"],["Journal","journal"],["Main menu","menu"]])
	await capture("checkpoint-recovery")
	home.queue_free()
	await process_frame
	print("AFTERMATH_RENDER: %d captures; %d failures" % [captures,failures])
	quit(1 if failures or captures != 6 else 0)
