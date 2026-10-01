# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/researched_chapter.gd"
## Extends the current integrated Gujranwala/narrator entry; no alternate game mode.
const ServiceState:=preload("res://misl/service_state.gd")
const Service:=preload("res://misl/service_rules.gd")
const Notes:=preload("res://misl/service_notes.gd")
var service_agent: CharacterBody3D
var _service_action:=""
var _service_speaker: Node3D

func _init() -> void:
	model=ServiceState.new();save_path=ServiceState.SERVICE_SAVE

func _build_world() -> void:
	super._build_world()
	service_agent=EscortAgent.new();service_agent.entity_id=Service.identity(-1)
	service_agent.name="HouseholdServiceDetail";service_agent.move_speed=Service.SPEED
	add_child(service_agent);service_agent.caption.text="Household guard · service detail"
	service_agent.add_collision_exception_with(avatar);service_agent.add_collision_exception_with(horse)
	# Original, fictional dispatch corner; no monument or footprint reconstruction claim.
	_box(Vector3(3.5,0.025,2),Vector3(-8,0.145,8.5),Color("89765d"))
	_box(Vector3(1.5,0.12,0.7),Vector3(-8,0.85,9),Color("66503a"))
	for x in [-8.6,-7.4]: _box(Vector3(0.1,0.75,0.1),Vector3(x,0.46,9),Color("66503a"))
	for x in [-8.35,-8,-7.65]: _box(Vector3(0.23,0.03,0.32),Vector3(x,0.93,9),Color("cab792"))
	_service_speaker=_box(Vector3(0.5,1.6,0.4),Vector3(26.3,0.94,10),Color("7c7165")).get_parent()
	var sign:=Label3D.new();sign.text="Local water carrier [E]";sign.position=Vector3(26.3,2.6,10)
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.font_size=20;add_child(sign)
	_sync_service(true)

func _sync_service(reset: bool=false) -> void:
	if not is_instance_valid(service_agent): return
	var active: bool=model.service_reserved()
	service_agent.visible=active;service_agent.collision_layer=2 if active else 0
	if active:
		var s: Dictionary=model.service()
		_guard_posts[int(s.ledger.slot)].visible=false
		service_agent.entity_id=Service.identity(int(s.ledger.slot))
	if reset: service_agent.apply(model.service().agent if model.has_service() else Service.motion(-1))

func _sync_economy(reset: bool=false) -> void:
	super._sync_economy(reset)
	_sync_service()

func _apply() -> void:
	super._apply();_sync_service(true)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_service_action=""

func _menu_action(action: String) -> void:
	if action.begins_with("service:"): _service_action=action.trim_prefix("service:")
	else: super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _service_action.is_empty():
		var parts:=_service_action.split("|",true,1);_service_action=""
		var kind: String=parts[0];var arg: String=parts[1] if parts.size()>1 else ""
		if kind=="import_supply": _load(Territory.TERRITORY_SAVE);return
		var error: String=model.begin_service() if kind=="begin" else model.service_action(kind,arg)
		_message=error if not error.is_empty() else ("Quartermaster · One hired guard can attend one request. A service commitment is not ownership of a village." if kind=="begin" else "Quartermaster · "+Service.ACCOUNTS[model.service().ledger.completed[-1]] if kind=="debrief" else "Recorded: "+kind+" "+arg)
		_sync_economy();_sync_service(true);_resume();return
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if int(model.progress().tick)==before or _paused or not model.service_reserved(): return
	var s: Dictionary=model.service()
	var target: Vector3=Service.SITES[s.ledger.active] if s.ledger.stage=="outbound" else Service.home(s.ledger.slot)
	var moving: bool=model.service_ready() and s.ledger.stage in ["outbound","returning"] and Model.distance(service_agent.global_position,target)>1.2
	var waypoint: Vector3=_navigation.waypoint(service_agent.global_position,target) if moving else service_agent.global_position
	var record: Dictionary=service_agent.step(delta,waypoint,moving)
	var error: String=model.record_service_motion(record,delta)
	if not error.is_empty(): service_agent.apply(s.agent);_message=error
	model.progress_service();_sync_service();_refresh()

func _extra_action(label: String,action: String) -> void:
	var button:=Button.new();button.text=label;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("service:"+action));_actions.add_child(button);_actions.move_child(button,0);_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	if not model.has_service(): _extra_action("Hear the Sukerchakia household-service brief","begin")
	else:
		var s: Dictionary=model.service().ledger
		if s.stage=="awaiting_account": _extra_action("Hear the returned guard's account","debrief")
		elif s.stage=="idle":
			for route in s.heard:
				if route not in s.completed: _extra_action("Commit one provisioned guard: "+Service.NAMES[route],"dispatch|"+route)

func _open_market() -> void:
	super._open_market()
	if model.has_service() and "market" not in model.service().ledger.heard:
		_extra_action("Hear the handler's local-service request","hear|market")

func _interact() -> void:
	if model.has_service() and not model.mounted() and Model.distance(model.position(),Service.SITES.well)<3:
		if not _seen(Vector3(26.3,1.7,10),5): _message="Face the water carrier before speaking."
		else:
			var actions: Array=[["Return","resume"]]
			if "well" not in model.service().ledger.heard: actions.push_front(["Hear the well-approach request","service:hear|well"])
			_show_dialog("WATER CARRIER · LOCAL REQUEST","Ask your household to send someone to hear us at the well approach. I do not speak for every village or claim the land for you.",actions)
		return
	super._interact()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		if not _paused: _show_dialog("GUJRANWALA / SUKERCHAKIA · RESEARCH VIEW",fabric.notebook()+"\n\n"+Notes.notebook(),[["Return","resume"]])
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func _open_journal() -> void:
	super._open_journal()
	if FileAccess.file_exists(Territory.TERRITORY_SAVE): _extra_action("Import prior household supply save (replaces this run)","import_supply")

func _account_text() -> String:
	var body:=super._account_text()
	if not model.has_service(): return body
	var s: Dictionary=model.service().ledger
	var absent:=1 if model.service_reserved() else 0
	body+="\n\nSUKERCHAKIA HOUSEHOLD SERVICE · authored detail\n%d hired total / %d committed / %d available at home. The same food and wage ledger covers all hired guards. No new troops or pay purse.\nRequests heard: %s\nAccounts received: %s" % [model.economy().ledger.guards,absent,model.economy().ledger.guards-absent,", ".join(s.heard),", ".join(s.completed)]
	return body

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud) or not model.has_service(): return
	var s: Dictionary=model.service().ledger
	var text: String="Hear requests at the market or eastern well approach."
	if s.stage!="idle": text="One guard committed to "+Service.NAMES[s.active]+". Hear the account after return."
	if s.stage!="idle" and not model.service_ready(): text+=" Supplies/pay insufficient: duty held until the next provisioned watch."
	if s.completed.size()==2: text="Two local accounts received. Neither grants territory or proves regional safety."
	_hud.text+="\nSERVICE · "+text

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if error.is_empty() and staged is ServiceState and staged.service_reserved() and not _navigation.fits(staged.service().agent):
		return "Service guard has no standing room. Save refused without changing state."
	return error

func _load(path: String="") -> void:
	var staged:=ServiceState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole home, supplies and service detail restored." if error.is_empty() else error
	_clear_pending_actions();_resume()
