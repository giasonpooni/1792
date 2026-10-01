# Historical world foundation — 1792

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## Production contract

The entire **geographic envelope exists as a single production plan from the
beginning**. Narrative detail remains focused on Ranjit's childhood through the
Lahore prelude, followed by his complete life. Other protagonists remain deferred
DLC research. No completed biography is inferred from a catalogue entry.

The intended anthology spans approximately **1200–1873**, with Punjab and its
connected frontier worlds as the organising subject, not one unchanging polity,
one religious identity or a continuous family tree. The 1873 endpoint is an
editorial epilogue, not a claim that clan/biradari society ceased to exist then.
Religious figures are not embodied; religious sites are exterior-only. Sada Kaur
and Adina Beg are not playable. These presentation decisions do not erase their
historical consequences from future researched narrative.

## Run the actual increment

Open `game/project.godot` in the existing standard **Godot 4.5.1**, choose the
existing **1792 / Buddh Singh / Home territory** entry, and press **F3** when no
other dialogue is open. Select a place in the list or click its map marker; move
the inspection-year slider; scroll the source/uncertainty text. F3 or Return closes
it. The inspector uses the original chapter's modal pause and resumes that same
world. It does not select a campaign, time-travel, teleport, add knowledge or
modify any game save. F2 reconstruction and T youth-story catalogue remain.

The atlas is explicitly an **acquisition diagram**, not a screenshot of rendered
historical terrain. Unmapped places remain visible in the list without fabricated
points. Out-of-period/unknown presence is stated instead of hiding research needs.
The coloured theatre boxes are authored production extents, not historical or
modern state borders. No river, road or territorial polygon has been fabricated.

Offline checks and complete runtime qualification:

```sh
python tools/world_atlas.py
python tools/world_atlas.py --plan-tiles /a/new/path/world-acquisition.json
python tools/check_world_atlas.py
python tools/run_checks.py --godot /path/to/godot
```

The output directory must already exist. The acquisition command exclusively
creates a new output and refuses to replace an existing file. It makes no network
request and never reports an absent tile as loaded. Source, model and operation
identities are separate from the later execution/verification record.

## What is actually implemented

| Component | Implemented boundary |
| --- | --- |
| Global catalogue | 41 persistent place identities, 12 authored theatres; source, epoch, placement class, uncertainty and missing-geometry fields |
| Full-envelope indexing | 66–84 E, 24–38 N; 252 half-open one-degree acquisition cells; **all missing** |
| Metric conversion | Original WGS84 scalar-double geodetic/ECEF/East-Up-South transforms; inverse; bounded coordinate reframe; no global float32 positions |
| Local numerical contract | One metre per unit; explicit ellipsoidal heights; 2,048 m local radius; out-of-radius requests refuse instead of compressing geography |
| Read-only game view | F3 atlas in the same home entry; searchable visually through list/markers and year selection; source detail; responsive compact layout |
| Anthology registry | 31 editorial modules, 43 distinct named prospective protagonist identities including Ranjit; active/deferred and incomplete status |
| Exterior component | Real solid collision fixture, outside approach, on-foot/facing/ray access checks, period/frame identity and execution-time recheck |
| Fortune rules | Period-specific importance, bounded temporary luck, global/per-site cooldown, diminishing returns, separate conduct/merit, immutable staged receipts and bounded risk-modifier seam |

**Not implemented:** full terrain download/streaming, geoid conversion, historical
hydrology, surveyed settlement layouts, production monument meshes, actual
site-importance ratings, runtime physics-origin rebasing, persistent cross-cell
agents, regional fast travel, or a completed childhood-to-Lahore campaign.

The existing **56 × 56 m compressed home greybox is unchanged**. It has not been
rescaled, assigned a fabricated geographic survey or represented as all Gujranwala.
No other draft branch was silently merged. The original player, horse, water,
household service, youth brawl, movement course, state authority and checkpoint
semantics remain. There is no second clock, NET server, native provider or treasury.

