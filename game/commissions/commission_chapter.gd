# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://youth/brawl_chapter.gd"
## Situated money, escort and limited viewpoint transfer in the SAME home world.
const CommissionState := preload("res://commissions/commission_state.gd")
const Contract := preload("res://commissions/commission_rules.gd")
const PlayerScene := preload("res://player/player.tscn")
var specialist_body: CharacterBody3D
var specialist_label: Label3D
var _commission_action := ""
var _commission_purse: MeshInstance3D
var _specialist_view_active := false
func _init() -> void:
	model=CommissionState.new();save_path=CommissionState.COMMISSION_SAVE
func _build_world() -> void:
	super._build_world()
	specialist_body=PlayerScene.instantiate();specialist_body.name="CommissionedSpecialist"
	specialist_body.menu_shortcut=false;specialist_body.movement_profile=0
	# A second body must not acquire the scene camera merely by being instantiated.
	specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D").current=false
	add_child(specialist_body)
	specialist_body.get_node("HomeIdentity").hide();specialist_body.get_node("MeshInstance3D").hide()
	var proxy:=preload("res://player/locomotion_proxy.gd").new();proxy.name="LocomotionProxy";specialist_body.add_child(proxy)
	specialist_body.collision_mask=1;specialist_body.add_collision_exception_with(avatar);specialist_body.add_collision_exception_with(horse)
	specialist_body.get_node("CameraPivot/SpringArm3D").add_excluded_object(avatar.get_rid())
	specialist_label=Label3D.new();specialist_label.text="Local instructor · candidate [E]"
	specialist_label.position=Vector3(0,2.1,0);specialist_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	specialist_label.font_size=20;specialist_label.pixel_size=0.006;specialist_body.add_child(specialist_label)
	# A receiving patch in the existing west-side lane, not a surveyed Eminabad yard.
	_box(Vector3(3.1,0.025,2),Contract.RECEPTION+Vector3(0,0.012,0),Color("887859"))
	var tag:=Label3D.new();tag.text="Receiving yard · original fiction";tag.position=Contract.RECEPTION+Vector3(0,2.8,0)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;tag.font_size=20;tag.pixel_size=0.004;add_child(tag)
	_commission_purse=MeshInstance3D.new();var pouch:=BoxMesh.new();pouch.size=Vector3(0.25,0.3,0.16);_commission_purse.mesh=pouch
	var leather:=StandardMaterial3D.new();leather.albedo_color=Color("947349");_commission_purse.material_override=leather
	_commission_purse.position=Vector3(0.38,0.8,0);avatar.add_child(_commission_purse)
	_sync_commission(true)
func _apply() -> void:
	super._apply();_sync_commission(true)
func _sync_commission(reset: bool=false) -> void:
	if not is_instance_valid(specialist_body): return
	var c: Dictionary=model.commission();var a: Dictionary=model.specialist()
	if reset:
		specialist_body.global_position=Model.point(a.position);specialist_body.velocity=Model.point(a.velocity)
		specialist_body.pivot.rotation.y=float(a.yaw)
	specialist_body.visible=not c.is_empty() and c.phase in ["introduced","escorting","appointed","dismissed"]
	specialist_body.collision_layer=2 if specialist_body.visible else 0
	specialist_body.set_physics_process(false) # Owner steps either AI or shared-player inputs once.
	var specialist_view: bool=model.controlling_specialist()
	specialist_body.input_enabled=specialist_view and not _paused
	# Ordinary hydration, dialogue and upkeep do not own the camera. A camera
	# selected by another scene/view remains current until an actual role transition.
	if specialist_view!=_specialist_view_active:
		var view_body: CharacterBody3D=specialist_body if specialist_view else avatar
		view_body.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
		_specialist_view_active=specialist_view
	if specialist_view:
		avatar.input_enabled=false;avatar.set_physics_process(false)
		if is_instance_valid(_veil): _veil.visible=false
	else:
		if is_instance_valid(_veil): _veil.visible=_subjective
	_commission_purse.visible=not c.is_empty() and c.phase in ["reserved","introduced","escorting"]
	specialist_label.text="Local instructor [E]" if not c.is_empty() and c.phase=="appointed" else "Local instructor · candidate [E]"
