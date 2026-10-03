# Copyright (c) 2026 Notation Systems Inc. / Notations Gaming.
# All rights reserved.
extends Node
## Focus is an observation presentation on the Home authority's existing clock.
const Rules := preload("res://perception/focus_rules.gd")
const Overlay := preload("res://perception/focus_overlay.gd")
const Audibility := preload("res://perception/focus_audibility.gd")
const Names := preload("res://characters/character_names.gd")
var active := false
var chapter: Node3D
var _tick := -1
var _targets: Dictionary={}
var _sounds: Dictionary={}
var _pending: Dictionary={}
var _acquiring: Array=[]
var _records: Dictionary={}
var _current: Dictionary={}
var _motion: Dictionary={}
var _predictions: Dictionary={}
var _heard: Dictionary={}
var _retained_notice_until := -1
var filter_layer: CanvasLayer
var overlay_layer: CanvasLayer
var overlay: Control
var heading: Label
var _task_hud_was_visible := false

func bind(owner_chapter: Node3D) -> void:
	chapter=owner_chapter
	set_meta("classification","authored-focus-observation")
	set_meta("save_authority",false)
	set_meta("historical_claim",false)
	filter_layer=CanvasLayer.new();filter_layer.layer=3;add_child(filter_layer)
	var filter:=ColorRect.new();filter.mouse_filter=Control.MOUSE_FILTER_IGNORE
	filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material:=ShaderMaterial.new();material.shader=preload("res://perception/focus_filter.gdshader")
	filter.material=material;filter_layer.add_child(filter)
	# Allow an existing higher-layer subjective shader to sample the focused scene.
	var copy:=BackBufferCopy.new();copy.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT;filter_layer.add_child(copy)
	overlay_layer=CanvasLayer.new();overlay_layer.layer=18;add_child(overlay_layer)
	overlay=Overlay.new();overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay_layer.add_child(overlay)
	heading=Label.new();heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	heading.add_theme_font_size_override("font_size",15);heading.add_theme_color_override("font_color",Color("eee2c4"))
	heading.add_theme_color_override("font_shadow_color",Color.BLACK)
	heading.add_theme_constant_override("shadow_offset_x",1);heading.add_theme_constant_override("shadow_offset_y",1)
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overlay.add_child(heading)
	_set_visible()

func register_target(id: String, node: Node3D, label: String, kind: String="contact", offset: Vector3=Vector3.ZERO) -> void:
	if id.is_empty() or not is_instance_valid(node) or not is_instance_valid(chapter) or not chapter.is_ancestor_of(node) or kind not in Rules.KINDS or not offset.is_finite(): return
	_targets[id]={"node":node,"label":label,"kind":kind,"offset":offset}

func register_sound(id: String, source: AudioStreamPlayer3D, label: String) -> void:
	if not id.is_empty() and is_instance_valid(source) and is_instance_valid(chapter) and chapter.is_ancestor_of(source): _sounds[id]={"node":source,"label":label}

func start() -> void:
	if active: return
	_task_hud_was_visible=chapter._hud.visible
	chapter._hud.hide()
	active=true;_pending.clear();_acquiring.clear();_motion.clear();_current.clear();_retained_notice_until=-1;_set_visible()
	_sample_compact_hud()

func stop() -> void:
	if active and is_instance_valid(chapter._hud): chapter._hud.visible=_task_hud_was_visible
	active=false;_pending.clear();_acquiring.clear();_motion.clear();_current.clear();_retained_notice_until=-1;_set_visible()
	_sample_compact_hud()

func clear() -> void:
	stop();_tick=-1;_records.clear();_predictions.clear();_heard.clear();_retained_notice_until=-1;overlay.marks.clear();overlay.queue_redraw()

func _set_visible() -> void:
	filter_layer.visible=active;overlay_layer.visible=active

func _sample_compact_hud() -> void:
	# The optional PoliticalChapter shares the Home sensor interface without the
	# composed art study. Its original HUD remains the presentation authority.
	if not "art" in chapter: return
	if is_instance_valid(chapter) and is_instance_valid(chapter.art) and is_instance_valid(chapter.art.detail) and is_instance_valid(chapter.art.detail.hud):
		chapter.art.detail.hud.sample()

func sample(tick: int) -> void:
	if tick<0 or not is_instance_valid(chapter): return
	if tick<_tick: clear()
	var fresh := tick!=_tick
	var continuous := _tick<0 or tick==_tick+1
	_tick=tick
	for id in _records.keys():
		if tick>=int(_records[id].expires_tick): _records.erase(id);_predictions.erase(id)
	for id in _predictions.keys():
		if tick>=int(_predictions[id].expires_tick): _predictions.erase(id)
	for id in _heard.keys():
		if tick>=int(_heard[id].expires_tick): _heard.erase(id)
	if active and fresh:
		_current.clear();_acquiring.clear()
		if not continuous: _pending.clear();_motion.clear()
		_scan_visual(tick)
		_scan_sound(tick)
	_present()

