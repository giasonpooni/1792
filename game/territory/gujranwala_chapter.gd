extends "res://childhood/home_chapter.gd"
## Same home-entry controller, extended only after the existing household inquiry.
const Territory := preload("res://territory/gujranwala_state.gd")
const Rules := preload("res://territory/misl_rules.gd")
const Cell := preload("res://territory/home_cell.gd")
const DeliveryPresentation := preload("res://territory/delivery_presentation.gd")
const GuardRecruitment := preload("res://territory/guard_recruitment.gd")
var cell: Node3D
var merchant: CharacterBody3D
var _economy_action := ""
var _economy_choices: Array[String] = []
var _delivery_load: Node3D
var _carrier_load: MeshInstance3D
var _carrier_status := ""
var _carrier_cue_tick := -720
var _guard_posts: Array[Node3D]=[]
var _works: Dictionary={}
var _budget_notice := false

func _init() -> void:
	model=Territory.new()
	save_path=Territory.TERRITORY_SAVE

func _build_world() -> void:
	super._build_world()
	cell=Cell.new()
	cell.name="GujranwalaCell"
	add_child(cell)
	cell.build()
	merchant=EscortAgent.new()
	merchant.entity_id=Rules.CARAVAN_ID
	merchant.move_speed=2.4
	merchant.name="HomeCaravan"
	add_child(merchant)
	merchant.caption.text="Return carrier"
	merchant.apply(Rules.blank_merchant())
	merchant.add_collision_exception_with(avatar)
	merchant.add_collision_exception_with(horse)
	# Cosmetic pack cargo; the physical agent remains a single bounded capsule.
	var pack:=MeshInstance3D.new()
	var pack_mesh:=BoxMesh.new()
	pack_mesh.size=Vector3(0.6,0.7,0.6)
	pack.mesh=pack_mesh
	pack.position=Vector3(0,1,0.4)
	var pack_cloth := StandardMaterial3D.new()
	pack_cloth.albedo_color = Color("a1865e")
	pack_cloth.roughness = 1.0
	pack.material_override = pack_cloth
	_carrier_load = pack
	merchant.add_child(pack)
	_delivery_load = DeliveryPresentation.make_cargo()
	avatar.add_child(_delivery_load)
	for i in range(3):
		var p:=_box(Vector3(0.5,1.7,0.5),Vector3(-2+i*2,0.95,10.5),Color("566777"))
		_guard_posts.append(p.get_parent())
	_works.palisade=_box(Vector3(16,1,0.35),Vector3(0,3.25,11.8),Color("75563a")).get_parent()
	_works.storehouse=_box(Vector3(3,1.5,4),Vector3(-25,2.85,2),Color("b19d73")).get_parent()
	_works.mill=_box(Vector3(1.5,1.8,1.5),Vector3(-24,1.1,-3),Color("927953")).get_parent()
	_sync_economy()

func _ready() -> void:
	super._ready()
	get_parent().get_node("Sun").light_energy=0.72
	var sky: WorldEnvironment=get_parent().get_node("WorldEnvironment")
	sky.environment=sky.environment.duplicate(true)
	sky.environment.ambient_light_energy=0.4
	_navigation.bind(get_world_3d(),[avatar.get_rid(),horse.get_rid(),attacker.get_rid(),escort.get_rid(),merchant.get_rid()])
	_navigation.built=false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_B:
		_open_accounts()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.mounted():
		if Model.distance(model.position(),Rules.QUARTERMASTER)<3:
			if _seen(Rules.QUARTERMASTER+Vector3.UP,4):
				_open_quartermaster()
			else: _message="Face the quartermaster before speaking."
			return
		if Model.distance(model.position(),Rules.MARKET)<3:
			if _seen(Rules.MARKET+Vector3.UP,4): _open_market()
			else: _message="Face the market trader before speaking."
			return
	super._interact()

func _menu_action(action: String) -> void:
	if action.begins_with("econ:"):
		if _paused and action in _economy_choices and _economy_action.is_empty():
			_economy_action=action.trim_prefix("econ:")
		return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_economy_action=""
	_economy_choices.clear()

