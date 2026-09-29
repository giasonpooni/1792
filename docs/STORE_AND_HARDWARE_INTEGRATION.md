# Store integration and real-machine qualification

This increment turns three remaining gaps into executable tools. It does **not** turn
synthetic tests into physical-controller evidence, a generated config into Microsoft
approval, or a Windows executable into an Xbox console port.

## Actual boundaries

| Work | Implemented | Still requires external qualification |
| --- | --- | --- |
| Windows hardware session | Opt-in local recorder, controller/focus counters, frame-interval summaries, optional game-view capture and attributed operator checklist | A person using physical hardware; consumer Windows rendering/performance and accessibility judgments |
| Steam client | Optional GodotSteam session bridge, callback owner, overlay gate, client/app/user checks and app/user-scoped local manual saves | Qualified native GodotSteam build, assigned App ID, running licensed Steam client, actual overlay/offline/account-change tests, separate native packaging |
| Microsoft PC | Verified-payload-to-loose-file staging, MicrosoftGame.config, logo checks, source receipt and explicit MakePkg genmap/pack runner | Assigned Partner Center identity, original approved assets, installed trusted GDK/MakePkg, SubmissionValidator success and actual installed-package tests |
| Signing / Xbox | Explicit handoff requirements; no silent conversion of local files into certified output | Publisher signing identity and private console engine/SDK/devkit integration; see [private port handoff](XBOX_PORT_HANDOFF.md) |

All previous home, controller, remapping, recovery and reading behavior remains the
default local-PC profile. No store enrollment, account login UI, upload, purchase,
key generation, production signing, installer registration or certification submission
is performed by these tools.

## Run the hardware session on your Windows machine

Extract the Windows development ZIP and keep its files together. From its root:

```powershell
.\content\1792.exe -- --hardware-session
```

The ordinary launch has no recorder. The flag explicitly enables a local observation
session. A **Local hardware test session** button appears at the title and in the
Home journal (**Menu/J**). The title can export the report. In the Home menu, choose
**Review: ...** to record **Observed pass**, **Observed failure** or **Not tested**
for a specific check. These are operator self-reports, not automatic test verdicts.

Test a real controller through conversation and menus; unplug/replug it; switch
focus out/back; save, quit the whole process, restart and Continue; inspect movement
and rendering; and read/navigate 200% text at the actual intended viewing distance.
After a restart, the new session can record the restart result explicitly. Reports
are separate execution records rather than merged automatically across processes.

**Export local report** writes `report.json` under a unique directory:

```text
user://1792-qualification/<session-id>/report.json
```

On the normal Windows profile, `user://` resolves under
`%APPDATA%\Godot\app_userdata\1792`. The report includes OS/engine, render-adapter
name/vendor/API, viewport, aggregate joypad/focus/connection counts, source/build
identity and bounded wall-frame interval percentiles. It does **not** record typed
text, account IDs, persona names, device GUIDs, player coordinates or save contents.
Nothing is uploaded, and no automatic report is saved at process exit.

**Capture current game view** explicitly stores the current game viewport in that
same session directory, not the operating-system desktop. Re-export the report to
include its image digest. Only one current `view.png` is retained per session.

Frame intervals include menu frames, scheduling and focus stalls; they are **not
GPU timer measurements or a frame-budget qualification**. Only the latest 3,600
process-frame samples are retained in memory. The report stores their summaries.
Software-renderer names are hints, not a general physical-GPU detector. OS joypad
events may come from real devices, virtual devices or test injection.

Headless, fixed-fps and CI sessions are classified as automated; code-side fixtures
also declare that status. They cannot write an operator pass/fail. Every report
keeps `certified=false`, `human_accessibility_study=false` and `uploaded=false`.
An interactive self-report still is not independently authenticated evidence.

The Windows exporter injects source commit/tree and build-execution metadata into
`build_identity.json` only during export, then restores its tracked editor template.
Source archives retain the template; the exported PCK contains the derived build
identity. Editor runs show `editor-unbound` rather than inventing a source revision.
The package manifest hashes the complete resulting PCK separately.

## Steam: explicit native session, no local-account fallback

`steam_services.gd` implements `cg.steam-client.v1` behind the existing
`cg.platform-services.v1`. `platform_runtime.gd` owns the single optional process
session; Godot retains the only active gameplay world and clock. The runtime pumps
callbacks during menus/pauses without advancing game time.

