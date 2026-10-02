# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/riding_training_chapter.gd"
## Optional local story on the current single Home authority, clock and save.
const MemoryState := preload("res://narrative/oral_memory/memory_state.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const MemoryDirection := preload("res://narrative/oral_memory/memory_direction.gd")
const MemoryProps := preload("res://narrative/oral_memory/memory_props.gd")
var _oral_action := ""
var _oral_choices: Array[String]=[]
var _oral_props: Array[Node3D]=[]

func _init() -> void:
	model=MemoryState.new()
	save_path=WorkshopState.WORKSHOP_SAVE

func _build_world() -> void:
	super._build_world()
	var peg:=_box(Vector3(0.8,0.12,0.55),Memory.SITES.trace+Vector3.UP*0.7,Color("806247"))
	_oral_props.append(peg.get_parent())
	for x in [-0.3,0.3]:
		var support:=_box(Vector3(0.1,0.65,0.35),Memory.SITES.trace+Vector3(x,0.325,0),Color("806247"))
		_oral_props.append(support.get_parent())
	_oral_props.append(MemoryProps.build(self,Memory.SITES.trace))
	var neighbour:=_box(Vector3(0.45,1.5,0.4),Memory.SITES.listener+Vector3.UP*0.75,Color("877c62"))
	_oral_props.append(neighbour.get_parent())
	for id in ["trace","listener"]:
		var label:=Label3D.new()
		label.position=Memory.SITES[id]+Vector3.UP*2.0
		label.text="Rope peg · E inspect" if id=="trace" else "Neighbour · E speak"
		label.font_size=20
		label.pixel_size=0.0015
		label.fixed_size=true
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		_oral_props.append(label)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_oral_action="";_oral_choices.clear()

func _resume() -> void:
	_oral_action="";_oral_choices.clear()
	super._resume()

func _show_dialog(title: String,body: String,actions: Array) -> void:
	super._show_dialog(title,body,actions)
	for spec in actions:
		if String(spec[1]).begins_with("oral:"): _oral_choices.append(String(spec[1]).trim_prefix("oral:"))

func _menu_action(action: String) -> void:
	if action.begins_with("oral:"):
		var choice:=action.trim_prefix("oral:")
		if _paused and choice in _oral_choices and _oral_action.is_empty(): _oral_action=choice
		return
	if action=="oral_view":
		if _paused: _open_oral_memory()
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _oral_action.is_empty():
		var choice:=_oral_action;_oral_action=""
		var parts:=choice.split("|",true,1)
		var error: String="This story choice is no longer open."
		if _paused and choice in _oral_choices and parts.size()==2:
			error=_oral_access(parts[0],parts[1])
			if error.is_empty(): error=model.oral_operation(parts[0],parts[1])
		if not error.is_empty():
			_show_dialog("THE STORY WAITS",error,[["Return to your walk","resume"]])
		else:
			var rows: Array=model.oral_journal()
			var response: String=model.listener_response(parts[1]) if parts[0]=="retell" else ""
			_show_dialog(MemoryDirection.title(parts[0],parts[1]),MemoryDirection.body(parts[0],parts[1],rows[-1].text,response),
				[["Continue your walk","resume"],["Remembered stories","oral_view"]])
		return
	super._physics_process(delta)

func _oral_access(kind: String,subject: String) -> String:
	if model.aftermath_phase()!="complete" or model.mounted(): return "Finish the household inquiry and dismount first."
	if model.brawl_busy(): return "Return with your friends before beginning another story."
	if is_instance_valid(training_session): return "Return from riding practice before hearing a story."
	if is_instance_valid(hawk_scout) and hawk_scout.active: return "Return to your own view before speaking."
	if not avatar.is_on_floor(): return "Stand on solid ground before listening or examining the rope."
	if avatar.global_position.distance_to(model.position())>.25: return "Your recorded and physical positions disagree."
	if kind=="compare": return ""
	var site_id:=Memory.site(kind,subject,Memory.content())
	if not _oral_visible(site_id): return "Face the same nearby speaker or rope from an unobstructed position."
	return ""

func _oral_visible(site_id: String) -> bool:
	if not Memory.SITES.has(site_id): return false
	return Memory.near(model.position(),site_id) and Memory.near(avatar.global_position,site_id) and _seen(Memory.SITES[site_id]+Vector3.UP*1.35,4.2)

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.mounted() and not model.brawl_busy():
		for site_id in ["trace","listener"]:
			if not Memory.near(model.position(),site_id): continue
			var subject: String="rope_trace" if site_id=="trace" else "well_echo"
			var error:=_oral_access("observe" if site_id=="trace" else "hear",subject)
			if not error.is_empty(): _message=error;return
			if site_id=="trace":
				if model.oral_progress().trace_seq==0:
					_show_dialog("ROPE BESIDE THE STABLE","A worn length of rope lies beside a repaired loop.",[["Look at the repaired loop","oral:observe|rope_trace"],["Leave it for now","resume"]])
				else: _show_dialog("ROPE BESIDE THE STABLE",model.oral_view().trace,[["Continue your walk","resume"],["Remembered stories","oral_view"]])
			else: _open_listener()
			return
	super._interact()

func _append_oral_button(text: String,action: String) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind(action));_actions.add_child(button)
	# Existing household continuation retains first focus; stories remain optional.
	_actions.move_child(button,maxi(1,_actions.get_child_count()-2))
	if action.begins_with("oral:"): _oral_choices.append(action.trim_prefix("oral:"))
	_layout()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if model.brawl_busy(): return
	var s: Dictionary=model.oral_progress()
	if not s.heard.has("quartermaster_account"):
		_append_oral_button("Hear the borrowed-rope story","oral:hear|quartermaster_account")
	else: _append_oral_button("Remember the borrowed-rope story","oral_view")
	if s.compared_seq>0 and s.trace_seq>0 and s.requested_seq==0:
		_append_oral_button("Ask about the moment of borrowing","oral:ask|quartermaster_reflection")
	elif s.requested_seq>0 and not s.heard.has("quartermaster_reflection"):
		_append_oral_button("Listen for his further recollection","oral:hear|quartermaster_reflection")

