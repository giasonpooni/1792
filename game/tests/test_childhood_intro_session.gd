extends SceneTree
## Actual production entry and routed input qualify the retained-Home lifecycle.
## Canvas/audio witnesses are explicit flag fixtures; no campaign progress,
## historical knowledge, skill receipt or fixed-interlude receipt is injected.
const Launch:=preload("res://childhood/home_launch.gd")
const IntroSession:=preload("res://history/childhood_intro_session.gd")
const SAVE_PATHS: Array[String]=["user://1792-childhood-v1.json","user://1792-childhood-aftermath-v1.json","user://1792-gujranwala-v1.json","user://1792-companions-v1.json","user://1792-home-workshop-v2.json","user://1792-home-workshop-v2.json.checkpoint.json"]
var passed:=0
var failed:=0
var home: Node3D
var chapter: Node3D
var session: Node
var story: Node3D
var binding: Dictionary={}
var returned: Dictionary={}
var returns: Array[bool]=[]
var initial_files: Dictionary={}

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if value: passed+=1
	else:
		failed+=1;push_error("CHILDHOOD INTRO SESSION: "+message)

func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	session._input(event)

func click_button(button: Button) -> void:
	# Story controls live in the child viewport. Feed the real displayed button
	# position in the parent canvas, including any TextureRect scaling.
	var display: TextureRect=session.get_child(1)
	var child_at: Vector2=button.get_global_rect().get_center()
	var parent_at: Vector2=display.get_global_rect().position+child_at/Vector2(session.viewport.size)*display.size
	for pressed_flag in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed_flag
		event.position=parent_at;event.global_position=parent_at
		session._input(event)

