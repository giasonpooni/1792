# Playable family tales: additive Home entry

Run the new composition with Godot 4.5.1:

```sh
godot --path game res://history/punjab_chiefs_home.tscn
```

The ordinary family opening plays first. After returning to the courtyard, walk
to the wooden story bench at `(-4, 0.14, 6)` and press **T**. Choose a tale to
enter its playable scene. The original T story-development slate remains
available away from the bench. Escape closes the selector; a tale's return
control returns to the retained household.

This is a new runnable composition. The default launcher, original Home,
opening, player and horse motors, state schemas and save files are unchanged.
No completed tale is added to Home's progression, inventory, knowledge or riding
skills. Each tale's own journal belongs to that telling.

`punjab_chiefs_entry.gd` adds the nearby selector. It pauses the live household
while choosing and consumes T before the existing development-slate handler.
Entry requires clear nearby ground, no mount, no active story/riding visit,
closed household menus and no active household commitment. A selection invokes
`PunjabChiefsSession.start_story(host, sequence_id)`.

`punjab_chiefs_session.gd` extends the existing retained-world lifecycle from
`riding_training_session.gd`. It parks the original Home in-tree, suspends its
execution, hides its CanvasLayers and pauses its audio. The tale owns an isolated
native SubViewport and World3D. The inherited input-forwarding path routes
events into that viewport. Return checks the original Home state SHA and refuses
a completed return before the playable scene reports completion. It restores
the same Home objects and flags, releases distinct session metadata and resumes
ordinary play. Cancel and external overlay cleanup also restore control.

The session overrides the riding completion path entirely and grants no riding
receipt. Host teardown releases the isolated viewport without trying to resume
a world that is leaving the tree. No source recollection is written into Home
merely because the player visited it.

The new chapter scene is the playable adapter, not a change to the default
launcher. A future default-menu hook can target this composition after the
owner of that launcher reviews the integration.

## Native lifecycle qualification

```sh
godot --headless --path game --script res://tests/test_punjab_chiefs_session.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_punjab_chiefs_journeys.gd
```

The native suite physically walks the original Home player to the story bench,
refuses distant entry, parks and closes the catalogue, enters an actual playable
delegation scene and refuses premature completion and overlapping visits. It
checks the retained authority, native body transforms, presentation identities,
Canvas/audio flags and Home save bytes through cancellation, forced overlay
removal and host teardown. This qualifies the visit boundary; individual tale
routes and cinematic presentation require their separate playable checks.

The journey suite walks all six fresh routes with keyboard inputs into the
existing player motor, and steers/stops Desi through the existing horse motor.
It invokes dialogue only after actual proximity and sight admission. It observes
a lagging companion, waits for physical arrival, walks around a well upright
that obstructs interaction, rides the declared crossing distance and dismounts
onto clear ground. It checks refused early completion and a single earned
return signal after every final objective. It never places the player at an
objective or injects narrative progress. These automated routes qualify basic
playability; they are not human playtesting or a cinematic-quality verdict.

## Checkpoints, controls and verified scope

Within a tale, use WASD to walk, mouse to look and E to interact. Desi uses
W to ride, A/D to turn, S to halt and Shift to canter. Choices are admitted
at the current physical objective, with sight and companion-arrival checks.
F5 keeps one checkpoint per tale; F9 recalls it. Save only on firm ground and
halt Desi first. Escape opens the return control. Completed tales retain local
choice outcomes; these are not faction simulation or campaign rewards.

Checkpoint loading validates narrative replay and candidate body positions
before applying them. It resets a former companion, restores mount presentation
and rejects damaged, incompatible or obstructed checkpoints atomically. It never
uses the household's save path.

```sh
godot --headless --path game --script res://tests/test_punjab_chiefs_state.gd
godot --headless --path game --script res://tests/test_punjab_chiefs_checkpoint.gd
godot --path game --rendering-method gl_compatibility --script res://tests/render_punjab_chiefs.gd
godot --path game --rendering-method gl_compatibility --script res://tests/render_punjab_chiefs_ride.gd
```

Godot 4.5.1 qualification on 2 October 2026: state 339/0, lifecycle 31/0,
native journeys 205/0 and checkpoints 94/0 (passed/failed). The existing
`test_childhood_intro_session.gd` regression also passed 613/0. Native
1280×720 OpenGL frames were inspected for all six openings and the mounted
Desi conversation/crossing; dialogue framing was adjusted to remove overlapping
exploration labels. The ride render passed its seven admission/capture checks.

This is a first playable blockout. Characters, landscapes, carried objects and
conversation cameras are simple procedural presentation. Finished art, voiced
performances, bespoke action animation and a sound pass remain future work.
Default-launcher and CI registration are separate integration decisions; the
new composition and checks are runnable directly without editing those files.
