# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://workshops/workshop_world.gd"
## Bakes the existing workshop presentation without inventing production rules.
@export var baked := false
@export var arm_path: NodePath
@export var coal_path: NodePath
@export var finished_path: NodePath
@export var carried_path: NodePath
@export var audio_path: NodePath

func prepare(avatar: Node3D) -> void:
	build(avatar)
	arm_path=get_path_to(smith_arm);coal_path=get_path_to(coal)
	finished_path=get_path_to(finished);carried_path=get_path_to(carried)
	audio_path=get_path_to(hammer_audio)
	baked=true

func _ready() -> void:
	if not baked: return
	smith_arm=get_node(arm_path);coal=get_node(coal_path)
	finished=get_node(finished_path);carried=get_node(carried_path)
	hammer_audio=get_node(audio_path)
	# Serialized materials, rather than replacement materials, receive the same tick.
	kit.cloth_materials.clear()
	for node in find_children("*","MeshInstance3D",true,false):
		var material: Material=node.material_override
		if material is ShaderMaterial and material.shader.resource_path=="res://presentation/canopy.gdshader":
			kit.cloth_materials.append(material)
	sample(0,"unassigned",-1)
