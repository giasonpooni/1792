# Faces, listening and a held response

This is direct **1792** scene craft, extending the existing bazaar scene. No NET
changes or runtime dependency. It remains original prototype art, not finished
realism, recorded acting, historical likeness or psychological inference.

## The scene being directed

Mela's invitation has a slight grin; Jiva's reply has a one-sided lifted brow.
At the challenge that levity settles into resolve/concern. The challenger narrows
his eyes and draws his brows together. Defeat is a chastened expression, not a
new injury simulation.

The most important homecoming turn is deliberately not another victory grin:
Mela boasts, Jiva says he saw Mela looking for them, Mela admits that of course he
was. The held face changes from amusement to chastened attention to relief.
The other existing outcomes retain their different treatment. These directions
are not new relationship values, knowledge, rewards, dialogue choices or receipts.

The previously incomplete goods vignette now contains a full two-line exchange:
Jiva warns about the baskets; Mela answers, “Then stand where you can say you
warned me.” It stays optional and cannot interrupt story dialogue. The spoken
language remains English development text pending Punjabi editorial/performance
work; it is not a historical quote or a supplied recording.

## What is rendered

The five original supporting figures keep their bodies and clothes. Their existing
heads now have a shallow three-piece mouth, movable brows, better-seated eye/brow
features and a less faceted face surface. Eight named facial directions manipulate
small geometric offsets: neutral, amused, wry, resolute, concerned, challenging,
relieved and chastened. No mesh controls feed back into game state.

A speaking companion gets one small early head emphasis, then stillness. There is
no perpetual jaw flapping and **no phoneme or lip-sync claim**. The listener's held
response is as important as the speaker. Existing subtitles, choices, control of
the camera and combat timing remain intact.

Buddh's imported costume, face covering policy and visual limitation are unchanged.
Only his existing presentation head bone receives corrected local attention.
This pass does not give him a new symmetrical two-eye facial rig.

## Repairs discovered before extension

The inherited market-craft test could not parse: duplicate local variable names
and inferred Variants stopped it before any assertion ran. The separate approach
test also had an uninferred return type. They now compile with explicit types.
The blink-offset assertion compared two instants when both characters were not
blinking; it now checks asynchronous behavior over a complete interval.

Blink scale previously replaced the eye's small absolute scale with a value near
one, enlarging the mesh. Closing now multiplies the stored original scale and
reopens exactly. Head/eye limits use the same native Vector2 precision as the
returned values. Upward gaze has the correct sign; pupils move toward rather than
away from the target. Features sit on the face ellipsoid instead of floating in
front of it. Repeated sampling restores from the authored pose rather than adding
another head turn to the previous result.

Eye-line uses the head joint, not feet. A short-range geometry check refuses
tracking through a wall or behind the face. This is local visual admission, not
a perception record. Save/load discards old speech emphasis and uses the existing
world state to reconstruct neutral or phase-appropriate presentation.

## Play

Godot 4.5.1 Standard → Home territory → complete the inquiry → western market →
Walk with Mela and Jiva → challenge → stand or leave → regroup → report.
E/Q/left click/F5/F9/F6 retain their previous meanings. No new mandatory dialogue,
slowdown, lock-on, camera cut or control interruption has been added.

## Execute and inspect

```sh
python tools/run_bazaar_direction.py --godot /path/to/godot
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /path/to/godot --fixed-fps 60 --path game \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_bazaar_direction.gd
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /path/to/godot --fixed-fps 60 --path game \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_bazaar_faces.gd
```

The new test reuses the original three input journeys and records actual displayed
expressions/speech/state, plus separate labelled spatial fixtures. It checks
expression identity, bounds, eye scaling, idempotence, neutral reset, correct gaze
sign, obstruction, frozen-clock behavior and unchanged actor/camera/world/journal.

Eight face images replay recorded states: six expressive close-ups, one neutral
visual comparison at identical state and one original player-camera view. The
close-up lens is **inspection-only**, not a new shipped camera mode. Captures contain
no recorded audio. The original scene renderer remains; capture auditing now checks
all required images against actual retained observations instead of assuming an
optional ambient sentence always produces a fixed extra frame.

The full regression runner and all original gameplay tests remain. Changed fixtures
repair compilation or representation mistakes; they do not shrink colliders, move
NPCs, change costs, bypass original assertions or grant earlier production credit.
The approach-only test may emit its inherited ObjectDB cleanup warning on exit;
this does not establish leak-free resource handling or invalidate it silently.

## Still requires craft and people

These faces are plainly prototypes. The next fidelity step is a properly modelled
and skinned face, authored eyelids/cheeks, measured conversational distance, Punjabi
line editing and real performers. A deterministic facial pose can be regression-
checked; whether this admission lands emotionally requires human viewing/playtesting.
No beauty, historical authenticity, voice, human playtest, hardware performance,
Jolt migration, main merge or full-game production readiness is claimed.
