# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Scene-local horsecraft workload. Existing horse.step owns each body's motor.
## No campaign, interlude receipt, save, inventory or character-knowledge authority.
const Horse:=preload("res://mounts/horse.tscn")
const State:=preload("res://mounts/horsecraft_state.gd")
const Kit:=preload("res://presentation/workshop_kit.gd")
const RiderVisual:=preload("res://mounts/horsecraft_rider_visual.gd")
var model:=State.new()
var kit:=Kit.new()
var left: CharacterBody3D
var right: CharacterBody3D
var camera: Camera3D
var hud: Label
var status: Label
var paused:=false
var release_mouse_on_exit:=true # Standalone study owns input; hosted lessons defer to their session.
var message:="Ride together, rise, fire four separate matchlocks, slow to recharge each, then settle and stop."
var aim_yaw:=0.0
var aim_pitch:=-0.12
var standing_blend:=0.0
var rider: Node3D
var weapon: Node3D
var body: MeshInstance3D
var head: MeshInstance3D
var turban: MeshInstance3D
var legs: Array[MeshInstance3D]=[]
var arms: Array[MeshInstance3D]=[]
var shoes: Array[MeshInstance3D]=[]
var stored_weapons: Array[MeshInstance3D]=[]
var effects: Array[Dictionary]=[]
var observations: Array[Dictionary]=[]
var shot_observations: Array[Dictionary]=[]
var targets: Array[StaticBody3D]=[]
var target_materials: Dictionary={}
var shot_sound: AudioStreamPlayer3D

func _ready() -> void:
	set_meta("classification","horsecraft-mechanics-study")
	set_meta("historical_authentication",false)
	set_meta("campaign_admission",false)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("93a3ac")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("eee0c5");env.ambient_light_energy=.45
	world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-28,0)
	sun.light_color=Color("ffe0b2");sun.light_energy=1.1;sun.shadow_enabled=true;add_child(sun)
	obstacle("PracticeGround",Vector3(0,-.16,-28),Vector3(64,.32,116),Color("ab9a77"))
	for x in [-16.0,16.0]:
		obstacle("LaneWall",Vector3(x,1.2,-25),Vector3(.4,2.4,100),Color("bbaa87"))
	for z in [-76.0,28.0]:
		obstacle("LaneEnd",Vector3(0,1.2,z),Vector3(32,2.4,.4),Color("bbaa87"))
	for z in [10.0,-8.0,-26.0,-44.0]:
		for x in [-4.0,4.0]:
			kit.box(self,Vector3(x,.06,z),Vector3(.10,.12,3.0),kit.plain("806a4a"))
	for i in range(4):
		var target:=obstacle("Target%d"%i,Vector3((-1.0 if i%2==0 else 1.0)*6.5,2.2,-8.0-i*12.0),Vector3(1.5,2.0,.22),Color("936142"),2)
		target.set_meta("target_id","practice_target_%d"%i);targets.append(target)
		var disk:=CylinderMesh.new();disk.top_radius=.48;disk.bottom_radius=.48;disk.height=.035;disk.radial_segments=24
		var marking:=kit.mesh_at(target,disk,Vector3(0,.1,.14),kit.plain("e0c493"));marking.rotation.x=PI/2
	left=Horse.instantiate();left.name="StudyHorseLeft";add_child(left)
	right=Horse.instantiate();right.name="StudyHorseRight";add_child(right)
	# Both conservative .8 m hulls remain collidable, independent and game-owned.
	_build_rider()
	_build_shot_sound()
	camera=Camera3D.new();camera.name="HorsecraftGameplayCamera";camera.far=160;camera.fov=62;add_child(camera)
	_build_hud()
	restart_study()
	if Engine.physics_ticks_per_second!=60:
		set_paused(true);message="This practice requires the game's 60 Hz physics setting."

func obstacle(id: String,at: Vector3,size: Vector3,color: Color,layer: int=1) -> StaticBody3D:
	var node:=StaticBody3D.new();node.name=id;node.position=at;node.collision_layer=layer;node.collision_mask=1
	var box:=BoxShape3D.new();box.size=size;var shape:=CollisionShape3D.new();shape.shape=box;node.add_child(shape)
	kit.box(node,Vector3.ZERO,size,kit.plain(color.to_html(false)));add_child(node);return node

