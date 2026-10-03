# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://history/childhood_intro_chapter.gd"
## Camp, invitations and mounted companions on the original Home entry and executor.
const CampState := preload("res://warband/nihang_state.gd")
const CampRules := preload("res://warband/nihang_rules.gd")
const CampView := preload("res://warband/nihang_camp_view.gd")
const Formation := preload("res://warband/mounted_formation.gd")
const CampFigure := preload("res://youth/performance/bazaar_figure.gd")
var camp_view: Node3D
var camp_horses: Array[CharacterBody3D]=[]
var camp_figures: Array[Node3D]=[]
var _camp_nav:=Navigation.new()
var _camp_action:=""
var _camp_choices: Array[String]=[]
var _camp_formation:="paired"
var _care_page:=-1

func _init() -> void:
	model=CampState.new();save_path=WorkshopState.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	camp_view=CampView.new();add_child(camp_view);camp_view.build()
	for i in range(2):
		var mount: CharacterBody3D=Horse.instantiate();mount.name="CampMount%d"%i
		add_child(mount);Formation.configure(mount);mount.gait_speed_limit=CampRules.SPEED
		# Preserve the common motor and legacy rider anchors; tint this owned projection.
		for part in mount._rider.get_children():
			if part is MeshInstance3D:
				var material: StandardMaterial3D=part.material_override.duplicate()
				material.albedo_color=Color("294965") if part.position.y>2.65 or part.position.y<2.4 else Color("ab8966")
				part.material_override=material
		camp_horses.append(mount)
		var figure:=CampFigure.new();add_child(figure);figure.build(4,false);CampView.dress(figure);camp_figures.append(figure)
	Formation.configure_navigation(_camp_nav)
	_camp_nav.bind(get_world_3d(),[avatar.get_rid(),horse.get_rid(),attacker.get_rid(),escort.get_rid(),camp_horses[0].get_rid(),camp_horses[1].get_rid()])
	_enable_camp_collision()
	_sync_camp(true)

func _enable_camp_collision() -> void:
	horse.collision_mask=1|Formation.TRAFFIC_LAYER
	if not model.mounted(): avatar.collision_mask=1|Formation.TRAFFIC_LAYER
	avatar.get_node("CameraPivot/SpringArm3D").collision_mask=1|Formation.TRAFFIC_LAYER

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
	if kind=="care": _show_care_page(0);return
	var camp: Dictionary=model.nihang_camp()
	var body: String="A familiar voice reaches you before anyone stands.\n\nBuddh. Come closer. Your father's companions are tending their horses; the elder makes room for you beside them."
	var choices: Array=[]
	match camp.phase:
		"unmet": choices=[["Greet the elder and the riders","camp:meet"]]
		"acquainted": body=CampRules.WORDS.meet
		"prepared":
			body="%s, your own horse; our company. Ask the veteran to ride with you, or bring both riders. The undertaking is the north marker and home again. Wait for one another."%model.nihang_address(CampRules.ELDER)
			choices=[["Invite the veteran to ride with me","camp:invite_one"],["Invite both familiar riders","camp:invite_two"]]
		"outbound", "returning":
			body="%s, our undertaking is the north practice marker and back. Bring everyone home before we settle it."%model.nihang_address(CampRules.ELDER)
			if camp.phase=="returning": choices.append(["Return together and thank the riders","camp:return"])
			choices.append(["End this outing here with everyone present","camp:cancel"])
		"complete": body=CampRules.WORDS["return"]+"\n\nThe elder makes room beside the mat. The horse-care lesson has become an undertaking you kept."
		"cancelled": body=CampRules.WORDS.cancel
	choices.append(["Leave the conversation","resume"])
	_show_dialog("THE CAMP · FAMILIAR VOICES",body,choices)
	for choice in choices:
		if choice[1].begins_with("camp:"): _camp_choices.append(choice[1].trim_prefix("camp:"))

func _show_care_page(page: int) -> void:
	var beat: Dictionary=CampRules.CARE_BEATS[page]
	var action: String=["care_footing","care_return","care"][page]
	_show_dialog(beat.title,beat.body,[[beat.choice,"camp:"+action],["Leave the conversation","resume"]])
	# _show_dialog clears pending actions; arm only the displayed page afterwards.
	_care_page=page;_camp_choices.append(action)

func _menu_action(action: String) -> void:
	if action.begins_with("camp:"):
		var kind:=action.trim_prefix("camp:")
		if _paused and kind in _camp_choices and _camp_action.is_empty(): _camp_action=kind
		return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_camp_action="";_camp_choices.clear();_care_page=-1

func _resume() -> void:
	_camp_action="";_camp_choices.clear();_care_page=-1;super._resume()

func training_entry_error() -> String:
	if model.nihang_active(): return "Return your camp companions before entering a separate riding lesson."
	return super.training_entry_error()

