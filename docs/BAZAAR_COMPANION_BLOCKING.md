# Companion blocking — Mela and Jiva should not move like mirrored slots

Dialogue already distinguishes Mela and Jiva. This pass makes their **physical staging** differ as well.

It changes no companion identity, survival rule, teleport rule or outcome. Both are still ordinary existing CharacterBody3D actors recorded through the same movement/state path, and both must physically reach the regroup point before the story advances.

## Mela

On the outward walk Mela tends to occupy a slightly forward-left position relative to the direction of travel.

That supports the writing: he is the friend pulling the group into the outing.

During withdrawal he falls slightly behind rather than magically becoming the pathfinder.

## Jiva

Jiva walks slightly behind/right on the outward approach.

When the group decides to leave, his target moves ahead of Buddh's direction of travel. He visually becomes the person who knows the way out without acquiring a navigation authority or quest-leader flag.

During fighting he stays farther behind the player than Mela. Neither companion becomes a combatant.

## Implementation

The target is derived each physics tick from:

```text
existing hero physical position
+ existing episode phase
+ existing phase destination
+ authored lateral / lead offset
```

The formation rotates with the route instead of using a fixed world-axis offset.

The existing navigation helper still supplies a waypoint to that target. The existing actor `step()`, collision and `record_brawl_actor()` remain authoritative.

Therefore the presentation intention is allowed to affect **where the real companion tries to walk**, but not bypass the verified movement rules.

## Why this is direct game craft

This is a feel/blocking decision:

- Does Mela seem to pull the group forward?
- Does Jiva feel more measured?
- When leaving, does Jiva naturally read as the friend finding the exit?
- Do all three still look like a group rather than a formation diagram?

A terminal can verify distances, collision, no teleporting and successful regroup. It cannot decide if the staging feels natural.

## Qualification

The pure blocking contract checks:
- Mela/Jiva occupy opposite sides;
- Mela leads Jiva on the invitation;
- Jiva leads Mela on departure;
- the formation stays within a bounded radius;
- phase targets use the already existing confrontation/regroup/home destinations.

The existing three input-driven bazaar routes then remain the decisive physical test: both companions must actually keep contact and reach home under fight, leave and withdraw branches.

No new save schema, follower AI tree, relationship variable or crowd system is introduced.