func _clear_pending_actions() -> void:
	super._clear_pending_actions();_commission_action=""
func _menu_action(action: String) -> void:
	if action.begins_with("commission:"): _commission_action=action.trim_prefix("commission:")
	else: super._menu_action(action)
func _add_commission_button(text: String,action: String) -> void:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=42;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(_menu_action.bind("commission:"+action));_actions.add_child(b);_actions.move_child(b,0);_layout()
func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy() or model.brawl_busy(): return
	var c: Dictionary=model.commission()
	if c.is_empty():
		_add_commission_button("Reserve senior commission · 156 household coins","reserve|senior")
		_add_commission_button("Reserve standard commission · 108 household coins","reserve|standard")
	elif c.phase in ["reserved","introduced"]: _add_commission_button("Cancel commission · return only unspent funds","cancel")
	elif c.phase=="escorting": _add_commission_button("Sign with the physically returned instructor","appoint")
	elif c.phase=="appointed":
		_add_commission_button("Take the instructor's viewpoint · same world","control|fictional_local_drillmaster")
		_add_commission_button("Dismiss instructor · accrued wages remain due","dismiss")
		if c.escrow>0: _add_commission_button("Release unspent wage reserve to household coffers","release_reserve")
		if c.lesson=="none": _add_commission_button("Begin funded drill · 2 food / 1 tool / one provisioned guard","lesson_start")
	if not c.is_empty() and c.arrears>0: _add_commission_button("Settle specialist's accrued wages","pay_arrears")
	_panel_text.text+="\n\n"+_commission_budget()
func _open_market() -> void:
	super._open_market()
	if model.commissioned() and model.commission().phase=="reserved":
		_add_commission_button("Present commission purse to the hiring agent","broker")
func _commission_budget() -> String:
	if not model.has_economy(): return "No household allowance has been entrusted yet."
	var s: Dictionary=model.economy().ledger;var b:=Contract.budget(s)
	var text: String="COMMITTED SERVICE · authored game quantities\nAvailable coffers %d · reserved contract purse %d · total arrears %d\nNext watch: %d wages (%d need unreserved cash), %d food, %d fodder.\nPersonal purse remains separate: %d."%[b.available,b.reserved,b.arrears,b.next_wages,b.next_unreserved_wages,b.food,b.feed,s.purse]
	if model.commissioned():
		var c: Dictionary=model.commission();var o: Dictionary=Contract.OFFERS[c.offer]
		text+="\n%s offer: agent %d, travel %d, signing %d, initial wage reserve %d; wage %d each watch.\nPhase %s · paid out %d · specialist arrears %d · drill %s."%[c.offer,o.agent,o.travel,o.signing,o.reserve,o.wage,c.phase,c.spent,c.arrears,c.lesson]
	text+="\nNo future harvest, unsigned agreement or undelivered income is counted as cash."
	return text
func _account_text() -> String: return super._account_text()+"\n\n"+_commission_budget()
func _open_journal() -> void:
	if not model.controlling_specialist():
		super._open_journal()
		if FileAccess.file_exists(YouthState.BRAWL_SAVE): _add_commission_button("Import earlier bazaar save · replace this whole run","import")
	else:
		var text: String="LOCAL INSTRUCTOR · MY PARTICIPATION\nI do not inherit Buddh's private journal or treasury authority.\n"
		for m in model.journal(): text+="\n"+m.text
		_show_dialog("INSTRUCTOR VIEWPOINT",text,[["Resume","resume"],["Save whole world","save"],["Load whole world","load"],["Main menu","menu"]])
	_sync_commission()
func _show_dialog(title: String,body: String,actions: Array) -> void:
	super._show_dialog(title,body,actions);_sync_commission()
func _resume() -> void:
	super._resume();_sync_commission()
func _speaker_for(kind: String) -> Vector3:
	return Contract.BROKER if kind=="broker" else specialist_body.global_position if kind=="engage" else Contract.HOME
