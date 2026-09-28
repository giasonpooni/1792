# 1792

**1792** is a historical open-world game about the early life and rise of **Ranjit Singh**, beginning in **Gujranwala in 1792**.

The first playable world is being built outward from the Sukerchakia home territory rather than from a strategy map. Gujranwala is the initial vertical slice: household space, a compact settlement, bazaar activity, roads into cultivated country, and incomplete knowledge beyond familiar places.

> **Current build:** researched Gujranwala greybox. Geometry is a reconstruction for play, not a surveyed 1792 town plan.

## Why Gujranwala first

Gujranwala was the Sukerchakia political center before Lahore. Historical scholarship describes it as a small settlement that expanded after Charat Singh established his capital there. The surviving Ranjit Singh birthplace haveli provides an architectural anchor: a brick-and-plaster residence organized around multiple courtyards. Pakistan's Department of Archaeology and Museums also notes that it likely had substantially more greenery and open space around it in the late eighteenth century than today.

The prototype therefore **does not back-project later nineteenth-century Gujranwala** into 1792. It does not treat the later street grid, Mahan Singh's later-built samadhi, or Ranjit Singh's Sheranwala baradari as features already present at game start.

See `docs/GUJRANWALA_1792.md` and `data/history/gujranwala_sources.v1.json`.

## First playable target

```text
home compound → settlement lanes / bazaar → cultivated edge
              → outbound roads → uncertain country → return home
```

The current Godot greybox supplies a multi-courtyard household type, compact irregular settlement, bazaar/workshop markers, cultivated plots, wells/trees/open ground, route exits, player traversal, orbit camera, and an exploration HUD. Reconstructed features are explicitly labelled.

## Architecture

Godot owns the playable world. Blender owns future authored assets. Bevy is reserved for simulation workloads that justify it. Notations Engineering Terminal may later run experiments, replay and validation; it does not own the game loop.

## Run

Target: Godot 4.x compatibility renderer.

```bash
git clone https://github.com/giasonpooni/1792.git
cd 1792
godot --path game --editor
```

Controls: **WASD** move, **Shift** sprint, **right mouse drag** orbit camera, **Esc** release mouse.

## Historical method

Features are classed **A documented**, **B reconstructed**, **C gameplay abstraction**, or **D fictional connective material**. A surviving building is evidence for architectural vocabulary, not automatic proof that every surviving element existed in exactly that form in 1792. Later monuments can be comparative evidence but are not silently inserted into the start-year town.

## Repository layout

```text
game/          Godot playable application
data/world/    canonical starting world records
data/history/  source and reconstruction records
docs/          design and historical research
schemas/       interchange contracts
```

## Licensing

Copyright © 2026 Cartesian Graphics. All rights reserved for original protected material except where a separate licence explicitly applies. Historical facts, public-domain material and third-party works remain outside that claim. See `LICENSE`.
