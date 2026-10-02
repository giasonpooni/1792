# Situated history and historical-perspective tooling

Decision: September 29, 2026. This document records the game's narrative method
and the next integration contract. It does not add a game runtime or mission.

## A life is an entry point, not the boundary of history

1792 remains a rich, embodied Ranjit Singh / Buddh Singh campaign. Its world
should also support discovering other people through encounters, accounts,
relationships, places and consequences rather than biography cards alone.
A discovered person can motivate a later episode; it does not automatically
create a playable campaign or override the main narrative's production order.

The player should make choices with situated information, not the historical
researcher's hindsight. Keep modeled world state, an actor's available
observations, beliefs, remembered accounts, retellings and retrospective
historiography distinguishable. Historical theory-of-mind means constrained
reconstruction of plausible knowledge and choices, not access to a historical
person's true private thoughts. Different perspectives need not be equally
supported by evidence, and understanding a choice is not endorsing it.

A private goal, relationship or motive must retain its supporting evidence or
explicit reconstruction/fiction status. A surviving account can attest that a
claim was made without proving its truth or sincerity. Conflicting traditions
remain attributed; they are not collapsed into a universal truth or karma score.
Existing sakhi-inspired oral-memory work, youth stories, naming, sacred-site
rules and narrator separation remain game-owned and are not replaced.

## Shared tool: implemented outside the game

The first authoring tool is in the existing terminal repository:

[Terminal PR #70](https://github.com/giasonpooni/Notations-Systems-Terminal/pull/70),
commit `e1fa85f89ff3f39db84ee9b157929133de49b72c`.
[Installation and exact limits](https://github.com/giasonpooni/Notations-Systems-Terminal/blob/e1fa85f89ff3f39db84ee9b157929133de49b72c/docs/HISTORICAL_PERSPECTIVE.md).

`net history` supplies `history.actor-state.v1` and
`history.epistemic-audit.v1` through NET's original Session and registries.
It projects explicit received information, retains conflicts and one-level
belief attribution, and checks annotated statements against receipts and
report/forecast modality. Original-fiction examples use logical ticks only.

This is not yet attached to 1792. It does not simulate couriers, parse dialogue
meaning, infer historical psychology, bind calendar dates or change Godot saves.
NET's other game-production PRs are separate development increments. Their
qualification does not qualify this proposed perspective adapter.

Only a filtered actor-result export should enter a dialogue worker's context.
The complete historical declaration, developer research notebook, narrator view
and operator audit remain privileged. Filtering is not an operating-system
sandbox; an unrestricted worker that reads those files can still learn them.

## First game-owned integration contract: not implemented here

Use one bounded original-fiction household message episode within the existing
Gujranwala chapter, not a fabricated attested historical incident. Keep the
existing `ranjit_singh` identity and the game's display-name policy.

Godot must own the world, clock, interactions and delivery events. NET receives
an explicit exported trace and retains the development operation; it does not
become a second live state writer. Reuse existing delayed-information and
oral-account systems where compatible, rather than duplicating their ledgers.

The acceptance case must demonstrate three actors with different information;
no knowledge before actual receipt; a lost or interrupted delivery that grants
nothing; contradictory accounts retained as such; a forecast distinguishable
from an observed outcome; and an attributed belief that does not copy another
actor's real private state. Repeating one source through several messengers must
not manufacture independent corroboration.

Save/load must preserve pending delivery and received-account history through
the existing save authority. A view switch changes observation access, not time,
resources, location or sovereign authority. Player-visible text still needs
human narrative review: passing an annotation does not prove its prose matches.
An imported trace must declare its clock mapping; no seconds-to-years guessing.

## Production order and ownership

1792 is the primary workload. Complete rich childhood/adolescence through the
prelude to Lahore, then the remaining full Ranjit Singh narrative before
historical-character DLC production. Hero of the Two Worlds / Garibaldi moves
slowly as a secondary project and transfer test. Geronimo is on hold.

Notations Game Foundry remains a workload on the existing NET substrate, not a
new engine or repository that absorbs game content. Godot, Blender, optional
Bevy and the shared C++/Rust/Python/Julia responsibilities remain unchanged.
No proprietary game code is copied into the terminal by this documentation.
No licence, source interpretation, release approval or execution permission is
changed. Automated checks are neither historical authentication nor proof.

Measure actual accepted and integrated playable work, including human setup,
supervision, art/narrative review, cost, rework and transfer. A growing character
catalogue is not itself a completed game or evidence of production speed.
