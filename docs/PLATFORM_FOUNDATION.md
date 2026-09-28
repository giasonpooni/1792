# PC, Steam, Microsoft and Xbox foundation

This increment makes the existing **1792 / Buddh Singh / Home territory** playable through semantic controller actions and adds an actual unsigned Windows export path. It does not publish the game, enroll a publisher, integrate a store SDK or produce an Xbox console executable. It is stacked on the oral-memory branch; unrelated town, social-field and economy branches are not silently combined.

## Play with an Xbox-style controller

Start the original project or an exported Windows development build. The title screen starts with the Home territory button focused. **D-pad** selects, **A** confirms and **B** backs out of a home panel. Menus scroll to focused controls; the right stick can scroll long text. All existing keyboard bindings remain.

| Gameplay action | Controller |
| --- | --- |
| Move / look | Left / right stick |
| Interact / mount | X / Y |
| Guard / counter | LB / RB |
| Run or faster riding gait / brake | RT / LT |
| Quiet approach | Hold L3 |
| Slower riding gait / escort order | D-pad down / up |
| Household accounts / reconstruction notes | D-pad left / right |
| Remembered stories | View |
| Journal, save, load, checkpoint, controls and main menu | Menu, then D-pad/A |

Controller settings offer bounded deadzone and look-speed presets, vertical inversion and reset. Preferences use a separate `1792-controller-settings.v1.json` file. Invalid or failed writes do not apply partial settings. There is **no arbitrary remapping editor, vibration or platform-specific glyph library** yet. A few inherited narrative/tooltips still mention keyboard keys; the integrated home HUD and control page provide the controller equivalents. Other menu modes remain available but are not claimed as fully controller-complete by this slice.

Walking now retains stick magnitude instead of normalizing every nonzero stick input to full speed. Full-stick keyboard/controller caps remain the old caps. Right-stick camera motion is time-based and respects deadzones, inversion and pitch limits; original mouse look remains. Walking and riding use the same existing physical bodies and authoritative operations.

## Focus and controller interruption

A scene-local shell observes input type and the last-used controller. Application focus loss or a simulated/native pause notification clears pending operations, releases held gameplay actions and opens the existing paused UI. Disconnecting the last-used pad also pauses. Focus return or reconnection never resumes automatically; the player deliberately resumes. Background confirm input is consumed rather than executing a menu action.

This is **single local-session input**, not authenticated controller-to-platform-user assignment. Multiple connected controllers are not segregated into different users. The notifications are a desktop foundation, not Xbox Quick Resume, console suspend deadlines, account-switch compliance or a certified lifecycle implementation. No catch-up clock, implicit save or second simulation loop is added.

## Platform boundary

`game/platform/local_services.gd` supplies `cg.platform-services.v1`; `local_storage.gd` supplies `cg.save-transport.v1`. The only implemented service provider is `cg.local-pc.v1`. It explicitly reports no platform account, no cloud save, no achievements and an entitlement status of **not_checked**, never a fabricated ownership result. Requests for unimplemented providers fail rather than silently substituting a local account.

The home state authority still validates schemas, source bindings, receipts and whole-world restoration. Only its byte transport is injected. The adapter uses bounded reads and temporary-file replacement; errors propagate without deleting an old destination or changing the live world. Existing save names, schema and earlier imports/checkpoint paths remain. The platform-service instance is not serialized into game state and cannot be selected by an untrusted save.

The original checkpoint store remains independently scoped and local; this increment does **not** claim that all checkpoint/economy/Lahore storage has been moved behind a cloud-ready interface. A future account-scoped asynchronous storage provider must include revision/cancellation/conflict handling and qualification before being selected. JSON numeric serialization is the existing save boundary; it is not a bitwise reproduction of in-memory floating-point values. Tests compare all restored serialized fields and separately validate the authoritative model.

## Distribution profiles

The executable declaration is `platforms/targets.v1.json`.

| Target | Implemented output | Still required |
| --- | --- | --- |
| `windows_local` | Godot Windows x86_64 release export, separate PCK, unsigned allowlisted development package | Real hardware/driver QA, release UX, signing and release review |
| `steam_windows` | Same PC payload plus offline **Preview=1** SteamPipe recipe generation | Actual assigned app/depot IDs, Steamworks onboarding, client testing and separately authorized upload |
| `microsoft_pc` | Explicit blocked target with reason, not a pretend package | GDK/MSIXVC integration, configured product identity and Microsoft certification |
| `xbox_series` | Explicit blocked target with reason, no binary | Approved console access, private engine port/templates and SDK, platform integration, devkit validation and certification |

Steam recipe generation never calls SteamCMD, signs in, sets a live branch or uploads. IDs must be supplied explicitly; the common sample 480 is rejected. Their assignment/ownership is not verified by the offline tool. Microsoft and Xbox targets are refused by the packager until real adapters exist. Naming an export profile does not add online capabilities to the local runtime.

## Windows export and packaging