func record(horse: CharacterBody3D) -> Dictionary:
	return {"position":[horse.global_position.x,horse.global_position.y,horse.global_position.z],"yaw":horse.rotation.y,
		"speed":horse.speed,"grounded":horse.is_on_floor(),"vertical_speed":horse.velocity.y}

func observation() -> Dictionary:
	return model.metrics(record(left),record(right))

func _step_motion(delta: float,throttle: float,steering: float,canter: bool,walk: bool,brake: bool) -> Dictionary:
	# Bounded follower inputs, not a kinematic constraint or transform copy.
	var lead: Dictionary=left.step(delta,throttle,steering,canter,walk,brake)
	var forward: Vector3=-left.global_basis.z
	var destination: Vector3=left.global_position+left.global_basis.x*2.1+forward*3.5
	var toward: Vector3=destination-right.global_position
	var heading_error:=wrapf(atan2(-toward.x,-toward.z)-right.rotation.y,-PI,PI)
	var follower_steering:=clampf(-heading_error*1.6,-1.0,1.0)
	var along_error:=forward.dot(left.global_position+left.global_basis.x*2.1-right.global_position)
	var follower_throttle:=clampf(throttle+along_error*.22,0.0,1.0)
	if brake or throttle<.01: follower_throttle=0.0
	var follow: Dictionary=right.step(delta,follower_throttle,follower_steering,canter,walk,brake)
	return {"left":lead,"right":follow,"support":model.metrics(lead,follow)}

func restart_study() -> void:
	model.restart();observations.clear();shot_observations.clear()
	if is_instance_valid(shot_sound): shot_sound.stop()
	for item in effects:
		if is_instance_valid(item.node): item.node.queue_free()
	effects.clear();standing_blend=0.0
	for pair in [[left,-1.05],[right,1.05]]:
		var horse: CharacterBody3D=pair[0]
		horse.apply_record({"position":[pair[1],.04,18.0],"yaw":0.0,"speed":0.0,"vertical_speed":0.0,"rider_id":""})
		horse.velocity=Vector3.ZERO
	for target in targets:
		for mesh in target.find_children("*","MeshInstance3D",true,false):
			if target_materials.has(mesh.get_instance_id()): mesh.material_override=target_materials[mesh.get_instance_id()]
	aim_yaw=0.0;aim_pitch=-.12;set_paused(false)
	message="A tale attributed to Maha Singh inspired this practice; its date and battlefield are unresolved."
	_present()

func set_paused(value: bool) -> void:
	paused=value or Engine.physics_ticks_per_second!=State.TICK_HZ
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	_refresh()

func toggle_stance() -> void:
	if paused: return
	var error: String=model.toggle_stance(observation())
	message=error if not error.is_empty() else "Changing riding stance. Keep the pair aligned."
	_refresh()

func reload() -> void:
	if paused: return
	var error: String=model.reload(observation())
	message=error if not error.is_empty() else "Reloading selected matchlock. Stay slow and aligned."
	_present(false)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not paused:
		aim_yaw=clampf(aim_yaw-event.relative.x*.003,-1.35,1.35)
		aim_pitch=clampf(aim_pitch-event.relative.y*.0025,-.55,.28)
		_present();return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		fire();return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE: set_paused(not paused)
		KEY_SPACE: toggle_stance()
		KEY_R: reload()
		KEY_BACKSPACE: restart_study()
		KEY_1,KEY_2,KEY_3,KEY_4:
			if not paused:
				var error: String=model.select_slot(int(event.keycode-KEY_1))
				message=error if not error.is_empty() else "Matchlock %d selected."%[event.keycode-KEY_1+1]
				_present(false)
		KEY_F1: get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_: return
	get_viewport().set_input_as_handled();_refresh()

