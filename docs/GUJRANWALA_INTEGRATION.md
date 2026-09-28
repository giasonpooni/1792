# Gujranwala integration receipt

## Inputs

| Workstream | Exact input commit | Treatment |
| --- | --- | --- |
| Main layout/research | a937bbd8722ae5505bbfc50e3792ddb4d007e3b9 | Retain starting world/design records; correct research; archive disconnected layout source. |
| Playable supply campaign | bec7c5e3d46dd5cd5318490a2ab08873bf7f66e2 | Preserve all existing missions, models, tests and the default home menu path. |
| Political/perception experiment | f82ac91e577056e259532d2da377e53c1a83237e | Preserve as a separate menu mode; include native tests; retain compatible checkpoint validator seam. |
| Rights/four-language documentation | 6b49d9dea96aae041977b3783f2ccb51a37f4078 | Adopt existing notices and architecture document unchanged. |

This is an integration of specific inputs, not a claim that every remote branch
was merged or every pending task was completed. No sibling game or NET repository
is changed by this Gujranwala-specific work.

## Preserved invariants

The original home scene and world schema stay byte-identical to their qualified
versions. The existing Gujranwala state and controller remain unchanged. A small
`researched_chapter.gd` subclass adds presentation, not a new treasury, clock,
save format, mission reducer or persistent population. `ranjit_singh` stays the
stable identity; Buddh remains the childhood display name. Lahore sandboxes and
the political experiment do not become chronological campaign transitions.

Main's `data/world/1792_start.json` is a design fixture, not an instruction to
inject extra known places into the separately validated childhood profile.
The full inherited player guide is retained in `docs/PLAYABLE_GUIDE.md`.

## Verification identity

The reconstruction test writes `gujranwala-reconstruction-audit.json` with a
versioned operation ID, model ID, raw manifest digest, engine version, executing
GitHub source SHA and pass/failure counts. This is synthetic validation evidence,
not a historical certificate, NET `run.v1` integration, or proof of physically
accurate simulation. GitHub run/artifact identity remains the external execution
record. Native and Python results, source snapshots and rendered captures are
retained by the workflow. Remote CI results must be read, not inferred from the
existence of tests.

## Local checks before submission

On 2026-09-28, the eight structural tests and 21 reconstruction tests passed in
the editing container. That container has no Godot executable. Native and rendered
validation are therefore performed by the repository's pinned Godot 4.5.1 workflow,
not silently credited to Python. See the integration pull request for the exact
run result and any fixes made after engine execution.