func _physics_process(delta: float) -> void:
	if not _camp_action.is_empty():
		var kind:=_camp_action;_camp_action=""
		var beat: bool=kind in ["care_footing","care_return"]
		var error:=_camp_access("care" if beat else kind)
		if beat:
			var expected:=0 if kind=="care_footing" else 1
			if error.is_empty() and (_care_page!=expected or model.nihang_camp().phase!="acquainted"):
				error="Return to the veteran before continuing the horse-care conversation."
			if error.is_empty(): _show_care_page(expected+1)
			else: _message=error;_resume()
			return
		if kind=="care" and _care_page!=2: error="Finish the horse-care conversation with the veteran."
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
	var riders: Array[CharacterBody3D]=[]
	var ignored: Array[RID]=[horse.get_rid(),avatar.get_rid(),camp_horses[0].get_rid(),camp_horses[1].get_rid()]
	for i in range(2):
		if CampRules.RIDERS[i] in state.selected: riders.append(camp_horses[i])
	var arrangement:=Formation.layout(horse,riders,func(body,goal): return Formation.Terrain.path_clear(body,goal,ignored))
	_camp_formation=arrangement.mode
	for i in range(2):
		if CampRules.RIDERS[i] not in state.selected: continue
		var mount: CharacterBody3D=camp_horses[i]
		# When back on foot by the elder, park in separate nearby slots to allow check-in.
		var parking: bool=not model.mounted() and model.position().distance_to(CampRules.CAMP)<3
		var yaw: float=horse.rotation.y if model.mounted() else avatar.rotation.y
		var goal: Vector3=CampRules.HORSE_LINES[i] if parking else Formation.slot(model.position(),yaw,i)
		if model.mounted(): goal=arrangement.goals[riders.find(mount)]
		var others: Array[CharacterBody3D]=[horse,avatar,camp_horses[0],camp_horses[1]]
		var traffic_goal:=goal if model.mounted() and _camp_formation=="single file" else Formation.traffic_goal(mount,goal,others)
		var waypoint:=traffic_goal if Formation.Terrain.path_clear(mount,traffic_goal,ignored) else _camp_nav.waypoint(mount.global_position,traffic_goal)
		var motion: Dictionary=Formation.step(mount,waypoint,delta)
		motion.id=CampRules.RIDERS[i];records[i]=motion
	var error: String=model.record_nihang_motion(records,delta)
	if not error.is_empty():
		_sync_camp(true);_message=error

func _apply() -> void:
	super._apply();_enable_camp_collision();_sync_camp(true)

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty() or not staged is CampState: return error
	var state: Dictionary=staged.nihang_camp()
	var staged_peers: Array[RID]=[horse.get_rid()]
	for i in range(camp_horses.size()):
		if not camp_horses[i].record_fits_world(state.mounts[i],avatar,staged_peers): return "A camp horse has no clear standing room. Home unchanged."
	# Test staged poses against one another, never against their stale live projections.
	var poses: Array=state.mounts
	if not Formation.separated(CampRules.point(poses[0].position),CampRules.point(poses[1].position),1.6):
		return "Saved camp horses overlap. Home unchanged."
	for pose in poses:
		var at:=CampRules.point(pose.position)
		if not Formation.separated(at,CampRules.point(staged.horse_record().position),1.6):
			return "A saved camp horse overlaps the household horse. Home unchanged."
		if not staged.mounted() and not Formation.separated(at,staged.position(),1.15):
			return "A saved camp horse overlaps the walking player. Home unchanged."
	return ""

func _restore_workshop_file(path: String,retry: bool) -> void:
	var staged:=CampState.new();var error: String=staged.load_from(path)
	if error.is_empty() and retry and staged.brawl_phase()!="challenged": error="No pre-confrontation bazaar snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	# Retain the established successful-load cue consumed by opening qualification.
	_message="Whole Home and riding skills restored." if error.is_empty() else error
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

func camp_guidance() -> Dictionary:
	# A read-only projection of the accepted undertaking into the existing HUD.
	var camp: Dictionary=model.nihang_camp()
	if not CampRules.active(camp.phase): return {}
	var nearby:=0
	for id in camp.selected:
		if CampRules.point(camp.mounts[CampRules.RIDERS.find(id)].position).distance_to(model.position())<=7: nearby+=1
	var result:={"title":"GUJRANWALA  /  RIDING WITH THE NIHANGS","task":"","progress":"%d / %d riders nearby"%[nearby,camp.selected.size()],"controls":"","target":CampRules.CAMP,"marker":"Camp elder · E","show_target":true}
	if model.mounted():
		result.progress+=" · "+_camp_formation
		result.controls="W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped     E  Speak"
	else:
		result.controls="WASD  Walk     Mouse  Look     F  Mount     E  Speak     J / Esc  Journal and menu"
	if nearby<camp.selected.size(): result.progress+="\nSlow down or return for the riders."
	if camp.phase=="outbound":
		if model.mounted():
			result.task="Ride to the north marker together"
			result.progress+="\nWait for everyone, then press E at the marker."
			result.target=CampRules.TURN;result.marker="North practice marker · E"
		else:
			result.task="Mount the household horse"
			result.progress+="\nYour companions have agreed to ride to the north marker and back."
			result.target=CampRules.Ride.position(model.horse_record());result.marker="Household horse · F"
	else:
		result.task="Return together to the camp"
		result.progress+="\nStop, dismount, and wait for the riders before speaking to the elder."
		if model.mounted(): result.marker="Camp elder · dismount first"
	return result

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var camp: Dictionary=model.nihang_camp()
	if CampRules.active(camp.phase):
		_hud.text+="\nCAMP RIDE · %d companion(s) · %s"%[camp.selected.size(),"ride to the north marker together [E]" if camp.phase=="outbound" else "return to the camp elder together [E]"]
		var nearby:=0
		for id in camp.selected:
			if CampRules.point(camp.mounts[CampRules.RIDERS.find(id)].position).distance_to(model.position())<=7: nearby+=1
		_hud.text+="\n%d/%d riders within calling distance%s"%[nearby,camp.selected.size()," · slow down or return for the riders" if nearby<camp.selected.size() else ""]
		if model.mounted(): _hud.text+=" · "+_camp_formation
	elif model.position().distance_to(CampRules.CAMP)<10:
		_hud.text+="\nNIHANG CAMP · Speak to the elder; listen beside the horse lines [E]."
