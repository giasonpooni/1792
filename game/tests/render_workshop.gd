extends SceneTree
## Declared scene fixtures only; test_workshop.gd separately drives real gameplay input.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String) -> void:
	var scene=current_scene.get_node_or_null("ChildhoodChapter") if current_scene!=null else null
	if scene!=null: scene._refresh()
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();count+=1
	if image.is_empty() or image.save_png("user://workshop-"+name+".png")!=OK: failed+=1
func expect(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func _run() -> void:
	root.size=Vector2i(1440,900)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://workshop-render-fixture-only.json"
	scene._message="Presentation fixture · original procedural workshop and authored commission."
	expect(scene.model.restore(Fixture.complete()));expect(scene.model.begin_allowance())
	root.add_child(home);current_scene=home;await frames();scene._paused=true;scene.avatar.set_physics_process(false)
	var camera:=Camera3D.new();home.add_child(camera);camera.current=true;camera.far=250
	camera.position=Vector3(-33,11,0);camera.look_at(Craft.SITE+Vector3(0,1,0));await capture("court")
	camera.position=Vector3(-43,3,-3);camera.look_at(Craft.SITE+Vector3(0,1,-0.5));await capture("smith")
	expect(scene.model.workshop_action("reserve"));expect(Pose.pose(scene.model,Craft.SITE+Vector3(2.4,0,0)));expect(scene.model.workshop_action("start"))
	for _i in range(27): scene.model.advance()
	scene._apply();scene._refresh();await capture("working")
	for _i in range(Craft.WORK_TICKS): scene.model.advance()
	scene._apply();scene._refresh();await capture("ready-bench")
	expect(scene.model.workshop_action("collect"));scene._apply();scene._refresh()
	camera.queue_free();scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	scene.avatar.pivot.rotation=Vector3(-0.2,PI/2,0);await capture("carried-player")
	scene._open_accounts();root.size=Vector2i(800,600);await capture("accounts-small")
	scene._resume();scene._paused=true;scene._open_smith();await capture("smith-small")
	home.queue_free();await frames()
	print("WORKSHOP_RENDER: %d captures; %d failures"%[count,failed]);quit(1 if failed or count!=7 else 0)
