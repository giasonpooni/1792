# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://workshops/home_workshop_chapter.gd"
## Riding skills extend the same Home authority, save and physical horse motor.
const SkillState:=preload("res://mounts/riding_skill_state.gd")
const TrainingSession:=preload("res://mounts/riding_training_session.gd")
const Stance:=preload("res://mounts/horsecraft_state.gd")
const RiderVisual:=preload("res://mounts/horsecraft_rider_visual.gd")
var training_session: Node
var _training_requested:=false
var _training_mode:=""
var _standing_requested:=false
var _single_stance:=Stance.new()
var _single_blend:=0.0
var _riding_visual: Node3D

func _init() -> void:
	model=SkillState.new();save_path=WorkshopState.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	var mentor:=_box(Vector3(.55,1.65,.5),SkillState.TRAINING_SITE+Vector3.UP*.825,Color("6c7f8b"))
	var caption:=Label3D.new();caption.text="Riding trainer [E]"
	caption.position=Vector3(0,1.35,0);caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size=20;caption.pixel_size=.0015;caption.fixed_size=true;mentor.add_child(caption)

func _ready() -> void:
	super._ready()
	_riding_visual=RiderVisual.new();add_child(_riding_visual);_riding_visual.configure(null,"childhood-home");_riding_visual.name="HomeRidingVisual"
	_riding_visual.set_equipped(false);_sample_standing()

func training_entry_error() -> String:
	if is_instance_valid(training_session): return "Finish or leave the active riding lesson first."
	var error: String=model.training_access()
	if not error.is_empty(): return error
	if avatar.global_position.distance_to(model.position())>.25:
		return "The rider's recorded and physical positions disagree."
	if not avatar.is_on_floor(): return "Stand beside the trainer on solid ground."
	if not _seen(SkillState.TRAINING_SITE+Vector3.UP*1.35,4.5):
		return "Face the nearby riding trainer from clear ground."
	if model._other_commitment(): return "Settle your active household task before riding practice."
	return ""

func open_riding_training(practice_mode: String="") -> String:
	var error:=training_entry_error()
	if not error.is_empty(): return error
	var session:=TrainingSession.new();session.name="RidingTrainingSession"
	get_tree().root.add_child(session)
	error=session.start_training(self,practice_mode)
	if not error.is_empty(): session.queue_free();return error
	training_session=session
	return ""

func _interact() -> void:
	if not model.mounted() and model.position().distance_to(SkillState.TRAINING_SITE)<=3.0:
		var error:=training_entry_error()
		if not error.is_empty(): _message=error;return
		if model.has_riding_skill("single_standing"):
			_show_dialog("RIDING PRACTICE · LEARNED HORSECRAFT",
				"Trainer: One horse or two today, Buddh? Take the practice matchlocks if you wish. Bring everything back when you finish.\n\nChoose a formation. Your learned skills stay with you when you return.",
				[["Practise on one horse","riding:single"],["Practise across two horses","riding:pair"],["Return to Home","resume"]])
			return
		_show_dialog("RIDING LESSON · A TALE OF MAHA SINGH",
			"Trainer: They tell a tale of your father riding two horses, Buddh. Begin with one. We will see what your feet remember when the smoke comes.\n\nThree exercises: one horse, a pair, then four matchlocks. Finish and return to learn the skills; leave at any time to try again later.",
			[["Practice the remembered feat" if model.has_riding_skill("single_standing") else "Learn the remembered feat","riding:begin"],["Continue the Home lesson","resume"]])
		return
	super._interact()

func _menu_action(action: String) -> void:
	if action=="riding:begin": _training_requested=true;return
	if action in ["riding:single","riding:pair"]:
		_training_mode=action.trim_prefix("riding:");_training_requested=true;return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_training_requested=false;_standing_requested=false;_training_mode=""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_X:
		if not _paused: _standing_requested=true
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func _horse_support() -> Dictionary:
	return _single_stance.single_metrics({"position":[horse.global_position.x,horse.global_position.y,horse.global_position.z],
		"yaw":horse.rotation.y,"speed":horse.speed,"grounded":horse.is_on_floor()})

func single_stance() -> String:
	return _single_stance.stance()