func _resume() -> void:
	_economy_choices.clear()
	_economy_action = ""
	super._resume()

func _economy_contact(site: Vector3) -> bool:
	return not model.mounted() and avatar.is_on_floor() and avatar.global_position.distance_to(model.position()) <= 0.25 and model.position().distance_to(site) <= 3.0 and _seen(site + Vector3.UP, 4.0)

func _remember_economy_choices(actions: Array) -> void:
	_economy_choices.clear()
	for spec in actions:
		if str(spec[1]).begins_with("econ:"): _economy_choices.append(str(spec[1]))

func _physics_process(delta: float) -> void:
	if not _economy_action.is_empty():
		var queued := _economy_action
		var parts:=queued.split("|",true,1)
		_economy_action=""
		var kind: String=parts[0]
		var arg: String=parts[1] if parts.size()>1 else ""
		var error: String
		var place: Vector3 = Rules.MARKET if kind in ["buy", "satchel", "deliver", "accept_escort"] else Rules.QUARTERMASTER
		if not _paused or "econ:" + queued not in _economy_choices or not _economy_contact(place):
			error = "Return to the speaker and face them before settling this account."
		elif kind=="guard_terms":
			var expected:=GuardRecruitment.next_candidate(model.economy().events)
			if expected.is_empty() or expected.id!=arg:
				_message="Those individual terms are no longer available."
				_resume()
			else: _open_guard_terms(arg)
			return
		elif kind=="begin": error=model.begin_allowance()
		elif kind=="rest": error=model.rest_watch()
		else: error=model.operate(kind,arg)
		_message=error if not error.is_empty() else DeliveryPresentation.acknowledgment(kind, arg, model)
		_sync_economy(true)
		_resume()
		return
	if model.has_economy() and model.economy().events.size()>=Rules.MAX_EVENTS and not _budget_notice:
		_budget_notice=true
		_show_dialog("END OF BOUNDED SUPPLY TEST","The 256-receipt budget is full. Save this run or start again; the economy is not an unbounded campaign.",
			[["Save","save"],["Main menu","menu"]])
		return
	super._physics_process(delta)
	if _paused or not model.has_economy(): return
	var m: Dictionary=model.economy()
	if m.ledger.caravan=="active":
		var moving: bool=Model.distance(model.position(),merchant.global_position)<=9 and Model.distance(merchant.global_position,Rules.QUARTERMASTER)>2.2
		var waypoint: Vector3=_navigation.waypoint(merchant.global_position,Rules.QUARTERMASTER) if moving else merchant.global_position
		# Reuse the physical agent with an explicit lower speed, not a changed clock.
		var motion: Dictionary=merchant.step(delta,waypoint,moving)
		var error: String=model.record_merchant(motion,delta)
		if not error.is_empty():
			merchant.apply(m.merchant)
			_message=error
	_sync_economy()
	_sample_carrier_story()
	_refresh()

func _sync_economy(reset: bool=false) -> void:
	if not is_instance_valid(merchant): return
	var enabled: bool=model.has_economy()
	horse.gait_speed_limit=3.0 if enabled and model.economy().ledger.feed_shortfall>0 else Riding.MAX_SPEED
	merchant.visible=enabled and model.economy().ledger.caravan in ["active","complete"]
	merchant.collision_layer=2 if merchant.visible else 0
	if is_instance_valid(_carrier_load):
		_carrier_load.position = Vector3(0.8, 0.35, 0.4) if enabled and model.economy().ledger.caravan == "complete" else Vector3(0, 1, 0.4)
	for i in range(_guard_posts.size()):
		_guard_posts[i].visible=enabled and model.economy().ledger.guards>i
	for name in _works: _works[name].visible=enabled and name in model.economy().ledger.built
	if reset:
		merchant.apply(model.economy().merchant if enabled else Rules.blank_merchant())
		_carrier_status = DeliveryPresentation.carrier_phase(model)
		_carrier_cue_tick = int(model.progress().tick)
	if is_instance_valid(_delivery_load):
		_delivery_load.visible = enabled and model.economy().ledger.cargo == 4
		_delivery_load.rotation.y = horse.rotation.y if model.mounted() else avatar.pivot.rotation.y
		_delivery_load.position.y = 1.0 if model.mounted() else 0.0