func _scan_visual(tick: int) -> void:
	for id in _targets.keys():
		var target: Dictionary=_targets[id]
		if not is_instance_valid(target.node):
			_targets.erase(id);_pending.erase(id);_motion.erase(id);continue
		var node: Node3D=target.node
		if not chapter.is_ancestor_of(node):
			_targets.erase(id);_pending.erase(id);_motion.erase(id);continue
		if not node.is_visible_in_tree():
			_pending.erase(id);_motion.erase(id);continue
		var at: Vector3=node.global_position+target.offset
		if not _visible_target(node,at):
			_pending.erase(id);_motion.erase(id);continue
		if not _pending.has(id): _pending[id]=tick
		var observed_ticks:=tick-int(_pending[id])+1
		if observed_ticks<Rules.DWELL_TICKS:
			# Anonymous current evidence: no registration identity, role or label yet.
			_acquiring.append({"position":[at.x,at.y,at.z],"observed_ticks":observed_ticks,
				"required_ticks":Rules.DWELL_TICKS,"sample_tick":tick,
				"observer_id":Names.HERO_ID,"sensor_id":"character-eye"})
			continue
		var record:=Rules.observation(id,String(target.label),String(target.kind),Names.HERO_ID,at,tick)
		var previous: Dictionary=_records.get(id,{})
		if _predictions.has(id) and not previous.is_empty() and int(previous.get("seen_tick",-1))==tick-1:
			if not Rules.supports(_predictions[id],previous,record): _predictions.erase(id)
		_records[id]=record
		_current[id]=true
		# Confirm that the anonymous dwell became bounded evidence without naming
		# another subject in the heading or creating persistent tutorial state.
		if previous.is_empty(): _retained_notice_until=maxi(_retained_notice_until,tick+Rules.RETAINED_NOTICE_TICKS)
		if not _motion.has(id):
			_motion[id]=record.duplicate(true)
			_predictions.erase(id)
		elif tick-int(_motion[id].seen_tick)>=Rules.MOTION_INTERVAL:
			var prediction:=Rules.estimate(_motion[id],record)
			if prediction.is_empty(): _predictions.erase(id)
			else: _predictions[id]=prediction
			_motion[id]=record.duplicate(true)

func _visible_target(node: Node3D, at: Vector3) -> bool:
	# The established chapter supplies its own eye/FOV policy, including optional vision profiles.
	if chapter._seen(at,Rules.RANGE): return true
	var eye: Vector3=chapter._eye_origin() if chapter.has_method("_eye_origin") else chapter.avatar.global_position+Vector3.UP*1.35
	if eye.distance_to(at)>Rules.RANGE: return false
	var ray:=PhysicsRayQueryParameters3D.create(eye,at,1,[chapter.avatar.get_rid(),chapter.horse.get_rid(),chapter.attacker.get_rid()])
	var hit:=chapter.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty(): return false
	var collider: Node=hit.collider
	var own_surface: bool=collider==node or node.is_ancestor_of(collider) or (node.get_parent() is CollisionObject3D and collider==node.get_parent())
	return own_surface and chapter._seen(hit.position+hit.normal*0.015,Rules.RANGE)

func _scan_sound(tick: int) -> void:
	var eye: Vector3=chapter.avatar.global_position+Vector3.UP*1.35
	var forward: Vector3=-chapter.avatar.pivot.global_basis.z
	for id in _sounds.keys():
		if not is_instance_valid(_sounds[id].node): _sounds.erase(id);continue
		var source: AudioStreamPlayer3D=_sounds[id].node
		if not chapter.is_ancestor_of(source): _sounds.erase(id);continue
		if not Audibility.admitted(source): continue
		var offset:=source.global_position-eye
		var reach:=minf(source.max_distance,16.0)
		var ray:=PhysicsRayQueryParameters3D.create(eye,source.global_position,1,[chapter.avatar.get_rid(),chapter.horse.get_rid()])
		var muffled:=not chapter.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		if muffled: reach*=0.5
		if offset.length()>reach or reach<=0: continue
		# Coarse direction only: no concealed person, identity or exact world coordinate.
		_heard[id]={"label":String(_sounds[id].label),"sector":Rules.sound_sector(forward,offset),
			"muffled":muffled,"heard_tick":tick,"expires_tick":tick+Rules.SOUND_TICKS,"sensor_id":"character-hearing"}

func observations() -> Array:
	var result: Array=[]
	for id in _records.keys(): result.append(_records[id].duplicate(true))
	result.sort_custom(func(a,b): return String(a.id)<String(b.id))
	return result

func acquisitions() -> Array:
	return _acquiring.duplicate(true) if active else []

