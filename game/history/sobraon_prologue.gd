# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Authored playable frame. Its observations never become childhood knowledge.
## Uses the retained-Home visit and original player motor; raft motion is local.
signal family_requested(completed: bool)
const Player := preload("res://player/player.tscn")
const Figure := preload("res://youth/performance/bazaar_figure.gd")
const VERSION := "1792.sobraon-oral-opening.v1"
const SPAWN := Vector3(0,0.04,14)
const RAFT_START := Vector3(1,-0.06,-19)
const WOUNDED := Vector3(3.8,0,2)
const LAMENT := "Today Ranjit Singh has died."
const HANDOFF := "Maha Singh told his son: ‘Before these courtyards were familiar to you…’"

var avatar: CharacterBody3D
var veteran: Node3D
var wounded: Node3D
var raft: CharacterBody3D
var battlefield: Node3D
var surrender: Node3D
var film_camera: Camera3D
var phase := "escape"
var tick := 0
var phase_tick := 0
var helped := false
var escaped := false
var paused := false
var failed := false
var returning := false
var retries := 0
var events: Array[Dictionary] = []
var weapons: Array[Node3D] = []
var soldiers: Array[Node3D] = []
var drop_count := 0
var impact_at := Vector3.ZERO
var impact_tick := -1
var impact_marker: MeshInstance3D
var _bank_seen := false
var _wounded_seen := false
var _materials: Dictionary = {}
var _title: Label
var _task: Label
var _speaker: Label
var _caption: Label
var _controls: Label
var _pause_panel: PanelContainer
var _retry_button: Button
var _curtain: ColorRect
var _fade: Tween
var _boom: AudioStreamPlayer
var _clank: AudioStreamPlayer
var _river: AudioStreamPlayer
var _carry: Node3D

func _ready() -> void:
	_build_light()
	_build_battlefield()
	_build_surrender()
	_build_player()
	_build_interface()
	_build_audio()
	_record("sobraon_begin",{"date":"1846-02-10","bridge":"already_broken","cause":"unresolved"})
	_say("Shah Muhammad","The bridge was gone. Behind them, the guns. Before them, the Sutlej.")
	_refresh()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _material(hex: String) -> StandardMaterial3D:
	if _materials.has(hex): return _materials[hex]
	var m:=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=.94
	_materials[hex]=m;return m

func _box(parent: Node3D,id: String,at: Vector3,size: Vector3,color: String,solid: bool=false) -> Node3D:
	var holder: Node3D=StaticBody3D.new() if solid else Node3D.new()
	holder.name=id;holder.position=at;parent.add_child(holder)
	var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size
	mesh.mesh=shape;mesh.material_override=_material(color);holder.add_child(mesh)
	if solid:
		var c:=CollisionShape3D.new();var s:=BoxShape3D.new();s.size=size;c.shape=s;holder.add_child(c)
	return holder

func _round(parent: Node3D,at: Vector3,size: Vector3,color: String) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new()
	sphere.radius=.5;sphere.height=1;sphere.radial_segments=12;sphere.rings=6
	mesh.mesh=sphere;mesh.position=at;mesh.scale=size;mesh.material_override=_material(color);parent.add_child(mesh)
	return mesh

func _person(parent: Node3D,id: String,at: Vector3,index: int=4) -> Node3D:
	var figure:=Figure.new();figure.name=id;figure.position=at;parent.add_child(figure);figure.build(index)
	figure.round_piece(figure.head,Vector3(.23,.25,.12),Vector3(0,-.04,-.10),Color("68645d"))
	return figure

func _pose(figure: Node3D,action: String,amount: float) -> void:
	var at:=figure.position
	figure.sample(tick,0.0,action,amount,false)
	figure.position=at

