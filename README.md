# 1792

**Grow from a young heir in the Sukerchakia heartland into a commander and state builder — without leaving the world behind.**

1792 is an early historical open-world game project centered on Ranjit Singh. The long-term
experience combines horseback travel and personal relationships, close-range exploration and
infiltration, contested local territory, and larger military campaigns. House and clan rivalries,
estate claims, patronage and personal obligations drive the political world, rather than
sorting its people into religious enemy teams.

**This is not a finished game.** The repository contains small Godot prototypes that we can build,
play, test and improve one at a time. There are no finished historical environments or character assets yet.

## Run it

Import **`game/project.godot`** into the standard Godot editor and press **F5**.
The reference test target is **Godot 4.5.1**; no Python, Rust or external service is needed to play.

The opening menu offers three development entries:

| Prototype | What is there |
| --- | --- |
| **1792 · Home territory** | The original home-territory ground, marker and movement scene, retained as the starting point. |
| **Lahore · Command story** | A separate, fictional 1801 sandbox: assign a patrol, play its captain or delegate, visit two locations, make a decision and receive a delayed report. |
| **Lahore · Houses and rivals** | The same command foundation with six non-playable antagonist biographies and one interactive estate petition. Negotiate, assert authority, defer or reconcile; the patrol carries the consequences. |

The Lahore sandboxes do **not** replace the childhood opening or assert that their invented missions
actually happened. Their captain, envoys and compressed geography are placeholders, not reconstructions.
The new entry extends the existing command implementation rather than duplicating its simulation.

## First command story

Walk to the courtyard table and press **E**. Assign the four-rider patrol, interact with the table again,
and choose **Play as the captain**. Follow the road to the village, press E to gather information,
then continue to the outpost. Organize a patrol or withdraw. The result changes local security and
the captain's relationship with Lahore, and a delayed report returns to Ranjit.

You can also delegate the same order or take control partway through. Switching does not reset
its allocation, progress, character positions or world clock. A completed story cannot repeatedly award resources.

## Houses, rivals and biographies

In **Houses and rivals**, press **H** for the antagonist codex, or access it through the command
table. Raj Kaur, Sada Kaur, Mehtab Kaur, Datar Kaur, Moran and Jind Kaur are NPCs, not selectable
protagonists. Each profile has an authored objective, source note and chapter presence. An antagonist
can be a useful patron or ally while opposing a particular decision; not every profile starts hostile.

Only **Sada Kaur's fictional estate petition** has an interactive conflict in this first slice.
At the table, hear the envoy and choose a commission. Recognizing a local revenue claim enables
a cooperative patrol. Asserting Lahore's authority creates rivalry and military presence without
settling local legitimacy. Deferring permits observation and withdrawal, not securing the road.
Ranjit can reconcile the disputed commission before the captain resolves it.

The same manual/delegated patrol rules apply. Political results reach the journal with the existing
messenger report, not before. Neither military presence nor an agreement automatically annexes land.
The codex intentionally includes earlier/later story profiles; this is a development roster, not six
finished character campaigns. See [Houses and rivals](docs/HOUSE_CONFLICT.md) for scope and contracts.

| Control | Action |
| --- | --- |
| WASD / Shift | Walk / run |
| Mouse | Orbit the third-person camera |
| E | Interact or open the captain's field menu |
| H | Antagonist codex in the Houses and rivals entry |
| F5 / F9 | Save / load the current sandbox (separate save slots for each entry) |
| F1 | Return-menu controls |
| Escape / click world | Release / recapture the mouse |

Decision menus pause the sandbox. The first slices have a simple delegated policy, not general commander AI.
The encounter is a choice interface; **combat, horses and marching troops are not implemented yet**.
See [Command stories](docs/COMMAND_STORIES.md) for the original walkthrough, persistence rules and limitations.

## Where the game is going

The main story starts from a small familiar home territory. Travel, local knowledge, companions,
relationships and contested roads should matter before large armies or administration enter play.
Greater power adds responsibilities without removing the ability to walk or ride through the world.

Later, Lahore becomes a command hub. Ranjit remains the main character, while smaller playable
stories follow subordinate commanders. Their decisions affect the same campaign world instead
of becoming disconnected missions. Documented commanders and expeditions will be added after
their dates, command relationships and sources have been checked. The proposed Tahal Singh
Chhachhi line is not yet substituted for the fictional captain.

The design references are the embodied world of *Red Dead*, personal traversal and infiltration
from *Assassin's Creed*, local territorial struggle from *Saints Row 2*, and campaign command
from *Shogun: Total War*. These are inspirations, not implemented feature claims or affiliations.

## Keep the technology behind the game

**Godot** owns gameplay and the current world state. **Blender** is the intended asset-authoring
pipeline. **Bevy** is reserved for simulation workloads that justify a separate runtime.
**Notations Engineering Terminal (NET)** can later provide external experiments, inspection,
replay tooling and validation. None of those future integrations is required to start these prototypes.

The command slice extends the existing `world-state.v1` record with a `command-story.v1` profile.
The house slice adds a versioned `house-conflict.v1` substate to that same authority; the original
command code and world schema remain unchanged. Orders, controlled characters, antagonist NPCs,
groups, source notes and reports have separate identities. Manual and delegated execution share
consequence rules. House, clan, misl and religious institution are not treated as synonyms.

## Develop and test

```sh
python tools/check_project.py
python tools/run_checks.py --godot /path/to/godot
/path/to/godot --headless --path game --script res://tests/test_house_conflict.gd
```

The structural checks run without Godot. Runtime checks require the engine and must not be
reported as passed when it is absent. CI imports the project, exercises both command and house
rules and scene interactions, and captures software-rendered screenshots. Inspect actual CI results;
[the earlier evidence note](docs/VALIDATION.md) covers the original command slice, not an automatic
pass for new code. New results are recorded against their tested commit in the pull request.

```text
 game/          Godot project, gameplay, sandbox data and engine tests
 data/          Original historical-start fixture
 schemas/       Existing interchange contract
 docs/          Design, historical method and implementation notes
 tools/         Structural and engine test runners
```

## History and scope

Separate documented history, attributed historical accounts, reconstruction, gameplay abstraction
and invented connective material. Antagonist characterization is the game's authored portrayal,
not certification of every allegation about a historical person's private motives. The supplied Raj
Kaur account remains referenced in her biography; no death scene is implemented in this slice.
The prototype's quantities and outcomes are game rules, not measured historical facts.
See [Historical method](docs/HISTORICAL_METHOD.md) and [Game design](docs/GAME_DESIGN.md).

**Build outward from home.** Make one small journey and its consequences work before building all Punjab.
