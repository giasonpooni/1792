# Horsecraft and the remembered feat

Horse handling is a production priority for 1792. The remembered horsecraft lesson now belongs to Buddh's childhood riding instruction in the playable Home. It extends the existing riding lesson with single-horse standing, paired standing and mounted matchlock practice. The separately available main-menu study remains a restartable practice scene. Both use the existing horse scene and motor.

## Play the childhood lesson

Pass the first existing riding practice gate. Brake, dismount with **F**, approach the nearby stable trainer on foot, and press **E**. The trainer opens a remembered tale of Maha Singh during Buddh's riding instruction. This is the lesson's present-day trigger; the feat itself has no assigned historical date or battlefield.

The lesson has three ordered parts:

1. Ride one horse, rise on its saddle, and hold supported standing while moving. Press **Enter** after completing the hold.
2. Establish the two-horse formation, rise with a foot supported by each saddle, and hold balanced support while moving. Press **Enter** after completing the hold.
3. Fire all four separately selected matchlocks from the supported pair, slow down to recharge **each of the four weapons**, then sit and stop. Press **Enter** to return after completing withdrawal.

Completing the full lesson admits one persistent receipt for the three capabilities `single_standing`, `paired_standing` and `mounted_matchlock`. In Home, **X** changes between seated riding and supported standing after the lesson is learned. **Space** changes stance inside the lesson and the standalone study. Capability learning is distinct from possession: the lesson grants no horse or weapon inventory items.

Home stays suspended throughout the lesson, including its world clock, actors and campaign state. The lesson runs in its own `World3D`; its horses and target physics cannot interact with the retained Home. Returning accepts the completed lesson against the suspended present and adds the riding-skills receipt to the existing save identity. Loading an older save without the extension creates an empty, locked skill record; it does not infer training from past riding progress. Pausing freezes lesson physics and progress. Retry restarts the lesson; returning before completion gives no partial skill grant.

`riding_training_chapter.gd` hosts the Home interaction, `riding_training_session.gd` owns the suspended-world lesson session, `riding_skill_state.gd` admits and persists the capabilities, and `horsecraft_training.gd` drives the three-part exercise. This training receipt does not complete the later fixed father retrospective, issue its story receipt, or change its ending.

## Standalone practice

Choose **Horsecraft · paired riding and mounted matchlocks** from the main menu. Ride both horses together, rise onto the two saddles, discharge four separately selected weapons, slow down to recharge each of the four weapons, then sit and stop. Targets provide feedback independent of whether a shot was accepted. Retry resets the exercise. This isolated study grants no Home capabilities or campaign progress.

| Input | Action |
|---|---|
| W, A/D, S | Forward, reins, brake |
| Ctrl / Shift | Walk / canter |
| Q/E | Counterbalance a turn |
| Space | Change between seated and supported standing |
| Mouse / left click | Aim / fire selected matchlock |
| 1–4 / R | Select one weapon / reload that weapon |
| Esc / Backspace / F1 | Pause / retry / return |
| Enter, in the childhood lesson | Continue a completed part / return after full completion |

## Handling and weapon model

The inherited motor retains walk, trot and canter caps of 3, 6.5 and 11 m/s, with finite acceleration, braking, slower turning at speed, gravity and collision-resolved movement. A follower receives bounded steering/throttle corrections through its own `horse.step`; it is never snapped or parented to the lead horse. Releasing forward or pressing brake stops the pair. Canter is available for handling practice, while standing and firing require the slower supported formation.

The support study checks lateral spacing, fore/aft slip, yaw difference, speed difference, height difference and grounding. A 48-tick rise precedes standing; turning induces signed sway and balance loss unless the rider counters it. Broken support requests braking and recovery. Thresholds are authored gameplay parameters, not measured human/horse biomechanics. Both original conservative horse hulls stay active. The interpolated rider/feet are a presentation study, not a ragdoll or a qualified standing-rider collision envelope.

The four slots hold separate single charges. A shot consumes one selected slot; another charged weapon must be selected for another shot. One weapon reloads at a time, for 180 supported slow-speed scene ticks; withdrawal requires all four weapons to have been recharged. Pausing freezes both bodies, attempt time and reload progress. Motion outside the reload envelope pauses progress. Timing and dispersion are play abstractions, not real firearm operation or calibrated ballistics. A camera ray establishes the aim point. A shoulder-to-muzzle ray checks a protruding weapon against cover, and an outward muzzle ray checks intervening scenery. Synthetic shot foley and a short tracer/flash provide local feedback.

The paired exercise has ordered approach, standing, four-weapon volley, reload and withdrawal objectives. The standalone study's completion stays local. The childhood lesson additionally requires its single-horse and paired standing holds before the weapon exercise, and only its complete verified return admits the three-skill bundle. Neither path can mark a historical chapter complete.

## Practice after learning

After learning the skills, the same trainer offers free single-horse and
paired-horse practice. Standing and mounted firing use the learned capability
checks in either formation. These sessions supply temporary training equipment
and return without new receipts or inventory grants. Buddh can also use **X**
to stand on the mounted Home horse; **Space** keeps its existing braking control.

## Horse, rider and handling presentation

