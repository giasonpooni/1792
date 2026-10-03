extends "res://childhood/home_chapter.gd"
## Same chapter, physics and world authority, with an opt-in extended menu entry.
const Campaign := preload("res://politics/political_state.gd")
const EyeShader := preload("res://perception/one_eye.gdshader")
const GroundFocus := preload("res://perception/ground_focus.gd")
var campaign: Campaign
var ground_focus: Node
var _eye_level := true
var _attention_cue := "No watchful glance has been observed. This is not proof of privacy."
var _north_observer: MeshInstance3D
var _outpost_visuals: Array = []
var _social_visuals: Array = []

func _init() -> void:
	campaign = Campaign.new()
	model = campaign # Two references to ONE authority, not two simulations.
	save_path = Campaign.POLITICAL_SAVE

func _ready() -> void:
	super._ready()
	var material := ShaderMaterial.new()
	material.shader = EyeShader
	_veil.material = material
	_north_observer = _box(Vector3(0.55,1.65,0.5),Vector3(-18,0.965,-20),Color("736d57"))
	for id in Campaign.OUTPOSTS:
		var node := _box(Vector3(1.2,1.2,1.2),Campaign.OUTPOSTS[id]+Vector3.UP*0.6,Color("8f7056"))
		var label := Label3D.new()
		label.text = str(id).capitalize()+" · authored outpost [E]"
		label.position.y = 1.4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 20
		label.pixel_size = 0.002
		node.add_child(label)
		_outpost_visuals.append(node)
	for id in Campaign.Politics.SocialProfile.ADDED_RESIDENTS:
		var at: Vector3 = Campaign.Politics.SocialProfile.SITES[id]
		var resident := _box(Vector3(0.55,1.65,0.5),at+Vector3.UP*0.825,Color("796f5b"))
		var label := Label3D.new()
		label.text = Campaign.Registry.PEOPLE[id].name+" [E]"
		label.position.y = 1.2
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 20
		label.pixel_size = 0.002
		resident.add_child(label)
		_social_visuals.append(resident)
	ground_focus=GroundFocus.new();ground_focus.name="GroundFocus";add_child(ground_focus);ground_focus.bind(self)
	ground_focus.register_target("trainer",trainer,"Trainer","interaction")
	ground_focus.register_target("mother",_mother,"Raj Kaur","ally")
	ground_focus.register_target("bend_trace",_clue,"Ground trace","clue")
	ground_focus.register_target("household_horse",horse,"Household horse","interaction",Vector3.UP*1.1)
	ground_focus.register_target("unknown_assailant",attacker,"Unknown contact","contact",Vector3.UP*1.15)
	ground_focus.register_target("household_guard",escort,"Household guard","ally",Vector3.UP*1.15)
	ground_focus.register_target("north_contact",_north_observer,"Unknown contact","contact",Vector3.UP*0.7)
	for id in Campaign.OUTPOSTS:
		ground_focus.register_target("outpost_"+id,_outpost_visuals[Campaign.OUTPOSTS.keys().find(id)],str(id).capitalize()+" outpost","interaction",Vector3.UP*0.6)
	for i in range(Campaign.Politics.SocialProfile.ADDED_RESIDENTS.size()):
		var id: String=Campaign.Politics.SocialProfile.ADDED_RESIDENTS[i]
		ground_focus.register_target("resident_"+id,_social_visuals[i],Campaign.Registry.PEOPLE[id].name,"interaction",Vector3.UP*0.8)
	_sync_eye_camera()
	_refresh()

func _apply() -> void:
	super._apply()
	if is_instance_valid(ground_focus): ground_focus.clear()
	_sync_eye_camera()

func _sync_eye_camera() -> void:
	if not is_instance_valid(avatar): return
	var arm: SpringArm3D = avatar.get_node("CameraPivot/SpringArm3D")
	var camera: Camera3D = arm.get_node("Camera3D")
	arm.spring_length = 0.0 if _eye_level else 6.8 if model.mounted() else 5.5
	# SpringArm owns its child's translation: put the eye offset on the arm itself.
	arm.position.x = float(campaign.perception().healthy_eye_offset) if _eye_level else 0.0
	camera.position.x = 0.0
	camera.near = 0.05 if _eye_level else 0.1
	avatar.get_node("MeshInstance3D").visible = not _eye_level and not model.mounted()

func _eye_origin() -> Vector3:
	# The inherited pivot already owns walking/riding eye height.
	return avatar.pivot.global_position+avatar.pivot.global_basis.x*float(campaign.perception().healthy_eye_offset)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			if ground_focus.active: ground_focus.stop()
			else:
				var reason:=_focus_access()
				if reason.is_empty(): ground_focus.start()
				else: _message=reason;_refresh()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F6:
			_eye_level = not _eye_level
			_sync_eye_camera()
			_refresh()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_P:
			_open_journal()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _focus_access() -> String:
	if _paused: return "Close the current conversation or notebook before focusing."
	if model.mounted() or model.stage() in ["active","caught"]: return "Focus requires a quiet moment on foot."
	if Input.is_action_pressed("sprint"): return "Slow down before focusing."
	return ""

