extends RefCounted
## Authored provisions trade. Caller stages BOTH records; no clock or treasury here.
const VERSION := "bazaar-provisions.v1"
const BUYER_ID := "gujranwala_provisions_buyer"
const LOT := 4
const PAYMENT := 6
const BUYER_COINS := 96
const CARRY_SPEED := 3.0
const PACKING := Vector3(10,0.14,9.4)

static func initial() -> Dictionary:
	return {"schema":VERSION,"buyer_id":BUYER_ID,"buyer_coins":BUYER_COINS,
		"buyer_food":0,"known_watch":-1,"last_sale_watch":-1,"carried":0,"lots":0}

static func apply(s: Dictionary,t: Dictionary,kind: String,arg: String) -> String:
	# The zero-size record is intentional: legacy saves invent no merchant offer.
	if kind=="bazaar_hear" and t.is_empty(): t.merge(initial())
	if t.is_empty(): return "Hear the trader's offer at the market first."
	match kind:
		"bazaar_hear":
			if arg!="": return "Unknown offer."
			if t.carried>0: return "Your packed lot retains its agreed terms; deliver or return it first."
			if t.known_watch==s.watch: return "You have already heard this watch's offer."
			if t.last_sale_watch==s.watch or t.buyer_coins<PAYMENT: return "This buyer has no further demand this watch."
			t.known_watch=s.watch
		"bazaar_pack":
			if arg not in ["reserve","risk_reserve"]: return "Choose whether to protect the next food reserve."
			if t.carried!=0 or s.cargo!=0: return "Carry only one provisions assignment at a time."
			if t.known_watch!=s.watch: return "That unpacked offer is stale. Hear current terms at the market."
			if t.last_sale_watch==s.watch or t.buyer_coins<PAYMENT: return "No remaining buyer demand this watch."
			if s.stock.food<LOT: return "Four food portions must actually be in the home store."
			var reserve: int=1+s.workers+s.guards
			if arg=="reserve" and s.stock.food-LOT<reserve:
				return "Packing would spend the next food reserve. Restock or explicitly accept the risk."
			s.stock.food-=LOT
			t.carried=LOT
			s.last_notice="Four portions left the store. Carried provisions cannot feed the household until returned."
		"bazaar_sell":
			if arg!="" or t.carried!=LOT: return "Bring the agreed provisions lot to the buyer."
			if t.last_sale_watch==s.watch or t.buyer_coins<PAYMENT: return "This watch's demand or the buyer's purse is exhausted."
			t.carried=0
			t.buyer_food+=LOT
			t.buyer_coins-=PAYMENT
			t.lots+=1
			t.last_sale_watch=s.watch
			s.treasury+=PAYMENT
			s.last_notice="Buyer received four portions. Six coins entered household coffers, not the personal purse."
		"bazaar_return":
			if arg!="" or t.carried!=LOT: return "No packed provisions to put back."
			var occupied:=0
			for amount in s.stock.values(): occupied+=int(amount)
			if occupied+LOT>(80 if "storehouse" in s.built else 48): return "Make four free storage units before unloading. Your cargo is retained."
			s.stock.food+=LOT
			t.carried=0
			s.last_notice="The packed provisions are back in household storage. No payment was made."
		_: return "Unknown bazaar operation."
	return ""
