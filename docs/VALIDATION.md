# Command-story validation

Implementation target: Godot 4.5.1 standard, compatibility renderer.
Base: `7c99341364ad344759f9f6f24d92090275214de9`.

## Verified engine result

The corrected gameplay revision **`9261542d6252f05747cf2def9955e01b26b09c59`** passed
[GitHub Actions run 36394330030](https://github.com/giasonpooni/1792/actions/runs/36394330030).
The PR merge ref tested was `4a5769bd472fa6f8188f420fb175352be3f19a7e`, against the base above.
The workflow completed successfully on 2026-09-28 at approximately 07:56 UTC.

| Check | Observed result |
| --- | --- |
| Offline structural checks | 8 tests passed |
| Actual Godot project import | Passed |
| Command rules, persistence, corruption refusal and scene interactions | `COMMAND_STORY_TESTS: 202 passed, 0 failed` |
| Software-rendered scene captures | `RENDER_SMOKE: 4 captures attempted; 0 failures` |

The engine reports `Godot Engine v4.5.1.stable.official.f62fdbde1`.
Rendering used Mesa llvmpipe under Xvfb, not a physical gaming GPU. A V-Sync support warning
was present; there were no script/runtime errors. This establishes a runnable prototype,
not finished gameplay, performance certification or a human playtest.

The retained artifact `command-story-evidence` (ID `10957661843`) contains import, structure,
command-story and render logs, plus courtyard, command-table, captain and received-report PNGs.
Its downloaded ZIP was verified against SHA256
`7da70462aef0e15ce9c06e29695969b2f0d760629b588ed8fccc976fdcce384b`.
The command-table and received-report images were inspected: the camera, allocation interface,
returned resource balance and delayed report are visible. The art remains a primitive blockout.
GitHub artifact retention is 14 days; this record preserves the run identity and observed results.

This evidence update changes documentation only; the gameplay revision above is the tested code.
The pull request remains a draft, unmerged, pending human review of mouse/camera comfort,
both mission routes, failed-load UI, return-to-menu behavior, window sizes and Windows save replacement.

## Local checks and limitations

The development container has Python but no Godot executable. Its direct network access also
cannot resolve GitHub, so the engine could not be installed locally. Source changes were written
through the authorized GitHub connector; the actual engine ran in GitHub Actions.

`tools/check_project.py` checks resource references, scene resource counts, fixture references,
separate chronology, menu entries and preservation of the original home scene and world schema.
`tools/run_checks.py` returns a failure/not-run status if no engine is available.

All 8 structural tests also passed locally. The command fixture passed validation against the
unchanged `world-state.v1` JSON schema using local `jsonschema`. The local engine runner
correctly exited with status 2 (Godot unavailable). No local engine execution is claimed.

## Failure found and corrected

The first actual run, `36393966294`, on feature commit `9332373a72ce7cd141131994fd39cb07922db5e0`,
imported the project and reached **184 assertions passed, 10 failed**. Rendering was correctly skipped.
The failures exposed type-sensitive Dictionary equality after JSON decoded integer quantities as floats.
The correction compares allocation quantities numerically and canonicalizes validated discrete counts
after loading. Added regressions ensure malformed fractional or boolean quantities are refused rather
than coerced into validity. The successful corrected run is recorded above.
