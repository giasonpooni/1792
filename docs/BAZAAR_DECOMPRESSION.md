# Bazaar decompression — making the walk home part of the scene

The bazaar episode no longer jumps aesthetically from conflict to administrative report.

This pass adds a short **presentation-only decompression beat** after the existing authoritative `regroup` receipt and before the existing quartermaster report.

## Three emotional shapes

The saved outcome remains exactly the existing one:

- `stood_ground`
- `withdrew`
- `walked_away`

Presentation interprets those outcomes differently for a few seconds.

### Stood ground

Mela is still carrying the energy of the fight. Jiva checks the group before relaxing.

> The shouting falls behind. Mela is still carrying the fight; Jiva counts heads before he says anything.

### Withdrew

The group has left an unfinished fight. The first few steps are intentionally quieter.

> Nobody speaks for a few steps. The road home is suddenly louder than the quarrel.

### Walked away

The insult remains unresolved, but the three friends remain together.

> The insult remains in the bazaar. All three of you keep walking.

These are original development captions, not historical quotations or narrator testimony.

## Spatial continuity

Five subtle road-wear presentation marks now visually connect the confrontation area toward the household approach. They are not waypoints, navigation targets, quest markers, footprints attributed to historical people or collision.

The existing player objective and regroup point remain authoritative.

## State boundary

The decompression beat is calculated from:

```text
existing regroup receipt + existing outcome + current existing game tick
```

It creates no new receipt, memory, knowledge, save field, reputation value or relationship statistic.

After six seconds it expires. A save/load reconstructs it only when the authoritative regroup receipt and clock still place the game inside that interval.

This is deliberate: **emotional presentation is allowed to be transient without pretending to be simulation state.**

## Why this matters

Large games often lose their most important moments by treating them as state transitions:

```text
combat complete → quest complete → next objective
```

1792 should preserve human-scale aftermath:

```text
event → physical exit → companions process it → home becomes visible → account
```

That rhythm is primarily level direction, writing, animation and sound work. NET can verify that it does not corrupt state, but should not decide whether the silence lasts long enough.

## Current limitations

The walk still uses prototype figures, procedural poses and generated ambience. There is no facial performance, recorded breathing/footsteps, authored camera blocking, crowd dialogue or final market-to-home environment art.

The next direct-craft step is to replace procedural hero/opponent poses with a Blender-authored skeletal exchange while retaining the same combat-receipt interface.
