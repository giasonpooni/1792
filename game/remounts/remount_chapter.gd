extends "res://narrative/oral_memory/memory_chapter.gd"
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Same playable home controller. Only this scene advances the physical agents.
const RemountState := preload("res://remounts/remount_state.gd")
const RemountRules := preload("res://remounts/remount_rules.gd")
const Yard := preload("res://remounts/remount_yard.gd")
const RemountSupply := preload("res://territory/misl_rules.gd")
const RemountDirection := preload("res://remounts/remount_direction.gd")
var yard: Node3D
var runner: CharacterBody3D
var responder: CharacterBody3D
var _remount_action := ""
var _remount_choices: Array[String]=[]

func _init() -> void:
	model=RemountState.new()
	save_path=WorkshopState.WORKSHOP_SAVE

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
func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_remount_action=""
	_remount_choices.clear()

func _show_dialog(title: String,body: String,actions: Array) -> void:
	_remount_choices.clear();_remount_action=""
	super._show_dialog(title,body,actions)

func _resume() -> void:
	_remount_choices.clear();_remount_action=""
	super._resume()

func _menu_action(action: String) -> void:
	if action.begins_with("remount:"):
		var kind:=action.trim_prefix("remount:")
		if _paused and kind in _remount_choices and _remount_action.is_empty(): _remount_action=kind
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _remount_action.is_empty():
		var action:=_remount_action;_remount_action=""
		if not _paused or action not in _remount_choices: return
		var at: Vector3=RemountSupply.MARKET if action=="introduction" else RemountRules.OBSERVERS.yard_gatekeeper.position if action=="permission" else RemountSupply.QUARTERMASTER
		var error:="Face the nearby speaker from clear ground before continuing."
		if _remount_contact(at):
			if action=="brief":
				_show_dialog("TWO EMPTY PLACES",RemountDirection.BRIEF,[["Find the horses and their tally","remount:begin"],["Not now","resume"]])
				_remount_choices.assign(["begin"])
				return
			if action=="after":
				_show_dialog("THE HORSES STAY IN THE YARD",RemountDirection.AFTERMATH,[["Return","resume"]])
				return
			error=model.begin_remounts() if action=="begin" else model.remount_action(action)
		_message=error if not error.is_empty() else RemountDirection.action_line(action)
		_sync_remounts(true)
		if error.is_empty() and action=="resolve":
			_show_dialog("THE SEALED ACCOUNT",RemountDirection.report(model.remounts().ledger),[["And the horses?","remount:after"],["Return","resume"]])
			_remount_choices.assign(["after"])
		else: _resume()
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
	yard.sample(model.position(),model.has_remounts(),not _paused)
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

func foreground_guidance(moving: bool=false) -> Dictionary:
	return RemountDirection.read(self,moving)

func _remount_contact(at: Vector3,height: float=1.4) -> bool:
	return not model.mounted() and avatar.is_on_floor() and avatar.global_position.distance_to(model.position())<=0.25 and model.position().distance_to(at)<=3 and _seen(at+Vector3.UP*height,4.5)

func _append_remount_action(text: String,action: String) -> void:
	_remount_choices.append(action)
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("remount:"+action))
	_actions.add_child(button)
	_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	if not model.has_remounts() and not model._other_commitment() and not model.carrying_workshop():
		_append_remount_action("Investigate the two missing remounts","brief")
	elif model.has_remounts():
		if model.remount_busy() and model.remounts().ledger.note and model.remounts().ledger.horses:
			_append_remount_action("Give the remount account and sealed tally","resolve")
		elif not model.remount_busy(): _append_remount_action("Ask about the remounts' return","after")
	_focus_household_continuation("home")

func _open_market() -> void:
	super._open_market()
	if model.remount_busy() and not model.remounts().ledger.introduced:
		_append_remount_action("Ask the handler for an introduction to the southern yard","introduction")
	_focus_household_continuation("market")

func _interact() -> void:
	if model.has_remounts() and not model.mounted():
		var s: Dictionary=model.remounts().ledger
		var gate: Vector3=RemountRules.OBSERVERS.yard_gatekeeper.position
		if Model.distance(model.position(),gate)<=3:
			if not _remount_contact(gate,1.6): _message="Face the gatekeeper before speaking."
			else:
				var choices: Array=[["Return","resume"]]
				if not s.permission: choices.push_front(["Present the handler's introduction","remount:permission"])
				_show_dialog("YARD GATEKEEPER",RemountDirection.GATE,choices)
				if not s.permission: _remount_choices.assign(["permission"])
			return
		if Model.distance(model.position(),RemountRules.POST)<=3:
			if _remount_contact(RemountRules.POST,1.0):
				var text: String="No account has reached this post."
				if not s.recipient_knowledge.is_empty():
					text="A witness reported unauthorized activity in the yard. " + ("The report named Buddh." if s.recipient_knowledge[0].subject!="" else "The report did not identify a person.")
				_show_dialog("DUTY POST · SPOKEN ACCOUNT",text+"\n\nThis is received testimony, not a finding of theft.",[["Return","resume"]])
			return
		for kind in ["note","horses"]:
			var at: Vector3=RemountRules.NOTE if kind=="note" else RemountRules.HITCH
			if not s[kind] and Model.distance(model.position(),at)<=3:
				if not _remount_contact(at,0.72 if kind=="note" else 1.4): _message="Face the nearby object and move into clear sight."
				else:
					var error: String=model.remount_action(kind)
					_message=error if not error.is_empty() else RemountDirection.action_line(kind)
					_sync_remounts()
				return
	super._interact()

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is RemountState and staged.has_remounts():
		for key in ["runner","responder"]:
			if not _navigation.fits(staged.remounts()[key]): return "Saved encounter agent has no standing room. Session unchanged."
	return ""