func _musket(parent: Node3D,id: String,at: Vector3) -> Node3D:
	var gun:=Node3D.new();gun.name=id;gun.position=at;parent.add_child(gun)
	_box(gun,"Stock",Vector3(0,.25,0),Vector3(.10,.53,.14),"654d35")
	_box(gun,"Barrel",Vector3(0,.94,0),Vector3(.05,.87,.05),"444849")
	_box(gun,"Lock",Vector3(.06,.53,0),Vector3(.07,.08,.10),"b39566")
	return gun

func _build_light() -> void:
	var env:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_SKY
	var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("536b7a");sky_material.sky_horizon_color=Color("b1afa1")
	sky_material.ground_horizon_color=Color("b1afa1");sky_material.ground_bottom_color=Color("716c5b")
	var sky:=Sky.new();sky.sky_material=sky_material;settings.sky=sky
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("bcc4c2");settings.ambient_light_energy=.65
	settings.fog_enabled=true;settings.fog_light_color=Color("a29b86");settings.fog_density=.007
	env.environment=settings;add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-26,-35,0)
	sun.light_color=Color("ede5d0");sun.light_energy=.78;sun.shadow_enabled=true;add_child(sun)

func _build_battlefield() -> void:
	battlefield=Node3D.new();battlefield.name="Sobraon1846";add_child(battlefield)
	_box(battlefield,"NearBank",Vector3(0,-.5,2),Vector3(80,1,44),"776b52",true)
	_box(battlefield,"FarBank",Vector3(0,-.5,-62),Vector3(80,1,36),"8e8160",true)
	# The river has no invisible walkable floor. Falling in requires a retry.
	var water:=_box(battlefield,"Sutlej",Vector3(0,-.34,-32),Vector3(170,.12,24),"536f72")
	water.set_meta("authored_scale",true)
	var river_material:=ShaderMaterial.new();river_material.shader=preload("res://history/sobraon_water.gdshader")
	water.get_child(0).material_override=river_material
	for i in range(25):
		_box(battlefield,"Current%d"%i,Vector3(-65+i*5.6,-.272,-21-(i%6)*3.7),Vector3(3.6,.014,.11),"a2aaa0")
	for side in [-1,1]:
		for i in range(5):
			var x: float=side*(8.0+i*1.7)
			var cover:=_box(battlefield,"Earthwork%d_%d"%[side,i],Vector3(x,.6,12-i*6),Vector3(5,1.2,1.4),"82745a",true)
			cover.rotation.y=side*.16
			for j in range(4):
				_round(cover,Vector3(-1.8+j*1.2,.67,0),Vector3(1.35,.33,.80),"a69470")
	for z in [-17.5,-20.5,-23.5,-39.5,-42.5,-45.5]:
		_box(battlefield,"Pontoon",Vector3(-9,-.13,z),Vector3(5,.65,2.1),"463e32")
		_box(battlefield,"BridgeDeck",Vector3(-9,.28,z),Vector3(2.8,.18,3),"9c835c",true)
		for x in [-10.2,-7.8]: _box(battlefield,"BrokenPost",Vector3(x,.7,z),Vector3(.12,1,.14),"69543c")
	for i in range(8):
		var fragment:=_box(battlefield,"BridgeWreckage",Vector3(-10+(i%3)*1.4,-.03,-25-i*1.7),Vector3(.22,.15,2.6),"7c684d")
		fragment.rotation.y=i*.71
	for spec in [Vector3(-3,-.03,-30),Vector3(5,-.03,-37)]:
		_box(battlefield,"DriftingTimber",spec,Vector3(4,.46,.7),"675a44",true)
	for i in range(11):
		var x: float=-25+i*5.1
		var smoke:=_round(battlefield,Vector3(x,2+(i%3),20+(i%2)*6),Vector3(6,8,5),"6e6e63")
		var haze:=StandardMaterial3D.new();haze.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		haze.albedo_color=Color(.25,.27,.27,.13);haze.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke.material_override=haze;smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Distant riverine vegetation and irregular bank edges are scenic, not surveyed.
	for i in range(20):
		var x: float=-60+i*6
		_box(battlefield,"FarTreeTrunk",Vector3(x,1.4,-65-(i%3)*3),Vector3(.22,2.8,.22),"635f4b")
		_round(battlefield,Vector3(x,3.5,-65-(i%3)*3),Vector3(5,3.4,4),"5d6856")
	for i in range(30):
		var x: float=-37+(i%15)*5.1
		var z: float=-18.5 if i<15 else -45.5
		_round(battlefield,Vector3(x,-.15,z),Vector3(4,.8,2.0),"837b62")
		for j in range(3):
			var reed:=_box(battlefield,"RiverReed",Vector3(x+j*.19,.46,z),Vector3(.035,.9,.035),"747852")
			reed.rotation.z=(j-1)*.15
	for i in range(10):
		var man:=_person(battlefield,"RetreatingSoldier%d"%i,Vector3(-14+(i%4)*9,0,10+(i/4)*4),i%5)
		_pose(man,"brace",.5)
	for i in range(3):
		var cannon:=_box(battlefield,"AbandonedGun",Vector3(-17+i*17,.5,17),Vector3(1.2,.6,2.0),"625037")
		_box(cannon,"Tube",Vector3(0,.5,-.4),Vector3(.34,.34,2.2),"464b47")
		for side in [-1,1]:
			var wheel:=_round(cannon,Vector3(side*.78,-.06,0),Vector3(.20,1.4,1.4),"3b3730")
			wheel.rotation.z=.06
	wounded=_person(battlefield,"WoundedComrade",WOUNDED,0);_pose(wounded,"down",1)
	raft=CharacterBody3D.new();raft.name="FloatingWreckage";raft.position=RAFT_START;battlefield.add_child(raft)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2.3,.20,1.9);collision.shape=shape;raft.add_child(collision)
	for i in range(6): _box(raft,"Plank%d"%i,Vector3(-.95+i*.38,0,0),Vector3(.34,.20,1.9),"826b49")
	for z in [-.6,.6]: _box(raft,"Lashing",Vector3(0,.115,z),Vector3(2.35,.03,.055),"c5b289")
	impact_marker=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=2.55;ring.outer_radius=2.72;ring.rings=32;ring.ring_segments=6
	impact_marker.mesh=ring;impact_marker.material_override=_material("c09358");battlefield.add_child(impact_marker);impact_marker.hide()

