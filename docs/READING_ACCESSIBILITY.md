# Reading settings and the current-message reader

A bounded, playable accessibility increment for the existing **Home territory** chapter. It extends the controller, remapping and save-recovery work; it does not change character knowledge, vision rules, physics, history or the platform provider.

## Use it

Before starting: **Title → Text and reading settings**.

In Home territory: **Menu/J → Text and reading settings**, or enter through Controller settings. **Menu/J → Read current messages** opens a larger, paused view of the last displayed task, controls and on-screen message. A visible narrator caption may also be included with its attribution. Unreceived stories and expired/disabled captions are not added. Restoring game state clears the old display snapshot; normal resumed rendering supplies the new one.

**Cycle text size** selects 100%, 125%, 150% or 200%. It applies to title labels, title buttons, home modal text, dialogue and modal buttons. Long content retains its full text in the existing scroll containers; right stick or mouse wheel scrolls, and D-pad moves between buttons. Layout updates reveal the focused button after font reflow, once per update rather than repeatedly overriding deliberate reading scroll.

**High-contrast menus** uses opaque black modal/button backgrounds, white enabled text, grey disabled text and a light focus border. Disabling it restores previous theme overrides. **Shah Muhammad captions** enables/disables only the optional retrospective development captions. It does not remove NPC dialogue, delete receipts, alter the narrator's event logic, or supply unheard testimony. There is no recorded voice or time-synchronized subtitle track in this increment.

**Reset reading preferences** returns these three settings to their defaults. It does not reset controller remapping, stick preferences or the saved chapter. B returns to the title or home journal; fixed Menu/View and keyboard/mouse controls remain available. Focus loss/disconnection keeps the existing pause behavior and cannot apply a background settings command.

## Scope of text scaling

The live HUD, live caption strip, 3D labels, other playable menu modes and the subjective peripheral treatment are unchanged. The **Read current messages** modal makes currently displayed home text available at the chosen menu text size instead of allowing an enlarged live HUD to cover the playable scene. Reading preferences are not clinical/perception parameters.

This is not a universal accessibility claim, screen reader, text-to-speech system, localization implementation, arbitrary font picker or Xbox accessibility feature certification. TV-distance testing and physical-controller/player review remain necessary. Full subtitle layout, remaining in-world prompts and other modes need their own bounded integration.

## Storage and ownership

`game/platform/reading_profile.gd` owns the process's local **presentation preference record** only:

```json
{
  "schema": "cg.reading-settings.v1",
  "text_percent": 100,
  "high_contrast": false,
  "narrator_captions": true
}
```

It is stored in `user://1792-reading-settings.v1.json`, separate from every world save and existing controller-preference file. The format and 4096-byte budget are strict; only declared preset values and boolean switches are admitted. Integral JSON numbers are normalized explicitly. Unknown operations are refused, not treated as implicit resets. Missing files use defaults; unreadable/invalid existing files are left intact with a visible settings warning.

A valid candidate is written through the caller's existing byte transport **before** becoming active. A failed or malformed transport result does not install unsaved preferences or silently fall back to another provider. Code-side test paths and transports are injected explicitly, not selected by saved game content. The local filename guard scopes settings to one user-data JSON filename. This does not provide adversarial-filesystem protection, locking or a power-loss durability guarantee.

`reading_ui.gd` styles selected Control subtrees, remembers original font/theme overrides, and scales from those originals so repeated updates do not compound. It queries no world state, changes no input bindings, and runs no gameplay clock. The active home controller's current-message snapshot is a disposable view of strings it already displayed, not a persistent transcript, source catalogue or second narrative ledger.

The original Godot authority, model-level schemas, manual save/recovery policy, checkpoints, platform identity and C++/Rust/Python/Julia roles remain. Steam, Microsoft and Xbox integration status is unchanged; no SDK, sign-in, cloud, publishing or certification work is represented as completed by text settings.

## Build and qualification

```sh
python tools/run_platform_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_reading_accessibility.gd
```

The new native suite retains separate model/operation/verification/execution identities in `platform-reading-audit.json`. Its labelled domain fixtures check format/preset bounds, startup failures, persist-before-apply, injected provider failures, scope, detached records, idempotent scaling and restoration of original styles.

The new actual-title journey uses only synthetic Godot joypad input: settings before gameplay, 200% text, contrast, focused-button bounds, scrolling, small-window resizing, storage failure, focus interruption, real walking/listening, save/load, narrator display and defaults reset. No pose/camera/story-progress injection or direct GUI button signal is used in that journey. Fault injection is identified separately. These are behavioral tests, not a physical controller or human accessibility study.

Four **explicit presentation fixtures** render title text, large small-window settings, remembered fictional accounts and a simulated error message. They are separate from the input-driven journey. The existing CI matrix includes all older suites plus the new one, Linux software-rendered captures and an actual exported Windows process probe. That process probes the shipped preference I/O and a real 200% modal without writing the player's preference file. Package verification remains a separate non-executing check.

Check retained logs and commit/tree identities for actual results. The workflow's presence alone does not establish a pass. No cross-platform bitwise physics determinism is claimed.

## Design references

Consulted 2026-09-28; these inform the direction, not a claim of compliance:

- [Microsoft XAG 101 — Text display](https://learn.microsoft.com/gaming/accessibility/xbox-accessibility-guidelines/101): configurable text and retained content/function during resizing.
- [Microsoft XAG 104 — Subtitles and captions](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104): separate caption readability concerns. The current English development narration is not a completed audio/subtitle implementation.
- [Microsoft accessibility metadata](https://learn.microsoft.com/en-us/gaming/game-publishing/concepts/metadata-accessibility): feature claims have criteria beyond simply adding a size setting. This project does not publish such a badge in this increment.

No third-party font, artwork, historical quotation or restricted platform material is imported.