func controls(forward: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward: Input.action_press("move_forward")

func digest_files() -> Dictionary:
	var values: Dictionary={}
	for path in SAVE_PATHS: values[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return values

func _flag_fixtures(steady_audio: bool=false) -> void:
	# These witnesses exercise restoration of pre-existing heterogeneous flags.
	for visible_flag in [true,false]:
		var layer:=CanvasLayer.new();layer.name="IntroVisibleFlag" if visible_flag else "IntroHiddenFlag"
		layer.visible=visible_flag;home.add_child(layer)
	var playing:=AudioStreamPlayer3D.new();playing.name="IntroAudioUnpausedFlag"
	if steady_audio: playing.process_mode=Node.PROCESS_MODE_ALWAYS
	playing.stream=_silent_loop();home.add_child(playing);playing.play();playing.stream_paused=false
	var already_paused:=AudioStreamPlayer.new();already_paused.name="IntroAudioPausedFlag"
	already_paused.stream=_silent_loop();home.add_child(already_paused);already_paused.play();already_paused.stream_paused=true

func _silent_loop() -> AudioStreamWAV:
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050
	var bytes:=PackedByteArray();bytes.resize(22050*2*4);stream.data=bytes
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=22050*4
	return stream

func _native_audio_frozen(sound: AudioStreamPlayback,witness: AudioStreamPlayer3D,must_remain_paused: bool) -> bool:
	# Pause is consumed by the audio mixer, independently of accelerated physics
	# frames. Observe a bounded quiescent interval instead of guessing that an
	# in-flight mix must have settled after exactly 80 ms. An unparked native
	# stream proves the mixer advances during that same interval.
	var mixer:=AudioStreamPlayer.new();mixer.stream=_silent_loop()
	mixer.process_mode=Node.PROCESS_MODE_ALWAYS;root.add_child(mixer);mixer.play()
	var reference: AudioStreamPlayback=mixer.get_stream_playback()
	var started: int=Time.get_ticks_msec()
	var deadline: int=started+2000
	while not reference.is_playing() and Time.get_ticks_msec()<deadline: await process_frame
	var unchanged_since: int=Time.get_ticks_msec()
	var parked_at: float=sound.get_playback_position()
	var first_at: float=parked_at
	var reference_at: float=reference.get_playback_position()
	var frozen:=false
	while Time.get_ticks_msec()<deadline:
		await process_frame
		# A pending, never-started 3D stream has no active pause flag. The
		# separate steady-audio case must retain a genuinely paused playback.
		if (must_remain_paused or sound.is_playing()) and not witness.stream_paused: break
		var now: int=Time.get_ticks_msec()
		var at: float=sound.get_playback_position()
		if at!=parked_at:
			parked_at=at;unchanged_since=now
			reference_at=reference.get_playback_position()
		if now-unchanged_since>=250 and reference.get_playback_position()>reference_at:
			frozen=(witness.stream_paused if must_remain_paused else not sound.is_playing() or witness.stream_paused) and at==parked_at
			break
	print("INTRO_AUDIO_PAUSE_OBSERVATION: first_position=%s; settled_position=%s; final_position=%s; unchanged_ms=%d; elapsed_ms=%d; mixer_before=%s; mixer_after=%s; paused=%s; frozen=%s"%[first_at,parked_at,sound.get_playback_position(),Time.get_ticks_msec()-unchanged_since,Time.get_ticks_msec()-started,reference_at,reference.get_playback_position(),witness.stream_paused,frozen])
	mixer.stop();mixer.stream=null;mixer.queue_free()
	return frozen

func _release_flag_audio() -> void:
	if not is_instance_valid(home): return
	for path in ["IntroAudioUnpausedFlag","IntroAudioPausedFlag"]:
		var player=home.get_node_or_null(path)
		if player!=null: player.stop();player.stream=null

func capture() -> Dictionary:
	var bodies: Dictionary={}
	for body in home.find_children("*","CharacterBody3D",true,false): bodies[body.get_instance_id()]=body.global_transform
	var canvases: Dictionary={}
	for layer in home.find_children("*","CanvasLayer",true,false): canvases[layer.get_instance_id()]=layer.visible
	var audio: Dictionary={}
	for node in home.find_children("*","",true,false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D: audio[node.get_instance_id()]=node.stream_paused
	var material_record: Dictionary=chapter.art.material_fidelity.records[0]
	var material_node: MeshInstance3D=material_record.node
	return {"snapshot":chapter.model.snapshot(),"sha":chapter.model.present_sha256(),"bodies":bodies,
		"art_id":chapter.art.get_instance_id(),"detail_id":chapter.art.detail.child_root.get_instance_id(),
		"workshop_id":chapter.workplace.carried.get_instance_id(),"material_node":material_node.get_instance_id(),
		"material":material_node.material_override,"canvases":canvases,"audio":audio,"process_mode":home.process_mode}

func _opening(steady_audio: bool=false) -> void:
	controls();returned.clear();returns.clear()
	if steady_audio:
		# A construction-only host supplies a genuinely running 3D audio stream.
		# Its world remains disabled while the explicit ALWAYS audio witness starts;
		# this introduces neither a gameplay tick nor a historical progress seed.
		home=Launch.make_world();root.add_child(home);current_scene=home
		chapter=home.get_node("ChildhoodChapter");home.process_mode=Node.PROCESS_MODE_DISABLED
		_flag_fixtures(true)
		var playback: AudioStreamPlayback=home.get_node("IntroAudioUnpausedFlag").get_stream_playback()
		var deadline: int=Time.get_ticks_msec()+1000
		while not playback.is_playing() and Time.get_ticks_msec()<deadline: await physics_frame
		check(playback.is_playing(),"steady audio fixture has genuinely active native 3D playback before parking")
		home.process_mode=Node.PROCESS_MODE_INHERIT
	else:
		Launch.enter(self)
		home=current_scene;chapter=home.get_node("ChildhoodChapter")
		_flag_fixtures()
	# Autoplay runs deferred. Capture the real freshly constructed authority before
	# any input or lesson rather than reconstructing it from a seeded save.
	binding=capture()
	if steady_audio: check(chapter.open_childhood_intro().is_empty(),"actual protected intro admits a fresh host with a running audio witness")
	await process_frame;await process_frame
	session=chapter.intro_session
	check(is_instance_valid(session),"production launch opens the family story" if not steady_audio else "native protected entry opens the family story with real active audio")
	if not is_instance_valid(session): return
	story=session.lesson
	check((chapter.autoplay_intro or steady_audio) and chapter.model.stage()=="orientation" and chapter.model.progress().tick<=1,"opening precedes any ordinary childhood lesson")
	check(session.present_sha256==binding.sha and chapter.model.snapshot()==binding.snapshot,"production autoplay binds the untouched canonical Home")
	check(home.is_inside_tree() and home.process_mode==Node.PROCESS_MODE_DISABLED,"waiting Home remains in-tree with execution suspended")
	check(session.viewport.own_world_3d and story.get_world_3d()!=chapter.get_world_3d(),"opening uses the existing isolated native World3D lifecycle")
	check(root.disable_3d and not session.viewport.disable_3d,"opening suspends only the waiting Home's 3D rendering")
	check(session.viewport.handle_input_locally and session.viewport.audio_listener_enable_3d,"child viewport owns story input and listening")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"actual opening exposes its pointer for story UI navigation")
	for layer in home.find_children("*","CanvasLayer",true,false): check(not layer.visible,"every retained Home CanvasLayer is hidden during opening")
	for node in home.find_children("*","",true,false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			var native_playback: AudioStreamPlayback=node.get_stream_playback() if node.has_stream_playback() else null
			check(native_playback==null or not native_playback.is_playing() or node.stream_paused,"every genuinely active retained Home audio stream is paused during opening: "+node.name)
	var witness: AudioStreamPlayer3D=home.get_node("IntroAudioUnpausedFlag")
	if steady_audio:
		check(witness.stream_paused and home.get_node("IntroAudioPausedFlag").stream_paused,"genuinely active 3D and already-paused audio witnesses are both parked")
	else:
		check(not witness.get_stream_playback().is_playing() and witness.get_stream_playback().get_playback_position()==0.0,"initial pending 3D playback remains unstarted during production autoplay")
	check(story.get_node("MahaSingh").get_meta("actor_id")=="mahan_singh" and story.get_node("YoungBuddhSingh").get_meta("actor_id")=="ranjit_singh","story separates adult father and very young listener identities")
	check(story.get_node("YoungBuddhSingh").get_meta("authored_age_presentation")=="very_young_child","young Buddh presentation is explicit without a new historical age")
	story.return_requested.connect(func(completed: bool): returns.append(completed))
	session.tree_exiting.connect(func():
		if is_instance_valid(home) and is_instance_valid(chapter): returned=capture())
	check(not session.finish(true).is_empty() and not session._finished,"immediate completed return is refused before final page")
	check(story._return_error.visible and not story._next.disabled,"premature completion has visible refusal and leaves navigation usable")
	check(chapter.model.snapshot()==binding.snapshot,"premature completion changes no canonical state")
	check(not chapter.open_childhood_intro().is_empty(),"second opening cannot overlap the live visit")
	check(chapter.training_entry_error().begins_with("Listen to or skip the opening") and not chapter.open_riding_training().is_empty(),"riding visit is explicitly refused while opening is active")
	var duplicate:=IntroSession.new();root.add_child(duplicate)
	check(not duplicate.start_intro(chapter).is_empty(),"second session refuses an already active production opening")
	duplicate.queue_free();await process_frame
	controls(true);await frames(12);controls()
	_check_frozen()
	var sound: AudioStreamPlayback=witness.get_stream_playback()
	check(await _native_audio_frozen(sound,witness,steady_audio),"native 3D playback clock stays frozen while the independent mixer advances during the opening")
	if not steady_audio: check(not sound.is_playing(),"initial pending 3D stream never begins secretly while Home is parked")

func _check_frozen() -> void:
	var now:=capture()
	check(now.snapshot==binding.snapshot and now.sha==binding.sha,"routed input and waiting frames preserve the exact Home clock and state SHA")
	check(now.bodies==binding.bodies,"waiting player, horse and other native character bodies remain frozen")
	check(now.art_id==binding.art_id and now.detail_id==binding.detail_id and now.workshop_id==binding.workshop_id,"live art and workshop attachment identities survive the opening")
	check(now.material_node==binding.material_node and now.material==binding.material,"original material override identity is retained")
	check(digest_files()==initial_files,"opening navigation writes no campaign save or checkpoint")

func _check_return(label: String) -> void:
	check(not returned.is_empty(),label+" produces a retained-Home return boundary witness")
	if returned.is_empty(): return
	check(returned.snapshot==binding.snapshot and returned.sha==binding.sha,label+" restores the exact canonical Home without skill, story, custody or knowledge grants")
	check(returned.bodies==binding.bodies,label+" returns the same native physical body transforms")
	check(returned.canvases==binding.canvases and returned.audio==binding.audio,label+" restores original heterogeneous Canvas visibility and audio pause flags")
	check(returned.process_mode==binding.process_mode,label+" restores the original Home process mode")
	check(returned.art_id==binding.art_id and returned.detail_id==binding.detail_id and returned.workshop_id==binding.workshop_id and returned.material==binding.material,label+" retains existing presentation objects without exit/rebuild")
	check(chapter.intro_session==null and chapter._intro_shown and home.is_inside_tree(),label+" releases the overlay and resumes its retained Home")
	check(not root.disable_3d,label+" restores the root rendering flag")
	check(not chapter._paused and chapter.avatar.input_enabled and chapter.avatar.is_physics_processing(),label+" restores the original playable Home avatar input mode")
	if DisplayServer.get_name()!="headless": check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,label+" restores the playable Home hardware pointer mode")
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false} and chapter.model.snapshot().riding_skills.lesson_receipts.is_empty(),label+" adds no riding skill or training receipt")
	check(chapter.horse._rider.get_child_count()==7,label+" preserves the original seven rider anchors")
	check(not chapter.open_childhood_intro().is_empty(),label+" cannot autoplay a duplicate opening in the same Home")
	check(digest_files()==initial_files,label+" writes no campaign save or checkpoint")

