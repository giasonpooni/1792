# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Scene-only costume and handling projection, sampled from existing observations.
## No clocks, stepping, collision, inventory, save or historical authority live here.
## Reload gestures are authored readability cues, not a firearm operating sequence.
const Kit := preload("res://presentation/workshop_kit.gd")
const MUZZLE_LOCAL := Vector3(0, 0, -.85)
const RELOAD_TICKS := 180.0
# Costume palette continuity only; these are authored colors, not age or likeness.
# The Home profile reuses tools/art/build_courtyard.py child() display palette.
const PALETTES := {
	"horsecraft-study": {"tunic":"748495", "trousers":"586575", "sash":"a58152",
		"headwrap":"526c87", "wrap_light":"637d95", "wrap_dark":"48617c",
		"skin":"a67f5d", "hair":"373229", "eyes":"373229", "leather":"40372f", "boot_upper":"4b4035"},
	"childhood-home": {"tunic":"b3aa8d", "trousers":"667271", "sash":"61766e",
		"headwrap":"b3aa8d", "wrap_light":"bdb59e", "wrap_dark":"a49b82",
		"skin":"b18a69", "hair":"382a20", "eyes":"292523", "leather":"514032", "boot_upper":"514032"}}
var palette_identity := "horsecraft-study"
var _palette: Dictionary = {}
var _palette_materials: Dictionary = {}
var kit: RefCounted
var body: MeshInstance3D
var head: MeshInstance3D
var turban: MeshInstance3D
var weapon_mount: Node3D
var storage: Node3D
var boots: Array[Node3D] = []
var hands: Array[Node3D] = []
var upper_legs: Array[MeshInstance3D] = []
var lower_legs: Array[MeshInstance3D] = []
var upper_arms: Array[MeshInstance3D] = []
var lower_arms: Array[MeshInstance3D] = []
var knees: Array[MeshInstance3D] = []
var elbows: Array[MeshInstance3D] = []
var weapons: Array[Node3D] = []
var charge_markers: Array[MeshInstance3D] = []
var rear_cloth: MeshInstance3D
var sash: MeshInstance3D
var neck: MeshInstance3D
var face_parts: Array[MeshInstance3D] = []
var wrap_bands: Array[MeshInstance3D] = []
var rein_mesh: MeshInstance3D
var equipped := true
var _built := false
var _pose: Dictionary = {}
var _reins: Dictionary = {}
var _slot := 0

