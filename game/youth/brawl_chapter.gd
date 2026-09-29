# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://misl/service_chapter.gd"
## The same home entry and physics executor, extended with a local youth encounter.
const YouthState := preload("res://youth/brawl_state.gd")
const Brawl := preload("res://youth/brawl_rules.gd")
const Dialogue := preload("res://youth/performance/bazaar_script.gd")
const Catalogue := preload("res://youth/catalogue.gd")
const Blocking := preload("res://youth/performance/bazaar_companion_blocking.gd")
var youths: Array[CharacterBody3D]=[]
var youth_rigs: Array[Node3D]=[]
var _youth_action := ""
func _init() -> void:
	model=YouthState.new();save_path=YouthState.BRAWL_SAVE
func _build_world() -> void:
	super._build_world()
	var records:=Brawl.actors()
	for i in range(5):
		var actor: CharacterBody3D=EscortAgent.new()
		actor.entity_id=Brawl.IDS[i];actor.move_speed=Brawl.SPEED
		actor.name=Brawl.IDS[i];add_child(actor);actor.apply(records[i])
		actor.caption.text=["Bazaar challenger","Challenger's companion","Challenger's companion","Mela · friend","Jiva · friend"][i]
		actor.add_collision_exception_with(avatar);actor.add_collision_exception_with(horse)
		youths.append(actor)
		var rig:=Node3D.new();rig.name="PresentationRig";actor.add_child(rig)
		for child in actor.get_children():
			if child==rig or child is CollisionShape3D or child is Label3D: continue
			if child is Node3D: child.reparent(rig)
			if child is MeshInstance3D and child.position.y>1.0 and child.position.y<1.2:
				var mat: StandardMaterial3D=child.material_override.duplicate()
				mat.albedo_color=Color("8d5544") if i<3 else Color("557b7d")
				child.material_override=mat
		youth_rigs.append(rig)
	# Ground dressing only; no false enclosure or new combat collision arena.
	_box(Vector3(10,0.015,7),Brawl.RING+Vector3(0,0.005,0),Color("a78f69"))
	var sign:=Label3D.new();sign.text="Bazaar approach · an authored youth tale"
	sign.position=Brawl.RING+Vector3(0,3.2,-3);sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size=20;sign.pixel_size=0.002;add_child(sign)
	_sync_youth(true)
func _apply() -> void:
	super._apply();_sync_youth(true)
func _sync_youth(reset: bool=false) -> void:
	if youths.size()!=5: return
	var phase: String=model.brawl_phase()
	var records: Array=model.brawl().actors if model.has_brawl() else Brawl.actors()
	for i in range(5):
		var actor: CharacterBody3D=youths[i]
		actor.visible=(i>=3 and model.aftermath_phase()=="complete") or phase!="none"
		if phase=="reported": actor.visible=false
		actor.collision_layer=2 if actor.visible else 0
		if reset: actor.apply(records[i])
		var down: bool=i<3 and model.has_brawl() and model.brawl().ledger.down[i]
		# Pose only the visual rig; never shrink a collision capsule to pass a test.
		youth_rigs[i].scale.y=0.5 if down else 1.0
		if i<3:
			var raised: bool=phase=="fighting" and not down and Brawl.attack_phase(int(model.progress().tick),int(model.brawl().ledger.start_tick),i) in range(80,106)
			for mesh in youth_rigs[i].get_children():
				if mesh is MeshInstance3D and mesh.position.x>0.3 and mesh.position.y<=1.14: mesh.rotation.x=-1.2 if raised else 0.0
			actor.caption.text="Out of the fight" if down else "Strike raised · Q" if phase=="fighting" and Brawl.attack_phase(int(model.progress().tick),int(model.brawl().ledger.start_tick),i) in range(80,106) else "Bazaar challenger"
func _clear_pending_actions() -> void:
	super._clear_pending_actions();_youth_action=""
func _menu_action(action: String) -> void:
	if action.begins_with("youth:"): _youth_action=action.trim_prefix("youth:")
	else: super._menu_action(action)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_T:
		if not _paused: _show_dialog("YOUTH STORIES · DEVELOPMENT SLATE",Catalogue.notebook(),[["Return","resume"]])
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)
func _youth_button(label: String,action: String) -> void:
	var button:=Button.new();button.text=label;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("youth:"+action));_actions.add_child(button);_actions.move_child(button,0);_layout()
