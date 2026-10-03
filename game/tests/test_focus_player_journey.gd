# Copyright (c) 2026 Notation Systems Inc. / Notations Gaming.
# All rights reserved.
extends SceneTree
## Earned perception evidence: ordinary mouse/key input, the production player
## motor, native collisions and the existing Home save authority. No target pose,
## story receipt or Focus sample is injected by this test.
const Launch := preload("res://childhood/home_launch.gd")
const State := preload("res://warband/nihang_state.gd")

var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D
var output := "user://focus-player-journey"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> bool:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("FOCUS PLAYER JOURNEY: " + label)
	return value

func frames(count: int = 1) -> void:
	for _index in range(count): await physics_frame
	await process_frame

func release_controls() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)

func key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate()
	release.pressed = false
	root.push_input(release, true)

func mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	root.push_input(event, true)

func steer(target: Vector3) -> float:
	var offset: Vector3 = target - chapter.avatar.global_position
	var yaw: float = atan2(-offset.x, -offset.z)
	var turn: float = wrapf(yaw - chapter.avatar.pivot.global_rotation.y, -PI, PI)
	mouse(Vector2(-turn / chapter.avatar.mouse_sensitivity, 0))
	return yaw

func face(target: Vector3) -> bool:
	var yaw:=steer(target)
	await process_frame
	return check(absf(wrapf(chapter.avatar.pivot.global_rotation.y-yaw,-PI,PI)) < .012,
		"ordinary mouse input turns the character eye toward the world target")

func horizontal_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))

func walk(target: Vector3, radius: float = .55, limit: int = 900) -> bool:
	release_controls()
	if not await face(target): return false
	var best: float = horizontal_distance(chapter.avatar.global_position,target)
	var stalled := 0
	for _tick in range(limit):
		var distance: float = horizontal_distance(chapter.avatar.global_position,target)
		if distance <= radius:
			release_controls(); await frames(8)
			return check(horizontal_distance(chapter.avatar.global_position,target) < radius+1.0,
				"ordinary movement returns through the production motor")
		if distance < best-.02:
			best=distance;stalled=0
		else:
			stalled+=1
		if stalled>120: break
		if _tick%12==0: steer(target)
		Input.action_press("move_forward")
		await physics_frame
	release_controls()
	return check(false,"player-input route stalled at %s toward %s" % [chapter.avatar.global_position,target])

func collision_identities() -> Array:
	var result: Array=[]
	for node in home.find_children("*","CollisionShape3D",true,false):
		var owner:=node.get_parent()
		# Bodies are allowed to move; ownership, local hull geometry and masks are not.
		result.append([node.get_instance_id(),node.transform,node.shape.get_rid(),node.disabled,
			owner.collision_layer if owner is CollisionObject3D else 0,
			owner.collision_mask if owner is CollisionObject3D else 0])
	return result

