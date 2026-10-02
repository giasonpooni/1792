# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/riding_training_session.gd"
## The opening uses the existing retained-Home visit lifecycle without skill grants.
const Intro:=preload("res://history/charat_campaign_intro.tscn")

func start_intro(host: Node3D) -> String:
	if is_instance_valid(chapter): return "The opening is already active."
	var error: String=host.intro_entry_error()
	if not error.is_empty(): return error
	_park_present(host)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	_build_isolated_viewport("ChildhoodStoryViewport")
	lesson=Intro.instantiate();lesson.return_requested.connect(_return_requested)
	viewport.add_child(lesson)
	return ""

func start_training(_host: Node3D,_practice: String="") -> String:
	return "This visit owns the family opening, not a riding exercise."

func finish(completed: bool) -> String:
	if _finished or not is_instance_valid(chapter): return "The opening has already returned."
	if chapter.model.present_sha256()!=present_sha256:
		var error: String="The waiting Home changed. Return cannot combine different states."
		lesson.reject_return(error);return error
	if completed and not lesson.can_complete():
		var error: String="Finish the last story page before completing the opening."
		lesson.reject_return(error);return error
	_finished=true
	_restore_host()
	chapter.intro_session=null;chapter._intro_shown=true
	chapter._clear_pending_actions();chapter.avatar.clear_motion_requests()
	chapter._message="Years later, Buddh's own childhood in Gujranwala begins. Explore the courtyard."
	chapter._resume()
	queue_free()
	return ""

func _exit_tree() -> void:
	# An externally removed presentation must release its live host's input too.
	# Home teardown uses abandon(), which already marks the visit finished.
	if not _finished:
		_restore_host()
		if is_instance_valid(chapter) and chapter.is_inside_tree() and is_instance_valid(world) and not world.is_queued_for_deletion():
			chapter.intro_session=null;chapter._intro_shown=true
			chapter._clear_pending_actions();chapter.avatar.clear_motion_requests()
			chapter._message="The telling has ended. Explore the courtyard."
			chapter._resume()
		_finished=true
	super._exit_tree()
