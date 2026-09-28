extends SceneTree
## Render-only fixtures. Full input-driven travel is tested separately in test_childhood.gd.
const Launch := preload("res://childhood/home_launch.gd")
const Model := preload("res://childhood/childhood_state.gd")
const Names := preload("res://characters/character_names.gd")
var captures := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()
func frames(count: int = 4) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	captures += 1
	if image.is_empty() or image.save_png("user://childhood-"+name+".png") != OK: failures += 1
func pose(scene, p: Vector3) -> void:
	var s: Dictionary = scene.model.snapshot()
	s.player.position = Model.coords(p)
	s.actors[Names.HERO_ID].position = Model.coords(p)
	var error: String = scene.model.restore(s)
	if not error.is_empty():
		failures += 1
		push_error(error)
	scene._apply()
func _run() -> void:
	root.size = Vector2i(1280,720)
	var home := Launch.make_world()
	root.add_child(home)
	var scene = home.get_node("ChildhoodChapter")
	await frames()
	scene.avatar.pivot.rotation = Vector3(-0.25,0,0)
	await capture("home")
	pose(scene, Model.SITES.letter + Vector3.RIGHT*1.5)
	scene.model.inspect_letter()
	scene._open_journal()
	await capture("unread-message")
	scene._resume()
	scene.model.hear("courier")
	pose(scene, Model.SITES.steward + Vector3.RIGHT*1.5)
	scene.model.hear("steward")
	scene._open_journal()
	await capture("voices")
	# A valid explicitly reconstructed precursor for a static encounter capture only.
	scene._resume()
	var s: Dictionary = scene.model.snapshot()
	s.childhood.walked = 6.0
	s.childhood.looked = 1.0
	s.childhood.ride_gate = 3
	s.childhood.parries = 2
	s.childhood.counters = 1
	s.player.position = Model.coords(Model.SITES.track_1)
	s.actors[Names.HERO_ID].position = s.player.position.duplicate()
	if not scene.model.restore(s).is_empty(): failures += 1
	for i in range(1,4):
		pose(scene,Model.SITES["track_%d"%i])
		if not scene.model.inspect_track("track_%d"%i).is_empty(): failures += 1
	pose(scene, Model.SITES.quarry)
	if not scene.model.observe_quarry(true).is_empty(): failures += 1
	pose(scene, Model.SITES.bend)
	await frames(45)
	scene.avatar.pivot.rotation = Vector3(-0.2,-PI/2,0)
	await frames(10)
	await capture("ambush")
	home.queue_free()
	await process_frame
	print("CHILDHOOD_RENDER: %d captures; %d failures"%[captures,failures])
	quit(1 if failures or captures != 4 else 0)