func _physics_process(delta: float) -> void:
	if paused: return
	var throttle:=Input.get_action_strength("move_forward")
	var steering:=Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
	var lean:=float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q))
	var walk:=Input.is_physical_key_pressed(KEY_CTRL)
	var canter:=Input.is_action_pressed("sprint")
	var before: Dictionary=model.snapshot()
	var brake: bool=Input.is_action_pressed("move_backward") or before.get("brake_required",false)
	var motion:=_step_motion(delta,throttle,steering,canter,walk,brake)
	var lead: Dictionary=motion.left
	var follow: Dictionary=motion.right
	var metrics: Dictionary=motion.support
	var error: String=model.advance(metrics,steering,lean)
	if not error.is_empty(): message=error
	if model.snapshot().stage=="complete":
		message="Four weapons recharged and both horses stopped. Backspace retries the study."
	elif model.snapshot().get("brake_required",false):
		message="Settling the rider and braking the pair." if metrics.safe else "Support lost. Settle the rider and brake; Backspace retries the exercise."
	observations.append({"tick":model.snapshot().tick,"left":lead,"right":follow,"support":metrics})
	if observations.size()>2048: observations.pop_front()
	standing_blend=move_toward(standing_blend,1.0 if model.stance() in ["rising","standing"] else 0.0,1.0/(36.0 if model.stance()=="recovering" else 48.0))
	_present();_refresh()
	var now: int=model.snapshot().tick
	for i in range(effects.size()-1,-1,-1):
		if effects[i].until<=now:
			if is_instance_valid(effects[i].node): effects[i].node.queue_free()
			effects.remove_at(i)

