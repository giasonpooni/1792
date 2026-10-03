# Ground Focus v2

**Z** toggles a local Focus mode in the composed Home chapter. It emphasizes available sensory evidence while preserving the original player motor, camera, world clock, state, interactions and save format. **Q** remains guard; **E** remains inspect/speak; **X** remains hawk release/recall.

## Seeing and remembering

Focus uses the existing chapter `_seen` character-eye policy and physics collision geometry, within an authored 18 m envelope. A speaker's own front collision surface can be admitted; a wall before it cannot. The follow camera never supplies visual evidence. The optional PoliticalChapter now hosts the same Focus observer through its existing offset eye origin and changing vision profile; that policy is not installed in ordinary Home. Its affected-side exclusion still wins even when a separately aimed camera can display the target.

A visible subject requires **45 continuous existing 60 Hz ticks (0.75 s)** before identification. Home's existing broad horizontal facing cone also includes peripheral subjects; acquisition is not a pixel-reticle test. Subjects outside the displayed camera produce no screen marker. Duplicate samples of one tick do not add dwell; an interruption or skipped tick starts acquisition again. Hidden/disabled nodes are not acquired. Registrations cover existing trainer, steward, courier, mother, escort, horse, smith, available ground trace, assailant proxy and the two fictional distant scout contacts. The trace's existing visibility gate remains authoritative.

Before identification, a neutral **Observing** ring fills from the currently admitted eye samples. It carries no subject name, role, registration identity or affiliation. At most three pending rings appear, ranked by screen distance from the centre to limit clutter; this display limit does not alter dwell. Duplicate samples keep the same sampled point and fraction. Occlusion removes the ring, and reacquisition begins again while any earlier last-seen record remains at its earlier observed point. Progress is transient and grants no knowledge or task receipt. The existing visible steward and courier are eligible interaction subjects, but observing either supplies no letter contents or testimony.

When a ring first completes, the heading says **Observation retained.** for an authored 90 active ticks (1.5 s), then yields. The confirmation repeats no subject label, role or affiliation and creates no saved tutorial state; the world label remains the only subject-specific presentation.

Records carry observer identity, sensor identity, last observed position, observation tick and expiry tick. They live for at most **600 active ticks (10 s)** after the last observation. Current eye evidence says **observed now** and uses a solid-centred marker. When sight is lost the marker becomes a broken hollow ring at that observed position, says **last seen <1s ago** during the first retained second, then reports completed whole seconds while fading with age. The broken ring is presentation derived from the absence of a current admitted sample; it does not re-read a hidden target. The system does not round a new loss up to one second or keep reading a hidden person's live transform into that marker.

| Symbol and color | Meaning |
| --- | --- |
| `?` amber | Unidentified observed contact |
| `E` pale | Visible existing interaction |
| `*` gold | Available visible trace |
| `+` blue | Already recognized household person |

An unknown contact is not promoted to an enemy, faction member or conspirator by Focus. A trace highlight does not reveal its cause, inspect it, create testimony or grant a journal receipt. Perform the ordinary **E** action to acquire the existing narrative knowledge. That input ends the live Focus presentation before the established interaction reducer runs; retained sensory memory remains bounded, while the task owns any journal receipt and its source/channel identity.

## Estimating movement

Two acquired visual position samples at least **30 ticks (0.5 s)** apart may produce a constant-horizontal-velocity estimate. The estimator refuses motion below 0.15 m/s, above the authored 7.5 m/s bound, mismatched observation identities or samples more than one second apart. It reads no actor velocity, destination, route, intention or future chapter tick.

The dashed line is labelled **estimated** with its observed sample interval, carries its two source observation ticks, and expires at most **120 ticks (2 s)** after its latest source. Its dashed geometry remains distinct from both the solid-centred current marker and broken retained-memory ring. Both samples must come from the same observer and sensor; the estimate retains those identities. A consecutive eye sample retracts the line when its observed displacement reverses direction or departs more than 0.35 m from the constant-velocity envelope. This check compares admitted positions rather than reading actor velocity, destination or route. Occlusion stops updates and freezes the existing estimate until its bounded expiry; reacquisition starts a new continuous history. A direction change may still occur while hidden: this prototype provides a visual hypothesis, not a calibrated probability or guaranteed patrol path.

