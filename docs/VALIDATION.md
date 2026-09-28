# Command-story validation

Implementation target: Godot 4.5.1 standard, compatibility renderer.
Base: `7c99341364ad344759f9f6f24d92090275214de9`.

The development container has Python but no Godot executable. Its direct network access also
cannot resolve GitHub, so the engine could not be installed locally. Source changes are written
through the authorized GitHub connector. Do not mistake structural checks for a playable-engine test.

`tools/check_project.py` checks resource references, scene resource counts, fixture references,
separate chronology, menu entries and preservation of the original home scene and world schema.
`tools/run_checks.py` returns a failure/not-run status if no engine is available.

Local result: all **8 structural tests passed**. The command fixture also passed validation
against the unchanged `world-state.v1` JSON schema using the locally available `jsonschema` package.
The engine runner correctly exited with status **2 (Godot unavailable)**. No local GDScript,
physics, rendering or human playtest pass is claimed.

The added workflow is designed to run the actual engine tests and retain logs/screenshots.
The implementation is kept in a draft pull request until that evidence and a human playtest
have been reviewed. Runtime and render outcomes must be recorded from the real workflow run,
not inferred from the presence of tests.

Human review still needs to cover mouse/camera comfort, both mission routes, failed-load UI,
return-to-menu behavior, different window sizes and Windows save replacement.
