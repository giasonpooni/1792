# The Account Beyond the Curtain

## Implemented scope

`audience` is an optional tale in the existing family-tale catalogue and session
allowlist. It uses `punjab_chiefs_playable.gd`, the native player motor, local
choice history and existing retained-Home lifecycle. It adds seven ordered beats
and fourteen original choices. The earlier `regency` tale remains a separate
sequence with its existing choices and checkpoint identity.

The player is a fictional adult household clerk in the project's early-regency
1792 frame. Mai Raj Kaur is Ranjit Singh's mother, distinct from his wife Raj Kaur
Nakai and the paternal aunt named Raj Kaur. The clerk requests and carries her
limited decisions rather than acquiring authority to rule in her place.

The scene separates permission to speak, access to accounts and entry into a
private room. A screened conversation and an inspectable working desk coexist.
Completion changes only this telling; it grants no Home grain, cash, guard,
horse, allegiance or campaign knowledge. Validation results remain to be added
after the native checks and renders run.

## Evidence and original reconstruction

| Material | Evidence boundary |
| --- | --- |
| Raj Kaur's identity and early-regency context | Existing `centenary_1939` and `buxi_1992` source records; Memorial printed 99–100 / PDF 127–128 and Buxi printed 6–7 / PDF 20–21. The Memorial's 1790 succession remains distinct from the project's 1792 frame. |
| This hearing, screen, court, staff, requests and local outcomes | **D — fictional connective material.** The sources do not authenticate this event or establish Raj Kaur's universal audience protocol. |
| Every line attributed to Raj Kaur or her attendants | **D — original dramatic dialogue**, never a historical quotation or translation. |
| Four grain bundles, two-bundle issue and one possible escort | **C/D — authored finite quantities**, not estate revenue, historical troop strength or an archival financial account. |
| Screened pavilion and compressed Gujranwala working court | Authored geometry; neither a surveyed building nor a rule for every Punjabi household. |

The catalogue labels the source kind
`early_regency_context_with_original_household_audience` and states these limits
in its adaptation and opening. Historical allegations in `rumours` are not
premises for this scene. No Sikh urdubegi corps, immunity from legal authority,
secret treasury or historical military consequence is asserted.

## Route and choices

| Beat / station | Admitted decision |
| --- | --- |
| `audience_permission` / `attendant` | Request a direct screened hearing (`audience_direct`) or a brief report from the public threshold (`audience_threshold`). Both permit direct speech from the public mark. |
| `audience_hearing` / `raj_screen` | Ask for witnessed totals (`audience_totals`) or protect dependants' names while opening totals (`audience_privacy`). Both set `totals_open`; neither permits residence entry. |
| `audience_count` / `dispatch_table` | Count four grain bundles (`audience_grain_count`) or check the remount note against that same stock (`audience_remount_note`). Both set `stock_counted`. |
| `audience_dispatch` / `raj_screen` | Request two bundles for the detail (`audience_issue`) or retain all grain and request a remount inspection (`audience_inspect`). The alternatives set `grain_issued` and `remount_requested` oppositely. |
| `audience_recipient` / `warband_runner` | Read the order together (`audience_read_back`) or obtain a named sealed receipt (`audience_sealed`). Both set `dispatch_received` and `escort_following`. |
| `audience_departure` / `departure_gate`, escort mode | Request one household escort (`audience_escort`) or keep its post filled (`audience_home_post`). Real runner arrival is required; both set `departure_witnessed`. |
| `audience_record` / `dispatch_table` | Record order and local arrival (`audience_register`) or file the recipient's receipt (`audience_receipt_copy`). Both set `receipt_recorded`; their copy flags remain distinct. |

Raj Kaur's central original line is: “The room may be private. The account must
answer to someone. Which part of your request needs a witness?” The runner's
reply makes the material limit explicit: “I will not tell the riders a horse is
coming if the paper promises only a look at one.” These are authored dialogue,
not sourced sayings.