func _close_home() -> void:
	controls();current_scene=null
	if is_instance_valid(home): _release_flag_audio();home.queue_free()
	home=null;chapter=null;session=null;story=null
	await frames(4)
	check(root.find_children("ChildhoodIntroSession","CanvasLayer",false,false).is_empty(),"closing Home leaves no opening overlay")

func _external_session_removal() -> void:
	await _opening()
	var removed: Node=session
	var removed_ref: WeakRef=weakref(removed)
	root.remove_child(removed)
	# Removal synchronously runs the real scene exit path. Capture immediately,
	# before ordinary resumed physics can advance the canonical Home clock.
	var after: Dictionary=capture()
	check(after.snapshot==binding.snapshot and after.sha==binding.sha,"external session removal immediately preserves exact Home authority without grants")
	check(after.bodies==binding.bodies,"external session removal immediately preserves every retained character body transform")
	check(after.canvases==binding.canvases and after.audio==binding.audio and after.process_mode==binding.process_mode,"external session removal immediately restores original Canvas, audio and process flags")
	check(after.art_id==binding.art_id and after.detail_id==binding.detail_id and after.workshop_id==binding.workshop_id and after.material==binding.material,"external session removal keeps original live art and workshop objects")
	check(chapter.intro_session==null and home.is_inside_tree() and not root.disable_3d,"external session removal releases the live host visit and restores root rendering")
	check(not chapter._paused and chapter.avatar.input_enabled and chapter.avatar.is_physics_processing(),"external session removal restores Home avatar control immediately")
	if DisplayServer.get_name()!="headless": check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"external session removal restores the actual Home mouse capture")
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false} and chapter.model.snapshot().riding_skills.lesson_receipts.is_empty(),"external session removal cannot admit an incomplete opening as a skill receipt")
	check(returns.is_empty() and not removed.is_inside_tree(),"external scene exit emits no completed-story signal or invisible active visit")
	check(not removed.finish(true).is_empty() and chapter.model.snapshot()==after.snapshot,"detached session cannot subsequently admit a forged completion")
	check(digest_files()==initial_files,"external session removal writes no campaign file")
	# A real later menu now owns the pointer. Repeated cleanup of the detached
	# visit must not reapply flags captured before the family opening.
	chapter._open_journal()
	removed._restore_host();removed._restore_host()
	check(chapter._paused and chapter._panel.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"repeated returned-session cleanup preserves the later journal's pointer ownership")
	check(chapter.model.snapshot()==after.snapshot and capture().bodies==after.bodies and digest_files()==initial_files,"repeated cleanup after a real journal opens changes no Home state, physics or campaign file")
	chapter._resume()
	removed.free();removed=null;session=null;story=null
	check(removed_ref.get_ref()==null,"detached session and its isolated viewport are explicitly disposed")
	# Qualify actual motor execution after restoration, rather than accepting
	# input_enabled alone as evidence that the player is no longer stranded.
	var before_position: Vector3=chapter.avatar.global_position
	var before_tick: int=chapter.model.progress().tick
	controls(true);await frames(12);controls();await frames(4)
	check(chapter.avatar.global_position.distance_to(before_position)>.05 and chapter.model.progress().tick>before_tick,"ordinary W input physically moves the Home player after external session removal")
	check(chapter.model.journal()==binding.snapshot.childhood.memories,"resumed movement after external removal invents no received historical memory")
	await _close_home()