func _build_surrender() -> void:
	surrender=Node3D.new();surrender.name="Rawalpindi1849";surrender.position=Vector3(170,0,0);add_child(surrender)
	_box(surrender,"SurrenderGround",Vector3(0,-.5,0),Vector3(65,1,55),"a89776",true)
	for i in range(7):
		var man:=_person(surrender,"KhalsaVeteran%d"%i,Vector3(-4.5+i*1.5,0,-1.4-(i%2)*1.8),i%5)
		man.rotation.y=.1*(i-3);_pose(man,"watch",.3);soldiers.append(man)
		var gun:=_musket(surrender,"SurrenderedMusket%d"%i,man.position+Vector3(.38,.0,-.2));weapons.append(gun)
	for i in range(12):
		var gun:=_musket(surrender,"ArmsPile%d"%i,Vector3(-2+(i%5)*.8,.13+(i/5)*.09,1+(i%3)*.18))
		gun.rotation=Vector3(PI/2,.4*i,.05*i)
	for i in range(2):
		var guard:=_person(surrender,"CompanyGuard%d"%i,Vector3(-8+i*16,0,-4),1)
		guard.rotation.y=PI;_musket(guard,"HeldMusket",Vector3(.4,0,0))
	for i in range(5):
		var tent:=MeshInstance3D.new();var canvas:=PrismMesh.new();canvas.size=Vector3(5,3.2,4.4)
		tent.mesh=canvas;tent.position=Vector3(-16+i*8,1.6,-16);tent.material_override=_material("b5ae98");surrender.add_child(tent)
		_box(surrender,"TentOpening",Vector3(-16+i*8,.84,-13.78),Vector3(.9,1.68,.04),"54564d")
	film_camera=Camera3D.new();film_camera.name="SurrenderCamera";surrender.add_child(film_camera)
	film_camera.position=Vector3(7,3.6,7);film_camera.fov=48
	film_camera.look_at(surrender.position+Vector3(0,1.1,0))
	surrender.hide()

