# Licensing policy

Copyright (c) 2026 Notation Systems Inc. All rights reserved.

Existing Cartesian Graphics/creator credits and third-party notices remain preserved.

**1792 is proprietary by default.** The [root notice](../LICENSE) applies to original material owned or validly controlled by Notation Systems Inc. unless an explicit separate licence applies. This policy documents the licensing boundary; it does not itself grant additional rights.

## Owner-declared company group

On 3 October 2026, the owner identified **Notation Systems Inc.** as the parent
company, with **Notations Gaming**, **Notation Manufacturing** and
**Notations Laboratories** as child companies. Notations Gaming is the current
game development company. Notation Systems Inc. remains the declared owner of
covered original material. These names do not themselves transfer ownership
or establish authority to license material or sign for another entity.
Each signed grant must identify its legal licensor and authorized signatory
and their capacity. The [ownership record](licensing/OWNERSHIP_AND_SCOPE.md)
records this declaration without independently certifying entity status.

## Scope and precedence

| Material | Treatment |
| --- | --- |
| Original game code, scripts, scenes, campaign implementation, dialogue, and authored world content | Proprietary under the root notice. |
| Original models, textures, animation, audio, illustrations, maps, and promotional artwork | Proprietary; see [asset licensing](ASSET_LICENSING.md). |
| Original documentation, schemas, and utilities | Proprietary unless deliberately released under explicit component-specific terms. A generic-looking filename is not an open-source grant. |
| Separately licensed or third-party material | Its applicable licence and notices remain controlling for that material. |
| Historical facts, ideas, mathematical methods, and public-domain material | Not claimed as Cartesian Graphics copyright by these notices. |

A root notice cannot override upstream rights or license material that Notation Systems Inc. does not own or control. Preserve existing notices and keep third-party attribution separate from project ownership. A technical integration with NET, Godot, Bevy, or Blender does not relicense another repository or transfer ownership to Notation Systems Inc..

## Deliberately reusable technology

The intended choices for **future explicitly designated releases** are:

- **MPL-2.0** for reusable simulation libraries, validators, replay tooling, and procedural systems when file-level reciprocity is desired.
- **Apache-2.0** for small reference implementations, interchange examples, or integration utilities intended for broad reuse.

**No project component is designated MPL-2.0 or Apache-2.0 by this change.** Neither licence applies repository-wide. Do not infer an `MPL-2.0 OR Apache-2.0` dual licence from this policy. Standard licence texts should be added with the first approved component release, not as an ambiguous alternative root licence.

For each separately released component, record its exact paths and release revision, confirm ownership and contributor permissions, review dependencies, and attach the unmodified licence text and accurate per-file notices. For an MPL component, retain its covered-source obligations when distributing it; separate proprietary files must not be used to hide covered modifications. Keep 1792's campaign content and creative assets outside that release unless explicitly authorized.

Official references: [Mozilla's MPL FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/) and [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Public repository and permissions

Repository visibility is separate from licensing. This change does not make the repository private, restrict access controls, or remove existing forks. The root notice preserves permissions arising under applicable law, existing licences, and GitHub's terms. See [GitHub's licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

No general modding, fan-asset redistribution, commercial reuse, or source-available experimentation licence is granted here. Specific permissions can be agreed separately with Notation Systems Inc. through the Notations Gaming child company; the signed grant must identify the legal licensor and authorized signatory and their capacity. A future player EULA or modding policy must identify what it permits and preserve applicable third-party and statutory rights.

## Contributions and provenance

Use the [contribution policy](../CONTRIBUTING.md) before accepting external code or assets. A copyright notice, commit identity, credit, or merged pull request is not a substitute for a required ownership assignment or licence agreement. Record the rights holder, origin, applicable licence or permission, and any attribution or distribution conditions for each imported component or asset. An unknown or unresolved rights status blocks its release.

## Release checks

Before distributing a playable build, verify the actual build rather than relying only on this repository notice:

1. Resolve ownership and permissions for included code and assets, including contractor and contributor work.
2. Include the applicable project/player terms, third-party licence texts, required attribution, and any required source-access information with the build. Files outside `game/` are not assumed to be included by Godot exports.
3. Record the exact engine, export-template, plug-in, library, font, and asset versions. Reconcile their obligations against [third-party notices](../THIRD_PARTY_NOTICES.md).
4. Recheck separately licensed components and retain rights granted in earlier releases; a new root notice does not revoke those grants.

This documentation change is not a release-compliance certification, an ownership-chain audit, or a substitute for legal review of commercial distribution agreements.

## Declared ownership and outreach

The owner identified Notation Systems Inc. as legal asset owner on 2 October 2026,
and stated assets are original with a reference-only corpus. The
[scope record](licensing/OWNERSHIP_AND_SCOPE.md) distinguishes that declaration
from independent title verification. This change creates no assignment or
worldwide legal certification and retains creator/third-party credits.

Before any act requiring authorization, [request permission](https://github.com/atomtrapping/1792-The-Lotus-Throne/issues/new?template=licensing-request.yml&title=Licensing%20request)
and obtain an express signed written grant. A request is not authorization.
The root AI/mining reservation preserves mandatory exceptions and prior/platform
permissions. Corpus sources, CC0 surfaces and MIT-covered code retain their rights.
