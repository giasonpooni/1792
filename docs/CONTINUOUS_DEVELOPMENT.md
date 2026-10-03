# Continuing game production

This is the execution checkpoint for the user-authorized development of 1792 and
the production tools that support it. Notation Systems Inc. develops these through
Notations Gaming, Notation Manufacturing and Notations Laboratories. The immediate
game work makes the jatha consequential through relationships, commitments,
received knowledge and physical travel.

## Current increment

PR #83 has merged. The next increment starts from main at
`152d880a3c221272525645c44f8d3e2a535d8529`, on
`feat/nihang-care-sequence-v1-20261003`:

- A voluntary three-beat horse-care conversation: bridle, footing and return.
  Only its final choice records the existing care event; all intermediate pages
  remain presentation. Childhood monikers and the received journal schema persist.
- A stop/start column that brakes without turning around to chase a retreating
  following slot. It uses the preceding horse's pace and the shared motor's
  stopping distances, then settles with zero steering inside the arrival radius.
- Native input, stale-dialogue, save/load and 30/60 Hz physics checks, plus
  three-page rendering from the input-driven journey's retained state.
- The workcell notice copy and its exact-source hash follow the updated root
  notice, repairing the stale-link mismatch encountered in the full suite.

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

Choose against current main and player-visible gaps, avoiding duplicate work in
other story branches. The next small camp increment is navigation from the first
greeting to the horse lines, followed by a clear return to household riding
guidance when care is accepted. Keep danger guidance ahead of optional mentorship.

Then develop the next consequential undertaking: a companion's terms, a journey
that exercises those terms and a witnessed consequence. Prefer a complete short
mission with a readable setup and payoff before expanding the roster. Recruiting
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
| An earlier save discards a future promise | Existing whole-Home save authority | F5/F9 rollback; no future page action or care testimony |

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
