extends "res://territory/gujranwala_chapter.gd"
## Same home entry. The extra route is optional; the original supply contract remains usable.
const RoadState := preload("res://territory/road/road_state.gd")
const Road := preload("res://territory/road/road_rules.gd")
const Narration := preload("res://narrative/narration_track.gd")
var narration := Narration.new()
var _road_action := ""
var _boom: StaticBody3D
var _roadkeeper: Node3D
var _road_sign: Label3D
var _narrator_panel: PanelContainer
var _narrator_caption: Label
var _gate_enabled := false

func _init() -> void:
	model=RoadState.new()
	save_path=RoadState.ROAD_SAVE

func _ready() -> void:
	super._ready()
	_build_narrator_panel()
	if int(model.progress().tick)>0: narration.rebase(_narration_events())
	else: narration.observe(_narration_events())
	_sync_road()

func _build_world() -> void:
	super._build_world()
	# A removable physical bar on the shared road. Not a historical building/faction claim.
	var visual:=_box(Vector3(0.32,0.30,6.0),Road.BOOM,Color("69553e"),true)
	_boom=visual.get_parent()
	_boom.name="DisputedRoadBoom"
	_boom.collision_layer=0
	_boom.hide()
	_roadkeeper=_box(Vector3(0.55,1.65,0.55),Road.SPEAKER+Vector3.UP*0.825,Color("6b737d")).get_parent()
	_roadkeeper.name="FictionalRoadkeeper"
	_roadkeeper.hide()
	_road_sign=Label3D.new()
	_road_sign.text="Roadkeeper [E]"
	_road_sign.position=Road.SPEAKER+Vector3.UP*2.2
	_road_sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	_road_sign.font_size=18
	_road_sign.pixel_size=0.0015
	_road_sign.fixed_size=true
	add_child(_road_sign)
	_road_sign.hide()

func _build_narrator_panel() -> void:
	# Insert in the existing layout, not an absolute overlay that covers captions/controls.
	var column: Control=_caption.get_parent().get_parent()
	_narrator_panel=PanelContainer.new()
	_narrator_panel.name="ShahMuhammadNarration"
	_narrator_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("202827e8")
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=9
	style.content_margin_bottom=9
	_narrator_panel.add_theme_stylebox_override("panel",style)
	_narrator_caption=Label.new()
	_narrator_caption.name="NarratorCaption"
	_narrator_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_narrator_caption.add_theme_font_size_override("font_size",17)
	_narrator_caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_narrator_panel.add_child(_narrator_caption)
	column.add_child(_narrator_panel)
	column.move_child(_narrator_panel,_caption.get_parent().get_index())
	_narrator_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
		_open_narration()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _open_narration() -> void:
	_show_dialog("NARRATOR · PLAYER PERSPECTIVE",narration.transcript_text(),[
		["Turn narrator captions off" if narration.enabled else "Turn narrator captions on","narrator_toggle"],
		["Return","resume"]])

func _open_market() -> void:
	super._open_market()
	if model.has_economy() and model.economy().ledger.caravan=="available":
		var button:=Button.new()
		button.text="Escort via the disputed crossing · optional local-road assignment"
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=42
		button.pressed.connect(_menu_action.bind("road:accept"))
		_actions.add_child(button)
		_actions.move_child(button,0)
		_layout()

func _open_journal() -> void:
	super._open_journal()
	var button:=Button.new()
	button.text="Import previous Gujranwala supply save"
	button.custom_minimum_size.y=42
	button.pressed.connect(_menu_action.bind("road:import_supply"))
	_actions.add_child(button)
	_layout()

func _interact() -> void:
	if model.has_road() and not model.mounted() and Model.distance(model.position(),Road.SPEAKER)<3:
		if not _seen(Road.SPEAKER+Vector3.UP*1.3,4):
			_message="Face the roadkeeper and move into clear sight."
		elif model.road().visited.size()<2:
			_message="Roadkeeper · Bring your carrier to the bar before asking for passage."
		else: _open_road_dialog()
		return
	super._interact()

func _open_road_dialog() -> void:
	var r: Dictionary=model.road()
	var actions: Array=[]
	var body := "FICTIONAL LOCAL-ROAD ENCOUNTER\n\nRoadkeeper · This household claims the crossing. Recognition buys passage, not ownership of the villages. You may ask me to seek permission for this load, or lead it around the longer field path.\n\nThe original shipment, cargo and payment remain unchanged. Choosing the disputed route awards no extra soldiers or money."
	if r.heard_tick<0:
		var error: String=model.hear_roadkeeper()
		if not error.is_empty(): _message=error;return
		r=model.road()
	if r.choice=="":
		actions.append_array([["Recognize the local passage claim · open the direct road","road:recognize_claim"],
			["Ask for confirmation · wait, then hear the answer here","road:seek_confirmation"],
			["Use the longer field bypass · leave the claim unresolved","road:bypass"]])
	elif r.choice=="seek_confirmation" and r.reply_received_tick<0:
		var ticks: int=maxi(0,int(r.decision_tick)+Road.REPLY_DELAY-int(model.progress().tick))
		body+="\n\nThe answer can be heard here after %0.1f more unpaused seconds. A paused conversation does not advance the courier delay."%(ticks/60.0)
		actions.append(["Hear the returned answer","road:receive_reply"])
	else:
		body+="\n\nDecision: "+r.choice.replace("_"," ")+". Lead the same carrier home; stay within nine metres."
	actions.append(["Return to the road","resume"])
	_show_dialog("A ROAD AND A CLAIM",body,actions)

