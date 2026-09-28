# 1792

**Copyright (c) 2026 Cartesian Graphics. All rights reserved.** Original project material is proprietary; see [licensing](#licensing).

**1792** is a historical open-world game project about the early life and rise of Buddh Singh.

The game begins in **1792**, when Buddh Singh is still a child and the Sikh Empire does not yet exist. The player starts inside the Sukerchakia Misl's home territory with a horse, a household, a small network of trusted people, and only partial knowledge of the wider Punjab.

The long-term design target is an embodied open world: ride, explore, hunt, talk, train, escort, trade, gather intelligence, build relationships, lead small groups, and gradually grow into military and political command.

This repository is intentionally being built **slowly, as a playable game**. Systems are added when they improve the player experience or make the simulated world more coherent.

## Core premise

The world should not initially feel like a strategy map.

At the start:

- the player controls Buddh Singh directly;
- the Sukerchakia heartland is the only reliably friendly territory;
- nearby settlements have varying relationships and incomplete information;
- roads, rivers, horses, weather, distance, and local knowledge matter;
- companions are people with trust and loyalty, not disposable unit slots;
- political power grows from relationships, reputation, logistics, and control of physical places.

As Buddh Singh grows older, the game expands in abstraction without abandoning third-person play:

```text
person
  ↓
rider
  ↓
small warband
  ↓
local commander
  ↓
campaign leader
  ↓
state builder
```

The player should still be able to mount a horse and ride through the same world even after gaining command responsibilities.

## First playable target

The first milestone is deliberately small:

**A rideable Sukerchakia home-territory prototype.**

It should contain:

- one home compound / misl headquarters;
- one controllable player character;
- one rideable horse;
- one nearby settlement;
- one road network;
- one patrol route;
- one neighboring uncertain or hostile area;
- a day/night clock;
- persistent NPC state;
- a minimal relationship system;
- a minimal world-intelligence system;
- save/load;
- one small encounter that can be solved by movement, conversation, avoidance, or combat.

The success criterion is simple:

> It should be enjoyable to leave home on horseback, travel through the countryside, encounter people, and return.

## Architecture

1792 uses a layered architecture, but the game remains the authority for player experience.

```text
                   1792
                    │
             GAMEPLAY AUTHORITY
                  Godot
                    │
       player / horse / UI / scenes
                    │
        ┌───────────┴───────────┐
        │                       │
 world-state seam         content pipeline
        │                       │
   future Bevy                Blender
 simulation runtime       models / terrain
        │
        └───────────┬───────────┘
                    │
             optional NET seam
      replay / experiments / validation
```

### Godot

Godot owns the current playable application:

- third-person movement;
- scene composition;
- camera;
- interaction;
- horse gameplay;
- dialogue;
- UI;
- encounters;
- local world presentation.

### Bevy

Bevy is reserved for simulation workloads that actually justify it:

- large persistent populations;
- asynchronous settlement simulation;
- faction-state evolution;
- campaign logistics;
- high-entity-count ECS workloads;
- deterministic/headless world stepping.

It should plug into the game through a versioned world-state boundary rather than duplicating gameplay logic.

### Blender

Blender is the content-authoring environment for:

- terrain;
- buildings;
- props;
- characters;
- horses;
- weapons;
- animation;
- environmental reconstruction.

### NET

Notations Engineering Terminal can later connect as an external development and scientific-analysis layer for:

- simulation runs;
- campaign replay;
- parameter sweeps;
- historical-data inspection;
- provenance;
- validation;
- comparison between runs.

NET does **not** own the game loop.

## Shared four-language architecture

All Cartesian Graphics games, including this title, will use the **C++ - Rust - Python - Julia** architecture: C++ for qualified native kernels, Rust for runtime systems, Python/NET for orchestration and retained experiments, and Julia for reference mathematics and numerical providers. Godot remains the playable application; Blender remains the authoring environment.

The [shared architecture baseline](docs/SHARED_GAME_ARCHITECTURE.md) defines single-writer state ownership, existing NET/`ciw`/SCR integration, native boundaries, development/shipping profiles and qualification requirements. This is a development commitment, not a claim that all four language integrations already run in this checkout. Existing gameplay, specialist providers and licences are preserved; no frame must pass through all four languages.

## Repository layout

```text
1792/
├─ game/                  Godot project
├─ data/                  versioned world/game data
├─ docs/                  design and historical notes
├─ schemas/               stable interchange contracts
└─ tools/                 import/build/validation utilities
```

## Historical approach

1792 should distinguish between:

1. **documented history**;
2. **reasonable reconstruction**;
3. **gameplay abstraction**;
4. **fictional connective material**.

Historical claims should eventually carry source notes in the project data or documentation. Where evidence is uncertain, the game should represent uncertainty rather than quietly presenting invention as fact.

## Design rule

Do not build Punjab all at once.

Build outward from home.

Every expansion should preserve the same question:

> Does this make riding through, understanding, and acting within the world more compelling?

## Status

Early foundation. The repository currently contains the first project scaffold and design contracts.

## Licensing

1792's original game code, authored content, and creative assets are proprietary to **Cartesian Graphics**, subject to the scope and exclusions in [LICENSE](LICENSE). Public repository access is not an open-source licence; applicable law, existing licences, and GitHub's hosting terms remain unaffected.

Selected reusable technology may be released separately under MPL-2.0 or Apache-2.0, but **no component is designated under either licence by this change**. Third-party material retains its own ownership and terms, including the separately supplied Godot Engine.

See the [licensing policy](docs/LICENSING.md), [asset terms](docs/ASSET_LICENSING.md), [third-party notices](THIRD_PARTY_NOTICES.md), and [contribution policy](CONTRIBUTING.md). These notices are not a player EULA or an automatic copyright assignment.
