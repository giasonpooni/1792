extends RefCounted
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Authored compressed town layout, never a surveyed 1792 plan or historical claim.
const ID := "gujranwala-neighbourhood.v1"
const VERSION := "1792.settlement.v1"
const SEED := 17920928
const EXTENT := Rect2(-58,-80,86,108) # x,z local metres; retained core is [-28,28]^2.
const WEST_GATE := Vector3(-29,0.14,-11)
const NORTH_GATE := Vector3(0,0.14,-29)
# A landmark's point is a physical object. Interacting must be nearby, on foot and visible.
const SITES := {
	"well": {"title":"The well square", "point":Vector3(-23,0.14,-42), "class":"B", "description":"The well sits where the lanes meet. A rope hangs from the crossbeam, and a water vessel waits beside the rim. From here I can see the bazaar and the entrance to the potter's court."},
	"potter": {"title":"The potter's courtyard", "point":Vector3(-45,0.14,-45), "class":"D", "description":"Jars stand in rows beside a low work table. Behind them is a kiln. The open doorway leads back to the lane; the covered verandah keeps part of the court in shade."},
	"cloth": {"title":"Cloth in the bazaar", "point":Vector3(14,0.14,-58), "class":"D", "description":"Cloth hangs in a wooden frame under the workshop roof. The open court gives room to work away from the passing traffic of the bazaar."},
	"grain": {"title":"The grain yard", "point":Vector3(-13,0.14,-64), "class":"D", "description":"Sacks and covered bins line the loading court. They belong to this yard, not to my household allowance. I must still settle purchases with the trader and the quartermaster."},
	"orchard": {"title":"The cultivated edge", "point":Vector3(15,0.14,-73), "class":"B", "description":"Beyond the last buildings the lanes give way to planted rows and open ground. The road continues out of the familiar settlement. I have not travelled the country beyond it yet."}
}
# Every compound has open court, covered rear rooms and a real front entrance.
# Front is local +Z, rotated with the compound. Doorways have 3 m clear width.
const COMPOUNDS := [
	{"id":"west_house","at":Vector3(-48,0,-7),"size":Vector2(13,16),"yaw":PI/2,"color":Color("c5a67f")},
	{"id":"potter_court","at":Vector3(-47,0,-45),"size":Vector2(15,15),"yaw":PI/2,"color":Color("bb916a")},
	{"id":"west_stable","at":Vector3(-47,0,-66),"size":Vector2(16,15),"yaw":PI/2,"color":Color("b69b71")},
	{"id":"grain_court","at":Vector3(-13,0,-65),"size":Vector2(16,16),"yaw":0.0,"color":Color("ccad80")},
	{"id":"cloth_court","at":Vector3(14,0,-61),"size":Vector2(16,13),"yaw":0.0,"color":Color("b8b5a0")},
	{"id":"north_house","at":Vector3(16,0,-36),"size":Vector2(16,9),"yaw":PI,"color":Color("ccb48a")},
	{"id":"west_kitchen","at":Vector3(-47,0,15),"size":Vector2(15,14),"yaw":PI/2,"color":Color("d1b58f")}
]
const ROADS := [
	[Vector3(-24,0,-11),Vector3(-38,0,-11),5.0],
	[Vector3(-38,0,23),Vector3(-38,0,-73),5.5],
	[Vector3(0,0,-24),Vector3(0,0,-53),7.0],
	[Vector3(-38,0,-42),Vector3(24,0,-42),6.0],
	[Vector3(-38,0,-53),Vector3(24,0,-53),5.5],
	[Vector3(0,0,-53),Vector3(0,0,-76),5.0],
	[Vector3(0,0,-73),Vector3(24,0,-73),3.0]
]

static func initial() -> Dictionary:
	return {"schema":VERSION,"map_id":ID,"seed":SEED,"visits":[]}

static func valid_position(p: Variant) -> bool:
	if not p is Array or p.size()!=3: return false
	for v in p:
		if typeof(v) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v)): return false
	return p[0]>=-58 and p[0]<=28 and p[2]>=-80 and p[2]<=28 and p[1]>=-0.5 and p[1]<=10

static func manifest() -> Dictionary:
	var buildings: Array=[]
	for c in COMPOUNDS:
		buildings.append({"id":c.id,"centre":[c.at.x,c.at.z],"size":[c.size.x,c.size.y],"yaw":c.yaw,"evidence_class":"B","surveyed":false})
	return {"schema":"1792.town-layout.v1","map_id":ID,"seed":SEED,
		"frame":"gujranwala-compressed-local-metres","georeferenced":false,
		"player_extent":[-58,28,-80,28],"retained_core_extent":[-28,28,-28,28],
		"open_after":"completed_household_inquiry","compounds":buildings,
		"landmarks":SITES.keys(),"later_monuments":[],"clocks_added":0}
