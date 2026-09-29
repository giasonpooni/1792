# Bazaar facial micro-performance — expression without an emotion simulator

This increment adds a deliberately small facial-performance layer to the existing procedural supporting figures.

It is **not** a character-emotion system. No mood scalar, relationship score, personality model, affective AI or save field is introduced.

## What the figures can now show

The two simple eye meshes, brow meshes and a new minimal mouth line provide:

- deterministic blinking,
- a slightly changing mouth shape while speaking,
- lowered/inward brow tension during wind-up and strike,
- raised brows after a checked blow or brace reaction,
- a small asymmetry during urging,
- softened half-closed eyes in the defeated crouch.

These are blockout performance cues. They are not anatomy, facial capture or final art.

## Deterministic visual timing

Blinking is derived from the existing presentation tick and actor index. It does not consume random state and does not create gameplay time.

Speaking shape is also sampled from the existing tick.

Therefore:

```text
game tick + current visual action
              ↓
        facial pose
```

There is no reverse authority from the facial pose into dialogue, AI, combat or memory.

## Why this remains direct craft

The tests can establish that:
- eyes close and reopen,
- speaking changes the mouth mesh,
- attack and checked reactions differ,
- presentation does not mutate world state.

They cannot establish whether the face is appealing, subtle, culturally appropriate, emotionally legible or believable.

Those questions need better assets and human review.

## Current limits

This is still a primitive sphere/mesh face:
- no eyelid mesh,
- no eye-ball aim,
- no facial bones,
- no blendshapes,
- no lip sync,
- no jaw,
- no cheeks,
- no wrinkle normals,
- no captured performance.

The next production-quality step is a proper skinned head/face authored in Blender and driven from the same existing dialogue/combat events.