func predictions() -> Dictionary:
	return _predictions.duplicate(true)

func sound_cues() -> Array:
	var result: Array=[]
	for id in _heard: result.append(_heard[id].duplicate(true))
	return result

func _hud_regions() -> Array[Rect2]:
	var regions: Array[Rect2]=[]
	if not "art" in chapter: return regions
	if not is_instance_valid(chapter.art) or not is_instance_valid(chapter.art.detail) or not is_instance_valid(chapter.art.detail.hud): return regions
	var hud=chapter.art.detail.hud
	if not hud.visible: return regions
	for panel in [hud.top,hud.bottom,hud.control_strip]:
		if is_instance_valid(panel) and panel.is_visible_in_tree():
			var rect: Rect2=panel.get_global_rect()
			rect.size=rect.size.max(panel.get_combined_minimum_size())
			regions.append(rect.grow(6))
	return regions

func _screen_point(camera: Camera3D, at: Vector3, size: Vector2) -> Vector2:
	if camera.is_position_behind(at): return Vector2.INF
	var screen:=camera.unproject_position(at)
	if not Rect2(Vector2(12,40),size-Vector2(24,80)).has_point(screen): return Vector2.INF
	for rect in overlay.exclusion_rects:
		if rect.grow(12).has_point(screen): return Vector2.INF
	return screen

func _present() -> void:
	if not active: return
	# Keep the live captions and compact task card; suppress the verbose legacy help.
	chapter._hud.hide()
	var camera: Camera3D=chapter.get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return
	var size: Vector2=chapter.get_viewport().get_visible_rect().size
	# The compact control strip owns keys. Context appears only until the first
	# identification, then yields the space to sensory evidence.
	heading.text="FOCUS"
	if _tick<_retained_notice_until:
		heading.text+="\nObservation retained."
	elif _records.is_empty():
		heading.text+="\nKeep subject visible until the ring fills." if not _acquiring.is_empty() else "\nLook toward a subject."
	for cue in sound_cues():
		var age:=int(ceil(float(_tick-int(cue.heard_tick))/60.0))
		heading.text+="\n~ %s · heard %s · %ds ago%s" % [cue.label,cue.sector,age," · muffled" if cue.muffled else ""]
	var regions:=_hud_regions()
	heading.position=Vector2(maxf(18,size.x-335),18)
	heading.size=Vector2(minf(317,size.x-36),0)
	var proposed:=Rect2(heading.position,heading.size.max(heading.get_combined_minimum_size()))
	for rect in regions:
		if proposed.intersects(rect) and rect.position.y<size.y*0.5:
			heading.position=Vector2(18,rect.end.y+6)
			break
	overlay.exclusion_rects=regions
	overlay.exclusion_rects.append(Rect2(heading.position,heading.size.max(heading.get_combined_minimum_size())).grow(6))
	overlay.marks.clear()
	for record in observations():
		var at:=Rules.position(record)
		var screen:=_screen_point(camera,at,size)
		if not screen.is_finite(): continue
		var age:=_tick-int(record.seen_tick)
		var is_current: bool=age==0 and _current.has(record.id)
		var state:=Rules.observation_state(age,is_current)
		var mark: Dictionary={"at":screen,"color":Rules.colour(record.kind),"alpha":clampf(1.0-float(age)/Rules.MEMORY_TICKS,0.15,1.0),
			"text":"%s %s · %s" % [Rules.symbol(record.kind),record.label,state],
			# Presentation metadata is derived only from current admission. It lets
			# the overlay distinguish live evidence from bounded memory without
			# reading the target again or changing the retained observation.
			"evidence_state":"observed" if is_current else "remembered"}
		if _predictions.has(record.id):
			var end:=Rules.position(_predictions[record.id])
			var origin:=Rules.position({"position":_predictions[record.id].origin_position})
			if not camera.is_position_behind(end) and not camera.is_position_behind(origin):
				mark.prediction=camera.unproject_position(end)
				mark.prediction_origin=camera.unproject_position(origin)
				mark.prediction_text=Rules.estimate_label(_predictions[record.id])
		overlay.marks.append(mark)
	var pending_marks: Array=[]
	for pending in acquisitions():
		var screen:=_screen_point(camera,Rules.position(pending),size)
		if not screen.is_finite(): continue
		pending_marks.append({"at":screen,"color":Color("d4d7cf"),"alpha":0.8,"text":"Observing",
			"progress":float(pending.observed_ticks)/float(pending.required_ticks)})
	# Screen ranking only limits clutter; every admitted subject keeps its dwell.
	pending_marks.sort_custom(func(a,b): return a.at.distance_squared_to(size*0.5)<b.at.distance_squared_to(size*0.5))
	for mark in pending_marks.slice(0,3): overlay.marks.append(mark)
	overlay.queue_redraw()
