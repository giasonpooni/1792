# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Rules := preload("res://dlc/fall_of_empire/rules.gd")
const Desk := preload("res://dlc/fall_of_empire/desk.tscn")
var passed:=0
var failed:=0
var final_state: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1;push_error("FALL OF EMPIRE FAIL: "+label)
func step(state: Dictionary, actor: String, action: String, value: String="", tick: int=-1) -> Dictionary:
	var result:=Rules.append(state,actor,action,value,int(state.tick)+1 if tick<0 else tick)
	check(result.error.is_empty(),"accepted "+action+" "+value)
	return result.state if result.error.is_empty() else state
func refused(state: Dictionary, actor: String, action: String, value: String="", tick: Variant=-1) -> void:
	var before:=state.duplicate(true)
	var result:=Rules.append(state,actor,action,value,int(state.tick)+1 if tick is int and tick==-1 else tick)
	check(not result.error.is_empty() and result.state.is_empty(),"refused "+action+" "+value)
	check(state==before,"refusal did not mutate input")
func anchors(state: Dictionary) -> Dictionary:
	var s:=state
	for anchor in Rules.ANCHORS: s=step(s,"host","anchor",anchor)
	return s
func finish(muster: String, household: String) -> Dictionary:
	var s:=anchors(Rules.initial("ending:"+muster+":"+household))
	refused(s,"host","close")
	s=step(s,"rebel_courier","muster",muster)
	s=step(s,"resident","household",household)
	s=step(s,"company_courier","inspect_road")
	refused(s,"resident","market")
	s=step(s,"company_courier","send","resident")
	refused(s,"resident","receive","",int(s.tick)+Rules.DELAY-1)
	s=step(s,"resident","receive","",int(s.tick)+Rules.DELAY)
	s=step(s,"resident","market")
	s=step(s,"host","close")
	check(s.world.closed and s.world.household==household and s.world.muster==muster,"adverse outcomes survive closure")
	check(Rules.view(s,"company_courier").observations[0].id==Rules.view(s,"resident").observations[0].id,"one source root, not two independent witnesses")
	return s
func domain() -> void:
	check(not Rules.production_refusal().is_empty(),"qualification cannot unlock production")
	check(Rules.initial("").is_empty(),"execution identity required")
	var s:=Rules.initial("native-domain")
	for role in Rules.ROLES:
		check(Rules.view(s,role).event_id=="fixture.shared_road","same event on all sides")
		check(Rules.view(s,role).keys().size()==4 and not Rules.view(s,role).has("world") and not Rules.view(s,role).has("reports"),"whitelisted view")
	check(Rules.view(s,"host").is_empty(),"no omniscient character view")
	refused(s,"host","close")
	refused(s,"company_courier","inspect_road")
	refused(s,"rebel_courier","muster","dispersed")
	refused(s,"resident","household","returned")
	refused(s,"resident","receive")
	refused(s,"company_courier","send","resident")
	refused(s,"host","anchor",Rules.ANCHORS[1])
	refused(s,"resident","anchor",Rules.ANCHORS[0])
	refused(s,"host","observe")
	refused(s,"company_courier","observe","unexpected")
	refused(s,"unknown","observe")
	refused(s,"resident","unsupported")
	for bad_tick in [true,false,null,NAN,INF,0.5,-2,100000001]: refused(s,"resident","observe","",bad_tick)
	s=step(s,"company_courier","observe")
	check(Rules.view(s,"rebel_courier").observations.is_empty() and Rules.view(s,"resident").observations.is_empty(),"private observation")
	var old:=s.duplicate(true)
	s=step(s,"company_courier","send","rebel_courier")
	refused(s,"company_courier","send","rebel_courier")
	refused(s,"company_courier","send","company_courier")
	refused(s,"rebel_courier","receive","",int(s.tick)+119)
	s=step(s,"rebel_courier","receive","",int(s.tick)+120)
	check(Rules.view(s,"rebel_courier").observations.size()==1,"delayed report received")
	refused(s,"rebel_courier","receive")
	refused(s,"rebel_courier","send","resident")
	refused(s,"resident","observe","",0)
	check(Rules.restore(old).state.reports.is_empty() and Rules.view(Rules.restore(old).state,"rebel_courier").observations.is_empty(),"whole restore discards later reports/knowledge")
	var detached:=Rules.view(s,"company_courier");detached.observations.clear()
	check(Rules.view(s,"company_courier").observations.size()==1,"view is detached")
	refused(s,"company_courier","send","resident",99999999)
	for muster in ["dispersed","detained","left_region"]:
		for household in ["returned","displaced","missing"]: final_state=finish(muster,household)
	refused(final_state,"resident","observe")
	check(Rules.restore(JSON.parse_string(JSON.stringify(final_state))).error.is_empty(),"JSON snapshot round trip")
	for field in ["world","knowledge","reports","binding","model_id","execution_id","schema","extra","sequence","operation","event","tick","history_extra","history_missing","bool_sequence","numeric_boolean","fractional_tick"]:
		var bad:=final_state.duplicate(true)
		match field:
			"world": bad.world.household="returned"
			"knowledge": bad.knowledge.resident=[]
			"reports": bad.reports[0].due=0
			"binding": bad.binding="altered"
			"model_id": bad.model_id="other"
			"execution_id": bad.execution_id="other-execution"
			"schema": bad.schema="unknown"
			"extra": bad.extra=true
			"sequence": bad.history[0].seq=2
			"operation": bad.history[0].operation_id="other"
			"event": bad.history[0].event_id="copy.of.road"
			"tick": bad.history[3].tick=0
			"history_extra": bad.history[0].extra="injected"
			"history_missing": bad.history[0].erase("value")
			"bool_sequence": bad.history[0].seq=false
			"numeric_boolean": bad.world.road_open=1
			"fractional_tick": bad.history[0].tick=0.5
		check(not Rules.restore(bad).error.is_empty(),"tamper refused: "+field)
	for malformed in [null,[],{},true,{"execution_id":"x","history":"not-array"}]: check(not Rules.restore(malformed).error.is_empty(),"malformed snapshot refused")
	var limited:=Rules.initial("budget")
	for i in range(Rules.LIMIT): limited=step(limited,"resident","observe","",i)
	refused(limited,"resident","observe")
	check(Rules.restore(limited).error.is_empty(),"bounded full history replay")