To exercise this bridge, first supply and qualify a GodotSteam-enabled engine or
compatible extension build. The standard downloadable local-PC build **does not
include a Steam native module/extension or Valve redistributable**. Dropping an
unverified DLL beside it is not a supported conversion. The current local-package
verifier deliberately rejects unknown added native files. Native Steam distribution
still needs its own dependency hashes/notices and export/verification profile.

With a qualified source runtime, supply the actual assigned App ID:

```text
<qualified-godotsteam-runtime> --path game -- --steam-app-id=<assigned-app-id> --hardware-session
```

The parser rejects duplicate/invalid/out-of-range IDs and the public sample ID 480.
It checks the singleton's method arities and three-argument overlay signal. It calls
`steamInitEx(app_id, false)` with **App ID first**, checks actual current App ID and
positive user identity, and requires the client to report access to the current app.
An offline client is not automatically refused just because it is not logged into
the network. The result is **client-reported subscription**, not signed server-side
authentication, a platform sign-in implementation or proof of purchase.

Disable `steam/initialization/initialize_on_startup` and
`steam/initialization/embed_callbacks` in this profile. No other script/provider
may initialize/shut down/pump this singleton. No relaunch or overlay activation is
automatically requested. The bridge does not request Steam Input, friends, cloud,
achievement, presence, commerce or telemetry operations.

Overlay opening pauses and blocks input. Closing it cannot override OS focus loss
or auto-resume the world. Callback App ID metadata is not substituted for the SDK's
actual current-session identity. Client/app/user change invalidates the provider,
pauses play and refuses later scoped reads/writes until deliberate process restart.
It does not silently switch account, restore old access or fall back to local files.

Manual saves and previous-generation recovery use the original state validator and
byte-transport contract under `user://store-users/steam/<app>/<user>/...`. There is
no automatic import of existing unscoped saves. Character IDs and save schemas do
not contain platform user identity. Reading/controller preferences remain OS-user
preferences, not account saves. Legacy shared checkpoint writes/restores are disabled
**only in this opt-in Steam profile** until their separate account-scoped integration
is qualified; use manual saves. Other development menu modes do not launch under
this opt-in profile because their providers have not been adapted.

Test doubles are explicitly tagged `injected_test_double`; they never set
`native_client_observed=true` in a diagnostic report. Method-shape and fake-client
tests do not establish native ABI compatibility, current library suitability,
live-client success or Steam Deck verification.

## Microsoft PC: stage first, run MakePkg explicitly

`tools/microsoft_pc.py` consumes an independently verified **local Windows** directory
or ZIP, plus explicit identity and original logo files. It never modifies the input
package. Other-store packages are refused. Only the six original allowed payload
files are copied, with their hashes checked during copy. A new, separate output
contains `loose/`, `MicrosoftGame.config`, four exact-size RGB/RGBA PNGs and `stage.json`.

Create a private identity JSON from the actual Partner Center product identity:

```json
{
  "schema": "cg.microsoft-pc-identity.v1",
  "identity_name": "<assigned package identity Name>",
  "identity_publisher": "<assigned Publisher, including CN=>",
  "version": "1.0.0.0",
  "store_id": "<assigned 12-character Store ID>",
  "display_name": "1792",
  "publisher_display_name": "Cartesian Graphics",
  "description": "<reviewed product description>"
}
```

Angle-bracket placeholders are deliberately **not valid production IDs**. The tool
validates their supplied shapes, not their assignment/ownership. Keep any restricted
product configuration in the private release workspace. The synthetic profile in
tests is explicitly not a Microsoft-assigned game.

Supply `Square44x44Logo.png` (44 square), `Square150x150Logo.png` (150 square),
`Square480x480Logo.png` (480 square), and `StoreLogo.png` (100 square). This bounded
stager accepts 8-bit, non-interlaced RGB/RGBA PNGs, checks dimensions/chunk CRCs and
bounded scanline decompression, and refuses malformed/oversized files. These checks
are not editorial review or Microsoft's full SubmissionValidator. Optional PC splash
art is not generated in this increment. No final store art is fabricated.

