# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node
## Authored staging on existing receipts/clock. No body movement, damage, rewards or save authority.
const Figure := preload("res://youth/performance/bazaar_figure.gd")
const Dialogue :=  preload("res://youth/performance/bazaar_script.gd")
const Sound := preload("res://youth/performance/bazaar_sound.gd")
const MarketStage := preload("res://youth/performance/bazaar_market_stage.gd")
const Ambience := preload("res://youth/performance/bazaar_ambience.gd")
const Rules := preload("res://youth/brawl_rules.gd")
const Choreo := preload("res://youth/performance/bazaar_choreography.gd")
const Decompression := preload("res://youth/performance/bazaar_decompression.gd")
const Departure := preload("res://youth/performance/bazaar_departure.gd")
const InhabitedApproach := preload("res://youth/performance/bazaar_inhabited_approach.gd")
const WalkLines := preload("res://youth/performance/bazaar_walk_lines.gd")
const Attention := preload("res://youth/performance/bazaar_attention.gd")
const FaceScore := preload("res://youth/performance/bazaar_expression.gd")
var chapter: Node3D
var figures: Array[Node3D]=[]
var sounds: Array[AudioStreamPlayer3D]=[]
var market_stage: Node3D
var ambience: AudioStreamPlayer3D
var departure: Node3D
var inhabited_approach: Node3D
var walk_seen: Dictionary={}
var walk_pending: Dictionary={}
var decompression: Dictionary={}
var enabled := true
var sound_enabled := true
var last_tick := -1
var event_cursor := 0
var origin := -1
var queue: Array=[]
var speech: Dictionary={}
var played: Array=[]
var heard: Array=[]
var _guard := false
var _hero_restore: Dictionary={}
var canvas: CanvasLayer
var top: PanelContainer
var bottom: PanelContainer
var title: Label
var objective: Label
var prompt: Label
var speaker: Label
var subtitle: Label
var _streams: Dictionary={}
var active := false
var report_until := -1
func build(owner_chapter: Node3D) -> void:
	chapter=owner_chapter
	market_stage=MarketStage.new();chapter.add_child(market_stage);market_stage.build()
	departure=Departure.new();chapter.add_child(departure);departure.build()
	inhabited_approach=InhabitedApproach.new();chapter.add_child(inhabited_approach);inhabited_approach.build()
	ambience=AudioStreamPlayer3D.new();ambience.name="OriginalBazaarAmbience";ambience.stream=Ambience.make();ambience.volume_db=-22
	ambience.max_distance=18;ambience.unit_size=5;ambience.position=preload("res://youth/brawl_rules.gd").RING+Vector3(0,1,0);chapter.add_child(ambience)
	for i in range(5):
		var figure:=Figure.new();figure.name="BazaarCharacterStudy";chapter.youths[i].add_child(figure);figure.build(i);figures.append(figure)
		var sound:=AudioStreamPlayer3D.new();sound.name="OriginalBazaarFoley";sound.max_distance=9;sound.unit_size=2;sound.volume_db=-12
		chapter.youths[i].add_child(sound);sounds.append(sound)
	for kind in ["cloth","check","impact"]: _streams[kind]=Sound.make(kind)
	canvas=CanvasLayer.new();canvas.layer=17;add_child(canvas)
	top=panel();var v:=VBoxContainer.new();v.add_theme_constant_override("separation",7);top.add_child(v)
	title=label(12,Color("cabc94"));v.add_child(title)
	objective=label(21,Color("f0e8d5"));v.add_child(objective)
	prompt=label(14,Color("ddd0b0"));v.add_child(prompt)
	bottom=panel();v=VBoxContainer.new();v.add_theme_constant_override("separation",5);bottom.add_child(v)
	speaker=label(12,Color("d3b983"));v.add_child(speaker)
	subtitle=label(18,Color("fff5dd"));v.add_child(subtitle)
	rehydrate()
