# 1792

**Grow from a young heir in the Sukerchakia heartland into a commander and state builder — without leaving the world behind.**

1792 is an early historical open-world game project centered on Ranjit Singh. The long-term
experience combines horseback travel and personal relationships, close-range exploration and
infiltration, contested local territory, and larger military campaigns.

**This is not a finished game.** The repository contains small Godot prototypes that we can build,
play, test and improve one at a time. There are no finished historical environments or character assets yet.

## Run it

Import **`game/project.godot`** into the standard Godot editor and press **F5**.
The reference test target is **Godot 4.5.1**; no Python, Rust or external service is needed to play.

The opening menu offers two deliberately separate prototypes:

| Prototype | What is there |
| --- | --- |
| **1792 · Home territory** | The original home-territory ground, marker and movement scene, retained as the starting point. |
| **Lahore · Command story** | A separate, fictional 1801 sandbox: assign a patrol, play its captain or delegate, visit two locations, make a decision and receive a delayed report. |

The Lahore sandbox does **not** replace the childhood opening or assert that its invented mission
actually happened. Its captain and compressed geography are placeholders, not reconstructions.

## First command story

Walk to the courtyard table and press **E**. Assign the four-rider patrol, interact with the table again,
and choose **Play as the captain**. Follow the road to the village, press E to gather information,
then continue to the outpost. Organize a patrol or withdraw. The result changes local security and
the captain's relationship with Lahore, and a delayed report returns to Ranjit.

You can also delegate the same order or take control partway through. Switching does not reset
its allocation, progress, character positions or world clock. A completed story cannot repeatedly award resources.

| Control | Action |
| --- | --- |
| WASD / Shift | Walk / run |
| Mouse | Orbit the third-person camera |
| E | Interact or open the captain's field menu |
| F5 / F9 | Save / load the command sandbox |
| F1 | Return-menu controls |
| Escape / click world | Release / recapture the mouse |

Decision menus pause the sandbox. The first slice has a simple delegated policy, not general commander AI.
The encounter is a choice interface; **combat, horses and marching troops are not implemented yet**.
See [Command stories](docs/COMMAND_STORIES.md) for the full walkthrough, persistence rules and limitations.

## Where the game is going

The main story starts from a small familiar home territory. Travel, local knowledge, companions,
relationships and contested roads should matter before large armies or administration enter play.
Greater power adds responsibilities without removing the ability to walk or ride through the world.

Later, Lahore becomes a command hub. Ranjit remains the main character, while smaller playable
stories follow subordinate commanders. Their decisions affect the same campaign world instead
of becoming disconnected missions. Documented commanders and expeditions will be added only
after their dates, command relationships and sources have been checked.

The design references are the embodied world of *Red Dead*, personal traversal and infiltration
from *Assassin's Creed*, local territorial struggle from *Saints Row 2*, and campaign command
from *Shogun: Total War*. These are inspirations, not implemented feature claims or affiliations.

## Keep the technology behind the game

**Godot** owns gameplay and the current world state. **Blender** is the intended asset-authoring
pipeline. **Bevy** is reserved for simulation workloads that justify a separate runtime.
**Notations Engineering Terminal (NET)** can later provide external experiments, inspection,
replay tooling and validation. None of those future integrations is required to start these prototypes.

The command slice extends the existing `world-state.v1` record with a `command-story.v1` profile.
The original world schema is retained. Orders, controlled characters, reports and event records
have separate identities. Manual and delegated execution share the same consequence rules.

## Develop and test

```sh
python tools/check_project.py
python tools/run_checks.py --godot /path/to/godot
```

The structural checks run without Godot. Runtime checks require the engine and must not be
reported as passed when it is absent. CI is configured to import the project, exercise the command
rules and scene interactions, and attempt software-rendered screenshots. Check the actual run
for validation status; see [the evidence note](docs/VALIDATION.md).

```text
 game/          Godot project, gameplay, sandbox data and engine tests
 data/          Original historical-start fixture
 schemas/       Existing interchange contract
 docs/          Design, historical method and implementation notes
 tools/         Structural and engine test runners
```

## History and scope

Separate documented history, reconstruction, gameplay abstraction and invented connective material.
The prototype's quantities and outcomes are game rules, not measured historical facts.
See [Historical method](docs/HISTORICAL_METHOD.md) and [Game design](docs/GAME_DESIGN.md).

**Build outward from home.** Make one small journey and its consequences work before building all Punjab.
