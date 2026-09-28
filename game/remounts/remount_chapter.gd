extends "res://territory/gujranwala_chapter.gd"
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Same playable home controller. Only this scene advances the physical agents.
const RemountState := preload("res://remounts/remount_state.gd")
const RemountRules := preload("res://remounts/remount_rules.gd")
const Yard := preload("res://remounts/remount_yard.gd")
const Fabric := preload("res://architecture/gujranwala_fabric.gd")
var fabric: Node3D
var yard: Node3D
var runner: CharacterBody3D
var responder: CharacterBody3D
var _remount_action := ""

func _init() -> void:
	model=RemountState.new()
	save_path=RemountState.REMOUNT_SAVE

func _build_world() -> void:
	super._build_world()
	yard=Yard.new();yard.name="RemountYard";add_child(yard);yard.build()
	runner=EscortAgent.new();runner.entity_id="yard_runner";runner.move_speed=RemountRules.SPEED
	add_child(runner);runner.caption.text="Duty runner"
	responder=EscortAgent.new();responder.entity_id="yard_reserve";responder.move_speed=RemountRules.SPEED
	add_child(responder);responder.caption.text="Yard reserve"
	for a in [runner,responder]:
		a.add_collision_exception_with(avatar);a.add_collision_exception_with(horse)
	_sync_remounts(true)
	_navigation.built=false
	fabric=Fabric.new();fabric.name="GujranwalaFabric";add_child(fabric)
	var fabric_error: String=fabric.build(self)
	if not fabric_error.is_empty(): push_error(fabric_error)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		_show_dialog("GUJRANWALA · RECONSTRUCTION NOTES",fabric.inspection_text(),[["Return","resume"]])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_remount_action=""

func _menu_action(action: String) -> void:
	if action.begins_with("remount:"):
		_remount_action=action.trim_prefix("remount:")
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _remount_action.is_empty():
		var action:=_remount_action;_remount_action=""
		if action=="load_supply":
			_load(Territory.TERRITORY_SAVE)
			return
		var error: String=model.begin_remounts() if action=="begin" else model.remount_action(action)
		_message=error if not error.is_empty() else RemountRules.WORDS[action].text
		_sync_remounts(true)
		_resume()
		return
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if int(model.progress().tick)==before or not model.has_remounts(): return
	# Complete perception for the last simulated tick, even when E just opened a menu.
	for id in RemountRules.OBSERVERS:
		var prior: Dictionary=model.remounts().ledger.contacts[id]
		var error: String=model.observe_yard(id,_observer_clear(id),Vector2(avatar.velocity.x,avatar.velocity.z).length())
		if not error.is_empty(): _message=error
		elif prior.seen_tick<0 and model.remounts().ledger.contacts[id].seen_tick>=0 and not model.remounts().ledger.permission:
			if Model.distance(model.position(),RemountRules.OBSERVERS[id].position)<10:
				_message=("Gatekeeper" if id=="yard_gatekeeper" else "Yard keeper")+" calls: Who gave you leave to enter?"
	if not _paused:
		_step_remount_agents(delta)
	_sync_remounts()
	_refresh()

