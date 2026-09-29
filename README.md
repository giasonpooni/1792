# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from Gujranwala and the Sukerchakia home territory toward wider command. Travel, relationships, provisions and incomplete knowledge matter before empire management. The stable character ID remains `ranjit_singh`; display names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development—not a finished city, released game or historical survey.**

[Play](#play) · [Walkthrough](docs/PLAYABLE_GUIDE.md) · [Creative direction](#scope-and-development-order) · [Research and production](#coupled-engineering-experiment) · [Development reference](DEVELOPMENT_REFERENCE.md) · [Rights](#rights)

## Cartesian Graphics and Notation Systems

**Cartesian Graphics — Private Creative, Simulation and Commercial IP Programme.** 1792 is its primary creative project and remains a product in its own right.

The proposed institutional direction places Cartesian Graphics as the private ownership/commercialization layer above a **Notation Systems public-interest scientific instrumentation commons**. This is conceptual governance—not a claim that a legal parent/subsidiary relationship, nonprofit entity or IP transfer has already been completed.

[Notations Systems Terminal](https://github.com/giasonpooni/Notations-Systems-Terminal) supplies shared scientific instrumentation. Cartesian can dogfood that commons while this game retains its worlds, assets, narrative, live state, clock, saves, creative direction and release approval.

Godot owns live game state and the clock. Shared primitives do not turn simulated events into physical observations or authorize industrial evidence admission.

## Play

Import `game/project.godot` in standard **Godot 4.5.1** and press **F5**. No .NET SDK, Python service, Bevy process or NET server is required to play. Choose **1792 · Buddh Singh · Home territory** for the integrated home chapter.

Learn the yard, hear a letter read, ride, train, follow traces, survive an authored ambush, investigate and report home. The household allowance introduces provisions, escort, workers, guards, infrastructure and recurring costs. Personal purse and household coffers remain separate; contracts pay once.

[Full walkthrough and save behavior](docs/PLAYABLE_GUIDE.md) · [Household economy](docs/GUJRANWALA.md)

## Gujranwala now has an evidence-bound setting

The current missions use a compressed **56 × 56 metre** test area, with courtyard, well, market props, field strips and ambient figures. Peripheral buildings are scenery, not a completed city. **F2** opens a paused reconstruction notebook linking geometry to source claims and uncertainty; it is a developer reference, not knowledge granted to the character.

Shah Muhammad's retrospective narrator cues currently use original English development text, not historical verse, translations or recorded voice. [Reconstruction and sources](docs/GUJRANWALA_1792.md) · [Integration receipt](docs/GUJRANWALA_INTEGRATION.md).

## New playable task: Water for the Household

After accepting the allowance, ask the quartermaster for the water round. Draw at the well, carry the load on foot and deposit it at home. Two trips complete the six-unit assignment. Drawing uses 180 existing physics ticks; leaving cancels it. A full open carrier slows movement and prevents mounting.

The task uses the existing save and clock. Its units are not measured litres or well yield; it adds no repeat cash reward, recurring water consumption or water-dependent production. [Water-round guide](docs/GUJRANWALA_WATER_ROUND.md).

## Other retained modes

The separate Lahore command story, houses-and-rivals patrol sandbox and exposure/perception experiment remain development scenarios, not completed biographical transitions.

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

## Scope and development order

Build the rich Gujranwala childhood/adolescence campaign through the prelude to Lahore first; then complete Lahore and the remaining Ranjit Singh narrative. Historical-character DLC follows the completed main narrative. Hero of the Two Worlds remains secondary; Geronimo remains on hold.

Plan the full geographic envelope from the beginning. Evidence-supported 1:1 terrain and location fidelity are reconstruction targets, not claims about the compressed playable cell. Visual beauty, movement, interaction and narrative are joint priorities. Historical claims, attributed oral tradition, conflicting accounts, reconstruction choices and original fiction remain distinguishable.

## Architecture

Blender is the intended asset-authoring path. Python, Julia, Rust and C++ are complementary implementation tools for bounded external workloads, not four compulsory live game runtimes. Godot retains the game loop; Bevy and NET are optional external providers.

[Shared game architecture](docs/SHARED_GAME_ARCHITECTURE.md) · [Campaign direction](docs/COUPLED_CAMPAIGN.md)

## Expertise amplification and transfer

The production goal is to help a small human-led team turn research and creative direction into coherent playable increments. Preserve source accounts, annotations, variants and rejected attempts. A machine-generated candidate is neither historical authentication nor editorial approval.

## Coupled engineering experiment

The game is also a demanding **synthetic-world testbed** for public instrumentation. Unlike physical systems, the engine can expose selected ground truth, letting experiments deliberately compare true simulated state, partial observation and estimated state.

That makes 1792 useful for state estimation, delayed information, partial observability, mapping, agents and rendering—but successful game-world results remain simulation evidence until separately validated for physical use.

**Notations Game Foundry remains a workload on NET**, not a second engine or a claim of autonomous game production. Measure end-to-end human effort, setup, model/provider cost, build time, memory, regressions and artistic/playtesting acceptance.

[Shared research programme](https://github.com/giasonpooni/Notations-Systems-Terminal/blob/docs/coupled-game-foundry-scope-20260929/RESEARCH_PROGRAMME.md).

## Develop and verify

```sh
python tools/check_project.py
python tools/check_reconstruction.py
python tools/run_checks.py --godot /path/to/godot
```

Existing gameplay, reconstruction and state-boundary checks remain unchanged. This documentation update does not rerun the suites, change the Godot pin, qualify repository-wide CI or publish a playable release.

The full previous overview is preserved byte-for-byte as [DEVELOPMENT_REFERENCE.md](DEVELOPMENT_REFERENCE.md).

## Rights

**Copyright (c) 2026 Cartesian Graphics. All rights reserved.**
Original protected game code and content are proprietary unless explicitly licensed otherwise. Engine and third-party rights remain separate. No claim is made over historical facts or public-domain material.

The proposed institutional inversion does not itself transfer any existing right, asset or repository. [LICENSE](LICENSE) · [Licensing scope](docs/LICENSING.md) · [Asset rules](docs/ASSET_LICENSING.md) · [Third-party notices](THIRD_PARTY_NOTICES.md)
