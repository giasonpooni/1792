# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dialogue and cosmetic staging. The retained economy owns all cargo,
## movement, arrival and payment; these helpers never mutate it.
const Rules := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")

static func briefing(model, market: bool = false) -> String:
	if not model.has_economy():
		return "Quartermaster · These coffers feed the household. Keep them apart from your own purse.\n\n120 household coins · 18 personal coins. B opens the spoken accounts."
	var s: Dictionary = model.economy().ledger
	if market:
		if s.delivery == "outbound": return "Trader · Four portions were promised. Set them here; we will count together.\n\nThe handover pays 12 personal coins and 26 household coins, with a 4-coin handling premium if you own the satchel."
		if s.caravan == "available": return "Trader · One, two, three, four. The promise is kept.\n\nA carrier has food and fodder for Home. You can walk back together when you are ready."
		if s.caravan == "active": return "Trader · The carrier is yours to accompany. Let the load set the pace.\n\nStay within 9 m; if you lose contact, return to the carrier."
		if s.caravan == "complete": return "Trader · The road's business is settled. What does the household need now?"
		return "Trader · Tell me what the household needs. Its coins stay in its account."
	if s.delivery == "available": return "Quartermaster · Four portions for the market. Count them out, and let the trader count them in.\n\nDelivery pays 12 personal coins and 26 household coins. The portions leave our store when you accept."
	if s.delivery == "outbound": return "Quartermaster · Four portions left this store. The trader is waiting to receive the same four."
	if s.caravan == "active":
		if carrier_phase(model) == "arrived": return "Quartermaster · You brought the carrier with you. The load has reached the store.\n\nCheck in to receive 8 food, 8 fodder, 8 personal coins and 18 household coins. Sixteen free store units are required."
		return "Quartermaster · I see you. Where is the carrier?\n\nReturn together before checking in. The load must reach the store."
	if s.caravan == "complete": return "Quartermaster · Four portions out; a carrier safely home. That is a promise finished."
	return "Quartermaster · The trader has received the four portions. Our return carrier is still at the market when you are ready."

static func acknowledgment(kind: String, arg: String, model) -> String:
	match kind:
		"begin": return "Quartermaster · Spend for the household. Answer for what leaves the store."
		"accept_delivery": return "Quartermaster · One, two, three, four. All yours to carry; all four owed at the market."
		"deliver": return "Trader · One, two, three, four. Good. Your %d coins, and 26 for the household." % (16 if model.economy().ledger.satchel else 12)
		"accept_escort": return "Carrier · I can carry the load. Walk close enough that I can keep with you."
		"checkin": return "Quartermaster · Eight food, eight fodder. Carrier and load both home. Put it down; the journey is done."
		"buy": return "Trader · The %s is counted against the household's coins." % ("fodder" if arg == "feed" else arg)
		"satchel": return "Trader · A wider satchel, from your own purse." + (" Your four-portion handover will earn its handling premium." if model.economy().ledger.delivery != "delivered" else " The earlier handover is already settled.")
		"hire": return "Quartermaster · Another %s on the roll. Another share of food and wages to remember." % arg
		"release_guard": return "Quartermaster · The guard is released. The recruitment fee has already been spent."
		"build": return "Quartermaster · Materials set aside for the %s. Provision the workers and the work can begin." % arg
		"meeting": return "Quartermaster · You came when the household called. They have heard your account."
		"pay_arrears": return "Quartermaster · The waiting wages are paid. We owe them none for the watches past."
		"contribute": return "Quartermaster · Ten coins from your purse into the household's. I have kept the accounts apart."
		"rest": return "Quartermaster · Another watch has passed. Hear the accounts before making another promise."
	return "Quartermaster · The account is settled."

static func carrier_phase(model) -> String:
	if not model.has_economy(): return "inactive"
	var m: Dictionary = model.economy()
	if m.ledger.caravan != "active": return str(m.ledger.caravan)
	var at := Base.point(m.merchant.position)
	if Base.distance(at, Rules.QUARTERMASTER) <= 4.5: return "arrived"
	return "separated" if Base.distance(model.position(), at) > 9.0 else "together"

static func carrier_transition(previous: String, current: String) -> String:
	if previous.is_empty() or previous == current: return ""
	if current == "separated": return "Buddh · We have lost contact. I should get back to the carrier."
	if current == "together" and previous == "separated": return "Carrier · There you are. We can go on together."
	if current == "arrived" and previous in ["together", "separated"]: return "Carrier · Home at last. Tell the quartermaster the load is here."
	return ""

static func make_cargo() -> Node3D:
	var cargo := Node3D.new()
	cargo.name = "FourFoodPortions"
	for i in range(4):
		var parcel := MeshInstance3D.new()
		parcel.name = "Portion%d" % (i + 1)
		var shape := BoxMesh.new()
		shape.size = Vector3(0.26, 0.23, 0.25)
		parcel.mesh = shape
		parcel.position = Vector3((i % 2 - 0.5) * 0.29, 0.82 + floori(i / 2.0) * 0.26, 0.29)
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = Color("bba276") if i % 2 == 0 else Color("947b54")
		cloth.roughness = 1.0
		parcel.material_override = cloth
		cargo.add_child(parcel)
	return cargo
