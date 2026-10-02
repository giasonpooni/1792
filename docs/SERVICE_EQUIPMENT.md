# Service equipment study

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

Open **Equipment study · sword, scabbard, shield and helmet** from the existing
main menu. The three sliders draw and resheathe the two swords, turn the display,
and scrub mail motion, in that order. H or the close-up toggle isolates the helmet.
G shows the equipped guard; its first slider changes the gate signal pose. H and G
select mutually exclusive views. The sliders have visible labels, and the draw
slider is disabled in the helmet close-up.
Keyboard arrows, Home and End work on focused sliders. R resets the poses and turn;
F1 returns to the menu. The menu scrolls on shorter windows so existing
entries remain reachable.

The same modules attach a sheathed sidearm, round shield and domed helmet to the
existing Home gate guard. This is a procedural art prototype. It adds a readable
equipment silhouette to the existing figure, not a combatant or inventory system.

## Geometry and attachment

The blade, crossguard, grip and pommel share one rigid `Sword` root. The dark
scabbard has its own root, cover, throat, two suspension bands/rings and toe fitting.
It remains attached while the sword moves. The service and fitted studies share
blade geometry; their fittings use different surfaces. Decoration supplies no
damage or rank multiplier.

The blade follows a circular centreline with authored radius 1.12 m and angle
0.78 radians: an arc length of 0.8736 m. Extraction rotates the sword about that
circle's centre, preserving the centreline of the portion still inside the sheath.
The slider is a reversible pose parameter. `SHEATHED`, `DRAWING` and `DRAWN` name
inspection poses, not saved actions, timing, hand IK or physically solved contact.
Full-width blade/sheath clearances and manufacturing feasibility are not qualified
by this centreline test.

The shield has a dished front/back shell, rim, four bosses and separate back grips.
Its back grips are now raised loops with an explicit hand anchor.
The helmet has a rigid dome, rim and finial. Its shell uses outward-facing triangles;
the close-up exposed and corrected the original inward winding.

The mail curtain uses 512 rigid torus instances in one `MultiMesh`: 32 strips of 16
rings, with an authored ring centre radius of 9.5 mm, wire radius of 1.35 mm and strip
pitch of 14 mm. The upper row stays pinned to helmet-local anchors in both position
and orientation. Lower rows articulate while preserving each ring and the length
of every strip segment. A front opening is an authored visibility choice.

Motion samples the supplied tick on a 480-tick cycle and has no integration history
or independent clock. The inspection slider uses full amplitude; the guard samples
the existing chapter tick at amplitude 0.20. Rewinding a tick reproduces the same
transforms. This is a kinematic presentation study. Adjacent strips are not solved
as a connected mesh, and interlink topology, ring contact, body contact, mass and
material response remain unqualified.

The gate guard reuses `bazaar_figure.gd`'s articulated torso, head, arms, hands, legs
and feet. Existing bazaar figures keep their default headwear; the guard uses an
optional uncovered head beneath the helmet. The helmet is uniformly scaled by 1.13
on its head socket and turned to align the mail opening with the face. This is an
authored fit, not a measured helmet or costume reconstruction.

The shield is parented to the outer forearm, with its hand anchor coincident with
the figure's actual hand centre. It follows the supporting arm during the existing
approach signal. The sword is parented to a torso socket, and two visible straps
join belt anchors to the actual scabbard suspension rings. Both feet stay planted.
These are rigid joint attachments and authored poses; grip forces, strap mechanics,
body contact, cloth dynamics and combat transitions are not solved.

All dimensions are authored working values, not measurements extracted from the
photographs. Physical mass, balance, inertia, cutting behaviour and historical
attribution remain uncalibrated. The two reference images are identified by content
hash in [the intake record](../data/art/service_equipment.v1.json). Their pixels,
inscriptions and detailed ornament are not distributed with the game.

## Existing authority

The guard's three equipment attachments add no passage record. The current gate
contract remains **seven records**, including the two sparse crossing figures.
Equipment supplies no collision, navigation, knowledge, access permission,
reputation, combat decision, campaign receipt, clock or save field.

Mesh AABB corners transformed into world space are checked against the existing
1.9 m half-width passage and ground plane. The mail suite also transforms the shared
ring mesh bounds through every sampled instance. These checks cover the authored
attachments and sampled mail poses; dynamic riders, crowd avoidance and weapon
contact remain outside this study.
The guard moves 0.15 m farther toward the outer edge (gate-local X = 2.40 m) so the
larger articulated figure and its complete signal remain outside that passage.

The same change repairs the earlier cart/pack invariant: `sample()` no longer
rotates either resting object. Full transforms, non-identity rotation/scale and
rewound ticks are checked. Cloth retains the existing motion channel.

## Execution and review

`tools/run_checks.py` includes `test_service_equipment.gd`, `test_mail_aventail.gd`,
`test_service_guard.gd` and the strengthened gate suite. Guard checks use the actual
hand mesh, shield anchor, strap endpoints, belt anchors and scabbard rings across
signal and rewound poses. They cover planted feet, body/equipment bounds, invalid
sampling and the native G/H/slider/reset controls. Deliberately detaching the shield
produces a detected grip mismatch. Mail checks cover rigid transforms, fixed strip
lengths, pinned anchors, bounds, rewind, invalid inputs, passage clearance and
native keyboard controls. CPU poses are checked explicitly because Godot's dummy
headless renderer does not retain the instance buffer.

The Home-art workflow retains nine actual engine views: sheathed, partially drawn,
drawn, two helmet close-ups, guard at rest/signalling/from behind, and equipment on
the live Home guard. With the real
renderer, it reads back all 512 instance transforms in each of three poses, and
deliberately corrupts one uploaded transform to prove the comparison detects it.
The capture checks different scene pixels across draw and mail poses, and unchanged
campaign/player state while inspecting Home. Source commit/tree and image hashes
accompany the captures. This renderer check does not qualify hardware performance.

The renderer proves execution, not final art acceptance. Procedural silhouettes,
simple surfaces and the reused supporting-character figure still require artist
and human play review. The equipment remains in separate attachment hierarchies
for later character-art refinement without replacing the game's state or movement
authority.