func _menu_action(action: String) -> void:
	if action=="narrator_toggle":
		narration.set_enabled(not narration.enabled)
		_open_narration()
		return
	if action.begins_with("road:"):
		_road_action=action.trim_prefix("road:")
		return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_road_action=""

func _physics_process(delta: float) -> void:
	if not _road_action.is_empty():
		var action:=_road_action
		_road_action=""
		if action=="import_supply":
			_load(Territory.TERRITORY_SAVE)
			return
		var error: String
		if action=="accept": error=model.accept_disputed_escort()
		elif action=="receive_reply": error=model.receive_road_reply()
		else: error=model.choose_road(action)
		_message=error if not error.is_empty() else "Buddh · The route decision is made. Stay with the carrier; the load is not home yet."
		_sync_economy(true)
		_sync_road()
		_resume()
		_refresh()
	else:
		super._physics_process(delta)
	_sync_road()
	narration.observe(_narration_events())
	var quiet: bool=not _paused and model.stage() not in ["active","caught"]
	narration.step(delta,quiet)
	if is_instance_valid(_narrator_panel):
		_narrator_panel.visible=quiet and not narration.text().is_empty()
		_narrator_caption.text="SHAH MUHAMMAD · NARRATOR\n"+narration.text()

func _step_merchant(delta: float) -> void:
	if not model.has_road():
		super._step_merchant(delta)
		return
	var m: Dictionary=model.economy()
	if m.ledger.caravan!="active": return
	var r: Dictionary=model.road()
	var moving: bool=Road.moving(r) and Model.distance(model.position(),merchant.global_position)<=9
	var target: Vector3=Road.target(r)
	var waypoint: Vector3=_navigation.waypoint(merchant.global_position,target) if moving else merchant.global_position
	var motion: Dictionary=merchant.step(delta,waypoint,moving)
	var error: String=model.record_merchant(motion,delta)
	if not error.is_empty():
		merchant.apply(m.merchant)
		_message=error

func _sync_road() -> void:
	if not is_instance_valid(_boom): return
	var active: bool=model.has_road()
	var closed: bool=active and not Road.permitted(model.road())
	_boom.visible=closed
	_roadkeeper.visible=active
	_road_sign.visible=active
	if closed!=_gate_enabled:
		_gate_enabled=closed
		_boom.collision_layer=1 if closed else 0
		_navigation.built=false # Rebuild once on a physical access change, not every frame.

func _apply() -> void:
	super._apply()
	_sync_road()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	_hud.text+="\nN: narrator captions / session transcript"
	if model.has_road() and model.road().completed_tick<0:
		var phase: String=Road.phase(model.road())
		var instructions: Dictionary={
			"approaching":"Accompany the carrier to the road bar.",
			"hear_claim":"Carrier halted. Speak to the roadkeeper on foot [E].",
			"choose":"Choose a passage agreement at the roadkeeper [E].",
			"await_reply":"Wait in the unpaused world, then hear the roadkeeper's reply [E].",
			"travelling":"Lead the carrier along the chosen route; remain within 9 m.",
			"arrived":"Carrier is home. Check in at the quartermaster [E]."}
		_hud.text+="\nROAD ASSIGNMENT · "+str(instructions.get(phase,phase))

func _account_text() -> String:
	return super._account_text().replace("The caravan's route has no hostile encounter yet.","The optional road dispute has negotiation and a bypass, not combat or a new toll charge.")

func _narration_events() -> Array:
	var events: Array=["home_open"]
	if model.stage()=="escaped": events.append("ambush_return")
	if model.has_economy():
		events.append("allowance")
		if model.economy().ledger.caravan=="complete": events.append("caravan_return")
	if model.has_road():
		var r: Dictionary=model.road()
		events.append("road_assignment")
		if r.choice=="recognize_claim": events.append("claim_recognized")
		if r.choice=="bypass": events.append("bypass_chosen")
		if r.reply_received_tick>=0: events.append("reply_received")
	return events

func _candidate_error(staged: Story) -> String:
	# Validate against static scenery first, then the CANDIDATE's gate state. The live
	# gate mask is restored before returning; no physics step occurs during staging.
	var layer: int=_boom.collision_layer if is_instance_valid(_boom) else 0
	if is_instance_valid(_boom): _boom.collision_layer=0
	var error:=super._candidate_error(staged)
	if is_instance_valid(_boom): _boom.collision_layer=layer
	if not error.is_empty(): return error
	if staged is RoadState and staged.has_road() and not Road.permitted(staged.road()):
		var probes: Array=[{"p":staged.position(),"radius":0.45},
			{"p":Model.point(staged.horse_record().position),"radius":0.85},
			{"p":Model.point(staged.economy().merchant.position),"radius":0.45}]
		for probe in probes:
			# Conservative horizontal clearance for the closed waist-high bar.
			if absf(probe.p.x-Road.BOOM.x)<0.16+probe.radius and absf(probe.p.z-Road.BOOM.z)<3.0+probe.radius and probe.p.y<1.3:
				return "Saved actor/caravan intersects the candidate's closed road bar. Session unchanged."
	return ""

func _load(path: String="") -> void:
	var staged:=RoadState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty():
		_apply()
		narration.rebase(_narration_events())
	_message="World, caravan and passage claim restored together. Narration does not add character knowledge." if error.is_empty() else error
	_clear_pending_actions()
	_resume()

func _restore_checkpoint() -> void:
	super._restore_checkpoint()
	if not _paused: narration.rebase(_narration_events())