func shot_query(origin: Vector3,end: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(origin,end,3,[left.get_rid(),right.get_rid()])
	query.hit_from_inside=true
	return get_world_3d().direct_space_state.intersect_ray(query)

func fire() -> Dictionary:
	if paused: return {"accepted":false,"reason":"Practice is paused."}
	# Selection and aim can change several times within one physics tick.
	_present(false)
	var event: Dictionary=model.fire(observation())
	if not event.accepted:
		message=event.reason;_refresh();return event
	var origin: Vector3=rider.active_muzzle_world()
	var direction: Vector3=-camera.global_basis.z
	# Reproducible authored dispersion; no calibrated ballistics or unowned randomness.
	var spread: float=event.dispersion
	var phase: float=float(event.shot_id)*2.399963
	direction=(direction+camera.global_basis.x*cos(phase)*spread+camera.global_basis.y*sin(phase)*spread).normalized()
	var camera_end: Vector3=camera.global_position+direction*100.0
	var aim_hit:=shot_query(camera.global_position,camera_end)
	var aim_point: Vector3=aim_hit.position if not aim_hit.is_empty() else camera_end
	# The weapon can protrude beyond a horse's conservative hull. Check from
	# the rider's shoulder to the muzzle before admitting the outward shot.
	var shoulder: Vector3=rider.shoulder_world()
	var barrel_hit:=shot_query(shoulder,origin)
	var hit: Dictionary=barrel_hit if not barrel_hit.is_empty() else shot_query(origin,aim_point)
	var endpoint: Vector3=hit.position if not hit.is_empty() else aim_point
	var target_id:=""
	if not hit.is_empty() and hit.collider.has_meta("target_id"):
		target_id=hit.collider.get_meta("target_id")
		var error: String=model.record_hit(event.shot_id,target_id)
		if error.is_empty():
			for mesh in hit.collider.find_children("*","MeshInstance3D",true,false):
				if not target_materials.has(mesh.get_instance_id()): target_materials[mesh.get_instance_id()]=mesh.material_override
				mesh.material_override=kit.plain("6d8563")
	var trace:=ImmediateMesh.new();trace.surface_begin(Mesh.PRIMITIVE_LINES,kit.plain("e9d2a0"))
	trace.surface_add_vertex(origin);trace.surface_add_vertex(endpoint);trace.surface_end()
	var visual:=MeshInstance3D.new();visual.mesh=trace;add_child(visual)
	effects.append({"node":visual,"until":model.snapshot().tick+12})
	var flash:=kit.ellipsoid(self,origin,Vector3(.18,.18,.25),kit.plain("ffd896"))
	effects.append({"node":flash,"until":model.snapshot().tick+5})
	shot_sound.global_position=origin;shot_sound.play()
	shot_observations.append({"shot_id":event.shot_id,"slot":event.slot,"tick":model.snapshot().tick,
		"origin":[origin.x,origin.y,origin.z],"endpoint":[endpoint.x,endpoint.y,endpoint.z],"target_id":target_id,
		"collision":not hit.is_empty(),"muzzle_obstructed":not barrel_hit.is_empty()})
	message="Matchlock %d fired · %s"%[event.slot+1,"target struck" if not target_id.is_empty() else "shot spent"]
	_present(false);_refresh();return event

func _build_shot_sound() -> void:
	# Original synthetic foley; no historical acoustic or firearm-energy calibration.
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050
	var data:=PackedByteArray();data.resize(11024)
	var noise_seed:=9137
	for i in range(5512):
		noise_seed=(noise_seed*1103515245+12345)&0x7fffffff
		var noise:=float(noise_seed%65536)/32768.0-1.0
		var seconds:=float(i)/22050.0
		var amplitude: float=(noise*.6+sin(seconds*TAU*85.0)*.25)*exp(-seconds*28.0)
		data.encode_s16(i*2,int(clampf(amplitude,-1,1)*21000))
	stream.data=data
	shot_sound=AudioStreamPlayer3D.new();shot_sound.stream=stream;shot_sound.volume_db=-12;shot_sound.max_distance=60
	add_child(shot_sound)

func _build_rider() -> void:
	rider=RiderVisual.new();add_child(rider);rider.configure(kit);rider.name="HorsecraftRiderVisual"
	body=rider.body;head=rider.head;turban=rider.turban;weapon=rider.weapon_mount

func active_riding_horses() -> Array[CharacterBody3D]:
	return [left,right]

func riding_centers() -> Array[Vector3]:
	return [left.global_position,right.global_position]

func rider_support_points() -> Array[Vector3]:
	# Feet use the inward part of each actual saddle, within the .65 m seat.
	return [left.saddle_support_point()+left.global_basis.x*.22,
		right.saddle_support_point()-right.global_basis.x*.22]

func _present(update_camera: bool=true) -> void:
	if not is_instance_valid(left) or not is_instance_valid(camera): return
	var centers:=riding_centers()
	var middle: Vector3=(centers[0]+centers[1])*.5
	var yaws: Array[float]=[];var bridles: Array[Vector3]=[]
	for horse in active_riding_horses():
		yaws.append(horse.rotation.y);bridles.append_array(horse.bridle_points_world())
	var snapshot: Dictionary=model.snapshot()
	var shot_tick: int=-1
	for i in range(snapshot.shots.size()-1,-1,-1):
		if snapshot.shots[i].slot==snapshot.selected_slot:
			shot_tick=snapshot.shots[i].tick;break
	rider.sample(snapshot,standing_blend,aim_yaw,aim_pitch,centers,rider_support_points(),yaws,shot_tick,bridles)
	if not update_camera: return
	var focus:=middle+Vector3.UP*2.65
	var view_basis:=Basis(Vector3.UP,left.rotation.y+aim_yaw)*Basis(Vector3.RIGHT,aim_pitch)
	camera.global_position=focus+view_basis.z*8.0+Vector3.UP*1.8
	camera.look_at(focus-view_basis.z*18.0,Vector3.UP);camera.current=true

func _build_hud() -> void:
	var canvas:=CanvasLayer.new();add_child(canvas)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left=16;panel.offset_right=-16;panel.offset_top=12;canvas.add_child(panel)
	hud=Label.new();hud.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hud.add_theme_font_size_override("font_size",17);panel.add_child(hud)
	var lower:=PanelContainer.new();lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_left=16;lower.offset_right=-16;lower.offset_top=-100;lower.offset_bottom=-12;canvas.add_child(lower)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",17);lower.add_child(status)
	var reticle:=Label.new();reticle.text="+";reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.position=Vector2(-5,-12);reticle.add_theme_font_size_override("font_size",24);canvas.add_child(reticle)

func _refresh() -> void:
	if not is_instance_valid(hud): return
	var snapshot: Dictionary=model.snapshot();var support:=observation()
	var slots: Array[String]=[]
	for i in range(4): slots.append("%s%d %s"%["•" if i==snapshot.selected_slot else "",i+1,"charged" if snapshot.slots[i] else "empty"])
	hud.text="1792 · HORSECRAFT · A REMEMBERED FEAT\nW forward · A/D reins · S brake · Ctrl walk · Shift canter · Q/E balance · Space sit/stand\nMouse aim · Left click fire · 1–4 select matchlock · R reload · Backspace retry · Esc pause · F1 menu"
	status.text=("PAUSED · " if paused else "")+"%s · %.1f m/s · support %.2f m · balance %d%% · %s\n%s\n%s"%[
		model.stance().to_upper(),support.get("mean_speed",0.0),support.get("separation",0.0),int(snapshot.balance*100)," / ".join(slots),snapshot.objective,message]

func _exit_tree() -> void:
	if is_instance_valid(shot_sound):
		shot_sound.stop()
		shot_sound.stream=null
	if release_mouse_on_exit: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
