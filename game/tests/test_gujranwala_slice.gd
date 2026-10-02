extends SceneTree
## Domain setups are declared fixtures; movement after setup uses the real shared motor.
const Launch := preload("res://slice/slice_launch.gd")
const Store := preload("res://slice/continuation_store.gd")
const Guide := preload("res://slice/route_guide.gd")
const State := preload("res://workshops/workshop_state.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const Supply := preload("res://territory/misl_rules.gd")
var passed:=0
var failed:=0
var slot:="user://slice-test-continue.json"
var run_paths: Array[String]=[]
func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error(label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func bytes(path: String) -> String: return FileAccess.get_file_as_string(path)
func write_raw(path: String,text: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(text);file.close()
func fresh():
	var model:=State.new();ok(model.restore(Fixture.complete()),"declared completed-inquiry fixture")
	ok(model.begin_allowance(),"fixture allowance");return model
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func look(scene,at: Vector3) -> void:
	var direction: Vector3=at-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-direction.x,-direction.z)
func tap(scene,key: Key) -> void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true
	scene._unhandled_input(event);await frames(2)
func press(scene,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix): button.pressed.emit();await frames(2);return
	check(false,"missing playable choice "+prefix)
func walk(scene,at: Vector3) -> void:
	var reached:=false
	for _i in range(1400):
		if State.distance(scene.avatar.global_position,at)<0.42: reached=true;break
		look(scene,at);Input.action_press("move_forward");await physics_frame
	Input.action_release("move_forward");await frames(8)
	if not reached: print("SLICE WALK: ",scene.avatar.global_position," -> ",at," / ",scene._message)
	check(reached,"shared-motor walk "+str(at))
func _store_checks() -> void:
	var model=fresh();var run:=Store.new_run_id()
	check(Store.valid_run_id(run),"bounded random run identity")
	check(Store.manual_path(run)!=Store.manual_path(Store.new_run_id()),"fresh run isolates manual and retry paths")
	for bad in ["", "../"+run,run.to_upper(),run+"0",17,null]: check(not Store.valid_run_id(bad),"invalid run id refuses "+str(bad))
	ok(Store.write(slot,run,model.snapshot(),Vector3(-0.2,0.7,0)),"whole-state continuation")
	var value:=Store.read(slot);check(value.error.is_empty(),"read continuation")
	check(Supply._equal(value.envelope.snapshot,model.snapshot()),"snapshot roundtrip exact")
	check(value.envelope.run_id==run and is_equal_approx(value.envelope.camera[0],-0.2) and is_equal_approx(value.envelope.camera[1],0.7),"run and camera retained")
	var original:=bytes(slot)
	for field in ["run_id","camera","schema","snapshot"]:
		var bad: Dictionary=value.envelope.duplicate(true)
		bad[field]="../escape" if field=="run_id" else [INF,0.0] if field=="camera" else "unsupported" if field=="schema" else {}
		check(not Store.validate(bad).is_empty(),"reject corrupt "+field)
	check(bytes(slot)==original,"validation leaves save bytes unchanged")
	check(not Store.write(slot,"../escape",model.snapshot(),Vector3.ZERO).is_empty(),"invalid write refused")
	check(bytes(slot)==original,"invalid write preserves earlier save")
	write_raw(slot,"{broken");check(not Store.read(slot).error.is_empty(),"bad JSON refuses")
	write_raw(slot," ".repeat(Store.LIMIT+1));check(not Store.read(slot).error.is_empty(),"oversized continuation refuses")
	write_raw(slot,original)
	# Pending smith and water share the original deadline/clock; no offline advance.
	ok(model.workshop_action("reserve"),"fixture reserve")
	ok(Pose.pose(model,Craft.SITE),"fixture smith pose");ok(model.workshop_action("start"),"fixture handover")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"fixture store pose");ok(model.begin_water_round(),"fixture water assignment")
	ok(Pose.pose(model,Water.WELL),"fixture well pose");ok(model.water_action("draw"),"fixture pending draw")
	for _i in range(Water.DRAW_TICKS-1): model.advance()
	ok(Store.write(slot,run,model.snapshot(),Vector3.ZERO),"pending water/smith continuation")
	var loaded:=State.new();ok(loaded.restore(Store.read(slot).envelope.snapshot),"pending integrated restore")
	check(Supply._equal(model.snapshot(),loaded.snapshot()),"pending tasks restored without catch-up")
	loaded.advance();check(loaded.water_round().ledger.carried==Water.LOAD,"draw fills on original 180th tick")
	check(loaded.water_round().ledger.remaining+loaded.water_round().ledger.carried+loaded.water_round().ledger.stored==Water.TOTAL,"water conserved after resume")
	ok(Store.write(slot,run,loaded.snapshot(),Vector3.ZERO),"carried water continuation")
	var next:=State.new();ok(next.restore(Store.read(slot).envelope.snapshot),"carried water restore")
	check(Supply._equal(next.snapshot(),loaded.snapshot()),"carried water custody exact")
	var before: Dictionary=next.snapshot();check(not next.mount().is_empty() and next.snapshot()==before,"mount refusal remains atomic after continuation")
	# Guide cannot reveal remote smith readiness or append a fact.
	model=fresh();ok(model.workshop_action("reserve"),"guide reserve")
	ok(Pose.pose(model,Craft.SITE),"guide smith fixture");ok(model.workshop_action("start"),"guide handover")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"guide remote fixture")
	var guide: Dictionary=Guide.inspect(model);var journal: Array=model.journal()
	for _i in range(Craft.WORK_TICKS): model.advance()
	check(model.workshop_phase()=="ready" and Guide.inspect(model)==guide,"remote ready gives identical guide")
	check(model.journal()==journal,"guide does not invent received readiness")
	before=model.snapshot();Guide.text(model);check(before==model.snapshot(),"route read does not mutate authority")
	ok(Pose.pose(model,Craft.SITE),"guide pickup fixture");ok(model.workshop_action("collect"),"guide collected locally")
	check(Guide.inspect(model).next.contains("Carry both tool"),"local pickup advances guidance")
	ok(Store.write(slot,run,model.snapshot(),Vector3.ZERO),"carried tools continuation")
	ok(next.restore(Store.read(slot).envelope.snapshot),"carried tools restore")
	check(next.carrying_workshop() and Supply._equal(next.snapshot(),model.snapshot()),"exact tool custody")
	model=fresh();ok(model.workshop_action("reserve"),"contract-priority reserve")
	ok(Pose.pose(model,Craft.SITE),"contract-priority smith fixture");ok(model.workshop_action("start"),"contract-priority pending work")
	ok(Pose.pose(model,Supply.QUARTERMASTER),"contract-priority household fixture")
	ok(model.begin_water_round(),"contract-priority idle water assignment")
	ok(model.operate("accept_delivery"),"contract-priority accepted cargo")
	check(Guide.inspect(model).active=="other" and Guide.inspect(model).next.contains("supply delivery"),"carried contract precedes idle water and pending smith")
	ok(Pose.pose(model,Supply.MARKET),"contract-priority market fixture");ok(model.operate("deliver"),"contract-priority cargo settlement")
	ok(model.operate("accept_escort"),"contract-priority active caravan")
	check(Guide.inspect(model).active=="other" and Guide.inspect(model).next.contains("active caravan"),"company precedes idle errands")
	ok(model.validate(model.snapshot()),"priority fixtures remain admitted whole state")

