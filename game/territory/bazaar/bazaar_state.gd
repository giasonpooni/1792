extends "res://territory/road/road_state.gd"
## The existing world/clock/economic ledger remains authoritative.
const Bazaar := preload("res://territory/bazaar/bazaar_rules.gd")
const BAZAAR_SAVE := "user://1792-bazaar-v1.json"

func trade() -> Dictionary:
	return _state.misl.get("trade",{}).duplicate(true) if has_economy() else {}

func carrying_provisions() -> bool:
	return int(trade().get("carried",0))>0

func operate(kind: String,arg: String="") -> String:
	if not kind.begins_with("bazaar_"): return super.operate(kind,arg)
	if not has_economy(): return "Complete the inquiry and hear the household allowance first."
	if mounted(): return "Dismount before hearing terms or handling provisions."
	if kind not in ["bazaar_hear","bazaar_pack","bazaar_sell","bazaar_return"]: return "Unknown bazaar instruction."
	var target: Vector3=Bazaar.PACKING if kind in ["bazaar_pack","bazaar_return"] else Economy.MARKET
	if distance(position(),target)>1.7: return "Enter the household store." if target==Bazaar.PACKING else "Stand beside the market buyer."
	return _post(kind,arg)

func mount() -> String:
	if carrying_provisions(): return "Deliver or put back the provisions before mounting."
	return super.mount()

func journal() -> Array:
	var entries: Array=super.journal()
	if not has_economy(): return entries
	for e in _state.misl.events:
		if e.kind=="bazaar_hear":
			entries.append({"id":"bazaar-offer-%d"%e.seq,"source_id":Bazaar.BUYER_ID,
				"received_tick":int(e.tick),"channel":"heard_speech",
				"text":"Trader: Four food portions for six household coins; one purchase each supply watch. A packed lot keeps these terms. My purse is finite."})
		elif e.kind in ["bazaar_pack","bazaar_sell","bazaar_return"]:
			entries.append({"id":"bazaar-handling-%d"%e.seq,"source_id":"ranjit_singh",
				"received_tick":int(e.tick),"channel":"direct_experience",
				"text":{"bazaar_pack":"I packed four portions from the household store.","bazaar_sell":"I delivered the lot; its payment belongs to the household.","bazaar_return":"I put the provisions back in the store."}[e.kind]})
	# Stable insertion keeps repeated same-tick receipts in their original order.
	for i in range(1,entries.size()):
		var item: Dictionary=entries[i];var j:=i-1
		while j>=0 and int(entries[j].received_tick)>int(item.received_tick):
			entries[j+1]=entries[j];j-=1
		entries[j+1]=item
	return entries
