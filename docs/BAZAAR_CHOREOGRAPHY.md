# Bazaar choreography — one exchange before more combat

This pass deliberately improves **one readable hand-to-hand exchange** instead of adding attacks.

The existing combat reducer remains authoritative:

```text
attack cycle → Q guard decision → parry/hit receipt → optional counter receipt
```

The presentation layer reads those facts and stages:

```text
measure → load rear foot → commit → guarded contact → recoil → counter → reaction → recover
```

No presentation curve can create a parry, damage an actor, extend reach, move a CharacterBody3D, change collision, or award an outcome.

## Choreographic intent

The challenger should telegraph with the whole body rather than an arm alone. The wind-up settles backward, the committed blow transfers forward, a checked blow compresses/recoils, and recovery visibly returns weight toward neutral.

Mela and Jiva now react to the same authoritative receipts rather than standing inert beside the exchange:

- a landed blow produces a short brace/flinch,
- a parry draws their attention into the contact,
- a counter produces a brief urging/relief gesture.

These reactions are not new knowledge or combat participation. They create no journal entry and are not saved as game state.

The market silhouettes also turn subtly toward recent physical contact. They remain generic presentation figures, not simulated witnesses, witnesses in the evidence model, or sources of later testimony.

## Why this is direct craft

The terminal can verify that these poses are bounded and do not mutate state. It cannot decide whether the anticipation is too long, the recoil feels heavy enough, or a friend's reaction looks emotionally convincing.

The production loop for this work is therefore:

```text
author pose → play → watch → revise → regression check
```

rather than generating more mechanics.

## Current limitations

This remains procedural prototype animation. There is no motion capture, hand IK, exact hand/body contact, facial blendshape rig, gaze solver, ragdoll, root-motion attack or camera choreography. The physical hit is still decided by the inherited abstract combat rules.

The next quality threshold is human review of the exchange at normal play speed, followed by a Blender-authored/skinned animation replacement that preserves the same receipt boundary.
