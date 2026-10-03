# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://remounts/remount_chapter.gd"
## Situated money, escort and limited viewpoint transfer in the SAME home world.
const CommissionState := preload("res://commissions/commission_state.gd")
const Contract := preload("res://commissions/commission_rules.gd")
const CommissionDirection := preload("res://commissions/commission_direction.gd")
const PlayerScene := preload("res://player/player.tscn")
var specialist_body: CharacterBody3D
var specialist_label: Label3D
var _commission_action := ""
var _commission_choices: Array[String]=[]
var _commission_context := ""
var _escort_contact_last := true
var _drill_eligible_last := true
var _drill_interrupted := false
var _commission_proxy: Node3D
var _practice_pupil: Node3D
var _commission_purse: MeshInstance3D
var _specialist_view_active := false
func _init() -> void:
	model=CommissionState.new();save_path=WorkshopState.WORKSHOP_SAVE
func _build_world() -> void:
	super._build_world()
	specialist_body=PlayerScene.instantiate();specialist_body.name="CommissionedSpecialist"
	specialist_body.menu_shortcut=false;specialist_body.movement_profile=0
	specialist_body.floor_snap_length=.18
	# A second body must not acquire the scene camera merely by being instantiated.
	specialist_body.get_node("CameraPivot/SpringArm3D/Camera3D").current=false
	add_child(specialist_body)
	specialist_body.get_node("HomeIdentity").hide();specialist_body.get_node("MeshInstance3D").hide()
	specialist_body.add_to_group("physical_home_agents")
	_commission_proxy=preload("res://player/locomotion_proxy.gd").new();_commission_proxy.name="LocomotionProxy";specialist_body.add_child(_commission_proxy)
	specialist_body.collision_mask=1;specialist_body.add_collision_exception_with(avatar);specialist_body.add_collision_exception_with(horse)
	specialist_body.get_node("CameraPivot/SpringArm3D").add_excluded_object(avatar.get_rid())
	specialist_label=Label3D.new();specialist_label.text="Local instructor · candidate [E]"
	specialist_label.position=Vector3(0,2.1,0);specialist_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	specialist_label.font_size=20;specialist_label.pixel_size=0.0015;specialist_label.fixed_size=true;specialist_body.add_child(specialist_label)
	# A receiving patch in the existing west-side lane, not a surveyed Eminabad yard.
	_box(Vector3(3.1,0.025,2),Contract.RECEPTION+Vector3(0,0.012,0),Color("887859"))
	var tag:=Label3D.new();tag.text="Receiving yard · original fiction";tag.position=Contract.RECEPTION+Vector3(0,2.8,0)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;tag.font_size=20;tag.pixel_size=0.0015;tag.fixed_size=true;add_child(tag)
	_commission_purse=MeshInstance3D.new();var pouch:=BoxMesh.new();pouch.size=Vector3(0.25,0.3,0.16);_commission_purse.mesh=pouch
	var leather:=StandardMaterial3D.new();leather.albedo_color=Color("947349");_commission_purse.material_override=leather
	_commission_purse.position=Vector3(0.38,0.8,0);avatar.add_child(_commission_purse)
	# An empty pale rectangle repeats the candidate's practical concern. It has
	# no collider or gameplay trigger; the real contact checks own the drill.
	_box(Vector3(1.0,0.012,1.25),Contract.POST+Vector3(0,-0.005,0),Color("b2a785"))
	_practice_pupil=Node3D.new();_practice_pupil.name="AssignedPracticePupil";add_child(_practice_pupil)
	_practice_pupil.position=Contract.POST
	for part in [[Vector3(.38,.65,.25),Vector3(0,.98,0),Color("6c7162")],[Vector3(.25,.28,.25),Vector3(0,1.48,0),Color("b69c78")],[Vector3(.14,.66,.15),Vector3(-.12,.34,0),Color("505c60")],[Vector3(.14,.66,.15),Vector3(.12,.34,0),Color("505c60")]]:
		var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=part[0];mesh.mesh=box;mesh.position=part[1]
		var mat:=StandardMaterial3D.new();mat.albedo_color=part[2];mat.roughness=1;mesh.material_override=mat;_practice_pupil.add_child(mesh)
	_sync_commission(true)
	_navigation.built=false
