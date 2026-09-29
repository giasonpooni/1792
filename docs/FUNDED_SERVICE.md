# Funded service: a playable household commission

## Implemented scope

This increment builds agent-mediated hiring, real escort and arrival, budget commitment,
recurring specialist wages, a funded practice session, and a limited instructor viewpoint
inside the existing **1792 · Buddh Singh · Home territory** chapter.

The current recruit is an original fictional local instructor. His agent, prices, receiving
patch and job are authored gameplay, not a recovered childhood incident. The western
receiving patch remains inside the compressed home cell. It is not Eminabad, a surveyed
haveli, an accurately scaled regional road or a religious site.

The earlier traversal-contact build is retained in this source baseline. Its movement course
and in-climb persistence remain separate from campaign eligibility. Campaign climbing is
still disabled; this commission does not migrate campaign airborne saves or navigation.
Parallel atlas, platform, workshop, oral-memory and unpublished anthology work is not
silently merged or advertised as jointly qualified.

## Play

Open `game/project.godot` in **Godot 4.5.1 Standard** and choose Home territory.
Finish the household inquiry and accept the limited allowance at the quartermaster.

A workable route is:

1. Accept the existing four-food delivery, carry it to the market and deliver it. Its original
   payout increases household coffers by 26; the personal payout remains in the separate purse.
2. Return home and reserve the standard instructor commission. The 156-coin senior option
   is deliberately unaffordable from the initial 120-coin household allowance. No debt or
   resources are silently created to fill a shortfall.
3. Walk to the market, face the agent, and present the commission. An introduction is not
   employment: the paid agent fee does not spawn a trained army or finish an appointment.
4. Walk just north to the receiving patch, speak to the candidate and accept his terms.
5. Walk home slowly, maintaining visual contact. The candidate uses the existing collision
   navigator and shared character motor. Stop when separated; he does not teleport home.
6. Return together to the quartermaster and sign. The signing payment leaves the remaining
   reserve earmarked for wages. Hire one garrison guard and provision a watch for a pupil.
7. At home, take the instructor's viewpoint. Move the instructor, not Buddh, and speak to the
   quartermaster to begin the one bounded funded drill. It needs two food and one tool unit.
8. Stay together for 180 eligible active ticks. Pausing, lost contact or unpaid/unprovisioned
   service does not earn progress. Return viewpoint through the quartermaster conversation.

WASD/left-stick inputs move through the shared motor; mouse looks; E interacts; B shows
accounts as Buddh; J opens the active actor's journal. F5/F9 save/load this whole run.
F8, only in Buddh's view, opens the paused **authoring** slate of future officer chapters.
Full physical-controller and accessibility qualification is still outstanding.

## Money is an obligation, not an upgrade token

All quantities below are **authored integer game coins**, not historical rupees or wages.

| Offer | Total reserved | Agent | Travel | Signing | Initial wage reserve | Wage per watch |
|---|---:|---:|---:|---:|---:|---:|
| Standard | 108 | 8 | 12 | 64 | 24 | 12 |
| Senior | 156 | 12 | 16 | 88 | 40 | 20 |

Reservation debits the existing household treasury and earmarks those same coins. Reserved
money is unavailable to unrelated purchases. Agent, travel and signing payments occur in
separate situated transitions. Cancellation before travel returns only the unspent part;
paid agent work stays paid. Repeating a refund or payment is refused.

After appointment, the existing watch settles ordinary household wages, food and production
first, then specialist upkeep. Specialist wages consume the dedicated reserve before ordinary
coffers. Inadequate funds accrue actual arrears; they are not taken from Buddh's private purse.
The budget exposes available cash, reserved cash, wage debt and next-watch needs separately.
Future production, promises and undelivered income are not spendable cash.

The player may explicitly release the unspent reserve, pay accrued specialist wages or dismiss
the present instructor. Dismissal does **not** erase earned unpaid wages. This is one finite
commission per prototype run, not an infinitely repeatable recruitment/refund loop.

No new automatic taxes, loans, territorial income, import market, inflation, population model
or Victoria 3 simulation is claimed. The older finite delivery and caravan proceeds remain
ways to earn actual cash. Existing production and ordinary wages continue on the same clock.

## Drill scope

The session proves resource consumption, a reserved provisioned guard slot, local presence,
paid service, shared-clock progress and persistence. It records one completed practice. It
**does not yet animate a complete paired combat drill or grant a global military technology,
combat-stat bonus, new troop formation or historical doctrine**. The guard slot is reserved
while the session is active; later personnel identity must be strengthened before awarding
persistent soldier-specific skills. A completed session is not proof of mastery.

## One world, different authority

