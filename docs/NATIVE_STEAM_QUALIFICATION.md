# Native Steam runtime qualification — not live-store approval

This is a separate, executable qualification lane for the existing Steam adapter.
The ordinary Windows build remains **standard Godot 4.5.1 / offline by default**.
No Steam client, assigned App ID, native redistribution permission or console
certification is inferred from a passing native load test.

## What the lane actually does

1. Build and independently verify the existing local Windows package with standard
   Godot and its original export preset. Preserve its source-bound manifest.
2. Download a SHA-256- and byte-size-pinned public **GodotSteam 4.16.1 module build
   for Godot 4.5.1 / Steamworks 1.62** into the runner's temporary directory.
3. Verify the complete upstream archive and exact selected member hashes. Run
   every retained source test through the **real native GodotSteam Windows editor**.
4. In an isolated temporary directory, combine the native release template and its
   matching `steam_api64.dll` with the **unchanged verified 1792.pck**.
5. Run a new packaged process that verifies native singleton availability, the
   adapter's actual method/signal contract, and native client absence. The common
   admission preflight refuses absence without any `SteamInit` invocation or
   sample/unassigned App ID. If a Steam client is running, this no-client fixture
   refuses rather than attempting a login.
6. Run the unchanged packaged gameplay/save/recovery/Continue/reading probe using
   that native release template. The gameplay provider remains local in this
   specific probe. Recheck native/PCK hashes after execution.
7. Delete the temporary payload. Retain source, logs, runtime licence metadata and
   separate dependency/operation/execution/verification records only. **Native
   binaries and Valve libraries are not uploaded in CI artifacts or game source.**

This separates **module/ABI/local-gameplay compatibility** from **live Steam client
behavior**. Neither a fake client nor native client absence is a successful live
session. Actual overlay rendering, launch entitlement, client-offline behavior,
user switching, cloud, achievements and Steam Deck remain separate qualifications.

## The deliberately pinned runtime

The upstream published [v4.16.1 release](https://github.com/GodotSteam/GodotSteam/releases/tag/v4.16.1)
identifies the Godot 4.5.1 line. It is an older reference, **not a recommendation that
this is the latest or production-approved bridge**. The project has moved to
[Codeberg](https://codeberg.org/godotsteam/godotsteam); GitHub describes these assets
as overflow downloads that may be removed. If they disappear or change, fail and
review an explicit new dependency lock. Do not fetch a moving latest release or
silently upgrade the game's engine.

`tools/steam_native.py` locks the archive's URL, length, SHA-256 and all five member
hashes. It copies only the release template, editor, console wrapper and x64 Valve
library. It uses no `extractall`, shell invocation, account discovery or installer.
Existing outputs are not overwritten. An interrupted acquisition never promotes
an incomplete reference directory. `inspect` checks the installed files against
code-owned constants, not just hashes supplied by a mutable receipt.

These integrity checks do not replace publisher signatures or a security review.
The probe executes code: use only the trusted project build and reviewed native
reference. It is not a sandbox for arbitrary attacker-supplied executables/PCKs.
Quiescent regular inputs are assumed; hostile concurrent filesystem changes and
power-loss durability are outside this slice.

## Run on a Windows development machine

From the source repository, using Python 3.12:

```powershell
python tools/steam_native.py install --output C:\1792-qualification\native-reference
python tools/steam_native.py inspect --reference C:\1792-qualification\native-reference
python tools/steam_native.py qualify `
  --reference C:\1792-qualification\native-reference `
  --package C:\1792-qualification\1792-windows-development.zip `
  --evidence C:\1792-qualification\native-results `
  --expected-commit <full-commit-from-the-verified-build> `
  --expected-tree <full-tree-from-the-verified-build>
```

Use a fresh output directory. `install --archive <downloaded-archive>` performs
the same locked validation without downloading again. `qualify` is an explicit
local execution operation on Windows, with isolated APPDATA/LOCALAPPDATA paths.
The no-client probe requires Steam not running; it does not close or launch it.
It does not create `steam_appid.txt`, invoke SteamCMD, authenticate, upload, register
an installer, sign a payload or write normal player saves/preferences.

The runner selects `res://platform/steam_native_probe.gd` from the verified PCK
with `--script`, passing only `--steam-native-probe` after the argument separator.
This probe accepts no other user flags and constructs no ordinary title or world. On a standard Godot build it correctly reports that the native module is
absent; that is a refusal, not a failed ordinary game launch.

## Evidence and native runtime ownership

`qualification.json` binds the source commit/tree, input package-manifest digest,
archive/member digests, original PCK digest, operation, execution and verifier IDs.
It contains separate observations for the native adapter preflight and the native
local-gameplay process. Nonempty native logs and completion markers must agree
with successful exit codes. Failures/interruption retain failure status and logs;
none is converted into a native-client pass.

The native preflight is shared with `steam_services.gd.initialize`; it owns no SDK
session and reads no user identity. The existing process-lifetime platform owner
still exclusively initializes, pumps callbacks and shuts down a requested live
Steam session. Source tests continue to label their injected clients separately.
World state, history/evidence receipts, input, save/recovery policies, platform
identities and NET's investigation role are not replaced or merged.

## Before a distributed Steam build

A native-module build is not made by placing an arbitrary DLL beside the ordinary
local package. The existing local package verifier deliberately still rejects
additional native files. A shipping native manifest, notices and any signing must
be verified as a **derived runtime profile**, not falsely claimed to match the old
standard-Godot executable hash.

GodotSteam's MIT terms and [Valve's Steamworks SDK terms](https://partner.steamgames.com/doc/sdk)
are separate. Downloading this public reference does not establish the publisher's
redistribution permission. Native runtime binaries remain local to qualification
until the applicable rights and final dependency profile are confirmed. The user
must supply the actual assigned App ID/client for a live test; no sample App ID is
substituted. Existing `--steam-app-id=<assigned-id>` behavior remains opt-in, with
no account fallback and no automatic import from shared saves.

The Windows native lane is in `.github/workflows/steam-native.yml`. Linux and
standard Windows still run the original qualification matrix. This adds no Xbox
port or Microsoft package claim and does not replace physical-controller or human
accessibility testing.
