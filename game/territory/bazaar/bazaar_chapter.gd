extends "res://territory/road/road_chapter.gd"
## One home entry: provisions change location through player motion and original receipts.
const BazaarState := preload("res://territory/bazaar/bazaar_state.gd")
const Bazaar := preload("res://territory/bazaar/bazaar_rules.gd")
var _provisions_pack: MeshInstance3D
var _packing_label: Label3D
var _trade_import := false

func _init() -> void:
	model=BazaarState.new()
	save_path=BazaarState.BAZAAR_SAVE

func _ready() -> void:
	super._ready()
	_build_bazaar_props()
	_sync_load()

func _build_bazaar_props() -> void:
	# Original authored balance/scales, not a calibrated historic instrument or asset import.
	var root_node:=Node3D.new()
	root_node.name="BazaarProvisionsProps"
	add_child(root_node)
	_make_prop(root_node,Vector3(0.65,0.07,0.35),Vector3(-24.6,1.37,-17.6),Color("54442f"))
	_make_prop(root_node,Vector3(0.06,0.65,0.06),Vector3(-24.6,1.7,-17.6),Color("ac8744"))
	_make_prop(root_node,Vector3(0.85,0.05,0.05),Vector3(-24.6,2.02,-17.6),Color("ac8744"))
	for x in [-25.0,-24.2]:
		_make_prop(root_node,Vector3(0.012,0.30,0.012),Vector3(x,1.86,-17.6),Color("cebf93"))
		_make_prop(root_node,Vector3(0.28,0.04,0.24),Vector3(x,1.69,-17.6),Color("ac8744"))
	_make_prop(root_node,Vector3(1.25,0.10,0.65),Vector3(10.5,0.7,10.5),Color("725137"))
	_make_prop(root_node,Vector3(0.7,0.10,0.45),Vector3(10.5,0.8,10.5),Color("bbb18a"))
	_provisions_pack=_make_prop(avatar,Vector3(0.56,0.65,0.32),Vector3(0,1.0,0.38),Color("b4a171"))
	_provisions_pack.name="CarriedProvisions"
	_packing_label=Label3D.new()
	_packing_label.text="Household provisions [E]"
	_packing_label.font_size=22
	_packing_label.position=Bazaar.PACKING+Vector3.UP*1.95
	_packing_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_packing_label)

func _make_prop(parent: Node3D,size: Vector3,at: Vector3,color: Color) -> MeshInstance3D:
	var item:=MeshInstance3D.new()
	var mesh:=BoxMesh.new();mesh.size=size
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=0.9
	item.mesh=mesh;item.material_override=material;item.position=at
	parent.add_child(item)
	return item

func _sync_load() -> void:
	if not is_instance_valid(avatar): return
	var loaded: bool=model.carrying_provisions()
	avatar.travel_speed_limit=Bazaar.CARRY_SPEED if loaded else INF
	if is_instance_valid(_provisions_pack): _provisions_pack.visible=loaded
	if is_instance_valid(_packing_label): _packing_label.visible=model.has_economy()

func _physics_process(delta: float) -> void:
	if _trade_import:
		_trade_import=false
		_load(RoadState.ROAD_SAVE)
		return
	_sync_load()
	var hearing: bool=_economy_action=="bazaar_hear"
	var count: int=model.economy().get("events",[]).size()
	super._physics_process(delta)
	_sync_load()
	if hearing and model.economy().get("events",[]).size()>count:
		_message="Trader: Four food portions for six household coins. One lot each supply watch; a packed lot keeps its terms."
		_refresh()

func _apply() -> void:
	super._apply()
	_sync_load()

func _interact() -> void:
	if model.has_economy() and not model.mounted() and Model.distance(model.position(),Bazaar.PACKING)<1.7:
		if _seen(Bazaar.PACKING+Vector3.UP,2.6): _open_packing()
		else: _message="Face the provisions station inside the store."
		return
	super._interact()

