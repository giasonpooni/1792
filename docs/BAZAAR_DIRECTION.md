# A Short Walk — directing the existing bazaar encounter

This is a direct game-content increment, not a NET workload. It extends the current
Home territory and authored courtyard, using the same protagonist, physical friends,
encounter, choices and final account. No new simulator, backend or parallel campaign.

## The playable dramatic shape

**Invitation → disagreement → decision → physical danger or departure → relief → account.**

Mela wants a shared adventure and dislikes backing down. Jiva is dry, observant and
more concerned about getting everyone home. Neither abandons Buddh. Their difference
should make the player care about the company, not choose a statistical allegiance.

At the market, select the existing **Walk with Mela and Jiva** option. On reaching
the challenger, **Hear Mela and Jiva** opens an optional exchange before choosing.
The original **Stand with my friends**, **Walk away together** and decision deferral
remain immediately available. Hearing the exchange is not mandatory.

> Mela: And you always know the way out.
>
> Jiva: I would rather we used it before someone breaks a tooth.

The fight still uses Q to guard a faced strike and left click to counter a checked
strike. Retreat after starting the fight remains possible. The two friends follow
physically, stop when contact is lost, and must return with the player. They do not
acquire new combat abilities in this increment.

After regrouping, they react differently to standing ground, withdrawing, or leaving
without fighting. The quartermaster has three newly written responses. He asks for
an account, not a heroic self-description. No branch receives new coins, experience,
territory, automatic recruitment or a generic morality bonus.

All new dialogue is original English development writing. It is not a quotation,
translation of a sakhi, voice performance or newly authenticated historical incident.
Mela, Jiva and these challengers are fictional; the existing Bhangi affiliation is
attributed speech within the authored tale, not a verdict about an entire community.
No religious figure or restricted historical character becomes playable.

## What the player sees and hears

Five supporting figures now have individual coat/cloth palettes, faces, modest headwear,
articulated shoulders/elbows/hips/knees, and visible hands. Their original body, collision
shape and physical motion remain. The defeated pose is a crouch, not vertical scaling
of the collision capsule. These are original procedural character studies, not finished
skinned production characters, historical costume reconstructions or final facial art.

Attacker animation follows the existing staggered attack cycle: preparation, raised
strike, committed blow, checked reaction and recovery. Buddh's existing fitted costume
now shows a two-handed guard, a short counter and a received-hit reaction. These are
visual bone rotations, not added hitboxes, IK/contact matching, root motion or a new
combat solver. The inherited abstract interaction reach is unchanged. No claim of
hand-to-body contact accuracy is made. The older training-shield proxy is hidden only
in this unarmed encounter; a shield is not awarded to the player.

The encounter has a compact objective and contextual guard/counter cue. The action
cue requires a nearby, visible opponent that the character is facing. Floating youth
labels no longer announce attacks through the scene. There is no camera takeover,
automatic targeting, forced zoom, shake, flash, slow motion or hit-stop. Existing
camera controls and reversible courtyard appearance settings remain.

Mela/Jiva lines are attributed on screen and last 210 existing simulation ticks.
They require nearby clear contact; a blocked/distant friend cannot continue a subtitle.
The small queue discards missed/expired lines rather than repeating stale speech.
The lines express immediate reactions only; they do not supply offscreen intelligence
or alter the saved journal. Existing authoritative encounter memories remain intact.

Original synthesized cloth/check/impact cues accompany visible/local actions. They
are nonvocal placeholders, not recordings, voice acting, historically authenticated
sound or a complete market ambience mix. F6 mutes these encounter sounds without
changing gameplay; muting and other presentation preferences are session-local.
Visual action cues remain available with sound off. No copied samples or music.

## Pacing, pause and persistence

The dialogue is a paused conversation using the existing panel; it does not steal
movement time or choose a branch. Both friends must still be nearby and in contact
when the optional exchange executes. The confrontation can be deferred as before.
An eight-second unobtrusive closing caption uses the existing report outcome.

The director reads the existing clock and encounter receipts. It cannot move a body,
apply damage, change a treasury, add memories or write a save. F5/F9, caught recovery
and the prior bazaar retry continue using the current whole Home/workshop save slot.
Restoring state reconstructs current poses and cues but does not replay old impacts
or previously spoken banter. Transient subtitle queues are intentionally not saved.
No cross-backend migration, networking or new save schema is added.

## Play and reproduce

Open `game/project.godot` in Godot 4.5.1 Standard. Choose **Home territory**, finish
the inquiry, go to the western market on foot and meet Mela and Jiva. E speaks;
Q guards; left click counters; F5/F9 save/load; F6 mutes this encounter's sounds.
No NET process is required. The funded-service and other independent branches are
not silently merged. This branch preserves the later courtyard and reference work.

```sh
python tools/run_bazaar_direction.py --godot /path/to/godot
```

The wrapper runs every original suite without edits, then reuses all three actual
input-driven brawl journeys with added presentation checks. Each journey has one
completed-inquiry setup fixture before launch. Optional conversations, guarding,
counters, departure, regrouping and reporting then use the real control path.
Separate labelled spatial tests verify source-state/collider preservation, blocked
speech, muted sounds, and no effect replay on hydration. PCM is checked for nonzero
bounded output, not evaluated for subjective quality.

For actual engine-rendered observation playback:

```sh
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /path/to/godot --fixed-fps 60 --path game \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_bazaar_direction.gd
```

Run the native direction test first: it writes `user://bazaar-direction.json`.
The render script reconstructs actual recorded states, player camera, input-dependent
pose and transient subtitle state. It creates eight stills (including 800×450 layout)
and a sequence of fight images at four simulation-tick intervals. Motion playback
should therefore be encoded at 15 fps, not the renderer's wall-clock speed. This is
observation replay, not a new playthrough or a physical-GPU benchmark. No recorded
voice or mixed game audio accompanies the capture.

## What still requires direct craft

The fighting remains a sparse, nonlethal greybox encounter. It still needs motion-
captured or carefully authored full-body actions, contact adjustment, facial acting,
real voice performances, richer bazaar composition, a fuller soundscape and independent
human playtests. The current visible figures and environment remain below the project's
high-fidelity target. Passing the checks establishes preserved behavior and functioning
presentation—not beauty, fun, dramatic effectiveness or final production readiness.

The next creative review should ask whether a player can distinguish Mela from Jiva,
read the next blow without floating labels, choose to leave without feeling that they
failed the story, and find the homecoming worth listening to. Those are testable human
experience questions, not properties a terminal should certify from file counts.

Engine API reference for skeletal presentation (not evidence of artistic quality):
https://docs.godotengine.org/en/4.5/classes/class_skeleton3d.html
