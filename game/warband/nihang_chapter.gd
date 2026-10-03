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
	camp_view.sample(int(model.progress().tick),state.phase,
		CampRules.terms_required(state) and not CampRules.has_event(state,"halt"))

func _camp_access(kind: String) -> String:
	if avatar.global_position.distance_to(model.position())>.25: return "Your physical and recorded positions disagree."
	var at: Vector3=CampRules.HORSE_LINES[0] if kind=="care" else CampRules.HALT if kind=="halt" else CampRules.TURN if kind=="turn" else CampRules.FARTHER if kind=="second_turn" else CampRules.CAMP
	if kind in ["halt","turn","second_turn"]:
		if kind=="halt":
			if model.mounted() or not avatar.is_on_floor(): return "Stop and put a foot down at the low ground."
			if model.position().distance_to(at)>3.0: return "Return to the low ground before crossing."
		else:
			if not model.mounted() or not horse.is_on_floor(): return "Reach the practice marker mounted on solid ground."
			if model.position().distance_to(at)>3.0: return "Reach the agreed marker with your companion."
		# The veteran must actually be audible through an unobstructed line.
		var speaker_from: Vector3=avatar.global_position if kind=="halt" else horse.global_position
		var veteran: Vector3=camp_horses[0].global_position
		var ray:=PhysicsRayQueryParameters3D.create(speaker_from+Vector3.UP*2.4,veteran+Vector3.UP*2.4,1,[horse.get_rid(),avatar.get_rid()])
		if veteran.distance_to(speaker_from)>7 or not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Wait within clear calling distance of the veteran."
	else:
		if model.mounted() or not avatar.is_on_floor(): return "Stand on foot beside the camp speaker."
		if model.position().distance_to(at)>3 or not _seen(at+Vector3.UP*1.35,4.5): return "Face the nearby camp speaker from clear ground."
	return ""

func _interact() -> void:
	var camp: Dictionary=model.nihang_camp()
	if model.mounted() and camp.phase=="second_outbound" and model.position().distance_to(CampRules.FARTHER)<3:
		var error:=_camp_access("second_turn")
		if error.is_empty(): error=model.camp_action("second_turn",true,true)
		_message=error if not error.is_empty() else CampRules.WORDS.second_turn
		_refresh();return
	if not model.mounted() and camp.phase=="outbound" and CampRules.terms_required(camp) and not CampRules.has_event(camp,"halt") and model.position().distance_to(CampRules.HALT)<3:
		_open_camp("halt");return
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
	if kind=="halt":
		var count: int=model.nihang_camp().selected.size()
		_show_dialog("LOW GROUND · COUNT THE RIDERS","The veteran waits with the reins loose. %s\n\nLittle rider. Before anyone crosses, look back and count aloud."%("The other horse settles behind him." if count>1 else "His horse settles on the low earth."),
			[["Count every rider, then cross together","camp:halt"],["Leave the halt","resume"]])
		_camp_choices.append("halt");return
	var camp: Dictionary=model.nihang_camp()
	var body: String="A familiar voice reaches you before anyone stands.\n\nBuddh. Come closer. Your father's companions are tending their horses; the elder makes room for you beside them."
	var choices: Array=[]
	match camp.phase:
		"unmet": choices=[["Greet the elder and the riders","camp:meet"]]
		"acquainted": body=CampRules.WORDS.meet
		"prepared":
			body="%s, your own horse; our company. Ask the veteran to ride with you, or bring both riders. The undertaking is the north marker and home again. Wait for one another."%model.nihang_address(CampRules.ELDER)
			choices=[["Invite the veteran on his terms","camp:invite_one_terms"],["Invite both riders on their terms","camp:invite_two_terms"]]
		"outbound", "returning":
			body="%s, our undertaking is the north practice marker and back. Bring everyone home before we settle it."%model.nihang_address(CampRules.ELDER)
			if camp.phase=="returning": choices.append(["Return together and thank the riders","camp:return"])
			choices.append(["End this outing here with everyone present","camp:cancel"])
		"complete":
			body=CampRules.WORDS["return"]+"\n\nThe elder makes room beside the mat. The horse-care lesson has become an undertaking you kept."
			if CampRules.has_event(camp,"halt"): body+="\n\nThe veteran answers before the elder asks: Little rider stopped at the low ground and counted us before he crossed."
			if CampRules.has_event(camp,"second_ready"):
				body+="\n\n"+CampRules.WORDS.second_ready
				choices.append(["Ask him to state the farther-road term","camp:second_terms"])
			elif not CampRules.second_outing_answered(camp): choices.append(["Ask the veteran about the farther road","camp:second_ready"])
		"cancelled":
			body=CampRules.WORDS.cancel
			if CampRules.has_event(camp,"second_deferred"): body+="\n\n"+CampRules.WORDS.second_deferred
			elif not CampRules.second_outing_answered(camp): choices.append(["Ask the veteran about the farther road","camp:second_deferred"])
		"second_outbound":
			body=CampRules.WORDS.second_begin+"\n\nThe veteran keeps his horse beside the horse lines until you mount. The farther stone waits beyond the first marker."
		"second_returning":
			body=CampRules.WORDS.second_turn+"\n\nBring horse and rider back to the camp before the undertaking is witnessed."
			choices.append(["Settle the farther road with the veteran","camp:second_return"])
		"second_complete":
			body=CampRules.WORDS.second_return+"\n\nThe elder says nothing at first. The veteran loosens the girth, and the small silence makes the return his testimony rather than a prize."
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

