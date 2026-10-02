# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/riding_training_chapter.gd"
## Production opening is a presentation visit before the original playable Home.
const IntroSession:=preload("res://history/childhood_intro_session.gd")
var autoplay_intro:=false
var intro_session: Node
var _intro_shown:=false

func _ready() -> void:
	super._ready()
	if autoplay_intro: open_childhood_intro.call_deferred()

func intro_entry_error() -> String:
	if is_instance_valid(intro_session) or is_instance_valid(training_session): return "Finish the active story or riding visit first."
	if _intro_shown: return "The opening has already been viewed in this Home."
	if model.stage()!="orientation" or model.progress().tick>1:
		return "The family opening belongs before the childhood lesson."
	return ""

func open_childhood_intro() -> String:
	var error:=intro_entry_error()
	if not error.is_empty(): return error
	var session:=IntroSession.new();session.name="ChildhoodIntroSession"
	get_tree().root.add_child(session)
	error=session.start_intro(self)
	if not error.is_empty(): session.queue_free();return error
	intro_session=session
	return ""

func training_entry_error() -> String:
	if is_instance_valid(intro_session): return "Listen to or skip the opening before riding practice."
	return super.training_entry_error()

func _exit_tree() -> void:
	if is_instance_valid(intro_session): intro_session.abandon();intro_session=null
	super._exit_tree()
