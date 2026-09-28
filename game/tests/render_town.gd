extends SceneTree
## Explicit presentation fixtures; actual gameplay movement is tested in test_town.gd.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=6) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();count+=1
	if image.is_empty() or image.save_png("user://town-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1440,900)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path="user://town-render-only.json"
	var error: String=scene.model.restore(Fixture.complete())
	if not error.is_empty(): push_error(error);quit(1);return
	root.add_child(home);await frames();scene._paused=true;scene.avatar.set_physics_process(false)
	var camera:=Camera3D.new();home.add_child(camera);camera.current=true;camera.far=400
	var views: Array=[
		["overview",Vector3(-82,75,36),Vector3(-12,0,-31)],
		["bazaar",Vector3(-4,8,-34),Vector3(-12,1,-50)],
		["well",Vector3(-13,5,-34),Vector3(-25,1,-44)],
		["pottery",Vector3(-36,5,-38),Vector3(-47,1,-46)],
		["cloth",Vector3(17,4,-51),Vector3(14,1.3,-61)],
		["cultivated-edge",Vector3(25,7,-59),Vector3(9,1,-74)]
	]
	for v in views:
		camera.position=v[1];camera.look_at(v[2]);await capture(v[0])
	# Standard gameplay camera, no hidden geometry or screenshot-only art.
	camera.queue_free();scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	error=Pose.pose(scene.model,Vector3(-20.7,0.14,-42))
	if not error.is_empty(): push_error(error);failed+=1
	scene._apply();scene.avatar.pivot.rotation=Vector3(-0.2,PI/2,0);scene._refresh();await capture("player-well")
	error=scene.model.observe_landmark("well")
	if not error.is_empty(): push_error(error);failed+=1
	scene._open_places();root.size=Vector2i(800,600);await capture("places-small-window")
	home.queue_free();await frames()
	print("TOWN_RENDER: %d captures; %d failures"%[count,failed]);quit(1 if failed or count!=8 else 0)