func panel() -> PanelContainer:
	var p:=PanelContainer.new();p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new();style.bg_color=Color(.055,.05,.04,.91);style.border_color=Color("877951");style.border_width_left=3;style.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel",style);canvas.add_child(p);return p
func label(size: int,color: Color) -> Label:
	var l:=Label.new();l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func rehydrate() -> void:
	if not is_instance_valid(chapter): return
	queue.clear();speech.clear();walk_seen.clear();walk_pending.clear();decompression.clear();report_until=-1;last_tick=int(chapter.model.progress().tick)
	var b: Dictionary=chapter.model.brawl();origin=int(b.get("origin_tick",-1));event_cursor=b.get("events",[]).size()
	_guard=false
	for sound in sounds: sound.stop()
	if is_instance_valid(ambience):
		ambience.stop()
	sample(false)
func audible(index: int,reach: float=7.0) -> bool:
	if index<0 or index>=chapter.youths.size(): return false
	var body: CharacterBody3D=chapter.youths[index]
	if not body.is_visible_in_tree() or body.global_position.distance_to(chapter.avatar.global_position)>reach: return false
	return chapter._contact(body)
func in_view(index: int) -> bool:
	if not audible(index,4.8): return false
	var camera:=chapter.get_viewport().get_camera_3d()
	if camera==null: return false
	var p: Vector3=chapter.youths[index].global_position+Vector3.UP*1.3
	return not camera.is_position_behind(p) and chapter.get_viewport().get_visible_rect().has_point(camera.unproject_position(p))
func play(kind: String,index: int,tick: int) -> void:
	if not sound_enabled or not audible(index): return
	sounds[index].stream=_streams[kind];sounds[index].play()
	played.append({"kind":kind,"actor":index,"tick":tick})
	if played.size()>96: played.pop_front()
func receive(event: Dictionary,ledger: Dictionary) -> void:
	var kind: String=event.kind
	if kind in ["challenge","stand","leave","regroup","report"]:
		queue.clear();speech.clear();walk_pending.clear()
	var lines: Array=Dialogue.lines(kind,ledger.outcome)
	for line_index in range(lines.size()):
		var line: Array=lines[line_index]
		queue.append({"actor":line[0],"text":line[1],"expires":int(event.tick)+780,
			"performance_beat":"%s:%s:%d"%[kind,ledger.outcome,line_index]})
	if kind in ["parry","hit","counter"]: play("check" if kind=="parry" else "impact",int(event.index),int(event.tick))
	if kind=="report": report_until=int(event.tick)+480
