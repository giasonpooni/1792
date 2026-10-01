# Bazaar attention performance — faces look before they talk

This pass develops **eye-line, head attention and blinking** as direct character craft.

It deliberately does **not** create a perception or relationship system.

## Principle

The game already knows current body positions, dialogue speaker, encounter phase and existing combat receipts. From those facts, presentation can derive a short-lived attention target:

```text
authoritative geometry / receipt
          ↓
transient attention target
          ↓
head + eye presentation
          ↓
discard
```

No new memory, observation, testimony, suspicion score or relationship value is created.

## Staging

- A speaker generally looks toward Buddh.
- A listener looks toward the current speaker.
- During the challenge, Mela and Jiva attend to the lead challenger.
- During fighting, they track an active opponent.
- Active challengers attend to Buddh.
- On the walk home, attention returns toward Buddh/group movement.
- Buddh's presentation head follows the current speaker, nearest active opponent, or friends during decompression.

Supporting figures also receive asynchronous deterministic blinks. Blink timing is visual only and is not saved.

## Bounds

Head yaw/pitch are deliberately small. Eye spots move at most 3.5 mm horizontally and 2 mm vertically inside the prototype eye markers. These constraints prevent the presentation layer from producing impossible full-body turns or becoming a substitute for authored animation.

The player and NPC root bodies are never rotated or moved by the attention pass.

## Limits

This prototype can establish that characters stop staring straight ahead. Production quality still needs sculpted faces, eyelids/eyeballs, facial blendshapes, authored gaze holds/aversions, breathing, performed facial animation and human review at conversational distance.

The terminal can regression-check the authority boundary; it should not certify acting quality.

## Listening pass: finish the performance in the playable scene

This follow-up completes the existing attention prototype rather than introducing
another control-plane feature or a new campaign. The same five supporting figures
and Buddh's fitted costume remain. The figures are still blockouts, not final heads.

Mela turns promptly toward an available conversational target; Jiva takes a little
longer. The eyes lead the partial head turn and recenter as the head arrives. A short,
early listening nod belongs to Mela, while Jiva's nod is later and smaller. A current
speaker does not perform the listener nod. These are authored presentation choices,
not claims about historical personalities or measured human responses.

New glances require a near, front-facing target and a clear static-world ray. Buddh's
selection must also pass the existing character-eye `_seen` check. Hidden, rearward
and occluded subjects do not become tracking targets. When contact becomes ineligible,
the pupils stop tracking and the head returns toward neutral. This is not new gameplay
perception and adds no knowledge, witnesses, threat markers or camera control.

### Corrections to the initial prototype

The old blink changed a small eye mesh's Y scale to approximately 1.0 instead of
multiplying its original 0.018 scale. The new application preserves the original
35 x 18 x 18 mm marker and closes it proportionally. Eye offsets are now bounded
inside that marker, at 3.5 mm horizontally and 2 mm vertically. Head turn limits
remain 0.46 radians yaw and 0.22 radians pitch. Conservative rounding keeps float32
Vector2 values inside those limits rather than loosening the assertions.

Pitch now follows the positive-X rotation of a -Z-facing head; the earlier sign
looked downward toward targets above it. Pupils shift toward the target rather than
opposite the head's yaw. The neutral head frame uses eye height, not the character's
feet. Buddh's head world frame includes the existing skeleton hierarchy and existing
combat spine pose. Head attention composes with the retained pose.

Applying the same gaze twice no longer doubles the head rotation. The per-figure
interpolator advances at most once for each existing game tick. It neither owns a
clock nor adds anything to the game save. Rehydration discards later transient turns.
Recorded visual captures retain the small interpolation state separately so playback
can reproduce a turn without pretending that gaze is campaign state. JSON numbers
are validated and reconstructed as native float32 vectors before equality checks.

The dedicated test previously stopped at duplicate `beat` declarations and several
untyped Variant results. Those declarations are corrected; original game tests and
combat thresholds are unchanged. The blink test now examines a full cycle instead
of two times when both actors happened to have open eyes.

### Qualification and viewing

```sh
python tools/run_bazaar_direction.py --godot /absolute/path/to/godot
```

The new `test_bazaar_listening.gd` covers signed gaze, target eligibility, distinct
turn timing, repeat sampling, bounded turns, neutral recovery, exact eye dimensions,
actual occlusion, hidden actors, whole-world/camera preservation and visual-record
roundtrip/refusal. It uses labelled spatial fixtures; the existing three full brawl
journeys remain separate integration tests. Numeric assertions are not human ratings.

After the journeys, run the ordinary observation renderer and the optional close
inspection renderer:

```sh
xvfb-run -a /path/to/godot --fixed-fps 60 --path game --rendering-method gl_compatibility --audio-driver Dummy --script res://tests/render_bazaar_direction.gd
xvfb-run -a /path/to/godot --fixed-fps 60 --path game --rendering-method gl_compatibility --audio-driver Dummy --script res://tests/render_bazaar_listening.gd
python tools/check_bazaar_presentation_capture.py --user-dir /path/to/godot/userdata/1792
```

Close views use the recorded real journey positions/poses and explicitly labelled
inspection cameras. They are not new cameras available during play. The original
player-camera view is captured separately. The ordinary set has 46 images when no
optional ambient line interrupted the walk, or 47 when one actually surfaced. The
checker still requires every mandatory view, every 4-tick motion sample and the exact
image sizes. No dialogue is forced to play merely to fill a screenshot slot.

Software rendering and synthetic PCM do not qualify physical-GPU performance, sound
quality, lip sync, human enjoyment or final art. A full facial rig, authored animation
clips, recorded actors, and human creative review remain separate production work.

Godot API basis: Skeleton3D bone global poses are skeleton-relative, and rotations
are local to the parent bone. The world frame is constructed explicitly:
https://docs.godotengine.org/en/4.5/classes/class_skeleton3d.html
