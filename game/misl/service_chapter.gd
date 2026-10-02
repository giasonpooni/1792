# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/researched_chapter.gd"
## Extends the current integrated Gujranwala/narrator entry; no alternate game mode.
const ServiceState:=preload("res://misl/service_state.gd")
const Service:=preload("res://misl/service_rules.gd")
const Notes:=preload("res://misl/service_notes.gd")
const ServicePresentation:=preload("res://misl/service_presentation.gd")
var service_agent: CharacterBody3D
var _service_action:=""
var _service_speaker: Node3D
var _service_choices: Array[String]=[]
var _service_satchel: Node3D

func _init() -> void:
	model=ServiceState.new();save_path=ServiceState.SERVICE_SAVE

func _build_world() -> void:
	super._build_world()
	service_agent=EscortAgent.new();service_agent.entity_id=Service.identity(-1)
	service_agent.name="HouseholdServiceDetail";service_agent.move_speed=Service.SPEED
	add_child(service_agent);service_agent.caption.text="Household guard · service detail"
	service_agent.add_collision_exception_with(avatar);service_agent.add_collision_exception_with(horse)
	_service_satchel=Node3D.new();_service_satchel.name="ServiceSatchel";service_agent.add_child(_service_satchel)
	_service_piece(Vector3(0.3,0.33,0.18),Vector3.ZERO,Color("856646"))
	_service_piece(Vector3(0.34,0.055,0.21),Vector3(0,0.17,0),Color("c0a581"))
	var strap:=_service_piece(Vector3(0.045,0.7,0.035),Vector3(-0.17,0.32,-0.12),Color("4d392b"))
	strap.rotation.z=-0.5
	# Original, fictional dispatch corner; no monument or footprint reconstruction claim.
	_box(Vector3(3.5,0.025,2),Vector3(-8,0.145,8.5),Color("89765d"))
	_box(Vector3(1.5,0.12,0.7),Vector3(-8,0.85,9),Color("66503a"))
	for x in [-8.6,-7.4]: _box(Vector3(0.1,0.75,0.1),Vector3(x,0.46,9),Color("66503a"))
	for x in [-8.35,-8,-7.65]: _box(Vector3(0.23,0.03,0.32),Vector3(x,0.93,9),Color("cab792"))
	_service_speaker=_box(Vector3(0.5,1.6,0.4),Vector3(26.3,0.94,10),Color("7c7165")).get_parent()
	var vessel:=MeshInstance3D.new();vessel.name="CarrierPot"
	var clay:=CylinderMesh.new();clay.top_radius=0.17;clay.bottom_radius=0.25;clay.height=0.38;vessel.mesh=clay
	var clay_material:=StandardMaterial3D.new();clay_material.albedo_color=Color("a3714e");vessel.material_override=clay_material
	vessel.position=Vector3(-0.33,-0.12,-0.08);_service_speaker.add_child(vessel)
	var sign:=Label3D.new();sign.text="Local water carrier [E]";sign.position=Vector3(26.3,2.6,10)
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.font_size=20;add_child(sign)
	_sync_service(true)

func _service_piece(size: Vector3,at: Vector3,color: Color) -> MeshInstance3D:
	var visual:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;visual.mesh=mesh;visual.position=at
	var material:=StandardMaterial3D.new();material.albedo_color=color;visual.material_override=material
	_service_satchel.add_child(visual)
	return visual

func _sync_service(reset: bool=false) -> void:
	if not is_instance_valid(service_agent): return
	var active: bool=model.service_reserved()
	service_agent.visible=active;service_agent.collision_layer=2 if active else 0
	if active:
		var s: Dictionary=model.service()
		_guard_posts[int(s.ledger.slot)].visible=false
		service_agent.entity_id=Service.identity(int(s.ledger.slot))
		service_agent.caption.text="Household guard · ready to give account" if s.ledger.stage=="awaiting_account" else "Household guard · service detail"
		# Existing dispatch tick drives a brief adjustment of the carried prop.
		# The bag contains no invented stock and has no independent clock/collider.
		var departure_tick:=int(model.progress().tick)
		for e in s.events:
			if e.kind=="dispatch": departure_tick=int(e.tick)
		var settle:=clampf(float(int(model.progress().tick)-departure_tick)/42.0,0.0,1.0)
		_service_satchel.position=Vector3(0.34,1.18,0.12).lerp(Vector3(0.34,0.86,0.12),settle)
		_service_satchel.rotation.z=lerpf(-0.2,0.0,settle)
	_service_satchel.visible=active
	if reset: service_agent.apply(model.service().agent if model.has_service() else Service.motion(-1))

func _sync_economy(reset: bool=false) -> void:
	super._sync_economy(reset)
	_sync_service()

func _apply() -> void:
	super._apply();_sync_service(true)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_service_action="";_service_choices.clear()

func _resume() -> void:
	_service_action="";_service_choices.clear();super._resume()

func _show_dialog(title: String,body: String,actions: Array) -> void:
	super._show_dialog(title,body,actions)
	for action in actions:
		if str(action[1]).begins_with("service:"): _service_choices.append(str(action[1]).trim_prefix("service:"))

func _menu_action(action: String) -> void:
	if action.begins_with("service:"):
		var choice:=action.trim_prefix("service:")
		if _paused and choice in _service_choices and _service_action.is_empty(): _service_action=choice
	else: super._menu_action(action)

func _service_contact(kind: String,arg: String) -> bool:
	if kind=="import_supply": return true
	if kind=="hear" and arg=="well":
		return not model.mounted() and avatar.is_on_floor() and avatar.global_position.distance_to(model.position())<=0.25 and model.position().distance_to(Service.SITES.well)<=3 and _seen(Vector3(26.3,1.7,10),5)
	# The request is voiced by the same visible trader as the market menu;
	# Service.SITES.market is the guard's loading-place destination nearby.
	return _economy_contact(Rules.MARKET if kind=="hear" else Rules.QUARTERMASTER)

func _physics_process(delta: float) -> void:
	if not _service_action.is_empty():
		var queued:=_service_action;_service_action=""
		if not _paused or queued not in _service_choices: return
		var parts:=queued.split("|",true,1)
		var kind: String=parts[0];var arg: String=parts[1] if parts.size()>1 else ""
		if not _service_contact(kind,arg):
			_message="Return to the speaker on clear, standing ground before answering.";_resume();return
		if kind=="import_supply": _load(Territory.TERRITORY_SAVE);return
		var error: String=model.begin_service() if kind=="begin" else model.service_action(kind,arg)
		_message=error if not error.is_empty() else ServicePresentation.reply(kind,arg,model.service().ledger)
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
	_service_choices.append(action)

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	_panel_text.text+="\n\n"+ServicePresentation.quartermaster_context(model.service().ledger if model.has_service() else {})
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
			_show_dialog("WATER CARRIER · LOCAL REQUEST","The carrier shifts a full pot to make space on the approach.\n\n"+(ServicePresentation.request("well") if "well" in model.service().ledger.heard else "Water carrier · A word, Buddh. Before you go back to the yard."),actions)
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
	if s.stage!="idle": text="One guard away on service. Hear the account after return."
	if s.stage=="awaiting_account": text="Guard returned. Hear his account at the quartermaster."
	if s.stage!="idle" and not model.service_ready(): text+=" Supplies/pay insufficient: duty held until the next provisioned watch."
	if s.completed.size()==2: text="Both local accounts received. The guard is back on household duty."
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
