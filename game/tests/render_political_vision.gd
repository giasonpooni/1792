extends SceneTree
## Software-rendered fixture captures, not a human-played campaign or GPU benchmark.
const World := preload("res://world/political_home.tscn")
const Fixture := preload("res://tests/aftermath_fixture.gd")
var captures := 0
var failures := 0
var output := "user://"

func _initialize() -> void:
	call_deferred("_run")

func capture(chapter, label: String) -> void:
	chapter._refresh()
	chapter._hud.text = "RENDER FIXTURE · "+label+"\n"+chapter._hud.text
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image == null or image.is_empty() or image.save_png(output.path_join("political-"+label+".png")) != OK:
		failures += 1
		printerr("FAIL: render capture "+label)

func _run() -> void:
	root.size = Vector2i(1280,720)
	var provided:=OS.get_environment("POLITICAL_VISION_OUTPUT")
	if not provided.is_empty(): output=provided
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var world: Node3D = World.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var chapter = world.get_node("ChildhoodChapter")
	chapter.set_physics_process(false)
	chapter.avatar.set_physics_process(false)
	chapter.avatar.input_enabled = false
	await capture(chapter,"initial")
	for i in range(9000): chapter.campaign.advance()
	await capture(chapter,"narrowing")
	for i in range(9000): chapter.campaign.advance()
	await capture(chapter,"monocular")
	# A declared presentation fixture: the production optional chapter and its
	# existing clock/sensor render Focus together. This is not an earned route.
	chapter.ground_focus.clear();chapter.ground_focus._targets.clear()
	var focus_at: Vector3=chapter._eye_origin()-chapter.avatar.pivot.global_basis.z*3.0
	var focus_target: Node3D=chapter._box(Vector3(.22,.22,.22),focus_at,Color("d6c78f"))
	chapter.ground_focus.register_target("vision_render_fixture",focus_target,"Observed fixture")
	chapter.ground_focus.start()
	for i in range(50):
		chapter.campaign.advance();chapter.ground_focus.sample(int(chapter.campaign.progress().tick))
	await capture(chapter,"focus-monocular")
	chapter.ground_focus.clear()
	chapter._subjective = false
	chapter._veil.visible = false
	await capture(chapter,"clear-presentation")
	chapter._subjective = true
	chapter._veil.visible = true
	if not chapter.campaign.restore(Fixture.survived()).is_empty(): failures += 1
	if not Fixture.pose(chapter.campaign,chapter.Story.MOTHER+Vector3.FORWARD*2.0).is_empty(): failures += 1
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	chapter.avatar.pivot.rotation = Vector3(0,PI,0)
	chapter._sample_observers()
	await capture(chapter,"watchful-glance")
	chapter._open_journal()
	await capture(chapter,"readable-journal")
	world.queue_free()
	await process_frame
	print("POLITICAL_RENDER: %d captures; %d failures" % [captures,failures])
	quit(0 if failures == 0 else 1)
