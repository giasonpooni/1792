# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Catalog := preload("res://reconstruction/ecology_catalog.gd")
const Launch := preload("res://childhood/home_launch.gd")
var passed := 0
var failed := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("PUNJAB ECOLOGY: " + label)
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var values: Array = []
	for node in home.find_children("*", "CollisionShape3D", true, false):
		values.append([node.get_instance_id(), node.global_transform, node.shape.get_rid(), node.disabled, node.get_parent().collision_layer, node.get_parent().collision_mask])
	return values

func reject(original: Dictionary, edit: Callable, label: String) -> void:
	var bad := original.duplicate(true)
	edit.call(bad)
	check(not Catalog.validate(bad).is_empty(), "reject " + label)

func run() -> void:
	var catalog := Catalog.new()
	check(catalog.load_catalog().is_empty(), "load validated catalogue")
	var data: Dictionary = catalog.manifest
	var before := data.duplicate(true)
	check(Catalog.validate(data).is_empty() and data == before, "read-only validation")
	check(data.sources[1].publication_year == 1978 and data.sources[1].observation_period.start_year == 1961 and data.sources[1].observation_period.end_year == 1966, "Nair publication distinct from principal fieldwork")
	check(data.sources[2].observation_period.start_year == 1849 and data.sources[2].observation_period.end_year == 1947, "governance period retained")
	check(data.observations[0].observation_date.start_year == 1839 and data.observations[1].observation_date.start_year == 1839, "Barr observations dated independently of reconstruction")
	check(data.taxonomic_corrections[0].original_wording == "willow azadirachta indica" and data.taxonomic_corrections[0].corrected_common_name == "neem", "both original and corrected names retained")
	check(data.evidence_issues[0].reported_publication_year == 1918 and data.evidence_issues[0].catalogued_publication_year == 1916, "chronology conflict retained")
	for placement in data.placements:
		var evidence := catalog.placement_evidence(placement.id)
		check(not evidence.evidence.is_empty() and evidence.reconstruction_decision.target_year == 1792, "placement resolves a dated evidence chain")
		evidence.evidence[0].observation.observation_date.start_year = 1792
		evidence.reconstruction_decision.canonical_admission = true
		check(data == before, "inspection returns detached records")
	check(catalog.placement_evidence("missing").is_empty(), "unknown placement yields no evidence")
	for case in [null, [], {}, {"schema":"survey"}]: check(not Catalog.validate(case).is_empty(), "malformed catalogue refused")
	reject(data, func(d): d.georeferenced = true, "invented survey")
	reject(data, func(d): d.sources.append(d.sources[0]), "duplicate source")
	reject(data, func(d): d.sources[1].observation_period.start_year = 1979, "reversed fieldwork period")
	reject(data, func(d): d.sources[1].publication_year = true, "boolean publication year")
	reject(data, func(d): d.observations[0].erase("observation_date"), "undated observation")
	reject(data, func(d): d.observations[0].source_id = "missing", "missing source")
	reject(data, func(d): d.observations[0].identification_confidence = "", "lost identification confidence")
	reject(data, func(d): d.reconstruction_decisions[1].observation_ids = ["nair_identification_scope"], "1960s flora used as local historical evidence")
	reject(data, func(d): d.reconstruction_decisions[1].observation_ids = ["gujrat_governance"], "later governance used for opening habitat")
	reject(data, func(d): d.reconstruction_decisions[1].observation_ids = ["barr_captive_tigers"], "captive tigers used for wild habitat")
	reject(data, func(d): d.reconstruction_decisions[0].canonical_admission = true, "inference promoted to authority")
	reject(data, func(d): d.placements[0].reconstruction_decision_id = "missing", "unbound placement")
	reject(data, func(d): d.placements[0].habitat_id = "riverine_thicket", "habitat mismatch")
	reject(data, func(d): d.placements[0].location.position[0] = NAN, "nonfinite coordinates")
	reject(data, func(d): d.placements[0].location.position = [0,0,0], "playable-cell intrusion")
	reject(data, func(d): d.placements[0].collision = true, "unqualified collision")
	reject(data, func(d): d.placements[0].navigation = true, "unqualified navigation")
	reject(data, func(d): d.placements[0].gameplay_active = true, "unqualified mechanics")
	reject(data, func(d): d.habitats[0].gameplay_proposal.status = "active", "proposal promotion")
	reject(data, func(d): d.placements.pop_back(), "missing mosaic habitat")
	reject(data, func(d): d.taxonomic_corrections[0].original_wording = "", "overwritten source wording")
	reject(data, func(d): d.evidence_issues[0].opening_admission = true, "unresolved chronology admitted")
	reject(data, func(d): d.wildlife_policy.spawn_records = ["tiger"], "unsupported spawn")
	reject(data, func(d): d.wildlife_policy.abundance_claims = ["millions"], "unsupported abundance")
	reject(data, func(d): d.wildlife_policy.dolphin.local_placement_supported = true, "unlocated dolphin")
	reject(data, func(d): d.wildlife_policy.dolphin.required_before_placement.erase("depth_evidence"), "missing river-depth requirement")
	reject(data, func(d): d.season_profiles.monsoon.water_extent = INF, "unbounded water extent")
	reject(data, func(d): d.season_authority = "campaign_calendar", "new calendar authority")
	var home := Launch.make_world()
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	chapter.save_path = "user://ecology-isolated.json"
	root.add_child(home)
	await frames(6)
	chapter.open_art_study()
	var state: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var bodies := physical(home)
	var ecology: Node3D = chapter.art.ecology
	check(ecology.pockets.size() == 4 and ecology.visible, "four visible habitat pockets in actual Home")
	check(ecology._legacy.size() == 7 and ecology._legacy.all(func(r): return not r.node.visible), "continuous furrow and unlocated water placeholders hidden")
	for type in ["CollisionObject3D", "CollisionShape3D", "NavigationRegion3D", "Timer"]:
		check(ecology.find_children("*", type, true, false).is_empty(), "no ecology-owned " + type)
	check(not ecology.is_processing() and not ecology.is_physics_processing(), "no independent ecology clock")
	for placement in data.placements:
		var pocket: Node3D = ecology.pockets[placement.id]
		check(pocket.get_meta("reconstruction_decision_id") == placement.reconstruction_decision_id and pocket.get_meta("evidence_digest") == catalog.digest, "rendered pocket retains evidence identity")
	var plant: MultiMeshInstance3D = ecology._plants[0].node
	var water: MeshInstance3D = ecology._waters[1].node
	var dry_count := plant.multimesh.visible_instance_count
	var dry_pose := plant.multimesh.get_instance_transform(0)
	var dry_water := water.scale
	chapter._menu_action("art:ecology")
	chapter._menu_action("art:ecology_monsoon")
	check(ecology.season == "monsoon" and plant.multimesh.visible_instance_count > dry_count and water.scale.x > dry_water.x, "actual menu grows monsoon vegetation and water")
	chapter._menu_action("art:ecology_receding")
	check(water.scale.x > dry_water.x, "receding profile intermediate")
	chapter._menu_action("art:ecology_dry")
	check(water.scale == dry_water and plant.multimesh.get_instance_transform(0).is_equal_approx(dry_pose), "season cycle restores exact visual sample without drift")
	check(not ecology.set_season("unknown").is_empty() and water.scale == dry_water, "invalid season is inert")
	for _i in range(3):
		chapter.art.set_refinement(false)
		check(not ecology.visible and ecology._legacy.all(func(r): return r.node.visible == r.visible), "earlier study restores exact legacy visibility")
		chapter.art.set_refinement(true)
		chapter.art.set_enabled(false)
		check(not ecology.is_visible_in_tree() and ecology._legacy.all(func(r): return r.node.visible == r.visible), "greybox restores legacy visibility")
		chapter.art.set_enabled(true)
	check(chapter.model.snapshot() == state and chapter.model.journal() == journal and physical(home) == bodies, "all ecology actions preserve campaign, journal, physics and saved state")
	await frames(12)
	check(chapter.model.snapshot() == state and water.scale == dry_water, "ecology modal stays paused")
	chapter._menu_action("art:back")
	check(chapter._art_open and chapter._paused, "return to existing art study")
	chapter._resume()
	check(not chapter._art_open and not chapter._paused, "return to childhood")
	home.queue_free()
	await frames()
	print("PUNJAB_ECOLOGY_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