func _show_second_terms() -> void:
	var beat: Dictionary=CampRules.SECOND_TERM_BEAT
	_show_dialog(beat.title,beat.body,[[beat.choice,"camp:second_begin"],["Not yet","resume"]])
	# Willingness is already received testimony; only this explicit acceptance
	# begins the physical undertaking. The page itself stays outside saved state.
	_camp_choices.append("second_begin")

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
		if kind=="second_terms":
			var terms_error:=_camp_access("")
			var camp: Dictionary=model.nihang_camp()
			if terms_error.is_empty() and (camp.phase!="complete" or not CampRules.has_event(camp,"second_ready")):
				terms_error="The veteran has not offered the farther road."
			if terms_error.is_empty(): _show_second_terms()
			else: _message=terms_error;_resume()
			return
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
	# Exclude every stale live horse projection here; the staged household and
	# companion poses are checked against one another immediately below.
	var staged_peers: Array[RID]=[horse.get_rid(),camp_horses[0].get_rid(),camp_horses[1].get_rid()]
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
	# Project received invitations and accepted undertakings into the existing HUD.
	var camp: Dictionary=model.nihang_camp()
	if camp.phase=="acquainted":
		# This optional local lesson cannot displace danger, another undertaking,
		# mounted riding or a task elsewhere in Home. No presentation state is saved.
		if model.stage()!="riding" or model.mounted() or model.position().distance_to(CampRules.CAMP)>10 or model._other_commitment() or model.carrying_workshop(): return {}
		return {"title":"GUJRANWALA  /  THE NIHANG HORSE LINES","task":"Listen beside the horse lines",
			"progress":"Optional · The elder asked you to listen beside the horse lines.\nYour household riding lesson remains available.",
			"controls":"WASD  Walk     Mouse  Look     E  Speak     F  Mount     J / Esc  Journal and menu",
			"target":CampRules.HORSE_LINES[0],"marker":"Veteran's horse · E","show_target":true}
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
	if camp.phase=="second_outbound":
		if model.mounted():
			result.task="Ride to the farther stone with the veteran"
			result.progress+="\nStop there and wait until the veteran's horse is still before pressing E."
			result.target=CampRules.FARTHER;result.marker="Farther stone · stop together [E]"
		else:
			result.task="Mount the household horse"
			result.progress+="\nThe veteran's term is to turn only after his horse has come fully to rest."
			result.target=CampRules.Ride.position(model.horse_record());result.marker="Household horse · F"
	elif camp.phase=="outbound":
		var halt_pending: bool=CampRules.terms_required(camp) and not CampRules.has_event(camp,"halt")
		if halt_pending and model.mounted():
			result.task="Halt together at the low ground"
			result.progress+="\nStop, dismount, and count every invited rider before crossing."
			result.target=CampRules.HALT;result.marker="Low ground · stop and dismount"
		elif halt_pending and model.position().distance_to(CampRules.HALT)<=4:
			result.task="Count every rider before crossing"
			result.progress+="\nFace the veteran and press E only when everyone can answer."
			result.target=CampRules.HALT;result.marker="Veteran · E"
		elif model.mounted():
			result.task="Ride to the north marker together"
			result.progress+="\nWait for everyone, then press E at the marker."
			result.target=CampRules.TURN;result.marker="North practice marker · E"
		else:
			result.task="Mount the household horse"
			result.progress+="\nYour companions have agreed to ride on their terms and return together."
			result.target=CampRules.Ride.position(model.horse_record());result.marker="Household horse · F"
	else:
		result.task="Return together to the camp"
		result.progress+="\nStop, dismount, and wait for the %s before speaking to the elder."%("veteran" if camp.phase=="second_returning" else "riders")
		if model.mounted(): result.marker="Camp elder · dismount first"
	return result

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var camp: Dictionary=model.nihang_camp()
	if CampRules.active(camp.phase):
		var direction: String="ride to the north marker together [E]" if camp.phase=="outbound" else "ride to the farther stone and stop together [E]" if camp.phase=="second_outbound" else "return to the camp elder together [E]"
		_hud.text+="\nCAMP RIDE · %d companion(s) · %s"%[camp.selected.size(),direction]
		var nearby:=0
		for id in camp.selected:
			if CampRules.point(camp.mounts[CampRules.RIDERS.find(id)].position).distance_to(model.position())<=7: nearby+=1
		_hud.text+="\n%d/%d riders within calling distance%s"%[nearby,camp.selected.size()," · slow down or return for the riders" if nearby<camp.selected.size() else ""]
		if model.mounted(): _hud.text+=" · "+_camp_formation
	elif model.position().distance_to(CampRules.CAMP)<10:
		_hud.text+="\nNIHANG CAMP · Speak to the elder; listen beside the horse lines [E]."
