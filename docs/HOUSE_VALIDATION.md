# House-conflict validation and audit

## First executed revision

Feature commit `560ad215bc258288f0ee6134036064a959062b8c`, stacked on the unchanged
command-story base `ee4a9c1e6418c8f85bf95736b45420f9314c48fe`, passed GitHub Actions
run `36397370519` on 2026-09-28:

| Check | Observed result |
| --- | --- |
| Structural suite | 8 passed |
| Original command suite | 202 assertions passed; 0 failed |
| New house-conflict suite | 253 assertions passed; 0 failed |
| Original render smoke | 4 captures; 0 failures |
| New codex/petition/biography/rival/report render | 5 captures; 0 failures |

This was Godot 4.5.1, Linux, OpenGL compatibility, Mesa llvmpipe software rendering
under Xvfb. The V-Sync support warning is retained in the logs; no runtime/script
errors were present. It is not a physical-GPU performance test or human playtest.

The downloaded evidence ZIP matched the GitHub artifact digest:
`82bf1d444c533acc8deb4cf0c1fe12566df56e7ed061ae8c492179466c0d3e20`.
The source snapshot ZIP matched:
`e7b1e9ef94e57241cdd51f920e7ebdcaf045981a1579801bce036dbec349e2d1`.
The code snapshot contains runnable project sources, not Git history or engine binaries.
Artifacts are retained for 14 days by GitHub; the PR retains the run identities.

## Audit corrections

Review of the rendered petition exposed HUD text visible through the default panel.
The revision makes the panel opaque, adds margins and hides the HUD/journal while
it is open. Closing restores them.

A second audit found that the house report should not carry territorial conditions
when the captain withdrew before observing the outpost. Outcome events now bind an
`outpost_observed` flag to the original order's actual observations; unobserved
territory is `null`, not a plausible-looking default. The UI reports it as unknown,
and the remote field sign is not updated from that report. Validation rejects even
internally consistent forged house evidence when the original order lacks the
claimed observation.

`test_house_reporting.gd` adds regressions for this boundary, pending-report save/load
and modal readability, then runs the unchanged original house suite. Run the full
extended suite with:

```sh
godot --headless --path game --script res://tests/test_house_reporting.gd
```

The first-revision numbers above are NOT automatically results for the audit revision.
The final tested commit, updated assertion count, successful run and artifact identity
are recorded in PR #2 after actual execution. The local container cannot run Godot;
its structural suite passed after the audit edits. Engine testing occurs in CI.

Outstanding manual checks: Windows replacement-save semantics, camera comfort,
controller input, small-window layout, scrolling and a complete human traversal.
The original `command_state.gd`, `command_sandbox.gd`, player implementation, home
scene, starting fixture and world schema are preserved. This is an additive single-
authority scenario variant, not a rewrite of the original working command slice.
