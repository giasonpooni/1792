# Gate traffic rhythm — sparse crossing without a crowd simulator

This direct-craft increment extends the existing household-gate passage study with **two presentation-only crossing figures**.

The goal is not population AI. It is to make the threshold feel temporally occupied when Buddh is far away and visibly clear as he approaches.

## Rhythm

The crossing figures use the existing childhood tick only. There is no new clock.

They spend long portions of an eight-second loop at the edges, cross during a short middle interval, and return. This deliberately leaves the gate empty much of the time.

When Buddh approaches:

- on foot, both crossing figures return to their own edges before close passage;
- mounted, clearance begins earlier;
- in a caught/ended presentation state, both return to the edges immediately.

The existing guard, porter, cart, pack and cloth marker remain unchanged.

## Authority boundary

The crossing figures are visual `Node3D` studies only.

They have no:

- collision,
- navigation,
- pathfinding,
- witness state,
- relationship state,
- economy,
- inventory,
- save data,
- historical identity.

They cannot delay the player mechanically. They only communicate that the gate has ordinary traffic and that people make practical room for a horse.

## Why this stays direct craft

A future crowd system can generate more traffic. It should not erase the authored timing principle:

```text
quiet edge dwell
→ brief crossing
→ approach detected
→ opening clears
```

The useful authored decision is **how much emptiness to preserve**, not how many agents can be spawned.

## Historical boundary

This is not a reconstruction of documented 1792 Gujranwala gate traffic. It is an original staging study inside the compressed Home territory, constrained by the existing project rule that presentation cannot become hidden gameplay authority.
