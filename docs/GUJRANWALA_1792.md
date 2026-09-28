# Gujranwala, 1792 — evidence-bound playable reconstruction

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## What this build represents

A compressed household-to-market journey, not a complete surveyed town. The
56 × 56 metre playable envelope, terrain profile, riding, inquiry, provision
ledger and caravan navigation remain the qualified gameplay substrate. New
courtyard frontages, verandah arches, an open forecourt, a well, trade props and
peripheral fields give that substrate a more specific architectural setting.

`game/data/gujranwala_reconstruction.v1.json` is the authoritative record for
these new features. Each mesh root retains claim IDs and a reconstruction class.
The notebook opened with **F2** shows the manifest's exact SHA-256. It pauses the
existing game clock; consulting it grants no places, reports or memories to Buddh.

## Research decisions

**Courtyard vocabulary, not a copied 1792 floor plan.** Ahmad and Khilat's 2023
field study documents verandahs, courtyards, masonry and timber features and an
open forecourt (kucha). These support architectural comparison, not our exact
footprints, arch counts, wall heights or placement. Their study also describes
modern alterations, so surviving fabric is not automatically original fabric.
Source: [study, Spatial Organization and Access](https://journals.umt.edu.pk/index.php/JAABE/article/download/3188/1851?inline=1).
The inline plan images were not successfully retrieved for measured transcription.
No surveyed plan, figure tracing or archival image is bundled.

**A settlement with a regional role.** Grewal's analysis of Ganesh Das describes
Gujranwala's expansion from a village as Charat Singh's capital. This supports a
regional settlement context; it supplies neither a 1792 parcel map nor a numerical
population model. Source: [Grewal, printed pp. 25–26](https://punjab.global.ucsb.edu/sites/default/files/sitefiles/journals/volume20/3-JS%20Grewal%2020.pdf).

**Separate the fabric phases.** The [Walled City Lahore Authority description](https://walledcitylahore.gop.pk/gujranwala-project/)
uses a nineteenth-century description alongside a birthplace attribution. We do
not resolve that into a single construction date for every surviving component.
Detailed fabric-phase research remains necessary.

**Exclude the completed later samadhi.** The [DOAM inventory](https://doam.gov.pk/public/sites/10110)
records establishment in 1835. The completed monument is not instantiated in the
1792 scene. This does not decide Mahan Singh's disputed death year or rewrite the
fixed retrospective already implemented in the narrative system.

**Correct the pavilion rule.** The [DOAM baradari entry](https://doam.gov.pk/public/sites/6546)
attributes it to Ranjit Singh's reign, while Ahmad and Khilat's Table 1 attributes
the garden and baradari to Mahan Singh. The earlier blanket assertion that it is
certainly later is too strong. Its status is now `defer_disputed`: absent from this
prototype pending reconciliation, not proven absent from historical Gujranwala.

## Runtime boundaries

The 11 feature records are original primitive geometry. Their placements are
class B reconstruction and their exact dimensions are class C abstractions. No
structure is admitted merely because a generator supplied a plausible date.
Mandatory exclusions, source references, finite geometry and the existing frame
are checked before the district is built. Python additionally checks conservative
clearance from new solid geometry; native tests exercise the actual swept routes.

The well has a collision body and now supports the optional finite
[household water round](GUJRANWALA_WATER_ROUND.md). Recurring water consumption
and water-dependent production are not implemented. Other new frontages and
props are visual dressing; existing walls still provide the qualified barriers.
Peripheral courts are scenery outside the playable boundary, not newly streamed
interiors. Field and market figures sample the existing tick deterministically;
they are not persistent NPCs, witnesses, merchants or additional state authorities.

## Shah Muhammad's retrospective voice

The user's narrator assignment is implemented as a read-only text presentation
layer at home, allowance, delivery and return milestones. All four lines are
original English development writing, not historical quotations, verse,
translations or a recorded performance. Punjabi authoring and voice production
remain unimplemented. Narrator perspective never becomes protagonist knowledge.
Save/load silently rebinds the view; rewinding removes later cues.

## Integration and validation

The current work joins the tested supply branch, the separate political/perception
experiment, and the previously prepared licensing/four-language documentation.
The full childhood, riding, command and economic suites remain in the runner.
The original generic 180-metre layout is retained as a non-imported source study
under `archive/gujranwala-layout-v0/`; it is not substituted for working missions.

Run `python tools/check_reconstruction.py` for offline checks and
`python tools/run_checks.py --godot /path/to/godot` for the native suite.
The latter must pass before describing this integration as runtime-verified.
CI also captures the district, verandah, well and paused evidence notebook.
Software-rendered captures are not human playtesting or historical verification.

## Next evidence needed

A dated construction-phase study, rights-cleared measured drawings, early town
plans and archaeology are needed before expanding the exact haveli footprint or
asserting an eleven-gate 1792 wall alignment. Crop species, prices, street widths,
water yields and household population remain uncalibrated. Later imagery can
constrain hypotheses, but cannot silently become start-year truth.