func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func pick(desk: Control, index: int) -> void:
	desk.role_picker.select(index);desk.role_picker.item_selected.emit(index)
func ui_journey() -> void:
	var desk:=Desk.instantiate();root.add_child(desk);current_scene=desk;await frames()
	check(root.get_child_count()==1,"isolated desk: no simultaneous campaign world")
	desk.buttons.observe.pressed.emit();desk.buttons.checkpoint.pressed.emit()
	desk.recipient.select(1);desk.buttons.send.pressed.emit();pick(desk,1)
	check(desk.notebook.text.contains("No observations"),"role button cannot leak source knowledge")
	await frames(125);desk.buttons.receive.pressed.emit()
	check(desk.state.knowledge.rebel_courier.size()==1,"actual UI/tick report delivery")
	desk.buttons.restore.pressed.emit()
	check(desk.state.reports.is_empty() and desk.state.knowledge.rebel_courier.is_empty(),"UI checkpoint rollback")
	for _i in range(3): desk.buttons.anchor.pressed.emit()
	desk.buttons.close.pressed.emit();check(not desk.state.world.closed,"UI formal peace alone refuses")
	desk.disposition.select(2);desk.buttons.muster.pressed.emit()
	pick(desk,0);desk.buttons.inspect_road.pressed.emit();desk.recipient.select(2);desk.buttons.send.pressed.emit()
	pick(desk,2);desk.household.select(2);desk.buttons.household.pressed.emit()
	await frames(125);desk.buttons.receive.pressed.emit();desk.buttons.market.pressed.emit();desk.buttons.close.pressed.emit()
	check(desk.state.world.closed and desk.state.world.household=="missing","UI completes with unresolved personal loss")
	check(desk.checkpoint.world.anchors.is_empty(),"checkpoint not silently overwritten")
	final_state=desk.state.duplicate(true)
	desk.queue_free();await frames()
func run() -> void:
	domain();await ui_journey()
	var record: Dictionary={"schema":"fall-of-empire.verification.v1","verification_id":"fall-of-empire.native-checks.v1", "model_id":Rules.MODEL,
		"operation_id":Rules.OPERATION,"binding":Rules.binding(),"execution_id":final_state.get("execution_id","failed"),
		"source_kind":"synthetic:qualification","historical_truth_certified":false,"production_ready":false,
		"observations":{"ui_final_snapshot":final_state},"passed":passed,"failed":failed}
	var file:=FileAccess.open("user://fall-of-empire-tests.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(record,"\t"));file.close()
	else: check(false,"evidence file creation")
	print("FALL_OF_EMPIRE_TESTS: %d passed, %d failed" % [passed,failed]);quit(1 if failed else 0)
