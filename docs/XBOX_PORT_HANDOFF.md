# Xbox port and signing handoff — restricted work stays private

The ordinary Windows Godot executable is not an Xbox console binary. The existing
`xbox_series` packaging target remains blocked. This document specifies the next
private implementation boundary; it does not claim that an engine port exists.

## Inputs that must be provided, not guessed

The publisher needs the applicable platform approval/agreements, authorized console
SDK and devkit access, and a qualified Godot console export provider/build. Godot's
[official console support overview](https://godotengine.org/consoles/) describes
why public Godot binaries do not include restricted console templates. W4/other
providers are possible routes to evaluate, not dependencies already purchased or
qualified for 1792.

Keep console SDKs, export templates, credentials, product configuration, restricted
requirements and detailed console test evidence in an authorized private workspace.
Public source/CI must not acquire these materials implicitly from build logs or
export snapshots. Do not put signing keys, private certificates or account tokens
in this repository or in chat attachments.

## Port this interface, not a second game

Godot remains the active application and writer of world/clock state. The public
`cg.platform-services.v1` boundary and existing save validators remain the integration
point. Console user identity is not `ranjit_singh` and must never be serialized as
character knowledge. C++/Rust can provide qualified native/platform work; Python/NET
and Julia retain their external tooling/reference roles, not mandatory console
processes. No separate Bevy world, historical ledger or parallel treasury is needed.

The private adapter must resolve a permitted active platform user, select their
storage explicitly, bridge platform lifecycle events to the existing interruption
semantics, and reject unsupported operations. Read/write, quota, cancellation,
account switch and cloud conflict results must not partly replace live game state.
Do not advertise unsupported services as successful local fallbacks. The local
transport's flat paths and synchronous behavior are not assumed to match console
storage APIs; an asynchronous operation/receipt seam must be qualified without
changing the authoritative state rules.

Legacy checkpoint storage is a separate domain and needs its own user-scoped port.
The two-file manual recovery policy is not power-loss atomicity or Quick Resume.
Suspend/resume, input assignment, profiles, platform UI and inaccessible/corrupt
storage must receive real platform-specific tests; this public document is not a
substitute for the current restricted requirement set.

## First private qualification slice

Import an immutable, hash-identified 1792 source snapshot, with an explicit declared
engine/SDK/template revision. Build and boot a real devkit package. Exercise title →
home → walking/riding → situated hearing → menu pause → manual save → process restart
→ Continue with the same admitted gameplay operations. Test the authored one-eye
presentation and 200% reading controls without changing character knowledge.

Retain source identity, native dependency digests, operation/execution IDs, actual
hardware class, logs, input method, store/user-storage context and refusal results.
Separate engine/runtime results, operator observations and platform certification
receipts. Passing Linux/Windows contracts provides regression evidence, not any of
those console results. Approval/certification references remain absent until they
actually exist.

## Windows signing is a separate release operation

This public pipeline continues to produce unsigned development packages. A future
private release job must use the publisher's trusted signing service/certificate,
perform Authenticode verification, then regenerate hashes for the **signed** payload
and bind them to its own execution record. Timestamping and chain validation must
be part of that qualification. Do not sign with a fabricated self-signed certificate
and label it a trusted production release. Never reuse the unsigned ZIP's digest
as proof of the signed artifact.

No enrollment, provider contract, signing identity, installed SDK, devkit, console
executable or certification was created by writing this handoff.
