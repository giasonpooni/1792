# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://history/childhood_intro_chapter.gd"
## Camp, invitations and mounted companions on the original Home entry and executor.
const CampState := preload("res://warband/nihang_state.gd")
const CampRules := preload("res://warband/nihang_rules.gd")
const CampView := preload("res://warband/nihang_camp_view.gd")
const CampFigure := preload("res://youth/performance/bazaar_figure.gd")
var camp_view: Node3D
var camp_horses: Array[CharacterBody3D]=[]
var camp_figures: Array[Node3D]=[]
var _camp_nav:=Navigation.new()
var _camp_action:=""
var _camp_choices: Array[String]=[]

func _init() -> void:
	model=CampState.new();save_path=WorkshopState.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	camp_view=CampView.new();add_child(camp_view);camp_view.build()
	for i in range(2):
		var mount: CharacterBody3D=Horse.instantiate();mount.name="CampMount%d"%i
		add_child(mount);mount.collision_layer=2;mount.collision_mask=1;mount.gait_speed_limit=CampRules.SPEED
		# Preserve the common motor and legacy rider anchors; tint this owned projection.
		for part in mount._rider.get_children():
			if part is MeshInstance3D:
				var material: StandardMaterial3D=part.material_override.duplicate()
				material.albedo_color=Color("294965") if part.position.y>2.65 or part.position.y<2.4 else Color("ab8966")
				part.material_override=material
		camp_horses.append(mount)
		var figure:=CampFigure.new();add_child(figure);figure.build(4,false);CampView.dress(figure);camp_figures.append(figure)
	_camp_nav.hull.radius=.84;_camp_nav.hull.height=3.2
	_camp_nav.sweep_height=1.65;_camp_nav.clearance_height=1.8;_camp_nav.clearance_size=Vector3(1.9,3.2,1.9)
	_camp_nav.bind(get_world_3d(),[avatar.get_rid(),horse.get_rid(),attacker.get_rid(),escort.get_rid(),camp_horses[0].get_rid(),camp_horses[1].get_rid()])
	_sync_camp(true)

func _sync_camp(reset: bool=false) -> void:
	if not is_instance_valid(camp_view): return
	var state: Dictionary=model.nihang_camp()
	for i in range(2):
		var joined: bool=CampRules.active(state.phase) and CampRules.RIDERS[i] in state.selected
		if reset:
			var record: Dictionary=state.mounts[i].duplicate(true);record.rider_id=CampRules.RIDERS[i] if joined else ""
			camp_horses[i].apply_record(record)
		camp_horses[i]._rider.visible=joined
		camp_figures[i].visible=not joined
		camp_figures[i].position=CampRules.point(state.mounts[i].position)+Vector3(1.1,0,0)
	camp_view.sample(int(model.progress().tick),state.phase)

func _camp_access(kind: String) -> String:
	if avatar.global_position.distance_to(model.position())>.25: return "Your physical and recorded positions disagree."
	var at: Vector3=CampRules.HORSE_LINES[0] if kind=="care" else CampRules.TURN if kind=="turn" else CampRules.CAMP
	if kind=="turn":
		if not model.mounted() or not horse.is_on_floor(): return "Reach the practice marker mounted on solid ground."
		if model.position().distance_to(at)>3.0: return "Reach the practice marker with your companions."
		# The veteran must actually be audible through an unobstructed line.
		var veteran: Vector3=camp_horses[0].global_position
		var ray:=PhysicsRayQueryParameters3D.create(horse.global_position+Vector3.UP*2.4,veteran+Vector3.UP*2.4,1,[horse.get_rid(),avatar.get_rid()])
		if veteran.distance_to(horse.global_position)>7 or not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Wait within clear calling distance of the veteran."
	else:
		if model.mounted() or not avatar.is_on_floor(): return "Stand on foot beside the camp speaker."
		if model.position().distance_to(at)>3 or not _seen(at+Vector3.UP*1.35,4.5): return "Face the nearby camp speaker from clear ground."
	return ""

func _interact() -> void:
	var camp: Dictionary=model.nihang_camp()
	if model.mounted() and camp.phase=="outbound" and model.position().distance_to(CampRules.TURN)<3:
		var error:=_camp_access("turn")
		if error.is_empty(): error=model.camp_action("turn",true,true)
		_message=error if not error.is_empty() else CampRules.WORDS.turn
		_refresh();return
	if not model.mounted() and camp.phase=="acquainted" and model.position().distance_to(CampRules.HORSE_LINES[0])<2.5:
		_open_camp("care");return
	if not model.mounted() and model.position().distance_to(CampRules.CAMP)<2.5:
		_open_camp();return
	super._interact()

func _open_camp(kind: String="") -> void:
	var error:=_camp_access(kind)
	if not error.is_empty(): _message=error;return
	var camp: Dictionary=model.nihang_camp()
	var body: String="The elder recognises you from earlier visits with your father. Two familiar riders tend the horses nearby."
	var choices: Array=[]
	if kind=="care":
		body="The veteran waits beside the horse. Look over its tack and listen before asking to ride."
		choices=[["Inspect the tack and hear the veteran","camp:care"]]
	else:
		match camp.phase:
			"unmet": choices=[["Greet the elder and the riders","camp:meet"]]
			"acquainted": body=CampRules.WORDS.meet
			"prepared":
				body="%s, take your own household horse. Ask one rider or both to accompany you to the north marker and back. Complete the first household riding gate before setting out."%model.nihang_address(CampRules.ELDER)
				choices=[["Invite the veteran to ride with me","camp:invite_one"],["Invite both familiar riders","camp:invite_two"]]
			"outbound", "returning":
				body="%s, our undertaking is the north practice marker and back. Bring everyone home before we settle it."%model.nihang_address(CampRules.ELDER)
				if camp.phase=="returning": choices.append(["Return together and thank the riders","camp:return"])
				choices.append(["End this outing here with everyone present","camp:cancel"])
			"complete": body=CampRules.WORDS["return"]
			"cancelled": body=CampRules.WORDS.cancel
	choices.append(["Leave the conversation","resume"])
	_show_dialog("THE CAMP · FAMILIAR VOICES",body,choices)
	for choice in choices:
		if choice[1].begins_with("camp:"): _camp_choices.append(choice[1].trim_prefix("camp:"))

