extends "res://tests/test_shah_road.gd"
## New domain fixtures are explicit; the two journeys below use actual input/collision.
const BazaarState := preload("res://territory/bazaar/bazaar_state.gd")
const Bazaar := preload("res://territory/bazaar/bazaar_rules.gd")
const BAZAAR_TEST_SAVE := "user://bazaar-regression-only.json"

func fresh():
	var s:=BazaarState.new()
	assert(s.restore(Fixture.complete()).is_empty())
	assert(s.begin_allowance().is_empty())
	return s

func heard():
	var s=fresh()
	assert(Pose.pose(s,Economy.MARKET+Vector3.RIGHT).is_empty())
	assert(s.operate("bazaar_hear").is_empty())
	return s

func packed():
	var s=heard()
	assert(Pose.pose(s,Bazaar.PACKING).is_empty())
	assert(s.operate("bazaar_pack","reserve").is_empty())
	return s

func _trade_domain() -> void:
	var s:=BazaarState.new()
	reject(s,s.operate.bind("bazaar_hear"),"no child allowance invented by trade")
	s=fresh()
	check(s.trade().is_empty(),"allowance does not grant unheard terms")
	reject(s,s.operate.bind("bazaar_hear"),"no remote hearing")
	ok(Pose.pose(s,Bazaar.PACKING),"packing fixture")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"no trade without offer")
	s=heard()
	var memories: int=s.journal().size()
	reject(s,s.operate.bind("bazaar_hear"),"repeat hearing is not a new source")
	check(s.journal().size()==memories,"one remembered offer")
	var before: Dictionary=s.economy().ledger
	ok(Pose.pose(s,Bazaar.PACKING),"inside store fixture")
	ok(s.operate("bazaar_pack","reserve"),"pack actual home food")
	check(s.trade().carried==4 and s.economy().ledger.stock.food==before.stock.food-4,"stock location conservation on packing")
	check(s.economy().ledger.treasury==before.treasury and s.economy().ledger.purse==before.purse,"packing creates no payment")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"no duplicate pack")
	reject(s,s.mount,"loaded character cannot mount")
	ok(Pose.pose(s,Economy.QUARTERMASTER),"quartermaster fixture")
	reject(s,s.operate.bind("accept_delivery"),"two physical assignments cannot share a carrier")
	reject(s,s.operate.bind("bazaar_sell"),"no remote sale")
	ok(Pose.pose(s,Economy.MARKET+Vector3.RIGHT),"buyer fixture")
	ok(s.operate("bazaar_sell"),"deliver real lot")
	check(s.trade().carried==0 and s.trade().buyer_food==4 and s.trade().lots==1,"buyer gets cargo exactly once")
	check(s.economy().ledger.treasury==before.treasury+6 and s.trade().buyer_coins==90,"money transfers from finite buyer purse")
	check(s.economy().ledger.purse==before.purse,"no private withdrawal")
	reject(s,s.operate.bind("bazaar_sell"),"no duplicate reward")
	reject(s,s.operate.bind("bazaar_hear"),"one sale per watch")
	ok(Pose.pose(s,Bazaar.PACKING),"return to store fixture")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"cannot repack sold watch")
	ok(Pose.pose(s,Economy.QUARTERMASTER),"rest fixture")
	ok(s.rest_watch(),"existing clock opens another supply watch")
	ok(Pose.pose(s,Economy.MARKET+Vector3.RIGHT),"hear next offer fixture")
	ok(s.operate("bazaar_hear"),"new watch permits genuinely new terms")
	check(s.trade().known_watch==1,"offer explicitly bound to supply watch")
	# Stale unpacked offers versus already packed contract terms.
	s=heard();ok(Pose.pose(s,Economy.QUARTERMASTER),"stale terms setup")
	ok(s.rest_watch(),"advance with original world clock")
	ok(Pose.pose(s,Bazaar.PACKING),"stale packing fixture")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"unpacked stale offer refused")
	s=packed();ok(Pose.pose(s,Economy.QUARTERMASTER),"packed terms setup")
	ok(s.rest_watch(),"carried food is not in home store during upkeep")
	ok(Pose.pose(s,Economy.MARKET+Vector3.RIGHT),"packed delivery fixture")
	ok(s.operate("bazaar_sell"),"packed terms honoured across watch")
	check(s.trade().last_sale_watch==1 and s.trade().known_watch==0,"agreement and settlement times are distinct")
	# Explicit reserve-risk choice couples to construction and garrison provision.
	s=heard();ok(Pose.pose(s,Economy.QUARTERMASTER),"staffing fixture")
	for role in ["worker","worker","guard","guard","guard"]: ok(s.operate("hire",role),"hire "+role)
	ok(s.operate("build","storehouse"),"schedule work using existing resources")
	ok(Pose.pose(s,Bazaar.PACKING),"full household packing fixture")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"reserve guard uses actual staffing")
	ok(s.operate("bazaar_pack","risk_reserve"),"explicitly accept shortfall risk")
	var safe:=BazaarState.new();ok(safe.restore(s.snapshot()),"compare valid alternate future")
	ok(safe.operate("bazaar_return"),"return risked reserve")
	ok(Pose.pose(s,Economy.QUARTERMASTER),"risky watch location")
	ok(Pose.pose(safe,Economy.QUARTERMASTER),"safe watch location")
	ok(s.rest_watch(),"settle risky watch");ok(safe.rest_watch(),"settle provisioned watch")
	check(s.economy().ledger.food_shortfall==1 and s.economy().ledger.work_left==4,"exported reserve halts actual construction")
	check(s.economy().ledger.duty_guards==0,"unfed garrison not ready")
	check(safe.economy().ledger.work_left==1 and safe.economy().ledger.duty_guards==3,"returned food enables existing work and guards")
	# No disappearance when home storage fills while cargo is outside.
	s=packed();ok(Pose.pose(s,Economy.MARKET+Vector3.RIGHT),"full store fixture")
	for lot in ["grain","grain","timber"]:ok(s.operate("buy",lot),"buy into released storage "+lot)
	ok(Pose.pose(s,Bazaar.PACKING),"unloading fixture")
	reject(s,s.operate.bind("bazaar_return"),"full storage retains carried lot")
	check(s.trade().carried==4,"failed return loses nothing")
	# Separate old delivery remains compatible but cannot duplicate the held pack.
	s=fresh();ok(s.operate("accept_delivery"),"old delivery unchanged")
	ok(Pose.pose(s,Economy.MARKET+Vector3.RIGHT),"offer while original cargo held")
	ok(s.operate("bazaar_hear"),"hearing does not allocate more cargo")
	ok(Pose.pose(s,Bazaar.PACKING),"mutual-exclusion fixture")
	reject(s,s.operate.bind("bazaar_pack","reserve"),"original cargo prevents bazaar cargo")

