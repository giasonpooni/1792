# Buddh Singh: personal identity and public address

## Authored rule

The player-facing protagonist is **Buddh Singh**. Other characters address him as
**Buddh Singh** before the authored accession and **Ranjit Singh** afterwards.
Formal post-accession dialogue may use **Maharaja Ranjit Singh**. Buddh remains
the name on the player's HUD. The fictional patrol captain is not renamed.

This is the requested campaign convention. It is not a historical finding that
the name Ranjit was first used at accession: the birth-name tradition attributes
the earlier renaming to his father. A researched secondary account describing
that tradition is [ThePrint, 13 November 2022](https://theprint.in/theprint-profile/maharaja-ranjit-singh-survived-assassination-at-12-at-40-he-was-ruling-punjab/1213107/),
which attributes its childhood account to Mohammed Sheikh's *Emperor of the Five Rivers*.
This note is a naming-source distinction, not an exhaustive historical review.

## Implemented

`game/characters/character_names.gd` is a pure presentation resolver. It has no
mutable campaign, clock, resource ledger or save routine. `player_name` leaves
other actors' supplied names unchanged. `address` requires a declared before/after
phase; an unknown phase returns no address, never an invented title.

The original 1792 home scene draws Buddh Singh through a home-only CanvasLayer
on the existing player scene. The home scene file, character movement code,
collision shapes and camera parameters are unchanged. Command scenes remove the
home-only overlay and draw their own HUD through the same name resolver.

The existing Lahore development scenes explicitly declare `after_accession`.
Their illustrative 1801 calendar does not drive the name rule. The fictional
estate envoy uses the formal post-accession name; that line is authored dialogue,
not a historical quotation. The codex's earlier-chapter Raj Kaur characterization
now refers to the young Buddh Singh. Source notes and historical quotations have
not been globally rewritten.

`ranjit_singh` remains the stable actor ID in all existing schemas, saved data,
orders, events, horse riders and relationships. Stored `actors.name` values in
older saves are legacy labels, not authority to change the new presentation rule.
No `buddh_singh` actor is created and no save format/version is changed.

## Limits and future event integration

This change does not implement an accession scene, chronological campaign
progression, a second protagonist, spoken audio or NPCs in the childhood scene.
When accession gameplay exists, its explicit story state should select the
address phase. Never infer accession from age, map position, being in Lahore,
or a calendar threshold; public naming is not permission to issue commands.
An observer-specific naming rule can be added later without changing actor IDs.

## Checks

The normal runner executes `test_character_names.gd` in addition to every prior
suite. It checks the two phases, personal/public separation, missing-phase
behavior, captain/antagonist names, old-format save/load, actor and order identity,
HUD handovers, envoy dialogue, repeated home creation/deletion and overlay cleanup.
All save tests use `user://character-names-regression-only.json`.

`render_character_names.gd` captures the unchanged home world with its new
nameplate, the Lahore HUD and the envoy's address. These are presentation
fixtures, not a played historical accession.
