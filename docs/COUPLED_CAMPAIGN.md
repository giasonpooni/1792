# Coupled campaign direction

This document records authorial game design. It is not a source-backed numerical
reconstruction of Ranjit Singh's entire physiology, court, finances or military.

## Build outward from the home container

The first playable territory is Gujranwala and its immediate authored hinterland.
Punjab, the northwestern frontier and the Sutlej frontier are eventual connected
regions, not uniformly detailed terrain to build before a compelling home exists.
Use a route/settlement graph for connectivity and constraints, a separate height
representation for landforms, and a distinct surface/asset/shader representation.
Do not infer historical boundaries, rivers or road alignments from modern height
data or arbitrary noise. Historical anchors need evidence and date ranges.

The current 56m home cell is a gameplay test, not a completed regional topology.
Future larger cells require origin/frame mapping, scene streaming, actor-specific
navigation, and an explicit game-time travel scale, preserving named places and
identities. Shaders and dense decoration should not hide defective traversal.

## Mechanisms rather than unrelated meters

Represent a hybrid dynamical system x_next = f(x, decisions, external_events).
Continuous condition/stock evolution coexists with discrete events: a road closes,
a contract settles, a gun fires, an appointment changes, or a story gate opens.
There is no one universal linear “equilibrium matrix” that describes every mode.

The player tries to remain viable over a campaign:
cash >= commitments due; stores >= consumption needed; forces available >=
promised deployments; decision information is restricted to what has arrived.
Maintaining all quantities at their maxima is not the goal. Large armies can make
their owner less capable when feed, pay or transport cannot support them.

A local Jacobian can later explain sensitivities within a smooth regime, but
thresholds, failed contracts and changes of command require actual branch tests.

## Earnings, commitments and infrastructure

Personal missions, escort, caravan interception, raids and contracted military
service should create different rewards and liabilities. A raid can secure goods
but jeopardize later trade or create retaliation. Contract income is not the same
as an unencumbered gift: payout, wage obligations, damage and return cost differ.

Stock belongs to an owner and a location. Market purchase does not deliver distant
goods instantaneously. Recruitment is a contractual relationship, not a free unit
slot; doctors, gunners, smiths, scouts and riders have different roles, availability,
upkeep and capacities. Hire/train/equip/deploy/resupply are distinct transitions.

Construction requires inputs, transport, labor and elapsed work. A larger workshop
raises capacity but needs labor, feedstock, upkeep and a viable route. More
production capacity cannot create missing raw material.

Future ordnance readiness requires compatible ammunition, powder inventory,
trained operators, loading state, transport and serviceable equipment. Reload,
repair and movement compete for personnel/time. Model resource dependencies and
authored performance profiles, not real-world explosive recipes or manufacturing
instructions. The present game implements none of this combat chain yet.

## Information, meetings, household and patronage

An intelligence network has sources, delivery delays, recurring expense, shared
origins and possibly conflicting obligations. Multiple retellings are not multiple
independent witnesses. A richer network improves coverage while increasing
maintenance and the number of people controlling access. NPCs do not query hidden
world truth merely because a numerical graph makes it convenient.

Later adult royal-household/harem and patronage mechanics belong to court life,
not the childhood tutorial. Model named relationships, conflicting succession
claims, reciprocal promises, funding, reader/messenger access and exposure.
Instability should arise from unresolved obligations and competing interests,
not a rule that counts women as intrinsically destabilizing. A larger network
can be stable when adequately maintained, and a small one can be divided.
These are proposed authored mechanics, not verified motives in every biography.

Misl meetings and court audiences cost travel/time and affect obligations.
Attendance, authorized delegates and intelligible failure recovery must be
available. The implemented home meeting is only a bounded fictional precursor.

## Buddh's body and state-level delegation

Buddh remains his personal identity; public Ranjit / Maharaja address stays a
presentation convention. Adult aging, pain, fatigue, illness, alcohol effects and
dependence are distinct candidate states. A chosen adult narrative can portray
short relief, intoxication and later costs, but historical drinking does not prove
a clinical requirement that alcohol is the only way he can function. Rest, care,
treatment, accommodation and delegation should remain meaningful decisions.

Do not make essential captions, controls or the entire viewport illegible to force
a consumption choice. Symptom severity can affect exertion, steadiness, activity
time and optional presentation. Readable/accessibility presentation preserves the
same underlying condition and decisions. The current peripheral option remains
subjective framing, not medical certification. No new alcohol/health model is
implemented in the child chapter.

Sarkar-i-Khalsa should retain embodied play through properly appointed subordinate
commanders. Switching viewpoint changes whose senses/abilities are presented; it
does not heal Buddh, duplicate troops, share every secret or reset outstanding
commitments. His court responsibilities persist. The Mahan interlude remains
fixed-history retrospective, not an economic income exploit or alternate survival.

## Next empirical gates

Home: earn → dispatch/deliver → provision → build → pay → face shortages → recover.
Next: a rival checkpoint makes route choice and force readiness materially relevant.
Then: unit equipment/ammunition/repair as a small audited combat loop.
Only scale the region and number of actors after those loops remain intelligible
and robust under save/load, missed information, travel delays and adverse choices.