func _build_player() -> void:
	avatar=Player.instantiate();avatar.name="SobraonVeteran";avatar.menu_shortcut=false
	avatar.position=SPAWN;avatar.get_node("HomeIdentity").free();add_child(avatar)
	avatar.get_node("MeshInstance3D").hide()
	avatar.walk_speed=3.4;avatar.run_speed=5.8
	avatar.get_node("CameraPivot/SpringArm3D").spring_length=4.4
	avatar.get_node("CameraPivot/SpringArm3D/Camera3D").fov=61
	veteran=_person(avatar,"VeteranFigure",Vector3.ZERO,4)
	_box(veteran,"RecognizableSleeveRepair",Vector3(-.31,1.08,-.08),Vector3(.13,.18,.08),"c6ad7c")
	_musket(veteran,"CarriedMusket",Vector3(.28,.18,.20)).rotation.z=-.18
	_carry=_person(avatar,"CarriedComrade",Vector3(.10,.84,.44),0)
	_carry.rotation=Vector3(PI/2,0,PI/2);_carry.scale=Vector3.ONE*.85;_carry.hide()

func _build_interface() -> void:
	var canvas:=CanvasLayer.new();canvas.name="PrologueInterface";add_child(canvas)
	var top:=VBoxContainer.new();top.position=Vector2(40,28);top.size=Vector2(1150,120);canvas.add_child(top)
	_title=Label.new();_title.add_theme_font_size_override("font_size",29);top.add_child(_title)
	_task=Label.new();_task.add_theme_font_size_override("font_size",21);_task.add_theme_color_override("font_color",Color("ead4a4"));top.add_child(_task)
	var panel:=PanelContainer.new();panel.name="Narration"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=40;panel.offset_right=-40;panel.offset_top=-170;panel.offset_bottom=-24
	var style:=StyleBoxFlat.new();style.bg_color=Color(.035,.047,.05,.90)
	style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=13;style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style);canvas.add_child(panel)
	var rows:=VBoxContainer.new();rows.add_theme_constant_override("separation",7);panel.add_child(rows)
	_speaker=Label.new();_speaker.add_theme_font_size_override("font_size",17);_speaker.add_theme_color_override("font_color",Color("d8b878"));rows.add_child(_speaker)
	_caption=Label.new();_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size",23);_caption.size_flags_vertical=Control.SIZE_EXPAND_FILL;rows.add_child(_caption)
	_controls=Label.new();_controls.add_theme_font_size_override("font_size",16);rows.add_child(_controls)
	_pause_panel=PanelContainer.new();_pause_panel.position=Vector2(430,190);_pause_panel.size=Vector2(420,270)
	_pause_panel.add_theme_stylebox_override("panel",style);canvas.add_child(_pause_panel)
	var options:=VBoxContainer.new();options.add_theme_constant_override("separation",12);_pause_panel.add_child(options)
	var title:=Label.new();title.text="The telling waits";title.add_theme_font_size_override("font_size",25);options.add_child(title)
	for spec in [["Resume",_toggle_pause],["Retry escape",retry],["Continue to family story · F2",skip_to_family]]:
		var button:=Button.new();button.text=spec[0];button.custom_minimum_size.y=46;button.pressed.connect(spec[1]);options.add_child(button)
		if spec[0]=="Retry escape": _retry_button=button
	_pause_panel.hide()
	_curtain=ColorRect.new();_curtain.color=Color(0,0,0,1);_curtain.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(_curtain)
	_fade=create_tween();_fade.tween_property(_curtain,"color:a",0.0,.7)

