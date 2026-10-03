# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared lesson/threat fixtures qualify production HUD visibility, with real
## walking input for progressive disclosure. They do not claim a full playthrough.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Riding := preload("res://mounts/riding_rules.gd")
var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; push_error("ATTENTION GUIDANCE: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func capture(label: String) -> void:
	if OS.get_environment("ATTENTION_CAPTURE") != "1": return
	await RenderingServer.frame_post_draw
	var pixels:=root.get_texture().get_image()
	check(pixels!=null and pixels.save_png("user://attention-"+label+".png")==OK,"native attention capture: "+label)

func lesson_fixture() -> Dictionary:
	var model := Base.new()
	check(Pose.pose(model,Base.SITES.letter).is_empty(),"declared courier contact")
	check(model.inspect_letter().is_empty() and model.hear("courier").is_empty(),"declared message and received courier account")
	check(Pose.pose(model,Base.SITES.steward).is_empty() and model.hear("steward").is_empty(),"declared steward account")
	var value := model.snapshot()
	value.childhood.walked=6.0;value.childhood.looked=1.0
	value.player.position=Base.coords(Vector3(0,.14,0));value.actors[Base.Names.HERO_ID].position=value.player.position.duplicate()
	check(model.restore(value).is_empty(),"declared riding lesson fixture validates")
	return model.snapshot()

func essential_controls(hud: Node, mounted: bool) -> void:
	check(hud.task.is_visible_in_tree() and not hud.task.text.is_empty() and not hud.task.text.contains("\n"),"one primary task stays visible")
	check(hud.controls.is_visible_in_tree() and hud.control_strip.is_visible_in_tree(),"controls have an independent visible strip")
	check(hud.controls.text.contains("Brake") and hud.controls.text.contains("Dismount") if mounted else hud.controls.text.contains("WASD"),"current locomotion remains discoverable")

func run() -> void:
	root.content_scale_size=Vector2i.ZERO # Exercise responsive layout, not scaled 720p pixels.
	root.size=Vector2i(1280,720)
	home=Launch.make_world();chapter=home.get_node("ChildhoodChapter")
	check(chapter.model.restore(lesson_fixture()).is_empty(),"install explicit lesson fixture")
	root.add_child(home);await frames(6)
	var hud: Node=chapter.art.detail.hud
	check(hud.narrator.is_visible_in_tree() and hud.narrator.text.contains("Optional: speak to the steward"),"rest reveals the optional message path without replacing the riding task")
	check(hud.task.text=="Mount the household horse", "optional detail leaves the main lesson first")
	await capture("rest")
	var before: Dictionary=chapter.model.snapshot()
	for _i in range(4): hud.sample()
	check(chapter.model.snapshot()==before,"attention sampling does not grant progress, knowledge, or alter saves")
	Input.action_press("move_forward");await frames(20)
	check(Vector2(chapter.avatar.velocity.x,chapter.avatar.velocity.z).length()>.3,"ordinary input moves the actual character")
	check(not hud.narrator.is_visible_in_tree() and not hud.title.is_visible_in_tree(),"walking removes secondary exposition and repeated location heading")
	essential_controls(hud,false)
	await capture("moving")
	Input.action_release("move_forward");await frames(20)
	check(hud.narrator.is_visible_in_tree() and hud.narrator.text.contains("Optional:"),"stopping restores the optional path instead of permanently dismissing it")
	# Mount through the existing reducer at an explicitly declared safe contact.
	check(Pose.pose(chapter.model,Riding.position(chapter.model.horse_record())+Vector3.RIGHT).is_empty(),"declared horse contact")
	check(chapter.model.mount().is_empty(),"existing reducer admits mounted fixture")
	chapter._apply();chapter._refresh();await frames(3)
	check(not hud.narrator.is_visible_in_tree() and hud.task.text=="Ride through gate 1 of 3", "mounted presentation keeps numbered progress in the primary task")
	essential_controls(hud,true)
	await capture("mounted")
	check(chapter.model.restore(Pose.precursor()).is_empty(),"declared quiet tracking fixture")
	chapter._apply();chapter._message="";chapter._refresh();await frames(3)
	check(chapter.model.stage()=="tracking" and not hud.bottom.is_visible_in_tree(),"quiet tracking removes the caption panel entirely")
	check(hud.controls.is_visible_in_tree() and hud.controls.text.contains("E  Examine") and hud.task.is_visible_in_tree(),"quiet interval retains current interaction and primary task")
	await capture("quiet-tracking")
	# Explicit threat fixture; no invented completed journey.
	var model:=Base.new();check(model.restore(Pose.precursor()).is_empty(),"declared completed training fixture")
	check(model.observe_quarry(true).is_empty() and Pose.pose(model,Base.SITES.bend).is_empty() and model.start_ambush().is_empty(),"declared threat starts through existing rules")
	check(chapter.model.restore(model.snapshot()).is_empty(),"install threat presentation fixture")
	chapter._apply();chapter._refresh()
	chapter._message="A blade comes up. Face him or run!";chapter._refresh();await frames(3)
	check(hud.task.text=="Reach the courtyard alive" and not hud.narrator.is_visible_in_tree(),"active threat gives survival precedence over optional plot exposition")
	check(hud.controls.text.contains("Q  Guard") and hud.controls.text.contains("Left click  Counter") and hud.controls.text.contains("Shift  Run"),"survival controls stay visible throughout threat")
	check(hud.bottom.is_visible_in_tree() and hud.words.text.contains("Face him or run"),"urgent directed caption remains visible during active threat")
	essential_controls(hud,false)
	await capture("threat")
	var prior_process:=home.process_mode;home.process_mode=Node.PROCESS_MODE_DISABLED
	for size in [Vector2i(800,450),Vector2i(1280,720)]:
		root.size=size;hud.sample();await frames(3);hud.sample();await process_frame
		var screen:=root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.control_strip.get_global_rect()),"task and controls fit %dx%d"%[size.x,size.y])
		check(not hud.top.get_global_rect().intersects(hud.control_strip.get_global_rect()),"survival objective and controls remain separate")
		if hud.bottom.visible:
			check(screen.encloses(hud.bottom.get_global_rect()) and not hud.bottom.get_global_rect().intersects(hud.control_strip.get_global_rect()),"urgent speech has its own fitting region")
		if size.x==800: await capture("threat-small")
	hud.compact=false;hud.sample()
	check(not hud.visible and chapter._hud.is_visible_in_tree(),"original HUD remains reversible")
	hud.compact=true;hud.sample()
	check(hud.visible and not chapter._hud.is_visible_in_tree(),"compact hierarchy returns without duplicate legacy narration")
	home.process_mode=prior_process
	chapter._open_journal();await frames(2)
	check(not hud.visible and chapter._panel.is_visible_in_tree(),"journal modal suppresses all three compact panels")
	home.queue_free();await frames(3)
	print("ATTENTION_GUIDANCE_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
