# 1792 — Game Design Foundation

## Player fantasy

The player begins as young Ranjit Singh inside Gujranwala and the Sukerchakia home territory. The fantasy is not “rule an empire”; it is **grow into someone capable of creating one**.

## First vertical slice: Gujranwala

The slice must prove that home is spatially memorable before the world expands. The player should be able to walk from the household through irregular settlement lanes, pass a small market/workshop cluster, reach cultivated/open ground and find outbound roads whose destinations are only partly known.

The town is not a strategy node. It is a physical place with household space, work, food, water, roads, visitors, rumor and political exposure.

### Design invariants

1. **Embodied world.** Travel happens physically whenever practical.
2. **Partial knowledge.** Geographic, political and military knowledge have provenance and age.
3. **Relationships before armies.** Trust, kinship, obligation and reputation precede command abstractions.
4. **Persistent world.** Important people and places retain state outside immediate view.
5. **Dangerous movement.** Terrain, numbers, surprise, negotiation and withdrawal matter.
6. **Growing abstraction.** Later command systems do not delete character-scale play.
7. **Historical layers.** A later building or road plan never appears in 1792 merely because it survives today.

## Gujranwala implementation rule

Build from evidence outward:

```text
documented anchor
      ↓
bounded reconstruction
      ↓
playable spatial hypothesis
      ↓
test in Godot
      ↓
revise when stronger evidence arrives
```

The current town geometry is a hypothesis under test. See `GUJRANWALA_1792.md`.