func sample(allow_edges: bool=true) -> void:
	if not is_instance_valid(canvas) or not is_instance_valid(chapter.art): return
	var tick:=int(chapter.model.progress().tick)
	var b: Dictionary=chapter.model.brawl();var phase: String=chapter.model.brawl_phase()
	if tick<last_tick or (not b.is_empty() and ((origin>=0 and origin!=int(b.origin_tick)) or event_cursor>b.events.size())):
		queue.clear();speech.clear();event_cursor=b.get("events",[]).size();origin=int(b.get("origin_tick",-1));report_until=-1
	var fresh: bool=tick!=last_tick
	if fresh and not chapter._paused: _guard=Input.is_key_pressed(KEY_Q)
	if not b.is_empty():
		if allow_edges and not chapter._paused and enabled:
			for i in range(event_cursor,b.events.size()): receive(b.events[i],b.ledger)
			event_cursor=b.events.size();origin=int(b.origin_tick)
		elif not enabled: event_cursor=b.events.size()
	active=enabled and phase not in ["none","reported","caught"]
	var contact_beat: Dictionary=Choreo.contact_pose(b.get("events",[]),tick) if not b.is_empty() else {}
	decompression.clear()
	if not b.is_empty() and phase=="returning":
		var regroup_tick:=Decompression.latest_regroup(b.events)
		decompression=Decompression.beat(String(b.ledger.outcome),tick-regroup_tick)
	if is_instance_valid(departure): departure.sample(tick,phase in ["leaving","returning"])
	if is_instance_valid(inhabited_approach): inhabited_approach.sample(tick,phase)
	if is_instance_valid(market_stage): market_stage.sample(tick,active,contact_beat)
	if is_instance_valid(ambience):
		var near_market: bool=chapter.avatar.global_position.distance_to(preload("res://youth/brawl_rules.gd").RING)<15
		if sound_enabled and near_market and not chapter._paused:
			if not ambience.playing: ambience.play()
		elif ambience.playing: ambience.stop()
	for i in range(figures.size()):
		var shown: bool=enabled and chapter.youths[i].visible
		figures[i].visible=shown;chapter.youth_rigs[i].visible=not enabled
		# Remove floating attack labels; visible body motion and local HUD now carry the tell.
		if active: chapter.youths[i].caption.hide()
		if not shown: continue
		var action:="idle";var amount:=0.0
		if i>=3 and not b.is_empty():
			var friend: Dictionary=Choreo.friend_pose(b.get("events",[]),tick,i)
			if not friend.is_empty(): action=friend.action;amount=friend.amount
			elif not decompression.is_empty():
				var mood: String=String(decompression.mela if i==3 else decompression.jiva)
				action={"energized":"urge","checking":"watch","restless":"watch","relieved":"brace","questioning":"watch","easy":"idle"}.get(mood,"idle")
				amount=float(decompression.amount)
		if i<3 and not b.is_empty():
			var cycle:=Rules.attack_phase(tick,int(b.ledger.start_tick),i)
			if b.ledger.down[i]: action="down";amount=1.0
			elif phase=="fighting":
				if b.ledger.stun_until[i]>=tick: action="checked"
				elif cycle in range(80,100): action="windup";amount=float(cycle-80)/20
				elif cycle in range(100,110): action="strike";amount=float(cycle-100)/10
				elif cycle in range(110,140): action="recover";amount=float(cycle-110)/30
				if fresh and cycle==80 and allow_edges and not chapter._paused and in_view(i): play("cloth",i,tick)
			if phase in ["challenged","fighting"] and not b.ledger.down[i] and audible(i,8):
				var d: Vector3=chapter.avatar.global_position-chapter.youths[i].global_position;figures[i].rotation.y=atan2(-d.x,-d.z)-chapter.youths[i].rotation.y
			else: figures[i].rotation.y=0
		figures[i].sample(tick,Vector2(chapter.youths[i].velocity.x,chapter.youths[i].velocity.z).length(),action,amount,speech.get("actor",-1)==i)

	if chapter._paused or not enabled:
		for sound in sounds: sound.stop()
		if is_instance_valid(ambience): ambience.stop()
	if not chapter._paused and allow_edges:
		if phase=="invited" and audible(3,7.0) and audible(4,7.0) and walk_pending.is_empty():
			var zone: Dictionary=WalkLines.available(chapter.avatar.global_position,phase,walk_seen)
			if not zone.is_empty():
				# Do not mark an ambient observation seen merely because higher-priority
				# story dialogue was already occupying the subtitle channel.
				walk_pending={"zone":zone,"entered":tick,"expires":tick+540}
		if phase!="invited": walk_pending.clear()
		if not speech.is_empty() and (tick>=speech.until or not audible(int(speech.actor))): speech.clear()
		if phase=="invited" and not walk_pending.is_empty():
			var center: Vector3=walk_pending.zone.center
			var still_relevant: bool=chapter.avatar.global_position.distance_to(center)<=float(walk_pending.zone.radius)+4.0
			if tick>int(walk_pending.expires) or not still_relevant:
				walk_pending.clear()
			elif speech.is_empty() and queue.is_empty():
				for line in walk_pending.zone.lines:
					queue.append({"actor":line[0],"text":line[1],"expires":tick+420,"duration":120,"ambient_zone":walk_pending.zone.id})
				walk_seen[walk_pending.zone.id]=tick
				walk_pending.clear()
		while speech.is_empty() and not queue.is_empty():
			var candidate: Dictionary=queue.pop_front()
			if tick>candidate.expires or not audible(int(candidate.actor)): continue
			candidate.started=tick;candidate.until=tick+int(candidate.get("duration",210));speech=candidate
			heard.append({"actor":candidate.actor,"tick":tick,"text":candidate.text})
			if heard.size()>32: heard.pop_front()
	_perform_faces(b,phase,tick)
	_pose_hero(b,tick)
	layout(phase,b,tick)
	# The retained courtyard HUD samples its labels during costume retargeting.
	# Apply this encounter presentation after that, never mutate collider/source identity.
	if active:
		chapter.guard_visual.hide() # Unarmed encounter: hands, not the earlier training-shield proxy.
		for actor in chapter.youths: actor.caption.hide()
	last_tick=tick
