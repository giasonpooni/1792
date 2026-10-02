# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Isolated inspection clock and ledger. Not a second authority in the Home campaign.
const Craft := preload("res://workshops/workshop_rules.gd")
const Economy := preload("res://territory/misl_rules.gd")
const BakedSmith := preload("res://workcells/baked_smith.gd")
@export var baked := false
var ledger: Dictionary=Economy.initial()
var tick := 0
var running := true
var message := "E: reserve fuel; E at next step: hand over; wait for tools."

func _ready() -> void:
	if not baked: construct()
	get_node("Camera").current=true
	project_state()

func construct() -> void:
	name="SmithInspection"
	var avatar:=Node3D.new();avatar.name="Avatar";avatar.position=Craft.SITE+Vector3(2.8,0,1.7);add_child(avatar)
	var station:=BakedSmith.new();station.name="Workshop";add_child(station)
	station.prepare(avatar);station.name="Workshop"
	var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(18,16)
	var floor_node:=MeshInstance3D.new();floor_node.name="Ground";floor_node.mesh=floor_mesh;floor_node.position=Craft.SITE-Vector3(0,0.03,0)
	var earth:=StandardMaterial3D.new();earth.albedo_color=Color("b49b77");earth.roughness=0.98;floor_node.material_override=earth;add_child(floor_node)
	var light:=DirectionalLight3D.new();light.name="Sun";light.rotation_degrees=Vector3(-48,-28,0);light.light_energy=1.25;light.shadow_enabled=true;add_child(light)
	var environment_node:=WorldEnvironment.new();environment_node.name="Environment"
	var environment_resource:=Environment.new();environment_resource.background_mode=Environment.BG_COLOR;environment_resource.background_color=Color("b9c9d1")
	environment_resource.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment_resource.ambient_light_color=Color("d5d9d8");environment_resource.ambient_light_energy=0.6
	environment_resource.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment_node.environment=environment_resource;add_child(environment_node)
	var camera:=Camera3D.new();camera.name="Camera";camera.position=Craft.SITE+Vector3(5.7,3.25,-6.5);camera.fov=53;camera.far=80;add_child(camera)
	camera.look_at(Craft.SITE+Vector3(-0.5,1.18,0.1))
	var ui:=CanvasLayer.new();ui.name="UI";add_child(ui)
	var label:=Label.new();label.name="Caption";label.position=Vector2(16,12);label.add_theme_font_size_override("font_size",15)
	label.add_theme_color_override("font_color",Color("fff0d0"));label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);ui.add_child(label)
	baked=true

func action(kind: String) -> String:
	var error: String=Craft.apply(ledger,"smith."+kind,str(tick))
	message=error if not error.is_empty() else "Action: "+kind
	project_state()
	return error

func step() -> void:
	tick+=1
	if Craft.phase(ledger)=="working" and tick==int(ledger.workshop.started_tick)+Craft.WORK_TICKS:
		var error: String=Craft.apply(ledger,"smith.ready",str(tick))
		if not error.is_empty(): push_error(error)
	project_state()

func project_state() -> void:
	var station=get_node("Workshop")
	station.sample(tick,Craft.phase(ledger),int(ledger.workshop.started_tick) if ledger.has("workshop") else -1)
	get_node("UI/Caption").text="1792 · Smith production inspection\nOriginal fictional site / prototype art / isolated ledger\nE: advance task   Space: pause   R: reset   L: lighting\n%s · tick %d · household %d · tools %d\n%s" % [Craft.phase(ledger),tick,ledger.treasury,ledger.stock.tools,message]

func lighting(evening: bool) -> void:
	get_node("Sun").light_color=Color("ffd49b") if evening else Color.WHITE
	get_node("Sun").light_energy=0.9 if evening else 1.25
	get_node("Environment").environment.ambient_light_energy=0.38 if evening else 0.6

func _physics_process(_delta: float) -> void:
	if running: step()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_SPACE: running=not running
		KEY_R: ledger=Economy.initial();tick=0;message="Reset inspection ledger.";project_state()
		KEY_L: lighting(get_node("Sun").light_color==Color.WHITE)
		KEY_E:
			var next={"unassigned":"reserve","fuel":"start","ready":"collect","tools":"deliver"}.get(Craft.phase(ledger),"")
			if not next.is_empty(): action(next)