func _physics_process(delta: float) -> void:
	if _training_requested:
		var practice_mode:=_training_mode;_training_mode=""
		_training_requested=false
		var error:=open_riding_training(practice_mode)
		if not error.is_empty(): _message=error;_resume()
		return
	if _standing_requested:
		_standing_requested=false
		if not model.mounted(): _message="Mount the household horse before changing stance."
		elif not model.has_riding_skill("single_standing"): _message="Learn standing riding with the stable trainer first."
		else:
			var error: String=_single_stance.toggle_stance(_horse_support())
			_message=error if not error.is_empty() else "Changing riding stance."
	var recovery_brake: bool=not _paused and model.mounted() and _single_stance.snapshot().brake_required
	var previous_gait: float=horse.gait_speed_limit
	if recovery_brake: horse.gait_speed_limit=0.0
	super._physics_process(delta)
	# Parent upkeep may have supplied a new condition cap during this tick.
	if recovery_brake and horse.gait_speed_limit==0.0: horse.gait_speed_limit=previous_gait
	if _paused: return
	if not model.mounted():
		_single_stance.restart();_single_blend=0.0
	else:
		_single_stance.advance(_horse_support(),Input.get_axis("move_left","move_right"),
			float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)))
		_single_blend=move_toward(_single_blend,1.0 if single_stance() in ["rising","standing"] else 0.0,1.0/(36.0 if single_stance()=="recovering" else 48.0))
	_sample_standing()

func _sample_standing() -> void:
	if not is_instance_valid(_riding_visual): return
	# Retain the legacy seven rider anchors for existing adapters; this shared
	# mesh projection follows the same observed household horse without a motor.
	horse._rider.hide();_riding_visual.visible=model.mounted()
	if not _riding_visual.visible: return
	var center: Vector3=horse.global_position
	var feet: Array[Vector3]=[horse.saddle_support_point()-horse.global_basis.x*.22,
		horse.saddle_support_point()+horse.global_basis.x*.22]
	var centers: Array[Vector3]=[center,center];var yaws: Array[float]=[horse.rotation.y]
	_riding_visual.sample(_single_stance.snapshot(),_single_blend,0.0,0.0,centers,feet,yaws,-1,horse.bridle_points_world())

func _apply() -> void:
	super._apply();_single_stance.restart();_single_blend=0.0;_sample_standing()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	if model.has_riding_skill("single_standing"):
		_hud.text+="\nRIDING SKILLS · standing / paired standing / mounted matchlocks learned · X stand while mounted"
	else:
		_hud.text+="\nRIDING SKILLS · after the first riding gate, return to the stable trainer [E]"

func _restore_workshop_file(path: String,retry: bool) -> void:
	var staged=model.get_script().new();var error: String=staged.load_from(path)
	if error.is_empty() and retry and staged.brawl_phase()!="challenged": error="No pre-confrontation bazaar snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole Home and riding skills restored." if error.is_empty() else error
	_clear_pending_actions();_resume()

func _capture_checkpoint(reason: String) -> void:
	var error:=_candidate_error(model)
	var snapshot: Dictionary=model.snapshot()
	# The absent extension is the same locked state. Retain legacy checkpoint
	# reader compatibility until a lesson receipt actually needs preservation.
	if snapshot.riding_skills.lesson_receipts.is_empty(): snapshot.erase("riding_skills")
	if error.is_empty(): error=Checkpoint.write(checkpoint_path(),snapshot,avatar.pivot.rotation,reason,model.get_script())
	_checkpoint_note="Checkpoint saved with riding skills." if error.is_empty() else "Checkpoint not saved: "+error
	_message+="\n"+_checkpoint_note

func _restore_checkpoint() -> void:
	var result:=Checkpoint.read(checkpoint_path(),model.get_script())
	var error: String=result.error;var staged=model.get_script().new()
	if error.is_empty(): error=staged.restore(result.envelope.snapshot)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if not error.is_empty():
		_show_dialog("CHECKPOINT NOT RESTORED",error+"\nYour Home is unchanged.",[["Return","resume"],["Load manual save","load"],["Main menu","menu"]]);return
	_apply();avatar.pivot.rotation=Vector3(result.envelope.camera[0],result.envelope.camera[1],0)
	_clear_pending_actions();_message="Whole Home checkpoint restored, including riding skills.";_resume()

func _exit_tree() -> void:
	if is_instance_valid(training_session): training_session.abandon();training_session=null
