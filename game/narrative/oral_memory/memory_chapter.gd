# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/researched_chapter.gd"
## Situated input/presentation adapter. Existing state, physics, pause and save machinery persist.
const MemoryState := preload("res://narrative/oral_memory/memory_state.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
var _oral_action := ""
var _oral_import_requested := false
var _oral_props: Array[Node3D]=[]

func _init() -> void:
	model=MemoryState.new()
	save_path=MemoryState.ORAL_SAVE

func _build_world() -> void:
	super._build_world()
	var peg:=_box(Vector3(0.8,0.12,0.55),Memory.SITES.trace+Vector3.UP*0.7,Color("806247"))
	_oral_props.append(peg.get_parent())
	for x in [-0.3,0.3]:
		var support:=_box(Vector3(0.1,0.65,0.35),Memory.SITES.trace+Vector3(x,0.325,0),Color("806247"))
		_oral_props.append(support.get_parent())
	for i in range(3):
		var coil:=MeshInstance3D.new()
		var mesh:=TorusMesh.new()
		mesh.inner_radius=0.20
		mesh.outer_radius=0.24
		mesh.rings=16
		mesh.ring_segments=8
		coil.mesh=mesh
		coil.position=Memory.SITES.trace+Vector3(0,0.78+i*0.045,0)
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color("ad9365")
		material.roughness=1.0
		coil.material_override=material
		add_child(coil)
		_oral_props.append(coil)
	var neighbour:=_box(Vector3(0.45,1.5,0.4),Memory.SITES.listener+Vector3.UP*0.75,Color("877c62"))
	_oral_props.append(neighbour.get_parent())
	for id in ["trace","listener"]:
		var label:=Label3D.new()
		label.position=Memory.SITES[id]+Vector3.UP*2.0
		label.text="Rope peg · E inspect" if id=="trace" else "Neighbour · E speak"
		label.font_size=30
		label.pixel_size=0.007
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		_oral_props.append(label)

func _unhandled_input(event: InputEvent) -> void:
	# The active consumer routes semantic actions; earlier chapter implementations remain intact.
	if event.is_action_pressed("open_accounts") and (not _paused or event is InputEventKey):
		_open_accounts()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_research") and (not _paused or event is InputEventKey):
		if not _paused: _show_dialog("GUJRANWALA — RESEARCH VIEW",fabric.notebook(),[["Return","resume"]])
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_memories") and not event.is_echo():
		_open_oral_memory()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_oral_action=""
	_oral_import_requested=false

func _menu_action(action: String) -> void:
	if action.begins_with("oral:"):
		_oral_action=action.trim_prefix("oral:")
		return
	if action=="oral_view":
		_open_oral_memory()
		return
	if action=="oral_import":
		_oral_import_requested=true
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if _oral_import_requested:
		_oral_import_requested=false
		_load(Territory.TERRITORY_SAVE)
		return
	if not _oral_action.is_empty():
		var parts:=_oral_action.split("|",true,1)
		_oral_action=""
		var error: String="Invalid oral-memory request."
		if parts.size()==2:
			var site_id:=Memory.site(parts[0],parts[1],Memory.content())
			if parts[0]=="compare" or _oral_visible(site_id):
				error=model.oral_operation(parts[0],parts[1])
			else: error="Face the speaker or trace from nearby, without an obstruction."
		if not error.is_empty():
			_show_dialog("NO NEW ACCOUNT RECORDED",error,[["Return","resume"]])
		else:
			var rows: Array=model.oral_journal()
			var text: String=rows[-1].text
			if parts[0]=="retell": text+="\n\n"+model.listener_response()
			_show_dialog("THE BORROWED ROPE · REMEMBERED ACCOUNT",text+"\n\nOriginal prototype fiction. Remembering an account does not certify the old event.",[["Continue","resume"],["Review remembered stories","oral_view"]])
		return
	super._physics_process(delta)

func _oral_visible(site_id: String) -> bool:
	return Memory.near(model.position(),site_id) and _seen(Memory.SITES[site_id]+Vector3.UP,4.2) if Memory.SITES.has(site_id) else false

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.mounted():
		for site_id in ["trace","listener"]:
			if not Memory.near(model.position(),site_id): continue
			if not _oral_visible(site_id):
				_message="Face the nearby rope or neighbour from an unobstructed position."
				return
			if site_id=="trace":
				if model.oral_progress().trace_seq==0:
					_show_dialog("ROPE BESIDE THE STABLE","Look closely at the rope and its repaired loop.",[["Inspect the rope","oral:observe|rope_trace"],["Return","resume"]])
				else: _show_dialog("ROPE BESIDE THE STABLE",model.oral_view().trace,[["Return","resume"]])
			else: _open_listener()
			return
	super._interact()

func _append_oral_button(text: String, action: String) -> void:
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind(action))
	_actions.add_child(button)
	# Preserve inherited first-button focus and every existing transaction.
	_actions.move_child(button,maxi(0,_actions.get_child_count()-2))