func _open_market() -> void:
	super._open_market()
	if not model.has_brawl(): _youth_button("Walk with Mela and Jiva · the bazaar story","invite")
func _open_quartermaster() -> void:
	super._open_quartermaster()
	if model.brawl_phase()=="returning": _youth_button("Give the bazaar account with both friends present","report")
func _open_journal() -> void:
	super._open_journal()
	if FileAccess.file_exists(ServiceState.SERVICE_SAVE): _youth_button("Import prior household-service save (replaces this run)","import")
func _interact() -> void:
	var phase: String=model.brawl_phase()
	if phase in ["invited","challenged"] and Model.distance(model.position(),youths[0].global_position)<3.2:
		if not _seen(youths[0].global_position+Vector3.UP*1.4,4.5): _message="Face the challenger in clear sight.";return
		if phase=="invited":
			var error: String=model.brawl_action("challenge")
			if not error.is_empty(): _message=error;return
		_show_dialog("AT THE BAZAAR · A SHORT WALK",Dialogue.CHALLENGE,[["Stand with my friends","youth:stand"],["Walk away together","youth:leave"],["Hear Mela and Jiva","youth:listen"],["Consider the challenge","resume"]])
		return
	if phase in ["fighting","leaving"]:
		_message="Get both friends to the open household approach. Fight with Q and left click, or make distance.";return
	super._interact()
func _youth_access(kind: String) -> String:
	if model.mounted(): return "Dismount before this conversation."
	var at: Vector3=Rules.MARKET if kind=="invite" else Rules.QUARTERMASTER if kind=="report" else youths[0].global_position
	if Model.distance(model.position(),at)>3.2 or not _seen(at+Vector3.UP*1.4,4.5): return "Return to the nearby speaker and face them in clear sight."
	return ""
func _physics_process(delta: float) -> void:
	if not _youth_action.is_empty():
		var kind:=_youth_action;_youth_action=""
		if kind in ["listen","answer"]:
			if model.brawl_phase()!="challenged" or not _youth_access(kind).is_empty() or not _contact(youths[3]) or not _contact(youths[4]) or Model.distance(model.position(),youths[3].global_position)>5 or Model.distance(model.position(),youths[4].global_position)>5:
				_message="Bring both friends close enough to speak, in sight of the challenger.";_resume();return
			if kind=="answer": _interact()
			else: _show_dialog("BETWEEN FRIENDS",Dialogue.FRIENDS,[["Stand with my friends","youth:stand"],["Walk away together","youth:leave"],["Back to the challenger","youth:answer"]])
			return
		if kind=="import": _load(ServiceState.SERVICE_SAVE);return
		if kind=="retry": _retry_bazaar();return
		var error:=_youth_access(kind)
		if error.is_empty() and kind in ["stand","leave"]:
			# A full-world sidecar, not progress/resource merging or a second live state.
			error=model.save_to(save_path+".bazaar-retry.json")
		if error.is_empty(): error=model.begin_brawl() if kind=="invite" else model.brawl_action(kind)
		_message=error if not error.is_empty() else {"invite":Dialogue.INVITE,"stand":Dialogue.STAND,"leave":Dialogue.LEAVE,"report":Dialogue.REPORT.get(model.brawl().ledger.outcome,"")}.get(kind,"Account received.")
		_sync_youth(true);_resume();return
	if model.brawl_phase()=="caught":
		if _load_requested: _load_requested=false;_load();return
		if _retry_requested: _retry_requested=false;_restore_checkpoint();return
		if _save_requested: _save_requested=false;_message=model.save_to(save_path)
		if not _paused: _show_dialog("CAUGHT IN THE CRUSH","This attempt ended after three unguarded blows. Retry restores the whole pre-confrontation world, including supplies, clock and memories.",[["Retry the bazaar confrontation","youth:retry"],["Load manual save","load"],["Main menu","menu"]])
		return
	var strike: bool=_strike_requested
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if _paused or int(model.progress().tick)==before or not model.has_brawl(): return
	_step_youth(delta,strike);_sync_youth();_refresh()