## Scale is not accuracy

`1 game metre = 1 physical metre` is the coordinate scale, **not a claim of
one-metre measurement accuracy**. Geographic input is `[longitude, latitude,
ellipsoidal_height_m]`. Global ECEF is stored in arrays of scalar doubles; only
bounded local geometry may become a standard Godot `Vector3`. Local axes are
**X east / Y up / Z south**. The coordinate `reframe` helper is not a tested live
physics-world rebasing transaction; bodies, velocities, contacts and navigation
will require coordinated streaming integration later.

Six independent synthetic numerical fixtures were generated with **pyproj 3.7.2 /
PROJ 9.5.1**, using EPSG:4979→4978 and PROJ's cart/topocentric pipeline. They are
qualification coordinates, not surveyed historical sites. The native tests compare
ECEF/local results, inverse transforms and metre displacements, including a point
across the antimeridian and a near-polar origin. No pyproj dependency is needed to
play or run the retained fixture checks.

Godot's reference documentation distinguishes scalar 64-bit floats from default
32-bit vector components. A full double-precision engine is a different build;
we do not silently switch the project's standard engine.

- [Godot 4.5: large world coordinates](https://docs.godotengine.org/en/4.5/tutorials/physics/large_world_coordinates.html)
- [PROJ: cartesian conversion](https://proj.org/en/stable/operations/conversions/cart.html)
- [PROJ: topocentric conversion](https://proj.org/en/stable/operations/conversions/topocentric.html)

## Evidence and reconstruction admission

`game/data/historical_world.v1.json` is the current catalogue. In this increment:

- **A:** one published modern reference point, Rohtas. UNESCO supplies
  N32°57′45″ / E73°35′20″ and construction beginning in 1541. Neither positioning
  accuracy nor ellipsoidal height nor a complete 1792 footprint is supplied.
- **C:** 37 coarse, explicitly authored map-label anchors for research orientation,
  rounded to 0.1 degrees, with a declared 20 km provisional uncertainty. These are
  not independently sourced coordinates and are not admitted scene placement.
- **D:** three unlocated research entries. No coordinate is fabricated.

The remaining 40 entries are research targets, not 40 historical reconstructions.
All geometry and importance arrays remain unadmitted. The JSON gate refuses
invented footprints, terrain assets, unsourced periods and importance ratings.
The point registry must not be misused as a scene importer. Its runtime reads
trusted packaged content; the Python authoring gate additionally rejects duplicate
JSON keys. Save authentication and hostile-content sandboxing are not claimed.

For actual terrain acquisition, **SRTM 1 arc-second** is a possible modern
baseline: the USGS specifies roughly 30 m samples, February 2000 observation,
WGS84 horizontal and **EGM96** vertical datum. It is neither a 1792 surface nor
one-metre terrain. An EGM96 height must not be passed as an ellipsoidal height
without an explicit geoid transformation and its provenance.

- [UNESCO: Rohtas Fort](https://whc.unesco.org/en/list/586/)
- [USGS: SRTM 1 Arc-Second Global](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm-1)

No source photographs, prose, plan imagery, clothing art, engine binaries or fonts
are included. Subsequent terrain/photogrammetry licences and attribution must be
recorded per actual acquired asset, not inferred from a search result.

## Exterior prayer / fortune contract

`fortune_rules.gd` is an **authored gameplay reducer**, not theology, a comparison
of religions or a validated model of human conduct. Importance is a reviewed
period/site-specific game parameter (1–5); it is not automatically inferred from
current fame, religion, UNESCO status or the player's affiliation.

The current `sacred_exterior.gd` builds **only explicitly opted-in synthetic
qualification volumes**. Calling it with `reviewed:gameplay` still refuses: a plain
box may not impersonate an admitted historical building. No invented shrine has
been inserted into the compressed childhood yard to make a fake playable claim.
Real-site asset admission, importance review, campaign save integration and the
actual prayer interaction UI are the next content gates.

At 60 Hz, the fixture rules use a 3,600-tick global cooldown, 216,000-tick per-site
cooldown and 18,000-tick effect duration. These are tunable play-time constants,
not historical days or religious prescriptions. A first visit's temporary benefit
is `min(0.10, 0.02 * importance * repetition * consistency)`. Repetition declines
with visits; consistency depends only on authored conduct. A weaker benefit does
not prolong a stronger existing one. The game authority supplies ticks; no new
clock, random generator or asynchronous service is introduced.

Conduct and prayer merit are separate. Conduct is bounded at −100…100; accumulated
prayer merit is capped at 10. Prayer cannot erase serious negative conduct,
concrete social grievances, unpaid wages, family memory or historical outcomes.
A permitted future hazard caller supplies opportunity and grievance independently.
Zero-opportunity hazards remain absent; impossible/certain and fixed-history events
are unchanged. Luck changes only bounded uncertainty classes—help, warning,
supply discovery, wound recovery, betrayal, assassination and desertion—not damage,
weather, troop creation or automatic survival of a scripted death. Actual
assassination/desertion agents have **not** been spawned by this increment.

The outside interaction checks the actor's real capsule position, the selected
period, frame, mounting, orientation and eye-ray occlusion again when executing.
A wall inserted after access was inspected invalidates the operation. An injected
interior position does not admit prayer. The synthetic solid enclosure is real
collision, not a UI-only “cannot enter” message.

The bounded 128-event receipt stream validates sequential identity, ticks, content
digest, operation fields, periods, cooldowns and replay. Operations stage detached
state before promotion. This is deterministic consistency checking, **not signed
saves or proof that an externally fabricated receipt was physically played**.
No file is written into a player's campaign slot by this test seam.

## Anthology and art-production roadmap

The machine-readable outline is `game/data/anthology.v1.json`; the table in
[ANTHOLOGY_PLAN.md](ANTHOLOGY_PLAN.md) is its readable companion. Dates there are
editorial research windows, not settled lifespans. Earlier planning conversations
contained conflicting dates and overstated genealogies; those do not become
verified facts because they were repeated. In particular, the Mahan/Charat
chronology, Gakhar episodes and early Khokhar identities need source review.
The currently qualified childhood chronology is not silently rewritten here.

Every future place needs separate location, terrain, hydrology, existence interval,
footprint, architecture and material-culture claims. Clothes need period, region,
occupation, wealth and evidence—not generic religion/caste “skins”. Kinship,
biradari, household, dynasty, military faction and religious affiliation are
separate relations. Architectural components can be reused without asserting that
a later monument existed earlier. Religious buildings remain exterior-only;
ordinary secular interiors are not prohibited by this rule.

The next physical-geography gate is one acquired, licensed and checksum-bound
terrain patch near the active Gujranwala campaign, with known horizontal/vertical
datums and a reviewed historical adjustment layer. The full-envelope acquisition
index remains present during that work. Migration of the existing mission core
requires new routes, distances and replay qualification; scaling the greybox is
not that migration.

## Verification boundaries

`tools/run_checks.py` retains all inherited suites and adds 34 offline contracts
plus `test_world_atlas.gd`. The latter tests scalar maths against independent
vectors, malformed catalogues, fortune replay, actual shared-player movement into
an exterior approach, real collision/late occlusion, and F3 pause/isolation in the
actual home launch. `render_world_atlas.gd` produces two real atlas screenshots
(1280×720 and 800×450) and one clearly labelled synthetic exterior view.

The workflow checks out the exact PR head and retains source tree, logs and
execution identity. Passing these checks is not human playtesting, a physical-GPU
performance result, a complete world map, a historical truth certificate, a
shipping console qualification or proof of hostile-save resistance.
