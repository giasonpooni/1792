extends RefCounted
## Bounded, pure economic transitions. Costs and watches are authored game units.
const VERSION := "gujranwala-misl.v1"
const WATCH_TICKS := 7200 # 120 playable seconds at 60 Hz; not a historical day.
const MAX_EVENTS := 256
const QUARTERMASTER := Vector3(3,0.14,5)
const MARKET := Vector3(-24,0.14,-15)
const CARAVAN_ID := "home_caravan_01"
const CELL_ID := "gujranwala-home-cell.v1"
const SEED := 1792
const PRICES := {
	"food":{"cost":8,"item":"food","quantity":4},
	"feed":{"cost":6,"item":"feed","quantity":6},
	"grain":{"cost":4,"item":"grain","quantity":6},
	"timber":{"cost":8,"item":"timber","quantity":4},
	"tools":{"cost":8,"item":"tools","quantity":2}}
const PROJECTS := {
	"palisade":{"cost":36,"timber":6,"tools":1,"work":6},
	"storehouse":{"cost":20,"timber":4,"tools":1,"work":4},
	"mill":{"cost":28,"timber":4,"tools":1,"work":4}}
const Base := preload("res://childhood/childhood_state.gd")

static func initial() -> Dictionary:
	return {"purse":18,"treasury":120,
		"stock":{"food":10,"feed":8,"grain":8,"timber":8,"tools":2},
		"workers":1,"guards":0,"horses":1,"watch":0,"arrears":0,
		"food_shortfall":0,"feed_shortfall":0,"duty_guards":0,
		"favor":50,"meeting":"pending","satchel":false,"delivery":"available",
		"caravan":"locked","cargo":0,"build":"","work_left":0,
		"built":[],"last_notice":"A bounded household allowance, not ownership of all royal funds."}

static func whole(value: Variant, low: int = 0, high: int = 10000000) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and value == floor(value) and value >= low and value <= high

static func stored(s: Dictionary) -> int:
	var n := 0
	for q in s.stock.values(): n += int(q)
	return n

static func capacity(s: Dictionary) -> int:
	return 80 if "storehouse" in s.built else 48

static func readiness(s: Dictionary) -> String:
	return "%d/%d guards provisioned · %s" % [s.duty_guards,s.guards,"reinforced gate" if "palisade" in s.built else "original walls"]

static func due(s: Dictionary) -> Dictionary:
	return {"food":1+s.workers+s.guards,"feed":2*s.horses,"wages":s.workers+2*s.guards}

static func _room(s: Dictionary, quantity: int) -> bool:
	return stored(s)+quantity <= capacity(s)