func _observer_clear(id: String) -> bool:
	var eye: Vector3=RemountRules.OBSERVERS[id].position+Vector3.UP*1.6
	var target: Vector3=model.position()+Vector3.UP*1.35
	var ray:=PhysicsRayQueryParameters3D.create(eye,target,1,[avatar.get_rid(),horse.get_rid(),attacker.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _step_remount_agents(delta: float) -> void:
	var m: Dictionary=model.remounts()
	var s: Dictionary=m.ledger
	var messenger_target: Vector3=RemountRules.OBSERVERS[s.report.sender].position if s.report.stage=="queued" else RemountRules.POST
	var response_target: Vector3=Model.point(s.response.target) if s.response.stage=="travelling" else RemountRules.POST
	for job in [["runner",runner,messenger_target,s.report.stage in ["queued","in_transit"]],
		["responder",responder,response_target,s.response.stage in ["travelling","returning"]]]:
		var a: CharacterBody3D=job[1]
		var moving: bool=job[3] and Model.distance(a.global_position,job[2])>1.25
		var waypoint: Vector3=_navigation.waypoint(a.global_position,job[2]) if moving else a.global_position
		var motion: Dictionary=a.step(delta,waypoint,moving)
		var error: String=model.record_remount_agent(job[0],motion,delta)
		if not error.is_empty():
			a.apply(m[job[0]]);_message=error
	model.progress_remount_messages()

func _sync_remounts(reset: bool=false) -> void:
	if not is_instance_valid(yard) or not is_instance_valid(runner) or not is_instance_valid(responder): return
	var enabled: bool=model.has_remounts()
	var m: Dictionary=model.remounts()
	yard.sync(enabled,enabled and m.ledger.note)
	for a in [runner,responder]:
		a.visible=enabled;a.collision_layer=2 if enabled else 0
	if reset:
		runner.apply(m.runner if enabled else RemountRules.agent("yard_runner",RemountRules.RUNNER_START))
		responder.apply(m.responder if enabled else RemountRules.agent("yard_reserve",RemountRules.POST))

func _apply() -> void:
	super._apply()
	_sync_remounts(true)

func _append_remount_action(text: String,action: String) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("remount:"+action))
	_actions.add_child(button);_actions.move_child(button,0)
	_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	if not model.has_remounts():
		_append_remount_action("Investigate the two missing remounts","begin")
	elif not model.remounts().ledger.resolved:
		_append_remount_action("Give the remount account and sealed tally","resolve")

func _open_journal() -> void:
	super._open_journal()
	if FileAccess.file_exists(Territory.TERRITORY_SAVE):
		_append_remount_action("Load the prior Gujranwala supply save (replaces this run)","load_supply")

func _open_market() -> void:
	super._open_market()
	if model.has_remounts() and not model.remounts().ledger.introduced:
		_append_remount_action("Ask the handler for an introduction to the southern yard","introduction")

func _interact() -> void:
	if model.has_remounts() and not model.mounted():
		var s: Dictionary=model.remounts().ledger
		var gate: Vector3=RemountRules.OBSERVERS.yard_gatekeeper.position
		if Model.distance(model.position(),gate)<=3:
			if not _seen(gate+Vector3.UP*1.6,4): _message="Face the gatekeeper before speaking."
			else:
				var choices: Array=[["Return","resume"]]
				if not s.permission: choices.push_front(["Present the handler's introduction","remount:permission"])
				_show_dialog("YARD GATEKEEPER", "An introduction permits entry. A service passage does not. Local witnesses remember what they perceived, not where you go afterward.",choices)
			return
		if Model.distance(model.position(),RemountRules.POST)<=3:
			if _seen(RemountRules.POST+Vector3.UP,4):
				var text: String="No account has reached this post."
				if not s.recipient_knowledge.is_empty():
					text="A witness reported unauthorized activity in the yard. " + ("The report named Buddh." if s.recipient_knowledge[0].subject!="" else "The report did not identify a person.")
				_show_dialog("DUTY POST · SPOKEN ACCOUNT",text+"\n\nThis is received testimony, not a finding of theft.",[["Return","resume"]])
			return
		for kind in ["note","horses"]:
			var at: Vector3=RemountRules.NOTE if kind=="note" else RemountRules.HITCH
			if not s[kind] and Model.distance(model.position(),at)<=3:
				if not _seen(at+Vector3.UP*(0.72 if kind=="note" else 1.4),4.5): _message="Face the nearby object and move into clear sight."
				else:
					var error: String=model.remount_action(kind)
					_message=error if not error.is_empty() else RemountRules.WORDS[kind].text
					_sync_remounts()
				return
	super._interact()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud) or not model.has_remounts(): return
	var s: Dictionary=model.remounts().ledger
	var objective: String="Ask the western market handler, or find the southern yard."
	if s.introduced and not s.permission: objective="Present the introduction at the yard's east gate."
	if s.permission: objective="Examine the remounts and their sealed tally [face + E]."
	if s.note and not s.horses: objective="Tally retained, unread. Observe the two tethered horses [E]."
	if s.horses and not s.note: objective="Horses located. Obtain the sealed tally [E]."
	if s.horses and s.note: objective="Return to the quartermaster with your account."
	if s.resolved: objective="BATCH LOCATED · Yard explanation retained as testimony; collection not simulated."
	_hud.text+="\n\nMISSING REMOUNTS · "+objective

func _load(path: String="") -> void:
	var staged:=RemountState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole chapter restored: supplies, inquiry, local knowledge and messenger custody." if error.is_empty() else error
	_clear_pending_actions();_resume()

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is RemountState and staged.has_remounts():
		for key in ["runner","responder"]:
			if not _navigation.fits(staged.remounts()[key]): return "Saved encounter agent has no standing room. Session unchanged."
	return ""