func _apply() -> void:
	super._apply();_sync_commission(true);_commission_context="";_drill_interrupted=false;_drill_eligible_last=true;_escort_contact_last=true
func _sync_commission(reset: bool=false) -> void:
	if not is_instance_valid(specialist_body): return
	var c: Dictionary=model.commission();var a: Dictionary=model.specialist()
	if is_instance_valid(_commission_proxy): _commission_proxy.set_process(not _paused)
	if is_instance_valid(_practice_pupil): _practice_pupil.visible=not c.is_empty() and c.phase=="appointed" and c.lesson=="active" and model.economy().ledger.duty_guards>c.guard_slot
	if reset:
		specialist_body.global_position=Model.point(a.position);specialist_body.velocity=Model.point(a.velocity)
		specialist_body.pivot.rotation.y=float(a.yaw)
		# Reconstruct native floor contact without spending saved travel. The same
		# admitted pose, velocity and camera angles remain exact after hydration.
		var retained_transform:=specialist_body.global_transform
		var retained_velocity:=specialist_body.velocity
		# Construction-only worlds may explicitly disable physics processing;
		# those bodies have no native space until the world is activated.
		if PhysicsServer3D.body_get_space(specialist_body.get_rid()).is_valid():
			specialist_body.apply_floor_snap()
		specialist_body.global_transform=retained_transform;specialist_body.velocity=retained_velocity
		if model.controlling_specialist():
			# The waiting principal also needs native ground history when an
			# instructor-view save was restored before this world was added.
			retained_transform=avatar.global_transform;retained_velocity=avatar.velocity
			if PhysicsServer3D.body_get_space(avatar.get_rid()).is_valid():
				avatar.apply_floor_snap()
			avatar.global_transform=retained_transform;avatar.velocity=retained_velocity
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
	specialist_label.visible=specialist_body.visible and not _paused and specialist_body.global_position.distance_to(_active_commission_body().global_position)<6.5
func _clear_pending_actions() -> void:
	super._clear_pending_actions();_commission_action="";_commission_choices.clear()
func _menu_action(action: String) -> void:
	if action.begins_with("commission:"):
		var choice:=action.trim_prefix("commission:")
		if _paused and choice in _commission_choices and _commission_action.is_empty(): _commission_action=choice
	elif model.controlling_specialist() and action not in ["resume","save","load","menu","journal"]:
		# An earlier principal menu may still own a deferred UI callback. Its
		# private story/account/training actions do not become this actor's view.
		return
	else: super._menu_action(action)
func _add_commission_button(text: String,action: String) -> void:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=42;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(_menu_action.bind("commission:"+action));_actions.add_child(b);_commission_choices.append(action);_layout()
func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy() or model.brawl_busy() or model.remount_busy(): return
	var c: Dictionary=model.commission()
	if c.is_empty() and not model._other_commitment() and not model.carrying_workshop():
		_add_commission_button("Ask what it takes to keep an instructor","terms")
	elif not c.is_empty() and c.phase in ["reserved","introduced"]: _add_commission_button("Cancel commission · return only unspent funds","cancel")
	elif not c.is_empty() and c.phase=="escorting": _add_commission_button("Sign with the physically returned instructor","appoint")
	elif not c.is_empty() and c.phase=="appointed":
		_add_commission_button("See the yard from the instructor's place","control|fictional_local_drillmaster")
		_add_commission_button("Dismiss instructor · accrued wages remain due","dismiss")
		if c.escrow>0: _add_commission_button("Release unspent wage reserve to household coffers","release_reserve")
		if c.lesson=="none": _add_commission_button("Begin funded drill · 2 food / 1 tool / one provisioned guard","lesson_start")
		elif c.lesson=="complete": _add_commission_button("Ask what it means to keep a place","after")
	if not c.is_empty() and c.arrears>0: _add_commission_button("Settle specialist's accrued wages","pay_arrears")
	if not c.is_empty() and c.phase=="escorting": _panel_text.text+="\n\n"+CommissionDirection.SIGNING
	_focus_household_continuation("home")