func _runtime_checks() -> void:
	var old_slot:=bytes(slot)
	var home:=Launch.make_world("new");var scene=home.get_node("ChildhoodChapter");scene.continuation_path=slot
	var new_id: String=scene.run_id;var new_manual: String=scene.save_path;run_paths.append(new_manual)
	root.add_child(home);current_scene=home;await frames(8)
	check(scene.continuation_ready and scene._paused,"new Slice launch reaches paused courtyard briefing")
	check(scene.model.aftermath_phase()!="complete" and not scene.model.has_economy(),"new run starts actual childhood, no fixture bypass")
	check(Store.read(slot).envelope.run_id==new_id and bytes(slot)!=old_slot,"new accepted visit becomes Continue")
	check(not FileAccess.file_exists(scene.checkpoint_path()) and not FileAccess.file_exists(new_manual+".bazaar-retry.json"),"fresh run has no prior retry")
	var pause: Dictionary=scene.model.snapshot();var saved:=bytes(slot)
	await frames(35);check(scene.model.snapshot()==pause and bytes(slot)==saved,"briefing pauses clock and periodic writes")
	scene._resume();await frames(5)
	var e:=InputEventKey.new();e.keycode=KEY_O;e.pressed=true;scene._unhandled_input(e)
	check(scene._paused and not scene.avatar.input_enabled,"route modal stops body and input")
	pause=scene.model.snapshot();await frames(30);check(scene.model.snapshot()==pause,"route modal freezes complete world")
	scene._interact_requested=true;scene._mount_requested=true;scene._strike_requested=true
	ok(scene.restore_continuation(),"native world Continue restore")
	check(not scene._interact_requested and not scene._mount_requested and not scene._strike_requested,"restore clears pending inputs")
	check(scene.run_id==new_id and scene.save_path==new_manual,"Continue binds the same run paths")
	check(Supply._equal(scene.model.snapshot(),Store.read(slot).envelope.snapshot),"native continuation restores entire world")
	# The physical gate is part of restore, not merely JSON validation.
	var wall: MeshInstance3D=scene._box(Vector3(2,3,2),scene.avatar.global_position+Vector3.UP,Color.GRAY,true)
	await frames(3);pause=scene.model.snapshot();saved=bytes(slot)
	check(not scene.restore_continuation().is_empty() and scene.model.snapshot()==pause,"blocked saved body refuses atomically")
	check(bytes(slot)==saved,"physical refusal retains prior continuation")
	wall.get_parent().queue_free();await frames(4)
	# An unavailable save target prevents exiting and retains the playable scene.
	scene.continuation_path="user://missing-slice-directory/continue.json"
	scene._menu_action("menu");await frames(3)
	check(current_scene==home and scene._paused and not scene.avatar.input_enabled,"exit save failure holds paused scene")
	check(scene._panel_text.text.contains("VISIT NOT SAVED"),"exit failure explained in game")
	scene.continuation_path=slot
	scene._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(scene._exit_action=="quit","OS close queues save before quit")
	scene._exit_action="";scene._resume()
	# A 30-active-second interval writes after inherited native processing.
	scene._last_continuation_tick=int(scene.model.progress().tick)-scene.AUTOSAVE_TICKS
	await frames(2)
	check(int(Store.read(slot).envelope.snapshot.childhood.tick)>int(pause.childhood.tick),"periodic save contains admitted current tick")
	scene._show_dialog("TEST PAUSE","",[["Return","resume"]]);saved=bytes(slot);await frames(35)
	check(bytes(slot)==saved,"paused visit makes no periodic write")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(slot+".tmp"))
	scene._resume();scene._last_continuation_tick=int(scene.model.progress().tick)-scene.AUTOSAVE_TICKS
	await frames(3)
	check(scene._paused and not scene.avatar.input_enabled and bytes(slot)==saved,"periodic write failure pauses and preserves earlier continuation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot+".tmp"))
	# Exit is the actual in-game button operation; no direct snapshot bypass.
	scene._menu_action("menu");await frames(5)
	check(current_scene!=home and current_scene.get_script().resource_path=="res://ui/main_menu.gd","save-and-menu transitions after write")
	check(Store.read(slot).envelope.run_id==new_id,"menu keeps the run continuation")
	current_scene.queue_free();current_scene=null;await frames()
	# Rejected startup must not overwrite a broken save with a fresh world.
	write_raw(slot,"{broken");saved=bytes(slot)
	home=Launch.make_world("continue");scene=home.get_node("ChildhoodChapter");scene.continuation_path=slot
	run_paths.append(scene.save_path);root.add_child(home);current_scene=home;await frames(8)
	check(not scene.continuation_ready and scene._paused and bytes(slot)==saved,"failed Continue remains paused and preserves evidence")
	check(scene._panel_text.text.contains("CONTINUE NOT RESTORED"),"failed startup is explicit")
	scene._unhandled_input(e);await frames(3);check(bytes(slot)==saved,"failed startup cannot enter route or autosave")
	home.queue_free();current_scene=null;await frames()
	# Refused first save must not replace an earlier accepted continuation.
	saved=bytes(slot);DirAccess.make_dir_absolute(ProjectSettings.globalize_path(slot+".tmp"))
	home=Launch.make_world("new");scene=home.get_node("ChildhoodChapter");scene.continuation_path=slot
	run_paths.append(scene.save_path);root.add_child(home);current_scene=home;await frames(8)
	check(not scene.continuation_ready and scene._paused and bytes(slot)==saved,"failed first New save preserves prior Continue")
	check(scene._panel_text.text.contains("CONTINUATION NOT CREATED") and not scene.avatar.input_enabled,"failed first save holds explicit disabled startup")
	home.queue_free();current_scene=null;await frames();DirAccess.remove_absolute(ProjectSettings.globalize_path(slot+".tmp"))

func _played_water_resume() -> void:
	# One declared starting fixture, then player movement, E, buttons and native ticks.
	var home:=Launch.make_world("new");var scene=home.get_node("ChildhoodChapter");scene.continuation_path=slot
	run_paths.append(scene.save_path);ok(scene.model.restore(Fixture.complete()),"played route starts from declared inquiry fixture")
	root.add_child(home);current_scene=home;await frames(8);await press(scene,"Continue in the courtyard")
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Accept the limited")
	await tap(scene,KEY_E);await press(scene,"Accept household water round")
	check(Guide.inspect(scene.model).active=="water","played route guides assigned water")
	var stand:=Vector3(26,0.14,14)
	for trip in range(2):
		for at in [Vector3(2,0.14,-10),Vector3(26,0.14,-10),stand]: await walk(scene,at)
		look(scene,Water.WELL);await tap(scene,KEY_E);await press(scene,"Draw one load")
		var due: int=int(scene.model.water_round().ledger.started_tick)+Water.DRAW_TICKS
		if trip==0:
			await frames(60);scene._show_dialog("TEST VISIT END","",[["Return","resume"]])
			var before: Dictionary=scene.model.snapshot();var id: String=scene.run_id
			ok(scene.save_continuation(),"input-driven pending draw continuation")
			home.queue_free();current_scene=null;await frames()
			home=Launch.make_world("continue");scene=home.get_node("ChildhoodChapter");scene.continuation_path=slot
			root.add_child(home);current_scene=home;await frames(8)
			check(scene.continuation_ready and scene.run_id==id and Supply._equal(scene.model.snapshot(),before),"new scene resumes exact pending played draw")
			check(int(scene.model.water_round().ledger.started_tick)+Water.DRAW_TICKS==due,"played draw deadline survives visit")
			await press(scene,"Continue in the courtyard")
		while int(scene.model.progress().tick)<due: await physics_frame
		await frames(2)
		check(scene.model.water_round().ledger.carried==Water.LOAD,"played draw finishes at original native deadline")
		check(scene.avatar.external_speed_limit==Water.CARRY_SPEED,"same physical motor carries at bounded walk")
		for at in [Vector3(26,0.14,-10),Vector3(2,0.14,-10),Water.STORE-Vector3(0,0,1)]: await walk(scene,at)
		look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E);await press(scene,"Deposit carried water")
		check(scene.model.water_round().ledger.stored==(trip+1)*Water.LOAD,"physical return deposits only one load")
	check(Guide.inspect(scene.model).active=="smith" and Guide.inspect(scene.model).rows[2].complete,"played water loop advances route to existing smith")
	ok(scene.model.validate(scene.model.snapshot()),"played multi-visit round remains valid")
	scene._show_dialog("TEST VISIT END","",[["Return","resume"]]);ok(scene.save_continuation(),"completed played round persists")
	home.queue_free();current_scene=null;await frames()

func _run() -> void:
	_store_checks();await _runtime_checks();await _played_water_resume()
	for path in run_paths+[slot]:
		for suffix in ["",".tmp",".checkpoint.json",".checkpoint.json.tmp",".bazaar-retry.json",".bazaar-retry.json.tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("GUJRANWALA_SLICE_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
