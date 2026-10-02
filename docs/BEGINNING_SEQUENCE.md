# Beginning of the game

The main menu gives the Home childhood entry one focused **Begin** action. Other playable prototypes remain available under **Development studies**. The family opening leads into the same retained Home scene; neither the opening nor the guidance supplies canonical progress.

The compact courtyard HUD now supports the early lessons. It shows one current objective, real progress and relevant controls, while the bottom panel preserves actual speech, refusals and errors. The classic HUD remains available through F7's existing compact/original switch. Journal and other modals immediately suppress the compact panels.

| Existing lesson | Guidance |
| --- | --- |
| Orientation | Separate walking and left/right-looking completion. Vertical looking is not described as the required horizontal look. |
| Sealed message | Collect at the courier, hear his account while still there, then visit the steward. Both accounts still use their original authority rules. |
| Riding | On foot: the current household horse and F. Mounted: the current numbered gate, W/A/D, braking and stopped dismount. |
| First riding gate | Optional stable-trainer lesson becomes visible once eligible. Standing and mounted matchlocks remain locked until the completed lesson receipt. |
| Sparring | Mounted players first see braking and dismounting; on foot, face the trainer and use the original guard/recovery window. |
| Tracking | Follow the current trace, then quietly approach the quarry. |
| Return encounter | Return by the bend, then reach Home alive using the existing movement/defence rules. |
| Household inquiry | Hear the returning accounts, answer Raj Kaur, examine the bend and report the observed trace. Existing escort obligations remain visible. |

The current lesson marker is excluded from cached static art-label visibility. Its initial hidden orientation state no longer hides it permanently after the lesson changes. Markers name the existing target: courier, steward, household horse, numbered riding gate, practice trainer, trace, quarry or Home. This is local guidance for the authored lesson, not a map-discovery or journal grant.

The mounted Home figure uses the existing on-foot child's authored garment palette and has no facial hair. That changes appearance only; the shared rig's geometry, saddle/bridle anchors, motor, original seven rider anchors and standing admission remain intact. The trainer's remembered Maha scene retains its separate palette. Early training exercises show only movement/balance controls, revealing continuation when the hold is earned; weapon handling displays the four distinct charge states and actual reload progress.

Hosted lessons preserve the Home's pointer ownership on return. The standalone horsecraft study releases the pointer when closed; the hosted lesson leaves that responsibility with the retained Home. The complete input journey caught and corrected the earlier cleanup ordering that released the mouse after Home had already resumed.

## Qualification

`test_beginning_guidance.gd` requires a real display backend because Godot's headless backend cannot capture the mouse. It uses focused menu launch and ordinary mouse, movement and E interactions through orientation, courier and steward. It checks authority and collision identity during UI reads/toggles, the earned visible waypoint, real journal/art modal isolation, classic-HUD restoration and 800×600/1280×720 layout. Run it under Xvfb with the same pinned Godot used by the renderer; it refuses a headless invocation rather than claiming pointer qualification.

`render_beginning_sequence.gd` starts through the true production Home entry, completes the story, walks/looks through orientation, collects/hears the courier's account, hears the steward, mounts, rides through the first gate, returns to the trainer, enters training through its actual button, holds the first standing exercise and cancels back to Home. No canonical progress, saved pose, capability or receipt is seeded. It does not inject a camera. Between captures, only 3D drawing is suppressed to speed software rendering; ordinary physics and input still run.

Its eleven 1280×720 images use production cameras and current HUD. The manifest records the route's ticks, positions, observed accounts, first gate, current objective/controls, state hashes, story presentation, local standing evidence, renderer/device and independent PNG/RGBA hashes. Capture pauses are explicit. All capabilities remain locked when the incomplete lesson returns. This automated route establishes that the beginning is traversable; it does not constitute a human playtest or prove final animation/asset quality.

`render_opening_chapter.gd` continues a separate fresh input journey through the complete beginning. It earns both moving standing holds, spends four distinct matchlock charges, performs four exclusive reloads, sits and stops, and completes the guarded lesson return. It then physically remounts, reaches the remaining gates, dismounts, guards twice and counters during recovery, follows three traces, approaches the quarry quietly, witnesses the return-path threat and reaches Home alive. No progress, camera pose or receipt is seeded. Gate admission uses the original gate-radius rule; it does not claim a new plane-crossing proof.

The extended route then hears both returning speakers, answers Raj Kaur through the actual guard-choice button, holds and regroups that guard with G, and revisits the bend with him physically attending. It examines the clue with E, saves through F5, walks back with the guard and gives the observed account. F9 deliberately restores that earned mid-return save: the later report knowledge disappears, the outstanding escort obligation returns, and the earned riding receipt remains. A second physical return/report completes the inquiry again, followed by the journal and a final F5 save. No initial progress or saved pose is seeded. The mid-return restore is declared in the v2 manifest; this is not described as a never-restored route.

Its eighteen production frames include the paired hold, distinct spent weapons, a reload in progress, earned Home return, sparring, tracking, the living courtyard return, actual offer, attended clue, report dialogue and completed-inquiry handoff. The manifest records actual receipt/shot identities, whole saved/progressed/restored/final snapshots and raw-save/checkpoint hashes. The automatic checkpoint remains the original pre-inquiry courtyard return. The completed inquiry retains compact guidance to the quartermaster until the allowance is actually accepted. Guidance and 800x600/1280x720 layout checks grant no economy, knowledge or capability.

`tools/qualify_opening.py` runs this route from a clean committed tree with isolated save paths and a real display. It retains a source archive and raw commit object, independently recomputes their Git identities, binds the actual Godot executable, command, operation and execution, decodes and hashes PNG/RGBA pixels, and checks the earned receipt, complete inquiry, native rollback and save/checkpoint bytes. The guard's staged JSON pose is compared only at the native Vector3 binary32 representation to reconcile measured one-double-ULP parsing differences; knowledge, events, receipts, clock and other authority remain exact. Original snapshots remain distinct and byte-bound. The verifier proves recorded execution consistency, not authenticated history, OS-level input automation or human playtesting.

Run `python3 tools/qualify_opening.py --godot /path/to/Godot --evidence-dir test-results/opening-qualified --xvfb`, then `python3 tools/qualify_opening.py --evidence-dir test-results/opening-qualified --verify-only`. The independent inquiry choice still needs a separate fresh opening route; inherited aftermath fixtures cover its domain rules but do not supply that new-game qualification.

CI runs the guidance suite and both input journeys under Xvfb, checks engine errors, and retains their frames beside the four opening and six training frames. The full headless runner retains the original childhood, riding, save, art, workshop and father-interlude checks.
