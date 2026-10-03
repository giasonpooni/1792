# Shared Notations Gaming game architecture

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

**Decision:** CG-GAME-ARCH-001, revision 1, 2026-09-28.
**Scope:** all Notations Gaming games under Notation Systems Inc., including 1792 and Hero of the Two Worlds.
**Status:** adopted development baseline; this document does not implement or certify an integration.

Every title will use the **C++ - Rust - Python - Julia** architecture. This extends the existing Godot/Bevy/Blender and NET/`ciw`/SCR boundaries rather than replacing them. All four languages have defined roles in the development and simulation system; they are not a mandatory four-stage call chain for every frame.

## Language and system responsibilities

| Layer | Assigned responsibility | Boundary |
| --- | --- | --- |
| C++ | Profile-justified numerical kernels, native engine integration, geometry, physics and other performance-critical providers. | Bounded computation, not a second campaign state or experiment controller. |
| Rust | Runtime services, declared world-state reducers, ECS/Bevy simulation where justified; SCR's existing execution supervision for registered scientific work. | Game runtime and SCR are separate components even when both use Rust. Do not copy SCR into a game-local execution backend. |
| Python | NET/`ciw` investigations, orchestration, data/asset tooling, automation, parameter sweeps, observation, analysis and regression campaigns. | Keep the existing session, record and provider contracts. Development agents submit supported commands; they do not silently rewrite live state. |
| Julia | Reference mathematics, numerical simulation, optimization, calibration, sensitivity and model qualification; explicitly selected runtime providers when needed. | A reference result is not automatically physical truth, historical evidence or a proof. A deployed Julia runtime must be declared and packaged. |
| Godot | Playable application, input, camera, scenes, UI and the gameplay state it owns. | Retain working GDScript and existing gameplay; do not rewrite everything merely to use four languages. |
| Blender | Asset, geometry and animation authoring. | Exported content does not become a second live simulation authority. |