static func apply(s: Dictionary, kind: String, arg: String) -> String:
	# Caller works on a copy; rejected decisions never mutate the live authority.
	match kind:
		"buy":
			if not PRICES.has(arg): return "Unknown market lot."
			var offer: Dictionary = PRICES[arg]
			if s.treasury < offer.cost: return "Insufficient household funds."
			if not _room(s,offer.quantity): return "Store full. Use stock or build storage first."
			s.treasury -= offer.cost
			s.stock[offer.item] += offer.quantity
		"hire":
			if arg == "guard":
				if s.guards >= 3: return "Three garrison slots in this cell."
				if s.treasury < 22: return "A guard requires 22 coins, then 2 wages and 1 food each watch."
				s.treasury -= 22
				s.guards += 1
			elif arg == "worker":
				if s.workers >= 3: return "Three worker slots in this cell."
				if s.treasury < 12: return "A worker requires 12 coins, then 1 wage and 1 food each watch."
				s.treasury -= 12
				s.workers += 1
			else: return "Unknown appointment."
		"release_guard":
			if arg != "" or s.guards == 0: return "No garrison guard to release."
			s.guards -= 1
			s.duty_guards = mini(s.duty_guards,s.guards)
			s.last_notice = "Guard released; recruitment fee is not refunded."
		"contribute":
			if arg != "" or s.purse < 10: return "Need 10 personal coins to contribute."
			s.purse -= 10
			s.treasury += 10
		"satchel":
			if arg != "" or s.satchel or s.purse < 12: return "A satchel costs 12 personal coins; only one can be equipped."
			s.purse -= 12
			s.satchel = true
		"build":
			if not PROJECTS.has(arg) or s.build != "" or arg in s.built: return "One unfinished project at a time; no duplicate upgrades."
			var project: Dictionary = PROJECTS[arg]
			if s.treasury < project.cost or s.stock.timber < project.timber or s.stock.tools < project.tools:
				return "Construction requires coins, timber and tools in the home store."
			s.treasury -= project.cost
			s.stock.timber -= project.timber
			s.stock.tools -= project.tools
			s.build = arg
			s.work_left = project.work
		"accept_delivery":
			if arg != "" or s.delivery != "available": return "This supply contract can only be accepted once."
			if s.stock.food < 4: return "Four food portions must actually be available for dispatch."
			s.stock.food -= 4
			s.cargo = 4
			s.delivery = "outbound"
		"deliver":
			if arg != "" or s.delivery != "outbound" or s.cargo != 4: return "No contracted cargo to deliver."
			s.cargo = 0
			s.delivery = "delivered"
			s.purse += 12 + (4 if s.satchel else 0)
			s.treasury += 26
			s.caravan = "available"
			s.last_notice = "Food delivered. The larger satchel earns a handling premium, not extra physical cargo."
		"accept_escort":
			if arg != "" or s.caravan != "available": return "The return caravan is unavailable or already assigned."
			s.caravan = "active"
		"checkin":
			if arg != "" or s.caravan != "active": return "No returning caravan to check in."
			if not _room(s,16): return "Need sixteen free store units for the arriving food and fodder."
			s.caravan = "complete"
			s.stock.food += 8
			s.stock.feed += 8
			s.purse += 8
			s.treasury += 18
		"meeting":
			if arg != "" or s.meeting != "pending" or s.watch < 2: return "The household meeting opens at watch 2 and is due before watch 5."
			s.meeting = "attended"
			s.favor = mini(100,s.favor+8)
		"pay_arrears":
			if arg != "" or s.arrears == 0: return "No wages in arrears."
			if s.treasury < s.arrears: return "Not enough treasury to clear the wage arrears."
			s.treasury -= s.arrears
			s.arrears = 0
		"watch":
			if arg != "": return "Invalid watch."
			_watch(s)
		_: return "Unknown economic operation."
	return ""

static func _watch(s: Dictionary) -> void:
	s.watch += 1
	var need := due(s)
	var fed: bool = s.stock.food >= need.food
	var watered: bool = s.stock.feed >= need.feed
	var paid: bool = s.treasury >= need.wages
	var wage_payment := mini(s.treasury,need.wages)
	s.treasury -= wage_payment
	s.arrears += need.wages-wage_payment
	s.food_shortfall = maxi(0,need.food-s.stock.food)
	s.feed_shortfall = maxi(0,need.feed-s.stock.feed)
	s.stock.food = maxi(0,s.stock.food-need.food)
	s.stock.feed = maxi(0,s.stock.feed-need.feed)
	s.duty_guards = s.guards if fed and paid and s.arrears == 0 else 0
	s.last_notice = "Upkeep paid; people and the household horse provisioned."
	if not fed or not watered or not paid or s.arrears > 0:
		s.favor = maxi(0,s.favor-4)
		s.last_notice = "Short food/wages can halt work; missing fodder restricts the horse to a walk."
	if fed and paid and s.arrears == 0:
		if s.build != "":
			s.work_left = maxi(0,s.work_left-s.workers)
			if s.work_left == 0:
				s.built.append(s.build)
				s.last_notice = s.build.capitalize()+" completed. No production during construction work."
				s.build = ""
		else:
			# Declared recipe: each grain lot yields two food portions. Units are not mass.
			var rate: int = s.workers*(2 if "mill" in s.built else 1)
			var batches := mini(rate,s.stock.grain)
			batches = mini(batches,maxi(0,capacity(s)-stored(s))) # net +1 per conversion.
			s.stock.grain -= batches
			s.stock.food += 2*batches
	if s.watch >= 5 and s.meeting == "pending":
		s.meeting = "missed"
		s.favor = maxi(0,s.favor-12)
		s.last_notice = "The meeting was missed. This penalty is applied once, not every watch."