func _contact(actor: CharacterBody3D) -> bool:
	if Model.distance(actor.global_position,model.position())>12: return false
	var ray:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.4,avatar.global_position+Vector3.UP*1.35,1,[avatar.get_rid(),horse.get_rid(),actor.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func _step_youth(delta: float,strike: bool) -> void:
	var s: Dictionary=model.brawl();var phase: String=s.ledger.phase
	if phase in ["caught","reported"]: return
	var tick: int=int(model.progress().tick)
	for i in range(5):
		var actor: CharacterBody3D=youths[i]
		var contact:=_contact(actor)
		var target: Vector3=Blocking.target(model.position(),phase,i) if i>=3 else model.position()
		var active: bool=true if i>=3 else phase=="fighting" and not s.ledger.down[i] and tick>s.ledger.stun_until[i] and Brawl.attack_phase(tick,int(s.ledger.start_tick),i)<80
		var moving: bool=active and contact and Model.distance(actor.global_position,target)>(0.65 if i>=3 else 2.0)
		var waypoint: Vector3=_navigation.waypoint(actor.global_position,target) if moving else actor.global_position
		var record: Dictionary=actor.step(delta,waypoint,moving)
		var error: String=model.record_brawl_actor(i,record,delta,contact)
		if not error.is_empty(): actor.apply(s.actors[i]);_message=error
	if phase=="fighting":
		for i in range(3):
			if model.brawl_phase()!="fighting": break
			var actor: CharacterBody3D=youths[i]
			var ledger: Dictionary=model.brawl().ledger
			if ledger.down[i] or not _contact(actor) or Model.distance(actor.global_position,model.position())>2.85: continue
			if Brawl.attack_phase(tick,int(ledger.start_tick),i)==105 and tick>ledger.stun_until[i]:
				var guarded: bool=Input.is_key_pressed(KEY_Q) and _facing(actor.global_position)
				var error: String=model.brawl_action("parry" if guarded else "hit",i)
				_message=error if not error.is_empty() else "The blow is checked. Counter now [left click]." if guarded else "A blow landed. Face the next attack or create distance."
			if strike and ledger.stun_until[i]>=tick and _facing(actor.global_position):
				var error: String=model.brawl_action("counter",i)
				if error.is_empty(): strike=false;_message="The challenger is out of this fight. Bring both friends home."
	if model.brawl_phase() in ["fighting","leaving"] and Model.distance(model.position(),Brawl.REGROUP)<3.2:
		var error: String=model.brawl_action("regroup")
		_message="We are together. Bring the account to the quartermaster [E]." if error.is_empty() else error
func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var phase: String=model.brawl_phase()
	var hint: String={"none":"After the inquiry, meet Mela and Jiva at the market.","invited":"Walk southeast with both friends; face the challenger and press E.","challenged":"Answer the challenger [E]: stand or leave together.","fighting":"Q guard · left click counter · regroup with both friends at the household approach.","leaving":"Walk to the household approach together; return for any friend left behind.","returning":"Give your account to the quartermaster with both friends present.","reported":"The bazaar episode is complete; your account remains in J.","caught":"The attempt ended. Retry or load an earlier whole-world save."}.get(phase,"")
	if model.brawl_busy():
		_hud.text="1792 · BUDDH SINGH · BAZAAR OUTING\n\n"+hint+"\n\nWASD / Mouse · E speak · Q guard · left click counter · F5/F9 save/load · J journal\nT: story-development slate · F2: reconstruction notes"
	else:
		_hud.text+="\nYOUTH · "+hint+"  T: story-development slate"
	if phase=="fighting": _hud.text+="\nUnguarded blows: %d / 3 · Opponents checked: %d / 3"%[model.brawl().ledger.hits,model.brawl().ledger.down.count(true)]
func _resume() -> void:
	super._resume()
	if model.brawl_phase()=="caught": avatar.input_enabled=false;avatar.set_physics_process(false)
func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is YouthState and staged.has_brawl():
		for actor in staged.brawl().actors:
			if not _navigation.fits(actor): return "A bazaar participant has no standing room. Load refused."
	return ""
func _load(path: String="") -> void:
	var staged:=YouthState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole home world and youth episode restored." if error.is_empty() else error
	_clear_pending_actions();_resume()
func _retry_bazaar() -> void:
	var staged:=YouthState.new()
	var error:=staged.load_from(save_path+".bazaar-retry.json")
	if error.is_empty() and staged.brawl_phase()!="challenged": error="No pre-confrontation bazaar snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Pre-confrontation world restored; no later supplies or memories retained." if error.is_empty() else error
	_clear_pending_actions();_resume()
