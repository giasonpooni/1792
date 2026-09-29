extends "res://settlement/town_chapter.gd"
## Same home entry and authoritative model. No workshop-menu shortcut bypasses local access.
const Workshop := preload("res://workshops/workshop_state.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const WorkWorld := preload("res://workshops/workshop_world.gd")
var workshop_world: Node3D
var _workshop_action := ""

func _init() -> void:
	model=Workshop.new()
	save_path=Workshop.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	workshop_world=WorkWorld.new();add_child(workshop_world);workshop_world.build(town,avatar)
	_sync_workshop()

func _sync_workshop() -> void:
	if not is_instance_valid(workshop_world): return
	workshop_world.sync(int(model.progress().tick),model.workshop_phase())
	if model.carrying_workshop():
		avatar.walk_speed=minf(avatar.walk_speed,Craft.CARRY_SPEED)
		avatar.run_speed=minf(avatar.run_speed,Craft.CARRY_SPEED)

func _apply() -> void:
	super._apply()
	_sync_workshop()

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_workshop_action=""

func _menu_action(action: String) -> void:
	if action.begins_with("smith:"):
		_workshop_action=action.trim_prefix("smith:");return
	super._menu_action(action)

func _access(action: String) -> bool:
	var at: Vector3=Craft.SITE if action in ["start","collect"] else Rules.QUARTERMASTER
	if model.mounted() or absf(model.position().y-at.y)>0.35: return false
	if Model.distance(model.position(),at)>3 or not _seen(at+Vector3.UP*1.35,4.5): return false
	# Rechecked when the queued action executes, not merely when dialogue opens.
	return action!="collect" or workshop_world.bench.can_collect(avatar)

func _physics_process(delta: float) -> void:
	if not _workshop_action.is_empty():
		var action:=_workshop_action;_workshop_action=""
		if action=="import_town": _load(Town.TOWN_SAVE);return
		var error: String=model.workshop_action(action) if _access(action) else "The speaker or collection point is no longer nearby and visible. No transaction occurred."
		_message=error if not error.is_empty() else Craft.WORDS.get(action,"Order updated.")
		avatar.velocity=Vector3.ZERO
		_resume();_sync_workshop();return
	super._physics_process(delta)
	_sync_workshop()

func _append_workshop_action(text: String,action: String) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("smith:"+action))
	_actions.add_child(button);_actions.move_child(button,0);_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	match model.workshop_phase():
		"unassigned": _append_workshop_action("Commission two tool bundles · 4 coins + 2 timber; carry to the smith","reserve")
		"fuel": _append_workshop_action("Cancel commission · return carried timber and unspent payment","refund")
		"tools": _append_workshop_action("Return the two tool bundles to household stock","deliver")

func _interact() -> void:
	if Model.distance(model.position(),Craft.SITE)<=3.0:
		if not _access("start"): _message="Dismount and face the smith from a clear position.";return
		_open_smith();return
	super._interact()

func _open_smith() -> void:
	var body: String="Smith · Ask your household quartermaster for a commission first. I work here, beyond the west gate."
	var choices: Array=[["Return","resume"]]
	match model.workshop_phase():
		"fuel":
			body="Smith · I will take the two timber bundles and four coins. My own iron is included in the price. Leave them here, then return for two tool bundles.\n\nThe job needs 600 unpaused chapter ticks (10 play seconds). This recipe, rate and payment are authored game units."
			choices.push_front(["Hand over the timber and payment","smith:start"])
		"working":
			var left: int=maxi(0,int(model.workshop().started_tick)+Craft.WORK_TICKS-int(model.progress().tick))
			body="Smith · Still working. Give me a little more time.\n\n%d active ticks remain; close this conversation to let time pass."%left
		"ready":
			body="Smith · The two bundles are ready on the bench. They become yours to carry only when you collect them."
			choices.push_front(["Collect two finished tool bundles","smith:collect"])
		"tools": body="Smith · You have both bundles. Return them to the quartermaster."
		"complete": body="Smith · Your household order is settled. This commission cannot pay or produce again."
		"cancelled": body="Smith · That commission was cancelled before the fuel and payment reached me."
	_show_dialog("GUJRANWALA · SMITH'S COURT",body+"\n\nFictional artisan and commission; not a documented incident.",choices)

func _open_places() -> void:
	super._open_places()
	_append_workshop_action("Import prior town save · replaces this whole run","import_town")

func _account_text() -> String:
	var text: String=super._account_text()
	if model.workshop_phase()=="unassigned": return text
	# Completion at a remote workshop does not grant protagonist knowledge.
	var label: String={"fuel":"2 timber + 4 coins in your custody","working":"Order left with the smith; return to enquire",
		"ready":"Order left with the smith; return to enquire","tools":"2 tool bundles carried, not yet in the store",
		"complete":"2 tool bundles returned; commission settled","cancelled":"Commission cancelled; original fuel and payment returned"}[model.workshop_phase()]
	return text+"\n\nWORKSHOP COMMISSION\n"+label

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud) or model.workshop_phase()=="unassigned": return
	var objective: String={"fuel":"Carry timber to the smith: west gate, then first courtyard on your left.",
		"working":"Order left with the smith. Return to his court to enquire.","ready":"Order left with the smith. Return to his court to enquire.",
		"tools":"Carry both tool bundles back to the quartermaster.","complete":"Workshop commission complete.","cancelled":"Workshop commission cancelled."}[model.workshop_phase()]
	_hud.text+="\n\nWORKSHOP · "+objective

func _load(path: String="") -> void:
	var staged:=Workshop.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole chapter, town, stores and workshop custody restored." if error.is_empty() else error
	_clear_pending_actions();_resume();_sync_workshop()
