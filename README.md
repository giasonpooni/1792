# 1792

**Build outward from home.**

A Cartesian Graphics historical open-world game following **Buddh Singh** from
Gujranwala and the Sukerchakia home territory toward wider command. Travel,
relationships, provisions and incomplete knowledge matter before empire management.
The stable character ID remains `ranjit_singh`; the childhood display name and
later public names follow the [naming policy](docs/CHARACTER_NAMES.md).

**Playable greybox in development, not a finished city or historical survey.**

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

**Shah Muhammad** is the retrospective narrator. Seven milestone cues currently
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

## New story loop: hear, explore and retell

After the household inquiry, listen to the quartermaster and market trader tell
**The borrowed rope** differently. Inspect the rope beside the stable, compare the
accounts in **F7**, return for a further recollection, and retell what you heard to
the neighbour by the well. Their next response remembers what you actually told them.

This original fictional episode tests **sakhi-inspired oral transmission**, not a
historically authenticated sakhi. Repeated hearsay retains its source; physical
traces do not magically settle permission or motive. The reward is discovery and a
new conversation, not XP or an official verdict. No allowance is required.

F5/F9 now use the distinct `1792-oral-memory-v1.json` slot. **J** can explicitly
import the previous integrated Gujranwala save without overwriting that old file.

[Oral-memory walkthrough, source lineage and tests](docs/ORAL_MEMORY.md)

## PC and controller foundation

The Home territory entry now accepts an Xbox-style controller from the title
screen through the childhood lessons, inquiry, stories and save/load menus.
Left stick moves; right stick looks; **X** interacts; **Y** mounts; **Menu** opens
journal/save/settings; **View** opens remembered stories. **D-pad/A/B** navigate
menus. Deadzone, look-speed and inversion settings are available under Menu.
Keyboard and mouse controls remain. **Menu → Controller settings → Reassign
gameplay buttons** opens the nine-action button editor. Occupied buttons require
an explicit swap confirmation; A/B and the Menu/View recovery controls stay fixed.

There is a public **Windows x86_64 (local)** export preset and an allowlisted,
unsigned development packager. Steam gets an **offline preview-recipe generator**,
not a published build or Steamworks SDK integration. Microsoft Store and Xbox
remain explicitly blocked packaging/port targets pending their actual adapters.
Local play invents no store account, achievement, cloud save or entitlement.

The packager now emits a versioned manifest that binds Steam preview recipes as
well as the payload. `python tools/verify_platform.py PACKAGE.zip` checks an
archive or directory without extracting, executing or uploading it. It rejects
changed/missing/extra files and non-preview recipes; it is not a signature check.
[Remapping and package-verification guide](docs/PLATFORM_CONTINUATION.md).

[Controller controls, Windows builds and platform qualification](docs/PLATFORM_FOUNDATION.md)

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
| F7 | Remembered stories and comparison of received accounts |
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
python tools/check_oral_memory.py
python tools/run_checks.py --godot /path/to/godot
python tools/run_platform_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_oral_memory.gd
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

## Continue and recover a saved chapter

The title now offers **Continue saved home chapter** and **Saved home chapter /
recovery**. Continue validates the selected file and the actual scene's standing
room before entering, then waits for Resume. The original Home entry still starts
a new session and never overwrites a save just by entering.

In the home journal, **Saved chapter / recovery** can load the primary or explicitly
recover the previous manual snapshot. F5 / Save chapter preserves a different,
valid primary as one previous generation before replacement. Corrupt primary
saves require an explicit, reviewed replacement; loading alone never rewrites a
file. No world-save format, clock or controller-preference migration is introduced.

[Save recovery rules, failure boundaries and qualification](docs/SAVE_RECOVERY.md)