[NET](https://github.com/atomtrapping/Notations-Systems-Terminal) remains the programmable workbench. [SCR](https://github.com/atomtrapping/Notations-Compute-Runtime) remains the shared execution foundation for its registered operations. Specialist repositories retain their mathematics, implementations and licences. These component names do not mean an adapter is already implemented in a particular title.

## One state owner, not four simulations

Each simulation instance declares its state owner, clock, tick/input ordering and persistence boundary. Partitioned systems may have different owners for different state domains, but not concurrent writers for the same authoritative state. For example, Godot can own local character motion while a registered Rust provider owns campaign evolution, with explicit commands and observations connecting them.

When a provider owns a trajectory, Godot presents it rather than integrating a competing authoritative trajectory. When Godot owns it, a native kernel returns a bounded result that Godot applies once. NET owns investigation history, not a competing copy of the live game world. Existing NET-owned scientific instances keep their declared ownership; the game-specific rule does not transfer those instances to Godot.

State-changing commands must be checked against the declared instance, owner, expected revision, sequence and tick. Reject stale/duplicate commands and invalid results. Provider failure must not commit a partial transition; any degraded mode or fallback needs explicit policy and a recorded event. Headless and interactive paths use the same authoritative transition implementation. Changing presentation must not change the model identity.

## Integration without a parallel substrate

```text
Blender -> authored assets -> Godot application
                                  |
                       commands / observations
                                  |
                     declared state-owning runtime
                     Godot or scoped Rust/Bevy
                                  |
                        qualified C++ kernels

Python / NET / existing ciw session
  -> supported adapters and declared SCR operations
  -> Julia references / native qualification / parameter sweeps
  <- retained observations, results, comparisons and checks
```

These are responsibility boundaries, not a requirement to embed all components in one process. Native gameplay calls do not automatically require an SCR round trip on every frame. Scientific operations registered with SCR continue through SCR; do not bypass its execution gates or invent another registry/session/evidence store.

Reuse the existing provider contracts and native ABI where supported. Add an adapter for a missing boundary before proposing new infrastructure. For native interfaces, specify ABI version, target platform, fixed-width types, units/frames, buffer sizes, ownership/lifetimes, thread rules, error status and resource limits. Do not pass language-private object layouts across the boundary. Contain C++ exceptions and Rust panics at the agreed non-unwinding interface; an in-process native fault is not isolated simply because a wrapper exists. Batch operations where latency measurements justify it.

Godot's [GDExtension](https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/index.html) provides the native shared-library integration route. The [Rust FFI guide](https://doc.rust-lang.org/nomicon/ffi.html) documents ABI, ownership and unwinding concerns. These are integration mechanisms, not evidence that this repository already contains a working binding.

## Julia reference and production implementation

Develop and qualify a model in Julia, then select its production path explicitly: a Julia provider with declared runtime dependencies, or a bounded generated/native implementation with retained model lineage. Generated C is an interoperability artifact inside this four-language architecture, not a new state owner or a claim that arbitrary Julia packages can be translated to runtime-free code.

Julia's [embedding API](https://docs.julialang.org/en/v1/manual/embedding/) uses the Julia runtime. A C-callable wrapper alone does not remove that dependency. A claimed runtime-free export must be demonstrated for its supported model subset and packaged artifact.

Keep the reference model, export/compiler version, native artifact digest, parameters, units, solver/timestep and numerical tolerances linked. Generated and reference implementations share lineage, not necessarily independent correctness. Check analytic cases or independent benchmarks as well as cross-language agreement. Do not maintain four untracked copies of the same equations.

## Development and shipping profiles

The **development profile** spans all four roles: Python/NET orchestration, Julia modelling and reference runs, Rust runtime work and C++ native providers. Activate only the providers required by the declared workload; a missing required provider yields an explicit failure, not a silent substitution.

The **shipping profile** includes the game and its qualified runtime components. Python and Julia may produce validated artifacts offline, or may ship as explicitly selected services/providers when gameplay needs them. They need not both be installed on every player's machine solely because they belong to the architecture. Pin the actual engine, compiler, library and provider versions for each build. Declare process boundaries, startup costs, memory budgets and latency limits; never hide runtime downloads or initialization in an ordinary gameplay command.

## Evidence, replay and verification

Reuse the existing records to distinguish model, implementation, runtime, operation, execution, result/artifact and verification identities. Simulation output, observation, estimate, historical source and verified claim remain different categories. A digest identifies bytes; it is not by itself a correctness proof.

Retain initial state/checkpoint, ordered inputs, seeds and RNG algorithm, timestep/solver configuration, relevant thread/scheduling policy, dependency versions and build identity. A fixed seed alone does not establish cross-platform determinism. Declare whether a check expects exact state equality, bounded numerical error or a statistical criterion and test that claim on the supported targets.

Distinguish reading a saved result, replaying observations, re-executing a run and continuing from a checkpoint. Fresh execution gets a fresh execution identity while retaining model and scenario lineage. Numerical agreement, gameplay acceptance, historical support and physical validation are separate checks. Registered proof/checker providers verify only their stated computation, not the entire game.

## Sharing and ownership

Keep title-specific campaigns, narrative, characters, assets and gameplay rules in their title repositories. Share qualified technical implementations through versioned dependencies or supported adapters from their owning repositories, not by forking the orchestration or copying untracked kernels into each game.

This document is mirrored with the same decision/revision across adopting game repositories; it is not a new runtime, package or repository. Future titles adopt the same baseline. Shared implementation does not mean shared fictional state or a single combined game world.

The [root notice](../LICENSE) and [licensing policy](LICENSING.md) remain controlling for their stated scope. No architecture choice relicenses NET, SCR, an engine, a dependency or another person's contribution. A language role does not automatically designate code MPL-2.0 or Apache-2.0. Release selected reusable components only through the existing explicit rights and licence review.

## First qualification increment

Use the existing NET native/interactive prototypes as references, not as automatically merged game capabilities. Select one small game-relevant operation with an independent reference, expose its qualified native implementation through the existing boundary, and consume it from both the headless and interactive path without changing state ownership. Python/NET retains the run and comparison; Julia supplies the reference; Rust and C++ have explicit runtime/kernel responsibilities rather than ceremonial duplicate implementations.

Before claiming an integration works, run valid/invalid-input tests, reference comparisons, repeated-run and checkpoint tests, owner/revision rejection tests, failure-without-state-advance tests, and frame/step budget measurements. Preserve existing game and workbench regressions. Build, run, observe, fix, audit and continue; a document, empty language folder or build recipe is not passing execution evidence.
