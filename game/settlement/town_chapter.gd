extends "res://remounts/remount_chapter.gd"
## The same home chapter, now with connected districts. No simultaneous second world.
const Town := preload("res://settlement/town_state.gd")
const TownWorld := preload("res://settlement/town_world.gd")
const Layout := preload("res://settlement/town_layout.gd")
var town: Node3D
var _district_was_open := false
var _town_import_requested := false

func _init() -> void:
	model=Town.new()
	save_path=Town.TOWN_SAVE

func _build_boundaries() -> void:
	# Deferred to the neighbourhood builder so its two gate colliders can follow chapter state.
	pass

func _build_world() -> void:
	super._build_world()
	town=TownWorld.new();add_child(town);town.build()
	# Inherited far scenery is a disposable visual projection. Hide pieces whose centres
	# now lie in the extended playable districts; keep original core terrain/props/collision.
	for n in cell.get_children():
		if n is Node3D and not n is StaticBody3D:
			var p: Vector3=n.position
			if Layout.valid_position([p.x,0,p.z]) and (p.x< -30 or p.z< -30): n.hide()
	# The parent fabric's distant house silhouettes are visual-only. Suppress
	# only pieces now inside the expanded playable space; keep original core dressing.
	for n in fabric.get_children():
		if n is MeshInstance3D:
			var p: Vector3=n.position
			if Layout.valid_position([p.x,0,p.z]) and (p.x< -30 or p.z< -30): n.hide()
	_sync_town()

func _ready() -> void:
	super._ready()
	_navigation.built=false
	var environment: WorldEnvironment=get_parent().get_node("WorldEnvironment")
	environment.environment.background_color=Color("bdc3b4")
	get_parent().get_node("Sun").light_color=Color("ffedce")

func _sync_town() -> void:
	if not is_instance_valid(town): return
	var opened: bool=model.district_open()
	town.set_open(opened)
	if opened!=_district_was_open: _navigation.built=false
	_district_was_open=opened

func _physics_process(delta: float) -> void:
	if _town_import_requested:
		_town_import_requested=false
		_load(RemountState.REMOUNT_SAVE)
		return
	super._physics_process(delta)
	_sync_town()

func _apply() -> void:
	super._apply()
	_sync_town()

func _interact() -> void:
	if model.district_open():
		for id in Layout.SITES:
			var site: Dictionary=Layout.SITES[id]
			if Model.distance(model.position(),site.point)>3.2: continue
			if model.mounted(): _message="Dismount to examine the place.";return
			if not _seen(site.point+Vector3.UP*1.15,4.5):
				_message="Face the place from an unobstructed position before examining it.";return
			var error: String=model.observe_landmark(id)
			_message=error if not error.is_empty() else "Remembered: "+site.title+". J opens your observations."
			_show_dialog(site.title.to_upper(),site.description+"\n\nRECONSTRUCTION CLASS "+site["class"]+" · Local authored placement. Not an exact historical town plan.",[["Return","resume"]])
			return
	super._interact()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		var notes: String=fabric.inspection_text().replace("Playable 56 m test cell;", "Retained 56 m mission core within the 86 × 108 m town;")
		_show_dialog("GUJRANWALA · RECONSTRUCTION NOTES",notes,[["Return","resume"]])
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_M:
		_open_places();get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func _open_places() -> void:
	var text: String="MY REMEMBERED PLACES\n\nOnly examined places appear here. This is a readable record of experience, not a document Buddh has learned to read.\n\n"
	for v in model.settlement().visits:
		text+="• "+Layout.SITES[v.id].title+"\n"
	if model.settlement().visits.is_empty(): text+="No town landmarks examined yet.\n"
	text+="\n"+("The west and north gates are open. Walk or ride out of the household precinct; look for the open square and workshops." if model.district_open() else "Complete the lesson, return-path encounter and household inquiry before the town gates open.")
	text+="\n\nNew neighbourhood: 86 × 108 local metres, including the retained home cell. A compressed reconstruction, not all of Gujranwala."
	_show_dialog("GUJRANWALA · PLACES",text,[["Return","resume"],["Import prior remounts save","town_import"]])

func _menu_action(action: String) -> void:
	if action=="town_import":
		_town_import_requested=true;return
	super._menu_action(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(town) or not is_instance_valid(_hud): return
	if model.district_open(): _hud.text+="\nTown gates open · M remembered places · %d/%d examined"%[model.settlement().visits.size(),Layout.SITES.size()]

func _load(path: String="") -> void:
	var staged:=Town.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Whole chapter, supplies, investigation and remembered places restored." if error.is_empty() else error
	_clear_pending_actions();_resume()

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_town_import_requested=false
