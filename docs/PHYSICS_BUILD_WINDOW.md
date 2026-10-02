# Physics development window: 2 October 2026

The authorized window runs from **01:53:25 to 07:53:25 America/Toronto**
(05:53:25–11:53:25 UTC). The initial interactive pass is followed by bounded
hourly continuation passes; the last pass reconciles evidence and stops new work.
This schedule does not assert six uninterrupted hours of engine execution.

## Ownership and integration

Repository: `giasonpooni/1792`, stable repository ID `1392110087`.
Dedicated branch: `feat/ground-contact-physics-v1-20261002`.
Initial source base: the exact gate-memory source tree from draft PR #67.
Keep this increment draft and unmerged during the window.

The initial isolated checkout is `/workspace/scratch/5a8547be7da5/1792-physics`.
The active horsecraft/family-introduction checkout is separate and must not be
modified by these passes. If a local checkout is absent, recover the dedicated
physics branch from GitHub rather than copying an unrelated working directory.

Acquire an exclusive `1792-physics-window.lock` in the Git common directory before
writing. Hold it for the complete build/check/publish pass. Check the branch head,
worktree status and current PR before editing. An existing live owner is a reason
to skip duplicate writes, not to remove its lock or overwrite its files. Independent
review agents in the same pass may inspect and test while file ownership is explicit.

## First measured defect

On the existing player capsule (radius 0.35 m, height 1.6 m), 180 forward physics
ticks at the 4.5 m/s walking target clear a 10 cm riser but stall at 18, 24, 30 and
34 cm risers. The wall begins at z=0; stopped centres are respectively near
z=0.306, 0.335, 0.350 and 0.350. Explicit vaulting begins at 35 cm.

An independent 30-degree slope fixture also measures approximately 3.893 m/s
uphill and 5.223 m/s downhill for the same 4.5 m/s command under the prior profile.
These are game-design fixture measurements, not historical or biomechanical data.

The first increment supplies bounded, collision-swept stair/curb contact and
constant-speed slope policy through the existing Player motor. A separate playable
ground-contact course admits it explicitly. Campaign defaults remain protected.

## Protected invariants

- Godot owns physical motion. Use the existing Player and horse bodies; do not
  introduce another controller, engine, campaign clock or state authority.
- Preserve legacy campaign acceleration and grounded save assumptions. New
  traversal/contact capabilities require declared admission and qualification.
- Use real collider shapes, collision masks, clearance and support. Art and visual
  contact do not establish physical support. Failed admission cannot teleport a body.
- A step must not add extra horizontal travel beyond the commanded tick movement.
  Grounded observations require supported physical contact; an unsupported drop falls.
- Keep physics observations separate from witness interpretation, received knowledge,
  journals and historical authentication.
- Course saves stay isolated. Validate complete source/tuning/geometry identity and
  physical fit before replacing motion, observation tick or the prior save file.
- Preserve concurrent standing/two-horse/mounted-matchlock and family work. Do not
  absorb unrelated branches, force-push, globally enable traversal or merge main.
- Keep source, runtime, operation, execution and independent verification identities
  distinct. A passed test is not a claim of human playtesting or production animation.

## Continuation queue

1. Complete the current step/slope course, verify overhead/overheight/edge refusal,
   native input-driven ascent/descent, pause and save/replay; retain executed traces.
2. Investigate defects exposed by independent adversarial collision and persistence
   review. Repair measured failures before adding another capability.
3. Qualify stopping, turning, approach clearance and capsule support on uneven ground;
   compare actual movement with commands at the pinned 60 Hz physics rate.
4. Inspect actor-specific horse clearance and mount/dismount transitions against the
   current committed horsecraft source. Implement only when ownership and integration
   are concrete; leave concurrent dirty work intact.
5. Run affected inherited checks and hosted qualification for each published head.
   At the cutoff, report exact completed commits, CI results and remaining limits.

No fixed amount of new code or checklist count is an acceptance criterion. Retain
failures and repair only demonstrated defects. Human feel and historical/art review
remain separate acceptance evidence.

## Current checkpoint

The initial increment supplies the opt-in shared motor, playable course, native
qualification suite, exact-source capture workflow and frozen-state renderer.
Its input-only half-speed journey traverses four 18 cm stairs and the connected
incline out and back in 798 observed ticks, with nine step contacts and 88 ground
follow observations. The quarter-speed route also completes. Ordinary airborne
descent uses real gravity; ascending corner transitions are explicitly identified
as bounded stair contact rather than reported as native floor contact.

Independent review reproduced and helped repair prior-floor-cache replay dependence,
false grounded fits, unrepresented native world/actor shape owners and collision
exceptions. Refused captures, restores and saves preserve native actor/course state
and existing slot bytes. The final binding also records shape margins and contact
solver bias. The proxy observes displacement without changing native physics.

Publication is stacked on gate PR #67's remote commit
`116cbc4125d2b56e556b0f7d2a3e0082fe9cd2cc`, tree
`1a8c9feb4b720f32265c9edff9809c85240d77d3`.
The physics draft PR and its current head are the continuation authority. Fetch
that head and verify its tree before writing; do not confuse the local source
commit with a remote commit sharing the same qualified tree. Each hosted capture
retains its own `source-commit.txt`, `source-tree.txt`, source archive, executed JSON
trace and native PNG in `ground-contact-physics-evidence`. Native full-run and
render logs are separate verification identities; inspect their completion markers
for the current head rather than treating this checkpoint as a CI success claim.

The next pass repaired a measured near-deadzone cycle: during a retained rounded-
capsule corner crossing, the supported destination may move slightly downward from
the prior tick while remaining above the original contact anchor. Mapped strength
0.22 now clears the connected stairs in 4,322 observed ticks; its longest retained
contact is 42 ticks, below the one-second deadline. Strength 0.24 remains the faster
qualified route. Stop, full reversal and perpendicular turn each release retained
contact in one physics tick and remain within the commanded travel budget.

Next unresolved work: qualify oblique approach angles and turning across uneven
ground beyond the straight authored lane. Keep the finite deadline, real full-hull
contact, rise bound and commanded travel budget. Inputs arbitrarily close to the
0.20 deadzone cannot have a finite completion-time guarantee. Human control feel
remains unqualified. Horse changes
still require a concrete, isolated integration with the current horsecraft source;
the concurrent family/horsecraft checkout remains untouched.
