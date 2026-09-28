extends Node3D
## Collision adapters and cached navigation only. Campaign remains state authority.
const Agent := preload("res://patrol/patrol_agent.gd")
const Navigation := preload("res://patrol/patrol_navigator.gd")
const Rules := preload("res://patrol/companion_rules.gd")
var navigator := Navigation.new()
var members: Dictionary = {}
var captain: CharacterBody3D
var avatar: CharacterBody3D
var horse: CharacterBody3D

func setup(player: CharacterBody3D, mount: CharacterBody3D) -> void:
	avatar = player
	horse = mount
	navigator.bind(get_world_3d(), [avatar.get_rid(), horse.get_rid()])

func sync(model, force: bool = false) -> void:
	var p: Dictionary = model.companion_state()
	var wanted: Array = []
	for record in p.get("members", []):
		wanted.append(record.id)
		if not members.has(record.id):
			var body = _agent(record.id)
			body.caption.text = "Trooper %d" % (members.size() + 1)
			members[record.id] = body
			body.apply(record)
		elif force:
			members[record.id].apply(record)
	for id in members.keys():
		if id not in wanted:
			members[id].queue_free()
			members.erase(id)
	if not model.has_companions():
		if is_instance_valid(captain):
			captain.hide()
		return
	if not is_instance_valid(captain):
		captain = _agent("patrol_captain")
		captain.caption.text = "Patrol captain"
		force = true
	captain.visible = model.actor_id() != "patrol_captain"
	if force or not captain.visible or model.snapshot().order.mode != "delegated":
		captain.global_position = model.actor_position("patrol_captain")
		captain.velocity = Vector3.ZERO

func _agent(id: String) -> CharacterBody3D:
	var body = Agent.new()
	body.name = id.replace(".", "_")
	body.entity_id = id
	add_child(body)
	# Friendly units use trailing offsets, not player-blocking capsule crowds.
	body.add_collision_exception_with(avatar)
	body.add_collision_exception_with(horse)
	return body

func step(model, delta: float) -> String:
	sync(model)
	if not model.has_companions() or model.snapshot().order.status != "active":
		return ""
	var s: Dictionary = model.snapshot()
	var p: Dictionary = s.companions
	if s.order.mode == "delegated":
		var target: Vector3 = model.patrol_destination()
		var next := navigator.waypoint(captain.position, target)
		var moving := Rules.horizontal(captain.position, target) > 0.65
		var motion: Dictionary = captain.step(delta, next, moving)
		var error: String = model.record_patrol_motion("patrol_captain", motion, delta)
		if not error.is_empty():
			captain.position = model.actor_position("patrol_captain")
			return error
	var leader: Vector3 = model.actor_position("patrol_captain")
	for i in range(p.members.size()):
		var record: Dictionary = p.members[i]
		var body: CharacterBody3D = members[record.id]
		# Small stable trail formation in world coordinates. No cavalry formation claim.
		var target: Vector3 = leader + Rules.OFFSETS[i]
		var follow: bool = p.instruction == "follow" and Rules.horizontal(body.position, target) > 0.65
		var next := navigator.waypoint(body.position, target) if follow else body.position
		var motion: Dictionary = body.step(delta, next, follow)
		var error: String = model.record_patrol_motion(record.id, motion, delta)
		if not error.is_empty():
			body.apply(record)
			return error
	return ""

func snapshot_fits(candidate: Dictionary) -> bool:
	if not candidate.has("companions"):
		return true
	for record in candidate.companions.members:
		if not navigator.fits(record):
			return false
	# Do not instantiate a delegated captain inside a wall after a legacy import.
	return navigator.fits({"position": candidate.actors.patrol_captain.position})