## Hearing

Focus observes actual playing, unpaused **AudioStreamPlayer3D** hammer playback already emitted by the workshop. Paused playback, a source at or below the existing -60 dB floor, an out-of-range source, or a mute anywhere in its send path through Master produces no new cue during ordinary mixing. Native solo mode instead admits only a source bus included in a soloed bus's send chain and, like Godot's mixer, ignores mute flags on that soloed chain. The configured source-plus-bus gain must also exceed the authored -60 dB cue threshold. Missing source buses follow Godot's Master fallback; malformed send routes decline safely. Already heard cues keep their reception tick and expire normally. Eight coarse direction sectors are retained for at most 120 ticks. Cues contain a sound description and sector, never an exact position or concealed person's identity.

This admission check reads playback and configured gain, mute and solo state. It does not measure stream samples, RMS, effects, speaker output or human audibility.

The acoustic envelope is an authored approximation: up to the emitter's existing maximum distance, capped at 16 m; a blocking collision halves that range and adds **muffled**. Direction is relative to the character's orientation when heard, and the UI displays the cue's age. This is not a measured sound-pressure, diffraction, room-acoustics or hearing model. No new sound is emitted and no historical sound recording is claimed.

## Lifecycle and authority

Focus does not pause or advance a second clock, move/freeze the body, switch cameras, change movement speed, write the journal, grant tasks, or write campaign saves. It yields whenever the player invokes the established **E** interaction, before that task path runs, and also stops during dialogue/notebook/art/atlas, sprinting, riding, active confrontation, or hawk scouting. It can resume only through the player control. Existing whole-world `_apply` clears all transient observations and estimates; tick rewind also clears them defensively.

The desaturation layer sits below the existing subjective framing and HUD. Focus temporarily hides the verbose original help block so it cannot cover observation markers; its prior visibility returns when Focus ends. Live dialogue captions and the compact task card remain available. The compact control strip changes its single Z hint from **Focus** to **Return** while active, so the Focus heading does not repeat E/Z keys. Until an identified observation is retained, that heading gives one contextual instruction: look toward a subject, then keep it visible while the anonymous ring fills. The instruction yields its space while identified evidence remains; coarse hearing lines use the same bounded heading. Instructions stack below the task card when the top-right space would overlap it. Rings and labels avoid visible task/word cards and Focus instructions; a crowded label can be omitted while its evidence remains intact. Icons, text and dashed estimates supplement color. All current figures and terrain remain prototypes; this does not qualify historical falconry reconnaissance, physiology, final art or human playtesting.

## Qualification

`game/tests/test_ground_focus.gd` exercises native character-eye and collision acquisition, anonymous progress, continuous dwell, stale evidence, sensor-bound estimates, sound cues, input/modal lifecycle and campaign isolation. `game/tests/test_focus_audibility.gd` checks actual native playback against routed bus mutes, solo isolation and configured gain, restoring the prior mixer layout afterward. `game/tests/test_focus_player_journey.gd` begins from fresh Home state and uses ordinary mouse/key input, the production ground motor, retained courtyard collision and the existing clock to approach, interrupt and earn an observation. The same unseeded route then observes the production courier without learning his account, uses actual **E** input to inspect the sealed letter and separately hear testimony through the existing reducers, and proves Focus yields while those task receipts retain their original source/channel identities. Actual F5/F9 input proves the whole-state save replaces the attempt and clears transient perception. The complete opening route additionally earns the household protection choice, deploys and holds the production escort, keeps him anonymous through the first 20 Focus ticks, identifies him only after continuous character-eye dwell, and uses actual G input plus the production escort motor to create and visibly contradict a 30-tick motion estimate. It injects no actor/sensor pose or velocity and reads no route or affiliation. These are earned automated input journeys, not first-time human playtesting. `game/tests/test_political_exposure.gd` separately binds Focus to the existing authored monocular profile and proves that camera placement cannot admit affected-side evidence. `game/tests/render_ground_focus.gd` renders declared presentation fixtures in the actual ordinary Home scene, including the real compact task panel at small window sizes. Those render fixtures are not earned campaign progress or a player-input journey.

Run the inherited native suite:

    python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64

Run the visual fixtures with a display and software GL if required:

    godot --path game --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 --script res://tests/render_ground_focus.gd
