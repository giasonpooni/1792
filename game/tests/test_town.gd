extends SceneTree
## Initial-state fixtures are explicit; the town tour thereafter uses real input/collision motion.
const Town:=preload("res://settlement/town_state.gd")
const Layout:=preload("res://settlement/town_layout.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Checkpoint:=preload("res://childhood/checkpoint_store.gd")
const SAVE:="user://town-regression-only.json"
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func same_retained(a: Variant,b: Variant) -> bool:
	# Identity/tick strings and normalized ints stay exact. Floating poses tolerate only
	# JSON double-rounding, not gameplay differences or missing fields.
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_retained(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same_retained(a[i],b[i]): return false
		return true
	if a is float or b is float:
		return Base.Riding.finite_number(a) and Base.Riding.finite_number(b) and absf(a-b)<=1e-12
	return typeof(a)==typeof(b) and a==b
func reject(model,action: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(action.call()).is_empty(),label+" refuses")
	check(model.snapshot()==before,label+" preserves state")
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,p: Vector3) -> void:
	var d: Vector3=p-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
func tap(scene,key: Key) -> void:
	var e:=InputEventKey.new();e.keycode=key;e.pressed=true
	scene._unhandled_input(e);await frames(2)
func walk(scene,p: Vector3) -> void:
	var reached:=false
	for _i in range(1300):
		if Base.distance(scene.avatar.global_position,p)<0.45: reached=true;break
		look(scene,p);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(8)
	if not reached: print("TOWN WALK DIAG ",scene.avatar.global_position," -> ",p," message ",scene._message)
	check(reached,"physical route "+str(p))
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
	if not reached: print("TOWN RIDE DIAG ",scene.horse.global_position," -> ",target," ",scene._message)
	check(reached,"physical horse course reaches "+str(target))
func fresh() -> Town:
	var s:=Town.new();ok(s.restore(Fixture.complete()),"completed inquiry fixture")
	return s
func _domain() -> void:
	var s:=Town.new()
	ok(s.validate(s.snapshot()),"new world valid")
	check(not s.snapshot().has("settlement"),"early checkpoint format retained")
	check(s.settlement().visits.is_empty(),"unvisited town has no observations")
	reject(s,s.observe_landmark.bind("well"),"no remote or premature observation")
	check(Base.valid_point([-27,0.14,-27]) and not Base.valid_point([-40,0.14,-42]),"original core domain unchanged")
	check(not Base.new().valid_player_point([-40,0.14,-42]),"original runtime keeps original envelope")
	check(s.valid_player_point([-40,0.14,-42]),"town opts into declared larger envelope")
	var p:=s.snapshot();p.player.position=[-40,0.14,-42];p.actors.ranjit_singh.position=p.player.position.duplicate()
	reject(s,s.restore.bind(p),"legacy pose cannot silently acquire expanded domain")
	p.settlement=Layout.initial();reject(s,s.restore.bind(p),"identity marker cannot bypass childhood gate")
	s=fresh();check(s.district_open(),"completed inquiry opens town")
	check(not s.has_economy() and not s.has_remounts(),"town creates no allowance or remount mission")
	reject(s,s.observe_landmark.bind("missing"),"undeclared site")
	reject(s,s.observe_landmark.bind("well"),"remote well")
	ok(Pose.pose(s,Vector3(-20.7,0.14,-42)),"domain-only observer pose")
	ok(s.observe_landmark("well"),"local observation")
	reject(s,s.observe_landmark.bind("well"),"no duplicate observation")
	var visit: Dictionary=s.settlement();visit.visits.clear();check(s.settlement().visits.size()==1,"detached receipt read")
	check(s.journal().back().source_id=="self" and s.journal().back().channel=="observed","firsthand provenance")
	check(s.snapshot().player.known_places==["sukerchakia_home"],"original geographic knowledge contract retained")
	for mutation in ["future","duplicate","far","id","map","seed","text","fractional","unknown_key"]:
		var bad:=s.snapshot()
		match mutation:
			"future": bad.settlement.visits[0].tick=bad.childhood.tick+1
			"duplicate": bad.settlement.visits.append(bad.settlement.visits[0].duplicate(true))
			"far": bad.settlement.visits[0].position=[0,0.14,0]
			"id": bad.settlement.visits[0].id="samadhi_1835"
			"map": bad.settlement.map_id="surveyed_city"
			"seed": bad.settlement.seed+=1
			"text": bad.settlement.visits[0].text="Forged testimony"
			"fractional": bad.settlement.visits[0].tick+=0.5
			"unknown_key": bad.settlement.extra=true
		reject(s,s.restore.bind(bad),"tamper "+mutation)
	for bad_point in [[-59,0,-42],[29,0,-42],[-40,0,-81],[-40,0,29],[true,0,0],[0,NAN,0]]:
		check(not Layout.valid_position(bad_point),"finite declared extent "+str(bad_point))
	p=s.snapshot();p.erase("settlement");reject(s,s.restore.bind(p),"extended pose cannot masquerade as old save")
	ok(s.save_to(SAVE),"town save")
	var load:=Town.new();ok(load.load_from(SAVE),"town JSON roundtrip")
	check(same_retained(load.settlement(),s.settlement()),"retained local observation exact")
	ok(load.restore(Pose.precursor()),"earlier checkpoint compatible")
	check(load.settlement().visits.is_empty() and not load.district_open(),"rollback removes future places and closes gate")
	check(not load.snapshot().has("settlement"),"no checkpoint schema change")
	check(Layout.manifest()==Layout.manifest(),"deterministic layout declaration")
	check(Layout.manifest().later_monuments.is_empty() and not Layout.manifest().georeferenced,"no later monuments or survey claim")

func _geometry_and_gates() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	root.add_child(home);await frames(6)
	check(scene.town.compound_nodes.size()==7,"seven courtyard compounds built")
	check(scene.town.landmarks.size()==5,"five observation anchors built")
	check(scene.town.crop_instances==360,"bounded instanced field detail")
	for gate in scene.town.gates: check(gate.collision_layer==1 and gate.visible,"early gate physically shut")
	check(not scene._navigation.clear_segment(Vector3(0,0.14,-25),Vector3(0,0.14,-33)),"north exit blocked by actual collider")
	ok(scene.model.restore(Fixture.complete()),"scene migration fixture")
	scene._apply();await frames(5)
	for gate in scene.town.gates: check(gate.collision_layer==0 and not gate.visible,"completed-inquiry gate opens physically")
	check(scene._navigation.clear_segment(Vector3(0,0.14,-25),Vector3(0,0.14,-33)),"north exit clear after inquiry")
	check(scene._navigation.clear_segment(Vector3(-26,0.14,-11),Vector3(-34,0.14,-11)),"west exit clear after inquiry")
	for p in [Vector3(-38,0.14,-11),Vector3(0,0.14,-42),Vector3(-38,0.14,-53),Vector3(0,0.14,-73)]:
		check(scene._fits(p),"expanded standing collision "+str(p))
	check(not scene._fits(Vector3(-55,0.14,-7)),"solid side rooms refuse a blocked standing pose")
	var n: Node3D=scene.town.compound_nodes.potter_court
	var doorway: Vector3=n.to_global(Vector3(0,0.14,7.5))
	check(scene._navigation.clear_segment(doorway+Vector3(2,0,0),doorway-Vector3(2,0,0)),"courtyard doorway is physically open")
	var roof_query:=PhysicsRayQueryParameters3D.create(Vector3(-47,12,-72),Vector3(-47,-2,-72),1)
	check(not scene.get_world_3d().direct_space_state.intersect_ray(roof_query).is_empty(),"collision geometry present under new architecture")
	# Explicit isolated pose fixture for actual static occlusion, not proof of player travel.
	ok(Pose.pose(scene.model,Vector3(-20.7,0.14,-42)),"visibility fixture")
	scene._apply();await frames(4);look(scene,Layout.SITES.well.point)
	var obstacle=scene._box(Vector3(0.3,3,3),Vector3(-21.6,1.5,-42),Color.GRAY,true).get_parent()
	await frames(4);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.is_empty(),"physics obstruction prevents place observation")
	obstacle.queue_free();await frames(4)
	await tap(scene,KEY_E);check(scene.model.settlement().visits.size()==1,"unobstructed place observed")
	var frozen: Dictionary=scene.model.snapshot();await frames(20)
	check(scene.model.snapshot()==frozen,"place panel pauses the single world clock")
	scene._resume()
	# Expanded snapshots cannot load into solid building volumes; refusal preserves the live world.
	var bad: Dictionary=scene.model.snapshot();bad.player.position=[-55,0.14,-7];bad.actors.ranjit_singh.position=bad.player.position.duplicate()
	var staged:=Town.new();ok(staged.restore(bad),"domain-only blocked-pose fixture")
	check(not scene._candidate_error(staged).is_empty(),"scene rejects valid-shaped but obstructed save")
	scene._open_places();var before: Dictionary=scene.model.snapshot()
	ok(staged.save_to(SAVE),"write isolated spatial-load fixture")
	scene._load()
	check(scene.model.snapshot()==before,"actual scene load refuses obstruction before replacing world")
	ok(scene.model.restore(Pose.precursor()),"restore earlier whole-world checkpoint state")
	scene._apply();await frames(4)
	check(scene.town.gates[0].collision_layer==1 and scene.model.settlement().visits.is_empty(),"whole-world rollback closes gates and discards later discoveries")
	home.queue_free();await frames(5)