The same procedural rider rig serves Home, the childhood flashback and learned
practice. It adds articulated limbs, visible hands and boots, rounded costume
and face landmarks, and a continuous seated/rising/standing/recovery projection.
The feet follow the observed saddle surfaces: one horse supplies both contacts
in single riding, while each independent horse supplies an inward saddle contact
in paired riding. Reins terminate at the actual animated bridle rings. Home's
unarmed rider holds them with both hands; practice gathers them in the supporting
grip while the selected weapon is handled.

Four persistent indexed weapon meshes follow the four existing charge slots.
Exactly one is selected and the other three are stored. Cosmetic charge cues,
recoil and abstract reload reach/work/return poses sample the existing model;
they cannot advance a reload or issue a shot. Selection is projected immediately,
including when all four weapons are selected and fired within one physics tick.
The established shoulder-to-muzzle and outward cover checks remain authoritative.

The shared horse now has rounded trunk/head massing, articulated legs and hooves,
mane/tail and saddle/tack. Its presentation samples the existing motor's speed
and distance phase only when the owner calls `step()` or restores a record.
The motor, gait caps, conservative hull and mount/dismount checks are retained.
The seven legacy rider anchors remain available to existing adapters.

These are authored procedural pose studies. They add no motion executor,
collision, inventory items, saved state or historical authority. Limb rhythm is
not a biomechanically calibrated gait, and the face is not a historical likeness.

## Historical evidence and attribution

| Claim | Evidence | Permitted use |
|---|---|---|
| Modern Nihang two-horse riding | Ajay Verma/Reuters photograph, Hola Mohalla, Anandpur Sahib, 24 March 2016, gallery 19/39 | Pose/composition reference for the modern practice |
| Sikh horsemen carrying matchlocks | John Malcolm, *Sketch of the Sikhs* (1812), printed pp. 140–141 | Near-period account of equipment |
| Mounted matchlock use | Joseph D. Cunningham, *A History of the Sikhs* (1849), Chapter IV, printed p. 117 | Retrospective account of mounted tactics |
| Maha Singh standing on two horses while managing four matchlocks | User-attributed story; passage not located in this research pass | Candidate remembered feat, with date, location and combined action unverified |

Sources and claim boundaries are retained in [mahan_horsecraft_sources.v1.json](../data/history/mahan_horsecraft_sources.v1.json). Photographic binaries have not been imported. The modern display does not authenticate the combined eighteenth-century battlefield episode. These accounts are historical sources with their own perspectives, not measurements of an individual's performance. Failure to locate the anecdote does not disprove it.

The horsecraft flashback is placed at `childhood_riding_training`, after the first observed riding gate and beside the stable trainer. It is an attributed tale used during Buddh's learning. The separate [Mahan retrospective](MAHAN_INTERLUDE.md), at the pre-Lahore 1797–1798 narrative gate, retains its fixed ending, childhood reprise and protected present-state return. Finishing the childhood riding lesson does not satisfy that later interlude. No battle/date is assigned to the horsecraft feat, and no interlude receipt, inventory item or character-knowledge claim is granted by the lesson.

The playable lesson opens with the remembered tale and teaches the single-horse stance before the pair, four separate shots and charge cycles, and withdrawal. Its practice ground, progression and thresholds are authored training design. An authenticated battlefield, historical dialogue and accompanying witnesses remain unresolved while the story passage is unlocated. Losing support or retrying cannot change the later father interlude's fixed outcome.

## Verification and production limits

`test_horsecraft_state.gd` exercises local rules and rejected transitions. `test_horsecraft_study.gd` drives the actual bodies through game input, tests a one-sided obstruction and blocked target rays, and checks pause/reload/retry and campaign-save isolation. `test_riding_skills.gd` covers the additive skill and save contract. `test_riding_training.gd` routes input through the isolated lesson viewport and checks access, all three lesson parts, all four reloads, suspended Home identity, completed return, cancellation, save/load and learned practice. The original `test_riding.gd` remains unchanged in the full suite.

`render_horsecraft_study.gd` retains five engine inspection frames and state/camera/image metadata. These are mechanics inspection views, not historical evidence, human playtesting or a hardware performance benchmark. The command-story workflow retains them with source identity and fails on engine errors.

`test_horse_visual.gd` checks observed horse presentation, stopped restoration,
pause and the preserved collision/rider contracts. `test_horsecraft_handling.gd`
checks actual same-frame weapon identities and muzzle origins, independent charge
cues, reload/pause behavior, saddle/bridle contacts and earned unarmed Home standing.

`render_riding_training.gd` retains six inspection frames covering the single-horse
lesson, paired stance, four spent matchlocks, reload, returned Home and earned
standing on the household horse. Native lesson progress, sampled hand/rein/weapon
observations and the retained Home binding accompany the capture metadata. The
last frame follows a seated departure from the stable using the real horse motor,
then earned standing in the courtyard. Its Home HUD is hidden only for the
declared inspection view and restored afterwards.

Next production work is authored gait-specific animation and hoof placement,
sculpted character/horse assets, uneven-terrain/support validation, and a mission
script grounded in the anecdote passage. The rhythmic articulated legs remain a
prototype; no anatomically correct walk/canter or physical rider-support claim is made.
