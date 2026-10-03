extends RefCounted
## Read-only authored identity and terms projected from existing economic receipts.
## This does not create a second roster, treasury, kinship relation or save field.

const FIRST_ID := "fictional_guard_jora"
const CANDIDATES := [{
	"id": FIRST_ID,
	"name": "Jora",
	"occupation": "independent sword-hand seeking one household guard place",
	"affiliation": "No affiliation is asserted before appointment. The retained hire receipt admits one Sukerchakia household guard place only.",
	"kinship": "No clan, village, jatha or family is transferred with him.",
	"price": "22 authored household coins on appointment; then 2 wages and 1 food portion each compressed supply watch.",
	"term": "One continuing roster place. Duty is available only after the existing watch finds him fed and paid.",
	"conduct": "He may keep household watch and may later be the one physically reserved guard on an admitted local service detail.",
	"departure": "Release occurs at the quartermaster while his slot is uncommitted. The appointment fee is not refunded, and existing household arrears remain due.",
	"classification": "Authored reconstruction; fictional individual and fictional words."
}]

static func candidate(id: String) -> Dictionary:
	for spec in CANDIDATES:
		if spec.id == id: return spec.duplicate(true)
	return {}

static func known(id: String) -> bool:
	return not candidate(id).is_empty()

static func used(events: Array, id: String) -> bool:
	for event in events:
		if event is Dictionary and event.get("kind", "") == "hire" and event.get("arg", "") == id:
			return true
	return false

static func next_candidate(events: Array) -> Dictionary:
	for spec in CANDIDATES:
		if not used(events, spec.id): return spec.duplicate(true)
	return {}

static func roster(events: Array) -> Array:
	var active: Array = []
	var legacy_index := 0
	for event in events:
		if not event is Dictionary: continue
		if event.get("kind", "") == "hire":
			var id := str(event.get("arg", ""))
			if id == "guard":
				active.append({"id":"legacy_household_guard_%d" % legacy_index,
					"name":"Unnamed retained guard","classification":"legacy generic appointment"})
				legacy_index += 1
			elif known(id): active.append(candidate(id))
		elif event.get("kind", "") == "release_guard" and not active.is_empty():
			active.pop_back()
	return active

static func terms(id: String) -> String:
	var spec := candidate(id)
	if spec.is_empty(): return "No individual terms are available."
	return "Quartermaster · Buddh, hear one man before I enter one name.\n%s · My service is mine. Do not write my village beside it.\n\nIDENTITY · %s · fictional independent guard\nPRICE · 22 now; 2 wages + 1 food per compressed watch\nTERM · One roster place; duty only when supplied\nCONDUCT · Household watch or one admitted local detail\nDEPARTURE · Release when uncommitted; no refund; arrears remain\nBOUNDARY · No clan, village, jatha or family is transferred\n\nAUTHORED RECONSTRUCTION · Not a historical person, wage or quotation." % [spec.name, spec.name]

static func active_summary(events: Array) -> String:
	var lines: Array[String] = []
	for spec in roster(events):
		if spec.get("classification", "") == "legacy generic appointment": continue
		lines.append("%s · %s · individual appointment; no clan transfer" % [spec.name, spec.occupation])
	return "No individually stated recruit remains on the active roster." if lines.is_empty() else "Individually stated roster:\n" + "\n".join(lines)
