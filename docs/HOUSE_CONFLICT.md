# Houses, rivals and antagonist biographies

## Direction

1792 remains Ranjit Singh's campaign, with subordinate command stories. Raj Kaur,
Sada Kaur, Mehtab Kaur, Datar Kaur, Moran and Jind Kaur are **non-playable antagonist
characters**, not alternative protagonists. Antagonist is an authored narrative role;
relationship state is separate. A patron, relative or ally can oppose a particular
appointment or claim without becoming a permanently hostile combatant.

Default conflict drivers are house, clan, estate, succession, patronage, personal
obligation and command. A misl is not flattened into a surname, a patronage network
is not invented as a clan, and a religion is not an enemy team. Akali/Nihang authority
has a distinct religious-military institution record. It has no active encounter yet.
Religious motivation can be declared by a specific story or institution; the engine
neither forces it onto all actors nor forbids it outside one group. No character's
faith automatically creates hostility, and one house dispute does not turn all women,
all members of a clan or all co-religionists against the player.

## Play the first conflict

The main menu adds **Lahore · Houses and rivals**, a variant of the existing command
sandbox using its same movement, command authority, resource accounting and report
clock. All geometry and the estate petition are explicitly fictional development
content set in the existing 1801 fixture, not historical reconstruction of Lahore.

At the courtyard table press E, choose **Houses / antagonist biographies**, then
**Hear the envoy's estate petition**. Sada Kaur's envoy requests recognition of a
local revenue claim before a road patrol is organized. The envoy is represented by
an interface and static greybox figure, not an animated dialogue character.

- **Recognize the local claim:** Sada becomes an ally. A successful patrol gains
  passage and cooperation but recognizes the local claim; it does not annex land.
- **Assert Lahore's authority:** Sada becomes a rival. A successful patrol creates
  military presence but passage and revenue authority remain contested.
- **Observe without settling the claim:** the captain may scout and withdraw, but
  cannot organize a security patrol until Ranjit revises the commission.

A rival or deferred commission can be reconciled at the command table before the
patrol resolves. This demonstrates patron -> competing patron -> rival -> ally.
The delegated captain waits after reaching the outpost if authority is unresolved;
the player must settle the petition or take control and withdraw. No duplicate
orders, rewards, resource pools or simulation clocks are created.

The petition is optional: leaving it dormant preserves the original patrol's rules.
Cancellation refunds the original command budget but does not erase a promise made
to the envoy. Politics does not create additional coins or riders in this slice.
F5/F9 use `user://1792-house-conflict-v1.json`; the original sandbox save is untouched.

## Biographies

The six profiles are writer-authored game biographies with their own goals, leverage,
group links and source notes. They are NOT six implemented AI campaigns. Only Sada
has a responsive dispute in this slice. Mehtab and Datar are active roster entries;
Raj is an earlier-chapter entry; Moran and Jind are later-chapter entries. These are
fixture chapter gates, not a complete historical lifetime/calendar scheduler. The
full roster is intentionally an authoring/development codex and can reveal spoilers.
None is inserted into the two playable actor slots or made playable by browsing.

`game/data/antagonists.json` separates source status from campaign characterization.
The supplied Raj Kaur page is retained by reference as an account of the killing,
not ignored or claimed to be wholly invented. The crop says Laik Missar **fled**;
no new biography should repeat the earlier assistant's erroneous assertion that the
crop says he was killed. Author, title, edition and page remain unidentified here.
The campaign can choose that narrative account without claiming every reported
private intention is independently established history. No death scene is built.

The previously proposed Tahal Singh Chhachhi protagonist is not silently installed
into the patrol-captain identity. His dates, appointments and family succession need
a separate biography/source decision. The current captain remains fictional.

## Code and persistence

`house_command_state.gd` extends `command_state.gd`, storing its additive
`house_conflict` object in the SAME authoritative `_state`. There is no second world,
new service, Bevy process or NET requirement. `house_sandbox.gd` extends the existing
scene script and presents commands; it cannot directly grant success or resources.
The original command-state implementation and tests remain unchanged.

The house substate has `house-conflict.v1` and `antagonist-roster.v1` identities. Its
small ordered decision history is replayed during validation to check relationships,
territory and report content. Validation also binds the outcome to the real command,
executor and observation tick. This is bounded consistency checking, not a signed
proof or an event-replay engine for the entire game. All numerical scores are authored
gameplay values, not measurements of historical persons or validated social models.

Historical source reference, authorial role, NPC ID, group ID, command ID and report
ID remain distinct. Concessions are made by Ranjit; command execution belongs to the
captain; the report is evidence of the completed order. A military-presence change
never silently changes `annexed` to true.

House reports become visible only when the original patrol report arrives. Actual
territory state and received information remain separate. Menu reading pauses the
same simulation as the existing decision interface.

A valid legacy command save can be loaded by the extended model; a dormant extension
is added after complete validation. Invalid new saves leave live state unchanged.
The base-only prototype is not advertised as a forward-compatible reader of extended
saves; use the new variant for house-conflict saves. Saved derived values must agree
with valid history, including after JSON numeric normalization.

## Scope and verification

Added engine regressions cover the existing loop, NPC-only roster, explicit chapter
presence, competing claims, manual/delegated equivalence, waiting and reconciliation,
non-annexation, delayed reports, legacy import and corrupt-load refusal. Render tests
capture the actual codex, decision interface and reported consequences.

Actual pass counts and CI run identities are recorded in the PR after execution.
No horse, combat, autonomous six-character plotting, full clan registry, empire map
or historical-source certification is claimed by this slice.

## Companion-patrol extension

The integrated scene can now muster a physical patrol and return it to court; see
[Companions](COMPANIONS.md). The original un-mustered command scenario remains unchanged.