func _open_commission_terms() -> void:
	_show_dialog("KEEPING AN INSTRUCTOR",CommissionDirection.RESERVATION+"\n\nAvailable household coffers: %d."%model.economy().ledger.treasury,
		[["Reserve standard commission · 108 household coins","commission:reserve|standard"],["Reserve senior commission · 156 household coins","commission:reserve|senior"],["Continue your day","resume"]])
func _open_market() -> void:
	super._open_market()
	if model.commissioned() and model.commission().phase=="reserved":
		_add_commission_button("Present commission purse to the hiring agent","broker")
		_panel_text.text+="\n\n"+CommissionDirection.INTRODUCTION
	_focus_household_continuation("market")
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
	if not model.controlling_specialist(): super._open_journal()
	else:
		var text: String="LOCAL INSTRUCTOR · MY WORK HERE\n"
		for m in model.journal(): text+="\n"+m.text
		_show_dialog("INSTRUCTOR VIEWPOINT",text,[["Resume","resume"],["Save whole Home","save"],["Load whole Home","load"],["Main menu","menu"]])
	_sync_commission()
func _show_dialog(title: String,body: String,actions: Array) -> void:
	super._show_dialog(title,body,actions);_commission_choices.clear()
	for spec in actions:
		if String(spec[1]).begins_with("commission:"): _commission_choices.append(String(spec[1]).trim_prefix("commission:"))
	_sync_commission()
func _resume() -> void:
	_commission_action="";_commission_choices.clear()
	super._resume();_sync_commission()
func _active_commission_body() -> CharacterBody3D:
	return specialist_body if model.controlling_specialist() and is_instance_valid(specialist_body) else avatar
func foreground_actor() -> CharacterBody3D:
	return _active_commission_body()
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
	if is_instance_valid(training_session): return "Return from riding practice before speaking about this commission."
	if is_instance_valid(hawk_scout) and hawk_scout.active: return "Return to your own view before speaking."
	if model.mounted(): return "Dismount before speaking about this commission."
	var body:=_active_commission_body()
	var recorded: Vector3=Model.point(model.specialist().position) if model.controlling_specialist() else model.position()
	if body.global_position.distance_to(recorded)>.25: return "The speaker's recorded and physical positions disagree."
	if not body.is_on_floor(): return "Stand beside the speaker on solid ground."
	if not _visible_from(body,_speaker_for(kind)): return "Face the same nearby speaker at the same level in clear sight."
	if kind in ["appoint","control","lesson_start","dismiss","after"]:
		if not specialist_body.is_on_floor() or specialist_body.global_position.distance_to(Model.point(model.specialist().position))>.25: return "Let the instructor settle on clear ground."
		if not _visible_from(specialist_body,Contract.HOME,4.8,false) or not _visible_from(avatar,specialist_body.global_position,5,false): return "Bring Buddh and the instructor together in clear sight."
	return ""
func _drill_contact() -> bool:
	return is_instance_valid(specialist_body) and specialist_body.is_on_floor() and avatar.is_on_floor() and specialist_body.global_position.distance_to(Model.point(model.specialist().position))<=.25 and avatar.global_position.distance_to(model.position())<=.25 and _visible_from(specialist_body,Contract.HOME,4.8,false) and _visible_from(avatar,specialist_body.global_position,5,false)
func _interact() -> void:
	if model.controlling_specialist():
		if not _visible_from(specialist_body,Contract.HOME): _message="Regroup at the quartermaster to begin a drill or return viewpoint.";return
		var actions: Array=[["Return to Buddh's viewpoint","commission:control|ranjit_singh"]]
		if model.commission().lesson=="none": actions.push_front(["Begin funded drill with the assigned guard","commission:lesson_start"])
		actions.append(["Return","resume"])
		_show_dialog("COMMISSIONED INSTRUCTOR", "Instructor · The yard is still here. Keep a place ready for the pupil.\n\nBegin the funded drill, or return beside Buddh to his viewpoint.",actions);return
	if model.commissioned() and model.commission().phase=="introduced" and Model.distance(model.position(),Contract.RECEPTION)<3:
		if not _visible_from(avatar,specialist_body.global_position): _message="Meet the candidate in clear sight at the receiving yard.";return
		_show_dialog("THE CANDIDATE'S TERMS",CommissionDirection.CANDIDATE+"\n\nOriginal fictional instructor and agreement; authored prices.",[["Accept terms and accompany the instructor home","commission:engage"],["Return","resume"]]);return
	super._interact()