func _external_session_disposal() -> void:
	await _opening()
	var disposed_ref: WeakRef=weakref(session)
	var after_disposal: Dictionary={}
	# tree_exited occurs after the production _exit_tree restoration; the earlier
	# tree_exiting witness used by normal guarded returns is intentionally not used.
	session.tree_exited.connect(func(): after_disposal.merge(capture(),true))
	session.queue_free();await process_frame;await process_frame
	returned=after_disposal
	_check_return("external queue_free")
	check(disposed_ref.get_ref()==null and returns.is_empty(),"external session disposal frees the isolated visit without emitting a story completion")
	session=null;story=null
	await _close_home()

func _run() -> void:
	root.size=Vector2i(1280,720);root.disable_3d=false;initial_files=digest_files()
	var front:=Node.new();front.name="ExplicitPreviousFrontFixture";root.add_child(front);current_scene=front
	var previous: WeakRef=weakref(front)
	await _opening()
	check(previous.get_ref()==null,"production entry releases the previous front scene")
	if not is_instance_valid(session): quit(1);return
	var expected_ids: Array=story.story_beats().map(func(beat): return beat.id)
	var ids: Array=[]
	for i in range(expected_ids.size()):
		ids.append(story.story_beats()[story.current_beat].id)
		check(story.current_beat==i and story._dialogue.text==story.story_beats()[i].dialogue,"real navigation displays ordered father narration beat %d"%i)
		if i<expected_ids.size()-1:
			if i%2==0: key(KEY_RIGHT)
			else: click_button(story._next)
			await process_frame
	check(ids==expected_ids and ids[0]=="grandfather","Maha-to-young-Buddh navigation retains the complete declared Charat campaign sequence")
	check(story.can_complete() and story._next.text=="Continue to Home","last displayed page enables a concrete Home return")
	key(KEY_LEFT);await process_frame
	check(not story.can_complete() and not session.finish(true).is_empty(),"returning to an earlier page cannot claim final completion")
	click_button(story._next);await process_frame
	_check_frozen()
	# The real final UI button emits exactly once. Duplicate routed Enter is
	# delivered before the deferred guarded return and cannot create a second one.
	click_button(story._next);key(KEY_ENTER)
	check(returns==[true],"final UI completion suppresses a same-frame duplicate keyboard return")
	await process_frame;await process_frame
	_check_return("complete opening")
	# Home's existing journal/menu route remains available after the introduction.
	var journal_key:=InputEventKey.new();journal_key.keycode=KEY_F1;journal_key.pressed=true
	chapter._unhandled_input(journal_key)
	var menu_button: Button
	for child in chapter._actions.get_children():
		if child is Button and child.text.begins_with("Main menu"): menu_button=child
	check(is_instance_valid(menu_button),"intro-to-Home exposes the inherited actual Main menu action")
	_release_flag_audio()
	if is_instance_valid(menu_button): menu_button.pressed.emit()
	await process_frame;await process_frame
	check(is_instance_valid(current_scene) and current_scene.get_script().resource_path=="res://ui/main_menu.gd","actual inherited UI returns from the intro's Home to the production menu")
	check(not root.disable_3d and root.find_children("ChildhoodIntroSession","CanvasLayer",false,false).is_empty(),"menu route leaves root rendering restored and no opening overlay")
	home=null;chapter=null;session=null;story=null
	await _opening();key(KEY_ESCAPE);await process_frame;await process_frame
	check(returns==[false],"actual routed Escape skips the opening without completion")
	_check_return("Escape skip");await _close_home()
	await _opening();click_button(story._skip);await process_frame;await process_frame
	check(returns==[false],"actual Skip UI emits only an incomplete return")
	_check_return("button skip");await _close_home()
	await _opening()
	var before_duplicate: Dictionary=chapter.model.snapshot()
	check(session.finish(false).is_empty(),"direct canceled return succeeds before native session disposal")
	check(not session.finish(true).is_empty() and chapter.model.snapshot()==before_duplicate,"duplicate completion after returned cancellation is refused without a canonical mutation")
	await process_frame;await process_frame
	_check_return("guarded direct skip");await _close_home()
	# A world close abandons an active overlay; the stored root flag must be
	# restored even when it was already disabled before the visit began.
	root.disable_3d=true;await _opening()
	var overlay_ref: WeakRef=weakref(session)
	await _close_home()
	check(root.disable_3d and overlay_ref.get_ref()==null,"closing an active opening releases its overlay and restores the pre-existing root disable flag")
	root.disable_3d=false
	# Native parent-window resizing exercises actual displayed mouse coordinates
	# rather than assuming that the fixed 1280x720 story fills the same pixels.
	for window_size in [Vector2i(1600,900),Vector2i(1024,768)]:
		root.size=window_size;await _opening()
		click_button(story._next);await process_frame
		check(story.current_beat==1,"actual displayed Next click advances story at window %s"%window_size)
		key(KEY_ESCAPE);await process_frame;await process_frame
		_check_return("resized window skip");await _close_home()
	root.size=Vector2i(1280,720)
	await _external_session_removal()
	await _external_session_disposal()
	await _opening(true);key(KEY_ESCAPE);await process_frame;await process_frame
	_check_return("active native audio skip");await _close_home()
	await _opening()
	# Explicit external-authority interference fixture: call the existing native
	# look recorder while execution is parked. No memory, historical knowledge or
	# progress receipt is invented, and the session must refuse a stale binding.
	chapter.model.record_look(.25)
	var changed_present: Dictionary=chapter.model.snapshot()
	check(chapter.model.present_sha256()!=binding.sha,"external native look operation creates a distinct present binding")
	check(not session.finish(false).is_empty() and story._return_error.visible,"return refuses an externally changed waiting Home with visible feedback")
	check(chapter.model.snapshot()==changed_present and not session._finished,"failed return preserves the changed authority and keeps the visit open")
	await _close_home()
	check(not root.disable_3d,"world close safely abandons a refused stale-binding opening")
	# make_world is intentionally construction-only for tools and tests. Let the
	# original motor actually advance before qualifying the late-entry guard.
	home=Launch.make_world();root.add_child(home);current_scene=home
	chapter=home.get_node("ChildhoodChapter");await frames(6)
	check(not chapter.autoplay_intro and chapter.intro_session==null,"construction-only make_world never starts the production opening")
	check(chapter.model.progress().tick>1 and not chapter.open_childhood_intro().is_empty(),"actual elapsed childhood ticks refuse a late opening")
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false},"intro qualification never manufactures learned campaign capabilities")
	# The common lifecycle must also leave a caller untouched when the story's
	# own entry rule rejects before it can park any part of that live caller.
	var prior_process: int=home.process_mode
	home.process_mode=Node.PROCESS_MODE_DISABLED
	var untouched: Dictionary=capture()
	var pointer_mode: int=Input.mouse_mode
	var drawing_disabled: bool=root.disable_3d
	var rejected:=IntroSession.new();root.add_child(rejected)
	var rejected_ref: WeakRef=weakref(rejected)
	check(not rejected.start_intro(chapter).is_empty(),"late direct intro session rejects before acquiring its caller")
	rejected.queue_free();await process_frame;await process_frame
	check(rejected_ref.get_ref()==null and Input.mouse_mode==pointer_mode,"rejected pre-park intro disposal preserves the real playable Home pointer")
	check(capture()==untouched and root.disable_3d==drawing_disabled and chapter.intro_session==null,"rejected intro disposal preserves all live Home authority and presentation flags")
	home.process_mode=prior_process
	await _close_home()
	check(digest_files()==initial_files,"all production entry, completion, skip, menu and close cases preserve campaign files")
	print("CHILDHOOD_INTRO_SESSION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
