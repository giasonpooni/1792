# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native node/material and reducer-fixture checks, not a claim of final art QA.
## Every restored fixture below is explicit; no fixture is called a played route.
const Scene := preload("res://world/home_territory.tscn")
const Chapter := preload("res://childhood/home_chapter.gd")
const Staging := preload("res://presentation/childhood_arc_staging.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const Kit := preload("res://presentation/workshop_kit.gd")
var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D
var staging: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("CHILDHOOD ARC STAGING: " + label)

func physics_identity() -> Array:
	var ids: Array = []
	for node in home.find_children("*", "CollisionObject3D", true, false):
		ids.append([node.get_instance_id(), node.global_transform, node.collision_layer, node.collision_mask])
	for node in home.find_children("*", "CollisionShape3D", true, false):
		ids.append([node.get_instance_id(), node.global_transform, node.shape.get_instance_id()])
	return ids

func fixture_lesson(gates: int, parries: int = 0, counters: int = 0) -> Dictionary:
	var model := Base.new()
	check(Fixture.pose(model, Base.SITES.letter).is_empty(), "declared fixture places reader at courier")
	check(model.inspect_letter().is_empty() and model.hear("courier").is_empty(), "declared fixture has a real sealed-message account")
	check(Fixture.pose(model, Base.SITES.steward).is_empty() and model.hear("steward").is_empty(), "declared fixture has a real read-aloud account")
	var value: Dictionary = model.snapshot()
	value.childhood.walked = 6.0
	value.childhood.looked = 1.0
	value.childhood.ride_gate = gates
	value.childhood.parries = parries
	value.childhood.counters = counters
	check(model.restore(value).is_empty(), "declared lesson totals pass the original validator")
	return model.snapshot()

func restore(value: Dictionary, description: String) -> void:
	check(chapter.model.restore(value).is_empty(), "existing authority restores " + description)
	chapter._apply()
	chapter._refresh()
	staging.sample()

func advance_to(tick: int) -> void:
	while int(chapter.model.progress().tick) < tick: chapter.model.advance()
	staging.sample()

func unchanged_sample(description: String) -> void:
	var before: Dictionary = chapter.model.snapshot()
	var bodies := physics_identity()
	var camera: Transform3D = chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").global_transform
	var pose: Transform3D = staging.trainer_arm.transform
	var flag: Transform3D = staging.gate_flags[0].flag.transform
	var breath: Transform3D = staging.quarry_body.transform
	for _index in range(5): staging.sample()
	check(chapter.model.snapshot() == before, description + " leaves whole authority, memories and time unchanged")
	check(physics_identity() == bodies, description + " leaves every collision object and shape unchanged")
	check(chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").global_transform == camera, description + " leaves the camera projection pose unchanged")
	check(staging.trainer_arm.transform == pose and staging.gate_flags[0].flag.transform == flag and staging.quarry_body.transform == breath, description + " repeats exactly at the same paused tick")

func run() -> void:
	home = Scene.instantiate()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	chapter = Chapter.new()
	chapter.name = "ChildhoodChapter"
	home.add_child(chapter)
	root.add_child(home)
	# The production controller attaches the helper. A direct standalone build is
	# retained to make the component test usable while integration is in progress.
	staging = chapter.get_node_or_null("ChildhoodArcStaging")
	if staging == null:
		staging = Staging.new()
		chapter.add_child(staging)
		var before: Dictionary = chapter.model.snapshot()
		var bodies := physics_identity()
		staging.build(chapter)
		check(chapter.model.snapshot() == before and physics_identity() == bodies, "component construction preserves authority and collision")
	check(is_instance_valid(staging.quarry_body), "existing quarry visual is found without adding an animal executor")
	check(staging.gate_flags.size() == 3 and staging.trace_roots.size() == 3, "three physical gates and three distinct trace sites are staged")
	check(staging.find_children("*", "CollisionObject3D", true, false).is_empty() and staging.find_children("*", "CollisionShape3D", true, false).is_empty(), "lesson staging adds no physics objects or shapes")
	check(staging.assailant_pose.get_parent() == chapter.attacker and not staging.assailant_pose.is_visible_in_tree(), "unknown future attacker stays under its existing hidden parent")
	check(not staging.is_processing() and not staging.is_physics_processing(), "staging has no process clock")
	var node_count := chapter.find_children("*", "Node", true, false).size()
	staging.build(chapter)
	check(chapter.find_children("*", "Node", true, false).size() == node_count, "repeated build does not duplicate geometry or attached arms")
	for gate in staging.gate_flags:
		check(gate.cloth.mesh is BoxMesh and gate.cloth.material_override is StandardMaterial3D and gate.number is MeshInstance3D and gate.number.mesh is TextMesh and not gate.number.mesh.text.is_empty(), "numbered gate has physical lettering that cannot be suppressed as a distant HUD label")
		check(gate.status == "remaining" and gate.cloth.material_override.albedo_color == Staging.REMAINING and not gate.stitch.visible, "unearned gate begins neutral without a completion stitch")
	check(staging.trace_roots.map(func(node): return String(node.name)) == ["SplitPrints", "DisturbedReeds", "CompressedGrass"], "successive traces use different readable physical treatments")
	for trace in staging.trace_roots:
		check(not trace.find_children("*", "MeshInstance3D", true, false).is_empty(), "trace has actual mesh geometry: " + String(trace.name))
	check(staging._hidden_traces.size() == 6, "six old non-colliding trace blocks are replaced without changing the world route")
	for record in staging._hidden_traces: check(not record.node.visible, "replaced trace block cannot obscure the new impression")
	check(staging.stop_marker.position == Base.GATES[2] + Staging.STOP_OFFSET and Staging.STOP_OFFSET.z > 3.0, "settling marker lies beyond the third gate")
	for mesh in staging.stop_marker.get_children():
		check(mesh is MeshInstance3D and mesh.mesh.size.y < 0.02 and mesh.position.y < 0.04, "stop mark stays a flat ground treatment")
	unchanged_sample("Fresh lesson sampling")
	restore(fixture_lesson(0), "first-gate fixture")
	check(staging.gate_flags[0].status == "active" and staging.gate_flags[0].cloth.material_override.albedo_color == Staging.ACTIVE and staging.gate_flags[1].status == "remaining", "first unpassed gate is ochre while later gates remain neutral")
	restore(fixture_lesson(1), "second-gate fixture")
	check(staging.gate_flags[0].status == "complete" and staging.gate_flags[0].stitch.visible and staging.gate_flags[0].cloth.material_override.albedo_color == Staging.COMPLETE, "passed gate uses a pale physical completion stitch and distinct colour")
	check(staging.gate_flags[1].status == "active" and staging.gate_flags[2].status == "remaining", "active guidance advances to exactly the next gate")
	restore(fixture_lesson(3), "sparring fixture")
	advance_to(110)
	check(staging.trainer_pose == "windup" and staging.trainer_arm.get_node("PracticeStick").global_position.y > staging.trainer_arm.global_position.y + 0.3, "trainer physically raises the practice stick above the shoulder inside the existing windup window")
	unchanged_sample("Paused sparring")
	# Match actual Home art's later construction order using its real person kit.
	var costume := Node3D.new()
	costume.name = "CostumeStudy"
	chapter.trainer.add_child(costume)
	var kit := Kit.new()
	kit.person(costume, -Vector3.UP * 0.85, "ab7149", 1.7)
	staging.sample()
	check(staging._costume_arms.size() == 2 and staging._costume_arms.all(func(record): return not record.node.visible), "actual person kit right sleeve and forearm are replaced, avoiding a third arm")
	costume.hide()
	check(staging._costume_arms.all(func(record): return record.node.visible == record.visible), "art comparison toggle immediately restores hidden kit arms while paused")
	costume.show()
	check(staging._costume_arms.all(func(record): return not record.node.visible), "art comparison toggle replaces the static arm again without a clock tick")
	unchanged_sample("Paused dressed trainer")
	advance_to(125)
	check(staging.trainer_pose == "recovery" and staging.trainer_arm.rotation.x < 0.0, "trainer displays the existing recovery opportunity")
	restore(fixture_lesson(3, 2, 1), "tracking fixture")
	check(staging.trainer_pose == "rest" and staging.trainer_arm.rotation == Vector3.ZERO, "trainer settles after the earned counter")
	var quarry_at_rest: Transform3D = staging.quarry_body.transform
	advance_to(30)
	check(staging.quarry_body.transform != quarry_at_rest and staging.quarry_body.position == quarry_at_rest.origin and absf(staging.quarry_body.scale.y - staging._quarry_rest.basis.get_scale().y) < 0.02, "stationary quarry gets only restrained tick-sampled breathing")
	unchanged_sample("Paused tracking")
	restore(Fixture.precursor(), "quarry approach fixture")
	check(chapter.model.observe_quarry(true).is_empty(), "fixture observes quarry through the original action")
	staging.sample()
	check(staging.threat_pose == "hidden" and not staging.assailant_pose.is_visible_in_tree(), "knowing the quarry does not reveal the future assailant")
	check(Fixture.pose(chapter.model, Base.SITES.bend).is_empty() and chapter.model.start_ambush().is_empty(), "declared encounter begins at the actual bend trigger")
	var start: int = chapter.model.progress().tick
	# A declared near-threat presentation fixture, not a claim of player movement.
	check(Fixture.pose(chapter.model, Base.point(chapter.model.progress().ambush.position) + Vector3(0, 0, 2.0)).is_empty(), "near-threat fixture stays within the original authority")
	chapter._apply()
	advance_to(start + 110)
	check(staging.threat_pose == "windup" and staging.assailant_pose.is_visible_in_tree() and staging.assailant_arm.get_node("PracticeStick").global_position.y > chapter.attacker.global_position.y + 1.6, "existing visible attacker telegraphs a nearby strike raised above the shoulder")
	check(not chapter.model.progress().ambush.seen, "visual sampling never grants witness knowledge")
	unchanged_sample("Paused threat windup")
	chapter.model.parry_threat()
	staging.sample()
	check(staging.threat_pose == "stagger" and staging._attacker_mesh.rotation.z > 0.2, "earned parry produces visible stagger while body remains authoritative")
	unchanged_sample("Paused stagger")
	check(Fixture.pose(chapter.model, Base.SITES.home).is_empty() and chapter.model.reach_home().is_empty(), "original reducer admits the return")
	chapter._apply()
	staging.sample()
	check(staging.threat_pose == "hidden" and not staging.assailant_pose.is_visible_in_tree(), "returned chapter hides the attacker gesture")
	# Restoring an earlier state removes later visual progress without saving a
	# second ledger or leaking future attack knowledge.
	restore(fixture_lesson(0), "early lesson rewind")
	check(staging.gate_flags[0].status == "active" and not staging.gate_flags[0].stitch.visible and staging.threat_pose == "hidden", "state rewind deterministically restores the first lesson presentation")
	unchanged_sample("Rewound lesson")
	var traces: Array = staging._hidden_traces.duplicate()
	var costume_arms: Array = staging._costume_arms.duplicate()
	var arm: Node3D = staging.trainer_arm
	var snapshot: Dictionary = chapter.model.snapshot()
	var physics := physics_identity()
	chapter.remove_child(staging)
	staging.queue_free()
	await process_frame
	await process_frame
	for record in traces: check(record.node.visible == record.visible, "component removal restores original trace visibility")
	for record in costume_arms: check(record.node.visible == record.visible, "component removal restores the original costume arm")
	check(not is_instance_valid(arm), "component removal also removes its externally attached arm")
	check(chapter.model.snapshot() == snapshot and physics_identity() == physics, "component removal preserves authority and colliders")
	home.queue_free()
	await process_frame
	print("CHILDHOOD_ARC_STAGING_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