static func blank_merchant() -> Dictionary:
	return {"id":CARAVAN_ID,"position":Base.coords(MARKET+Vector3(1,0,0)),
		"yaw":0.0,"velocity":[0.0,0.0,0.0]}

static func validate(value: Variant, tick: int, reducer: Callable = Callable()) -> String:
	if not value is Dictionary or value.size()!=7: return "Malformed home economy."
	for key in ["schema","cell_id","seed","origin_tick","events","ledger","merchant"]:
		if not value.has(key): return "Missing home-economy field."
	if value.schema != VERSION or value.cell_id != CELL_ID or value.seed != SEED: return "Unsupported economy or generated cell identity."
	if not whole(value.origin_tick,0,tick) or not value.events is Array or value.events.size()>MAX_EVENTS: return "Invalid economy origin or event budget."
	var replay := initial()
	var prior: int = int(value.origin_tick)
	var seq := 0
	for e in value.events:
		if not e is Dictionary or e.size()!=4: return "Malformed economic receipt."
		for key in ["seq","tick","kind","arg"]:
			if not e.has(key): return "Incomplete economic receipt."
		if not whole(e.seq,1,MAX_EVENTS) or e.seq != seq+1 or not whole(e.tick,prior,tick) or not e.kind is String or not e.arg is String:
			return "Unordered economic receipts."
		var next_watch: int = int(value.origin_tick)+(replay.watch+1)*WATCH_TICKS
		if e.kind == "watch":
			if e.tick != next_watch: return "Upkeep occurred on the wrong tick."
		elif e.tick >= next_watch: return "Missing due upkeep before transaction."
		var error: String = reducer.call(replay,e.kind,e.arg) if reducer.is_valid() else apply(replay,e.kind,e.arg)
		if not error.is_empty(): return "Invalid retained economic action: "+error
		prior = int(e.tick)
		seq += 1
	if tick >= int(value.origin_tick)+(replay.watch+1)*WATCH_TICKS and value.events.size()<MAX_EVENTS:
		return "A due watch has not settled."
	# JSON normalizes integral storage, but booleans, strings, extra keys remain invalid.
	if not _equal(replay,value.ledger): return "Ledger disagrees with retained receipts."
	var m: Variant = value.merchant
	if not m is Dictionary or m.size()!=4 or m.get("id") != CARAVAN_ID: return "Invalid caravan identity."
	if not m.has("position") or not Base.valid_point(m.position) or not m.has("velocity") or not valid_velocity(m.velocity): return "Invalid caravan coordinates."
	if not finite_number(m.get("yaw")) or absf(m.yaw)>PI: return "Invalid caravan facing."
	if absf(m.velocity[0])>2.6 or absf(m.velocity[2])>2.6: return "Caravan velocity out of bounds."
	if replay.caravan in ["locked","available"] and not _equal(m,blank_merchant()): return "An unassigned caravan cannot have travelled."
	if replay.caravan == "complete" and Base.distance(Base.point(m.position),QUARTERMASTER)>4.5: return "Returned caravan is not at the store."
	return ""

static func valid_velocity(value: Variant) -> bool:
	if not value is Array or value.size()!=3: return false
	for n in value:
		if not finite_number(n): return false
	return value[1]>=-50 and value[1]<=0 and Vector2(value[0],value[2]).length()<=2.61

static func finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))

static func _equal(a: Variant,b: Variant) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not _equal(a[i],b[i]): return false
		return true
	if typeof(a) in [TYPE_INT,TYPE_FLOAT]: return finite_number(b) and a==b
	return typeof(a)==typeof(b) and a==b

static func replay(events: Array, reducer: Callable = Callable()) -> Dictionary:
	var s := initial()
	for e in events:
		if reducer.is_valid(): reducer.call(s,e.kind,e.arg)
		else: apply(s,e.kind,e.arg)
	return s

static func forecast(s: Dictionary) -> Dictionary:
	var candidate: Dictionary=s.duplicate(true)
	_watch(candidate)
	return {"food_delta":candidate.stock.food-s.stock.food,
		"feed_delta":candidate.stock.feed-s.stock.feed,"treasury_delta":candidate.treasury-s.treasury,
		"work_delta":candidate.work_left-s.work_left,
		"warning":candidate.last_notice,"scope":"next_watch_under_unchanged_choices"}
