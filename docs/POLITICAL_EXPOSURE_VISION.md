# Living politics and one-eye perspective

## Play the extension

Open `game/project.godot` in **Godot 4.5.1 Standard** and choose **Living politics + one-eye vision (extended home chapter)**. The retained Home territory and both Lahore entries remain available. The extended entry instantiates the same home PackedScene and subclasses the existing chapter and aftermath state; it does not replace their mathematics, physics or chronology.

Complete the existing tutorial, survive the return encounter, and finish the household inquiry. Then use **E beside Raj Kaur** for scouts, reparations and discretion; use **E at the three labeled authored outpost nodes** for raids and limited incursions. These orders resolve **abstract political/logistical incidents**, not animated raids or full battles. Outposts are deliberately fictional test geography.

**P / J** opens received reports and remembered experience. **F6** switches between eye-level and the retained follow camera. **F4** toggles visual treatment only; it does not restore sensory eligibility or change rivals' information. F5/F9 and R retain the existing save/load and checkpoint controls.

## Authority and evidence

`political_state.gd` extends `aftermath_state.gd`. There is one `_state` and one authoritative `childhood.tick`. The new `childhood.politics.v1` profile contains `politics.v1` (bounded input ledger) and `vision.v1` (profile and onset identity). Political metrics, coalitions, delayed reports and encounters are deterministic, disposable projections of the input ledger and that same clock. The controller's `campaign` and inherited `model` are references to the **same object**.

Recorded inputs distinguish a game operation from an observation submitted by the physical line-of-sight executor. An input ID is not a source identity; neither is a report ID. Relayed reports retain the originating event identity and reduced confidence. Geometry submissions are trusted engine observations, not cryptographic proofs.

Victim resources can be damaged before the victim receives attributed information. Retaliation uses received attribution rather than direct access to every world event. The regular journal includes only the protagonist's own commands and reports actually delivered to his channel. `political_debug()` and JSONL campaign traces are explicitly privileged test telemetry; they are not player HUD data.

## Political dynamics implemented

Five authored gameplay blocs exercise directed grievance, attention, fear, resource limits and political surface area. Repeated raids are more disruptive and more visible than limited incursions. Reports travel on declared prototype routes with different arrival times and confidence. Scouts cost resources and produce delayed, potentially stale accounts rather than granting an instantaneous global map.

Grievance and attention decay at different rates. Thresholds produce watchfulness, rallies, mustering and resource-constrained retaliatory incursions. Pairwise coalitions require a shared target and sufficient common pressure, reduced by grievances between the prospective partners. Separate entry/exit thresholds allow coalitions to dissolve without oscillating at one threshold. A temporary coalition does not rewrite kinship or permanently merge factions.

High hostility, attention, recent observed opportunity, and exposed surface area can create a **covert warning**, followed by a **plot disruption**, **assassination-attempt event**, or **poisoning-attempt event**. Discretion reduces surface area and supplies abstract protective precautions. These are encounter hooks with a small abstract resource consequence. They do **not** prescribe methods, model substances, identify an attacker without a report, or impose an unavoidable player death. Physical covert encounters and assassination combat are not implemented by this slice.

The physical home controller samples Raj Kaur, a fictional northern observer, and an active household escort using range, facing cone and collision raycasts. Riding and conspicuous movement increase the submitted signature. A player-facing watchful-glance cue additionally requires Buddh to perceive the observer; a hidden observer does not produce an omniscient warning icon. No visible glance is not proof that no one is watching.

## Characters, households and historical status

Raj Kaur's **gameplay bloc is Phulkian**, per the selected game taxonomy. Personal identity, household service and political alignment remain separate relations. The canonical protagonist ID remains `ranjit_singh`; the self/player name remains Buddh Singh through the inherited naming authority.

