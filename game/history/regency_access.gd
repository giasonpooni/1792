# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Derived access and presentation for one authored visit. The retained story
## model owns all decisions; this helper stores no supply or permission counters.
var visit: Node3D
var screen_barrier: StaticBody3D
var sacks: Array[Node3D] = []
var receipt: Node3D
var account_label: Label3D
const HEARING := Vector3(0, 0, -6)
const VOICE := Vector3(0, 1.4, -9.5)

func _init(owner_visit: Node3D) -> void:
	visit = owner_visit

func build() -> void:
	var stage: Node3D = visit._stage
	var clay := Color("9d805e")
	var cloth := Color("536f6c")
	# This closed pavilion is an authored privacy boundary, not a universal rule
	# about elite women or a reconstruction of an identifiable historical room.
	screen_barrier = visit._box(stage, Vector3(6, 4.5, 0.16), Vector3(0, 2.25, -7.8), cloth, true)
	screen_barrier.name = "AudienceScreen"
	for x in [-3.1, 3.1]:
		visit._box(stage, Vector3(0.3, 4.5, 5.6), Vector3(x, 2.25, -10.5), clay, true)
	visit._box(stage, Vector3(6.5, 4.5, 0.3), Vector3(0, 2.25, -13.2), clay, true)
	visit._box(stage, Vector3(6.5, 0.2, 5.6), Vector3(0, 4.55, -10.5), clay, true)
	for x in range(-5, 6):
		visit._box(stage, Vector3(0.04, 4.35, 0.025), Vector3(x * 0.5, 2.25, -7.69), cloth.darkened(0.13))
	visit._box(stage, Vector3(6.5, 0.18, 0.3), Vector3(0, 4.4, -7.65), Color("bd9e63"))
	# The public hearing mark stays outside the curtain; no concealed actor is
	# rendered or registered as an escort, and the objective never marks a bedroom.
	visit._box(stage, Vector3(2.3, 0.025, 1.4), HEARING + Vector3.UP * 0.02, Color("b9a77a"))
	for x in [-0.95, 0.95]:
		visit._box(stage, Vector3(0.04, 0.028, 1.2), HEARING + Vector3(x, 0.04, 0), Color("6b5d43"))
	var desk: Node3D = visit.stations.dispatch_table
	for i in range(4):
		var sack := Node3D.new()
		sack.name = "CountedGrain_%d" % i
		stage.add_child(sack)
		visit._oval(sack, Vector3(0, 0.27, 0), Vector3(0.42, 0.54, 0.55), Color("b19b70"))
		visit._cylinder(sack, Vector3(0, 0.55, 0), 0.055, 0.07, Color("6f6249"))
		sacks.append(sack)
	receipt = Node3D.new()
	receipt.name = "ReceivedDispatch"
	stage.add_child(receipt)
	visit._box(receipt, Vector3(0.28, 0.1, 0.19), Vector3.ZERO, Color("d5c5a0"))
	visit._box(receipt, Vector3(0.035, 0.11, 0.2), Vector3.ZERO, Color("8d463c"))
	account_label = Label3D.new()
	account_label.font_size = 18
	account_label.pixel_size = 0.006
	account_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	account_label.position = Vector3(0, 2.2, 0)
	desk.add_child(account_label)
	sync_visuals()

func audience_status() -> Dictionary:
	var flags: Dictionary = visit.model.flags
	return {"audience_granted": bool(flags.get("audience_granted", false)),
		"public_report": bool(flags.get("public_report", false)),
		"totals_open": bool(flags.get("totals_open", false)), "residence_entry": false}

func logistics_outcome() -> Dictionary:
	var flags: Dictionary = visit.model.flags
	var counted := 4 if flags.get("stock_counted", false) else 0
	var issued := 2 if flags.get("grain_issued", false) else 0
	return {"counted_bundles": counted, "issued_bundles": issued,
		"retained_bundles": counted - issued,
		"remount_requested": bool(flags.get("remount_requested", false)),
		"escort_requested": bool(flags.get("escort_requested", false)),
		"dispatch_received": bool(flags.get("dispatch_received", false)),
		"departure_witnessed": bool(flags.get("departure_witnessed", false)), "delivered": false}

func pose_allowed(at: Vector3) -> bool:
	# Reject forged checkpoint placements inside the permanently private room,
	# as well as relying on its real walls for ordinary motor collision.
	return not (absf(at.x) < 3.3 and at.z < -7.3 and at.z > -13.5)

func interaction_error(at: Vector3) -> String:
	if visit.model.current_beat().get("target", "") != "raj_screen": return ""
	var access := audience_status()
	if not access.audience_granted and not access.public_report:
		return "Ask the attendant to admit your report first."
	if at.z < -7.3: return "Address the hearing from the public side of the screen."
	var exclusions: Array[RID] = [visit.avatar.get_rid()]
	if is_instance_valid(visit.companion): exclusions.append(visit.companion.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.4, VOICE, 1, exclusions)
	var hit: Dictionary = visit.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.get("collider") != screen_barrier:
		return "Stand at the public hearing mark to address Raj Kaur."
	# Exempt exactly this screen from the acoustic path. Other walls, props or
	# bodies still block speech, including obstructions behind the curtain.
	exclusions.append(screen_barrier.get_rid())
	ray.exclude = exclusions
	if not visit.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		return "The hearing is obstructed; find a clear speaking place."
	return ""

func compose_camera(camera: Camera3D) -> void:
	camera.position = Vector3(3.7, 2.6, -2.3)
	camera.look_at(Vector3(0, 1.4, -7.5))

func sync_visuals() -> void:
	var outcome := logistics_outcome()
	var received: bool = outcome.dispatch_received
	var runner: Node3D = visit.actors.warband_runner
	for i in range(sacks.size()):
		var loaded: bool = received and outcome.issued_bundles > 0 and i < 2
		var parent: Node3D = runner if loaded else visit._stage
		if sacks[i].get_parent() != parent: sacks[i].reparent(parent, false)
		sacks[i].position = Vector3(-0.25 + i * 0.5, 0.7, 0.27) if loaded else visit.stations.dispatch_table.position + Vector3(1.55 + (i % 2) * 0.55, 0, -0.3 + (i / 2) * 0.7)
	if receipt.get_parent() != runner: receipt.reparent(runner, false)
	receipt.position = Vector3(0.32, 1, -0.18)
	receipt.visible = received
	account_label.text = "Four bundles await a witnessed count" if outcome.counted_bundles == 0 else "%d issued • %d retained\n%s" % [outcome.issued_bundles, outcome.retained_bundles, "Remount inspection requested" if outcome.remount_requested else "Grain account"]
	if outcome.issued_bundles > 0 and not received:
		account_label.text = "Two authorized • two reserved\nAwaiting the runner’s receipt"
	account_label.visible = not visit.paused