`commission_rules.gd` adds an optional contract to `misl.ledger`; its receipts remain in the
original `misl.events`. `commission_state.gd` extends the existing youth state with the
physical candidate and practice progress. `commission_chapter.gd` extends the existing
Home controller; the inherited main scene, treasury and `childhood.tick` remain authoritative.

The instructor is another instance of **the same player scene and motor**, stepped once by
the owning controller. Employment, control permission, physical body and treasury authority
are separate. Switching viewpoints leaves both bodies where they are. Buddh waits while the
instructor is controlled; this does not launch another world or advance the clock twice.

The instructor does not receive Buddh's private journal or the ability to buy from his treasury.
The limited journal contains that actor's performed commission events. Role switching requires
regrouping at home and is refused during the active drill or incompatible carried/escort tasks.
No religious portrayal or pre-existing non-playable-character rule is changed.

## Persistence and compatibility

Default slot: `user://1792-commission-v1.json`. Buddh's J menu offers an explicit import of
the earlier youth-bazaar slot; this replaces the entire current run and does not merge later
funds or knowledge backward. The earlier slot itself is not overwritten.

Both economic replay and current physical standing-space checks precede load promotion.
Wrong actor IDs, altered balances, incompatible phases, impossible velocities, future clocks,
unearned practice and obstructed specialist positions are refused. A newly placed wall also
invalidates an already-open handover at execution, before money moves.

Inherited numeric serialization uses full precision. Snapshot comparisons normalize both
sides through the same JSON decoder; this is consistency checking, not a signature, anti-cheat
system or proof that a maliciously authored receipt really happened in play.

The inherited 256-economic-receipt budget remains. Commission admission requires spare room,
but unrelated later actions can exhaust it. No forged settlement is substituted on exhaustion.
Windows filesystem replacement, hostile duplicate-key JSON, power-loss recovery, unrestricted
multi-character persistence and cross-platform bitwise determinism are not qualified here.

## Future European officer chapters

The authoring catalogue preserves required playable chapters for **Allard, Ventura, Court
and Avitabile**, with distinct roles and year-level reference eligibility. They are explicitly
unimplemented; all remain unavailable in 1792. The current instructor is not one of those people.

The supplied Ian Heath, *The Sikh Army 1799–1849* (2005), printed pages 10–12 / PDF pages
12–14, was inspected. It distinguishes foreign recruitment, service conditions, wages and
training that predated the most prominent arrivals. The Wallace Collection article
“Ranjit Singh's army: his Firangis” describes Allard and Ventura arriving in 1822 seeking
employment. Neither source establishes that every officer was purchased abroad through a
royal agent. The proposed agent → consent → terms → travel → appointment pipeline is a game
requirement, with each historical route still requiring individual research.

Source URL: https://www.wallacecollection.org/explore/explore-in-depth/the-sikh-empire/sikh-arms-armour/ranjit-singhs-army-his-firangis/

Victoria 3 inspires the relationship between revenue, institutions, production and military
sustainment. This is not a mod, a clone or a claim about current Victoria 3 Punjab balance.
Significant officer viewpoints should execute funded responsibilities in the same world;
recruitment alone must not supply free troops, factories, equipment or omniscient knowledge.

## Execute the checks

```sh
python tools/run_commission_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /path/to/godot --fixed-fps 60 --path game \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_commissions.gd
```

The wrapper keeps the inherited test commands and timeouts, then runs ten editorial-contract
checks and the actual native commission suite. Rendering requires the input-driven journey's
retained output. Receiving-yard and account views use declared presentation fixtures; returned
household and instructor views use the played journey state. These are not human playtests.

Current local result: **8,080 native assertions (7,894 retained +186 new), zero failures;
51 Python tests (41 retained +10 new); 18 fresh-process contact replay comparisons; six new
software-rendered views**. Hosted execution is a separate observation, not inferred from this
workflow definition. Physical GPUs, human feel, Windows, consoles and controller hardware
remain unqualified by this increment.

## Camera-ownership regression caught by inherited CI

The first hosted revision passed the funded-service and native suites, but failed the
unchanged completed-water screenshot assertion. A local replay reproduced the identical
occluded-water pixel. The cause was not the water mesh: routine commission hydration
unconditionally selected the principal camera, replacing the water fixture's chosen camera.

Secondary actor construction now leaves its camera inactive. Commission synchronization
changes cameras only on an actual transition into or out of the instructor viewpoint.
Ordinary hydration, pause, resume and repeated sync preserve the current scene camera.
Nine added assertions cover the initial camera, scene-owned camera preservation, unchanged
state, appointed-principal hydration, and both genuine role transitions. The original
water rendering script and its pixel/visibility assertions remain byte-identical; rerunning
that script now produces five captures with zero failures.