```powershell
python tools/microsoft_pc.py stage --package <verified-local-zip> --identity <private-identity.json> --assets <original-logo-directory> --output <new-stage-directory> --expected-commit <full-source-sha> --expected-tree <full-tree-sha>
python tools/microsoft_pc.py pack --stage <stage-directory> --makepkg <absolute-installed-makepkg.exe> --tool-sha256 <trusted-tool-sha256> --output <new-package-directory>
```

The second command prints a plan only. Add **`--execute`** on Windows to invoke
exactly these argument-array operations on the pinned installed tool:

```text
makepkg genmap /f <output>/layout.xml /d <stage>/loose
makepkg pack /pc /f <output>/layout.xml /d <stage>/loose /pd <output>/packages /validationcritical
```

It never executes a command supplied by the profile, uses no shell, and invokes no
`upload`, authentication, key-generation, `/skipvalidation`, install or signing step.
The stage is revalidated before each call. Existing outputs are not replaced. Tool
failure/interruption retains logs and a distinct execution record rather than
promoting a failed result. Successful execution must produce a nonempty `.msixvc`.

The generated config is PC-only, `configVersion=1`, with explicit Name/Publisher/
Version/StoreId, one executable, ShellVisuals and x64 registration. It does not
invent Xbox Live TitleId/MSAAppId, cloud saves, AdvancedUserModel support or console
flags. The baseline MakePkg format is **MSIXVC**, not an automatic adoption of the
separate MSIXVC2 route. No production encryption option is supplied; development
packaging is not suitable evidence of production encryption/signing.

`stage.json` is immutable staging evidence. A separate `execution.json` records
native tool execution when requested. Source/hash consistency is not a publisher
signature or authenticated third-party filesystem. Work with quiescent regular
inputs; racing hostile changes, junctions in ancestors and cross-process locks are
not qualified. Tool hash pinning needs a trusted origin; a hash of an arbitrary
executable is not an endorsement of that executable.

## Verification and provenance

`python tools/run_platform_checks.py --godot <godot>` retains every earlier suite
and adds `check_store_integration.py` plus `test_store_integration.gd`. Native tests
use explicit fake clients for SDK success/account changes and actual Godot scenes,
input dispatch, pause and local file I/O. No fake DLL is shipped. Three render fixtures
show the report UI, operator-report distinction and missing native-client refusal.

The Windows build additionally runs a new exported process with
`--headless -- --hardware-session --platform-integration-smoke`, verifies its source
bindings, and retains `windows-integration-observation.json`. This probe cannot
claim a native Steam client or physical hardware. The original exported gameplay/
reading/recovery probe and independent package verifier still run separately.

## Primary references consulted

- [Steamworks API overview](https://partner.steamgames.com/doc/sdk/api): initialization, explicit App ID, running client and callback/shutdown ownership. Native API integration is not required merely to distribute a PC game on Steam.
- [ISteamApps](https://partner.steamgames.com/doc/api/ISteamApps): current-client subscription semantics; this is not a server-side ticket verification service.
- [GodotSteam source snapshot](https://github.com/GodotSteam/GodotSteam/blob/9a3480/godotsteam.cpp), `steamInitEx`, `getAppID`, `getSteamID` and `overlay_toggled`; [registration settings](https://github.com/GodotSteam/GodotSteam/blob/9a3480/register_types.cpp). This historical primary snapshot verifies the targeted callable shape, not a current binary recommendation. The maintainer's current repository moved to Codeberg; that native distribution was not installed/tested here.
- [MicrosoftGame.config reference and schema](https://learn.microsoft.com/en-us/gaming/gdk/docs/reference/system/microsoftgameconfig/microsoftgameconfig-schema?view=gdk-2604): current installed `GameConfigSchema.xsd` and SubmissionValidator remain the native authority.
- [ShellVisuals](https://learn.microsoft.com/en-us/gaming/gdk/docs/reference/system/microsoftgameconfig/elements/microsoftgameconfig-element-shellvisuals?view=gdk-2604): logo dimensions/pixel formats and optional PC splash.
- [MakePkg](https://learn.microsoft.com/en-us/gaming/gdk/docs/features/common/packaging/deployment/makepkg?view=gdk-2604), updated 2026-09-15: local pack/genmap, `/pc`, validation-critical mode, separate upload operation and development encryption limits.

No biological/educational/clinical benefit, historically authenticated sakhi,
physical-controller validation or store certification is inferred from this build.
