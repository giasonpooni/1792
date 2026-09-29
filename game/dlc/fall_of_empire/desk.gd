# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Control
## Standalone authoring/qualification scene; never mounted beside the Home world.
const Rules := preload("res://dlc/fall_of_empire/rules.gd")
var state: Dictionary = {}
var checkpoint: Dictionary = {}
var tick := 0
var role := "company_courier"
var manifest: Dictionary = {}
var buttons: Dictionary = {}
var tabs: TabContainer
var role_picker: OptionButton
var recipient: OptionButton
var disposition: OptionButton
var household: OptionButton
var notebook: RichTextLabel
var status_label: Label
var clock_label: Label
var timeline_label: Label
var closure_label: Label

func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string(Rules.MANIFEST))
	build_ui()
	reset()

func reset() -> void:
	state = Rules.initial("desk:%d" % Time.get_ticks_usec())
	tick=0;checkpoint={};role="company_courier";role_picker.select(0)
	status_label.text="Start with an observation. Role switching does not transfer knowledge."
	refresh()

func _physics_process(_delta: float) -> void:
	# Only this opt-in scene is running. No campaign clock or save is acquired.
	if not state.is_empty() and not state.world.closed: tick+=1
	if tick%30==0: clock_label.text="AUTHORING CLOCK  %d ticks / 60 Hz   |   %d / 64 receipts" % [tick,state.get("history",[]).size()]

func label(text: String, size_px: int=16) -> Label:
	var node:=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size_px)
	return node

func button(id: String, title: String, callback: Callable, parent: Node) -> Button:
	var node:=Button.new();node.text=title;node.custom_minimum_size.y=34
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.pressed.connect(callback)
	parent.add_child(node);buttons[id]=node
	return node

func panel(parent: Node) -> VBoxContainer:
	var box:=PanelContainer.new();var style:=StyleBoxFlat.new()
	style.bg_color=Color("182633");style.corner_radius_top_left=8;style.corner_radius_top_right=8
	style.corner_radius_bottom_left=8;style.corner_radius_bottom_right=8
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=12;style.content_margin_bottom=12
	box.add_theme_stylebox_override("panel",style);parent.add_child(box)
	var contents:=VBoxContainer.new();contents.add_theme_constant_override("separation",10);box.add_child(contents)
	return contents

func tab(title: String) -> VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var margin:=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	scroll.add_child(margin)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",12)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;margin.add_child(content)
	return content

func choices(values: Array, parent: Node) -> OptionButton:
	var picker:=OptionButton.new();picker.custom_minimum_size.y=34
	picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for value in values: picker.add_item(str(value).replace("_"," ").capitalize())
	parent.add_child(picker);return picker

