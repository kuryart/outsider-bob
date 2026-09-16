extends EventBus

@export var dialogue: DialogueResource

func _on_event_fired():
	Commands.start_dialogue(dialogue)
	await DialogueManager.dialogue_ended
	event_finished.emit()