func configure(shared_kit: RefCounted = null, palette_profile: String = "horsecraft-study") -> void:
	if _built: return
	_built = true
	kit = shared_kit if shared_kit != null else Kit.new()
	palette_identity = palette_profile if PALETTES.has(palette_profile) else "horsecraft-study"
	_palette = PALETTES[palette_identity].duplicate(true)
	name = "ObservedHorsecraftRider"
	set_meta("classification", "scene-only-rider-presentation")
	set_meta("historical_authentication", false)
	set_meta("owns_clock", false)
	set_meta("palette_identity", palette_identity)
	set_process(false)
	set_physics_process(false)
	var cloth: Material = kit.surface(_palette.tunic, 4)
	var trousers: Material = kit.surface(_palette.trousers, 4)
	var skin: Material = kit.plain(_palette.skin)
	var hair: Material = kit.plain(_palette.hair)
	var eyes: Material = kit.plain(_palette.eyes)
	var sash_material: Material = kit.surface(_palette.sash, 4)
	var wrap: Material = kit.surface(_palette.headwrap, 4)
	var leather: Material = kit.plain(_palette.leather)
	_palette_materials = {"tunic":cloth, "trousers":trousers, "sash":sash_material, "headwrap":wrap, "skin":skin, "hair":hair, "eyes":eyes, "leather":leather}
	body = kit.ellipsoid(self, Vector3.ZERO, Vector3(.53, .70, .36), cloth)
	body.name = "RoundedTorso"
	rear_cloth = kit.ellipsoid(self, Vector3.ZERO, Vector3(.59, .30, .40), cloth)
	sash = kit.ellipsoid(self, Vector3.ZERO, Vector3(.55, .105, .38), sash_material)
	neck = kit.ellipsoid(self, Vector3.ZERO, Vector3(.15, .20, .15), skin)
	head = kit.ellipsoid(self, Vector3.ZERO, Vector3(.265, .325, .265), skin)
	head.name = "RoundedHead"
	turban = kit.ellipsoid(self, Vector3.ZERO, Vector3(.355, .245, .34), wrap)
	turban.name = "WrappedTurban"
	for i in range(3):
		var band: MeshInstance3D = kit.ellipsoid(self, Vector3.ZERO, Vector3(.36 - i * .024, .05, .345 - i * .023), kit.surface(_palette.wrap_light if i % 2 == 0 else _palette.wrap_dark, 4))
		wrap_bands.append(band)
	# Restrained face landmarks aid silhouette/readability without a likeness claim.
	face_parts.append(kit.ellipsoid(self, Vector3.ZERO, Vector3(.065, .075, .07), skin))
	face_parts.append(kit.ellipsoid(self, Vector3.ZERO, Vector3(.19, .105, .065), hair))
	# Keep the attributed adult study landmark separate from the child costume.
	face_parts[1].visible = palette_identity != "childhood-home"
	for side in [-1.0, 1.0]:
		face_parts.append(kit.ellipsoid(self, Vector3.ZERO, Vector3(.037, .018, .018), eyes))
	for side in range(2):
		upper_legs.append(_segment(.092, trousers))
		lower_legs.append(_segment(.074, trousers))
		upper_arms.append(_segment(.074, cloth))
		lower_arms.append(_segment(.054, skin))
		knees.append(kit.ellipsoid(self, Vector3.ZERO, Vector3(.18, .18, .18), trousers))
		elbows.append(kit.ellipsoid(self, Vector3.ZERO, Vector3(.125, .125, .125), cloth))
		var boot := Node3D.new(); boot.name = "ObservedFootAnchor%d" % side; add_child(boot); boots.append(boot)
		kit.ellipsoid(boot, Vector3(0, .068, -.065), Vector3(.21, .135, .34), leather)
		kit.ellipsoid(boot, Vector3(0, .14, .025), Vector3(.16, .20, .17), kit.plain(_palette.boot_upper))
		var hand := Node3D.new(); hand.name = "VisibleGrip%d" % side; add_child(hand); hands.append(hand)
		kit.ellipsoid(hand, Vector3.ZERO, Vector3(.105, .14, .085), skin)
		kit.ellipsoid(hand, Vector3(-.046 if side == 0 else .046, -.012, -.035), Vector3(.045, .075, .05), skin)
		for j in range(3):
			kit.ellipsoid(hand, Vector3((j - 1) * .027, -.041, -.03), Vector3(.022, .075, .05), skin)
	weapon_mount = Node3D.new(); weapon_mount.name = "SelectedMatchlockMount"; add_child(weapon_mount)
	storage = Node3D.new(); storage.name = "ThreeSeparateStoredMatchlocks"; add_child(storage)
	for i in range(4): weapons.append(_build_weapon(i))
	rein_mesh = MeshInstance3D.new(); rein_mesh.name = "ObservedBridleToGripReins"; add_child(rein_mesh)
	rein_mesh.material_override = kit.plain("514333")
	set_equipped(equipped)

