extends SceneTree
## Native scene/UI checks; no historical reenactment or Home preservation claim.
const Intro := preload("res://history/charat_campaign_intro.tscn")
const EXPECTED_BEATS := ["grandfather","desan_household","chenab_sialkot","gujranwala_relief","kup","kasur","sirhind","sutlej","jhelum_rohtas","jammu_desan_regency"]
const ORIGINAL_BEATS := ["grandfather","chenab_sialkot","gujranwala_relief","kup","sirhind","sutlej","jhelum_rohtas"]
var passed := 0
var failed := 0
var returns: Array[bool] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: "+label)

func record_return(completed: bool) -> void:
	returns.append(completed)

func key(code: Key) -> InputEventKey:
	var result := InputEventKey.new()
	result.keycode = code
	result.pressed = true
	return result

func descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result

func _run() -> void:
	root.size = Vector2i(1280,720)
	var scene = Intro.instantiate()
	scene.return_requested.connect(record_return)
	root.add_child(scene)
	await process_frame
	await process_frame
	var beats: Array = scene.story_beats()
	check(beats.size() == 10,"ten family and campaign beats")
	check(beats.map(func(beat): return beat.id) == EXPECTED_BEATS,"family and regency frame the extended chronological campaign sequence")
	check(beats.filter(func(beat): return beat.id in ORIGINAL_BEATS).map(func(beat): return beat.id) == ORIGINAL_BEATS,"all seven original campaign beats retain their order")
	check(beats[1].dialogue.contains("Desan Kaur") and beats[1].dialogue.contains("She is your grandmother."),"family frame includes Desan without selecting biological maternity or personal acquaintance")
	check(beats[5].dialogue.contains("plundered") and beats[5].dialogue.contains("Hari Singh Bhangi"),"Kasur includes verified participation and plunder")
	check(beats[-1].dialogue.contains("matchlock burst") and beats[-1].dialogue.contains("Desan Kaur held"),"Jammu loss leads to Desan's leadership")
	check(not beats[-1].period.contains("1770") and not beats[-1].period.contains("1774"),"conflicting death year is not selected")
	var word_count := 0
	for beat in beats:
		word_count += beat.dialogue.split(" ",false).size()
	check(word_count >= 450 and word_count <= 650,"extended family narration stays within concise word budget")
	beats[0].dialogue = "changed outside scene"
	check(scene.story_beats()[0].dialogue != beats[0].dialogue,"story projection is detached")
	check(scene.get_node("MahaSingh").get_meta("actor_id") == "mahan_singh","father has his own identity")
	check(scene.get_node("YoungBuddhSingh").get_meta("actor_id") == "ranjit_singh","young listener keeps hero identity")
	check(scene.get_node("YoungBuddhSingh").get_meta("authored_age_presentation") == "very_young_child","young presentation is explicit without invented age")
	check(scene.get_node("YoungBuddhSingh").scale.x < scene.get_node("MahaSingh").scale.x,"visible child differs in scale from adult")
	check(not scene.is_processing() and not scene.is_physics_processing(),"recollection has no ticking simulation")
	check(descendants(scene).all(func(node): return not node is CollisionObject3D and not node is Timer),"no physics bodies or autonomous timers")
	check(scene.get_node("StoryCamera").current,"story owns a camera")
	var first_presentation: Dictionary = scene.presentation_snapshot()
	check(first_presentation.schema == "1792.charat-intro-presentation.v1" and first_presentation.settled,"opening production pose is immediately settled")
	check(first_presentation.camera.production_camera and first_presentation.camera.v_offset == scene.get_node("StoryCamera").v_offset,"presentation exposes the actual production camera including offset")
	check(scene.get_node("MahaSingh/HeadAttentionPivot/Nose") != null and scene.get_node("YoungBuddhSingh/HeadAttentionPivot/Nose") != null,"simple faces make the father and child orientation visible")
	var detached_presentation: Dictionary = scene.presentation_snapshot()
	detached_presentation.camera.position[0] = 9999
	check(scene.presentation_snapshot().camera.position[0] != 9999,"camera evidence projection is detached")
	var finishes = scene.material_projection
	check(finishes.records.size() == 54 and finishes.get_child_count() == 0,"only 54 declared existing meshes receive material projection without new geometry")
	check(not finishes.get_meta("historical_claim") and not finishes.get_meta("gameplay_authority"),"material reuse has no history or gameplay authority")
	var material_description: Dictionary = first_presentation.material_projection
	check(material_description.mesh_count == 54 and material_description.added_geometry == 0,"renderer receives exact material count and geometry boundary")
	check(material_description.groups == [{"kind":"plaster","mesh_count":5},{"kind":"timber","mesh_count":14},{"kind":"woven_mat","mesh_count":11},{"kind":"costume_cloth","mesh_count":24}],"declared material classification stays explicit")
	check(material_description.shader == "res://presentation/craft_surface.gdshader" and material_description.sources.map(func(source): return source.resource) == ["res://assets/surfaces/plastered_wall_disp_1k.png","res://assets/surfaces/plastered_wall_rough_1k.png"],"material evidence identifies the existing shader and credited source resources")
	check(material_description.sources.all(func(source): return source.license == "CC0-1.0" and source.provenance == "res://assets/surfaces/sources.json"),"reused generic surface maps retain their provenance and license")
	var material_geometry: Array = []
	for record in finishes.records:
		check(record.node.material_override == record.new and record.new is ShaderMaterial and record.new.get_shader_parameter("pigment") == record.old.albedo_color,"declared material preserves original pigment: "+str(scene.get_path_to(record.node)))
		material_geometry.append([record.node.get_instance_id(),record.node.mesh,record.node.transform])
	finishes.set_enabled(false)
	check(finishes.records.all(func(record): return record.node.material_override == record.old),"projection restores exact original material references")
	finishes.set_enabled(true)
	check(finishes.records.all(func(record): return record.node.material_override == record.new),"projection restores the same finished material references")
	var after_material_toggle: Array = []
	for record in finishes.records: after_material_toggle.append([record.node.get_instance_id(),record.node.mesh,record.node.transform])
	check(after_material_toggle == material_geometry,"material lifecycle preserves mesh, node and transform identities")
	for actor in ["MahaSingh","YoungBuddhSingh"]:
		for part in ["Head","Nose","EyeLeft","EyeRight"]:
			check(scene.get_node(actor+"/HeadAttentionPivot/"+part).material_override is StandardMaterial3D,"face detail stays plain: "+actor+"/"+part)
	check(scene.get_node("MahaSingh/HeadAttentionPivot/Beard").material_override is StandardMaterial3D,"beard remains plain")
	var detached_materials: Dictionary = scene.presentation_snapshot()
	detached_materials.material_projection.declared_meshes[0].mesh = "changed outside scene"
	check(scene.presentation_snapshot().material_projection == material_description,"material evidence arrays are detached")
	check(scene.get_node("StoryInterface/DramatizationLabel").text.contains("dramatized"),"authored dialogue is framed as dramatization")
	check(scene.current_beat == 0 and not scene.can_complete(),"start is not completion")
	scene.previous()
	check(scene.current_beat == 0,"previous cannot underflow")
	scene.request_return(true)
	check(returns.is_empty(),"early completed return refused")
	for i in range(EXPECTED_BEATS.size()):
		check(scene.current_beat == i,"current ordered beat %d" % i)
		check(scene.get_node("StoryInterface/Subtitles/Column/HeadingRow/BeatTitle").text.begins_with("%d / %d" % [i+1,EXPECTED_BEATS.size()]),"visible ordered beat %d" % i)
		check(scene.get_node("StoryInterface/Subtitles/Column/Dialogue").text == scene.story_beats()[i].dialogue,"visible father dialogue %d" % i)
		check(scene.get_node("StoryInterface/Subtitles/Column/Dialogue").modulate.a >= 0.87,"full page stays visible throughout transition beat %d" % i)
		scene.settle_presentation()
		var projected: Dictionary = scene.presentation_snapshot()
		check(projected.settled and projected.beat_id == EXPECTED_BEATS[i] and projected.dialogue_opacity == 1.0,"settled pose belongs to current readable beat %d" % i)
		check(projected.material_projection == material_description,"source identities and declared material arrays stay stable across beat %d" % i)
		check(finishes.records.all(func(record): return record.node.material_override == record.new),"page and pose changes retain the same material references beat %d" % i)
		var actor_camera: Camera3D = scene.get_node("StoryCamera")
		for actor in ["MahaSingh","YoungBuddhSingh"]:
			var head: Node3D = scene.get_node(actor+"/HeadAttentionPivot/HeadWrap")
			var screen_head := actor_camera.unproject_position(head.global_position)
			check(screen_head.x >= 180 and screen_head.x <= 1100 and screen_head.y >= 110 and screen_head.y <= 380,"visible seated attention clear of titles and subtitles %s beat %d" % [actor,i])
		await process_frame
		var dialogue: Label = scene.get_node("StoryInterface/Subtitles/Column/Dialogue")
		check(dialogue.get_line_count()*dialogue.get_theme_font("font").get_height(dialogue.get_theme_font_size("font_size")) <= dialogue.size.y+1.0,"dialogue fits scene at 1280x720 beat %d" % i)
		var panel: PanelContainer = scene.get_node("StoryInterface/Subtitles")
		check(panel.get_global_rect().end.y <= 700.0,"longer dialogue keeps navigation inside viewport beat %d" % i)
		if i < EXPECTED_BEATS.size()-1: scene.advance()
	var final_presentation: Dictionary = scene.presentation_snapshot()
	scene.previous()
	scene.settle_presentation()
	scene.advance()
	scene.settle_presentation()
	check(scene.presentation_snapshot() == final_presentation,"back and forward produce the same deterministic final camera and pose")
	check(first_presentation.father_right_hand != final_presentation.father_right_hand,"father's presentation gesture changes across the telling")
	check(scene.can_complete(),"all ten beats allow completion")
	check(scene.get_node("StoryInterface/Subtitles/Column/Controls/Next").text == "Continue to Home","final button explicitly returns Home")
	scene.previous()
	check(not scene.can_complete(),"viewing prior beat is not final completion")
	scene.advance()
	scene.advance()
	check(returns == [true],"final continue emits completion exactly once")
	scene.request_return(true)
	check(returns == [true],"duplicate return suppressed")
	scene.reject_return("The present could not be restored.")
	check(scene.get_node("StoryInterface/Subtitles/Column/ReturnMessage").visible,"host refusal has visible local feedback")
	check(not scene.get_node("StoryInterface/Subtitles/Column/Controls/Next").disabled,"host refusal reenables navigation")
	scene.request_return(false)
	check(returns == [true,false],"host refusal permits safe cancellation request")
	scene.queue_free()
	await process_frame
	returns.clear()
	var skipped = Intro.instantiate()
	skipped.return_requested.connect(record_return)
	root.add_child(skipped)
	await process_frame
	skipped._input(key(KEY_RIGHT))
	check(skipped.current_beat == 1,"real key event advances story")
	check(skipped.presentation_snapshot().transition_phase == 0.0,"keyboard starts the same short visual blend as click navigation")
	await skipped._presentation_tween.finished
	var naturally_settled: Dictionary = skipped.presentation_snapshot()
	check(naturally_settled.settled and naturally_settled.dialogue_opacity == 1.0,"engine completes the visual blend without advancing the story")
	skipped.settle_presentation()
	check(skipped.presentation_snapshot() == naturally_settled and skipped.current_beat == 1,"explicit inspection settling matches the production tween's reachable pose")
	skipped._input(key(KEY_LEFT))
	check(skipped.current_beat == 0,"real key event returns to prior story beat")
	skipped._input(key(KEY_ESCAPE))
	check(returns == [false],"Escape emits cancellation without completing history")
	check(skipped._presentation_tween == null,"safe cancellation stops the presentation blend")
	skipped.advance()
	check(skipped.current_beat == 0,"closed scene cannot keep advancing")
	skipped.queue_free()
	await process_frame
	print("CHARAT_CAMPAIGN_INTRO_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
