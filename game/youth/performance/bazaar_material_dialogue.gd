# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original fictional micro-dialogue for optional material details. No historical quotation.
const TEXT := {
	"pale_repair":{
		"title":"THE PALE REPAIR",
		"description":"One side of the basket has been rebuilt with three pale strips. The old weave is darker where hands have polished it. Short offcuts were saved under the handle.",
		"with_friends":"BUDDH\nThe new strips do not match.\n\nJIVA\nThey match the break.\n\nMELA\nYou wanted a basket, not a disguise."
	},
	"hidden_colour":{
		"title":"COLOUR UNDER THE FOLD",
		"description":"The folded cloth is brighter where the sun did not reach it. A pale repair thread crosses two dyes without trying to imitate either.",
		"with_friends":"BUDDH\nThe colour underneath is stronger.\n\nMELA\nThen turn it over.\n\nJIVA\nAnd make the repair wear twice as fast? Leave one thing alone."
	},
	"kept_place":{
		"title":"A PLACE KEPT",
		"description":"A cup with a nicked rim sits beside a rolled cloth. Older cup rings stain the board around it, but this one is empty.",
		"with_friends":"BUDDH\nWhy keep an empty cup here?\n\nMELA\nPerhaps somebody is late.\n\nJIVA\nOr expected. Those are not the same thing."
	}
}
static func record(id: String) -> Dictionary:
	return TEXT.get(id,{}).duplicate(true)
