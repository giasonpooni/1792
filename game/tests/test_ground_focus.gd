# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native physics/interaction checks. Synthetic sensor fixtures never become campaign evidence.
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://perception/focus_rules.gd")

var passed := 0
var failed := 0
var checks: Array = []
var output := "user://ground-focus-tests"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks.append({"label":label,"passed":value})
	if value: passed += 1
	else:
		failed += 1
		push_error("GROUND FOCUS FAIL: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func key(scene, code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	scene._unhandled_input(event)

func box(at: Vector3, size: Vector3, label: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	body.add_child(mesh)
	return body

func looping_sound() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(2205 * 2)
	for i in range(2205): data.encode_s16(i*2,int(sin(TAU*440.0*i/22050.0)*2200.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 2205
	return stream

func prepare(scene, at: Vector3) -> void:
	scene.set_physics_process(false)
	scene.set_process_unhandled_input(false)
	scene.avatar.set_physics_process(false)
	scene.avatar.input_enabled = false
	scene.avatar.global_position = at
	scene.avatar.pivot.rotation = Vector3.ZERO
	scene.ground_focus.clear()
	scene.ground_focus._targets.clear()
	scene.ground_focus._sounds.clear()

func acquire(focus, first: int = 0) -> void:
	for tick in range(first, first + Rules.DWELL_TICKS): focus.sample(tick)

func visual_checks(scene) -> void:
	# Reuse the real Home visibility policy in an empty part of its physics space.
	# Only physical fixture poses change; the campaign snapshot remains untouched.
	prepare(scene, Vector3(1000.0,0.14,0.0))
	var focus = scene.ground_focus
	var contact := Node3D.new()
	contact.position = Vector3(1000.0,1.49,-8.0)
	contact.set_meta("hidden_faction", "hostile_fixture_secret")
	scene.add_child(contact)
	focus.register_target("unknown_fixture",contact,"Unknown contact","contact")
	var before: Dictionary = scene.model.snapshot()
	var journal: Array = scene.model.journal()
	var save := output.path_join("unmodified-campaign.json")
	check(scene.model.save_to(save).is_empty(), "native model save before observation")
	var bytes := FileAccess.get_file_as_string(save)
	focus.start()
	for _i in range(80): focus.sample(0)
	check(focus.observations().is_empty(), "duplicate simulation tick never earns identification dwell")
	for tick in range(1, Rules.DWELL_TICKS-1): focus.sample(tick)
	check(focus.observations().is_empty(), "44 distinct contiguous ticks do not identify a contact")
	focus.sample(Rules.DWELL_TICKS-1)
	check(focus.observations().size()==1, "45 distinct contiguous ticks acquire one observation")
	var record: Dictionary = focus.observations()[0]
	check(record.kind=="contact" and record.label=="Unknown contact" and not record.has("faction"), "unknown contact never exposes hidden hostility or affiliation")
	check(record.sensor_id=="character-eye" and not record.observer_id.is_empty(), "observation binds the protagonist and character-eye sensor")
	check(scene.model.snapshot()==before and scene.model.journal()==journal, "Focus acquisition leaves campaign state and journal unchanged")
	check(FileAccess.get_file_as_string(save)==bytes, "Focus never writes or changes the retained native save")
	var returned: Array = focus.observations()
	returned[0].position[0] = -9999.0
	check(Rules.position(focus.observations()[0]).x==1000.0, "caller mutation cannot rewrite retained observations")
	contact.hide()
	contact.position += Vector3(5.0,0,0)
	focus.sample(45)
	check(Rules.position(focus.observations()[0]).is_equal_approx(Vector3(1000.0,1.49,-8.0)), "lost sight freezes the last observed coordinate instead of tracking hidden motion")
	focus.sample(int(record.expires_tick)-1)
	check(focus.observations().size()==1, "last-seen observation survives until its bounded expiry")
	focus.sample(int(record.expires_tick))
	check(focus.observations().is_empty(), "last-seen observation expires exactly on the existing tick")

	contact.show()
	contact.position = Vector3(1000.0,1.49,-8.0)
	focus.clear(); focus.start()
	for tick in range(20): focus.sample(tick)
	focus.sample(100)
	for _i in range(60): focus.sample(100)
	for tick in range(101,144): focus.sample(tick)
	check(focus.observations().is_empty(), "a discontinuous tick interrupts acquisition and duplicated ticks do not reconnect it")
	focus.sample(144)
	check(focus.observations().size()==1, "45 new contiguous observations reacquire after a discontinuity")

	focus.clear(); focus.start()
	contact.position = Vector3(1000.0,1.49,8.0)
	acquire(focus)
	check(focus.observations().is_empty(), "a contact behind the character sensor cannot be acquired")
	contact.position = Vector3(1000.0,1.49,-Rules.RANGE-0.5)
	var camera: Camera3D = scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	var original_camera := camera.global_transform
	camera.global_position = contact.global_position+Vector3(0,0,1)
	camera.look_at(contact.global_position)
	focus.clear(); focus.start(); acquire(focus)
	check(focus.observations().is_empty(), "a nearer chase camera cannot extend the character sensor range")
	camera.global_transform = original_camera
	contact.position = Vector3(1000.0,1.49,-8.0)
	focus.clear(); focus.start(); acquire(focus)
	camera.global_position = Vector3(1000.0,3.0,2.0)
	camera.look_at(Vector3(1000.0,3.0,12.0))
	focus.sample(44)
	check(focus.observations().size()==1 and focus.overlay.marks.is_empty(), "a retained character observation behind the displayed camera produces no screen marker")
	camera.global_transform = original_camera
	contact.queue_free()
	await frames()

	var own := box(Vector3(1000.0,1.49,-8.0),Vector3(1,2,1),"OwnColliderFixture")
	scene.add_child(own)
	await frames()
	focus.clear(); focus.start()
	focus.register_target("own_body",own,"Own surface fixture")
	check(not scene._seen(own.global_position,Rules.RANGE), "fixture endpoint ray hits its own solid body")
	acquire(focus)
	check(focus.observations().size()==1, "a target's own first-hit collider permits its visible surface")
	check(not focus._targets.has("unknown_fixture"), "freed target references are pruned without a native script error")
	focus.clear(); focus._targets.clear(); focus.start()
	var own_mesh: Node3D = own.get_child(1)
	focus.register_target("own_mesh",own_mesh,"Own mesh fixture")
	acquire(focus)
	check(focus.observations().size()==1, "mesh target accepts the first hit on its collision-body parent")
	var wall := box(Vector3(1000.0,1.49,-4.0),Vector3(5,5,1),"BlockingWallFixture")
	scene.add_child(wall)
	await frames()
	focus.clear(); focus.start(); acquire(focus)
	check(focus.observations().is_empty(), "an intervening first-hit wall blocks identification through the target's own-collider fallback")
	wall.queue_free(); own.queue_free()
	await frames()
	check(scene.model.snapshot()==before and scene.model.journal()==journal and FileAccess.get_file_as_string(save)==bytes, "all rejected and accepted physics observations preserve campaign/journal/save identities")

func motion_checks(scene) -> void:
	prepare(scene, Vector3(1000.0,0.14,0.0))
	var focus = scene.ground_focus
	var contact := Node3D.new()
	contact.position = Vector3(1000.0,1.49,-8.0)
	scene.add_child(contact)
	focus.register_target("moving_fixture",contact,"Observed moving contact")
	focus.start(); acquire(focus)
	for tick in range(45,75):
		contact.position.x = 1000.0+float(tick-44)*0.01
		focus.sample(tick)
	var predictions: Dictionary = focus.predictions()
	check(predictions.has("moving_fixture"), "two spaced visible snapshots produce a bounded motion estimate")
	if predictions.has("moving_fixture"):
		var prediction: Dictionary = predictions.moving_fixture
		check(prediction.from_ticks==[44,74] and prediction.kind=="estimate", "prediction retains its two observed source ticks and estimate identity")
		check(absf(Rules.position(prediction).x-1001.5)<0.002, "prediction follows measured displacement rather than an authored future patrol route")
		contact.hide(); contact.position.x=1040.0
		focus.sample(75)
		check(focus.predictions()==predictions and absf(Rules.position(focus.observations()[0]).x-1000.3)<0.002, "concealed movement changes neither the retained snapshot nor its existing estimate")
		focus.sample(int(prediction.expires_tick)-1)
		check(focus.predictions().has("moving_fixture"), "estimate remains available only within its short horizon")
		focus.sample(int(prediction.expires_tick))
		check(focus.predictions().is_empty() and focus.observations().size()==1, "estimate expires before the longer-lived last-seen observation")
		focus.sample(674)
		check(focus.observations().is_empty(), "motion observation also expires without omniscient refresh")
	contact.show(); contact.position=Vector3(1000,1.49,-8)
	focus.clear(); focus.start(); acquire(focus)
	for tick in range(45,75):
		contact.position.x=1000.0+float(tick-44)*0.01
		focus.sample(tick)
	check(focus.predictions().has("moving_fixture"), "prediction exists before a brief visual interruption")
	contact.hide(); focus.sample(75)
	contact.show()
	for tick in range(76,120): focus.sample(tick)
	check(focus.predictions().has("moving_fixture"), "old estimate keeps its source identity while reacquisition is still incomplete")
	focus.sample(120)
	check(focus.predictions().is_empty(), "new acquisition baseline discards an estimate derived from an earlier observation")
	for tick in range(121,151):
		contact.position.x=1000.3+float(tick-120)*0.01
		focus.sample(tick)
	check(focus.predictions().has("moving_fixture") and focus.predictions().moving_fixture.from_ticks==[120,150], "reacquired estimate uses only the new visible observation interval")
	focus.stop(); focus.start()
	for tick in range(151,195): focus.sample(tick)
	check(focus.predictions().has("moving_fixture"), "stop/restart preserves the old estimate only through incomplete reacquisition")
	focus.sample(195)
	check(focus.predictions().is_empty(), "stop/restart identification creates a fresh baseline and clears stale estimate")
	contact.show(); contact.position=Vector3(1000,1.49,-8)
	focus.clear(); focus.start(); acquire(focus)
	for tick in range(45,75):
		contact.position.x = 1000.0+float(tick-44)*0.14
		focus.sample(tick)
	check(focus.predictions().is_empty(), "implausible observed displacement does not produce an accepted patrol prediction")
	contact.queue_free(); await frames()

func audio_checks(scene) -> void:
	prepare(scene,Vector3(1000,0.14,0))
	var focus = scene.ground_focus
	var source := AudioStreamPlayer3D.new()
	source.position=Vector3(1000,1.49,-6)
	source.max_distance=12.0
	source.volume_db=-12.0
	source.stream=looping_sound()
	scene.add_child(source)
	focus.register_sound("hidden_guard_identity",source,"Metal striking")
	focus.start(); source.play(); await frames(2)
	check(source.playing, "native looping audio fixture is actually playing")
	focus.sample(0)
	var cues: Array=focus.sound_cues()
	check(cues.size()==1 and cues[0].sector=="ahead", "an actual nearby source emits a coarse directional hearing cue")
	if not cues.is_empty():
		check(not cues[0].has("id") and not cues[0].has("position") and not cues[0].has("source_id") and cues[0].sensor_id=="character-hearing", "sound cue exposes no concealed identity or exact coordinate")
		var expires: int=int(cues[0].expires_tick)
		source.stop(); focus.sample(expires-1)
		check(focus.sound_cues().size()==1, "a stopped source retains only a bounded past hearing cue")
		focus.sample(expires)
		check(focus.sound_cues().is_empty(), "heard cue expires without sound or another clock")
	focus.clear(); focus.start(); focus.sample(0)
	check(focus.sound_cues().is_empty(), "a silent source cannot create hearing evidence")
	source.play(); await frames(2); source.stream_paused=true; await frames(2)
	focus.clear(); focus.start(); focus.sample(1)
	check(source.stream_paused, "native stream reports paused after mixer settling")
	check(focus.sound_cues().is_empty(), "a paused native audio stream cannot create hearing evidence")
	source.stream_paused=false; source.volume_db=-70; await frames(2)
	focus.clear(); focus.start(); focus.sample(2)
	check(focus.sound_cues().is_empty(), "a source below the sound threshold cannot create hearing evidence")
	source.volume_db=-12
	var bus: int=AudioServer.get_bus_index(source.bus)
	var was_muted: bool=AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus,true); await frames(2)
	focus.clear(); focus.start(); focus.sample(3)
	check(focus.sound_cues().is_empty(), "a muted source bus cannot create hearing evidence")
	AudioServer.set_bus_mute(bus,was_muted)
	source.position.z=-30; await frames(2)
	focus.clear(); focus.start(); focus.sample(4)
	check(focus.sound_cues().is_empty(), "a playing source beyond its hearing radius is declined")
	source.position.z=-5
	var wall := box(Vector3(1000,1.49,-2.5),Vector3(5,5,0.5),"MuffledSoundWallFixture")
	scene.add_child(wall); await frames()
	focus.sample(5)
	check(focus.sound_cues().size()==1 and focus.sound_cues()[0].muffled, "nearby sound through a wall remains coarse and explicitly muffled")
	focus.clear(); focus.start(); source.position.z=-8; focus.sample(6)
	check(focus.sound_cues().is_empty(), "wall attenuation shortens the admitted sound radius")
	source.stop(); source.queue_free(); wall.queue_free(); await frames()
	focus.clear(); focus.start(); focus.sample(7)
	check(not focus._sounds.has("hidden_guard_identity"), "freed audio sources are pruned without a native script error")

func scope_checks(scene) -> void:
	prepare(scene,Vector3(1000,0.14,0))
	var focus=scene.ground_focus
	var foreign:=Node3D.new(); foreign.position=Vector3(1000,1.49,-6); root.add_child(foreign)
	var foreign_audio:=AudioStreamPlayer3D.new(); foreign_audio.position=foreign.position; foreign_audio.stream=looping_sound(); root.add_child(foreign_audio)
	focus.register_target("foreign_contact",foreign,"Foreign contact")
	focus.register_sound("foreign_audio",foreign_audio,"Foreign sound")
	check(not focus._targets.has("foreign_contact") and not focus._sounds.has("foreign_audio"), "targets and sounds outside the active Home cannot enter its sensor registry")
	var local:=Node3D.new(); local.position=Vector3(1000,1.49,-6); scene.add_child(local)
	var local_audio:=AudioStreamPlayer3D.new(); local_audio.position=local.position; local_audio.stream=looping_sound(); scene.add_child(local_audio)
	focus.register_target("reparented_contact",local,"Local contact")
	focus.register_sound("reparented_audio",local_audio,"Local sound")
	check(focus._targets.has("reparented_contact") and focus._sounds.has("reparented_audio"), "active Home descendants can register observation sources")
	local.reparent(root); local_audio.reparent(root); local_audio.play(); await frames(2)
	focus.start(); acquire(focus)
	check(not focus._targets.has("reparented_contact") and not focus._sounds.has("reparented_audio") and focus.observations().is_empty() and focus.sound_cues().is_empty(), "reparenting a source out of the Home revokes its registration and observation admission")
	foreign.queue_free(); foreign_audio.queue_free(); local.queue_free(); local_audio.queue_free(); await frames()

func integration_checks() -> void:
	var home: Node3D=Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.set_physics_process(false)
	scene.set_process_unhandled_input(false)
	root.add_child(home); await frames(8)
	scene.avatar.set_physics_process(false)
	scene.save_path=output.path_join("integration-slot.json")
	var valid_fixture: Dictionary=scene.model.snapshot()
	valid_fixture.player.position=[0.0,0.14,4.0]
	valid_fixture.actors[scene.Names.HERO_ID].position=[0.0,0.14,4.0]
	check(scene.model.restore(valid_fixture).is_empty(), "isolated native load fixture restores a validated clear-yard pose")
	scene._apply(); scene.avatar.set_physics_process(false)
	var candidate_error: String=scene._candidate_error(scene.model)
	check(candidate_error.is_empty(), "native clear-yard load fixture has valid standing room: "+candidate_error)
	var focus=scene.ground_focus
	check(is_instance_valid(focus) and not focus.get_meta("save_authority",true), "Focus attaches to the native Home without save authority")
	check(focus.get_meta("historical_claim",true)==false, "Focus declares authored gameplay instead of historical proof")
	var before: Dictionary=scene.model.snapshot()
	var journal: Array=scene.model.journal()
	var help_was_visible: bool=scene._hud.visible
	key(scene,KEY_Z)
	check(focus.active and not scene._hud.visible, "Focus suppresses inherited verbose help while leaving the controller active")
	key(scene,KEY_Z)
	check(not focus.active and scene._hud.visible==help_was_visible, "stopping Focus restores the inherited help visibility flag")
	scene._hud.hide(); key(scene,KEY_Z)
	check(focus.active and not scene._hud.visible, "Focus can start with inherited verbose help already hidden")
	key(scene,KEY_Z)
	check(not focus.active and not scene._hud.visible, "stopping Focus preserves an already-hidden inherited help flag")
	scene._hud.visible=help_was_visible
	key(scene,KEY_Z)
	check(focus.active and scene.avatar.input_enabled, "Z enables Focus while preserving the inherited ground controller")
	key(scene,KEY_E)
	check(scene._interact_requested, "E retains the inherited normal interaction request while focusing")
	key(scene,KEY_F)
	check(scene._mount_requested, "F retains the inherited mount request while focusing")
	scene._clear_pending_actions()
	var guard_event:=InputEventKey.new(); guard_event.keycode=KEY_Q; guard_event.physical_keycode=KEY_Q; guard_event.pressed=true
	Input.parse_input_event(guard_event); scene._unhandled_input(guard_event); await frames(2)
	check(Input.is_key_pressed(KEY_Q) and focus.active and scene.guard_visual.visible, "Q remains a held native guard control rather than a Focus binding")
	check(scene.model.progress().tick>before.childhood.tick and scene.model.journal()==journal, "native guard demonstration advances only the inherited active-play clock")
	var release:=guard_event.duplicate(); release.pressed=false; Input.parse_input_event(release); await frames(2)
	scene.set_physics_process(false)
	before=scene.model.snapshot()
	journal=scene.model.journal()
	key(scene,KEY_Z)
	check(not focus.active and scene.model.snapshot()==before, "Z disables Focus without changing native campaign state")
	key(scene,KEY_Z); focus._pending["journal_fixture"]=0
	key(scene,KEY_J)
	check(scene._paused and not focus.active and focus._pending.is_empty(), "the real J journal key immediately interrupts Focus identification")
	key(scene,KEY_Z)
	check(not focus.active, "a modal journal refuses Focus activation")
	scene._resume(); scene.avatar.set_physics_process(false)
	Input.action_press("sprint"); key(scene,KEY_Z)
	check(not focus.active, "held sprint refuses Focus activation")
	Input.action_release("sprint"); key(scene,KEY_Z)
	var sprint_tick: int=int(scene.model.progress().tick)
	Input.action_press("sprint"); scene._physics_process(1.0/60.0)
	check(not focus.active and scene.model.progress().tick==sprint_tick+1, "sprinting interrupts Focus during the single inherited physics transition")
	Input.action_release("sprint")
	before=scene.model.snapshot(); journal=scene.model.journal()
	key(scene,KEY_Z); focus._pending["interrupted_fixture"]=0
	scene._show_dialog("ISOLATED TEST FIXTURE","Native modal interruption",[["Return","resume"]])
	check(not focus.active and focus._pending.is_empty(), "a native dialogue interrupts and discards partial identification")
	scene.set_physics_process(true); await frames(10); scene.set_physics_process(false)
	check(scene.model.snapshot()==before and scene.model.journal()==journal, "native modal pause preserves the common clock and journal")
	scene._resume(); scene.avatar.set_physics_process(false)
	key(scene,KEY_Z); scene._launch_hawk()
	check(scene.hawk_scout.active and not focus.active, "hawk launch interrupts ground Focus and switches to the existing aerial layer")
	key(scene,KEY_Z)
	check(not focus.active, "Z cannot enable ground Focus during active hawk scouting")
	scene.hawk_scout.return_to_player(); scene.avatar.set_physics_process(false)
	check(scene.model.save_to(scene.save_path).is_empty(), "native isolated save is available for a whole-state load")
	var saved_bytes:=FileAccess.get_file_as_string(scene.save_path)
	var expected_slot=scene.WorkshopState.new()
	check(expected_slot.load_from(scene.save_path).is_empty(), "independent native decoder reads the isolated saved state")
	key(scene,KEY_Z); focus._records["discarded_fixture"]=Rules.observation("discarded_fixture","Discarded observation","contact","test-observer",Vector3.ZERO,0)
	scene._load()
	scene.avatar.set_physics_process(false)
	check(not focus.active and focus.observations().is_empty() and focus.predictions().is_empty() and focus.sound_cues().is_empty(), "successful native load clears transient Focus and discarded-attempt observations")
	check(scene.model.snapshot()==expected_slot.snapshot() and scene.model.journal()==journal and FileAccess.get_file_as_string(scene.save_path)==saved_bytes, "native load retains the independently decoded campaign, journal and saved bytes, independent of Focus")
	key(scene,KEY_Z); focus._pending["retry_fixture"]=0
	scene._apply()
	check(not focus.active and focus._pending.is_empty() and focus._tick==-1, "native whole-state apply interrupts Focus and resets sensor time")
	home.queue_free(); await frames()

func run() -> void:
	var provided := OS.get_environment("GROUND_FOCUS_OUTPUT")
	if not provided.is_empty(): output=provided
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var home: Node3D=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.set_physics_process(false)
	scene.set_process_unhandled_input(false)
	root.add_child(home); await frames(8)
	await visual_checks(scene)
	await motion_checks(scene)
	await audio_checks(scene)
	await scope_checks(scene)
	home.queue_free(); await frames()
	await integration_checks()
	var file:=FileAccess.open(output.path_join("ground-focus-checks.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"schema":"1792.ground-focus-native-checks.v1","passed":passed,"failed":failed,"checks":checks,"engine":Engine.get_version_info().string,"native_physics":true,"fixtures":"synthetic observations on real Home visibility and interaction policies"},"\t",true,true)); file.close()
	print("GROUND_FOCUS_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
