# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original English dramatic writing. No recovered dialogue or historical voice claim.
const CHALLENGE := "The challenger plants himself in the road.\n\nCHALLENGER\nThe Sukerchakia heir. One eye, two playmates. This is Bhangi company. Your name does not clear our road.\n\nBUDDH\nThen move your feet.\n\nMELA\nWe came together. We go home together.\n\nStand and answer the raised blows, or leave with both friends. Neither choice leaves a friend behind."
const FRIENDS := "Mela lowers his voice. Jiva glances back along the road.\n\nMELA\nSay the word and I am with you.\n\nJIVA\nYou are always with him. Usually that is how we get into trouble.\n\nMELA\nAnd you always know the way out.\n\nJIVA\nI would rather we used it before someone breaks a tooth.\n\nTheir disagreement is over the quarrel, not whether they will stay with you."
const INVITE := "Mela · Come on, Buddh. One walk through the bazaar. Even you can manage that without a quarrel."
const STAND := "Buddh · Stay close. I am not leaving either of you here."
const LEAVE := "Buddh · Let him have the last word. We have somewhere to be."
const REPORT := {
	"stood_ground":"Quartermaster · Your friends came back with you. Good. Now tell me what happened before the shouting—not only the part where you won.",
	"withdrew":"Quartermaster · You began a fight and chose to end it. Tell me where they stopped following. I need the road, not the boast.",
	"walked_away":"Quartermaster · No missing friend. No broken head. You need not make the story louder for my sake. Tell me what was said."
}
static func lines(kind: String,outcome: String="") -> Array:
	match kind:
		"invite": return [[3,"A short walk. Then home before they send someone to fetch us."],[4,"You said that before the last short walk."]]
		"stand": return [[3,"I am here, Buddh. Keep them in front of you."]]
		"leave": return [[4,"This way. We do not owe him an audience."],[3,"I was just beginning to dislike him."]]
		"regroup":
			if outcome=="stood_ground": return [[3,"You should have seen his face."],[4,"I saw yours. You were looking for us."],[3,"Of course I was."]]
			if outcome=="withdrew": return [[3,"We could have stayed."],[4,"We could also be carrying you. Keep walking."]]
			return [[3,"You really let him keep the road?"],[4,"For the price of a few words. A poor trade for him."]]
	return []
