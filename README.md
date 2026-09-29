# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from
Gujranwala and the Sukerchakia home territory toward wider command. Travel,
relationships, provisions and incomplete knowledge matter before empire management.
The stable character ID remains `ranjit_singh`; the childhood display name and
later public names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development, not a finished city or historical survey.**

[Play](#play) · [Project scope](#scope-and-development-order) ·
[Coupled engineering experiment](#coupled-engineering-experiment) ·
[Develop and verify](#develop-and-verify)

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

## Scope and development order

The intended product is an embodied historical open-world biography: childhood,
adolescence, relationships, travel and increasing responsibility lead toward the
full Ranjit Singh narrative. First complete the rich Gujranwala childhood and
adolescent campaign through the prelude to Lahore, then the Lahore campaign and
remaining life story. Historical-character DLC production follows the completed
main narrative, not the other way around.

Plan the wider geographic envelope from the beginning, while building playable
detail outward from home. Evidence-supported 1:1 terrain and location fidelity
are reconstruction targets, not claims about the current compressed test cell.
Unknown historical layouts remain explicit reconstruction choices. Visual beauty,
movement, interaction and narrative are joint production priorities, not a choice
between an empty beautiful map and mechanics with indefinitely deferred art.

Oral tradition, differing accounts and dramatized youth stories belong in the
authored campaign. Preserve their attribution and distinguish historical claims,
later tradition, inference and original fiction rather than silently promoting
all generated material into historical fact.

## Coupled engineering experiment

**1792 is both a game project and the first major reference workload for an
industrial agentic game-development experiment.** Its ambition motivates a second
deliverable: reusable production workflows that help a small human-led team turn
research and creative direction into coherent, tested, playable content.

That work belongs in
[Notations Engineering Terminal](https://github.com/giasonpooni/Notations-Engineering-Terminal),
with **Notations Game Foundry (working name: NGF)** as a game-production workload
on the existing workbench, not a new engine inside this repository. The question
is whether typed work orders, bounded tools/agents, retained evidence and
independent acceptance gates can increase integrated output without supervision
and repair consuming the gain. It is an engineering hypothesis, not a claim that
autonomous large-studio production has already been achieved.

```text
1792 requirement → bounded production work → candidate artifact
       ↑                                          ↓
       └── playable result + review ← checks + controlled integration
```

Measure accepted and integrated work per human hour, compute/provider cost,
review and rework effort, regressions, visual/playtesting quality and actual reuse.
Compare equivalent tasks with fixed acceptance criteria; count tooling setup and
failed attempts, not just successful generation. A working production system must
improve the game rather than only produce more files, plans or agent activity.

**Current boundary:** NET's [production-controller PR #65](https://github.com/giasonpooni/Notations-Engineering-Terminal/pull/65)
is draft and unmerged as of September 29, 2026. Its
[pinned implementation guide](https://github.com/giasonpooni/Notations-Engineering-Terminal/blob/98386f4dfa621f6340670755603abd229be4684f/docs/NET_PRODUCTION.md)
describes a local sequential controller with declared parameter repairs and a
synthetic Godot courier fixture. It does **not** attach this game or provide an
autonomous asset factory. The next engineering gate is one actual 1792 scenario
or asset operation with a fixed acceptance contract and retained failure/success
evidence, demonstrated back in a playable build.

Godot remains the game-state and clock authority. Story, art direction, source
interpretation, sacred-site rules, saves and release approval stay game-owned;
automation does not get to redefine its own success criteria. Development-time
agents do not add a live AI service requirement to playing 1792. Shared tooling
may later benefit sister titles, but does not move them ahead of this campaign.

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