func gaze_clear(observer: Vector3,target: Variant,reach: float=7.5) -> bool:
	if not (target is Vector3) or observer.distance_to(target)>reach: return false
	# Geometry check is visual admission only. It writes no perception receipt.
	var query:=PhysicsRayQueryParameters3D.create(observer,target,1,[chapter.avatar.get_rid(),chapter.horse.get_rid()])
	return chapter.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _perform_faces(b: Dictionary,phase: String,tick: int) -> void:
	var line: Dictionary=FaceScore.delivery(speech,tick)
	for i in range(figures.size()):
		var figure: Node3D=figures[i]
		if not figure.visible: continue
		# Measure eye-line from the neutral head joint, not the character's feet or
		# yesterday's gaze. Repeated render sampling cannot feed its result back in.
		var frame: Transform3D=figure.torso.global_transform*Transform3D(Basis.IDENTITY,figure.head.position)
		var target: Variant=Attention.figure_target(i,phase,speech,chapter.youths,chapter.avatar.global_position,b) if active else null
		var clear:=gaze_clear(frame.origin,target)
		var gaze:=Attention.angles(frame,target) if clear else Vector2.ZERO
		figure.apply_attention(gaze.x,gaze.y,Attention.eyes(gaze),Attention.blink(tick,i+1))
		var down: bool=i<3 and not b.is_empty() and b.ledger.down[i]
		var outcome:=String(b.get("ledger",{}).get("outcome",""))
		var name:=FaceScore.choose(i,phase,outcome,down,figure.pose_name,speech)
		if not active: name="neutral"
		var emphasis: float=line.nod if line.speaker==i and clear else 0.0
		# Stillness has a job: the speaker gets one restrained emphasis, the listener
		# a held response. These are acting directions, not simulated psychology.
		figure.apply_expression(name,.85 if active else 0.0,emphasis)

