# Continue and recover the home chapter

The integrated **1792 · Buddh Singh · Home territory** now has a title-screen
Continue path and explicit previous-manual-save recovery. It extends the existing
platform branch; no new game world, clock, save schema or cloud provider is added.

## Play

**Title → Continue saved home chapter** reads the existing primary manual save.
The saved file must pass the current game's validator and actual scene geometry
checks. Entry remains paused until **Resume**. A missing or data-invalid primary
never silently selects an earlier file. The original Home button remains the first
menu entry, starts a new session, and does not write to disk just by entering.

**Title → Saved home chapter / recovery** shows both slots. Review and explicitly
confirm a previous snapshot to enter it. **Menu/J → Saved chapter / recovery**
provides the same primary/previous choices while playing; all loads there require
confirmation because they replace live progress. B cancels a confirmation or leaves
the browser. Saved summaries contain chapter phase and active simulation seconds,
not real-world timestamps, historical dates, trophies or inferred character knowledge.

**F5 / Save chapter** keeps the original primary path
`user://1792-oral-memory-v1.json`. Before replacing a different, valid primary,
it preserves those exact bytes in `1792-oral-memory-v1.json.previous`. There is
one previous generation, not a full archive. Saving identical serialized bytes
does not displace the previous file. A missing primary does not erase a previous
file. Merely loading either slot does not write to either slot.

A malformed or incompatible primary blocks ordinary manual saving. The browser
lets you **Replace invalid primary with this chapter**, with explicit confirmation
bound to both the inspected file bytes and current world snapshot. This may discard
the invalid file, so choose recovery first when the previous snapshot is the desired
progress. Replacement never copies invalid bytes over the previous file. An oversized
or unreadable file has no safe bounded content fingerprint and is not offered for
in-game replacement. No original corrupted-file archive is automatically created.

Focus loss or controller disconnection cancels an unconfirmed action. Returning
focus does not resume play or apply that old choice. A changed file invalidates a
prior selection; review it again. No inter-process lock or cloud conflict merge is
implied by these in-process checks.

## Existing invariants

The original validator owns world/content/receipt validity. Loading replaces the
whole chapter, including later testimony, money, water progress and listener memory;
none is merged back from a discarded future. Look settings and remapped controller
buttons remain in their existing separate files. Checkpoints and legacy imports
retain their existing paths and behavior. The old primary JSON format remains
readable with no wrapper or version migration.

`cg.manual-save-recovery.v1` is a policy over the injected byte transport, not another
state authority. `local_storage.gd` has an optional `path_status` inspection method;
`cg.save-transport.v1` is unchanged. A provider without that optional local capability
refuses this policy rather than selecting a different provider or inventing an account.
The integrated load path also passes the injected provider into its staged reader.

The original model-level `save_to` remains its validated byte-write operation for
compatibility. Interactive manual saves route through `SaveRecovery.save`; direct
model writes, checkpoints, preferences and other development modes are not newly
claimed to have backup policy. Headless callers that need this policy must invoke
the same helper, as the packaged probe does.

Title Continue prepares a candidate from the selected immutable byte identity,
freezes script callbacks, and lets its real collision space register before checking
standing room. Disabling the entire node subtree is intentionally avoided: that
would remove collision objects under their default disable behavior. The candidate
is discarded on failure or interruption. Only an admitted candidate replaces the
title scene. No game-time catch-up or narrator replay is introduced.

## Write-failure boundary

The existing local transport stages a temporary file, flushes it and renames it.
This policy first finishes the previous-file write, then attempts the primary write:

- A refused backup write leaves primary untouched.
- A refused primary write retains the old primary. The previous file may already
  contain a duplicate of that old primary; two-file promotion is not atomic.
- A failed operation does not mutate the live game state or claim it was saved.
- Temporary files are never candidates for automatic load or recovery.

This is bounded local recovery and validation, **not** signed-save authentication,
proof of played history, cloud conflict resolution, cross-process synchronization,
filesystem adversary protection or a guarantee against sudden hardware/power loss.
There is no explicit directory fsync or storage-device durability qualification.
Public engine references: [FileAccess](https://docs.godotengine.org/en/4.5/classes/class_fileaccess.html)
and [DirAccess](https://docs.godotengine.org/en/4.5/classes/class_diraccess.html).
These document primitives, not the stronger guarantees this implementation disclaims.

## Implementation and verification

`game/platform/save_recovery.gd` implements read/summary/selection/write policy.
The existing home controller gets a default manual-save hook; the active oral-memory
consumer composes the recovery menus. `home_launch.gd` qualifies title continuation.
No mathematics, private NET source, SDK, engine port, new language runtime, signing
credential or store service is copied into the game.

`test_save_recovery.gd` separates labelled storage/geometry/lifecycle fault fixtures
from a real title-started journey using Godot joypad events, D-pad/A navigation,
walking and local hearing. The journey saves before/after testimony, continues from
title, cancels and confirms recovery, verifies whole-state rollback and repairs an
explicitly corrupted primary. No pose, camera or narrative-progress injection is
used in that journey. Synthetic controller events are not physical-controller tests.

The existing platform runner executes every inherited suite plus this new suite.
Three new rendered presentation fixtures cover the title overview, confirmation and
invalid-primary browser; small-window viewports follow the inherited aspect policy.
The Windows exported-executable probe additionally exercises preservation, invalid
primary refusal, explicit repair and actual title-Continue entry without a source
`--path`. Exact source, operation, execution, model and verification identities remain
separate in retained CI evidence. Check current CI results before claiming a pass.

```sh
python tools/run_platform_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_save_recovery.gd
```

This is still one local manual save with one previous generation. Physical controller
use, consumer Windows rendering, hardware suspend/resume, storage crash injection,
Steam cloud/client integration, Microsoft packaging and Xbox port/certification
remain separate qualification work. No store publication occurs here.