Actual station positions are `attendant: [-9, 0, 8]`,
`raj_screen: [0, 0, -6]`, `dispatch_table: [-9, 0, -1]`,
`warband_runner: [9, 0, 2]` and `departure_gate: [10, 0, -14]`.
The player's route returns to the hearing after counting, then crosses the court
to acknowledge the runner and accompanies his native body to the gate.

## Screen access and local transport

`regency_access.gd` adds an opaque collision screen and a closed pavilion. It
renders no concealed queen avatar or bedroom objective. Conversation text names
Raj Kaur behind the screen. There is no recorded voice or new audio system.

The public hearing mark is at `[0, 0, -6]`; the interior voice target is
`[0, 1.4, -9.5]`. `interaction_error()` requires either `audience_granted` or
`public_report`, a public-side position and a ray whose first obstruction is the
specific screen. A second ray exempts that screen while checking for other
obstructions. This does not disable general proximity, facing or sight checks.
The audience camera stays on the public side. The ordinary motor collides with
the walls, and `pose_allowed()` rejects checkpoint positions inside the private
pavilion independently of ordinary contact.

Four visible sacks begin at the account desk. When `dispatch_received` is true,
the grain branch parents exactly two sacks to the actual runner body; the other
two remain at the desk. The remount branch leaves all four sacks there. The
written dispatch becomes visible on the runner after acknowledgement. These
props are derived from existing choice flags, including after checkpoint recall.
They are not a second inventory or a separate simulation clock.

## Derived account and outcome limits

`audience_status()` returns `audience_granted`, `public_report`, `totals_open`
and permanently false `residence_entry`. `logistics_outcome()` derives
`counted_bundles`, `issued_bundles`, `retained_bundles`, `remount_requested`,
`escort_requested`, `dispatch_received`, `departure_witnessed` and `delivered`.
The helper owns presentation and admission checks; the story model owns every
decision. It stores no independent permission, supply or delivery counters.

After counting, the two material alternatives are **two issued / two retained**
or **zero issued / four retained, with an inspection requested**. On receipt,
issued sacks physically accompany the runner to the courtyard gate. This supports
witnessed local transport. `delivered` remains false: no distant road detail has
been reached. No inspected, purchased or supplied horse exists in this telling.

An escort is a request only. There is no additional guard body, acceptance,
provisioning or onward movement. Keeping the home post changes the local account;
it does not manipulate the retained Home's guards. Four specific endings combine
the grain/remount and escort/home-post choices, followed by a fallback. Both final
receipt choices complete the record; neither creates a repeatable reward.

## Executed qualification

Godot 4.5.1 qualification on 2 October 2026 completed cleanly:

| Check | Result | Scope |
| --- | --- | --- |
| Full `tools/run_checks.py` | Exit 0; no engine errors | Structural checks and the entire inherited native campaign |
| Family-tale state | 607 passed / 0 failed | Fourteen finite histories and exact replay |
| Retained Home lifecycle | 50 passed / 0 failed | Bench entry, cancellation, teardown and completed audience return with unchanged Home and save bytes |
| Native family-tale journeys | 490 passed / 0 failed | All fourteen routes through original movement motors |
| Existing checkpoints | 124 passed / 0 failed | Prior visit and legacy checkpoint regression |
| Regency access | 462 passed / 0 failed | Two native audience routes, four policy replay combinations, screen collision and selective acoustic admission, stock transport, rollback and atomic rejection |
| Software-rendered capture | 3 captures / 0 failures | Public hearing, account desk and runner carrying two sacks at the gate; visually inspected at 1280×720 |

The completed-return fixture tests the session transaction by replaying choices;
it does not count as a native gameplay journey. The two fully walked audience
routes are separate evidence. The original thirteen catalogue entries were also
compared directly with the parent revision and remain exactly equal.

`render_regency_access.gd` emits three PNGs and a manifest containing accepted
progress, bodies, camera, access, supplies and each sack's parent/location. The
existing historical-world workflow runs this render and retains it beside the
exact source identity. Local software rendering used Mesa llvmpipe through Xvfb;
the images demonstrate the current procedural blockout, not finished art or
human playtesting. Voice, audio production, onward guard deployment and remote
supply delivery remain outside this slice.
