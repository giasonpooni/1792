# Gujranwala: connected neighbourhoods

The **same Home territory entry** now opens into a larger Gujranwala blockout.
Finish the existing childhood lessons, ambush and household inquiry. The two
wooden town gates then open. No allowance, remount quest or new menu selection
is required to explore. Both the independent and guarded inquiry routes unlock
the same space; the guard's existing agreement ends before town access opens.

## Walk out of home

Leave the courtyard through its open front. Continue north through the gateway
beyond the practice field, or turn west past the existing supply market and go
through the western gate. The bazaar, well square and workshops are connected
by collision-supported streets. You can walk or ride the **existing household
horse**, save in the new districts, and return to the original missions.

The expanded envelope is **86 by 108 local metres**, including the retained
56 by 56 metre mission core: `x = [-58, 28]`, `z = [-80, 28]`. It is a compressed
playable neighbourhood, not all of Gujranwala, a surveyed street map, or a Misl
border. The original tutorial, ambush, household, trader, caravan and remount
anchors have not moved. No new region streaming or geographical campaign
transition is implemented.

Seven courtyard compounds provide residential courts, a pottery workshop,
a cloth workshop, a grain yard and a stable court. Flat rear roofs, parapets,
verandahs, timber lintels, latticed openings and exposed brick courses give the
blockout an architectural vocabulary. Courtyards have actual open entrances;
rear and side room volumes are **not enterable furnished interiors**. Six
additional bazaar stalls, a ring-built well, an orchard and instanced field rows
fill out the town. These are original procedural assets, not finished Blender
art or textures copied from photographs.

## Examine, remember, return

**E** examines five local landmarks when you are on foot, close enough, facing
them and have an unobstructed character-eye ray. **M** opens remembered places;
**J** includes the same firsthand observations alongside the existing memories.
Unvisited landmarks are not listed in the remembered-places panel. These local
observations do not grant remote reports, reading ability, money, grain, mounts,
automatic corroboration or historical certainty. New sacks and stalls are scene
objects, **not extra stock or additional trade interfaces**.

The five places are the well square, potter's court, cloth workshop, grain yard
and cultivated edge. Their prose is authored first-person connective material.
The town adds exploration, not a second trading economy or a populated-city AI
system. The original quartermaster and supply trader remain the operational
interfaces. Their active obligations continue on the same clock while you
explore; town dialogue and remembered-places panels pause the world as before.

## Persistence and compatibility

The new scene is `settlement/town_chapter.gd`, extending the existing remount,
supply and childhood controllers. `town_state.gd` extends the same authority and
uses **one `_state` and the existing `childhood.tick`**. `settlement` is an
optional root member, activated after the inquiry. It binds map ID/seed and at
most five original landmark receipts with visit tick and local position. Journal
text is derived from the declared layout, not arbitrary prose in a save file.

F5/F9 use **`user://1792-gujranwala-town-v1.json`**. M offers an explicit import
of the older remounts slot. The inherited quartermaster's prior-supply import and
the journal's childhood import remain. Old saves receive no invented visits;
an old-format save outside its original map is refused. Wrong map IDs, seeds,
unknown or duplicate landmarks, extra fields, future/fractional ticks and remote
visit receipts are refused before replacing live state. The scene separately
checks saved standing space against real collision geometry.

Earlier checkpoints remain in their original envelope format: the settlement
member does not exist yet when the normal pre-ambush/return checkpoints are
written. Restoring an earlier whole-world state closes the town gates and
removes later exploration, resources and knowledge rather than merging them.
The checkpoint store, original PackedScene and existing save slots are unchanged.
The map binding and receipt validation establish internal consistency, not
signed-save authenticity or independent proof that movement happened.

## Minimal changes to shared code

`childhood_state.gd` gains a code-owned `valid_player_point` hook. Its default is
the **unchanged** original static `valid_point`; the town subclass opts the player
and horse into the larger declared envelope. Their speed, timestep and riding
checks are retained. Assailants, household escort, caravan and remount messengers
keep their existing smaller spatial contracts. They do not acquire new travel
capabilities by accident. The town's runtime and save gates both require the
completed household inquiry before an expanded player/horse pose can be accepted.

