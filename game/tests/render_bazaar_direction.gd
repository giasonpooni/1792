# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Render retained input-journey observations. No synthetic progress or future game outcome.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Dialogue := preload("res://youth/performance/bazaar_script.gd")
var scene: Node3D
var home: Node3D
var count := 0
var failed := 0
var output := "user://bazaar-direction-images"
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	if not ok: failed+=1;push_error("DIRECTION RENDER: "+text)
func frames(n: int=4) -> void:
	for _i in range(n): await process_frame
func apply(item: Dictionary) -> void:
	check(scene.model.restore(item.state).is_empty(),"retained gameplay state restores")
	scene._apply();scene.avatar.pivot.rotation=Base.point(item.camera_pivot);scene.avatar.velocity=Base.point(item.velocity)
	scene._message=item.message;scene._paused=false
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	var director: Node=scene.bazaar_performance
	director.sound_enabled=false;director.speech=item.speech.duplicate(true);director._guard=item.guard;director.report_until=int(item.report_until)
	scene._refresh();director._guard=item.guard;director.sample(false)
func capture(name: String,check_ui: bool=true) -> void:
	await frames(1)
	scene.bazaar_performance.sample(false);await RenderingServer.frame_post_draw
	var d: Node=scene.bazaar_performance
	var screen:=root.get_visible_rect()
	if check_ui and d.canvas.visible:
		check(screen.encloses(d.top.get_global_rect()),"objective panel inside viewport")
		if d.bottom.visible: check(screen.encloses(d.bottom.get_global_rect()),"subtitle panel inside viewport")
	var image:=root.get_texture().get_image();check(not image.is_empty(),"rendered image available")
	check(image.save_png(output.path_join(name+".png"))==OK,"write PNG")
	count+=1
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var input: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bazaar-direction.json"))
	if not input is Dictionary or input.get("failed")!=0: push_error("Run the successful direction gameplay test first.");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	home=Launch.make_world();root.add_child(home);scene=home.get_node("ChildhoodChapter")
	scene.set_physics_process(false);scene.avatar.set_physics_process(false);await frames(8)
	for name in ["friends-walking","windup","checked","down","ending-fight","ending-leave"]:
		apply(input.snapshots[name]);await capture(name)
	# Optional dialogue uses its actual captured pre-decision state and the actual shipped panel.
	apply(input.snapshots["friends-dialogue"])
	scene._show_dialog("BETWEEN FRIENDS",Dialogue.FRIENDS,[["Stand with my friends","youth:stand"],["Walk away together","youth:leave"],["Back to the challenger","youth:answer"]])
	await capture("friends-dialogue")
	root.size=Vector2i(800,450);await frames(10)
	apply(input.snapshots["checked"]);await capture("compact")
	root.size=Vector2i(800,450);await frames(3)
	for i in range(input.motion.size()):
		apply(input.motion[i]);await capture("motion-%03d"%i)
	var manifest: Dictionary={"schema":"1792.bazaar-direction-render.v1","captures":count,"failed":failed,
		"motion_frames":input.motion.size(),"motion_ticks":input.motion.map(func(f):return f.tick),
		"frame_interval_ticks":4,"physics_hz":60,"kind":"observation playback through shipped scene and player camera, not a fresh playthrough","audio":"disabled for these captures"}
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("BAZAAR_DIRECTION_RENDER: %d captures; %d failures"%[count,failed]);quit(1 if failed else 0)
