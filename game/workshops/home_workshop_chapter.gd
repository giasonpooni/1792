# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://presentation/art_chapter.gd"
## Selectively integrates PR21's finite workshop into the current Home, not its old town.
const WorkshopState := preload("res://workshops/workshop_state.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const WorkshopView := preload("res://workshops/workshop_world.gd")
var workplace: Node3D
var _workshop_action := ""
var _workshop_choices: Array[String]=[]

func _init() -> void:
	model=WorkshopState.new();save_path=WorkshopState.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	workplace=WorkshopView.new();add_child(workplace);workplace.build(avatar)
	_navigation.built=false

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_workshop_action="";_workshop_choices.clear()

func _menu_action(action: String) -> void:
	if action.begins_with("smith:"):
		var kind:=action.trim_prefix("smith:")
		if _paused and kind in _workshop_choices and _workshop_action.is_empty(): _workshop_action=kind
		return
	super._menu_action(action)

func _resume() -> void:
	_workshop_action="";_workshop_choices.clear()
	super._resume()

func _workshop_button(label: String,kind: String) -> void:
	var b:=Button.new();b.text=label;b.custom_minimum_size.y=42;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(_menu_action.bind("smith:"+kind));_actions.add_child(b);_actions.move_child(b,0)
	_workshop_choices.append(kind);_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	match model.workshop_phase():
		"unassigned": _workshop_button("Commission two tool bundles · carry 2 timber and 4 household coins","reserve")
		"fuel": _workshop_button("Return undelivered workshop fuel and payment · cancel this job","refund")
		"tools": _workshop_button("Return both tool bundles to household stock","deliver")

func _open_journal() -> void:
	super._open_journal()
	if FileAccess.file_exists(YouthState.BRAWL_SAVE):
		_workshop_button("Import prior youth/visual save · replaces this whole run","import")

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.brawl_busy() and model.position().distance_to(Craft.SITE)<=3.0:
		var error:=_workshop_access("start")
		if not error.is_empty(): _message=error;return
		_open_smith();return
	super._interact()

func _open_smith() -> void:
	var text: String={"unassigned":"Smith · Ask your quartermaster about the two tool bundles. I cannot charge his household on your word alone.",
		"fuel":"Smith · Put the assigned timber and payment here. I can then finish the two bundles; you must come back for them.",
		"working":"Smith · The work is underway. The bundles remain here until you collect them. You can wait nearby or return later.",
		"ready":"Smith · Here are the two bundles. Will you carry them back yourself? They are not in the household store yet.",
		"tools":"Smith · You have both bundles. Take them to the quartermaster; I will not issue them twice.",
		"complete":"Smith · Your household has received this order. The commission is settled.",
		"cancelled":"Smith · The undelivered commission was cancelled. There is no charge or order here."}.get(model.workshop_phase(),"")
	var choices: Array=[["Return","resume"]]
	var kind: String="start" if model.workshop_phase()=="fuel" else "collect" if model.workshop_phase()=="ready" else ""
	if not kind.is_empty(): choices.push_front(["Hand over fuel and payment" if kind=="start" else "Collect both tool bundles", "smith:"+kind])
	_show_dialog("HOUSEHOLD SMITH · ORIGINAL FICTION",text+"\n\nA fictional childhood errand in the authored Home cell, not a documented event or surveyed workshop. The existing game clock pauses during conversation.",choices)
	if not kind.is_empty(): _workshop_choices.append(kind)

func _workshop_access(kind: String) -> String:
	if model.mounted(): return "Dismount before changing workshop custody."
	var at: Vector3=Craft.SITE if kind in ["start","collect"] else Rules.QUARTERMASTER
	if avatar.global_position.distance_to(model.position())>0.25: return "The body and recorded position must agree."
	if avatar.global_position.distance_to(at)>3.0 or not _seen(at+Vector3.UP*1.35,4.5):
		return "Face the nearby speaker from unobstructed standing ground."
	return ""

func _physics_process(delta: float) -> void:
	if not _workshop_action.is_empty():
		var kind:=_workshop_action;_workshop_action=""
		if kind=="import": _load(YouthState.BRAWL_SAVE);return
		var error:=_workshop_access(kind) # Recheck the actual world after the menu was opened.
		if error.is_empty(): error=model.workshop_action(kind)
		_message=error if not error.is_empty() else Craft.WORDS[kind]
		_sync_economy();_resume();_sync_workshop();return
	super._physics_process(delta)
	_sync_workshop()

func _sync_workshop() -> void:
	if not is_instance_valid(workplace): return
	var w: Dictionary=model.workshop()
	workplace.sample(int(model.progress().tick),model.workshop_phase(),int(w.get("started_tick",-1)))
	# Dialogues pause the existing simulation, and stop the prototype decay sound.
	if _paused: workplace.hammer_audio.stop()

func _sync_water() -> void:
	super._sync_water()
	if is_instance_valid(avatar) and model.carrying_workshop(): avatar.external_speed_limit=minf(avatar.external_speed_limit,Craft.CARRY_SPEED)

func _apply() -> void:
	super._apply();_sync_workshop()

func workshop_hint() -> String:
	return {"unassigned":"Ask the quartermaster about the smith's commission.","fuel":"Carry the fuel/payment to the smith in the western courtyard [E].",
		"working":"Order left with the smith. Return to his court to ask about it.","ready":"Order left with the smith. Return to his court to ask about it.",
		"tools":"Carry both tool bundles back to the quartermaster [E].","complete":"Both tool bundles returned to household stock.","cancelled":"Unused fuel and payment returned; this job is cancelled."}.get(model.workshop_phase(),"")

func _refresh() -> void:
	super._refresh();_sync_workshop()
	if not is_instance_valid(_hud) or not model.has_economy(): return
	if model.workshop_phase() in ["fuel","working","ready","tools"] and not model.brawl_busy():
		var ledger: Dictionary=model.economy().ledger
		_hud.text="1792 · BUDDH SINGH · HOME COURTYARD\n\nSMITH'S COMMISSION · "+workshop_hint()+"\nHousehold coffers %d · timber %d · stored tools %d · personal purse %d" % [ledger.treasury,ledger.stock.timber,ledger.stock.tools,ledger.purse]
		_hud.text+="\nE speak · B supplies · J journal · F5/F9 save/load · F7 visual comparison"
	else: _hud.text+="\nWORKSHOP · "+workshop_hint()

func _account_text() -> String:
	var text:=super._account_text()
	if not model.has_economy(): return text
	return text+"\n\nSMITH'S COMMISSION · original fictional task\n"+workshop_hint()+"\nCost: 2 timber and 4 household coins; output: 2 tool units only after physical return. No personal cash reward. Ten seconds of active work is an authored duration, not historical craft production."

func _load(path: String="") -> void:
	_restore_workshop_file(save_path if path.is_empty() else path,false)

func _retry_bazaar() -> void:
	_restore_workshop_file(save_path+".bazaar-retry.json",true)

func _restore_workshop_file(path: String,retry: bool) -> void:
	var staged:=WorkshopState.new()
	var error:=staged.load_from(path)
	if error.is_empty() and retry and staged.brawl_phase()!="challenged": error="No pre-confrontation bazaar snapshot."
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message=("Earlier whole world restored, including workshop custody and clock." if retry else "Whole Home restored: workshop, supplies, water, service and youth state.") if error.is_empty() else error
	_clear_pending_actions();_resume()
