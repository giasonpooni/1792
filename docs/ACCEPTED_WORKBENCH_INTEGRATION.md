# Accepted workbench: from Foundry output to the existing playable workshop

## What changed

The **existing Home territory** chapter on the Gujranwala workshop branch now places
the exact NET-produced `workbench.glb` in the west-gate smith's courtyard. It replaces
that courtyard's earlier procedural tabletop and four visual supports; it is not a
second test scene or another workshop economy. The anvil, hearth, smith, town, horse,
original Player PackedScene/motor, workshop state, receipts, save slot and game clock
remain. The tools appear on the accepted bench while ready, on the player when
collected, and enter household stock only after the return trip.

This increment is stacked on **1792 PR #21**, branch `feat/gujranwala-workshop-v1`,
commit `51fae26d48348cb7e82ef5f8ff5b9567bfe37bd4`. It does not silently merge the
parallel funded-instructor, traversal, narration, atlas, anthology or other branches.
The terminal repository and its producer are unchanged. No main-branch merge,
release, external service or NET runtime dependency is introduced.

## Provenance and the consumer boundary

The asset bytes are identical to the accepted primary output of NET PR #73 at
`edcb0b2f09ccd351de3e977dec1c1a910d021cd3`, native workflow `36546004870`:

- SHA-256: `60ea4b4657f9c73d12c956e20498e99afa0f892a7b3167ecb033c53d3ec50736`
- Size: **11,076 bytes**, nine closed mesh parts, 108 triangles.
- Dimensions: **1.8 m long, 0.7 m deep, 0.9 m high**, glTF Y-up.
- Content: original untextured technical blockout, not a historical reconstruction.

`game/assets/props/workbench.provenance.json` retains the original accepted-export
manifest and its distinct packet, production, execution, result and receipt identities.
Those identify the producer's technical qualification. They are not relabelled as this
consumer's gameplay test, human art approval or historical evidence. The consumer's
source, execution, trace and checks are retained separately by the new workflow.

Only the GLB and its provenance cross into the game. No NET source, checker, engine
binary, font, external texture or book scan is copied. Godot's ordinary resource import
loads the visual from an explicit PackedScene dependency; Blender is not needed to play.
Importer settings pin unit scale and disable generated LODs and animation import for
this static candidate. Engine import caches are not committed.

## Placement and collision are owned by 1792

`game/workshops/accepted_workbench.tscn` instances the accepted visual at unit scale.
The existing workshop builder places it at **(-46, 0.132, -5.4)** in the compressed
Gujranwala local frame. The foot height meets the courtyard's visual floor. There is no
claim that this is a surveyed coordinate, georeferenced location or documented object.

A separate **game-authored BoxShape3D** covers the 1.8 × 0.9 × 0.7 m volume, with its
local centre at (0, 0.45, 0), on the existing static-world collision layer. This is a
conservative full-height-player blocker: empty space between the legs is intentionally
not a crouch/crawl route. It is not the producer's six-ray mesh test, a dynamic rigid
body, detailed contact model, or general-purpose collider-generation algorithm.

The original player remains a 0.35 m radius / 1.6 m height capsule with its existing
movement response. No shrinking the player, removing neighbouring walls, teleport
recovery or replacing the motor was required. The inherited navigator and standing-space
validation see the same static box; the bench adds no process callback, clock or state.

Finished tools remain projections of original ledger custody. Their lowest tool-head
surfaces sit five millimetres above the new tabletop, rather than floating at the old
procedural bench's height. No new inventory item or resource balance is introduced.

## Interactions and saves

Use **E** to speak to the smith from a clear nearby position. The original conversation
and commission remain: reserve two timber bundles and four household coins, carry them
to the smith, wait 600 active ticks, collect the tools, and return them to household stock.
Buddh's personal purse receives no payout. See `GUJRANWALA_WORKSHOP.md` for the full route.

Workshop access now explicitly rejects a feet-height difference above 0.35 m. Collection
also requires the accepted visual to be visible and a clear character-eye ray to its
collection point, within the existing conversation-scale reach (3.6 m to that point).
This is not an anatomical hand-reach/IK animation. The original smith proximity and
facing checks still apply. The third-person camera does not determine access.

These checks run again when a queued menu choice executes. A new obstacle can block
the tabletop while leaving the smith visible; that invalidates collection before any
custody or economic state changes. Removing it restores access, not automatic pickup.
The full dialogue is preserved; an unavailable queued handover reports refusal.

