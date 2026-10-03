extends SceneTree
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
var passed:=0
var failed:=0

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame

func _wall(at: Vector3) -> StaticBody3D:
	var wall:=StaticBody3D.new()
	wall.position=at
	wall.collision_layer=1
	wall.collision_mask=1
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(3,5,0.5)
	shape.shape=box
	wall.add_child(shape)
	return wall

func _run() -> void:
	var home:=Launch.make_world()
	root.add_child(home)
	await frames(5)
	var scene=home.get_node("ChildhoodChapter")
	ok(scene.model.restore(Fixture.complete()),"complete inquiry fixture")
	scene._apply()
	await frames(2)
	check(is_instance_valid(scene.hawk),"hawk scout composed into active home workload")
	check(scene.attacker.is_in_group("hawk_hostile"),"hostile registration is explicit")

	scene.attacker.visible=true
	scene.attacker.collision_layer=1
	scene.attacker.collision_mask=1
	scene.attacker.global_position=scene.avatar.global_position+Vector3(0,0,-12)
	ok(scene.hawk.release_from_owner(),"release scout")
	await frames(2)
	scene.hawk.global_position=scene.avatar.global_position+Vector3(0,4,0)
	scene.hawk.rotation=Vector3(0,0,0)
	check(scene.hawk.active and not scene.avatar.input_enabled,"remote camera freezes protagonist input")
	check(scene.hawk.can_observe(scene.attacker),"visible unobstructed hostile observable beyond protagonist reach")
	scene.hawk._scan()
	check(scene.hawk.tagged_count()==1,"observable hostile receives temporary tag")
	check(scene.attacker.get_node_or_null("HawkScoutTag")!=null,"tag has world marker")

	var wall:=_wall(scene.avatar.global_position+Vector3(0,2,-6))
	scene.add_child(wall)
	await frames(2)
	check(not scene.hawk.can_observe(scene.attacker),"terrain/structure occlusion blocks hawk observation")
	scene.hawk.recall()
	check(not scene.hawk.active and scene.avatar.input_enabled,"recall restores protagonist control")
	scene.hawk._decay_tags(scene.hawk.TAG_SECONDS+0.1)
	await frames(2)
	check(scene.hawk.tagged_count()==0,"tags expire instead of becoming permanent enemy knowledge")

	home.queue_free()
	await frames()
	print("HAWK_RECON_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
