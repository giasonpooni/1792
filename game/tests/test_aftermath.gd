extends SceneTree
const Story := preload("res://childhood/aftermath_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Checkpoint := preload("res://childhood/checkpoint_store.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const SAVE := "user://aftermath-regression-only.json"
const CP := SAVE + ".checkpoint.json"
var passed := 0
var failed := 0
var final_escort: Dictionary
var final_alone: Dictionary

func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: "+label)
func ok(error: String, label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(),label+" refused")
	check(model.snapshot() == before,label+" leaves state unchanged")
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
func tap(scene, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	scene._unhandled_input(e)
	await frames(2)
func press(scene, text: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(text):
			button.pressed.emit()
			await frames(2)
			return
	check(false,"button not found: "+text)
func look(scene, p: Vector3) -> void:
	var d: Vector3 = p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y = atan2(-d.x,-d.z)
func walk(scene, p: Vector3) -> void:
	var reached := false
	for _i in range(1400):
		if Base.distance(scene.avatar.global_position,p) < 0.6:
			reached = true
			break
		look(scene,p)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(12)
	check(reached,"input-driven walk to "+str(p))

func _domain() -> void:
	var model := Story.new()
	ok(model.validate(model.snapshot()),"new additive profile")
	check(model.aftermath_phase() == "dormant","aftermath not available before survival")
	reject(model,model.hear_return.bind("courier"),"pre-ambush hearing")
	reject(model,model.decide_protection.bind("household_escort"),"unheard offer")
	reject(model,model.inspect_bend,"pre-decision investigation")
	ok(model.restore(Fixture.survived()),"legacy escaped snapshot migrates without new memories")
	check(model.aftermath_phase() == "accounts" and model.aftermath().memories.is_empty(),"migration invents no events")
	check(model.snapshot().player.character_id == "ranjit_singh","Buddh keeps stable actor key")
	ok(Fixture.pose(model,Story.MOTHER+Vector3.RIGHT),"explicit conversation fixture")
	reject(model,model.hear_offer,"offer requires return accounts")
	for speaker in ["steward","courier"]:
		ok(Fixture.pose(model,Base.SITES[speaker]+Vector3.RIGHT),"speaker pose fixture")
		ok(model.hear_return(speaker),"return testimony: "+speaker)
		reject(model,model.hear_return.bind(speaker),"duplicate witness")
	ok(Fixture.pose(model,Story.MOTHER+Vector3.RIGHT),"offer pose")
	ok(model.hear_offer(),"Raj Kaur's offer remembered")
	reject(model,model.decide_protection.bind("accuse_house"),"invented conspiracy decision")
	ok(model.decide_protection("household_escort"),"escort agreement")
	reject(model,model.decide_protection.bind("independent_inquiry"),"cannot switch after agreement")
	check(model.aftermath().escort.active,"agreed escort deployed once")
	var receipt: Dictionary = model.aftermath().escort
	var motion := {"id":receipt.id,"position":receipt.position.duplicate(),"yaw":0.0,"velocity":[0.0,0.0,0.0]}
	ok(model.record_escort(motion,1.0/60),"bounded stationary escort sample")
	motion.position = [25.0,0.14,25.0]
	reject(model,model.record_escort.bind(motion,1.0/60),"teleport escort")
	motion.position = receipt.position.duplicate()
	motion.yaw = NAN
	reject(model,model.record_escort.bind(motion,1.0/60),"nonfinite escort")
	ok(Fixture.pose(model,Story.CLUE),"domain clue setup")
	reject(model,model.inspect_bend,"guard must actually attend inspection")
	reject(model,model.order_escort.bind("follow"),"no distant telepathic order")
	var value := model.snapshot()
	value.aftermath.escort.position = Base.coords(Story.CLUE+Vector3.RIGHT*2)
	ok(model.restore(value),"explicit unit fixture of arrived guard")
	ok(model.order_escort("hold"),"nearby hold")
	motion = {"id":receipt.id,"position":Base.coords(Story.CLUE+Vector3.RIGHT*2.01),"yaw":0.0,"velocity":[0.5,0.0,0.0]}
	reject(model,model.record_escort.bind(motion,1.0/60),"held escort cannot advance")
	ok(model.inspect_bend(),"observed clue with escort")
	reject(model,model.inspect_bend,"no duplicated clue")
	reject(model,model.report_home,"no remote report")
	ok(Fixture.pose(model,Story.MOTHER+Vector3.RIGHT),"unit return pose")
	reject(model,model.report_home,"cannot abandon agreed escort on return")
	value = model.snapshot()
	value.aftermath.escort.position = Base.coords(Story.MOTHER+Vector3.RIGHT*3)
	ok(model.restore(value),"explicit arrived return fixture")
	ok(model.report_home(),"oral report")
	check(model.aftermath_phase() == "complete" and not model.aftermath().escort.active,"escort retired once at check-in")
	reject(model,model.report_home,"cannot farm report")
	check(model.journal().back().text.contains("unidentified"),"report does not reveal a mastermind")
	ok(model.save_to(SAVE),"save aftermath")
	var restored := Story.new()
	ok(restored.load_from(SAVE),"aftermath save round trip")
	check(restored.aftermath() == model.aftermath(),"agreement and exact memories survive JSON")
	var detached := restored.aftermath()
	detached.heard.clear()
	check(restored.aftermath().heard.size() == 2,"read API detached")
	for kind in ["future","text","source","order","id","decision","deployment","extra","false_observation"]:
		var bad := model.snapshot()
		match kind:
			"future": bad.aftermath.memories[0].received_tick = bad.childhood.tick + 1
			"text": bad.aftermath.memories[0].text = "A named house ordered it."
			"source": bad.aftermath.memories[0].source_id = "self"
			"order": bad.aftermath.memories.reverse()
			"id": bad.aftermath.escort.id = "second_hero"
			"decision": bad.aftermath.decision_tick = 0.5
			"deployment": bad.aftermath.escort.active = true
			"extra": bad.aftermath.hidden_culprit = "invented"
			"false_observation": bad.aftermath.clue_tick = -1
		reject(model,model.restore.bind(bad),"tampered "+kind)

func _journey(choice: String) -> void:
	# Start from a declared survived-tutorial fixture; no pose/progress injection after departure.
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(Fixture.survived()),"install survived opening fixture")
	root.add_child(home)
	await frames(5)
	check(scene.model.aftermath_phase() == "accounts","aftermath appears in same chapter")
	check(scene._hud.text.contains("steward") and scene._mother.get_parent().visible,"aftermath guidance and Raj Kaur visible")
	await walk(scene,Vector3(-10,0,2))
	await walk(scene,Vector3(-10.5,0,5))
	look(scene,Base.SITES.steward)
	await tap(scene,KEY_E)
	check(scene._paused and scene.model.aftermath().heard == ["return_steward"],"physical E conversation records one account")
	var paused: Dictionary = scene.model.snapshot()
	await frames(20)
	await tap(scene,KEY_G)
	check(scene.model.snapshot() == paused,"conversation pauses world and ignores orders")
	await press(scene,"Remember")
	await walk(scene,Vector3(-7,0,2))
	await walk(scene,Vector3(-5.6,0,3))
	look(scene,Base.SITES.courier)
	await tap(scene,KEY_E)
	check(scene.model.aftermath().heard.size() == 2,"second witness reached on foot")
	await press(scene,"Remember")
	await walk(scene,Story.MOTHER+Vector3(0,0,-1.8))
	look(scene,Story.MOTHER)
	await tap(scene,KEY_E)
	check(scene._paused and scene._panel_text.text.contains("PROTECTION"),"Raj Kaur opens actual choice interface")
	await press(scene,"Accept" if choice == "household_escort" else "Insist")
	check(scene.model.aftermath().decision == choice,"button commits selected agreement")
	if choice == "household_escort":
		await frames(50)
		await tap(scene,KEY_G)
		check(scene.model.aftermath().escort.instruction == "hold","G gives nearby hold")
		var at: Vector3 = scene.escort.global_position
		await walk(scene,Vector3(1,0,3))
		check(Base.distance(scene.escort.global_position,at) < 0.001,"held guard stays behind physically")
		await walk(scene,Vector3(-4,0,5))
		await tap(scene,KEY_G)
		check(scene.model.aftermath().escort.instruction == "follow","G regroups on return within range")
	# Avoid the stable's posts; physical pathfinding should carry the guard around them.
	await walk(scene,Vector3(2,0,-2))
	await walk(scene,Vector3(3,0,-12))
	await walk(scene,Story.CLUE+Vector3(0,0,2))
	await frames(70)
	look(scene,Story.CLUE)
	await tap(scene,KEY_E)
	check(scene.model.aftermath_phase() == "return","actual bend inspection advances inquiry")
	check(scene.model.aftermath().clue_tick >= scene.model.aftermath().decision_tick,"causal clue timestamp")
	if choice == "household_escort": check(Base.distance(scene.escort.global_position,Story.CLUE) < 6,"escort physically arrives at clue")
	else: check(not scene.escort.visible,"independent route has no free guard")
	# Mid-return persistence goes through the scene's staging pipeline.
	await tap(scene,KEY_F5)
	var saved: Dictionary = scene.model.snapshot()
	await walk(scene,Vector3(3,0,-8))
	await tap(scene,KEY_F9)
	check(scene.model.position().is_equal_approx(Base.point(saved.player.position)),"scene load restores saved return pose")
	check(scene.model.aftermath().decision == choice and scene.model.aftermath_phase() == "return","save retains branch")
	await walk(scene,Vector3(2,0,1))
	await walk(scene,Story.MOTHER+Vector3(0,0,-1.8))
	await frames(80)
	look(scene,Story.MOTHER)
	await tap(scene,KEY_E)
	await press(scene,"Give")
	check(scene.model.aftermath_phase() == "complete","full physical aftermath route completes")
	ok(scene.model.validate(scene.model.snapshot()),"complete world validates")
	check(not scene.model.aftermath().escort.active,"escort not duplicated after report")
	if choice == "household_escort": final_escort = scene.model.snapshot()
	else: final_alone = scene.model.snapshot()
	home.queue_free()
	await frames(2)

func _checkpoints() -> void:
	# Staged predecessor fixture. Actual E observes quarry, captures checkpoint and triggers an attack.
	var home := Launch.make_world()
	var scene = home.get_node("ChildhoodChapter")
	scene.save_path = SAVE
	ok(scene.model.restore(Fixture.precursor()),"install late-lesson checkpoint fixture")
	root.add_child(home)
	await frames(5)
	look(scene,Base.SITES.quarry)
	key(KEY_C,true)
	await tap(scene,KEY_E)
	key(KEY_C,false)
	check(scene.model.stage() == "ready","quarry inspection completed")
	check(FileAccess.file_exists(CP) and scene._checkpoint_note.contains("saved"),"automatic pre-ambush checkpoint written")
	var checkpoint := Checkpoint.read(CP)
	check(checkpoint.error.is_empty() and checkpoint.envelope.reason == "return_trail","checkpoint reason and schema")
	var checkpoint_bytes := FileAccess.get_file_as_bytes(CP)
	ok(scene.model.save_to(SAVE),"manual save alongside checkpoint")
	var manual_bytes := FileAccess.get_file_as_bytes(SAVE)
	await walk(scene,Base.SITES.bend)
	await frames(620) # Real approach/strike cycles, not take_hit injections.
	check(scene.model.stage() == "caught" and scene._paused,"three actual strikes open recovery")
	check(scene._panel_text.text.contains("ATTEMPT ENDED"),"recovery screen visible")
	await tap(scene,KEY_F4)
	await tap(scene,KEY_R)
	check(scene.model.stage() == "ready" and not scene._paused,"R restores playable pre-ambush checkpoint")
	check(not scene._veil.visible,"recovery keeps presentation option")
	check(scene.model.progress().ambush.hits == 0 and not scene.model.progress().ambush.seen,"later damage and knowledge rolled back together")
	check(not scene.attacker.visible and scene.attacker.collision_layer == 0,"recovery leaves no ghost assailant")
	check(scene.model.position().is_equal_approx(Base.point(checkpoint.envelope.snapshot.player.position)),"checkpoint restores physical pose")
	check(FileAccess.get_file_as_bytes(SAVE) == manual_bytes,"automatic checkpoint and retry never overwrite manual save")
	# Survive the second attempt through actual movement. The new courtyard checkpoint supersedes it.
	await walk(scene,Base.SITES.bend)
	await walk(scene,Base.SITES.home)
	check(scene.model.stage() == "escaped","retry can escape physically")
	check(Checkpoint.read(CP).envelope.reason == "courtyard_return","survival checkpoint captured")
	check(FileAccess.get_file_as_bytes(SAVE) == manual_bytes,"return checkpoint also preserves manual save")
	# Refused checkpoint cannot partially mutate live state (paused throughout).
	scene._open_journal()
	var before: Dictionary = scene.model.snapshot()
	var corrupt: Dictionary = Checkpoint.read(CP).envelope
	corrupt.snapshot.childhood.memories[0].text = "Forged private knowledge"
	var file := FileAccess.open(CP,FileAccess.WRITE)
	file.store_string(JSON.stringify(corrupt))
	file.close()
	await tap(scene,KEY_R)
	check(scene.model.snapshot() == before,"invalid checkpoint leaves complete live state unchanged")
	check(scene._panel_text.text.contains("NOT RESTORED"),"checkpoint rejection explained")
	# A structurally valid blocked pose is also refused by the scene, not admitted from its schema.
	var parsed := JSON.new()
	parsed.parse(checkpoint_bytes.get_string_from_utf8())
	corrupt = parsed.data
	var p: Array = corrupt.snapshot.player.position
	var obstacle = scene._box(Vector3(2,3,2),Base.point(p)+Vector3.UP,Color.GRAY,true).get_parent()
	file = FileAccess.open(CP,FileAccess.WRITE)
	file.store_buffer(checkpoint_bytes)
	file.close()
	await frames(3)
	await tap(scene,KEY_R)
	check(scene.model.snapshot() == before,"spatially blocked checkpoint does not replace world")
	obstacle.queue_free()
	await frames(2)
	# Domain checkpoint validator refuses active/caught snapshots and invented stages/cameras.
	corrupt.reason = "return_trail"
	corrupt.camera[0] = 4.0
	check(not Checkpoint.validate(corrupt).is_empty(),"checkpoint rejects camera outside input limits")
	home.queue_free()
	await frames(2)

func _run() -> void:
	for path in [SAVE,CP]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_domain()
	await _journey("household_escort")
	await _journey("independent_inquiry")
	check(final_escort.aftermath.decision != final_alone.aftermath.decision,"two distinct agreements")
	check(final_escort.aftermath.memories.back().text == final_alone.aftermath.memories.back().text,"same observed limit, different household arrangement")
	await _checkpoints()
	for path in [SAVE,CP,SAVE+".tmp",CP+".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("AFTERMATH_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
