# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from
Gujranwala and the Sukerchakia home territory toward wider command. Travel,
relationships, provisions and incomplete knowledge matter before empire management.
The stable character ID remains `ranjit_singh`; the childhood display name and
later public names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development, not a finished city or historical survey.**

**Visual target:** grounded, high-fidelity historical realism. Current character,
horse and environment proxies are not the intended finished style.
[Street, interior and roofscape reference targets](docs/VISUAL_REFERENCE_TARGETS.md)
apply to the existing childhood benchmark, not a new engine or copied setting.

**Begin in Gujranwala:** the focused Begin action opens Maha Singh's authored
family recollection, then resumes the existing childhood Home. Learn the yard,
hear the sealed message, ride and train, follow the hunting trail, return alive,
hear the household, investigate the bend and give your observed account. Compact
guidance then points to the quartermaster; hearing and accepting the allowance
still uses the existing dialogue and world authority.
[Opening sequence and qualification](docs/BEGINNING_SEQUENCE.md) ·
[Current intro development window](docs/INTRO_BUILD_WINDOW.md)

## Current foundation work: movement before more content

The existing stories remain intact. A new **Movement qualification** menu entry
uses the **same Player scene and motor** to test analog control, isotropic
acceleration, buffered jumping, low vaults, mantles and a connected gap/drop route.
It includes an articulated skeletal proxy and collision-aware camera, not final art.

Campaign scenes retain their qualified legacy acceleration profile, with analog
magnitude now preserved. Vertical traversal stays opt-in until campaign saves,
interactions and companions support it. The course has its own isolated save slot;
it does not advance Buddh's biography or replace a story chapter.

[Movement controls, rules, evidence and remaining gates](docs/LOCOMOTION_FOUNDATION.md)