func _persistence() -> void:
	var s=packed()
	ok(s.save_to(BAZAAR_TEST_SAVE),"save loaded provisions")
	var loaded:=BazaarState.new()
	ok(loaded.load_from(BAZAAR_TEST_SAVE),"JSON restore optional trade alongside original ledger")
	check(Economy._equal(s.snapshot(),loaded.snapshot()),"whole world roundtrip")
	check(s.journal()==loaded.journal(),"same oral offer and direct-experience records")
	for mode in ["buyer","coins","food","cargo","lots","watch","bool","absent","orphan","receipt","extra","mounted"]:
		var bad: Dictionary=s.snapshot()
		match mode:
			"buyer":bad.misl.trade.buyer_id="other"
			"coins":bad.misl.trade.buyer_coins+=6
			"food":bad.misl.trade.buyer_food=4
			"cargo":bad.misl.trade.carried=0
			"lots":bad.misl.trade.lots=1
			"watch":bad.misl.trade.known_watch=1
			"bool":bad.misl.trade.known_watch=false
			"absent":bad.misl.erase("trade")
			"orphan":bad.misl.events.clear();bad.misl.ledger=Economy.initial()
			"receipt":bad.misl.events[-1].kind="bazaar_sell"
			"extra":bad.misl.trade.hidden_plot="invented"
			"mounted":bad.riding.horse.rider_id="ranjit_singh"
		reject(loaded,loaded.restore.bind(bad),"invalid trade save "+mode)
	var inherited:=State.new()
	ok(inherited.restore(s.snapshot()),"base road authority validates extended ledger")
	reject(inherited,inherited.mount,"inherited mounting also enforces optional load")
	var copy: Dictionary=loaded.trade();copy.carried=0
	check(loaded.carrying_provisions(),"detached presentation query")
	ok(loaded.restore(Fixture.complete()),"old complete-inquiry save rolls back later trade")
	check(not loaded.has_economy() and loaded.trade().is_empty(),"no future allowance or terms retained")
	check(not str(loaded.journal()).contains("bazaar-offer"),"future testimony rolled back")
	# Pure declared stress fixture, not a human campaign or historically calibrated economy.
	var ledger:=Economy.initial();ledger.stock.food=200
	var trade: Dictionary={}
	for i in range(16):
		ledger.watch=i
		ok(Bazaar.apply(ledger,trade,"bazaar_hear",""),"finite-buyer offer")
		ok(Bazaar.apply(ledger,trade,"bazaar_pack","reserve"),"finite-buyer pack")
		ok(Bazaar.apply(ledger,trade,"bazaar_sell",""),"finite-buyer settle")
		check(ledger.treasury+trade.buyer_coins==120+96,"total trade money conserved")
		check(ledger.stock.food+trade.carried+trade.buyer_food==200,"total trade food conserved")
	ledger.watch=16
	check(not Bazaar.apply(ledger,trade,"bazaar_hear","").is_empty(),"finite purse cannot print more money")
	check(trade.lots==16 and trade.buyer_food==64 and trade.buyer_coins==0,"finite buyer terminal totals")