func _visible_from(body: CharacterBody3D,target: Vector3,reach: float=4.8,face: bool=true) -> bool:
	if not Contract.near(body.global_position,target,reach): return false
	var eye: Vector3=body.global_position+Vector3.UP*1.35
	var d:=target-body.global_position;d.y=0
	var forward: Vector3=-body.pivot.global_basis.z;forward.y=0
	if face and d.length()>0.1 and forward.normalized().dot(d.normalized())<0.15: return false
	var q:=PhysicsRayQueryParameters3D.create(eye,target+Vector3.UP*1.1,1,[body.get_rid(),avatar.get_rid(),horse.get_rid(),specialist_body.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()
func _access(kind: String) -> String:
	var body: CharacterBody3D=specialist_body if model.controlling_specialist() else avatar
	if not _visible_from(body,_speaker_for(kind)): return "Face the nearby speaker at the same level in clear sight."
	if kind in ["appoint","control","lesson_start","dismiss"] and not _visible_from(specialist_body,Contract.HOME,4.8,false): return "The instructor must also be present, at ground level, with a clear path of sight."
	return ""
func _interact() -> void:
	if model.controlling_specialist():
		if not _visible_from(specialist_body,Contract.HOME): _message="Regroup at the quartermaster to begin a drill or return viewpoint.";return
		var actions: Array=[["Return to Buddh's viewpoint","commission:control|ranjit_singh"]]
		if model.commission().lesson=="none": actions.push_front(["Begin funded drill with the assigned guard","commission:lesson_start"])
		actions.append(["Return","resume"])
		_show_dialog("COMMISSIONED INSTRUCTOR", "Your appointment grants this work, not ownership of the treasury. A drill requires paid service, a provisioned pupil and material supplies.",actions);return
	if model.commissioned() and model.commission().phase=="introduced" and Model.distance(model.position(),Contract.RECEPTION)<3:
		if not _visible_from(avatar,specialist_body.global_position): _message="Meet the candidate in clear sight at the receiving yard.";return
		_show_dialog("THE CANDIDATE'S TERMS","Local instructor · The agent has introduced us. Travel and signing costs are separate. Walk back with me; I will not arrive at your household merely because time passes.\n\nThis person, appointment and prices are original gameplay fiction.",[["Accept terms and accompany the instructor home","commission:engage"],["Return","resume"]]);return
	super._interact()
func _unhandled_input(event: InputEvent) -> void:
	if not model.controlling_specialist():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
			_show_dialog("OFFICER CHAPTER DEVELOPMENT",preload("res://commissions/officer_catalogue.gd").notebook(),[["Return","resume"]]);return
		super._unhandled_input(event);return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_E: _interact_requested=not _paused
		KEY_F5: _save_requested=true
		KEY_F9: _load_requested=true
		KEY_J,KEY_B,KEY_ESCAPE,KEY_F1:
			if _paused: _resume()
			else: _open_journal()
		_: return
	get_viewport().set_input_as_handled()
func _physics_process(delta: float) -> void:
	if not _commission_action.is_empty():
		var parts:=_commission_action.split("|",true,1);_commission_action=""
		var kind: String=parts[0];var option: String=parts[1] if parts.size()>1 else ""
		if kind=="import": _load(YouthState.BRAWL_SAVE);return
		var error:=_access(kind)
		if error.is_empty(): error=model.commission_action(kind,option)
		_message=error if not error.is_empty() else {"reserve":"The commission is reserved, not spent or delivered. Carry it to the market agent.","broker":"Agent · My fee is paid. Meet the candidate in the receiving yard just north of here.","engage":"Instructor · I accept those terms. Walk back with me.","appoint":"The service agreement is signed. Wages and food are now ongoing obligations.","cancel":"Only the unspent balance returned. Agent work already paid is not refunded.","control":"Viewpoint changed; no person, item, knowledge or money was transferred.","lesson_start":"The drill is funded. Stay together with the pupil for three active seconds.","release_reserve":"The wage reserve is released. Future wages now depend on uncommitted funds.","pay_arrears":"The accrued specialist wages are settled.","dismiss":"Service ended. Earned but unpaid wages still remain an obligation."}.get(kind,"Commission recorded.")
		_sync_commission();_resume();return
	if model.controlling_specialist():
		if _load_requested: _load_requested=false;_load();return
		if _save_requested:
			_save_requested=false
			var error: String=model.save_to(save_path);_message="Whole world saved." if error.is_empty() else error
		if _paused: return
		# One existing clock; the waiting principal remains at his actual retained pose.
		model.advance()
		_step_specialist(delta,true)
		if _interact_requested: _interact_requested=false;_interact()
		model.progress_drill(_visible_from(specialist_body,Contract.HOME,4.8,false))
		_refresh();return
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if _paused or int(model.progress().tick)==before or not model.commissioned(): return
	if model.commission().phase=="escorting": _step_specialist(delta,false)
	model.progress_drill(_visible_from(specialist_body,Contract.HOME,4.8,false) and _visible_from(avatar,specialist_body.global_position,5,false))
	_sync_commission();_refresh()
func _step_specialist(delta: float,controlled: bool) -> void:
	var a: Dictionary=model.specialist();var contact: bool=true
	var stick:=Vector2.ZERO
	if controlled:
		stick=Input.get_vector("move_left","move_right","move_forward","move_backward")
	else:
		contact=_visible_from(specialist_body,model.position(),10,false)
		if contact and specialist_body.global_position.distance_to(model.position())>1.65:
			var waypoint: Vector3=_navigation.waypoint(specialist_body.global_position,model.position())
			var d:=waypoint-specialist_body.global_position;d.y=0
			if d.length()>0.15: specialist_body.pivot.rotation.y=atan2(-d.x,-d.z);stick=Vector2(0,-1)
	specialist_body.input_enabled=true;specialist_body.walk_speed=4.5 if controlled else 2.5;specialist_body.external_speed_limit=specialist_body.walk_speed
	specialist_body.step_motion(delta,stick,false)
	var record: Dictionary=a.duplicate(true);record.position=Model.coords(specialist_body.global_position)
	record.velocity=Model.coords(specialist_body.velocity);record.velocity[1]=minf(0,record.velocity[1]);record.yaw=wrapf(specialist_body.pivot.rotation.y,-PI,PI)
	var error: String=model.record_specialist(record,delta,contact)
	if not error.is_empty(): specialist_body.global_position=Model.point(a.position);specialist_body.velocity=Model.point(a.velocity);_message=error
	specialist_body.input_enabled=controlled and not _paused
func _refresh() -> void:
	if model.controlling_specialist():
		if not is_instance_valid(_hud): return
		var c: Dictionary=model.commission()
		_hud.text="1792 · LOCAL INSTRUCTOR · LIMITED VIEWPOINT\nWASD / mouse · E at quartermaster · J own participation · F5/F9 whole-world save\nContract: %s · specialist wage arrears %d · drill %s (%d/%d active ticks)"%[c.phase,c.arrears,c.lesson,model.specialist().practice,Contract.PRACTICE_TICKS]
		_caption.text=_message
		if is_instance_valid(_narrator_label): _narrator_label.hide()
		return
	super._refresh()
	if not is_instance_valid(_hud) or model.brawl_busy() or model.aftermath_phase()!="complete": return
	var c: Dictionary=model.commission()
	var hint: String="Ask the quartermaster about a funded instructor commission."
	if not c.is_empty(): hint={"reserved":"Carry the commission to the market agent.","introduced":"Meet the instructor in the receiving yard north of the market.","escorting":"Return together to the quartermaster. Keep visual contact.","appointed":"Instructor appointed. B: budget. E at home: viewpoint or funded drill.","cancelled":"Commission cancelled; spent fees remain spent.","dismissed":"Instructor dismissed; outstanding wages remain due."}[c.phase]
	_hud.text+="\nCOMMISSION · "+hint
func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is CommissionState and staged.commissioned() and not _navigation.fits(staged.specialist()): return "Saved specialist has no safe standing space. Load refused."
	return ""
func _load(path: String="") -> void:
	var staged:=CommissionState.new();var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole world, contract and viewpoint restored." if error.is_empty() else error
	_clear_pending_actions();_resume()
func _retry_bazaar() -> void:
	var staged:=CommissionState.new();var error:=staged.load_from(save_path+".bazaar-retry.json")
	if error.is_empty() and staged.brawl_phase()!="challenged": error="No pre-confrontation snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole pre-bazaar world restored." if error.is_empty() else error
	_clear_pending_actions();_resume()