func _open_packing() -> void:
	var s: Dictionary=model.economy().ledger
	var t: Dictionary=model.trade()
	var actions: Array=[]
	var body: String="Four portions make one carryable lot. Only home stock feeds this watch's household.\n\nFood in store: %d\nNext-watch food due: %d\n"%[s.stock.food,Rules.due(s).food]
	if model.carrying_provisions():
		body+="\nYou carry four portions. They are NOT in home storage. Returning them requires four free storage units."
		actions.append(["Put four portions back","econ:bazaar_return"])
	elif t.is_empty():
		body+="\nHear the buyer at the western market before packing a lot."
	elif t.known_watch!=s.watch:
		body+="\nThat unpacked offer has expired. Return to hear the trader's current terms."
	elif t.last_sale_watch==s.watch or t.buyer_coins<Bazaar.PAYMENT:
		body+="\nNo further demand from this buyer now."
	else:
		body+="\nTrader's offer: four food portions for six household coins. Carrying caps walking/running at 3 m/s; put the load down in the store before mounting.\n\nThe reserve protects only the next watch under current staffing, not your whole future campaign."
		actions.append(["Pack lot, protecting the next food reserve","econ:bazaar_pack|reserve"])
		if s.stock.food>=Bazaar.LOT and s.stock.food-Bazaar.LOT<Rules.due(s).food:
			actions.append(["Pack anyway — spend the next food reserve","econ:bazaar_pack|risk_reserve"])
	actions.append(["Leave provisions here","resume"])
	_show_dialog("HOUSEHOLD STORE",body,actions)

func _append_trade_button(text: String,action: String) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=40
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind(action));_actions.add_child(button)

func _open_market() -> void:
	super._open_market()
	if not model.has_economy(): return
	# Existing trader, current delivery and road options remain; no rival copy of the market.
	_append_trade_button("Hear provisions buyer / sell carried lot","bazaar_terms")

func _open_terms() -> void:
	var s: Dictionary=model.economy().ledger
	var t: Dictionary=model.trade()
	var body: String="Speak to the trader here. Opening this panel alone grants no remembered terms."
	var actions: Array=[]
	if model.carrying_provisions():
		body="Trader: You brought the agreed four portions. The six coins belong to the household. Packed terms remain valid across a watch."
		actions.append(["Sell the four carried portions for six household coins","econ:bazaar_sell"])
	elif t.is_empty() or (t.known_watch!=s.watch and t.last_sale_watch!=s.watch and t.buyer_coins>=Bazaar.PAYMENT):
		actions.append(["Hear this watch's offer","econ:bazaar_hear"])
	elif t.last_sale_watch==s.watch:
		body="Trader: I have bought this watch's lot. Ask again after the next supply watch; I cannot buy endlessly."
	elif t.buyer_coins<Bazaar.PAYMENT:
		body="Trader: My allocated purse is spent. I have no more orders in this bounded scenario."
	else:
		body="Remembered offer: four portions for six household coins, one sale per watch. Enter the household store to pack; you can put the provisions back rather than sell. The default packing choice preserves the next food reserve."
	actions.append(["Return to the market","resume"])
	_show_dialog("PROVISIONS BUYER",body,actions)

func _menu_action(action: String) -> void:
	if action=="bazaar_terms": _open_terms();return
	if action=="import_road": _trade_import=true;return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_trade_import=false

func _open_journal() -> void:
	super._open_journal()
	_append_trade_button("Import earlier narrator / road save","import_road")

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud) or not model.has_economy(): return
	if model.carrying_provisions():
		_hud.text+="\nPROVISIONS · Carrying 4 food, outside home stock. Market: sell / store: put back."
	else:
		_hud.text+="\nBazaar: hear terms at market, pack provisions inside the household store."

func _account_text() -> String:
	var text:=super._account_text()
	if model.has_economy():
		text+="\n\nPROVISIONS TRADE\nCarried: %d food (excluded from home supply).\nSold: %d lots. Sales pay household coffers, not Buddh's purse. Buyer demand is finite."%[model.trade().get("carried",0),model.trade().get("lots",0)]
	return text

func _load(path: String="") -> void:
	var staged:=BazaarState.new()
	var error:=staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error=_candidate_error(staged)
	if error.is_empty(): error=model.restore(staged.snapshot())
	if error.is_empty():
		_apply()
		narration.rebase(_narration_events())
	_message="Chapter, provisions and household accounts restored together." if error.is_empty() else error
	_clear_pending_actions()
	_resume()
