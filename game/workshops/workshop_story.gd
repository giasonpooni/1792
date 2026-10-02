# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dialogue around the existing finite commission. These words do not
## change the order, advance work, or supply a remotely received completion.

static func conversation(phase: String) -> String:
	match phase:
		"unassigned": return "Smith · Two rough heads on the bench. They need handles, fuel, and someone to pay for the work. Ask your quartermaster about the pair."
		"fuel": return "Smith · Two timber bundles and four household coins. Put them here if the order stands. Until you do, you can take them back to your quartermaster."
		"working": return "Smith · I have your order. There is no need to watch every blow. Go about your work; ask me when you return."
		"ready": return "Smith · Two handles, two sound heads. The pair is ready. Will you take both back to the household?"
		"tools": return "Smith · The bench is empty because you have them. The order ends when both bundles reach your quartermaster."
		"complete": return "Smith · Both made it Home. Good. Let them do some work now."
		"cancelled": return "Smith · No work was started. Your quartermaster has the fuel and payment back."
	return ""

static func acknowledgment(action: String) -> String:
	match action:
		"reserve": return "Quartermaster · Two timber bundles, four coins. Bring us back the pair you have promised."
		"start": return "Smith · I have the fuel and payment. Leave the work with me; come back for the pair."
		"collect": return "Smith · Both bundles. Keep them together on the way Home."
		"deliver": return "Quartermaster · Two bundles, as promised. Set them with the others. That will do."
		"refund": return "Quartermaster · The fuel and payment are back. The order ends here."
	return ""