**F5/F9 still use `user://1792-gujranwala-workshop-v1.json`.** The bench does not add a
save schema or migrate balances. Whole-world load already validates domain data and
current collision before promotion. A domain-valid saved position inside the bench now
fails that standing-room test and leaves live state and transforms unchanged. A safe
bench-side save restores the original pending work or carried tools without duplication.
Older blocked positions are refused, not silently moved to new coordinates.

## What was exercised

`test_workbench_integration.gd` extends the existing workshop test helpers. It does not
modify the original tests or implement a second player. Three sorts of evidence are
kept distinct:

**Physical fixtures:** labelled initial placements in the actual workshop check imported
mesh bounds, triangle count, floor alignment, tool support, original capsule size,
neighbouring static overlap, four swept-clear ring edges and four directions of actual
sprinting into the bench. The real motor must contact the new body without crossing it
or climbing onto the tabletop. Endpoint overlap queries accompany shape sweeps; a sweep
alone does not detect a shape already inside an obstacle.

**Access and persistence fixtures:** a ready-state setup checks visible collection,
facing away, wrong elevation, a hidden visual, a tabletop-only obstruction inserted
after opening the menu, an external camera, a refused colliding save and a valid nearby
save. The before/after states of the refused queued collection are retained.

**Connected input-driven journey:** one completed-household-inquiry snapshot is supplied
before launch. After that, movement inputs, E, actual button callbacks and F5/F9 execute
the route. The player reserves funds, travels through the existing west gate, walks a
complete circuit of the bench while carrying timber, hands over the order, saves/reloads
work, waits for the original clock, collects the visible output, saves/reloads beside
the bench, circuits it with the tools, and returns to the quartermaster. There is no
subsequent pose or progress injection; F9 is an explicit whole-world rewind, marked as
a new observation epoch rather than disguised as uninterrupted forward travel.

Per-tick positions, velocities, phases, contacts and tool custody are retained, plus
initial/ready/carried/delivered snapshots. A separate Python rechecker validates observed
clearance, bounded movement between recorded ticks, both restore epochs, exactly-once
receipt order, 600-tick work timing and the resource deltas. Eight deliberately altered
observation records must fail this checker. This is consistency qualification, not
cryptographic authentication or proof of a hostile execution host's honesty.

## Execute and retain

Open `game/project.godot` in **Godot 4.5.1 Standard** and choose **Home territory**.
Complete the original inquiry, accept the allowance and ask the quartermaster for the
smith's commission. No terminal server or Blender process runs alongside the game.

```sh
python tools/run_bench_checks.py --godot /absolute/path/to/godot
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /absolute/path/to/godot --fixed-fps 60 --path game \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_workbench_integration.gd
```

The wrapper runs the entire unchanged inherited suite before the new identity checks,
native integration and offline recheck. It retains `test-results/bench-gameplay.json`,
`bench-verification.json`, logs, exact module hashes and the engine executable hash.

Four actual software-rendered captures use the retained journey's ready/carried states:
a court overview, close bench view, player/cargo view, and compact smith conversation.
The first two are labelled inspection-camera views, not player-camera screenshots.
They hide interface text only, not geometry. No inventory or progression is fabricated
to obtain those captures. Engine rendering remains separate from gameplay acceptance.

The `Accepted workbench gameplay integration` workflow runs the same commands on the
exact PR head, with the unchanged checksum-pinned engine. Its artifact includes source
commit/tree, source.tar, gameplay trace, checks and screenshots; retention is 90 days.
The original workshop/town/remount/command workflows are unchanged and remain additional
regression paths. A workflow definition alone is not a successful qualification record.

## Deliberate limits and next work

This is one accepted prop in one existing authored courtyard. It does not qualify
all items, settlements, moving platforms, mounted contact, combat, full campaign
traversal, Windows save replacement, controller hardware, physical-GPU performance,
console export, human enjoyment or final artistic/historical quality. The full-height
box is intentionally conservative; crouching or complex contact needs a different
qualified collision contract. The source and test package is not a player-ready release.

The closed worker is still procedural, not a free-form creative model. This integration
does not manufacture human review or promote the parent's art milestone. The useful
next step is a second approved prop through the same producer/consumer path, with a
measured interaction use case, not an unqualified bulk asset drop.

Official Godot API references consulted:
- https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html
- https://docs.godotengine.org/en/4.5/classes/class_characterbody3d.html
- https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