Mounting now checks the rider's full collision shape along the approach. Narrow gaps
and low barriers block the transfer even when the horse is visible; refusal preserves
the walking state. [Mounting and riding physics](docs/RIDING.md#spatial-checks).

## Play

Import `game/project.godot` in standard **Godot 4.5.1** and press **F5**.
No .NET SDK, Python service, Bevy process or NET server is required to play.
Choose **1792 · Buddh Singh · Home territory** for the integrated home chapter.

Learn the yard, hear a letter read, ride, train, follow traces, survive an authored
ambush, investigate and report home. After the inquiry, administer a limited
household allowance: carry provisions to market, physically escort a carrier home,
hire workers or guards, build infrastructure, and meet food, fodder and wage costs.
Your personal purse and the household coffers are separate. Contracts pay once.

[Full walkthrough, rules and save behavior](docs/PLAYABLE_GUIDE.md) ·
[Household economy](docs/GUJRANWALA.md)

## Gujranwala now has an evidence-bound setting

The existing missions run within a compressed **56 × 56 metre** test area. The
new reconstruction layer adds a verandah arcade, open forecourt, courtyard
frontages, a collision-tested well, market props, field strips and ambient figures.
Peripheral buildings are scenery, not a secretly enlarged playable city.

**F2** opens a paused reconstruction notebook. Feature records bind original
geometry to source claims, uncertainty classes and an exact content digest.
Later or disputed monuments cannot silently appear at the 1792 start date.
The notebook is a developer reference, not information granted to Buddh.

**Shah Muhammad** is the retrospective narrator. Four milestone cues currently
use original English development text—not historical verse, translations or a
recorded voice. They observe the existing state without altering resources,
knowledge or save history. Punjabi authoring and voice production remain future work.

[Reconstruction and historical sources](docs/GUJRANWALA_1792.md) ·
[Integration receipt](docs/GUJRANWALA_INTEGRATION.md)

The [courtyard detail pass](docs/COURTYARD_FABRIC_DETAIL.md) adds photo-informed
cusped reveals, grouped shaft detail, recessed panels and timber bearers to the
existing bays. Geometry and trim colours remain authored interpretations, with
unchanged collision and campaign state.

**Punjab ecology mosaic:** F7 → **Ecology / seasonal study** previews cultivated
margins, grazing/scrub, riverine thickets and wetland edges in the same Home.
Dry, monsoon and receding-water appearances retain separate source dates and
reconstruction decisions. Movement, concealment and seasonal-route effects remain
proposed mechanics. [Evidence, scope and controls](docs/PUNJAB_ECOLOGY.md).

## New playable task: Water for the Household

After accepting the household allowance, ask the quartermaster for the optional
water round. Leave through the courtyard's open front, take the east lane to the
well, face it and press **E**. Draw a load, carry it back on foot, and deposit it
with the quartermaster. Two trips complete the six-unit assignment. Drawing takes
180 existing physics ticks; leaving cancels without consuming water. A full open
carrier slows movement and prevents mounting until deposited.

The task, pending draw and transfers use the existing save and clock. Its six
units are not litres or a measured well yield. It grants no repeat cash reward;
recurring consumption and water-dependent production are not implemented.

[Water-round walkthrough and research](docs/GUJRANWALA_WATER_ROUND.md)

## Playable youth stories (this development branch)

The childhood years now have a **28-entry playable-story development slate**, not
just a tutorial or codex. The **Bhangi Bazaar Brawl** is the first new playable
increment: after the household inquiry, meet Mela and Jiva at the western market,
walk to the challenge, stand and counter or leave together, regroup and report
home. **Q** guards, **left click** counters, **E** interacts. The two fictional
friends physically follow within sight; they are not hired garrison guards.

F5/F9 use the separate youth-bazaar slot; the confrontation has a whole-world
retry sidecar. **T** opens the paused full story slate. Only the brawl is newly
playable here; other entries explicitly distinguish existing seeds from planned
work. Lore and conflicting versions remain included, with evidence and timeline
framing kept separate from the stable actor identity.

[Youth walkthrough, all required stories, sources and remaining work](docs/YOUTH_CAMPAIGN.md)

## Other retained modes

The menu also retains the separate Lahore command story, houses-and-rivals patrol
sandbox, and the political-exposure/perception experiment. These are development
scenarios, not completed transitions in the childhood-to-Lahore biography.

## Controls

| Control | Action |
| --- | --- |
| WASD / Shift / mouse | Walk, run and look |
| F / mounted W,A,D | Mount or dismount / ride and steer |
| E / B | Interact / oral household accounts |
| Q / left click / C | Childhood guard / counter / quiet approach |
| G / J / F1 | Follow or hold where available / journal / pause |
| F2 | Paused reconstruction notebook in the home chapter |
| F5 / F9 / R | Save / load / restore childhood checkpoint |

The detailed guide covers mounted gaits, alternate modes and optional framing.
Loading and checkpoints retain their existing validation and rollback semantics.

## Architecture

Godot owns the active game, state and clock. Blender is the intended asset-authoring
path. The shared **C++–Rust–Python–Julia** architecture remains documented for
bounded provider workloads; this update does not pretend all four runtimes have
been integrated. Bevy and Notations Engineering Terminal remain optional external
simulation/experiment providers, not competing game loops.

[Shared game architecture](docs/SHARED_GAME_ARCHITECTURE.md) ·
[Campaign direction](docs/COUPLED_CAMPAIGN.md)

## Develop and verify

```sh
python tools/check_project.py
python tools/check_reconstruction.py
python tools/run_checks.py --godot /path/to/godot
```

The runner retains every inherited gameplay suite and adds reconstruction,
narration-isolation and political/perception tests. GitHub Actions uses pinned
Godot 4.5.1, retains logs and exact source, and produces software-rendered captures.
A test suite passing is not human playtesting or verification of historical truth.

```text
game/       Game, state authority, original meshes, source-bound layout and tests
data/       Design fixtures and historical source index
docs/       Player guide, research, design, architecture and rights
schemas/    Retained world-state contract
tools/      Offline and native verification runner
archive/    Earlier disconnected layout study, not an active world
```

## Rights

**Copyright (c) 2026 Cartesian Graphics. All rights reserved.**
Original protected game code and content are proprietary unless explicitly
licensed otherwise. Engine and third-party rights remain separate. No claim is
made over historical facts or public-domain material. No archival photos, copied
plans, licensed game assets or voice recordings were imported for this update.

[LICENSE](LICENSE) · [Licensing scope](docs/LICENSING.md) ·
[Asset rules](docs/ASSET_LICENSING.md) · [Third-party notices](THIRD_PARTY_NOTICES.md)

## Sukerchakia household service (this development branch)

After the home inquiry and allowance, hear the quartermaster's service brief.
Visit the market or eastern well approach, then commit one already-hired,
provisioned guard. The home post becomes empty while he attends and physically
returns. Hear his account before reusing the detail. Existing food, wages,
production, supply shortages and saves remain authoritative.

F2 extends the Gujranwala research notebook with distinct person/household/Misl
records and source limitations. These two local errands are original fiction,
not a completed regional Misl simulation. No main merge or other draft merge is
implied by this branch. [Rules, research, controls and checks](docs/SUKERCHAKIA_SERVICE.md).

### Home visual study — same childhood entry

The Home entry now includes an original material/mesh study for its courtyard,
stable and market. **F7** opens paused comparison controls (retained greybox,
daylight, golden hour, evening); it does not change the calendar or saved world.
The visual kit retains original collision, missions, horse and state authority.
The scenery and characters remain development reconstructions/proxies, not a
surveyed 1:1 Gujranwala or finished production art.

See [the implementation and native capture command](docs/HOME_VISUAL_STUDY.md).

## Inhabited courtyard: integrated smith commission

The current Home entry now brings PR #21's finite workshop recipe into the visual,
youth, water and service build, without importing the older town/remount branch.
After the inquiry and allowance, speak to the quartermaster, carry fuel/payment to
the west courtyard smith, collect the finished tools, and physically return them
to household stock. This is an original fictional errand and prototype workplace,
not a surveyed historical building or completed production art. F5/F9 use a new
workshop-aware whole-run slot; the earlier youth save is an explicit journal import.

See [the integrated workshop guide](docs/HOME_WORKSHOP_INTEGRATION.md) for the
finite recipe, shared-clock/replay boundaries and qualification methods.

```sh
python tools/capture_home_art.py --profile workshop --godot /path/to/godot --output /existing-parent/new-run
```

The default Home-art capture profile, F7 comparison, full-envelope atlas and active
Ranjit childhood priority remain. The five workshop views come from an executed
input journey and native Godot rendering, not concept-art generation.

## Courtyard: authored asset and walking-view increment

The existing Home now loads a Blender-authored bay kit and a fitted childhood
costume study, with attributed CC0 dirt/plaster samples and explicit post
collision. F7 also compares the earlier study, close/original walking camera and
compact/original task HUD. The same smith commission, clock and saves remain.
This is a prototype improvement, not the completed high-fidelity visual target.

[Implementation, source assets and qualification](docs/COURTYARD_AUTHORED.md) ·
[New references and Ranjit's uncovered/plain-cloth direction](docs/REFERENCE_BATCH_20260929.md)

```sh
python tools/capture_home_art.py --profile courtyard --godot /path/to/godot --output /existing-parent/new-run
```

The courtyard profile renders retained observations of real input-driven walking
through the existing player camera; its video is not a physical-GPU FPS claim.

## A Short Walk — bazaar direction (this branch)

The existing Bhangi Bazaar Brawl now gives Mela and Jiva distinct dialogue, an optional
pre-decision exchange, articulated supporting figures, visible guard/counter reactions,
local nonvocal foley, compact action cues and outcome-specific homecoming text. The
three original outcomes, timing, player/companion collision, money and saves remain.
This is direct game content, not another terminal feature. [Play and limits](docs/BAZAAR_DIRECTION.md).


## Gujranwala beauty pass

The existing Home visual study now adds a reversible beauty layer over the authored courtyard: shallow plaster/ochre accents, dark jali depth, six garden pockets, clustered market pottery/textiles, a low reflective basin and warm practical lights for the existing golden-hour/evening F7 presets. It changes presentation only; collision, navigation, water gameplay, economy, saves and historical authority remain unchanged.

See [the beauty-pass scope and limits](docs/GUJRANWALA_BEAUTY_PASS.md).

A second reversible depth/patina pass extends the composition beyond the immediate courtyard with wall-top rhythm, peripheral pavilion silhouettes, selective plaster aging, high household cloth, distant foliage and warm evening opening glows. See [the depth/patina scope and limits](docs/GUJRANWALA_DEPTH_PATINA.md).

A third reversible eye-level craft pass adds restrained trim, dark timber reveals, plinth accents, selective repair fields, sparse wall hardware and two quiet storage corners. See [the microdetail scope and limits](docs/GUJRANWALA_MICRODETAIL.md).

The next increment improves the existing assets: metre-scaled plaster, directional timber grain, filtered cloth weave and twelve fitted hollow vessels inside their original envelopes. Six engine inspection views include a same-camera daylight/golden-hour/evening comparison with independent PNG verification. Explicit CI error guards and renderer cleanup address shutdown errors that previously escaped qualification. See [material fidelity, verification scope and limits](docs/GUJRANWALA_MATERIAL_FIDELITY.md).

The main menu also offers a playable horsecraft study: the existing motor drives two independent horse bodies, with a supported standing stance, counterbalance, four separate matchlock charge slots and collision-checked target shots. It develops a candidate Maha Singh remembered feat while preserving the campaign, riding-save and father-interlude contracts. The specific two-horse/four-matchlock anecdote remains source-unlocated. [Controls, evidence and production limits](docs/HORSECRAFT_STUDY.md).

The Home riding lesson now offers that tale through the stable trainer after the first riding gate. Its playable flashback teaches standing on one horse, standing across two horses and mounted matchlock handling; completing all three exercises unlocks those capabilities in the existing Home save. Older saves acquire no inferred skills. The Home remains parked in-tree during the lesson and resumes with its prior clock, pose, economy and memories. The later fixed-ending Mahan retrospective remains a separate story sequence.

The production Home entry opens with Maha Singh telling a very young Buddh/Ranjit Singh about Charat Singh, his grandfather. Ten original dialogue pages cover the family in Gujranwala, Desan Kaur, the campaigns from 1761 to 1767, and Charat's death and succession. Next/Previous and Skip return to the retained Home before its playable childhood begins. The conversation has no asserted historical date or quotation and grants no skills or journal knowledge. Campaign claims, conflicting chronology, and the supplied cinematic research candidates are recorded in a separate source ledger. [Opening, controls and evidence](docs/CHARAT_CAMPAIGN_INTRO.md).

The beginning presents one compact objective with actual progress and contextual controls through walking, conversations, riding, practice, tracking and the household inquiry. Named lesson markers remain visible when earned, the courier's interactions stay together, and the optional standing lesson appears after the first riding gate. Eleven production-camera frames cover the first standing exercise and its incomplete return. The extended eighteen-frame route earns the riding skills, completes the original lessons and return, hears the household, physically investigates with its guard, reports home and exercises declared native save rollback. Source, runtime, execution, PNG/RGBA, receipt, checkpoint and save evidence are independently verified. Exact observed status belongs to the draft PR and retained execution, not the frame count alone. [First-play sequence and verification](docs/BEGINNING_SEQUENCE.md).