func _tour() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"only initial tour fixture; no pose injection after launch")
	root.add_child(home);await frames(6)
	for p in [Vector3(2,0,-10),Vector3(0,0,-23),Vector3(0,0,-34),Vector3(0,0,-42),Vector3(-20.7,0,-42)]: await walk(scene,p)
	look(scene,Layout.SITES.well.point);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.size()==1,"input-driven well discovery")
	scene._resume()
	for p in [Vector3(-20,0,-39),Vector3(-35,0,-39),Vector3(-38,0,-45),Vector3(-43,0,-45)]: await walk(scene,p)
	look(scene,Layout.SITES.potter.point);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.size()==2,"walked through pottery doorway and examined")
	scene._resume();await tap(scene,KEY_F5)
	var saved: Dictionary=scene.model.snapshot();await frames(8);await tap(scene,KEY_F9)
	check(same_retained(scene.model.settlement().visits,saved.settlement.visits),"mid-town save/load keeps observations")
	check(Base.distance(scene.model.position(),Base.point(saved.player.position))<0.1,"mid-town save/load restores expanded physical pose")
	for p in [Vector3(-38,0,-45),Vector3(-38,0,-53),Vector3(14,0,-53),Vector3(14,0,-55.9)]: await walk(scene,p)
	look(scene,Layout.SITES.cloth.point);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.size()==3,"cloth courtyard discovery")
	scene._resume()
	for p in [Vector3(14,0,-53),Vector3(-13,0,-53),Vector3(-13,0,-61.5)]: await walk(scene,p)
	look(scene,Layout.SITES.grain.point);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.size()==4,"grain courtyard discovery")
	scene._resume()
	for p in [Vector3(-13,0,-53),Vector3(0,0,-53),Vector3(0,0,-73),Vector3(14,0,-73)]: await walk(scene,p)
	look(scene,Layout.SITES.orchard.point);await tap(scene,KEY_E)
	check(scene.model.settlement().visits.size()==5,"cultivated edge discovery")
	scene._resume();await tap(scene,KEY_M)
	check(scene._panel_text.text.contains("well square") and scene._panel_text.text.contains("cultivated edge"),"remembered places panel reflects actual visits")
	scene._resume()
	for p in [Vector3(0,0,-73),Vector3(0,0,-53),Vector3(-38,0,-53),Vector3(-38,0,-11),Vector3(-24,0,-11),Vector3(2,0,-10),Vector3(3,0,4)]: await walk(scene,p)
	check(Base.valid_point(Base.coords(scene.model.position())),"returned to unchanged household through west gate")
	check(not scene.model.has_economy() and not scene.model.has_remounts(),"scenery creates no supplies or extra horses")
	ok(scene.model.validate(scene.model.snapshot()),"complete physical tour valid")
	var file:=FileAccess.open("user://town-tour-trace.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"automated_input_driven_tour_after_explicit_inquiry_fixture","map":Layout.manifest(),"world":scene.model.snapshot()},"",true,true));file.close()
	home.queue_free();await frames(5)

func _riding() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(Fixture.complete()),"riding starts from declared completed-inquiry fixture")
	root.add_child(home);await frames(5)
	for p in [Vector3(4,0,-4),Vector3(6.3,0,-5)]: await walk(scene,p)
	await tap(scene,KEY_F)
	check(scene.model.mounted() and not scene.avatar.is_physics_processing(),"same existing horse is sole mounted executor")
	for p in [Vector3(8,0,-18),Vector3(0,0,-18),Vector3(0,0,-34),Vector3(0,0,-42)]: await drive(scene,p)
	check(scene.model.position().z< -30,"actual horse crossed north gate into town")
	await tap(scene,KEY_F5);var saved: Dictionary=scene.model.snapshot();await frames(6);await tap(scene,KEY_F9)
	check(scene.model.mounted() and Base.distance(scene.model.position(),Base.point(saved.player.position))<0.1,"mounted expanded save/load restores one bound rider")
	await tap(scene,KEY_F)
	check(not scene.model.mounted(),"safe dismount in town")
	ok(scene.model.validate(scene.model.snapshot()),"dismounted expanded horse save validates")
	home.queue_free();await frames(5)

func _run() -> void:
	_domain();await _geometry_and_gates();await _tour();await _riding()
	for p in [SAVE,SAVE+".tmp",SAVE+".checkpoint.json"]:
		if FileAccess.file_exists(p): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("TOWN_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
