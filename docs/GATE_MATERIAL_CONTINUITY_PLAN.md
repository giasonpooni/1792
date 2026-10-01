# Gate threshold material continuity

This increment extends the authored household-gate passage with **four static material marks**. It is direct scene craft, not a traffic simulation and not a historical reconstruction claim.

The purpose is visual continuity: the porter, guard, tucked cart and mounted passage should appear to inhabit one repeatedly used packed-earth threshold rather than floating over an undifferentiated surface.

## Authored marks

- **PackedEarthThreshold** — broad, shallow compression through the opening.
- **CartWheelScuffOuter** — restrained wheel abrasion on the cart side.
- **CartWheelScuffInner** — a slightly shorter and narrower paired scuff so the ground does not read as a perfect procedural rail.
- **CartRestAbrasion** — a local worn patch beneath the already-tucked handcart.

All four are thin `MeshInstance3D` boxes. They have no collision or navigation body and no update loop. Their transforms do not react to the player, riding state, guard gesture or caught phase.

## Performance boundary

The detail budget is deliberately fixed at **four mesh instances, zero animated wear meshes**. Nothing is spawned from footsteps, wheel motion or distance travelled. This keeps the direct-craft layer readable and bounded while leaving later terrain-decal batching, mesh merging or an authored texture bake as an optimization choice rather than a new simulation subsystem.

## Authority boundary

The wear geometry does not enter campaign state, route authority, save state, economy, witness memory, rank, reputation or historical evidence. It suggests material use only. It does **not** assert measured traffic paths, paving, rut depth or household-gate geometry for 1792 Gujranwala.

Contract: `data/art/gate_material_continuity.json`.

Qualification: `game/tests/test_gate_material_continuity.gd`.
