# Continuing game production

This is the execution checkpoint for the user-authorized development of 1792 and
the production tools that support it. Notation Systems Inc. develops these through
Notations Gaming, Notation Manufacturing and Notations Laboratories. The immediate
game work makes the jatha consequential through relationships, commitments,
received knowledge and physical travel.

## Current increment

PR #99 has merged the current Nihang mentorship and Focus integration. Draft PR
#95 was closed as superseded because its remaining diff would restore an obsolete
renderer timeout and regress the stronger current renderer. This increment starts
from main at `43521dbeb939ce0b3f833e965f90c2112478688b`, on
`feat/nihang-terms-crossing-v1-20261003`:

- The veteran states a concrete low-ground condition before accompaniment. Ranjit
  must halt, dismount and count every invited rider within calling distance before
  the group may cross to the north marker.
- Riding directly to the marker produces a local refusal, not progress. Returning
  to the halt and keeping the term records received testimony; the veteran later
  names the conduct at homecoming. Childhood monikers remain relationship-bound.
- The condition derives from existing received events, adds no parallel quest
  engine or save schema, and does not retrofit old invitations with a new obligation.
- The input-driven journey covers the attempted shortcut, physical return,
  dismount/count/remount, group turnaround, F5/F9 and stopped check-in.
- The journey exposed a native restore-preflight defect: appended staged peer RIDs
  were not retained by the physics query. The query now assigns the completed
  exclusion array, rejects real staged overlaps separately and restores the saved
  formation without treating discarded live positions as obstacles.

Draft PR #101 publishes this continuation for review.

Local focused qualification is complete at 301 assertions with zero failures,
and the full configured suite exits zero on Godot 4.5.1. Hosted results must be
bound to the exact published continuation commit before they are reported as
passing. This execution host cannot attach Godot to its virtual X display, so the
hosted graphics workflow remains the visual-review authority.

See [the camp guide](NIHANG_COMPANIONS.md) for play, authority and historical scope.
These additions develop one existing childhood sequence. General recruitment,
adult campaigning and the full childhood-through-Lahore route are ongoing work.

## Execution cycle

An enabled automation runs bounded hourly development passes. A scheduled pass is
not a resident worker and does not guarantee an uninterrupted process. Each pass
should finish one concrete, qualified increment, publish a reviewable draft and
leave a precise checkpoint for its successor.

1. Resolve GitHub repository ID `1392110087` and inspect current main, relevant
   open drafts and CI. The current name is `atomtrapping/1792-The-Lotus-Throne`.
   Continue an open development branch; if it merged, start from current main.
   Never keep publishing to the closed PR #83 branch.
2. Use an isolated checkout. On this execution host, hold a nonblocking exclusive
   `flock` on `/workspace/scratch/1792-pr83-development.lock` for the entire pass.
   Keep the established path after that PR merged so old and new runs share the
   lock. If occupied, skip mutations. Check for interrupted or concurrent work
   before choosing a new change; do not discard another pass's edits.
3. Finish any interrupted qualified increment first. Make implementation choices
   within the user's authorized scope and publish draft commits without force
   pushes or automatic main merges.
4. Run the affected native checks. Changes to common motors or inherited Home
   execution also require the full configured suite. Treat engine errors as
   failure even if an assertion count looks successful. Inspect the actual
   rendered interaction when layout or pacing changes.
5. Report implemented behavior, exact source/runtime identity, checks and real
   blockers. Update this checkpoint with completed scope and the next bounded
   action. Hosted checks still running must remain described as running.

Scratch recovery should use published source and verified Git object identities.
Do not infer that a removed workspace means published work is missing. Restore
imports before diagnosing UI failures caused by unavailable native assets.

## Next priorities

Finish exact-commit full-suite and hosted qualification for the low-ground terms
increment before starting another feature. Keep danger guidance ahead of optional
mentorship and avoid duplicating adjacent opening, household, instructor and
ecology work. Draft PR #100 qualifies the existing Focus system's earned-input
journey; it changes Focus tests, documentation and CI rather than this camp route.

Then carry this witnessed obligation into one later bounded choice rather than
expanding the roster immediately: the veteran's willingness to accompany a second
outing should derive from the received halt/homecoming history, with a readable
alternative for an unfinished first ride. Recruiting
mercenaries, specific outlaw bands and local kinship contingents requires distinct
terms and identities. Hiring a leader does not transfer an entire clan. Historic
Thuggee-associated content needs period and geographic evidence before authoring.

Keep the established protagonist identity, Home clock, physical controllers,
whole-state saves/checkpoints and finite received event records. Newly encountered
Nihangs do not automatically inherit childhood intimacy. Outdoor camp authoring
does not establish a historical Gujranwala site or open a religious-site interior.

## From stated need to evidence

The current increment provides a small production example of the company's
approach: state a need, keep its authority explicit, execute it and retain evidence.

| Need | Authority | Executed check |
| --- | --- | --- |
| A veteran teaches care before accompanying Ranjit | Existing camp care event | Actual page buttons; partial reading cannot grant an event |
| A jatha returns together | Selected rider identities and native mount poses | Input-driven ride, turnaround and stopped check-in |
| A follower leaves stopping room | Shared horse motor and physical collision | Stop/start column at 30 and 60 Hz; spacing and final rest |
| A rider's stated term constrains the route | Received invitation and halt events | Direct-marker refusal; physical dismount/count; witnessed homecoming |
| An earlier save discards a future promise | Existing whole-Home save authority | F5/F9 rollback; no future page action or care testimony |
| A loaded formation is judged as staged state | Existing world-clearance preflight | Stale live peers excluded; staged overlaps still refused |

Use observed repeated production needs to justify reusable tooling. Inspect current
NET and superrepo interfaces before changing them; reuse existing exact-source and
runtime binding where sufficient. Avoid a parallel state engine, proof vocabulary
or production framework for one scene.

Game execution can qualify internal rules and native simulation. Connecting the
terminal to physical equipment additionally needs measured observations,
calibration, explicit units and independently established acceptance criteria.
Industrial measurement retains its own authority. Neither rendered footage nor
passing game physics tests establish a validated cyber-physical process.

## Reproduce the checks

Use Godot 4.5.1 Standard, executable SHA-256
`db07cae7de644278a1884d4552bdf2bca3f5d30131b18faf3a0c4d730080b199`.

```sh
python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
```

For executed-state rendering, first run the camp journey with
`NIHANG_CAPTURE_OUTPUT` set to an existing output directory. Then run
`game/tests/render_nihang_care.gd` in a graphics-capable native session with the
same output directory. The source snapshot and capture provenance belong with
the results. Human review still determines literary quality, attention and art;
passing geometric bounds alone does not measure them. This host cannot start
X11; the configured Linux CI performs that render check and retains its artifacts.
