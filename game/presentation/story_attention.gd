# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## A bounded presentation queue on the existing simulation tick. No game state,
## independent timer, rewards, camera control or remembered-evidence mutation.
const STORY := 20
const ACCOUNT := 50
const ACTION := 80
const DANGER := 100
const MAX_PENDING := 2
const HISTORY_LIMIT := 12
var _current: Dictionary = {}
var _pending: Array[Dictionary] = []
var _history: Array[String] = []
var _context := ""
var _last_tick := -1
var _last_input := ""

static func reading_ticks(line: String) -> int:
	# A production starting point, not a measured player-attention claim.
	var words := line.replace("\n", " ").split(" ", false).size()
	return clampi(90 + words * 20, 180, 720)

func reset(tick: int, keep_history: bool = false) -> void:
	_current.clear()
	_pending.clear()
	_context = ""
	_last_input = ""
	_last_tick = tick
	if not keep_history: _history.clear()

func enter_context(value: String, tick: int) -> void:
	if tick < _last_tick: reset(tick)
	if value != _context:
		# Never play an old trail reaction over an attack or after returning home.
		_pending.clear()
		if value == "active" or _context == "active" or int(_current.get("priority", 0)) >= ACTION: _current.clear()
		_context = value
		_last_input = ""
	_last_tick = tick

func offer(line: String, tick: int, priority: int = ACCOUNT) -> void:
	if tick < _last_tick: reset(tick)
	_last_tick = tick
	if line.is_empty():
		_current.clear()
		_pending.clear()
		_last_input = ""
		return
	if line == _last_input: return
	_last_input = line
	var item := {"text": line, "priority": priority, "offered": tick, "until": tick + reading_ticks(line)}
	if _current.is_empty() or priority >= int(_current.priority) and priority >= ACCOUNT:
		if priority >= ACCOUNT: _pending.clear()
		_start(item, tick)
		return
	# Latest interaction replaces older undelivered reactions; incidental lines
	# can wait briefly, but never accumulate a distant backlog of dialogue.
	if priority == ACCOUNT:
		_pending = _pending.filter(func(old: Dictionary) -> bool: return int(old.priority) > STORY)
	for old in _pending:
		if old.text == line: return
	if _pending.size() == MAX_PENDING: _pending.pop_front()
	_pending.append(item)

func _start(item: Dictionary, tick: int) -> void:
	_current = item.duplicate()
	_current.until = tick + reading_ticks(str(item.text))
	_history.append(str(item.text))
	if _history.size() > HISTORY_LIMIT: _history.pop_front()

func read(tick: int) -> String:
	if tick < _last_tick: reset(tick)
	_last_tick = tick
	if not _current.is_empty() and tick >= int(_current.until): _current.clear()
	while _current.is_empty() and not _pending.is_empty():
		var item: Dictionary = _pending.pop_front()
		if tick - int(item.offered) <= 720: _start(item, tick)
	return str(_current.get("text", ""))

func history() -> Array[String]:
	return _history.duplicate()

func pending_count() -> int:
	return _pending.size()