func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("0d1721")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);margin.add_child(column)
	column.add_child(label("1792  /  FALL OF EMPIRE",28))
	var boundary:=label("1839–1859  •  DEFERRED DLC FOUNDATION  •  synthetic:qualification  •  Not a playable historical campaign",14)
	boundary.add_theme_color_override("font_color",Color("dab980"));column.add_child(boundary)
	tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	var plan:=tab("Campaign contract")
	var intro:=panel(plan)
	intro.add_child(label("From the succession to the postwar settlement",22))
	intro.add_child(label("The full Ranjit Singh narrative remains first. These linked chapters preserve earlier anthology modules, shared places and the Bar uprising; none is advertised as completed gameplay."))
	for i in range(manifest.chapters.size()):
		var chapter: Dictionary=manifest.chapters[i];var card:=panel(plan)
		card.add_child(label("%02d   %s   /   %d–%d" % [i+1,chapter.title,int(chapter.editorial_years[0]),int(chapter.editorial_years[1])-1],20))
		card.add_child(label("Proposed player actions: "+", ".join(chapter.verbs).replace("_"," ")))
		card.add_child(label("Shared places: "+", ".join(chapter.place_refs)+"  |  planned, not playable",14))
	var desk:=tab("Perspective test")
	var host_controls:=tab("Timeline / checkpoints")
	var host:=panel(host_controls)
	host.add_child(label("AUTHORING CONTROLS — not a character's knowledge",14))
	timeline_label=label("",18);host.add_child(timeline_label)
	clock_label=label("",14);host.add_child(clock_label)
	var host_buttons:=GridContainer.new();host_buttons.columns=2;host.add_child(host_buttons)
	button("anchor","Advance historical anchor",advance_anchor,host_buttons)
	button("close","Check settlement / close",func(): command("host","close"),host_buttons)
	button("checkpoint","Keep in-memory checkpoint",keep_checkpoint,host_buttons)
	button("restore","Restore whole checkpoint",restore_checkpoint,host_buttons)
	var card:=panel(desk)
	card.add_child(label("One shared road. Three limited perspectives.",22))
	card.add_child(label("Original unnamed role fixtures. No battle, town, historical person, physical courier journey or production save is simulated here.",14))
	role_picker=choices(Rules.ROLES,card)
	role_picker.item_selected.connect(func(index: int): role=Rules.ROLES[index];refresh())
	notebook=RichTextLabel.new();notebook.bbcode_enabled=false;notebook.fit_content=true
	notebook.custom_minimum_size.y=80;notebook.selection_enabled=true;card.add_child(notebook)
	status_label=label("",16);status_label.add_theme_color_override("font_color",Color("dab980"));card.add_child(status_label)
	var actions:=GridContainer.new();actions.columns=2;card.add_child(actions)
	button("observe","Observe the shared road",func(): command(role,"observe"),actions)
	button("receive","Receive an arrived report",func(): command(role,"receive"),actions)
	recipient=choices(Rules.ROLES,actions);recipient.select(2)
	button("send","Send own observation",func(): command(role,"send",Rules.ROLES[recipient.selected]),actions)
	disposition=choices(["dispersed","detained","left_region"],actions)
	button("muster","Rebel role: record disposition",func(): command(role,"muster",["dispersed","detained","left_region"][disposition.selected]),actions)
	button("inspect_road","Company role: inspect / reopen",func(): command(role,"inspect_road"),actions)
	button("market","Resident: make market delivery",func(): command(role,"market"),actions)
	household=choices(["returned","displaced","missing"],actions)
	button("household","Resident: record household",func(): command(role,"household",["returned","displaced","missing"][household.selected]),actions)
	closure_label=label("",16);host.add_child(closure_label)
	button("reset","Reset qualification fixture (not the main game)",reset,desk)
	var research:=tab("Evidence boundary")
	var note:=panel(research)
	note.add_child(label("An attributed story is not an identity merge.",22))
	note.add_child(label("1859-07-08 is the working formal-peace closing anchor from a secondary chronology; the original proclamation has not been independently inspected. Delhi's capture in 1857, the 1858 statute and the November proclamation remain separate events."))
	note.add_child(label("Bikrama Singh's armed rising is not silently moved from 1848–49 into 1857. Thakur Singh's alleged Ballabhgarh operations and Sampuran Singh's specific 1857 activity remain research leads. Koot Hoomi is not merged with Thakur Singh."))
	note.add_child(label("Religious figures remain unembodied; religious sites remain exterior-only. 1867 Mentana, the separate 1873 epilogue and later Blavatsky/Duleep material are retained outside this DLC."))
	for claim in manifest.claims:
		var box:=panel(research);box.add_child(label(str(claim.id).replace("_"," ").capitalize()+" / "+claim.status,18))
		box.add_child(label(claim.summary));box.add_child(label(claim.constraint,14))
	tabs.current_tab=1

func command(actor: String, action: String, value: String="") -> void:
	var result:=Rules.append(state,actor,action,value,tick)
	if result.error.is_empty():
		state=result.state;status_label.text="Recorded: "+action.replace("_"," ")+"."
	else: status_label.text="Refused: "+result.error
	refresh()

func advance_anchor() -> void:
	var index: int=state.world.anchors.size()
	if index>=Rules.ANCHORS.size(): status_label.text="All three closing anchors are already recorded.";return
	command("host","anchor",Rules.ANCHORS[index])

func keep_checkpoint() -> void:
	checkpoint=state.duplicate(true);status_label.text="Whole-state checkpoint retained in memory; no player save was written."

func restore_checkpoint() -> void:
	var restored:=Rules.restore(checkpoint)
	if not restored.error.is_empty(): status_label.text="Refused: no valid whole-state checkpoint.";return
	state=restored.state;tick=int(state.tick)
	status_label.text="Restored: later world changes, reports and knowledge are gone.";refresh()

func refresh() -> void:
	var view:=Rules.view(state,role)
	var lines: Array[String]=["RECEIVED NOTEBOOK / "+role.replace("_"," ").to_upper()]
	for item in view.get("observations",[]):
		lines.append("%s | tick %d | origin %s | road %s" % [item.id,int(item.tick),item.origin,"open" if item.road_open else "not yet open"])
	if view.get("observations",[]).is_empty(): lines.append("No observations received. Another character's knowledge is not yours.")
	for key in view.get("personal",{}): lines.append(str(key)+": "+str(view.personal[key]))
	notebook.text="\n".join(lines)
	timeline_label.text="Editorial date: %s   /   %d of 3 closing anchors" % [state.world.date,state.world.anchors.size()]
	closure_label.text="SETTLEMENT RECORDED. Loss and opposed memories remain." if state.world.closed else "OPEN: formal peace + road inspection + disposition + delivery + household account."
	clock_label.text="AUTHORING CLOCK  %d ticks / 60 Hz   |   %d / 64 receipts" % [tick,state.history.size()]