func _open_quartermaster() -> void:
	super._open_quartermaster()
	var s: Dictionary=model.oral_progress()
	if not s.heard.has("quartermaster_account"):
		_append_oral_button("Listen to the quartermaster's rope story","oral:hear|quartermaster_account")
	else: _append_oral_button("Recall the rope story · no new evidence","oral_view")
	if s.compared_seq>0 and s.trace_seq>0 and s.requested_seq==0:
		_append_oral_button("Ask the quartermaster to remember the borrowing again","oral:ask|quartermaster_reflection")
	elif s.requested_seq>0 and not s.heard.has("quartermaster_reflection"):
		_append_oral_button("Listen for the quartermaster's further recollection","oral:hear|quartermaster_reflection")

func _open_market() -> void:
	super._open_market()
	if not model.oral_progress().heard.has("trader_account"):
		_append_oral_button("Listen to the trader's rope story","oral:hear|trader_account")
	else: _append_oral_button("Recall the trader's account · no new evidence","oral_view")

func _open_listener() -> void:
	var s: Dictionary=model.oral_progress()
	var actions: Array=[]
	if not s.heard.has("well_echo"): actions.append(["Hear what the neighbour heard","oral:hear|well_echo"])
	if s.heard.has("quartermaster_account") and not s.retellings.has("quartermaster_account"):
		actions.append(["Retell the quartermaster's account, naming the source","oral:retell|quartermaster_account"])
	if s.compared_seq>0 and not s.retellings.has("comparison"):
		actions.append(["Retell both accounts and keep the disagreement open","oral:retell|comparison"])
	actions.append(["Return","resume"])
	_show_dialog("NEIGHBOUR NEAR THE WELL",model.listener_response(),actions)

func _open_oral_memory() -> void:
	var body: String="Stories you have heard and traces you have examined. This readable view represents oral memory, not literacy.\n\n"
	var rows: Array=model.oral_journal()
	if rows.is_empty(): body+="No story has been received. Speak with people in the household and market."
	for row in rows:
		body+="[%s · %s · %.1fs]\n%s\n\n"%[row.channel,row.source_id,row.received_tick/60.0,row.text]
	var s: Dictionary=model.oral_progress()
	if s.heard.has("trader_account") and s.heard.has("well_echo"):
		body+="The trader and neighbour repeat one reported source, not two independent witnesses.\n\n"
	var actions: Array=[]
	if s.heard.has("quartermaster_account") and s.heard.has("trader_account") and s.compared_seq==0:
		actions.append(["Compare the two accounts","oral:compare|borrowed_rope"])
	actions.append(["Return","resume"])
	_show_dialog("REMEMBERED STORIES · F7",body,actions)

func _open_journal() -> void:
	super._open_journal()
	_append_oral_button("Remembered stories [F7]","oral_view")
	_append_oral_button("Import previous integrated Gujranwala save · replace current session","oral_import")

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(_hud): _hud.text+="\nF7: remembered stories · E: hear, inspect or retell locally"
	if is_instance_valid(controls) and controls.using_gamepad and is_instance_valid(_hud):
		_hud.text=InputProfile.controller_text(_hud.text)
	for prop in _oral_props:
		prop.visible=model.aftermath_phase()=="complete"

func _load(path: String="") -> void:
	var staged:=MemoryState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="The complete chapter, including received accounts, was restored." if error.is_empty() else error
	_clear_pending_actions()
	_resume()