func _unhandled_input(event: InputEvent) -> void:
	if not model.controlling_specialist(): super._unhandled_input(event);return
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
		var choice:=_commission_action;_commission_action=""
		var parts:=choice.split("|",true,1)
		var kind: String=parts[0];var option: String=parts[1] if parts.size()>1 else ""
		var error: String="This commission choice is no longer open."
		if _paused and choice in _commission_choices:
			error=_access(kind)
			if error.is_empty() and kind=="terms":
				if model.commissioned(): error="The household already has an instructor agreement."
				else: _open_commission_terms();return
			elif error.is_empty() and kind=="after":
				if model.commission().lesson!="complete": error="Finish the practice before asking for its account."
				else: _show_dialog("KEEPING A PLACE",CommissionDirection.AFTER,[["Continue your day","resume"]]);return
			elif error.is_empty(): error=model.commission_action(kind,option)
		if not error.is_empty():
			_show_dialog("THE AGREEMENT WAITS",error,[["Return to your walk","resume"]]);return
		_message=CommissionDirection.line("control_instructor" if option==Contract.SPECIALIST else "control_buddh") if kind=="control" else CommissionDirection.line(kind)
		_sync_commission();_resume();return
	if model.controlling_specialist():
		if _load_requested: _load_requested=false;_load();return
		if _save_requested:
			_save_requested=false
			var error: String=model.save_to(save_path);_message="Whole Home saved." if error.is_empty() else error
		if _paused: return
		# One existing clock; the waiting principal retains his real pose.
		model.advance()
		_step_specialist(delta,true)
		if _interact_requested: _interact_requested=false;_interact()
		if not _paused: _advance_commission_drill()
		_sync_economy();_sync_water();_sync_workshop();_sync_remounts();_sync_commission();_refresh();return
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if _paused or int(model.progress().tick)==before or not model.commissioned(): return
	if model.commission().phase=="escorting":
		_step_specialist(delta,false)
		var contact:=_visible_from(specialist_body,model.position(),10,false)
		if _commission_context=="escorting" and contact!=_escort_contact_last:
			_message=CommissionDirection.line("rejoined" if contact else "separated")
		_escort_contact_last=contact
	_advance_commission_drill()
	_commission_context=model.commission().phase
	_sync_commission();_refresh()
func _advance_commission_drill() -> void:
	var c: Dictionary=model.commission()
	if c.lesson!="active": return
	var eligible: bool=_drill_contact() and Contract.ready(model.economy().ledger) and model.economy().ledger.duty_guards>c.guard_slot and Contract.near(model.position(),Contract.HOME,4) and Contract.near(specialist_body.global_position,Contract.HOME,4)
	if eligible!=_drill_eligible_last:
		if not eligible: _drill_interrupted=true;_message=CommissionDirection.line("drill_paused")
		elif _drill_interrupted: _message=CommissionDirection.line("drill_resumed")
	_drill_eligible_last=eligible
	model.progress_drill(eligible)
	if model.commission().lesson=="complete": _message=CommissionDirection.line("lesson_complete")
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
func foreground_guidance(moving: bool=false) -> Dictionary:
	var result:=CommissionDirection.read(self,moving)
	return result if not result.is_empty() else super.foreground_guidance(moving)
func _refresh() -> void:
	super._refresh()
	_sync_commission()
	if model.controlling_specialist():
		if is_instance_valid(_narrator_label): _narrator_label.hide()
		if is_instance_valid(_veil): _veil.hide()
		if is_instance_valid(art) and is_instance_valid(art.detail) and is_instance_valid(art.detail.hud): art.detail.hud.sample()
func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is CommissionState and staged.commissioned() and not _navigation.fits(staged.specialist()): return "Saved specialist has no safe standing space. Load refused."
	return ""
