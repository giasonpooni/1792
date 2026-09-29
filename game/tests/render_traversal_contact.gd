# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared presentation fixtures: real motor/contact/save, not a claimed human playthrough.
const Course := preload("res://mechanics/course.gd")
var captures := 0
var failures := 0
var c: Node3D
var camera: Camera3D
func _initialize() -> void: run.call_deferred()
func check(value: bool,message: String) -> void:
	if not value: failures+=1;push_error("CONTACT RENDER: "+message)
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func step(obstacle: bool=false) -> void:
	await physics_frame
	var error: String=c.avatar.step_motion(1.0/60,Vector2.ZERO,false,false,obstacle)
	c.tick+=1
	check(error.is_empty(),"physical fixture movement: "+error)
func setup(p: Vector3) -> void:
	c.set_paused(true);c.avatar.input_enabled=true;c.avatar.clear_traversal()
	c.avatar.global_position=p;c.avatar.velocity=Vector3.ZERO;c.avatar._grounded=false
	c.avatar._coyote=0;c.avatar._buffer=0;c.avatar.pivot.rotation=Vector3(-.2,0,0)
	for _i in range(10): await step()
func look(from: Vector3,at: Vector3) -> void:
	camera.global_position=from;camera.look_at(at);camera.current=true
func capture(id: String,require_hands: bool=false) -> void:
	c.avatar.get_node("LocomotionProxy").update_pose(0);c.refresh()
	await frames(5);await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty(): check(false,"missing framebuffer");return
	var sight:=PhysicsRayQueryParameters3D.create(camera.global_position,c.avatar.global_position+Vector3.UP*1.1,1,[c.avatar.get_rid()])
	check(c.get_world_3d().direct_space_state.intersect_ray(sight).is_empty(),"camera-to-body view not obstructed")
	var rect:=Rect2(Vector2.ZERO,Vector2(root.size))
	check(rect.encloses(c.hud.get_global_rect()) and rect.encloses(c.status.get_global_rect()),"UI within framebuffer")
	if require_hands:
		var proxy=c.avatar.get_node("LocomotionProxy")
		check(proxy.grips.size()==2,"two actual reachable skeletal hand contacts")
		for grip in proxy.grips:
			check(grip.error<.00001 and not camera.is_position_behind(grip.actual) and rect.has_point(camera.unproject_position(grip.actual)),"actual hand endpoint and visible framing")
	check(image.save_png("user://contact-"+id+".png")==OK,"write image")
	captures+=1
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	c=Course.new();c.save_path="user://test-contact-render.json";root.add_child(c);await frames(10)
	camera=Camera3D.new();camera.fov=52;c.add_child(camera)
	# Close-up inspection hides floating station captions, never geometry or actors.
	for child in c.get_children():
		if child is Label3D: child.hide()
	await setup(Vector3(0,.04,-3.08));await step(true)
	look(Vector3(2.3,2.6,-1.5),Vector3(0,1.25,-3.18))
	check(c.save_course().begins_with("Course motion saved"),"save actual in-contact mantle")
	c.message="CONTACT FIXTURE / Both hands meet the reachable ledge. Save retains the active mantle."
	await capture("mantle-hands",true)
	for _i in range(25): await step()
	check(c.load_course().begins_with("Course motion restored"),"reload contact while paused")
	check(c.paused and not c.avatar._route.is_empty(),"reload preserves active path in paused world")
	look(Vector3(-2.2,2.45,-1.6),Vector3(0,1.25,-3.18))
	c.message="RESTORED / Same saved contact and remaining path. No physics tick advanced by reload."
	await capture("restored-hands",true)
	await setup(Vector3(0,.04,.95));await step(true)
	for _i in range(17): await step()
	look(Vector3(1.4,2.8,2.7),Vector3(0,1.1,-.2))
	check(c.save_course().begins_with("Course motion saved"),"save mid-vault")
	c.message="VAULT FIXTURE / Remaining path is saved. Hands release when the ledge is out of reach."
	await capture("vault-saved")
	for _i in range(70): await step()
	check(c.load_course().begins_with("Course motion restored"),"load mid-vault")
	for _i in range(70): await step()
	check(c.avatar._route.is_empty() and c.avatar._grounded,"resumed vault physically lands")
	look(Vector3(1.45,2.8,1.8),Vector3(0,.8,-.95))
	c.message="LANDED / Resumed vault completed through collision movement, not a completion teleport."
	await capture("resumed-landing")
	root.size=Vector2i(800,450)
	await setup(Vector3(0,.04,-3.08));await step(true)
	look(Vector3(2.3,2.6,-1.5),Vector3(0,1.25,-3.18))
	check(c.save_course().begins_with("Course motion saved"),"compact active-contact save")
	c.message="PAUSED CONTACT / F5 saves the remaining climb. F9 restores it after validation."
	await capture("compact",true)
	if FileAccess.file_exists(c.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(c.save_path))
	print("TRAVERSAL_CONTACT_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures else 0)
