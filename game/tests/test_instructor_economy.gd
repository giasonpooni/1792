# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared domain fixtures qualify money/custody/replay. Native journey coverage
## is separate; these poses and an explicit skill proof are not relabelled play.
const State:=preload("res://commissions/commission_state.gd")
const C:=preload("res://commissions/commission_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Craft:=preload("res://workshops/workshop_rules.gd")
const Remounts:=preload("res://remounts/remount_rules.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const SAVE:="user://instructor-economy-isolated.json"
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("INSTRUCTOR ECONOMY: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func refuse(model,fn: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not str(fn.call()).is_empty(),label+" refused")
	check(Supply._equal(model.snapshot(),before),label+" atomic")
func near(model,at: Vector3) -> void: ok(Pose.pose(model,at),"explicit domain pose")
func fresh():
	var model:=State.new()
	ok(model.restore(Fixture.complete()),"explicit inquiry fixture migration")
	ok(model.begin_allowance(),"existing allowance")
	return model
func income(model) -> void:
	near(model,C.HOME);ok(model.operate("accept_delivery"),"take existing income contract")
	near(model,C.BROKER);ok(model.operate("deliver"),"settle existing income contract")
	near(model,C.HOME)
func recruit(model,offer: String="standard") -> void:
	ok(model.commission_action("reserve",offer),"reserve authored contract")
	near(model,C.BROKER);ok(model.commission_action("broker"),"broker introduction fee")
	near(model,C.RECEPTION);ok(model.commission_action("engage"),"accept candidate travel terms")
	var arrived: Dictionary=model.snapshot()
	arrived.commission_actor.position=Base.coords(C.HOME+Vector3.RIGHT)
	ok(model.restore(arrived),"explicit arrived specialist fixture")
	near(model,C.HOME);ok(model.commission_action("appoint"),"sign physical appointment fixture")
func funds_and_debt() -> void:
	var model=fresh()
	refuse(model,model.commission_action.bind("reserve","senior"),"unfunded senior offer")
	refuse(model,model.commission_action.bind("reserve","allard"),"unknown childhood appointment")
	ok(model.commission_action("reserve","standard"),"reserve 108 once")
	check(model.economy().ledger.treasury==12 and model.commission().escrow==108 and model.economy().ledger.purse==18,"one treasury reservation and separate personal purse")
	refuse(model,model.commission_action.bind("reserve","standard"),"duplicate reservation")
	refuse(model,model.operate.bind("commission.cancel"),"generic API cannot inject a commission receipt")
	refuse(model,model.commission_action.bind("lesson_finish"),"player cannot finish drill")
	refuse(model,model.commission_action.bind("broker"),"remote broker fee")
	ok(model.commission_action("cancel"),"unspent cancellation")
	check(model.economy().ledger.treasury==120 and model.commission().escrow==0,"full unused reservation refund")
	refuse(model,model.commission_action.bind("cancel"),"duplicate refund")
	model=fresh();ok(model.commission_action("reserve","standard"),"second reservation fixture")
	near(model,C.BROKER);ok(model.commission_action("broker"),"earned introduction fee")
	refuse(model,model.commission_action.bind("broker"),"double introduction fee")
	near(model,C.HOME);ok(model.commission_action("cancel"),"cancel before travel")
	check(model.economy().ledger.treasury==112 and model.commission().spent==8,"earned broker fee remains spent")
	model=fresh();recruit(model)
	check(model.commission().escrow==24 and model.commission().spent==84 and model.economy().ledger.treasury==12,"appointment partitions exact funds")
	refuse(model,model.commission_action.bind("cancel"),"accepted travel cannot be cancelled as unused")
	var purse: int=model.economy().ledger.purse
	ok(model.rest_watch(),"first original upkeep watch")
	check(model.commission().escrow==12 and model.commission().arrears==0,"first wage comes from reserve")
	ok(model.rest_watch(),"second original upkeep watch")
	check(model.commission().escrow==0,"second reserve wage spent once")
	ok(model.rest_watch(),"third original upkeep watch")
	check(model.commission().arrears==3 and model.economy().ledger.treasury==0,"base worker paid before uncovered specialist wage")
	check(not C.ready(model.economy().ledger) and model.economy().ledger.purse==purse,"debt suspends training without private purse withdrawal")
	refuse(model,model.commission_action.bind("lesson_start"),"unpaid drill")
	ok(model.commission_action("dismiss"),"dismiss present instructor")
	check(model.commission().arrears==3,"dismissal retains earned debt")
	ok(model.operate("contribute"),"explicit personal contribution")
	ok(model.commission_action("pay_arrears"),"settle dismissed claim")
	check(model.commission().arrears==0 and model.economy().ledger.purse==8,"only explicit contribution spends personal money")
	refuse(model,model.commission_action.bind("pay_arrears"),"duplicate debt payment")
	model=fresh();income(model);ok(model.operate("contribute"),"fund senior difference")
	recruit(model,"senior")
	check(model.commission().escrow==40 and model.commission().spent==116 and model.economy().ledger.treasury==0,"senior exact fee partition")
	var estimate:=C.budget(model.economy().ledger)
	check(estimate.reserved==40 and estimate.next_wages==21 and estimate.next_unreserved_wages==1,"next watch distinguishes reserve from spendable funds")
	ok(model.commission_action("release_reserve"),"release unused wage reserve")
	check(model.economy().ledger.treasury==40 and model.commission().escrow==0,"released reserve creates no money")
	refuse(model,model.commission_action.bind("release_reserve"),"duplicate reserve release")
	ok(model.validate(model.snapshot()),"all fee and debt receipts replay")

func viewpoint_and_motion() -> void:
	var model=fresh();recruit(model)
	var principal: Vector3=model.position()
	var treasury: int=model.economy().ledger.treasury
	ok(model.commission_action("control",C.SPECIALIST),"limited instructor viewpoint")
	check(model.position()==principal and model.economy().ledger.treasury==treasury,"viewpoint switch moves no body and grants no money")
	check(model.journal().is_empty(),"instructor does not inherit Buddh's private memories")
	for action in [model.operate.bind("buy","food"),model.mount,model.begin_brawl,model.begin_service,model.begin_water_round,model.begin_remounts,model.workshop_action.bind("reserve"),model.oral_operation.bind("hear","quartermaster_account"),model.gate_action.bind("request",true),model.training_access]:
		refuse(model,action,"limited viewpoint authorizes only its own body and drill")
	var motion: Dictionary=model.specialist();motion.position=Base.coords(Base.point(motion.position)+Vector3(.04,0,0));motion.velocity=[2.4,0,0]
	ok(model.record_specialist(motion,1.0/60.0,true),"bounded specialist body motion")
	refuse(model,model.record_specialist.bind(motion,1.0/60.0,true),"duplicate same tick specialist movement")
	model.advance();motion=model.specialist();motion.position[0]+=30
	refuse(model,model.record_specialist.bind(motion,1.0/60.0,true),"specialist teleport")
	motion=model.specialist();motion.practice=1
	refuse(model,model.record_specialist.bind(motion,1.0/60.0,true),"motion cannot award drill credit")
	near(model,C.HOME+Vector3(0,0,12))
	refuse(model,model.commission_action.bind("control",C.HERO),"role return requires both separate bodies at home")
	near(model,C.HOME);ok(model.commission_action("control",C.HERO),"return principal control")
	check(model.journal().size()>0 and model.position()==principal,"principal journal and position retained")
	model.advance();motion=model.specialist();motion.position[0]+=.02
	refuse(model,model.record_specialist.bind(motion,1.0/60.0,true),"appointed unattended instructor cannot follow")
	ok(model.validate(model.snapshot()),"separate-body role history validates")

func active_custody() -> void:
	for contract in ["commission","workshop","remount","delivery"]:
		var model=fresh()
		match contract:
			"commission": ok(model.commission_action("reserve","standard"),"commission custody fixture")
			"workshop": ok(model.workshop_action("reserve"),"workshop custody fixture")
			"remount": ok(model.begin_remounts(),"remount custody fixture")
			"delivery": ok(model.operate("accept_delivery"),"delivery custody fixture")
		if contract=="commission":
			for action in [model.begin_remounts,model.workshop_action.bind("reserve"),model.begin_brawl,model.begin_service,model.begin_water_round,model.mount,model.rest_watch,model.operate.bind("accept_delivery"),model.training_access]: refuse(model,action,"commission excludes another commitment")
		else:
			refuse(model,model.commission_action.bind("reserve","standard"),contract+" excludes commission")
		ok(model.validate(model.snapshot()),contract+" single custody validates")

func drill_attendance() -> void:
	var model=fresh();income(model);recruit(model)
	ok(model.operate("hire","guard"),"hire actual drill pupil")
	ok(model.rest_watch(),"pay and feed guard through original watch")
	check(model.economy().ledger.duty_guards==1,"provisioned guard attendance available")
	var food: int=model.economy().ledger.stock.food
	var tools: int=model.economy().ledger.stock.tools
	ok(model.commission_action("lesson_start"),"fund drill from existing stock")
	check(model.economy().ledger.stock.food==food-2 and model.economy().ledger.stock.tools==tools-1,"drill consumes exactly two portions and one tool")
	for action in [model.commission_action.bind("lesson_start"),model.begin_brawl,model.begin_service,model.begin_water_round,model.begin_remounts,model.workshop_action.bind("reserve"),model.operate.bind("accept_delivery"),model.commission_action.bind("control",C.SPECIALIST),model.operate.bind("release_guard"),model.mount,model.rest_watch,model.training_access]: refuse(model,action,"funded drill reservation")
	model.progress_drill(true)
	check(model.specialist().practice==0,"same admission tick is not practice")
	model.advance();model.progress_drill(false)
	check(model.specialist().practice==0,"lost contact earns no practice")
	model.progress_drill(true);model.progress_drill(true)
	check(model.specialist().practice==1,"one eligible practice increment per common tick")
	near(model,C.HOME+Vector3(0,0,10));model.advance();model.progress_drill(true)
	check(model.specialist().practice==1,"principal absence suspends practice")
	near(model,C.HOME)
	ok(model.save_to(SAVE),"save partial funded drill")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load partial funded drill")
	check(Supply._equal(model.snapshot(),loaded.snapshot()),"whole-world partial drill roundtrip")
	for i in range(179): loaded.advance();loaded.progress_drill(true)
	check(loaded.commission().lesson=="complete" and loaded.specialist().practice==180,"180 actual eligible ticks finish once")
	var complete: Dictionary=loaded.snapshot()
	loaded.advance();loaded.progress_drill(true)
	check(loaded.specialist().practice==180 and loaded.economy().events.size()==complete.misl.events.size(),"completed drill cannot duplicate resources or receipt")
	ok(loaded.validate(loaded.snapshot()),"executed drill receipts replay")
	# Pure reducer fixture: admission reserves both portions, so no third portion
	# is demanded for work already funded. A failed subsequent watch still halts it.
	var ledger:=Supply.initial();ledger.guards=1;ledger.duty_guards=1
	var text:=instruction("standard",C.HOME,C.RECEPTION,0)
	ok(C.apply(ledger,"commission.reserve",text),"pure minimum-food reservation")
	ok(C.apply(ledger,"commission.broker",instruction("",C.BROKER,C.RECEPTION,0)),"pure broker")
	ok(C.apply(ledger,"commission.engage",instruction("",C.RECEPTION,C.RECEPTION,0)),"pure engagement")
	ok(C.apply(ledger,"commission.appoint",instruction("",C.HOME,C.HOME,0)),"pure appointment")
	ledger.stock.food=2
	ok(C.apply(ledger,"commission.lesson_start",instruction("",C.HOME,C.HOME,1)),"pure exact two-portion drill")
	check(ledger.stock.food==0 and C.ready(ledger),"allocated drill food remains sufficient")
	C.upkeep(ledger);check(not C.ready(ledger),"failed next feeding interrupts allocated drill")
	# An active instructor can relinquish its viewpoint without releasing the
	# paid lesson. Principal control remains the route to settle interruption.
	model=fresh();income(model);recruit(model)
	ok(model.operate("hire","guard"),"role repair pupil")
	ok(model.rest_watch(),"role repair supplies")
	ok(model.commission_action("control",C.SPECIALIST),"role repair limited control")
	ok(model.commission_action("lesson_start"),"instructor starts paid drill")
	model.advance();model.progress_drill(true)
	var commitment: Dictionary=model.commission()
	var allocation: Dictionary=model.economy().ledger.stock.duplicate(true)
	ok(model.commission_action("control",C.HERO),"active instructor may return financial authority")
	check(model.commission().lesson=="active" and model.commission().guard_slot==commitment.guard_slot and model.specialist().practice==1,"role return retains pupil and earned practice")
	check(model.economy().ledger.stock==allocation,"role return consumes and refunds nothing")
	refuse(model,model.commission_action.bind("control",C.SPECIALIST),"principal cannot leave active drill obligations again")
	ok(model.validate(model.snapshot()),"active role-return receipt replay")

func instruction(option: String,at: Vector3,other: Vector3,tick: int) -> String:
	return JSON.stringify({"schema":C.VERSION,"actor":C.HERO,"at":Base.coords(at),"companion":Base.coords(other),"option":option,"tick":tick,"practice":0})

func mixed_replay_and_restore() -> void:
	var model=fresh()
	ok(model.oral_operation("hear","quartermaster_account"),"retain actually heard oral account fixture")
	ok(model.begin_remounts(),"retain remount inquiry")
	near(model,Remounts.NOTE);ok(model.remount_action("note"),"retained sealed tally fixture")
	near(model,Remounts.HITCH);ok(model.remount_action("horses"),"retained horse observation fixture")
	near(model,C.HOME);ok(model.remount_action("resolve"),"settled remount account")
	ok(model.workshop_action("reserve"),"existing smith contract")
	near(model,Craft.SITE);ok(model.workshop_action("start"),"smith owns work and fuel")
	near(model,C.HOME);recruit(model)
	var oral: Dictionary=model.snapshot().oral_memory
	var remount: Dictionary=model.remounts()
	for i in range(Craft.WORK_TICKS): model.advance()
	check(model.workshop_phase()=="ready" and model.commission().phase=="appointed","smith automatic completion survives instructor receipt composition")
	check(model.snapshot().oral_memory==oral and model.remounts()==remount,"unrelated source receipts stay retained")
	ok(model.begin_service(),"idle service record with funded instructor")
	ok(model.begin_water_round(),"idle water record with funded instructor")
	ok(model.save_to(SAVE),"save mixed Home authority")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load mixed Home authority")
	check(Supply._equal(model.snapshot(),loaded.snapshot()),"oral remount workshop service water instructor roundtrip")
	var retained: Dictionary=model.snapshot()
	for fault in ["escrow","actor","tick","phase","extra","practice","control","velocity","oral","smith"]:
		var broken:=retained.duplicate(true)
		match fault:
			"escrow": broken.misl.ledger.commission.escrow+=1
			"actor": broken.commission_actor.id="jean_francois_allard"
			"tick":
				for event in broken.misl.events:
					if event.kind=="commission.reserve":
						var d: Dictionary=JSON.parse_string(event.arg);d.tick+=1;event.arg=JSON.stringify(d);break
			"phase": broken.misl.ledger.commission.phase="cancelled"
			"extra": broken.commission_actor.extra=1
			"practice": broken.commission_actor.practice=180
			"control": broken.misl.ledger.commission.controlled="sada_kaur"
			"velocity": broken.commission_actor.velocity=[100,0,0]
			"oral": broken.oral_memory.content_digest="0".repeat(64)
			"smith": broken.misl.ledger.workshop.fee_paid+=1
		refuse(model,model.restore.bind(broken),"mixed tampered "+fault)
	near(model,Craft.SITE);ok(model.workshop_action("collect"),"idle instructor allows free principal to carry smith tools")
	refuse(model,model.commission_action.bind("control",C.SPECIALIST),"tool load blocks viewpoint change")
	ok(model.validate(model.snapshot()),"idle commissioned specialist with workshop cargo validates")
	ok(model.restore(Fixture.complete()),"earlier whole-world rewind")
	check(not model.commissioned() and not model.has_remounts() and not model.has_oral_memory() and not model.has_economy(),"earlier snapshot removes all future optional receipts")
	# A smith deadline on an upkeep boundary must follow original watch, including
	# instructor upkeep, without replacing or duplicating either reducer.
	model=fresh();recruit(model)
	ok(model.workshop_action("reserve"),"boundary smith reservation")
	for i in range(Supply.WATCH_TICKS-Craft.WORK_TICKS): model.advance()
	near(model,Craft.SITE);ok(model.workshop_action("start"),"boundary smith start")
	for i in range(Craft.WORK_TICKS): model.advance()
	var events: Array=model.economy().events
	check(events[-2].kind=="watch" and events[-1].kind=="smith.ready" and events[-2].tick==events[-1].tick,"single watch precedes coincident smith completion")
	check(model.commission().escrow==12 and model.workshop_phase()=="ready","one specialist wage and one smith completion")
	ok(model.validate(model.snapshot()),"mixed coincident receipt replay")
	check(Supply._equal(Supply.replay(events,Craft.apply),model.economy().ledger),"canonical economic replay includes both optional systems")

func run() -> void:
	funds_and_debt();viewpoint_and_motion();active_custody();drill_attendance();mixed_replay_and_restore()
	for suffix in ["",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("INSTRUCTOR_ECONOMY_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