func _physics_process(delta: float) -> void:
	var before: int = model.progress().tick
	super._physics_process(delta)
	if is_instance_valid(ground_focus):
		if ground_focus.active and not _focus_access().is_empty(): ground_focus.stop()
		ground_focus.sample(int(model.progress().tick))
	if not _paused and model.progress().tick != before and int(model.progress().tick)%60 == 0:
		_sample_observers()
	_sync_eye_camera()

func _sample_observers() -> void:
	if model.stage() != "escaped": return
	var samples := [
		{"id":"raj_kaur","at":Story.MOTHER+Vector3.UP*1.5,"forward":Vector3.FORWARD},
		{"id":"fictional_north_observer","at":Vector3(-18,1.64,-20),"forward":Vector3.RIGHT}
	]
	if model.aftermath().escort.active:
		samples.append({"id":"fictional_household_guard","at":escort.global_position+Vector3.UP*1.5,"forward":-escort.global_basis.z})
	var noticed: Array = []
	for observer in samples:
		var at: Vector3 = observer.at
		var destination: Vector3 = avatar.pivot.global_position-Vector3.UP*0.2
		var offset: Vector3 = destination-at
		var facing: Vector3 = observer.forward
		var in_cone := Vector2(facing.x,facing.z).normalized().dot(Vector2(offset.x,offset.z).normalized()) >= cos(deg_to_rad(65.0))
		if offset.length() > 22.0 or not in_cone: continue
		var ray := PhysicsRayQueryParameters3D.create(at,destination,1,[avatar.get_rid(),horse.get_rid(),escort.get_rid(),attacker.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var signature := clampf(0.35+(0.25 if model.mounted() else 0.0)+(0.25 if avatar.velocity.length() > 5.0 else 0.0)+0.15*(1.0-offset.length()/22.0),0.1,1.0)
		campaign.record_gaze(observer.id,true,signature)
		if _seen(at,24.0): noticed.append(Campaign.Registry.PEOPLE[observer.id].name)
	_attention_cue = "A watchful glance: "+", ".join(noticed) if not noticed.is_empty() else "No watchful glance has been observed. This is not proof of privacy."

func _seen(at: Vector3, reach: float) -> bool:
	var eye: Vector3 = _eye_origin()
	var offset: Vector3 = at-eye
	var forward: Vector3 = -avatar.pivot.global_basis.z
	var angle := Campaign.Vision.bearing(forward,offset)
	var ray := PhysicsRayQueryParameters3D.create(eye,at,1,[avatar.get_rid(),horse.get_rid(),attacker.get_rid()])
	var clear := get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	return campaign.can_perceive(angle,offset.length(),reach,clear)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var p := campaign.perception()
	if _veil.material is ShaderMaterial and _veil.material.shader == EyeShader:
		_veil.material.set_shader_parameter("loss",p.loss)
		_veil.material.set_shader_parameter("affected_left",p.affected_left)
	_hud.text += "\nP reports · F6 camera: %s · Vision: %s (authored profile)\n%s" % ["eye-level" if _eye_level else "follow",p.stage,_attention_cue]
	if _focus_access().is_empty(): _hud.text += "\nZ Focus · uses the current character-eye vision profile"
	if campaign.political_inputs().size() >= Campaign.Politics.MAX_INPUTS:
		_hud.text += "\nPrototype ledger full: further political inputs are refused; save remains available."
	if is_instance_valid(_north_observer): _north_observer.get_parent().visible = model.stage() == "escaped"
	for node in _outpost_visuals: node.get_parent().visible = model.aftermath_phase() == "complete"
	for node in _social_visuals: node.get_parent().visible = model.aftermath_phase() == "complete"

func _open_journal() -> void:
	if is_instance_valid(ground_focus): ground_focus.stop()
	super._open_journal()
	_panel_text.text = _panel_text.text.replace("Eye loss is already present; F4 changes only subjective framing. There is no historically established progressive-blindness schedule here.",
		"The extended new-game profile gradually reduces left-eye contribution during active play and stops at one-eye vision. This is authored, not a verified disease timeline. Imported legacy saves retain stable one-eye vision. F4 changes rendering only; F6 changes viewpoint, not perception or rival knowledge.")
	_panel_text.text += "\n\nPOLITICAL PROTOTYPE\nAfter the inquiry, E at Raj Kaur arranges scouts, reparations or discretion. E at authored outpost nodes orders an abstract raid/incursion. No physical army deployment or complete historical retainer roster is claimed. Rival metrics and undiscovered plots are not exposed in this journal."
	_panel_text.text += "\n\nLOCAL SOCIAL FIELD\nAfter the inquiry, E at the market keeper or gate keeper hears their current response. News reaches each through authored delayed channels. Their manner is evidence of their own response, not a view of every faction. These conversations do not alter the separate household trade economy."
	var button := Button.new()
	button.text = "Import previous aftermath save (original slot is not overwritten)"
	button.custom_minimum_size.y = 48
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("political_import"))
	_actions.add_child(button)

func _show_dialog(title: String,body: String,actions: Array) -> void:
	if is_instance_valid(ground_focus): ground_focus.stop()
	super._show_dialog(title,body,actions)

func _interact() -> void:
	if model.aftermath_phase() != "complete" or model.mounted():
		super._interact()
		return
	for id in Campaign.Politics.SocialProfile.SITES:
		var at: Vector3 = Campaign.Politics.SocialProfile.SITES[id]
		if Model.distance(model.position(),at)>3.0: continue
		var response := campaign.local_social_response(id,_seen(at+Vector3.UP,4.0))
		if not response.is_empty():
			_show_dialog(response.speaker.to_upper()+" · LOCAL CONVERSATION",response.text,[["Leave","resume"]])
			return
	if Model.distance(model.position(),Story.MOTHER) <= 3.0 and _seen(Story.MOTHER+Vector3.UP,4.0):
		var household := campaign.local_social_response("raj_kaur",true)
		_show_dialog("PHULKIAN HOUSEHOLD · RAJ KAUR", str(household.get("text",""))+"\n\nAuthored household arrangements. Scouts produce delayed, fallible reports; reparations address one grievance, not every rival. Discretion lowers public exposure and supports abstract protective precautions.",
			[["Send scouts toward Bhangi (8)","policy:scout:bhangi"],["Send scouts toward Sandhawalia (8)","policy:scout:sandhawalia"],
			["Offer Phulkian reparations (15)","policy:reparation:phulkian"],["Offer Bhangi reparations (15)","policy:reparation:bhangi"],
			["Offer Sandhawalia reparations (15)","policy:reparation:sandhawalia"],["Reduce public exposure / precautions (5)","policy:discretion:sukerchakia"],["Leave","resume"]])
		return
	for id in Campaign.OUTPOSTS:
		var at: Vector3 = Campaign.OUTPOSTS[id]
		if Model.distance(model.position(),at) <= 3.0 and _seen(at+Vector3.UP,4.0):
			_show_dialog(str(id).to_upper()+" · AUTHORED CAMPAIGN NODE", "These orders resolve abstract political/logistical incidents, not a staged battle. A raid is more visible than an incursion. Opponents respond to reports, resources, grievances and opportunities rather than a universal hostility flag.",
				[["Order raid (12)","policy:raid:"+str(id)],["Order limited incursion (6)","policy:incursion:"+str(id)],["Withdraw without incident","resume"]])
			return
	super._interact()

func _run_after_action(action: String) -> void:
	if action == "political_import":
		_load(Story.AFTER_SAVE)
		return
	if not action.begins_with("policy:"):
		super._run_after_action(action)
		return
	var parts := action.split(":")
	var error := campaign.order_political(parts[1],parts[2]) if parts.size() == 3 else "Malformed order."
	_message = "Order recorded. Its wider consequences are not yet known." if error.is_empty() else error
	_resume()

func _load(path: String = "") -> void:
	var staged := Campaign.new()
	var error := staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error = _candidate_error(staged)
	if error.is_empty(): error = campaign.restore(staged.snapshot())
	if error.is_empty():
		_attention_cue = "No watchful glance has been observed since this restore."
		_apply()
	_message = "Chapter loaded; perception, events and received knowledge restored." if error.is_empty() else error
	_clear_pending_actions()
	_resume()

func _capture_checkpoint(reason: String) -> void:
	var error := _candidate_error(campaign)
	if error.is_empty(): error = Checkpoint.write(checkpoint_path(),campaign.snapshot(),avatar.pivot.rotation,reason,Campaign)
	_checkpoint_note = "Checkpoint retained with political and vision state." if error.is_empty() else "Checkpoint not saved: "+error
	_message += "\n"+_checkpoint_note

func _restore_checkpoint() -> void:
	var result := Checkpoint.read(checkpoint_path(),Campaign)
	var error: String = result.error
	var staged := Campaign.new()
	if error.is_empty(): error = staged.restore(result.envelope.snapshot)
	if error.is_empty(): error = _candidate_error(staged)
	if error.is_empty(): error = campaign.restore(staged.snapshot())
	if not error.is_empty():
		_show_dialog("CHECKPOINT NOT RESTORED",error+"\nCurrent state is unchanged.",[["Return","resume"]])
		return
	_attention_cue = "No watchful glance has been observed since this restore."
	_apply()
	avatar.pivot.rotation = Vector3(result.envelope.camera[0],result.envelope.camera[1],0)
	_clear_pending_actions()
	_message = "Checkpoint restored. Future political knowledge and sight progression were discarded with that attempt."
	_resume()
