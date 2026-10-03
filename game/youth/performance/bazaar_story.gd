# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original optional dialogue. The chapter owns contact; receipts own the outcome.
## These exchanges add no historical claim, reward, remembered evidence or timer.
const INVITATION := "Mela waits with Jiva at the edge of the stalls.\n\nMela · A short walk, Buddh. All three of us.\n\nJiva · And all three back. He always forgets that part."

static func return_exchange(outcome: String) -> String:
	match outcome:
		"stood_ground":
			return "Mela · When you tell it, begin with the first blow.\n\nJiva · Begin with the road. We could have kept walking.\n\nBuddh · You think I should have?\n\nJiva · I think he should hear what happened before you won.\n\nMela · A short walk. That was all I promised.\n\nBuddh · Then we had better tell him how it grew."
		"withdrew":
			return "Mela · We could have stayed.\n\nJiva · You were the first to turn when Buddh called.\n\nMela · He called.\n\nBuddh · And you came. That is the part I will remember.\n\nJiva · Tell the quartermaster where we left them.\n\nBuddh · And that I chose to stand there first."
		"walked_away":
			return "Mela · He will say he frightened us.\n\nJiva · He can tell his friends. We still have ours.\n\nBuddh · A short walk. All three back.\n\nMela · You are both going to keep saying that.\n\nJiva · Only when you invite us again."
	return ""