`home_chapter.gd` extracts its existing four-wall construction into an overridable
method; its default geometry is unchanged. The town replaces that outer test
boundary with two explicit gate openings and wider supported terrain. The
existing household/mission geometry is otherwise retained. `home_launch.gd`
selects the extended controller within the original entry.

There is no new mandatory package, native library, service, engine, world clock,
resource ledger, NET/SCR import or geographical coordinate conversion. The
existing C++/Rust/Python/Julia architecture direction is not a reason to send
these Godot scene operations through four runtimes. Specialist integration stays
an explicit later capability.

## Concurrent parent update retained

During development the remounts parent advanced to `06fccd1` with its
research-informed brick/plaster shader, blind courtyard bays, stable details,
background silhouettes and F2 reconstruction notes. This branch composes that
increment rather than replacing it. All its source files and assertions remain
unchanged. The extended controller hides only old visual-only silhouettes whose
centres are now inside the new playable districts; it retains the existing core
masonry and timber dressing. F2 identifies the original 56 m mission core within
the expanded town and remains outside the character's knowledge. Both sets of
research records keep their own claims and limitations.

## Research basis and reconstruction limits

Research records: `data/history/gujranwala_town_sources.v1.json`. The existing
historical-method and naming policies continue to apply.

The Pakistan Department of Archaeology and Museums' **Ranjit Singh Birthplace**
entry describes brick/plaster construction with wood, courtyards and halls; it
suggests more greenery/open space around the late-eighteenth-century mansion.
The entry itself cites Asian Historical Architecture and labels the monument's
relative chronology 1799–1849. It is an architectural-type reference, **not a
survey proving this game's exact 1792 layout**, nor a primary eyewitness account.
Its present-day coordinates are not applied as if our compressed game were GIS.

The same department dates construction of the **Mahan Singh samadhi** to 1835
and attributes **Sheranwala baradari** to Ranjit Singh's reign. Neither building
is spawned in this 1792 scene. The death-date conflict already recorded by the
Mahan interlude is left unresolved; this town expansion does not choose a year,
invent an accession or bypass that future narrative gate.

Source pages inspected September 28, 2026:
- https://doam.gov.pk/public/sites/10111 — Ranjit Singh Birthplace.
- https://doam.gov.pk/public/sites/10110 — Mahan Singh Samadhi.
- https://doam.gov.pk/public/sites/6546 — Baradari at Sheranwala Garden.

Exact building footprints, street widths, gateway placement, craft-yard contents,
planting and dialogue are **authored**. Architectural context is reconstructed
(class B); compressed scale/access gates are gameplay abstraction (C); exact
placements and connective descriptions are fictional (D). No claim is made to
have read the complete historical bibliography or reconstructed the actual city.

## Run the checks

```sh
python tools/run_checks.py --godot /absolute/path/to/Godot

# Actual render fixtures, separate from the input-driven gameplay tests:
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /absolute/path/to/Godot \
  --path game --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_town.gd
```

The town suite checks input-driven walking through both gates and multiple
courtyard doorways, five actual visibility-gated interactions, mid-town save/load,
actual mounted travel through the north gate and safe dismount, physical
occlusion, blocked-save refusal, rollback, finite map limits and tampering.
The initial completed-inquiry state is explicitly a fixture; no poses or mission
progress are injected after either travel route begins. The inherited suites
still test the real childhood/inquiry/caravan/remount journeys separately.
Render fixtures use declared camera/pose setups, not evidence of human play.

Build-and-audit found a premature settlement field breaking old checkpoint
readers, a well support occluding the intended approach, a wrong blocked-room
test coordinate, JSON floating-position comparison assumptions, and a gateway
lintel low enough to catch the actual mounted collision hull. All were corrected
and their checks retained. The earlier checkpoint store was restored unchanged;
the new field begins only after inquiry completion. Gate clearance was raised,
not the horse collider shrunk. No tests were removed to turn failure into pass.

`town-qualification.yml` retains the exact source, logs, tour trace and eight
software-rendered views. The full source runner includes all inherited suites.
Consult the PR's exact head/run for observed results: a workflow definition is
not proof of a pass. Linux/Mesa rendering is not a physical-GPU benchmark,
Windows save qualification, controller accessibility test or human playtest.