func _pose_hero(b: Dictionary,tick: int) -> void:
	var phase: String=chapter.model.brawl_phase()
	var target: Variant=Attention.hero_target(phase,speech,chapter.youths,b,chapter.avatar.global_position) if active else null
	var fighting: bool=active and not b.is_empty() and b.ledger.phase=="fighting"
	if not fighting and not (target is Vector3) and _hero_restore.is_empty(): return
	var proxy: Node3D=chapter.art._hero_proxy
	if not is_instance_valid(proxy): return
	var rig: Skeleton3D=proxy.skeleton
	if not _hero_restore.is_empty():
		for id in _hero_restore:
			var restore_bone:=rig.find_bone(id)
			if restore_bone>=0: rig.set_bone_pose_rotation(restore_bone,_hero_restore[id])
		_hero_restore.clear()
	proxy.sample_tick(tick)
	var rotations: Dictionary={}
	if fighting and _guard:
		rotations={"upper_armL":Vector3(-1.4,0,-.22),"forearmL":Vector3(-1.05,0,0),"upper_armR":Vector3(-1.0,0,.20),"forearmR":Vector3(-1.2,0,0)}
	if fighting:
		for event in b.events:
			var elapsed:=tick-int(event.tick)
			if elapsed<0 or elapsed>20: continue
			if event.kind=="counter": rotations={"upper_armR":Vector3(-1.4,.2,0),"forearmR":Vector3(-.05,0,0),"spine":Vector3(0,.30*sin(PI*float(elapsed)/20),0)}
			elif event.kind=="hit": rotations["spine"]=Vector3(-.17*sin(PI*float(elapsed)/20),0,0)
	var head_bone:=rig.find_bone("head")
	if head_bone>=0 and target is Vector3:
		var frame: Transform3D=rig.global_transform*rig.get_bone_global_pose(head_bone)
		if gaze_clear(frame.origin,target):
			var hero_gaze:=Attention.angles(frame,target)
			rotations["head"]=Vector3(hero_gaze.y,hero_gaze.x,0)
	for id in rotations:
		var bone:=rig.find_bone(id)
		if bone<0: continue
		_hero_restore[id]=rig.get_bone_pose_rotation(bone)
		rig.set_bone_pose_rotation(bone,_hero_restore[id]*Quaternion.from_euler(rotations[id]) if id=="head" else Quaternion.from_euler(rotations[id]))
	if is_instance_valid(chapter.art.detail): chapter.art.detail.sample(tick)

func layout(phase: String,b: Dictionary,tick: int) -> void:
	var ending: bool=enabled and phase=="reported" and tick<report_until
	canvas.visible=(active or ending) and not chapter._paused
	if not canvas.visible: return
	chapter._hud.hide();chapter._caption.hide();chapter._narrator_label.hide()
	var size:=chapter.get_viewport().get_visible_rect().size
	top.position=Vector2(18,18);top.size=Vector2(minf(390,size.x-36),0)
	title.text="GUJRANWALA  /  A SHORT WALK" if not ending else "ALL THREE HOME"
	objective.text={"invited":"Walk with Mela and Jiva","challenged":"Your answer. Your way home.","fighting":"Hold your ground—or leave together","leaving":"Bring both friends home","returning":"Tell the quartermaster what happened","reported":"A story to tell. Not a reward to collect."}.get(phase,"")
	prompt.text="E  Speak     J  Journal     F5 / F9  Save / Load\nF6  Sound: %s"%("on" if sound_enabled else "off")
	if phase=="fighting":
		var tell:="Q  Guard a faced blow   ·   Left click  Counter"
		for i in range(3):
			if not in_view(i) or not chapter._facing(chapter.youths[i].global_position) or b.ledger.down[i]: continue
			if b.ledger.stun_until[i]>=tick: tell="BLOW CHECKED  ·  Counter now [left click]";break
			if Rules.attack_phase(tick,int(b.ledger.start_tick),i) in range(80,106): tell="STRIKE COMING  ·  Face him and hold Q";break
		prompt.text=tell+"\nUnguarded blows: %d / 3  ·  F6 sound %s"%[b.ledger.hits,"on" if sound_enabled else "off"]
	bottom.visible=ending or not speech.is_empty() or not decompression.is_empty()
	if ending: speaker.text="QUARTERMASTER";subtitle.text=Dialogue.REPORT[b.ledger.outcome].trim_prefix("Quartermaster · ")
	elif not speech.is_empty(): speaker.text="MELA" if speech.actor==3 else "JIVA";subtitle.text=speech.text
	elif not decompression.is_empty(): speaker.text="THE WALK HOME";subtitle.text=String(decompression.caption)
	bottom.size=Vector2(minf(740,size.x-36),0)
	bottom.position=Vector2((size.x-bottom.size.x)*.5,size.y-bottom.get_combined_minimum_size().y-20)
func toggle_sound() -> void:
	sound_enabled=not sound_enabled
	for sound in sounds: sound.stop()
	if is_instance_valid(ambience): ambience.stop()
	sample(false)
