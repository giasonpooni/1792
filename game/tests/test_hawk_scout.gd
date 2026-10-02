# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://scouting/hawk_scout_rules.gd")
const Scout := preload("res://scouting/hawk_scout.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("HAWK SCOUT FAIL: " + label)

func frames(count: int=3) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func blocker(at: Vector3, size := Vector3(5.0, 12.0, 1.0)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "ScoutOcclusionFixture"
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body

func test_sensor_admission() -> void:
	# Separate the bird and chase-view origins in a real physics space. A narrow
	# obstacle intersects one ray at a time, so neither refusal can pass because
	# both origins happen to share the same obstruction.
	var fixture := Node3D.new()
	fixture.position = Vector3(1000.0, 0.0, 0.0)
	root.add_child(fixture)
	var scout := Scout.new()
	fixture.add_child(scout)
	scout.chapter = fixture
	scout.active = true
	scout.position = Vector3(0.0, 8.0, 0.0)
	var contact := Node3D.new()
	contact.position = Vector3(0.0, 8.0, -10.0)
	contact.set_meta("hawk_scout_height", 0.0)
	fixture.add_child(contact)
	scout.register_target("sensor_fixture", contact, "Sensor fixture")
	scout.camera.global_position = scout.sensor_position() + Vector3(4.0, 0.0, 0.0)
	scout.camera.look_at(contact.global_position, Vector3.UP)
	await frames()
	check(scout.sensor_position().is_equal_approx(scout.get_node("HawkBody").global_position), "explicit sensor position is the bird body, independent of the chase camera")
	check(String(scout.tag_best_target().error).is_empty(), "contact clear to both sensor and chase view can be tagged")
	scout.clear_tags()

	var wall := blocker(Vector3(0.0, 8.0, -5.0), Vector3(1.0, 3.0, 1.0))
	fixture.add_child(wall)
	await frames()
	check(scout._line_of_sight(contact, scout.camera.global_position, contact.global_position) and not scout._line_of_sight(contact, scout.sensor_position(), contact.global_position), "camera-clear/bird-blocked fixture separates both physics rays")
	check(not String(scout.tag_best_target().error).is_empty() and scout.observations().is_empty(), "camera peeking around an obstruction cannot acquire a bird-hidden target")
	wall.queue_free()
	await frames()

	wall = blocker(Vector3(2.0, 8.0, -5.0), Vector3(1.0, 3.0, 1.0))
	fixture.add_child(wall)
	await frames()
	check(scout._line_of_sight(contact, scout.sensor_position(), contact.global_position) and not scout._line_of_sight(contact, scout.camera.global_position, contact.global_position), "bird-clear/camera-blocked fixture separates both physics rays")
	check(not String(scout.tag_best_target().error).is_empty() and scout.observations().is_empty(), "bird visibility alone cannot tag through an obstruction in the displayed chase view")
	wall.queue_free()
	await frames()

	contact.position = Vector3(0.0, 8.0, -48.0)
	scout.camera.global_position = scout.sensor_position() + Vector3(0.0, 0.0, -7.5)
	scout.camera.look_at(contact.global_position, Vector3.UP)
	check(scout.camera.global_position.distance_to(contact.global_position) < Rules.TAG_RANGE and scout.sensor_position().distance_to(contact.global_position) > Rules.TAG_RANGE, "camera-nearer fixture is inside camera range but beyond bird range")
	check(not String(scout.tag_best_target().error).is_empty() and scout.observations().is_empty(), "camera offset cannot extend the bird's acquisition range")

	contact.position = Vector3(0.0, 8.0, -41.0)
	scout.camera.global_position = scout.sensor_position() + Vector3(0.0, 0.0, 7.5)
	scout.camera.look_at(contact.global_position, Vector3.UP)
	check(scout.camera.global_position.distance_to(contact.global_position) > Rules.TAG_RANGE and scout.sensor_position().distance_to(contact.global_position) < Rules.TAG_RANGE, "camera-farther fixture is beyond camera range but inside bird range")
	check(String(scout.tag_best_target().error).is_empty(), "camera offset does not shorten the bird's acquisition range")
	var last_seen: Array = scout.observations()
	contact.queue_free()
	await frames()
	check(not String(scout.tag_best_target().error).is_empty() and not scout._targets.has("sensor_fixture"), "freed target is pruned before typed access and cannot be tagged again")
	check(scout.observations() == last_seen, "target removal preserves the acquired last-seen observation")
	var expiry: int = int(last_seen[0].expires_tick)
	scout.sample(expiry - 1)
	check(scout.observations() == last_seen, "freed-target last-seen observation remains until its original expiry")
	scout.sample(expiry)
	check(scout.observations().is_empty(), "freed-target last-seen observation expires on the existing clock")
	scout.clear_tags()
	var decoy := Node3D.new()
	decoy.position = fixture.global_position + Vector3(0.0, 8.0, -10.0)
	decoy.set_meta("hawk_scout_id", "foreign_group_contact")
	decoy.set_meta("hawk_scout_label", "Another chapter's contact")
	decoy.set_meta("hawk_scout_height", 0.0)
	root.add_child(decoy)
	decoy.add_to_group("hawk_scout_hostile")
	scout.camera.look_at(decoy.global_position, Vector3.UP)
	await frames()
	check(scout.sensor_position().distance_to(decoy.global_position) < Rules.TAG_RANGE and scout._line_of_sight(decoy, scout.sensor_position(), decoy.global_position) and scout._line_of_sight(decoy, scout.camera.global_position, decoy.global_position), "foreign chapter decoy is inside sensor range and clear to both observation rays")
	scout.register_target("foreign_explicit_contact", decoy, "Foreign explicit contact")
	check(not scout._targets.has("foreign_explicit_contact"), "explicit registration refuses nodes outside the bound chapter")
	check(not String(scout.tag_best_target().error).is_empty() and not scout._targets.has("foreign_group_contact") and scout.observations().is_empty(), "global group membership cannot acquire a contact from another chapter")
	decoy.queue_free()
	fixture.queue_free()
	await frames()

func run() -> void:
	var origin := Vector3(3.0, 2.0, -4.0)
	var bounded := Rules.bound_position(origin, origin + Vector3(100.0, 100.0, 0.0))
	check(is_equal_approx(Vector2(bounded.x-origin.x,bounded.z-origin.z).length(),Rules.MAX_RADIUS),"flight radius is bounded")
	check(is_equal_approx(bounded.y,origin.y+Rules.MAX_ALTITUDE),"flight altitude is bounded")
	check(Rules.view_score(Vector3.ZERO,Vector3.FORWARD,Vector3(0,0,-10))>0.0,"forward target is scoutable")
	check(Rules.view_score(Vector3.ZERO,Vector3.FORWARD,Vector3(0,0,10))<0.0,"rear target is outside scout view")
	var sample := Rules.observation("fixture","Fixture hostile",Vector3(1,2,3),20)
	check(Rules.valid_observation(sample) and sample.expires_tick==20+Rules.TAG_TTL_TICKS,"last-seen observation has bounded lifetime")
	await test_sensor_admission()

	var home: Node3D = Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(8)
	var scout = scene.hawk_scout
	check(is_instance_valid(scout),"hawk scout attaches to the current composed Home chapter")
	check(scout.get_meta("classification","")=="authored-gameplay-scouting","scout declares its gameplay classification")
	check(scout.get_meta("historical_claim",true)==false and scout.get_meta("save_authority",true)==false,"scout is neither historical proof nor save authority")

	check(is_instance_valid(scene.scout_contacts) and scene.scout_contacts.contacts.size()==2,"two distant fictional scout contacts are present behind the Home sightline")
	check(scene.scout_contacts.get_meta("historical_claim",true)==false and scene.scout_contacts.get_meta("persistent_state",true)==false,"distant contacts are authored gameplay, not historical or persistent state")
	var before: Dictionary = scene.model.snapshot()
	scene._launch_hawk()
	check(scout.active and scout.camera.current,"launch switches to the aerial camera")
	check(not scene.avatar.input_enabled,"launch freezes player input without replacing the body")
	check(scene.model.snapshot()==before,"launch does not mutate campaign state")

	var contact: Node3D=scene.scout_contacts.contacts[0]
	scout.global_position = contact.global_position + Vector3(0.0,8.0,10.0)
	scout.rotation = Vector3.ZERO
	scout.sample(int(scene.model.progress().tick))
	var tagged: Dictionary = scout.tag_best_target()
	check(String(tagged.error).is_empty() and tagged.target_id=="unknown_northwest_lookout","distant hostile contact is discovered and tagged from the hawk view")
	var observations: Array = scout.observations()
	check(observations.size()==1 and Rules.valid_observation(observations[0]),"tag produces one valid last-seen observation")
	var remembered: Vector3 = Rules.observation_position(observations[0])
	contact.position += Vector3(3.0,0.0,0.0)
	check(Rules.observation_position(scout.observations()[0]).is_equal_approx(remembered),"tag does not become omniscient live tracking")
	check(scene.model.snapshot()==before,"tagging does not mutate the campaign model")

	scout.clear_tags()
	var wall := blocker(Vector3(0.0,6.0,-2.5))
	scene.add_child(wall)
	await frames(2)
	# Superclass sampling restores the encounter proxy from the authoritative model.
	# Reinstall only the physical visibility fixture after the physics-space blocker exists.
	scout.global_position = Vector3(0.0,10.0,4.0)
	scout.rotation = Vector3.ZERO
	scene.attacker.global_position = Vector3(0.0,0.14,-12.0)
	scene.attacker.visible = true
	scene.attacker.collision_layer = 1
	scene.attacker.collision_mask = 1
	var blocked_before: Dictionary=scene.model.snapshot()
	var blocked: Dictionary=scout.tag_best_target()
	check(not String(blocked.error).is_empty() and scout.observations().is_empty(),"occluding collision prevents an aerial tag")
	check(scene.model.snapshot()==blocked_before,"rejected tag leaves game authority unchanged")
	wall.queue_free()
	await frames(2)
	scout.global_position = Vector3(0.0,10.0,4.0)
	scout.rotation = Vector3.ZERO
	scene.attacker.global_position = Vector3(0.0,0.14,-12.0)
	scene.attacker.visible = true
	scene.attacker.collision_layer = 1
	scene.attacker.collision_mask = 1

	scout.clear_tags()
	scout.sample(100)
	var retagged: Dictionary=scout.tag_best_target()
	if String(retagged.error).is_empty():
		var expiry: int=int(retagged.observation.expires_tick)
		scout.sample(expiry)
		check(scout.observations().is_empty(),"last-seen tag expires on the existing chapter clock")
	else:
		check(false,"retag before expiry test: "+String(retagged.error))

	scout.return_to_player()
	check(not scout.active and scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current,"return restores the original player camera")
	check(scene.avatar.input_enabled,"return restores player input")
	home.queue_free()
	await frames(3)
	print("HAWK_SCOUT_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
