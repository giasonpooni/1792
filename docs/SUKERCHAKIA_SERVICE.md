# Gujranwala and the Sukerchakia Misl: a household-service slice

This increment extends the current integrated `main` home entry. It adds a small
playable service obligation and its research context, not a completed simulation
of the entire Sukerchakia Misl. The existing Gujranwala reconstruction, narrator,
childhood, household supply, water round, riding and political/perception code remain intact.
The separate missing-remounts draft is neither merged nor replaced here.

## Play the detail

Open `game/project.godot` with Godot **4.5.1 Standard**, F5, and select the existing
**1792 / Buddh Singh / Home territory** entry. Finish the original inquiry and
accept the quartermaster's household allowance.

1. Speak again to hear the Sukerchakia household-service brief. Hire a guard using
   the existing quartermaster menu; complete a supplied, paid watch to provision him.
2. Visit the western market and hear the handler's request, or speak to the water
   carrier on the eastern well approach. Return to the quartermaster.
3. Commit **one of the guards you actually hired**. His home post becomes empty;
   the same reserved slot travels through the existing collision navigator.
4. He attends the requested place, returns, and waits at home. Speak to the
   quartermaster to hear his account. Only then does the report enter the journal.
5. The same guard can attend the other request. Each request and account is finite;
   there is no repeatable money reward or unlimited recruitment.

The local water carrier and dispatch corner are original greybox additions.
They do not reproduce a documented person, building or event. Site distances,
2.4 m/s pace and 120-tick minimum stop are authored gameplay values. The latter
checks elapsed time and provision at arrival/departure, not measured continuous
labour or historical duty duration. No new traversable regional map is claimed.

**Controls:** E interacts; B shows the original accounts plus committed/home guard
counts; J shows oral records and explicit prior-save import; F2 opens the extended
research notebook; F5/F9 save/load. All use the existing controller and modal pause.

The new default slot is `1792-sukerchakia-service-v1.json`. J can explicitly import
an existing `1792-gujranwala-v1.json` save. This replaces the whole run; it does not
merge later earnings or knowledge. Original slots remain untouched. Existing
checkpoints and older saves discard subsequent optional service state.

## No duplicate forces, clock or treasury

A dispatch reserves the highest currently hired/provisioned guard slot. During the
detail, that original stationary post is hidden and the moving representation is
shown instead. This prototype has no guard dismissal/re-hiring identity history;
slot identities are local to the current retained household scenario.

The guard remains in the **existing** food and wage calculations while away.
No extra force, duty-payment account, garrison strength or revenue entitlement is
created. Releasing a committed slot is refused until the returned account is heard.
Additional hires still use the prior rule and maximum of three. One detail at a time.

Food shortage or unpaid wages holds duty movement. Existing production may postpone
food shortage until stored grain is exhausted. Restock or pay through the existing
market/quartermaster and settle a provisioned watch to restore readiness. Resting
an entire watch is refused while a ready detail is moving/attending; it is allowed
while held, without advancing the guard's position. There is no magical recall.

Hearing a request, dispatching a guard, reaching the site, returning and receiving
an account are separate events. A remote arrival/return does not give Buddh the
content of an unheard report. A report of a local visit is not a finding that a
whole road is safe, nor a grant of land or tax rights. The HUD shows the commitment,
not an omniscient live mission-progress meter.

## Research and modelling distinctions

The source/claim/type records are in `game/data/sukerchakia_service.v1.json`.
They distinguish **person, household, Misl, place and service detail**. Relations
carry a source-context or authored-model label. This is a development model, not
a claim that historical actors used these software categories.

| Reference | Supported context | Boundary retained |
| --- | --- | --- |
| [District history](https://gujranwala.punjab.gov.pk/mughal_empire) | Associates Gujranwala with the headquarters of Charat, Maha and Ranjit Singh before Lahore. | Retrospective and evaluative account with conflicting dates. It gives both 1773 and 1778 for Charat's death, and 1791 for Maha's death. No chronology, caste-based allegiance, motive or fixed-history game rule is rewritten from it. |
| [Pattidari entry](https://www.thesikhencyclopedia.com/pattidari/) | Describes co-sharing and early Sikh-period allotments; cites Prinsep (1834) and Indu Banga. | Only the opening entry informs the concept. Later appended material about colonial southeast Punjab is not transplanted to 1792 Gujranwala. The cited books were not directly consulted for this slice. |
| [District administration account](https://gujranwala.punjab.gov.pk/administration_under_ranjit_singh) | Distinguishes direct management, contracted dues, jagirs and service, with overlapping officeholding. | Describes later consolidated rule. No percentages, assessment rates or administrative appointments are adopted as a 1792 schedule. |
| [District geography](https://gujranwala.punjab.gov.pk/geography) | Supplies present regional orientation relative to the Chenab and neighbouring areas. | No modern administrative boundary is used as an eighteenth-century Misl border or a historical property claim. |

These sources motivate separating service, tenure and affiliation. They do **not**
document the two playable errands, this guard's identity, the local agreement or
its numerical rules. Those are explicitly original fiction. The research notebook
is outside character knowledge and cannot grant a request, title, troop or memory.
The existing Shah Muhammad presentation remains separate and unchanged.

## Implementation and checks

`service_state.gd` extends the original supply state with one optional `service`
substate. `service_chapter.gd` extends the existing researched chapter. Only the
home launcher's selected subclass changes; there is still one live authority and
one native `childhood.tick`. No NET, Rust, C++ or Julia runtime is copied into Godot.

Each service event binds an exact prefix of the original supply receipts. Save
validation replays those receipts and refuses future/omitted supply history,
missing or released reserved slots, forged outcomes and invalid agent identities.
Transitions operate on staged copies; rejected actions and loads leave live state
unchanged. Motion caps and standing-room checks are additional checks, not proof
that an arbitrary saved trace actually occurred or authenticated anti-cheat.

The original supply/childhood schemas are unchanged. The new state has at most
32 receipts, two request sites and one moving detail. It does not implement a
regional army, taxation, estate titles, general alliances, mounted escort combat,
raids, a full service labour model or independent cross-language verification.

```sh
python tools/run_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_sukerchakia_service.gd
/path/to/godot --path game --rendering-method gl_compatibility --script res://tests/render_sukerchakia_service.gd
```

Domain fixtures test refusals, supply coupling and a pending water draw saved
alongside a committed guard. Water transfers leave service custody unchanged. The playable journey begins
from a labelled completed-inquiry fixture, then uses real input/button signals,
collision navigation and actual guard travel for both requests, including a
mid-route save/load. It does not claim to replay the entire childhood tutorial;
the inherited suites retain their own full journeys.

Rendered views use labelled camera/scenario fixtures. They are not human
playtesting or physical-GPU performance qualification. The native test exports
`user://sukerchakia-service-trace.json` for developer inspection: synthetic test
state and original service/supply receipts, not player knowledge or historical
verification. Exact observed counts and code revision belong in the PR audit.
