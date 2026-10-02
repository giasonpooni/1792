# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/riding_training_session.gd"
## A source-inspired story visit reuses the retained Home lifecycle. No Home grants.
const OWNER_META := "punjab_chiefs_story_session"
const STORY_SCENE := "res://history/punjab_chiefs_playable.tscn"
const SEQUENCES := ["delegation", "alliance", "revenge", "desi", "exile", "well"]
var sequence_id := ""

static func entry_error(host: Node3D) -> String:
	if not is_instance_valid(host) or not host.is_inside_tree(): return "The household is no longer available."
	if host.has_meta(OWNER_META) and is_instance_valid(host.get_meta(OWNER_META)):
		return "Return from the active family tale first."
	if is_instance_valid(host.intro_session) or is_instance_valid(host.training_session):
		return "Finish the current telling or riding visit first."
	if host._paused: return "Close the household menu before hearing another tale."
	if host.model.mounted(): return "Dismount before sitting with the storyteller."
	if host.model.stage() == "caught": return "Restore the household attempt before hearing another tale."
	if host.model.stage() in ["active", "escaped"]: return "Return safely to the household before another tale."
	if host.model._other_commitment() or host.model.carrying_workshop(): return "Settle the active household task before another tale."
	if not host.avatar.is_on_floor(): return "Stand on clear ground beside the storyteller."
	if host.avatar.global_position.distance_to(host.model.position()) > 0.25:
		return "The recorded household position has not caught up with your step."
	return ""

func start_story(host: Node3D, id: String) -> String:
	if is_instance_valid(chapter) or _finished: return "This story visit has already been used."
	if id not in SEQUENCES: return "That family tale is unavailable."
	var error := entry_error(host)
	if not error.is_empty(): return error
	var packed := load(STORY_SCENE) as PackedScene
	if packed == null: return "The playable family tale could not be opened."
	var scene := packed.instantiate() as Node3D
	if scene == null: return "The playable family tale has no scene."
	scene.configure(id)
	sequence_id = id
	_park_present(host)
	host.set_meta(OWNER_META, self)
	world.tree_exiting.connect(_host_exiting, CONNECT_ONE_SHOT)
	_build_isolated_viewport("PunjabChiefsStoryViewport")
	lesson = scene
	lesson.return_requested.connect(_return_requested)
	viewport.add_child(lesson)
	return ""

func start_training(_host: Node3D, _practice: String = "") -> String:
	return "This visit belongs to a family tale."

func finish(completed: bool) -> String:
	if _finished or not is_instance_valid(chapter): return "This telling has already ended."
	if chapter.model.present_sha256() != present_sha256:
		var error := "The waiting household changed. The telling cannot combine different states."
		lesson.reject_return(error)
		return error
	if completed and not lesson.can_complete():
		var error := "Complete the tale's final action before returning as finished."
		lesson.reject_return(error)
		return error
	_finished = true
	_restore_host()
	_release_owner()
	chapter._clear_pending_actions()
	chapter.avatar.clear_motion_requests()
	chapter._message = "The tale ends. The household waits where you left it." if completed else "The telling pauses. Return to the story bench whenever you wish."
	chapter._resume()
	queue_free()
	return ""

func _release_owner() -> void:
	if is_instance_valid(chapter) and chapter.get_meta(OWNER_META, null) == self:
		chapter.remove_meta(OWNER_META)

func _host_exiting() -> void:
	abandon()

func abandon() -> void:
	_release_owner()
	super.abandon()

func _exit_tree() -> void:
	# External overlay removal returns control too; host teardown uses abandon().
	if not _finished:
		_restore_host()
		_release_owner()
		if is_instance_valid(chapter) and chapter.is_inside_tree() and is_instance_valid(world) and not world.is_queued_for_deletion():
			chapter._clear_pending_actions()
			chapter.avatar.clear_motion_requests()
			chapter._resume()
		_finished = true
	super._exit_tree()