func _menu_action(action: String) -> void:
	if action.begins_with("camp:"):
		var kind:=action.trim_prefix("camp:")
		if _paused and kind in _camp_choices and _camp_action.is_empty(): _camp_action=kind
		return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_camp_action="";_camp_choices.clear()

func _resume() -> void:
	_camp_action="";_camp_choices.clear();super._resume()

func training_entry_error() -> String:
	if model.nihang_active(): return "Return your camp companions before entering a separate riding lesson."
	return super.training_entry_error()

func _physics_process(delta: float) -> void:
	if not _camp_action.is_empty():
		var kind:=_camp_action;_camp_action=""
		var error:=_camp_access(kind)
		if error.is_empty(): error=model.camp_action(kind,true,true)
		_message=error if not error.is_empty() else CampRules.WORDS[kind]
		_sync_camp();_resume();return
	var before: int=int(model.progress().tick)
	super._physics_process(delta)
	if not _paused and model.nihang_active() and int(model.progress().tick)>before:
		_step_camp(delta)
	_sync_camp()

func _step_camp(delta: float) -> void:
	var state: Dictionary=model.nihang_camp()
	var records: Array=state.mounts.duplicate(true)
	for i in range(2):
		if CampRules.RIDERS[i] not in state.selected: continue
		var mount: CharacterBody3D=camp_horses[i]
		# When back on foot by the elder, park in separate nearby slots to allow check-in.
		var parking: bool=not model.mounted() and model.position().distance_to(CampRules.CAMP)<3
		var goal: Vector3=CampRules.HORSE_LINES[i] if parking else model.position()+Vector3(-2.2 if i==0 else 2.2,0,3.5)
		var waypoint:=_camp_nav.waypoint(mount.global_position,goal)
		var offset:=waypoint-mount.global_position;offset.y=0
		var difference:=wrapf(atan2(-offset.x,-offset.z)-mount.rotation.y,-PI,PI)
		var stop: bool=offset.length()<.8 or absf(difference)>.8
		var motion: Dictionary=mount.step(delta,0.0 if stop else 1.0,clampf(-difference*2,-1,1),false,false,stop)
		motion.id=CampRules.RIDERS[i];records[i]=motion
	var error: String=model.record_nihang_motion(records,delta)
	if not error.is_empty():
		_sync_camp(true);_message=error

func _apply() -> void:
	super._apply();_sync_camp(true)

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty() or not staged is CampState: return error
	var state: Dictionary=staged.nihang_camp()
	for i in range(camp_horses.size()):
		if not camp_horses[i].record_fits_world(state.mounts[i],avatar): return "A camp horse has no clear standing room. Home unchanged."
	return ""

func _restore_workshop_file(path: String,retry: bool) -> void:
	var staged:=CampState.new();var error: String=staged.load_from(path)
	if error.is_empty() and retry and staged.brawl_phase()!="challenged": error="No pre-confrontation bazaar snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole Home restored, including camp agreements and companions." if error.is_empty() else error
	_clear_pending_actions();_resume()

func _capture_checkpoint(reason: String) -> void:
	var error:=_candidate_error(model)
	var snapshot: Dictionary=model.snapshot()
	if snapshot.riding_skills.lesson_receipts.is_empty(): snapshot.erase("riding_skills")
	if error.is_empty(): error=Checkpoint.write(checkpoint_path(),snapshot,avatar.pivot.rotation,reason,CampState)
	_checkpoint_note="Checkpoint saved with camp relationships." if error.is_empty() else "Checkpoint not saved: "+error
	_message+="\n"+_checkpoint_note

func _restore_checkpoint() -> void:
	var result:=Checkpoint.read(checkpoint_path(),CampState)
	var error: String=result.error;var staged:=CampState.new()
	if error.is_empty(): error=staged.restore(result.envelope.snapshot)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if not error.is_empty():
		_show_dialog("CHECKPOINT NOT RESTORED",error+"\nYour Home is unchanged.",[["Return","resume"],["Load manual save","load"],["Main menu","menu"]]);return
	_apply();avatar.pivot.rotation=Vector3(result.envelope.camera[0],result.envelope.camera[1],0)
	_clear_pending_actions();_message="Whole Home checkpoint restored, including camp relationships.";_resume()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var camp: Dictionary=model.nihang_camp()
	if CampRules.active(camp.phase):
		_hud.text+="\nCAMP RIDE · %d companion(s) · %s"%[camp.selected.size(),"ride to the north marker together [E]" if camp.phase=="outbound" else "return to the camp elder together [E]"]
	elif model.position().distance_to(CampRules.CAMP)<10:
		_hud.text+="\nNIHANG CAMP · Speak to the elder; listen beside the horse lines [E]."
