extends RefCounted
## Presentation only. No world reference, treasury, RNG, gameplay clock or knowledge writer.
const FILE := "res://narrative/shah_cues.json"
var catalog: Dictionary={}
var observed: Array[String]=[]
var queued: Array[String]=[]
var transcript: Array[String]=[]
var current := ""
var remaining := 0.0
var enabled := true

func _init() -> void:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if not value is Dictionary or value.get("schema")!="1792.narration-catalog.v1": return
	for cue in value.cues:
		if cue is Dictionary and cue.get("id") is String and cue.get("text") is String:
			catalog[cue.id]=cue.text

func observe(eligible: Array) -> String:
	# Validate all IDs before mutation; this adapter accepts no hidden world payload.
	for id in eligible:
		if not id is String or not catalog.has(id): return "Unsupported narration event."
	for id in eligible:
		if id not in observed:
			observed.append(id)
			if enabled: queued.append(id)
	return ""

func rebase(eligible: Array) -> String:
	for id in eligible:
		if not id is String or not catalog.has(id): return "Unsupported narration baseline."
	observed.clear()
	queued.clear()
	transcript.clear()
	current=""
	remaining=0.0
	# Restored past events are baseline, not falsely labelled as heard narration.
	for id in eligible:
		if id not in observed: observed.append(id)
	return ""

func set_enabled(value: bool) -> void:
	enabled=value
	if not enabled:
		current=""
		queued.clear()
		remaining=0.0

func step(delta: float, quiet: bool) -> void:
	if not enabled or not quiet or not is_finite(delta) or delta<=0 or delta>0.25: return
	if not current.is_empty():
		remaining=maxf(0,remaining-delta)
		if remaining>0: return
		current=""
	if not queued.is_empty():
		current=queued.pop_front()
		remaining=maxf(8.0,str(catalog[current]).length()/13.0)
		transcript.append(current)

func text() -> String:
	return str(catalog.get(current,""))

func transcript_text() -> String:
	var result := "SHAH MUHAMMAD · NARRATOR\n\nOriginal English game drafts; not quotations, not recorded speech.\nThese are narration lines displayed in this session, not Buddh's remembered accounts.\n\n"
	for id in transcript: result+=str(catalog[id])+"\n\n"
	if transcript.is_empty(): result+="No narrator line has been displayed since the current load.\n"
	return result
