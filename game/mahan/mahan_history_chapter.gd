extends "res://mahan/mahan_orders_chapter.gd"
## Mahan historical-event presentation: known frames only after observe / delayed delivery / endpoint ack.
const HistoryModel := preload("res://mahan/mahan_history_state.gd")

func _ready() -> void:
	campaign = HistoryModel.new()
	campaign.enable_riding()
	super._ready()
	_notice = "E at the table for scouts, counsel, orders, or historical frames. F to mount. Known history appears only after observation or delivery."
