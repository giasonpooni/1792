# Bazaar attention — eye-line as authored performance, not perception state

This increment develops a small but important direct-craft layer: **where characters look during the bazaar episode**.

The game already knew who was speaking, who was attacking and which outcome had occurred. The presentation now uses those existing facts to make the cast visibly attend to the moment.

## Buddh

Buddh's existing childhood skeleton now applies a bounded head pose toward:

- the currently speaking nearby companion,
- the nearest active challenger during confrontation/fighting,
- one of the returning friends during the short decompression beat.

The head turn is layered on the existing visual proxy. It does not rotate the authoritative player body, camera, collision capsule or attack direction.

## Mela and Jiva

Supporting figures now use small head turns:

- a speaking friend glances toward Buddh,
- the other friend can look toward the speaker,
- both track the active conflict while fighting,
- during the return they periodically reconnect visually with Buddh.

These are performance choices, not a gaze/perception simulation.

## Challengers

Active challengers continue to orient their presentation toward Buddh and now use a bounded head adjustment on top of that body orientation.

Again, this does not modify AI steering, target selection, attack reach or line-of-sight rules.

## Separation of identities

The important invariant is:

```text
authoritative perception / combat / dialogue state
                    ↓
              presentation
```

not:

```text
where a head mesh happens to point
                    ↓
         new knowledge or AI state
```

A character looking at a blow does not create a witness receipt. A friend glancing at a speaker does not add a journal memory. A head turn never grants gameplay visibility through an obstruction.

## Bounded pose

Yaw and pitch are deliberately clamped. This avoids impossible neck rotations while the project still uses procedural/blockout characters.

The tests require:
- visible but bounded yaw,
- bounded pitch,
- speaker priority for Buddh,
- return to an active challenger when no one is speaking,
- a speaking friend's head actually changes,
- no authoritative state changes.

## Why this is direct craft

A terminal can prove that a head turn did not mutate state.

It cannot determine whether:
- Buddh looks too long,
- the challenger appears threatening,
- Mela's glance reads as bravado,
- Jiva feels attentive rather than robotic,
- eye-line supports the composition.

Those are human animation/directing questions.

The next real quality jump remains a proper skinned facial/head rig and authored animation, not a more elaborate control-plane abstraction.