func _wave(kind: String) -> AudioStreamWAV:
	var sample:=AudioStreamWAV.new();sample.format=AudioStreamWAV.FORMAT_16_BITS;sample.mix_rate=22050
	var duration:=2.0 if kind=="river" else .65
	var count:=int(duration*22050);var data:=PackedByteArray();data.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=18460210
	for i in range(count):
		var t:=float(i)/22050.0;var noise:=rng.randf_range(-1,1)
		var value: float
		if kind=="river": value=.10*noise+.025*sin(t*TAU*71)
		elif kind=="clank": value=(sin(t*TAU*780)+.4*sin(t*TAU*1370)+noise*.3)*exp(-t*10)*.3
		else: value=(noise*.45+sin(t*TAU*43)*.5)*exp(-t*6)*.7
		data.encode_s16(i*2,int(clampf(value,-1,1)*32760))
	sample.data=data
	if kind=="river": sample.loop_mode=AudioStreamWAV.LOOP_FORWARD;sample.loop_end=count
	return sample

func _build_audio() -> void:
	_boom=AudioStreamPlayer.new();_boom.stream=_wave("boom");_boom.volume_db=-10;add_child(_boom)
	_clank=AudioStreamPlayer.new();_clank.stream=_wave("clank");_clank.volume_db=-7;add_child(_clank)
	_river=AudioStreamPlayer.new();_river.stream=_wave("river");_river.volume_db=-17;add_child(_river);_river.play()

func _record(id: String,details: Dictionary={}) -> void:
	events.append({"id":id,"tick":tick,"phase":phase,"details":details.duplicate(true)})

func _say(speaker: String,words: String) -> void:
	_speaker.text=speaker;_caption.text=words
	_record("caption",{"speaker":speaker,"text":words,"authorship":"reported_lament" if words==LAMENT else "original_dramatic_dialogue"})

func _set_phase(next: String) -> void:
	phase=next;phase_tick=tick;_record("phase",{"phase":phase});_refresh()

func observation() -> Dictionary:
	return {"schema":VERSION,"phase":phase,"tick":tick,"helped_comrade":helped,"escaped":escaped,
		"retries":retries,"weapons_laid_down":drop_count,"narrator":_speaker.text,
		"caption":_caption.text,"events":events.duplicate(true),"historical_bridge_cause":"unresolved",
		"veteran_identity":"fictional_composite_sobraon_survivor","campaign_mutation":false,
		"narration_delivery":"captions; no recorded voice performance"}

func can_complete() -> bool:
	return phase=="handoff" and escaped and drop_count==weapons.size()

func reject_return(message: String) -> void:
	returning=false;_curtain.color.a=0;_say("",message)

func _input(event: InputEvent) -> void:
	if returning or not event is InputEventKey or not event.pressed or event.echo: return
	var code: int=event.keycode if event.keycode!=0 else event.physical_keycode
	match code:
		KEY_ESCAPE: _toggle_pause()
		KEY_F2: skip_to_family()
		KEY_R:
			if failed: retry()
		KEY_E:
			if not paused and not failed: interact()
		_: return
	get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if returning or failed: return
	paused=not paused;_pause_panel.visible=paused
	avatar.set_physics_process(not paused and phase in ["escape","escaped","surrender"])
	avatar.input_enabled=not paused and phase in ["escape","escaped","surrender"]
	for sound in [_boom,_clank,_river]: sound.stream_paused=paused
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func skip_to_family() -> void:
	if returning: return
	_record("explicit_skip_to_family");returning=true
	family_requested.emit(false)

