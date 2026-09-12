class_name UIButton extends BaseButton

func _ready() -> void:
	button_up.connect(_on_button_up)

func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_EXIT:
		if not Audio.is_sound_canceled:
			Audio.play_se(Audio.se_bank_ui.bank["cursor_move"])

func _on_button_up():
	Audio.play_se(Audio.se_bank_ui.bank["select"])
