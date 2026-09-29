# 1792 / Foundry integration and repository delivery

The game-owned adapter is `game/foundry/water_round.gd`. It exercises the existing
household water-round reducer, 180-tick clock, pending-draw save/load and duplicate
deposit refusal. The terminal checks returned observations independently; the
game does not declare its own acceptance.

## Source and repository location

Game runtime qualification is pinned to
`2bb8a16e63716d54de2d4e97daabc4671d3e07f4`. This documentation-only follow-up does
not alter that adapter, any game reducer, clock, save format, scene or licence.

The terminal repository is now
[Notations-Systems-Terminal](https://github.com/giasonpooni/Notations-Systems-Terminal),
GitHub repository ID 1377790873, formerly Notations-Engineering-Terminal.
The preserved runtime uses the original `net foundry` commands and its original
package/operation identities. A repository rename is not a runtime replacement.

[Terminal PR #68](https://github.com/giasonpooni/Notations-Systems-Terminal/pull/68)
contains the controller integration. This game branch is
[1792 PR #30](https://github.com/giasonpooni/1792/pull/30). Both are feature-branch
increments, not automatic merges into main.

## Complete handoff retained in Git

The terminal's
[Foundry delivery guide](https://github.com/giasonpooni/Notations-Systems-Terminal/blob/feat/game-foundry-1792-v1-20260929/docs/NET_FOUNDRY_DELIVERY.md)
links the complete 131-file handoff under `delivery/foundry-v1/retained/`:
installable terminal wheel, exact source snapshots for both repositories with
their own licences, applicable patches, setup instructions, all original native
campaign evidence and failed attempts, local and CI reports, and checksums.

The archival ZIP is a deterministic repack with all original enclosed file bytes
preserved. It is stored in repository history rather than only in this chat or
an expiring Actions artifact. The original source snapshots keep their historical
names and links; the delivery guide uses the current repository name.

## Run and scope

Use the terminal Foundry branch and this game branch, then follow
[the terminal command guide](https://github.com/giasonpooni/Notations-Systems-Terminal/blob/feat/game-foundry-1792-v1-20260929/docs/NET_FOUNDRY.md).
The recipe is `1792.water-round.v1`; `--game-root` points to this repository's
`game/` directory. Choose a trusted Godot executable and bind its verified
SHA256. Compiling or inspecting work orders does not launch the game.

This adapter uses explicit completed-inquiry and position fixtures. Qualification
establishes the domain/clock/save production contract, not input-driven walking,
visual quality, historical authentication or a complete playable build.
The disposable project is not an operating-system or network sandbox.
No autonomous model workers, production release, or ESM admission is implied.
Playing 1792 normally still requires only the game and its supported Godot engine.