func _open_market() -> void:
	super._open_market()
	if model.brawl_busy(): return
	if not model.oral_progress().heard.has("trader_account"):
		_append_oral_button("Hear the trader's rope story","oral:hear|trader_account")
	else: _append_oral_button("Remember the trader's account","oral_view")

func _open_listener() -> void:
	var s: Dictionary=model.oral_progress();var actions: Array=[]
	if not s.heard.has("well_echo"): actions.append(["Hear where the neighbour heard it","oral:hear|well_echo"])
	if s.compared_seq>0 and not s.retellings.has("comparison"):
		actions.append(["Tell both accounts; keep the disagreement","oral:retell|comparison"])
	if s.heard.has("quartermaster_account") and not s.retellings.has("quartermaster_account"):
		actions.append(["Tell the quartermaster's account; name him","oral:retell|quartermaster_account"])
	actions.append(["Continue your walk","resume"])
	_show_dialog("NEIGHBOUR NEAR THE WELL",model.listener_response(),actions)

func _open_oral_memory() -> void:
	var body: String=MemoryDirection.next_beat(model.oral_progress(),int(model.progress().tick))+"\n\n"
	var rows: Array=model.oral_journal()
	for row in rows: body+=MemoryDirection.receipt_heading(row)+"\n"+String(row.text)+"\n\n"
	var s: Dictionary=model.oral_progress()
	if s.heard.has("trader_account") and s.heard.has("well_echo"):
		body+="The trader and neighbour repeat one reported source.\n\n"
	body+="Original fictional story, not an attested historical tale. This readable view represents oral memory."
	var actions: Array=[]
	if s.heard.has("quartermaster_account") and s.heard.has("trader_account") and s.compared_seq==0:
		actions.append(["Put the two accounts side by side","oral:compare|borrowed_rope"])
	actions.append(["Return to your walk","resume"])
	_show_dialog("REMEMBERED STORIES · THE BORROWED ROPE",body,actions)

func _open_journal() -> void:
	super._open_journal()
	_append_oral_button("Remembered stories · the borrowed rope","oral_view")

func _refresh() -> void:
	super._refresh()
	for prop in _oral_props: prop.visible=model.aftermath_phase()=="complete"