func _sample_carrier_story() -> void:
	var next := DeliveryPresentation.carrier_phase(model)
	if next == _carrier_status: return
	var line := DeliveryPresentation.carrier_transition(_carrier_status, next)
	# A nearby carrier speaks only when visible. The separation cue is Buddh's
	# own decision to turn back, never remote dialogue or a completion receipt.
	if next in ["together", "arrived"] and not _seen(merchant.global_position + Vector3.UP, 10.0): return
	var tick: int = int(model.progress().tick)
	if not line.is_empty() and tick - _carrier_cue_tick < 180: return
	_carrier_status = next
	if not line.is_empty():
		_message = line
		_carrier_cue_tick = tick

func _apply() -> void:
	super._apply()
	_sync_economy(true)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(cell) or not is_instance_valid(_hud): return
	if model.aftermath_phase()=="complete":
		var title: String="GUJRANWALA · HOME TERRITORY"
		var message: String="Speak to the quartermaster [E] for your first household allowance. B: supplies."
		if model.has_economy():
			var m: Dictionary=model.economy()
			var s: Dictionary=m.ledger
			var seconds: int=maxi(0,(int(m.origin_tick)+(s.watch+1)*Rules.WATCH_TICKS-int(model.progress().tick))/60)
			message="Purse %d | Coffers %d | Food %d | Fodder %d | Watch %d (%ds to upkeep)\n%s\n%s" % [s.purse,s.treasury,s.stock.food,s.stock.feed,s.watch,seconds,
				"Stay with the caravan; return to the quartermaster." if s.caravan=="active" else "Deliver the supplies to the market." if s.delivery=="outbound" else "E: trade / orders at a speaker · B: oral accounts",s.last_notice]
		_hud.text="1792 · BUDDH SINGH · "+title+"\n\n"+message+"\n\nWASD / Mouse · F horse · E speak · B accounts · F5/F9 save/load · J journal"
		_marker.visible=false

func _account_text() -> String:
	if not model.has_economy(): return "The allowance begins only after the household inquiry. These accounts are spoken by the quartermaster; readable UI does not give Buddh literacy."
	var s: Dictionary=model.economy().ledger
	var need:=Rules.due(s)
	return "QUARTERMASTER'S ORAL ACCOUNT · Authored game quantities\n\nPersonal purse: %d coins\nHousehold coffers: %d coins (separate; no private withdrawal)\n\nStores %d/%d: food %d · fodder %d · grain %d · timber %d · tools %d\n\nPeople: %d workers, %d garrison guards. One existing household horse.\nEach 120-second supply watch: %d food + %d fodder + %d wages.\nArrears: %d · Last food shortfall: %d · Last feed shortfall: %d\n\n%s\n\n%s\nHousehold standing: %d · Meeting: %s (available watch 2; due before 5)\nProject: %s · Work remaining: %d\nCompleted: %s\n\n%s\n\nSimulation watch is deliberately compressed, NOT a real historical day. Farm/mill recipes, prices and capacities are balancing fixtures. The caravan's route has no hostile encounter yet." % [
		s.purse,s.treasury,Rules.stored(s),Rules.capacity(s),s.stock.food,s.stock.feed,s.stock.grain,s.stock.timber,s.stock.tools,
		s.workers,s.guards,need.food,need.feed,need.wages,s.arrears,s.food_shortfall,s.feed_shortfall,
		Rules.readiness(s),GuardRecruitment.active_summary(model.economy().events),s.favor,s.meeting,s.build if s.build!="" else "none",s.work_left,", ".join(s.built),s.last_notice]

func _open_guard_terms(id: String) -> void:
	var spec:=GuardRecruitment.candidate(id)
	if spec.is_empty():
		_message="No individual guard terms are available."
		_resume()
		return
	var actions: Array=[["Enter %s alone for household guard service · 22 now" % spec.name,"econ:hire|"+id],["Not yet","resume"]]
	_show_dialog("ONE PERSON · ONE PLACE",GuardRecruitment.terms(id),actions)
	_remember_economy_choices(actions)

