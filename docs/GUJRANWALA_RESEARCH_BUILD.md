# Gujranwala: research-to-scene increment

## Scope

The playable container is still the same **56 x 56 metre home cell**, with the
original tutorial, ambush, household inquiry and supply routes. It is not the
whole town, a surveyed 1792 street grid or the historical boundary of the misl.
The new setting improves material character and usable domestic space while
keeping known training and escort routes intact.

This work uses the nominated Latif account plus explicitly identified outside
research. The attached AI conversations are bibliographic leads and creative
framing, not transcripts of the nominated books or independent corroboration.
Latif remains the project's selected **biased narrative account**. The source
records do not relabel it, Griffin, Suri, Gardner or Shah Muhammad as impartial.
No private conversation dump is published in the repository.

## Consulted sources and actual support

The machine-readable record is
`game/territory/settlement/gujranwala_research.json`, reviewed 2026-09-28.
It retains source IDs, URLs, passage locators, perspective, consultation depth,
positive support and explicit limits. Scene features cite those source IDs or
are declared authored connective material.

| Source | What shaped the build | Boundary |
| --- | --- | --- |
| [Latif, History of the Panjab (1891)](https://archive.org/details/in.ernet.dli.2015.109845) | The passage about Charat's small mud fort at Gujraoli, used for troops and storage, supports the enclosure/store role. | Retrospective narrative, not an architectural survey. The Archive text is damaged by OCR; no exact foundation year or footprint is inferred. |
| [District Gujranwala: village origins](https://gujranwala.punjab.gov.pk/origin) | The regional account connects renewed settlement with restoration of wells and homesteads. | Supports a feature vocabulary, not the placement, mechanism or size of our courtyard well. Relative dates in the reproduced historical prose have not been silently assigned modern meanings. |
| [District Gujranwala: colonization](https://gujranwala.punjab.gov.pk/colonization_of_district) | Its administrative discussion places the site in the older Eminabad parganah and distinguishes earlier regional centres. | A reminder that the city and district are different spatial/historical objects; not a safe-territory polygon. Antiquarian conjectures elsewhere on the page were not used to populate the game. |
| [Hari Singh Nalwa Foundation](https://www.harisinghnalwa.com/gen_multan.html) | Its Gujranwala discussion places Nalwa's jagir/town development around 1815-1837. | A commemorative secondary account and a reason not to backdate that later town into childhood. Its cited original Cave-Browne text has not been independently read here. |

The Latif text passage consulted is in the Archive's
[full-text derivative](https://archive.org/stream/in.ernet.dli.2015.109845/2015.109845.History-Of-The-Panjab1891_djvu.txt),
lines 25195-25205 as served during this review. The locator and source terminology
are retained, but derivative line numbers are not printed page numbers. Page-image
confirmation and exact architectural documentation are still required before
claiming a measured reconstruction. No reliable 1792 cadastral plan was established
in this pass.

## Built now

A walk-in household store occupies an authored clear portion of the existing
courtyard. It has real wall/roof/rack/sack collision, an open human-scale doorway,
timber roof members and storage props. The player can enter, leave, and save/load
inside. It is **not** a second production building: it adds no inventory, income,
upkeep, building bonus or free loot to the existing economy. Visible sacks are
illustrative, not an exact count of the current stock.

A protected courtyard well provides a water landmark without an open fall-through
hole. Its central collider is deliberate; water drawing, disease, irrigation and
horse hydration are not simulated. A stable trough and market props make existing
activity legible. All positions and dimensions are authored, including the timber
lifting-frame depiction; source support for a regional well does not establish
that exact mechanism.

The retained enclosure receives a procedural earthen surface shader. Noise and
subtle courses change albedo and roughness without changing geometry or collisions.
This is not a measured material, physically calibrated deterioration or historical
brick-size reconstruction. Eighteen seeded low dwellings create a settlement
silhouette outside the playable cell; they are cosmetic, not visitable or streamed.
A fixed warm haze and light treatment provide atmosphere, not a new weather/time
simulation. **O** opens the research/authoring notebook and a haze toggle. These
presentation changes never alter health, vision state, inventory or knowledge.

No later New Town street grid, colonial gateway, railway, clock tower, tomb or
canal has been copied into the childhood scene based merely on present-day
photographs. Nor are missing shop counts, population estimates or borders invented
as source-backed facts. Subsequent reconstruction should add evidence-backed
anchors before expanding the terrain envelope.

## Engineering

`gujranwala_setting.gd` is a static representation attached by the existing home
chapter. It owns no campaign state, clock, ledger or character memory. Its local
seeded RNG does not consume gameplay randomness. The manifest records its geometry
revision, research-record ID, seed, piece count and layout digest. Repeated build
calls are idempotent. Equal-seed scenes produce equal manifests; this does not
claim bit-identical floating rendering across operating systems.

Existing home PackedScene, physics authorities, economic transitions, routes,
Mahan contract, historical roster and Lahore profiles are retained. New scenery
is checked by the existing staged load geometry tests; a previous save that now
intersects a new wall/well is refused, not teleported to an invented location.
The old Gujranwala slot is imported explicitly, never overwritten. See
[road persistence](DISPUTED_ROAD.md).

The same build includes the previously pending Shah Muhammad caption track and
optional disputed-road caravan. These are now registered in the standard runtime
and render suites. The temporary source-transfer workflow used to recover the
pending files is removed from the final tree. A recovered `BoxMesh3D` typo is
corrected to the existing Godot `BoxMesh` type before qualification.

## Checks and remaining work

`test_gujranwala_setting.gd` checks source references and boundaries, collider
presence, a real input-driven walk into/out of the store and around the well,
interior save/load, invalid well-intersecting load refusal, idempotent construction,
repeatable manifests and the knowledge/clock isolation of the O notebook and haze
control. Its distinct render fixtures include courtyard, store exterior/interior, well and 800x600
research-view captures. All older suites and the disputed-road suite run too.

This is not production art, full-city reconstruction, a water economy, measured
material simulation, Windows qualification, physical-GPU benchmarking or human
playtesting. The other active PRs for Mahan content, political exposure/vision,
licensing/four-language policy and missing-remounts investigation are not silently
merged into this branch. They remain independent work awaiting deliberate
integration and combined qualification.