func interact() -> void:
	if returning or paused or failed: return
	match phase:
		"escape":
			if not helped and avatar.position.distance_to(WOUNDED)<2.4:
				helped=true;wounded.hide();_carry.show();avatar.external_speed_limit=2.3
				_record("helped_comrade");_say("Wounded soldier","My arm. Take my arm. I can hold on.")
			elif avatar.position.distance_to(RAFT_START)<3.0:
				avatar.velocity=Vector3.ZERO;avatar.input_enabled=false;avatar.set_physics_process(false)
				impact_tick=-1;impact_marker.hide()
				_set_phase("crossing");_say("Shah Muhammad","Some found timber in the broken crossing. They held to it, and to one another.")
		"escaped":
			if tick-phase_tick>=90: _enter_surrender()
		"surrender":
			if avatar.position.distance_to(surrender.position+Vector3(0,0,3))<3.0:
				avatar.velocity=Vector3.ZERO;avatar.input_enabled=false;avatar.set_physics_process(false)
				film_camera.make_current();_set_phase("weapons")
				_say("Shah Muhammad","Three years had passed since Sobraon. Here, they were ordered to lay down their arms.")
		"lament":
			if tick-phase_tick>=120:
				_set_phase("remembering");_say("Shah Muhammad","Ranjit Singh. Maha Singh's son. And Maha Singh was the son of Charat Singh. Listen to what a father once told his child.")
		"remembering":
			if tick-phase_tick>=60:
				_set_phase("handoff");_say("Shah Muhammad",HANDOFF)
		"handoff":
			if tick-phase_tick>=90 and can_complete():
				returning=true;_record("oral_handoff",{"from":"shah_muhammad","to":"mahan_singh","subject":"charat_singh"})
				_fade=create_tween();_fade.tween_property(_curtain,"color:a",1.0,.55)
				_fade.tween_callback(func(): family_requested.emit(true))
	_refresh()

func _enter_surrender() -> void:
	battlefield.hide();battlefield.process_mode=Node.PROCESS_MODE_DISABLED;surrender.show()
	avatar.position=surrender.position+Vector3(0,.04,9);avatar.velocity=Vector3.ZERO
	avatar.pivot.rotation=Vector3(-.16,0,0);avatar.external_speed_limit=2.0
	avatar.input_enabled=true;avatar.set_physics_process(true);_carry.hide();_river.stop()
	_set_phase("surrender");_record("time_cut",{"from":"1846-02-10","to":"1849-03-14","place":"near Rawalpindi"})
	_say("Shah Muhammad","He survived the river. Now he stood among the men who had carried their arms through another war.")

func retry() -> void:
	if returning or phase not in ["escape","crossing"]: return
	retries+=1;failed=false;paused=false;_pause_panel.hide();impact_tick=-1;impact_marker.hide()
	avatar.position=Vector3(1,.04,-16.4) if _bank_seen else SPAWN
	avatar.velocity=Vector3.ZERO;avatar.input_enabled=true;avatar.set_physics_process(true)
	raft.position=RAFT_START;avatar.pivot.rotation=Vector3(-.20,0,0)
	for sound in [_boom,_clank,_river]: sound.stream_paused=false
	_set_phase("escape");_record("retry",{"checkpoint":"riverbank" if _bank_seen else "earthworks"})
	_say("Shah Muhammad","The river was still ahead. There was wreckage at the bank.")
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _fail(reason: String) -> void:
	failed=true;avatar.input_enabled=false;avatar.set_physics_process(false)
	_record("failed_attempt",{"reason":reason});_say("",reason+"  Press R to retry.");_refresh()