func to_market(scene) -> void:
	await walk(scene,Vector3(10,0.14,4.5))
	await walk(scene,Vector3(5,0.14,-12))
	await walk(scene,Vector3(-12,0.14,-15))
	await walk(scene,Economy.MARKET+Vector3.RIGHT)

func to_store(scene) -> void:
	await walk(scene,Vector3(-12,0.14,-15))
	await walk(scene,Vector3(5,0.14,-12))
	await walk(scene,Vector3(10,0.14,4.5))
	await walk(scene,Bazaar.PACKING-Vector3(0,0,0.6))

func _bazaar_journey(sell: bool) -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=BAZAAR_TEST_SAVE
	# Only initialization fixture: already completed earlier story, no trade/offer.
	ok(scene.model.restore(fresh().snapshot()),"explicit completed-inquiry journey start")
	root.add_child(home);await frames(5)
	await to_market(scene)
	look(scene,Economy.MARKET)
	await tap(scene,KEY_E);await press(scene,"Hear provisions buyer")
	var prior: Dictionary=scene.model.snapshot()
	await frames(30)
	check(prior==scene.model.snapshot(),"reading options pauses clock without granting offer")
	await press(scene,"Hear this watch")
	check(scene.model.trade().known_watch==scene.model.economy().ledger.watch,"actual hearing dispatch")
	await to_store(scene)
	look(scene,Bazaar.PACKING)
	await tap(scene,KEY_E);await press(scene,"Pack lot, protecting")
	check(scene.model.carrying_provisions() and scene._provisions_pack.visible,"actual packing action and visible held pack")
	check(scene.avatar.travel_speed_limit==Bazaar.CARRY_SPEED,"holding load applies traversal cap")
	# Mid-route real movement and save/load; no arbitrary position injection.
	await walk(scene,Vector3(10,0.14,4.5))
	await tap(scene,KEY_F5)
	var saved: Vector3=scene.model.position()
	await walk(scene,Vector3(6,0.14,4.5))
	await tap(scene,KEY_F9)
	check(Base.distance(scene.model.position(),saved)<0.2 and scene.model.carrying_provisions(),"loaded route resumes with same cargo")
	Input.action_press("sprint")
	look(scene,Vector3(10,0.14,1))
	Input.action_press("move_forward");await frames(15);Input.action_release("move_forward");Input.action_release("sprint")
	check(Vector2(scene.avatar.velocity.x,scene.avatar.velocity.z).length()<=Bazaar.CARRY_SPEED+0.01,"sprint cannot bypass physical carrying limit")
	await frames(10)
	if sell:
		await to_market(scene)
		look(scene,Economy.MARKET);await tap(scene,KEY_E);await press(scene,"Hear provisions buyer")
		await press(scene,"Sell the four")
		check(scene.model.trade().lots==1 and scene.model.trade().buyer_food==4,"physical route ends in one actual sale")
		check(scene.model.economy().ledger.treasury==126,"six coins in original household treasury")
	else:
		await walk(scene,Vector3(10,0.14,4.5))
		await walk(scene,Bazaar.PACKING-Vector3(0,0,0.6))
		look(scene,Bazaar.PACKING);await tap(scene,KEY_E);await press(scene,"Put four portions")
		check(scene.model.trade().lots==0 and scene.model.economy().ledger.stock.food==10,"physical return restores stock without sale")
	check(not scene._provisions_pack.visible and is_inf(scene.avatar.travel_speed_limit),"settlement removes load without changing base pace")
	check(not scene.model.snapshot().actors.has(Bazaar.BUYER_ID),"no new independent simulation actor")
	home.queue_free();await frames()

func _run() -> void:
	_trade_domain();_persistence()
	await _bazaar_journey(true)
	await _bazaar_journey(false)
	for suffix in ["",".tmp",".checkpoint.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(BAZAAR_TEST_SAVE+suffix))
	print("BAZAAR_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
