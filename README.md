# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from
Gujranwala and the Sukerchakia home territory toward wider command. Travel,
relationships, provisions and incomplete knowledge matter before empire management.
The stable character ID remains `ranjit_singh`; the childhood display name and
later public names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development, not a finished city or historical survey.**

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
schemas/    Retained world-state contract
docs/       Player guide, research, design, architecture and rights
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

## Deferred DLC foundation: Fall of Empire

[Fall of Empire](docs/FALL_OF_EMPIRE.md) now has a source-scoped 1839–1859 campaign
contract and a standalone **synthetic authoring desk** for opposing perspectives,
delayed reports and postwar closure. It is not a playable historical campaign.
The ordinary Home chapter, main menu and saves are unchanged; the full Ranjit
Singh narrative still precedes DLC production. Run the isolated desk with
`godot --path game res://dlc/fall_of_empire/desk.tscn`.