`game/export_presets.cfg` contains the public **Windows x86_64 (local)** preset. Keep export credentials and restricted SDKs outside public source. The preset excludes development tests, uses a separate `.pck`, disables signing, and retains the reference compatibility renderer. It does not require Python, Julia, NET, Bevy, or the editor on the player's machine.

On Windows with the reference Godot 4.5.1 editor and matching standard export templates installed:

```sh
python tools/run_platform_checks.py --godot /path/to/Godot_v4.5.1-stable_win64_console.exe
python tools/windows_build.py --godot /path/to/Godot_v4.5.1-stable_win64_console.exe
```

Run this in a Git checkout without an existing `build/windows` or `build/package` output. The builder refuses to overwrite those directories. It exports the actual game, starts a **new Windows process from the export directory**, runs the opt-in `--platform-smoke` probe, then creates `build/1792-windows-development.zip`. The probe instantiates the actual home world, performs isolated-file save/replacement/load, checks content availability and development-test exclusion, and emits runtime copyright/licence notices. It never uses the player's regular save slot. This headless check is not a rendered Windows GPU test.

`tools/package_platform.py` checks executable architecture and PCK header, then copies only the declared executable, pack and notices. Its manifest records source commit/tree, runtime provider, operation/execution identity, size and SHA-256 for every payload file. Header checks are not proof of execution; the boot observation is separate. The packaged licence JSON comes from `Engine.get_license_text()`, `get_copyright_info()` and `get_license_info()` in the executed reference build. It includes engine dependency notices, not font assets. Original Cartesian Graphics rights and engine rights remain separate.

The offline Steam recipe mode accepts `--target steam_windows --app-id YOUR_ASSIGNED_ID --depot-id YOUR_ASSIGNED_DEPOT` together with `--source`, `--output`, `--notices`, `--source-commit`, `--source-tree` and `--execution-id`. It deliberately produces preview instructions only. No production release is performed by this repository workflow.

## Verification and retained evidence

The new workflow runs on **Linux and Windows** using explicit engine SHA-256 values. Every inherited native test remains; the runner adds oral-memory, platform and offline packaging checks. Four actual Linux software-rendered fixtures cover title focus, home controller HUD, settings and interruption. The unchanged inherited workflows also retain their existing renders. The temporary engine-transfer workflow used during development is removed from the final tree.

The new native suite has two distinct parts. An explicitly labelled fixture tests analog input, focus/disconnection, modal routing, settings, failure injection and persistence. The **full controller journey** starts from the actual title screen with no pose, camera or progress fixture. It injects Godot joypad events, navigates menus using the D-pad/A, walks, rides, guards/counters, follows traces, escapes, completes the household inquiry, hears and compares oral accounts, saves/loads through the menu, retells to the neighbour and returns to the title. It uses no keyboard/mouse events and no direct button-signal shortcuts. It is still synthetic input, **not a physical gamepad test**.

The packaged probe uses a fresh actual world, not a completed-inquiry fixture. Source inspection, headless native execution, packaging, software rendering and human/hardware qualification are reported separately. CI retains exact source.tar, commit/tree, per-suite logs, controller observations and rendered captures for 14 days. A successful workflow is necessary evidence for this slice, not a console certificate or store acceptance. Check actual run results; workflow configuration alone is not a pass.

## Architecture and next boundary

Godot retains the active game and clock. C++/Rust remain options for qualified native providers; Python/NET and Julia remain the tooling/reference layer. The four-language architecture is extended, not replaced. This code does not add a workbench dependency or a second game authority. The small public service/input contracts can be evaluated for Hero of the Two Worlds and Geronimo later; their repositories have **not** been modified or claimed qualified here.

The next bounded qualification is a real Windows controller session including unplug/replug, window focus, save permissions and restart, followed by a store-specific adapter selected through this boundary. Steam Deck/Proton, Windows rendered GPU behavior, console lifecycle, cloud conflicts, platform users, signing, arbitrary remapping and television-distance accessibility remain unverified.

## Primary references consulted

- [Godot 4.5 controller input](https://docs.godotengine.org/en/4.5/tutorials/inputs/controllers_gamepads_joysticks.html): InputMap, analog vectors/deadzones and controller focus behavior.
- [Godot 4.5 Windows exporting](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html): executable/PCK packaging and signing boundaries.
- [Godot Engine licence APIs](https://docs.godotengine.org/en/4.5/classes/class_engine.html): runtime copyright and licence reporting.
- [SteamPipe uploading documentation](https://partner.steamgames.com/doc/sdk/uploading): app/depot scripts and preview builds. This project does not execute an upload.
- [Microsoft PC game publishing with GDK](https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-game-publishing): current PC-only GDK/MSIXVC route, distinct from console onboarding.
- [Godot console support](https://godotengine.org/consoles/): approved SDK/template access and private porting requirements.

Consulted 2026-09-28. These references establish external integration boundaries, not that our project has passed their requirements.