func _open_accounts() -> void:
	_show_dialog("SUPPLIES AND OBLIGATIONS",_account_text(),[["Return","resume"]])

func _open_quartermaster() -> void:
	var actions: Array=[]
	if not model.has_economy():
		actions.append(["Accept the limited household allowance","econ:begin"])
	else:
		var s: Dictionary=model.economy().ledger
		if s.delivery=="available": actions.append(["Carry four food portions to the market · purse +12 / coffers +26","econ:accept_delivery"])
		if s.caravan=="active": actions.append(["Check the physically arrived caravan in · receive food and fodder","econ:checkin"])
		var prospect:=GuardRecruitment.next_candidate(model.economy().events)
		if prospect.is_empty(): actions.append(["Hire a garrison guard · 22 now / 2 wages + 1 food each watch","econ:hire|guard"])
		else: actions.append(["Hear %s's individual guard terms" % prospect.name,"econ:guard_terms|"+prospect.id])
		actions.append_array([
			["Hire a worker · 12 now / 1 wage + 1 food each watch","econ:hire|worker"],
			["Release one guard (no refund)","econ:release_guard"],
			["Build palisade · 36 coins / 6 timber / 1 tool / 6 work","econ:build|palisade"],
			["Build storehouse · 20 coins / 4 timber / 1 tool / 4 work","econ:build|storehouse"],
			["Build mill · 28 coins / 4 timber / 1 tool / 4 work","econ:build|mill"],
			["Attend the household meeting · watch 2 to 4","econ:meeting"],
			["Pay accrued wages","econ:pay_arrears"],["Contribute 10 personal coins to coffers","econ:contribute"],
			["Rest until next supply watch (unavailable during escort)","econ:rest"]])
	actions.append(["Return","resume"])
	_show_dialog("QUARTERMASTER · GUJRANWALA",DeliveryPresentation.briefing(model) + "\n\n" + _brief_text(),actions)
	_remember_economy_choices(actions)

func _open_market() -> void:
	if not model.has_economy():
		_show_dialog("MARKET", "Trader · Hear your quartermaster before making commitments.",[["Return","resume"]])
		return
	var s: Dictionary=model.economy().ledger
	var actions: Array=[]
	if s.delivery=="outbound": actions.append(["Deliver the four carried portions","econ:deliver"])
	if s.caravan=="available": actions.append(["Escort a return caravan to the home store","econ:accept_escort"])
	for key in Rules.PRICES:
		var lot: Dictionary=Rules.PRICES[key]
		actions.append(["Buy %d %s for %d household coins" % [lot.quantity,key,lot.cost],"econ:buy|"+key])
	actions.append(["Buy a supply satchel · 12 personal coins / delivery premium +4","econ:satchel"])
	actions.append(["Return","resume"])
	_show_dialog("MARKET · LOCAL SUPPLY",DeliveryPresentation.briefing(model, true) + "\n\n" + _brief_text(),actions)
	_remember_economy_choices(actions)

func _candidate_error(staged: Story) -> String:
	var error:=super._candidate_error(staged)
	if not error.is_empty(): return error
	if staged is Territory and staged.has_economy() and not _navigation.fits(staged.economy().merchant):
		return "Saved caravan position is obstructed. Session unchanged."
	return ""

func _load(path: String="") -> void:
	var staged:=Territory.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message="Chapter, coffers, supplies and caravan restored together." if error.is_empty() else error
	_clear_pending_actions()
	_resume()

func _brief_text() -> String:
	if not model.has_economy(): return "Food, fodder and wages are settled every 120 seconds of play."
	var s: Dictionary=model.economy().ledger
	return "Purse %d · Coffers %d · Stores %d/%d\nFood %d · Fodder %d · B: full oral accounts." % [
		s.purse,s.treasury,Rules.stored(s),Rules.capacity(s),s.stock.food,s.stock.feed]
