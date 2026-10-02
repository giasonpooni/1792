# Ground Focus v1

**Z** toggles a local Focus mode in the composed Home chapter. It emphasizes available sensory evidence while preserving the original player motor, camera, world clock, state, interactions and save format. **Q** remains guard; **E** remains inspect/speak; **X** remains hawk release/recall.

## Seeing and remembering

Focus uses the existing chapter `_seen` character-eye policy and physics collision geometry, within an authored 18 m envelope. A speaker's own front collision surface can be admitted; a wall before it cannot. The follow camera never supplies visual evidence. Optional chapters can supply their existing eye origin and visibility policy through the same interface; this feature does not install the optional PoliticalChapter vision model in Home.

A visible subject requires **45 continuous existing 60 Hz ticks (0.75 s)** before identification. Home's existing broad horizontal facing cone also includes peripheral subjects; acquisition is not a pixel-reticle test. Subjects outside the displayed camera produce no screen marker. Duplicate samples of one tick do not add dwell; an interruption or skipped tick starts acquisition again. Hidden/disabled nodes are not acquired. Registrations cover existing trainer, mother, escort, horse, smith, available ground trace, assailant proxy and the two fictional distant scout contacts. The trace's existing visibility gate remains authoritative.

Records carry observer identity, sensor identity, last observed position, observation tick and expiry tick. They live for at most **600 active ticks (10 s)** after the last observation. When sight is lost they stay at that observed position. The overlay explicitly says **last seen** and fades with age. It does not keep reading a hidden person's live transform into that marker.

| Symbol and color | Meaning |
| --- | --- |
| `?` amber | Unidentified observed contact |
| `E` pale | Visible existing interaction |
| `*` gold | Available visible trace |
| `+` blue | Already recognized household person |

An unknown contact is not promoted to an enemy, faction member or conspirator by Focus. A trace highlight does not reveal its cause, inspect it, create testimony or grant a journal receipt. Perform the ordinary **E** action to acquire the existing narrative knowledge.

## Estimating movement

Two acquired visual position samples at least **30 ticks (0.5 s)** apart may produce a constant-horizontal-velocity estimate. The estimator refuses motion below 0.15 m/s, above the authored 7.5 m/s bound, mismatched observation identities or samples more than one second apart. It reads no actor velocity, destination, route, intention or future chapter tick.

The dashed line is labelled **estimated**, carries its two source observation ticks, and expires at most **120 ticks (2 s)** after its latest source. Occlusion stops updates; reacquisition starts a new continuous history. A direction change can invalidate the estimate immediately in reality: this prototype provides a visual hypothesis, not a calibrated probability or guaranteed patrol path.

## Hearing

Focus observes actual playing, unpaused **AudioStreamPlayer3D** hammer playback already emitted by the workshop. Silent, muted or out-of-range sources do not produce a new cue. Eight coarse direction sectors are retained for at most 120 ticks. Cues contain a sound description and sector, never an exact position or concealed person's identity.

The acoustic envelope is an authored approximation: up to the emitter's existing maximum distance, capped at 16 m; a blocking collision halves that range and adds **muffled**. Direction is relative to the character's orientation when heard, and the UI displays the cue's age. This is not a measured sound-pressure, diffraction, room-acoustics or hearing model. No new sound is emitted and no historical sound recording is claimed.

## Lifecycle and authority

Focus does not pause or advance a second clock, move/freeze the body, switch cameras, change movement speed, write the journal, grant tasks, or write campaign saves. It stops during dialogue/notebook/art/atlas, sprinting, riding, active confrontation, or hawk scouting. It can resume only through the player control. Existing whole-world `_apply` clears all transient observations and estimates; tick rewind also clears them defensively.

The desaturation layer sits below the existing subjective framing and HUD. Focus temporarily hides the verbose original help block so it cannot cover observation markers; its prior visibility returns when Focus ends. Live dialogue captions and the compact task card remain available. Icons, text and dashed estimates supplement color. Overlay labels fit the viewport at small window sizes. All current figures and terrain remain prototypes; this does not qualify historical falconry reconnaissance, physiology, final art or human playtesting.

## Qualification

`game/tests/test_ground_focus.gd` exercises native character-eye and collision acquisition, continuous dwell, stale evidence, bounded estimates, sound cues, input/modal lifecycle and campaign isolation. `game/tests/render_ground_focus.gd` renders declared presentation fixtures in the actual Home scene. The render fixtures are not earned campaign progress or a player-input journey.

Run the inherited native suite:

    python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64

Run the visual fixtures with a display and software GL if required:

    godot --path game --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 --script res://tests/render_ground_focus.gd
