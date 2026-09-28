extends SceneTree
const Model := preload("res://childhood/childhood_state.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Names := preload("res://characters/character_names.gd")
const SAVE := "user://childhood-regression-only.json"
var passed := 0
var failed := 0
var saved_precursor: Dictionary

func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
func ok(error: String, label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(),label+" refused")
	check(model.snapshot()==before,label+" leaves state unchanged")
func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
func tap(scene, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=true
	scene._unhandled_input(event)
	await frames(2)
func fixture_pose(model, p: Vector3) -> void:
	# Explicit domain-only setup, never used in the full input-driven journey.
	var s: Dictionary = model.snapshot()
	s.player.position=Model.coords(p)
	s.actors[Names.HERO_ID].position=Model.coords(p)
	ok(model.restore(s),"install domain pose fixture")
func _domain() -> void:
	var model := Model.new()
	ok(model.validate(model.snapshot()),"initial home profile")
	check(model.stage()=="orientation","starts at practice, not a battlefield")
	check(model.snapshot().player.character_id=="ranjit_singh","retains hero identity")
	check(model.journal().is_empty(),"no secret world facts in initial memories")
	reject(model,model.start_ambush,"ambush before practice")
	reject(model,model.mount,"mount before briefing")
	reject(model,model.hear.bind("steward"),"reading without acquired document")
	reject(model,model.record_position.bind(Vector3(20,0.14,20),1.0/60),"teleport sample")
	reject(model,model.record_position.bind(Vector3(NAN,0,0),1.0/60),"nonfinite motion")
	fixture_pose(model,Model.SITES.letter+Vector3.RIGHT*1.5)
	ok(model.inspect_letter(),"acquire message")
	check(model.journal().size()==1 and model.journal()[0].channel=="observed","seeing a letter is not reading its words")
	ok(model.hear("courier"),"hear attributed testimony")
	reject(model,model.hear.bind("courier"),"repetition is not new corroboration")
	var altered: Dictionary = model.snapshot()
	altered.childhood.memories[1].text="An enemy house definitely ordered an ambush."
	reject(model,model.restore.bind(altered),"tampered testimony")
	altered=model.snapshot()
	altered.childhood.memories[0].text="I know which household ordered an ambush."
	reject(model,model.restore.bind(altered),"invented firsthand certainty")
	altered=model.snapshot()
	altered.childhood.memories[0].received_tick=10
	reject(model,model.restore.bind(altered),"future observation")
	altered=model.snapshot()
	altered.childhood.ride_gate=1
	reject(model,model.restore.bind(altered),"skip briefing")
	altered=model.snapshot()
	altered.childhood.tick=true
	reject(model,model.restore.bind(altered),"boolean simulation clock")
	altered=model.snapshot()
	altered.childhood.tracks=0.5
	reject(model,model.restore.bind(altered),"fractional lesson progress")
	altered=model.snapshot()
	altered.profile="command-story.v1"
	reject(model,model.restore.bind(altered),"other profile save")
	altered=model.snapshot()
	altered.future_knowledge={"culprit":"fictional"}
	reject(model,model.restore.bind(altered),"extra hidden-state field")
	fixture_pose(model,Model.SITES.reflection+Vector3.LEFT*0.5)
	var before: Dictionary=model.progress()
	ok(model.reflect(),"optional devotional pause")
	check(model.progress().tick==before.tick and model.progress().parries==before.parries and model.progress().tracks==before.tracks,"reflection grants no combat or knowledge bonus")
	reject(model,model.reflect,"reflection not a farming loop")
	ok(model.save_to(SAVE),"isolated save")
	var restored:=Model.new()
	ok(restored.load_from(SAVE),"read childhood save")
	check(restored.journal()==model.journal(),"heard voices and provenance survive save")
	check(restored.position().is_equal_approx(model.position()),"saved position restored")
	var detached:=restored.journal()
	detached.clear()
	check(not restored.journal().is_empty(),"memory projection is detached")

func walk(scene,target: Vector3,run: bool=false) -> void:
	var reached:=false
	for _i in range(1600):
		var d: Vector3=target-scene.avatar.global_position
		d.y=0
		if d.length()<0.65:
			reached=true
			break
		scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
		Input.action_press("move_forward")
		if run: Input.action_press("sprint")
		await physics_frame
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await frames(12)
	check(reached,"input walk to "+str(target)+" from "+str(scene.avatar.global_position))
func drive(scene,target: Vector3) -> void:
	var reached:=false
	for _i in range(1600):
		var d: Vector3=target-scene.horse.global_position
		d.y=0
		if d.length()<1.2 and scene.horse.speed<0.3:
			reached=true
			break
		var desired:=atan2(-d.x,-d.z)
		var error: float=wrapf(desired-scene.horse.rotation.y,-PI,PI)
		var stopping: float=scene.horse.speed*scene.horse.speed/18.0+0.7
		Input.action_release("move_forward")
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(error)<0.4 and d.length()>stopping: Input.action_press("move_forward")
		if error>0.03: Input.action_press("move_left",minf(error*3.0,1.0))
		if error< -0.03: Input.action_press("move_right",minf(-error*3.0,1.0))
		await physics_frame
	for action in ["move_forward","move_left","move_right"]: Input.action_release(action)
	await frames(15)
	check(reached,"physical horse course reaches "+str(target))
func look_at(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)

func _journey() -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	root.add_child(home)
	await frames(6)
	check(not scene.avatar.get_node("HomeIdentity").visible,"tutorial owns HUD without duplicate nameplate")
	check(scene._hud.text.contains("BUDDH SINGH"),"inner name remains Buddh")
	check(scene.save_path!=Model.SAVE_PATH,"test save is isolated")
	# No pose or progression injection after launch: keyboard movement and actual horse physics.
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(130,0)
	for _i in range(3):
		scene.avatar._unhandled_input(motion)
		scene._unhandled_input(motion)
	await walk(scene,Vector3(0,0,-7))
	check(scene.model.stage()=="letter","walk and view practice precede reading")
	await walk(scene,Vector3(-2.5,0,3))
	await tap(scene,KEY_E)
	check(scene.model.progress().letter_seen,"E acquires letter physically")
	await tap(scene,KEY_E)
	check(scene.model.progress().heard==["courier"],"courier account attributed")
	await walk(scene,Vector3(-2,0,0))
	await walk(scene,Vector3(-10,0,0))
	await walk(scene,Vector3(-10.5,0,5))
	await tap(scene,KEY_E)
	check(scene.model.stage()=="riding","two oral accounts open riding")
	await walk(scene,Vector3(-10,0,0))
	await walk(scene,Vector3(4,0,-4))
	await walk(scene,Vector3(6.3,0,-5))
	await tap(scene,KEY_F)
	check(scene.model.mounted(),"mount reuses existing horse")
	check(not scene.avatar.is_physics_processing(),"one mounted motion executor")
	for gate in Model.GATES: await drive(scene,gate)
	check(scene.model.progress().ride_gate==3,"all three physical gates")
	await tap(scene,KEY_F)
	check(not scene.model.mounted(),"dismount before sparring")
	await walk(scene,Vector3(-14,0,-3))
	look_at(scene,Model.SITES.spar)
	key(KEY_Q,true)
	await frames(320)
	key(KEY_Q,false)
	check(scene.model.progress().parries==2,"actual guard input checks telegraphed practice strikes")
	for _i in range(160):
		if int(scene.model.progress().tick)%150>123:
			var strike:=InputEventMouseButton.new()
			strike.button_index=MOUSE_BUTTON_LEFT
			strike.pressed=true
			scene._unhandled_input(strike)
			await frames(2)
			break
		await physics_frame
	check(scene.model.stage()=="tracking","counter opens hunting lesson")
	for i in range(1,4):
		var at: Vector3=Model.SITES["track_%d"%i]
		await walk(scene,at+Vector3(0,0,2.2))
		look_at(scene,at)
		await tap(scene,KEY_E)
		check(scene.model.progress().tracks==i,"physical sight and inspection of track "+str(i))
	key(KEY_C,true)
	await walk(scene,Vector3(13,0,-18.5))
	look_at(scene,Model.SITES.quarry)
	await tap(scene,KEY_E)
	key(KEY_C,false)
	check(scene.model.stage()=="ready","quiet quarry observation precedes ambush")
	saved_precursor=scene.model.snapshot()
	ok(scene.model.validate(saved_precursor),"complete lessons are domain-consistent")
	scene._open_journal()
	var paused: Dictionary=scene.model.snapshot()
	await frames(15)
	check(scene.model.snapshot()==paused,"journal pauses world and practice clock")
	await tap(scene,KEY_F4)
	check(scene.model.snapshot()==paused and not scene._veil.visible,"clear viewport mode changes no state or knowledge")
	await tap(scene,KEY_F4)
	check(scene._veil.visible,"subjective framing is reversible")
	ok(scene.model.save_to(SAVE),"save before return attempt")
	scene._resume()
	await walk(scene,Model.SITES.bend)
	check(scene.model.stage()=="active","return bend triggers first authored attack only after lessons")
	await walk(scene,Model.SITES.home,true)
	check(scene.model.stage()=="escaped","actual movement escapes to the courtyard")
	ok(scene.model.validate(scene.model.snapshot()),"escaped chapter valid")
	check(scene.model.journal().back().text.contains("do not") or scene.model.journal().back().text.contains("does not"),"survival does not reveal conspiracy")
	# Load old precursor through staged scene loading, not just a domain restore.
	scene._load_requested=true
	await frames(1)
	check(scene.model.stage()=="ready","save resumes before ambush without losing lessons")
	check(scene.model.progress().heard.size()==2,"oral accounts remain known")
	# Wall LOS is tested separately from the input-driven journey.
	var wall=scene._box(Vector3(4,3,0.2),scene.avatar.global_position+Vector3(0,1,-1),Color.GRAY,true).get_parent()
	look_at(scene,scene.avatar.global_position+Vector3(0,0,-4))
	await frames(2)
	check(not scene._seen(scene.avatar.global_position+Vector3(0,1,-3),5),"third-person camera cannot inspect through a wall")
	wall.queue_free()
	await frames(2)
	scene._open_journal()
	paused=scene.model.snapshot()
	var bad: Dictionary=paused.duplicate(true)
	bad.player.position=Model.coords(Model.SITES.steward)
	bad.actors[Names.HERO_ID].position=bad.player.position.duplicate()
	ok(scene.model.validate(bad),"blocked pose deliberately domain-valid")
	var f:=FileAccess.open(SAVE,FileAccess.WRITE)
	f.store_string(JSON.stringify(bad,"",true,true))
	f.close()
	scene._load_requested=true
	await frames(1)
	check(scene.model.position().is_equal_approx(Model.point(paused.player.position)),"blocked save does not partially replace position")
	check(scene._message.contains("unchanged"),"spatial refusal explained")
	home.queue_free()
	await process_frame

func _encounter_fixture() -> void:
	# Separate controlled encounter fixture, not evidence of another played full journey.
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	root.add_child(home)
	await frames(5)
	var s:=saved_precursor.duplicate(true)
	s.player.position=[8.0,0.14,-13.0]
	s.actors[Names.HERO_ID].position=s.player.position.duplicate()
	ok(scene.model.restore(s),"restore explicit encounter fixture")
	scene._apply()
	await frames(2)
	check(scene.model.stage()=="active","fixture encounter starts")
	look_at(scene,scene.attacker.global_position)
	key(KEY_Q,true)
	for _i in range(480):
		look_at(scene,scene.attacker.global_position)
		if scene.model.progress().ambush.stun_until>scene.model.progress().tick: break
		await physics_frame
	key(KEY_Q,false)
	check(scene.model.progress().ambush.hits==0 and scene.model.progress().ambush.stun_until>scene.model.progress().tick,"guard physically checks the nearby attacker")
	scene._strike_requested=true
	await frames(2)
	check(scene.model.progress().ambush.deflected,"counter creates an escape opening")
	var before: Dictionary=scene.model.snapshot()
	await frames(240)
	check(scene.model.progress().ambush.hits==before.childhood.ambush.hits,"deflected attacker stops striking")
	ok(scene.model.validate(scene.model.snapshot()),"guard/counter result persists consistently")
	home.queue_free()
	await process_frame

func _menu_lifecycle() -> void:
	# Exercise the actual menu signal and deferred scene handoff, not only make_world().
	for _i in range(2):
		var menu = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		var first: Button
		for button in menu.find_children("*", "Button", true, false):
			if button.text.contains("Home territory"): first = button
		check(first != null, "existing home menu entry found")
		if first == null: return
		first.pressed.emit()
		await frames(6)
		check(current_scene != menu and current_scene.scene_file_path == "res://world/home_territory.tscn", "menu composes original home scene")
		check(current_scene.has_node("ChildhoodChapter"), "one chapter director attached on entry")
		check(not current_scene.get_node("Player/HomeIdentity").visible, "legacy nameplate is hidden, not stacked")
		current_scene.queue_free()
		current_scene = null
		await frames(2)

func _run() -> void:
	_domain()
	await _menu_lifecycle()
	await _journey()
	if not saved_precursor.is_empty() and saved_precursor.childhood.quarry_seen: await _encounter_fixture()
	for suffix in ["", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("CHILDHOOD_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