`social_registry.gd` seeds only the identities needed by this slice. Two historical-character portrayals are distinguished from explicitly fictional retainers. Relations have half-open year validity and declared design provenance. Undated candidates and unresolved identities are not activated. **This is not a completed Sandhawalia genealogy, historical retainer list, or evidence-supported political reconstruction.** The larger roster still requires source-backed research and review; no family members have been invented to fill it.

The new politics, reports, dialogue choices, observation routes, outposts and tuning are authored game content. They do not establish historical motives, conspiracies, alliances, or facts about Raj Kaur or any other historical person. Existing source files, antagonist roster, identity rules and both Lahore authorities are unchanged.

## Progressively decreasing vision

A new extended game uses `authored_progressive_left`: the normalized left-eye contribution decreases at an increasing rate over **18,000 active physics ticks** (five minutes at the declared 60 Hz). This duration and the field/range parameters are **game-design parameters, not historical dates, clinical measurements or a claim of progressive bilateral blindness**. The right eye remains functional; progression stops at the one-eye endpoint.

The eye-level camera is offset to the functional-eye side. Physical recognition has an asymmetric affected-side angular limit and peripheral range reduction. Turning the head can bring a target into the retained central field. Occlusion is checked from the character's eye, not from a camera floating behind a wall.

The shader gradually softens and darkens the affected periphery rather than blacking out half the display. It renders below the HUD so dialogue, journal text and controls remain readable. Presentation and viewpoint preferences do not alter the persistent vision profile or the rival observation reducer. There is no calibrated stereopsis/depth-perception model, medical simulation, or proven accessibility usability result here.

## Saves, checkpoints and legacy import

The extended manual slot is `user://1792-political-vision-v1.json`; the checkpoint appends `.checkpoint.json`. Original childhood and aftermath slots are not overwritten. The journal includes an explicit previous-aftermath import control; the original childhood import is retained.

Imported legacy saves begin with an empty political ledger at their existing chapter tick and **stable left-monocular vision**. They do not fabricate earlier incidents or restart the loss of an eye. New-profile saves cannot silently omit one of their extension identities. Invalid loads validate before replacing state; the inherited scene geometry checks still apply. Restoring an earlier snapshot discards subsequent incidents, observations, knowledge and visual progression, while rendering preferences remain presentation settings.

The existing checkpoint store gains only an optional caller-declared validator script. Its envelope, size checks, staged validation and default legacy behavior are retained. No authority script path is read from an untrusted save.

## Verification and limits

The new GitHub Actions workflow imports with pinned, checksum-verified Godot 4.5.1, runs `res://tests/test_political_exposure.gd`, retains a real **1,000-step reducer trace**, and executes six Xvfb/Mesa software-rendered fixtures. It fails on engine errors or a missing completion marker. The inherited workflow continues to run all previous suites and render captures. A workflow definition is not evidence that a run passed: consult the checks for the actual commit.

The new suite covers temporal registry behavior, monotone vision progression, healthy-eye preservation, left/right handedness, occlusion, nonfinite inputs, delayed attribution, relay delay, atomic rate-limit/capacity refusal, rally/muster/retaliation, coalition formation/dissolution, protective mitigation, full versus incremental replay, JSON restoration, physical-site dispatch, old-save migration, checkpoint preservation, and one-authority controller wiring. Fixtures are marked as synthetic rather than presented as a human-played journey.

The authoritative input ledger is capped at **256 inputs**. Gaze submissions are rate-limited to once per observer per 600 ticks; player operations to once per 180 ticks. Capacity overflow refuses new inputs atomically and displays a prototype-limit notice. This is a bounded prototype, not a streaming persistence implementation. Derived traces and received-report display windows are bounded separately; the full projection can be reconstructed from the authoritative inputs.

Outstanding: the full historically verified Sandhawalia/retainer network, geographic campaign migration, physical raiding armies, battle resolution, covert encounter spawning, voice/audio design, broader diplomacy and economy, additional camera/perception calibration, physical-GPU performance, Windows persistence validation, and human playtesting. No private NET/SCR provider or replacement execution substrate is introduced.