func _segment(radius: float, material: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * .88; shape.bottom_radius = radius; shape.height = 1.0; shape.radial_segments = 12
	return kit.mesh_at(self, shape, Vector3.ZERO, material)

func _build_weapon(slot: int) -> Node3D:
	var node := Node3D.new(); node.name = "SeparateMatchlock%d" % (slot + 1); storage.add_child(node)
	var woods: Array[String] = ["72543c", "665039", "805a3c", "705647"]
	var metals: Array[String] = ["454443", "555047", "3b4042", "585246"]
	var wood: Material = kit.surface(woods[slot], 2)
	var metal: Material = kit.plain(metals[slot], .18)
	# Distinct butt/stock forms share the established functional muzzle anchor.
	var stock: MeshInstance3D = kit.ellipsoid(node, Vector3(0, -.015, .10), Vector3(.115 + slot * .008, .13, .61 - slot * .018), wood)
	stock.rotation.x = .045 * (slot - 1)
	var butt: MeshInstance3D = kit.ellipsoid(node, Vector3(0, -.04 - slot * .008, .365), Vector3(.115 + slot * .014, .17 + slot * .014, .13), wood)
	butt.rotation.z = (slot - 1) * .025
	kit.rod(node, Vector3(0, 0, -.13), MUZZLE_LOCAL, .022 + slot * .001, metal)
	kit.rod(node, Vector3(0, -.025, -.15), Vector3(0, -.025, -.63 + slot * .035), .03, wood)
	for band_index in range(2 + slot % 2):
		var z := -.20 - band_index * (.22 - slot * .015)
		kit.rod(node, Vector3(-.039, 0, z), Vector3(.039, 0, z), .014, kit.plain("9b8c68", .22))
	# A small abstract lock/cord silhouette, without operating geometry.
	kit.ellipsoid(node, Vector3(.055, -.018, -.03), Vector3(.035, .065, .13), metal)
	kit.rod(node, Vector3(.049, -.005, -.05), Vector3(.063, .073, -.09), .011, kit.plain("897659"))
	var charge_marker: MeshInstance3D = kit.ellipsoid(node, Vector3(-.058, .018, .17), Vector3(.025, .075, .105), kit.plain("a99b65"))
	charge_marker.name = "AuthoredChargeStatusCue"
	charge_markers.append(charge_marker)
	node.set_meta("weapon_identity", "horsecraft-study-slot-%d" % (slot + 1))
	var marker := Marker3D.new(); marker.name = "EstablishedMuzzleEndpoint"; marker.position = MUZZLE_LOCAL; node.add_child(marker)
	return node

func set_equipped(value: bool) -> void:
	equipped = value
	if not _built: return
	weapon_mount.visible = value
	storage.visible = value
	for node in weapons: node.visible = value

func sample(snapshot: Dictionary, standing_blend: float, aim_yaw: float, aim_pitch: float,
		actual_centers: Array[Vector3], foot_points: Array[Vector3], horse_yaws: Array[float],
		shot_tick: int = -1, bridle_points: Array[Vector3] = []) -> void:
	if not _built: configure()
	if actual_centers.is_empty() or foot_points.size() < 2 or horse_yaws.is_empty(): return
	var blend := clampf(standing_blend, 0.0, 1.0)
	var eased := blend * blend * (3.0 - 2.0 * blend)
	var center_right: Vector3 = actual_centers[1] if actual_centers.size() > 1 else actual_centers[0]
	var midpoint := (actual_centers[0] + center_right) * .5
	global_position = actual_centers[0].lerp(midpoint, eased)
	global_basis = Basis(Vector3.UP, horse_yaws[0])
	var sway := clampf(float(snapshot.get("sway", 0.0)), -1.0, 1.0)
	var pelvis := Vector3(sway * .16, lerpf(1.87, 2.49, eased), .13)
	body.position = pelvis + Vector3(0, .31, 0)
	body.rotation = Vector3(lerpf(.065, -.035, eased), 0, -sway * .10)
	rear_cloth.position = pelvis + Vector3(0, .05, .025)
	rear_cloth.rotation.z = -sway * .06
	sash.position = pelvis + Vector3(0, .105, 0)
	neck.position = pelvis + Vector3(0, .68, -.007)
	head.position = pelvis + Vector3(0, .855, -.017)
	head.rotation = Vector3(aim_pitch * .12 if equipped else 0.0, aim_yaw * .22 if equipped else 0.0, -sway * .035)
	turban.position = head.position + Vector3(0, .16, .015)
	turban.rotation = head.rotation
	for i in range(wrap_bands.size()):
		wrap_bands[i].position = turban.position + Vector3(0, -.075 + i * .045, -.002)
		wrap_bands[i].rotation = head.rotation + Vector3(0, 0, -.12 + i * .04)
	var facial_offsets: Array[Vector3] = [Vector3(0, .006, -.135), Vector3(0, -.08, -.119), Vector3(-.06, .057, -.124), Vector3(.06, .057, -.124)]
	for i in range(face_parts.size()):
		face_parts[i].position = head.position + head.basis * facial_offsets[i]
		face_parts[i].rotation = head.rotation
	var foot_world: Array[Vector3] = []
	for i in range(2):
		var sign_value := -1.0 if i == 0 else 1.0
		var seated_foot := Vector3(sign_value * .43, 1.12, .14)
		var anchor := to_local(foot_points[i])
		var foot := seated_foot.lerp(anchor, eased)
		boots[i].position = foot
		boots[i].rotation.y = wrapf(horse_yaws[mini(i, horse_yaws.size() - 1)] - horse_yaws[0], -PI, PI) * eased
		var hip := pelvis + Vector3(sign_value * .16, -.015, 0)
		var ankle := foot + Vector3.UP * .14
		var knee := hip.lerp(ankle, .54) + Vector3(sign_value * .07, -.04, -.16 * (1.0 - eased) - .035)
		_pose_limb(upper_legs[i], hip, knee); _pose_limb(lower_legs[i], knee, ankle)
		knees[i].position = knee
		foot_world.append(boots[i].global_position)
	_slot = clampi(int(snapshot.get("selected_slot", 0)), 0, 3)
	var reload_active := int(snapshot.get("reload_slot", -1)) >= 0
	var progress := clampf(float(snapshot.get("reload_ticks", 0)) / RELOAD_TICKS, 0.0, 1.0) if reload_active else 0.0
	var tick := int(snapshot.get("tick", 0))
	var recoil_age := tick - shot_tick
	var recoil := (1.0 - float(recoil_age) / 12.0) if shot_tick >= 0 and recoil_age >= 0 and recoil_age < 12 else 0.0
	var reload_weight := sin(progress * PI) if reload_active else 0.0
	weapon_mount.position = pelvis + Vector3(.22, .45, -.23 + recoil * .045)
	weapon_mount.rotation = Vector3(aim_pitch - recoil * .075, aim_yaw, 0).lerp(Vector3(.26, -.24, -.23), reload_weight * .72)
	for i in range(4):
		var parent_node: Node3D = weapon_mount if i == _slot else storage
		if weapons[i].get_parent() != parent_node: weapons[i].reparent(parent_node, false)
		if i == _slot:
			weapons[i].position = Vector3.ZERO; weapons[i].rotation = Vector3.ZERO
		else:
			var stored_index := i if i < _slot else i - 1
			weapons[i].position = pelvis + Vector3(-.24 + stored_index * .16, .25, .23)
			weapons[i].rotation = Vector3(.38 + stored_index * .035, .04 * (i - 1), .10 * (stored_index - 1))
		weapons[i].visible = equipped
		var charged: bool = snapshot.get("slots", [true, true, true, true])[i]
		charge_markers[i].material_override = kit.plain("a99b65" if charged else "453d35")
	var grips: Array[Vector3] = []
	if equipped:
		grips = [to_local(weapon_mount.to_global(Vector3(0, -.045, -.35))), to_local(weapon_mount.to_global(Vector3(.025, -.08, .09)))]
		if reload_active:
			# Abstract sampled reach/work/return gesture: no autonomous animation clock.
			var path: Array[Vector3] = [grips[1], pelvis + Vector3(.33, .16, -.12), pelvis + Vector3(.23, .49, -.43), grips[1]]
			var path_segment := mini(int(progress * 3.0), 2)
			var phase := clampf(progress * 3.0 - path_segment, 0.0, 1.0)
			var smooth_phase := phase * phase * (3.0 - 2.0 * phase)
			grips[1] = path[path_segment].lerp(path[path_segment + 1], smooth_phase)
	else:
		grips = [pelvis + Vector3(-.18, .24, -.31), pelvis + Vector3(.18, .24, -.31)]
	for i in range(2):
		var sign_value := -1.0 if i == 0 else 1.0
		var shoulder := pelvis + Vector3(sign_value * .245, .55, -.005)
		var elbow := shoulder.lerp(grips[i], .54) + Vector3(sign_value * .095, -.10, .045)
		_pose_limb(upper_arms[i], shoulder, elbow); _pose_limb(lower_arms[i], elbow, grips[i])
		elbows[i].position = elbow; hands[i].position = grips[i]
		hands[i].rotation = weapon_mount.rotation if equipped else Vector3(-.28, sign_value * .16, 0)
	_sample_reins(actual_centers, horse_yaws, bridle_points, equipped)
	_pose = {"classification": "sampled-presentation-only", "tick": tick, "stance": snapshot.get("stance", "seated"),
		"standing_blend": blend, "eased_blend": eased, "selected_slot": _slot, "equipped": equipped,
		"foot_world": foot_world, "support_world": foot_points.duplicate(), "reload_progress": progress,
		"reload_cue": _reload_cue(progress) if reload_active else "none", "reload_paused": snapshot.get("reload_paused", false),
		"weapon_identity": weapons[_slot].get_meta("weapon_identity"),
		"stored_weapon_identities": _stored_identities(), "charges": snapshot.get("slots", [true, true, true, true]).duplicate(),
		"reload_active": reload_active, "reload_slot": snapshot.get("reload_slot", -1), "reload_ticks": snapshot.get("reload_ticks", 0),
		"grip_world": [hands[0].global_position, hands[1].global_position],
		"recoil": recoil, "muzzle_world": active_muzzle_world(), "shoulder_world": shoulder_world()}

func _pose_limb(mesh: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	mesh.position = (a + b) * .5
	mesh.scale = Vector3(1, maxf(a.distance_to(b), .001), 1)
	mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized()) if a.distance_to(b) > .000001 else Quaternion.IDENTITY

func _reload_cue(progress: float) -> String:
	if progress < 1.0 / 3.0: return "reach"
	if progress < 2.0 / 3.0: return "work"
	return "return"

func _sample_reins(centers: Array[Vector3], yaws: Array[float], supplied: Array[Vector3], aiming: bool) -> void:
	var horse_count := mini(centers.size(), yaws.size())
	var supplied_exact := supplied.size() == horse_count * 2
	var anchors: Array[Vector3] = []
	for i in range(horse_count):
		for sign_value in [-1.0, 1.0]:
			var index := i * 2 + (0 if sign_value < 0 else 1)
			anchors.append(supplied[index] if supplied_exact else centers[i] + Basis(Vector3.UP, yaws[i]) * Vector3(sign_value * .22, 1.85, -1.32))
	var grip_world: Array[Vector3] = []
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(anchors.size()):
		# Firing/handling visibly gathers the reins in the forward supporting grip.
		# This is a presentation of held/loose leather, never a steering executor.
		var grip := hands[0].global_position if aiming else hands[i % 2].global_position
		grip_world.append(grip)
		var previous: Vector3 = to_local(anchors[i])
		for j in range(1, 9):
			var phase := float(j) / 8.0
			var point := anchors[i].lerp(grip, phase) - Vector3.UP * sin(phase * PI) * (.12 if aiming else .065)
			var local_point := to_local(point)
			mesh.surface_add_vertex(previous); mesh.surface_add_vertex(local_point); previous = local_point
	mesh.surface_end()
	rein_mesh.mesh = mesh
	_reins = {"classification": "sampled-bridle-to-grip-presentation", "horse_count": horse_count,
		"source": "supplied-observed-bridle-anchors" if supplied_exact else "current-horse-mesh-anchor-fallback",
		"anchors": anchors, "grips": grip_world, "held_with_supporting_hand": aiming, "owns_steering": false}

func _stored_identities() -> Array[String]:
	var identities: Array[String] = []
	for i in range(weapons.size()):
		if i != _slot: identities.append(weapons[i].get_meta("weapon_identity"))
	return identities

func shoulder_world() -> Vector3:
	return to_global(body.position + Vector3(.25, .12, 0))

func active_muzzle_world() -> Vector3:
	return weapon_mount.to_global(MUZZLE_LOCAL)

func visible_foot_points() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for boot in boots: result.append(boot.global_position)
	return result

func weapon_observation() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for i in range(weapons.size()):
		var charged: bool = _pose.get("charges", [true, true, true, true])[i]
		var marker_material: StandardMaterial3D = charge_markers[i].material_override
		records.append({"slot": i, "weapon_identity": weapons[i].get_meta("weapon_identity"),
			"instance_id": weapons[i].get_instance_id(), "parent_instance_id": weapons[i].get_parent().get_instance_id(),
			"role": "unequipped" if not equipped else "selected" if i == _slot else "stored",
			"charged": charged, "visible": weapons[i].visible and equipped,
			"charge_marker_color": marker_material.albedo_color.to_html(false)})
	return records

func palette_observation() -> Dictionary:
	var material_ids: Dictionary = {}
	var colors: Dictionary = {}
	for key in _palette_materials:
		var material: Material = _palette_materials[key]
		material_ids[key] = material.get_instance_id()
		var color: Color = material.get_shader_parameter("pigment") if material is ShaderMaterial else material.albedo_color
		colors[key] = color.to_html(false)
	return {"classification":"authored-costume-palette-continuity", "profile":palette_identity,
		"colors":colors, "material_ids":material_ids, "visible_facial_hair":face_parts[1].visible, "historical_authentication":false}

func pose_observation() -> Dictionary:
	return _pose.duplicate(true)

func rein_observation() -> Dictionary:
	return _reins.duplicate(true)
