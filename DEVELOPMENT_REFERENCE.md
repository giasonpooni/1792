# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from
Gujranwala and the Sukerchakia home territory toward wider command. Travel,
relationships, provisions and incomplete knowledge matter before empire management.
The stable character ID remains `ranjit_singh`; the childhood display name and
later public names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development, not a finished city or historical survey.**

[Play](#play) · [Project scope](#scope-and-development-order) ·
[Expertise amplification](#expertise-amplification-and-transfer) ·
[Coupled engineering experiment](#coupled-engineering-experiment) ·
[Develop and verify](#develop-and-verify)

## Notation Systems and Cartesian Graphics

**Notation Systems is the parent organization of Cartesian Graphics.** Notation
Systems develops evidence-backed industrial intelligence, computational
instrumentation and tooling that connect domain expertise to bounded, inspectable
work. **Cartesian Graphics** is its games, graphics, physics and simulation
studio/label; **1792 is its primary historical-biographical game** and the first
major reference workload for the shared game-production engineering experiment.
This describes an organizational relationship, not a separate incorporation claim.

The firm's industrial domain identities remain **PAYLOAD** (physical operations,
facilities, materials and logistics, including Caravan), **LANDSHARK** (land/site
and spatial constraints), and **TRADEWIND** (contracts, prices and exposure).
PayloadOS and ESM retain governed industrial evidence/state responsibilities;
Dossier Services packages scoped service outputs. Games are not another
industrial evidence domain or a reason to replace those identities.

The studio's creative focus is historical lives experienced through geography,
relationships, limited knowledge and consequential action. These layered worlds
motivate physics-engine, graphics, coupled physical/multi-agent and multirate
simulation research. Such ambitions do not imply that every planned system or
a general-purpose multiphysics engine is implemented in this game.

**Shared primitives; separate state authority.** Reusable production tooling
belongs on the existing [Notations Systems Terminal (NET)](https://github.com/giasonpooni/Notations-Systems-Terminal)
workbench; specialist repositories keep their own mathematics, implementations
and licences. Godot retains the game's live state and clock; story, art direction
and game-release approval remain game-owned. Simulation output is not automatically
admitted industrial evidence, and shared tooling does not grant industrial
admission or release authority. Existing Cartesian Graphics copyright, licensing
and third-party notices are unchanged.

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
been integrated. Bevy and Notations Systems Terminal remain optional external
simulation/experiment providers, not competing game loops. Existing NET / `net` /
`ciw` interfaces are retained; this is not a universal cross-language compiler.

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

## Expertise amplification and transfer

1792 provides a concrete setting for **expertise amplification rather than
expertise substitution**. Academic study, oral renditions, remembered episodes
and creative direction can supply a rich authoring input; they are not all the
same evidence class. Preserve the original account, its attribution, competing
versions and unresolved questions before selecting a playable interpretation.

The intended production path is:

```text
expert account + references + creative constraints
        ↓
reviewed episode specification and explicit knowledge boundaries
        ↓
typed research / geography / asset / mechanics work orders on NET
        ↓
candidate content → execution observations → checks + editorial review
        ↓
accepted, integrated playable increment
```

This is a **workflow-development target**, not a claim that free-form stories
already compile automatically into games. The game owns its historical/editorial
policy, sacred-site rules, live state, saves, clock and release approval. Agents
may produce candidates within declared permissions; they do not choose their own
acceptance criteria, authenticate history or acquire release authority.

A correction affecting several scenes should eventually propagate through declared
dependencies and trigger scoped rebuilds, not repeated manual edits. That requires
actual dependency coverage and regression evidence; it is not established by this
README. Human effort should increasingly concentrate on consequential decisions,
while elicitation, research, review, integration and rework remain measured costs.

The reusable asset belongs on the existing NET substrate: bounded capture,
composition, execution, observation and verification contracts. Other stories,
subjects, sensor/DSP investigations and industrial tasks may use those contracts
with different domain schemas and validators. Cross-title and cross-domain reuse
is a hypothesis to test, not proof that a historical simulation validates a
physical process. **1792 remains a game worth finishing in its own right.**

## Coupled engineering experiment

**1792 is both a game project and the first major reference workload for an
industrial agentic game-development experiment.** Its ambition motivates a second
deliverable: reusable production workflows that help a small human-led team turn
research and creative direction into coherent, tested, playable content.

That work belongs in
[Notations Systems Terminal](https://github.com/giasonpooni/Notations-Systems-Terminal),
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
failed attempts, not just successful generation. Record cost and time separately.
A working production system must improve the game rather than only produce more
files, plans or agent activity.

**Documentation snapshot: September 29, 2026.** The earlier NET
[production-controller PR #65](https://github.com/giasonpooni/Notations-Systems-Terminal/pull/65)
[pinned implementation guide](https://github.com/giasonpooni/Notations-Systems-Terminal/blob/98386f4dfa621f6340670755603abd229be4684f/docs/NET_PRODUCTION.md)
describes a local sequential controller, declared repairs and a synthetic courier.
The subsequent draft/unmerged [NET Foundry PR #68](https://github.com/giasonpooni/Notations-Systems-Terminal/pull/68)
and companion [1792 PR #30](https://github.com/giasonpooni/1792/pull/30) separately
track the game-owned water-round attachment. Their evidence is revision-scoped;
these implementation branches are not merged by this README update. Neither a
headless attachment nor a passing contract establishes autonomous asset production,
full-game validation or an automatically generated playable release.

Godot remains the game-state and clock authority. Story, art direction, source
interpretation, sacred-site rules, saves and release approval stay game-owned;
automation does not get to redefine its own success criteria. Development-time
agents do not add a live AI service requirement to playing 1792. Shared tooling
may later benefit sister titles, but does not move them ahead of this campaign.
A logical work container or MCP tool connection is not an OS security sandbox.

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
