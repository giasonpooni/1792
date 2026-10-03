# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dialogue around the existing received-request/received-account rules.
## No state writes, hidden-site reports, or historical reconstruction claim.
const Service := preload("res://misl/service_rules.gd")

static func request(route: String) -> String:
	match route:
		"market": return "Handler · The men loading these carts keep talking over one another. Send someone who can stay and hear them before the carts go."
		"well": return "Water carrier · We need room to pass with full pots. Ask a guard to hear us at the approach. Carry our difficulty back to your household."
	return ""

static func reply(kind: String, route: String, ledger: Dictionary) -> String:
	match kind:
		"begin": return "Quartermaster · Hear what they need. We can spare one provisioned guard. When he comes back, listen."
		"hear": return request(route) if route in ledger.get("heard", []) else ""
		"dispatch":
			if ledger.get("stage", "idle") != "outbound" or ledger.get("active", "") != route: return ""
			return "Guard · I will hear the handler. Keep my place here; I will bring the account back." if route == "market" else "Guard · I will go to the well approach and listen. You can ask me when I return."
		"debrief": return received_account(ledger)
	return ""

static func received_account(ledger: Dictionary) -> String:
	var completed: Array = ledger.get("completed", [])
	if completed.is_empty(): return ""
	var route: String = completed[-1]
	if not Service.ACCOUNTS.has(route): return ""
	# Use the unchanged account only after the debrief receipt exists.
	var received := false
	for memory in ledger.get("memories", []):
		if memory.get("id", "") == "service-account-" + route and memory.get("channel", "") == "spoken_account": received = true
	if not received: return ""
	return "Guard · " + Service.ACCOUNTS[route] + "\nBuddh · Thank you. Take your place again."

static func quartermaster_context(ledger: Dictionary) -> String:
	if ledger.is_empty(): return "One place at the gate can be spared. First hear whom you would send that guard to."
	match str(ledger.get("stage", "idle")):
		"awaiting_account": return "The guard has returned to his place. Hear him before sending him anywhere else."
		"outbound", "attending", "returning": return "You have sent one guard away. His place remains empty; his account will have to wait for his return."
	if ledger.get("completed", []).size() == 2: return "You have heard both accounts. No request remains on this detail."
	if not ledger.get("heard", []).is_empty(): return "Choose which heard request to attend. One guard goes; the other posts remain your responsibility."
	return "The handler and the water carrier have separate requests. Go and hear them."