func anonymous(sample: Dictionary) -> bool:
	var allowed := ["position","observed_ticks","required_ticks","sample_tick","observer_id","sensor_id"]
	for field in sample.keys():
		if field not in allowed: return false
	return not sample.has("id") and not sample.has("label") and not sample.has("kind") and not sample.has("faction")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("FOCUS PLAYER JOURNEY requires a display backend for native mouse capture.")
		quit(2);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(960,540)
	root.disable_3d=true # Input and native physics are qualified; this suite does not claim pixels.
	release_controls()
	var provided:=OS.get_environment("FOCUS_PLAYER_JOURNEY_OUTPUT")
	if not provided.is_empty():output=provided
	home=Launch.make_world();root.add_child(home);current_scene=home
	chapter=home.get_node("ChildhoodChapter")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	chapter.save_path=output.path_join("earned-focus-slot.json")
	if FileAccess.file_exists(chapter.save_path):DirAccess.remove_absolute(chapter.save_path)
	await frames(12)
	check(chapter.model.stage()=="orientation" and chapter.model.journal().is_empty(),
		"journey begins from the production fresh Home authority")
	var physical_authority:=collision_identities()
	var opening_position: Vector3=chapter.avatar.global_position
	var opening_progress: Dictionary=chapter.model.snapshot()

	# Deliberately walk into the retained courtyard boundary. The player motor,
	# rather than a test clamp, must consume the commanded displacement.
	var wall_goal:=Vector3(opening_position.x,opening_position.y,20.0)
	await face(wall_goal)
	var hit_wall:=false
	Input.action_press("move_forward");Input.action_press("sprint")
	for _tick in range(160):
		await physics_frame
		if chapter.avatar.get_slide_collision_count()>0: hit_wall=true
	release_controls();await frames(4)
	check(hit_wall and chapter.avatar.global_position.z<11.7,
		"native courtyard collision stops held player input at the retained wall")
	check(chapter.model.progress().walked>float(opening_progress.childhood.walked),
		"the same collision route still earns ordinary opening movement")
	check(collision_identities()==physical_authority,
		"walking, collision and perception preparation preserve physical authority identities")
	# Return along the same admitted corridor with real reverse input. This avoids
	# manufacturing a pose and exercises collision release from the retained wall.
	Input.action_press("move_backward");Input.action_press("sprint")
	var returned:=false
	for _tick in range(180):
		if chapter.avatar.global_position.distance_to(opening_position)<.7:
			returned=true;break
		await physics_frame
	release_controls();await frames(6)
	if not check(returned and chapter.avatar.global_position.distance_to(opening_position)<1.2,
		"ordinary reverse input returns from the wall through the existing opening"):
		await finish();return

	# Approach and face an existing registered person. No sensor or subject pose is
	# manipulated; the current Home clock drives Focus through its physics process.
	var mother: Node3D=chapter._mother.get_parent()
	var approach:=Vector3(mother.global_position.x,chapter.avatar.global_position.y,mother.global_position.z-4.5)
	# Follow the same open courtyard corridor used by the production opening;
	# the direct diagonal intersects retained architecture and is not a valid route.
	for waypoint in [Vector3(-4.8,chapter.avatar.global_position.y,1.0),Vector3(-5.2,chapter.avatar.global_position.y,2.0)]:
		if not await walk(waypoint,.55): await finish();return
	if not await walk(approach,.7): await finish();return
	var subject: Node3D=chapter.workplace.find_child("FictionalSmith",true,false)
	await face(subject.global_position+Vector3.UP*1.0)
	check(chapter._seen(subject.global_position+Vector3.UP*1.0,18.0),
		"the existing character-eye policy admits the smith from the played pose")
	key(KEY_Z);await frames(20)
	var pending: Array=chapter.ground_focus.acquisitions()
	check(chapter.ground_focus.active and not pending.is_empty() and chapter.ground_focus.observations().is_empty(),
		"twenty played ticks expose progress without identifying the subject")
	check(pending.all(func(sample):return anonymous(sample)),
		"pre-identification journey evidence remains anonymous and sensor-bound")
	check(pending.all(func(sample):return sample.observer_id==chapter.Names.HERO_ID and sample.sensor_id=="character-eye"),
		"anonymous samples bind the protagonist and character eye, not the camera")

	var before_modal: Dictionary=chapter.model.snapshot()
	var journal_before_modal: Array=chapter.model.journal()
	key(KEY_J);await frames(3)
	check(chapter._paused and not chapter.ground_focus.active and chapter.ground_focus.acquisitions().is_empty(),
		"actual journal input interrupts and discards incomplete observation")
	var paused_state: Dictionary=chapter.model.snapshot()
	await frames(8)
	check(chapter.model.snapshot()==paused_state and chapter.model.journal()==journal_before_modal,
		"the modal freezes the existing clock and creates no perception receipt")
	key(KEY_ESCAPE);await frames(3)
	var resumed_tick: int=int(chapter.model.progress().tick)
	check(not chapter._paused and resumed_tick>=int(before_modal.childhood.tick) and resumed_tick<=int(before_modal.childhood.tick)+4,
		"returning from the modal resumes the same authority with only visible active-play ticks")
	await face(subject.global_position+Vector3.UP*1.0)

	# Save via the real key before identification. The independent decoder is the
	# comparison authority; Focus itself has no save fields.
	key(KEY_F5);await process_frame;await physics_frame
	var save_bytes:=FileAccess.get_file_as_bytes(chapter.save_path)
	var saved:=State.new()
	check(not save_bytes.is_empty() and saved.load_from(chapter.save_path).is_empty(),
		"actual F5 writes one independently decodable whole-Home save")
	var saved_snapshot: Dictionary=saved.snapshot()
	var saved_journal: Array=saved.journal()
	key(KEY_Z);await frames(60)
	var records: Array=chapter.ground_focus.observations()
	var subject_records:=records.filter(func(record):return record.id=="smith")
	if subject_records.is_empty():
		print("FOCUS JOURNEY DIAGNOSTIC: ",JSON.stringify({"active":chapter.ground_focus.active,
			"access":chapter._focus_access(),"tick":chapter.model.progress().tick,"records":records,
			"pending":chapter.ground_focus.acquisitions(),"seen":chapter._seen(subject.global_position+Vector3.UP*1.0,18.0),
			"player":chapter.avatar.global_position,"subject":subject.global_position,"camera":chapter.avatar.pivot.rotation}))
	check(subject_records.size()==1 and subject_records[0].label=="Smith" and not subject_records[0].has("faction"),
		"forty-five continuous played ticks identify only the registered visible person")
	if not subject_records.is_empty():
		check(subject_records[0].observer_id==chapter.Names.HERO_ID and subject_records[0].sensor_id=="character-eye",
			"earned observation retains its observer and sensor identities")
	var current_marks: Array=chapter.ground_focus.overlay.marks.filter(func(mark):return String(mark.text).contains("Smith"))
	check(current_marks.size()==1 and String(current_marks[0].text).ends_with("observed now"),
		"earned character-eye observation presents the smith as current evidence")
	check(chapter.ground_focus.heading.text.contains("Observation retained.") and chapter.ground_focus.heading.text.count("Observation retained.")==1 and not chapter.ground_focus.heading.text.contains("Smith"),
		"earned ring completion confirms bounded retention once without duplicating the subject identity")
	check(chapter.model.journal()==saved_journal and FileAccess.get_file_as_bytes(chapter.save_path)==save_bytes,
		"earned Focus evidence writes neither the journal nor the retained save")

	if not subject_records.is_empty():
		var observed_position: Array=subject_records[0].position.duplicate()
		mouse(Vector2(PI/chapter.avatar.mouse_sensitivity,0));await frames(2)
		subject_records=chapter.ground_focus.observations().filter(func(record):return record.id=="smith")
		check(not chapter._seen(subject.global_position+Vector3.UP*1.0,18.0) and subject_records.size()==1 and subject_records[0].position==observed_position,
			"turning the character eye away freezes the bounded last-seen point")
		# A retained world point correctly has no marker while it is behind the
		# displayed camera. Turn back through ordinary input: the old record is
		# then visible as retained evidence while fresh dwell is still anonymous.
		await face(subject.global_position+Vector3.UP*1.0);await frames()
		var retained_marks: Array=chapter.ground_focus.overlay.marks.filter(func(mark):return String(mark.text).contains("Smith"))
		check(not chapter.ground_focus.acquisitions().is_empty() and chapter.ground_focus.acquisitions().all(func(sample):return anonymous(sample)) and retained_marks.size()==1 and String(retained_marks[0].text).ends_with("last seen <1s ago"),
			"looking back presents the prior point as sub-second retained evidence while reacquisition stays anonymous")

	# Yield the sensory view, then continue into the ordinary sealed-message task
	# with the same production motor. The visible courier can be identified, but
	# neither the letter contents nor testimony exist until the existing E reducer
	# receives actual player input.
	key(KEY_Z);await frames(2)
	check(not chapter.ground_focus.active and chapter.model.stage()=="letter" and not chapter.model.progress().letter_seen,
		"the earned opening route reaches the normal letter task without staged campaign progress")
	var courier: Node3D=chapter._message_speakers.courier
	if not await walk(chapter.Model.SITES.courier,.65): await finish();return
	await face(courier.global_position+Vector3.UP*0.3)
	var letter_seen_before_focus: bool=chapter.model.progress().letter_seen
	var heard_before_focus: Array=chapter.model.progress().heard.duplicate()
	var journal_before_courier_focus: Array=chapter.model.journal()
	key(KEY_Z);await frames(20)
	check(not chapter.ground_focus.acquisitions().is_empty() and chapter.ground_focus.acquisitions().all(func(sample):return anonymous(sample)),
		"the courier's visible collision surface admits only anonymous character-eye progress")
	await frames(40)
	var courier_records: Array=chapter.ground_focus.observations().filter(func(record):return record.id=="courier")
	check(courier_records.size()==1 and courier_records[0].label=="Courier" and courier_records[0].observer_id==chapter.Names.HERO_ID and courier_records[0].sensor_id=="character-eye",
		"continuous played observation identifies the existing visible courier with explicit observer and sensor")
	check(chapter.model.progress().letter_seen==letter_seen_before_focus and chapter.model.progress().heard==heard_before_focus and chapter.model.journal()==journal_before_courier_focus,
		"courier observation reveals no sealed words, testimony or campaign receipt")
	key(KEY_E);await frames(3)
	check(not chapter.ground_focus.active and chapter.model.progress().letter_seen and chapter.model.progress().heard.is_empty(),
		"actual E yields Focus and lets the existing letter inspection own its receipt")
	check(chapter.model.journal().size()==journal_before_courier_focus.size()+1 and chapter.model.journal()[-1].id=="letter" and chapter.model.journal()[-1].source_id=="self",
		"letter inspection records only the protagonist's bounded observation")
	key(KEY_E);await frames(3)
	check(chapter.model.progress().heard==["courier"] and chapter.model.journal().size()==journal_before_courier_focus.size()+2,
		"a second actual E admits the courier's existing testimony through its normal task reducer")
	check(chapter.model.journal()[-1].id=="courier" and chapter.model.journal()[-1].source_id==chapter.Model.ACCOUNTS.courier.source_id and chapter.model.journal()[-1].channel==chapter.Model.ACCOUNTS.courier.channel,
		"the testimony receipt retains its authored source and channel instead of inheriting Focus identity")
	key(KEY_Z);await frames(3)
	check(chapter.ground_focus.active,"Focus can resume after the established task interaction completes")

	# Load while Focus is active. The production loader must replace the campaign
	# state and independently clear every transient perception layer.
	key(KEY_F9);await process_frame;await physics_frame
	chapter.set_physics_process(false);chapter.avatar.set_physics_process(false)
	await process_frame
	check(chapter.model.snapshot()==saved_snapshot and chapter.model.journal()==saved_journal,
		"actual F9 rolls the whole Home back to the independently decoded save")
	check(not chapter.ground_focus.active and chapter.ground_focus.observations().is_empty() and
		chapter.ground_focus.acquisitions().is_empty() and chapter.ground_focus.predictions().is_empty() and
		chapter.ground_focus.sound_cues().is_empty(),
		"save rollback discards observations, progress, estimates and heard cues")
	check(FileAccess.get_file_as_bytes(chapter.save_path)==save_bytes and collision_identities()==physical_authority,
		"rollback preserves saved bytes and the retained collision authority")
	await finish()

func finish() -> void:
	release_controls();current_scene=null
	if is_instance_valid(home):home.queue_free()
	await frames(4)
	print("FOCUS_PLAYER_JOURNEY_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
