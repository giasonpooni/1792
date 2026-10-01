# Bazaar market craft — direct game work outside the control plane

This increment intentionally develops work that a terminal/control plane is comparatively poor at deciding by itself: **scene composition, body language, environmental rhythm, nonverbal ambience and authored moment-to-moment staging**.

It builds on *A Short Walk* without changing the encounter's state machine, collision authority, navigation, money, saves or outcomes.

## What changed

The confrontation now sits inside a more legible market corner rather than an almost empty patch of road.

- Two shallow stall fronts frame the encounter outside the playable lane.
- Fabric awnings and hanging cloth introduce motion and depth.
- Baskets, carrying poles and sacks create foreground/background layers.
- Three generic non-speaking market silhouettes provide occupation without creating new NPC state.
- Two small warm practical lights give the confrontation a visual anchor.
- A six-second synthesized ambient loop combines air, timber creak and a distant hoof rhythm.

All of this is **original prototype art**. It is not a surveyed bazaar, a reconstructed 1790s market layout, historical costume evidence, recorded ambience, or a final sound mix.

The new market dressing contains **no CollisionShape3D or StaticBody3D nodes**. It cannot block the player, companions or existing navigation. The physical route remains owned by the pre-existing scene.

## Combat craft

The existing attack timing remains authoritative, but the visible challenger now shows clearer weight transfer:

- **wind-up:** visual weight settles to the rear foot;
- **strike:** a bounded visual step-through accompanies the committed blow;
- **checked:** the body recoils and compresses;
- **recovery:** weight returns toward neutral.

These offsets occur only on the presentation child and stay inside a small envelope. They do not move the CharacterBody3D, change reach, create a hitbox, alter timing or affect collision.

The same principle applies to Buddh's guard/counter presentation from *A Short Walk*: animation reads the existing event; it does not author the event.

## Why this belongs in the game rather than NET

NET is useful for:

- source/evidence identity,
- bounded work assignments,
- build/run orchestration,
- regression testing,
- asset admission,
- performance measurement,
- replay and comparison.

It should **not** be treated as an authority for:

- whether a market composition has useful visual depth,
- whether a stance communicates intent,
- whether a companion feels distinct,
- whether the rhythm before and after a blow is satisfying,
- whether dialogue lands,
- whether a sound bed supports or distracts from a scene,
- whether the final frame is beautiful.

Those are direct-craft and human-review problems. Automation can retain variants and measurements; it should not convert them into aesthetic truth.

## Sound

The ambient loop is generated from deterministic synthetic waveforms/noise and contains no voice or third-party samples. F6, inherited from *A Short Walk*, mutes both encounter foley and the ambient market bed. Muting changes no game state.

This is deliberately sparse. Future production sound needs:

- human-recorded or licensed environmental sources,
- footsteps by surface,
- cloth and body contacts,
- distant trade/animal activity,
- performed dialogue,
- spatial mixing and occlusion,
- human listening tests.

## Qualification

Run:

```sh
python tools/run_bazaar_direction.py --godot /path/to/godot
```

The wrapper retains every inherited suite, the *A Short Walk* directed journeys, and adds direct-craft boundary checks.

The market-craft tests require:

- the market stage exists in the shipped Home scene,
- exactly two awnings, eight hanging cloth pieces and three ambient silhouettes,
- no hidden collision or static physics bodies,
- stage/pose sampling leaves whole-world state unchanged,
- supporting-character presentation never moves the authoritative actors,
- visual footwork stays inside a bounded presentation envelope,
- ambience is looping mono PCM, nonempty and unclipped,
- mute stops the ambience immediately,
- mute changes no game state.

These tests establish **separation of authority and working presentation hooks**. They do not establish historical authenticity, beauty, drama, human enjoyment or final animation quality.

## Next direct-craft work

The highest-value work now is not another orchestration layer. It is:

1. one carefully authored two-person combat exchange with convincing contact timing,
2. facial acting and eye-line,
3. richer market dressing derived from evidence rather than generic composition,
4. recorded performances,
5. a real environmental sound mix,
6. human playtests of readability, pacing and emotional response.

That work should continue to plug into the verified substrate without asking the substrate to replace artistic judgment.