func _physics_process(_delta: float) -> void:
	if paused or failed or returning: return
	tick+=1
	if phase=="escape":
		if avatar.position.y < -1.8: _fail("Swept away.");return
		if avatar.position.z<5 and not _wounded_seen:
			_wounded_seen=true;_say("Wounded soldier","Brother! Here, by the gun!")
		if avatar.position.z < -13 and not _bank_seen:
			_bank_seen=true;_record("riverbank_reached")
			_say("Shah Muhammad","The boats had parted. Men shouted of treachery; others could only see the river.")
		# Telegraph an impact using a past position; movement can avoid it.
		if tick%540==360 and avatar.position.z> -13:
			impact_at=avatar.position;impact_at.y=.025;impact_tick=tick+120
			impact_marker.position=impact_at;impact_marker.show();_record("incoming",{"at":[impact_at.x,impact_at.z]})
		if impact_tick==tick:
			_boom.play();impact_marker.hide();impact_tick=-1
			if Vector2(avatar.position.x-impact_at.x,avatar.position.z-impact_at.z).length()<2.55:
				_fail("The blast caught you.");return
	elif phase=="crossing":
		var stick:=Input.get_vector("move_left","move_right","move_forward","move_backward")
		var speed:=1.8 if helped else 2.3
		raft.velocity=Vector3(stick.x*speed+.12,0,stick.y*speed)
		raft.move_and_collide(raft.velocity*_delta)
		raft.position.x=clampf(raft.position.x,-6,10);raft.position.z=minf(raft.position.z,-18.9)
		avatar.position=raft.position+Vector3(0,.13,0)
		if raft.position.z<=-43:
			avatar.position=Vector3(raft.position.x,.04,-45);avatar.input_enabled=true;avatar.set_physics_process(true)
			escaped=true;_record("far_bank_reached",{"helped_comrade":helped})
			_set_phase("escaped");_say("Shah Muhammad","He reached the other bank. The river carried away the sound of the guns.")
	elif phase=="weapons":
		var age:=tick-phase_tick
		for i in range(weapons.size()):
			var start:=90+i*44
			if age>=start and age<=start+35:
				var amount:=clampf(float(age-start)/35,0,1)
				weapons[i].rotation.x=lerpf(0,PI/2,amount)
				weapons[i].position.y=sin(amount*PI)*.13+.09*amount
				_pose(soldiers[i],"checked",amount)
				soldiers[i].shoulders[1].rotation.x=lerpf(-.9,0,amount)
			if age==start+35:
				_clank.play();drop_count+=1;_record("weapon_laid_down",{"soldier":i})
				_pose(soldiers[i],"idle",1.0);soldiers[i].head.rotation.x=.25
		if drop_count==weapons.size() and age>=450:
			_set_phase("lament");_say("An old Khalsa veteran",LAMENT)
	if phase in ["escape","escaped","surrender"]:
		var moving:=Vector2(avatar.velocity.x,avatar.velocity.z).length()>.15
		_pose(veteran,"brace" if moving else "watch",.45)
		if moving:
			veteran.rotation.y=atan2(-avatar.velocity.x,-avatar.velocity.z)
			for i in range(2): veteran.hips[i].rotation.x=sin(tick*.15+i*PI)*.38
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_title): return
	_retry_button.disabled=phase not in ["escape","crossing"]
	_title.text="SOBRAON  ·  10 FEBRUARY 1846" if phase in ["escape","crossing","escaped"] else "NEAR RAWALPINDI  ·  14 MARCH 1849"
	_controls.text="WASD move · Mouse look · Shift run · Esc pause"
	match phase:
		"escape":
			_task.text="Reach the riverbank beyond the broken bridge"
			if not helped and avatar.position.distance_to(WOUNDED)<2.4: _task.text="E · Help the wounded soldier"
			elif avatar.position.distance_to(RAFT_START)<3: _task.text="E · Take hold of the floating wreckage"
			if impact_tick>tick: _task.text="Incoming shot · Leave the marked ground"
		"crossing":
			_task.text="Reach the far bank · Steer between the timbers"
			_controls.text="W forward · S back · A / D steer · Mouse look · Esc pause"
		"escaped": _task.text="You reached the far bank · E to follow the telling"
		"surrender": _task.text="Walk to the waiting soldiers · E to witness the surrender"
		"weapons": _task.text="The laying down of arms"
		"lament": _task.text="E · Listen"
		"remembering": _task.text="E · Follow the story to Charat Singh"
		"handoff": _task.text="E · A father's telling"
	if phase in ["weapons","lament","remembering","handoff"]: _controls.text="E continue · Esc pause"
	if failed: _task.text="R · Retry escape     F2 · Continue to family story"

func _exit_tree() -> void:
	if _fade!=null and _fade.is_valid(): _fade.kill()
	for sound in [_boom,_clank,_river]:
		if is_instance_valid(sound): sound.stop();sound.stream=null
