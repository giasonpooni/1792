# Controller remapping and verifiable development packages

This is an additive continuation of the [platform foundation](PLATFORM_FOUNDATION.md), inside the same Home territory game. It retains the original world, clock, story/save schemas, input executor, keyboard/mouse controls and native tests. It adds no store service, console binary, platform account or publishing operation.

## Reassign gameplay buttons

In Home territory, open **Menu → Controller settings → Reassign gameplay buttons** (keyboard: J/F1, then the same menu). Choose one of nine actions, select a button, inspect the proposed changes, then confirm. A conflict is a displayed, explicit two-action swap, not two actions firing from one button. An unused R3 can receive an action without a swap. **B** backs out through the editor; restoring defaults also requires confirmation.

The actions are interact/listen, mount/dismount, guard, counter, quiet approach, escort order, lower gait, household accounts and research. Allowed buttons are X, Y, LB, RB, L3, R3 and the four D-pad directions. D-pad navigation remains UI-only while a panel is open. **A/B, Menu/View, movement/look axes and triggers are not reassignable in this first editor.** This deliberately retains an accessible route to restore controls. Original keyboard and mouse mappings are not removed.

The home tutorial HUD and controls summary read the active mapping. A few inherited 3D labels and narrative/tooltips still show keyboard keys; this is not a universal dynamic-glyph conversion or a claim that other modes support the new layout.

`cg.controller-bindings.v1` is a separate bounded preferences record in `user://1792-controller-bindings.v1.json`. The existing deadzone/look/inversion file remains `1792-controller-settings.v1.json`, with no schema change. Character saves do not contain either preference record. Save/load/checkpoint rollback does not change your chosen layout.

Every action must occur exactly once, button codes must be finite whole values from the supported set, and two actions cannot share a button. Reads return detached records. A candidate is validated, persisted through the existing byte transport, then applied to InputMap. Invalid content or a failed write leaves the existing map installed. A malformed stored file is not deleted or silently rewritten. Held gameplay actions are released on reassignment. Focus loss discards an unconfirmed candidate; a background confirm cannot apply it or resume the world.

## Verify a development package

`tools/verify_platform.py` accepts a staged directory or ZIP. It does not extract an archive, execute a game, contact Steam, upload, sign or alter the package:

```sh
python tools/verify_platform.py /path/to/1792-windows-development.zip
python tools/verify_platform.py /path/to/package-directory \
  --expected-commit FULL_SOURCE_COMMIT --expected-tree FULL_SOURCE_TREE
```

Use actual full identities from the build record; the placeholder words above intentionally fail validation. Expected identities bind a result to the selected source record. Without a trusted external record, an unsigned manifest can be rewritten with its payload. **Conformance and hash consistency are not authenticity, code-signing, proof of execution or store certification.**

The checker enforces an exact file allowlist, bounded member counts/sizes, unique names including case-folding, non-linked members, safe canonical paths, strict manifest fields and booleans, duplicate-free JSON objects, sizes and SHA-256 values. It also checks the PE x86-64 and separate-PCK header shapes and runtime-notice identity. Shape checks do not validate an executable's behavior. Archive contents are streamed and never extracted. This is not a sandbox for racing hostile local filesystem writers; verify a quiescent build artifact.

The Windows build tool now verifies its completed ZIP against the actual checkout commit/tree and retains a separate `windows-package-verification.json` observation. The pre-existing new-process exported boot/save/replace/load test still supplies execution evidence. Neither observation substitutes for the other.

### Versioning and Steam

The producer emits `cg.platform-build.v2`. It preserves the prior payload/source/provider/operation/execution fields and adds `steam_preview` plus hashes for `recipes`. Local builds have no Steam identity and an empty recipe map.

Steam staging requires explicit app/depot IDs and produces the same preview-only app/depot scripts, now bound to the manifest. The verifier reconstructs the expected script bytes from those declared IDs and source commit. Turning Preview off, adding SetLive, or changing mappings fails even when somebody updates the recipe's hash. This is a local consistency rule, not a restriction on what an independently edited Steam tool can do. No SteamCMD command is executed and assignment/ownership of supplied IDs is not verified.

Old `cg.platform-build.v1` **local PC** packages remain readable. Old Steam packages lack a manifest-bound app/depot/recipe identity, so this verifier explicitly requires regeneration rather than pretending to verify that missing binding. The game save formats and existing platform-provider contracts are unchanged. Microsoft PC and Xbox targets remain unimplemented and fail with the same explicit reasons as before.

## Qualification

```sh
python tools/check_package_verification.py
python tools/run_platform_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game \
  --script res://tests/test_controller_remapping.gd
```

The expanded runner retains every previous suite and adds two test groups. Synthetic package fixtures cover valid directory/ZIP equivalence, old local manifests, recipe binding, rehashed non-preview scripts, duplicate/path/case/link attacks, changed/missing/extra files, strict types, oversized metadata and wrong expected identities. These fixture headers are not run as executables.

The remapping suite reuses the existing joypad-navigation helpers without rerunning/counting the parent's assertions. Its new journey starts at the actual title screen; only gamepad events reach menus, confirm/cancel the swap, encounter write failure, interrupt an unconfirmed change, and then physically walk to the courier and listen with the remapped button. It uses no pose/camera/progress injection, direct button-signal shortcut or keyboard/mouse event in that journey. Separate domain fixtures check reserved controls, detached proposals, corrupt files, held-state release, map preservation and persistence. Tests use isolated preferences/save slots.

Three explicit render fixtures show the editor, a small-window swap confirmation and a save-failure response. They are presentation fixtures, not the input-driven journey. The Linux/Windows workflow retains exact source, runtime logs and a remapping observation; Linux produces the images, while Windows builds, boots and verifies the actual development ZIP. Check observed workflow results before claiming qualification.

A synthetic joypad event is not a physical gamepad test. Consumer Windows rendering, unplug/replug on hardware, Steam client/Deck, authenticated platform users, cloud-save conflicts, arbitrary axis/keyboard rebinding, television-distance accessibility, signing, Microsoft packaging and Xbox port/certification remain separate work. The shared four-language architecture and NET's external investigation role are unchanged; the same game implementation remains the authority.

## Primary references

[Godot 4.5 InputMap API](https://docs.godotengine.org/en/4.5/classes/class_inputmap.html) documents runtime addition/removal of individual action events. This implementation replaces only gameplay joypad-button events, retaining keyboard/mouse/analog and recovery controls.

[SteamPipe configuration](https://partner.steamgames.com/doc/sdk/uploading) defines Preview, AppID, DepotID, ContentRoot and mapping behavior. Our recipe generator is offline; an actual Steam preview run remains unqualified. References consulted 2026-09-28.
