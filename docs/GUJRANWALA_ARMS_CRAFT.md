# Gujranwala arms-craft niche v1

This increment uses the growing user-supplied weapons/object corpus to improve **material richness, elite craft language, and display composition** inside the already-playable Gujranwala Home.

It does **not** add usable weapons, a new armory system, firearm mechanics, blade combat, inventory, loot, or ownership claims.

## Visual language extracted from the corpus

The references repeatedly support several useful art-direction contrasts:

- darkened steel or dark wood fields against localized warm-metal fittings;
- ornament concentrated at grips, guards, lock plates, scabbard mouths/tips and focal bands;
- pale grip material creating strong contrast against dark scabbards or steel;
- paired display composition;
- repair wrapping and replaced fittings remaining visible rather than being normalized away;
- scabbards, shields and sidearms reading as part of a body silhouette rather than floating inventory slots;
- prestige pieces carrying denser ornament than ordinary household working arms.

The newest portrait/shield/sword references are especially useful for **carry and resting composition**: how a curved sword and scabbard relate to the leg, how a shield sits beside the body, and how ornamented weapons remain visually subordinate to the person.

## Implemented niche

A single wall-backed household craft/display niche is placed on the east-side perimeter, clear of the childhood lesson sites and riding gates.

It contains:

- two abstract long-arm silhouettes;
- one sheathed curved-blade study;
- one exposed curved blade study;
- two compact sidearm/dagger studies;
- a maintenance tray;
- three small loose fittings;
- one folded repair cloth;
- localized warm-metal inlay/bands and pale/dark grip contrast.

The objects are intentionally **abstract presentation studies**. They are not literal replicas of any supplied reference object.

## F7 ownership

The niche belongs to the same reversible authored-courtyard presentation lifecycle:

- F7 greybox/earlier-art comparison removes it;
- authored refinement restores it;
- the repair cloth samples the existing chapter tick;
- no second timer and no shader TIME are introduced.

## Physical/state boundary

The niche adds no:

- CollisionShape3D;
- StaticBody3D;
- NavigationRegion;
- weapon pickup;
- equip slot;
- ammunition;
- damage;
- inventory;
- economy;
- journal fact;
- knowledge receipt;
- save state.

The wall and courtyard collision remain authoritative.

## Historical boundary

The reference manifest lives at:

`data/art/arms_craft_reference_20261002.json`

The images are not redistributed. Each entry is C- or D-tier and carries explicit allowed/forbidden influence.

This pass does **not** establish:

- exact firearm types in the household;
- exact sword/dagger provenance;
- wootz/Damascus identification;
- ivory/jade/gem material identification;
- exact 1792 ownership;
- inscriptions;
- functioning lockwork;
- a named historical armory.

Those require separate source qualification.

## Direct-craft rule

Future industrial generation may produce weapon/display families, but it should preserve the authored hierarchy:

```text
plain working object
    ↓
repaired / maintained object
    ↓
better-finished household object
    ↓
prestige display piece
```

Not every object receives maximal ornament.

The point is to make craftsmanship, repair and status visible at gameplay distance while keeping the historical and gameplay authority boundaries intact.
