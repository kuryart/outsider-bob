extends Node

@export var dialogue_01: DialogueResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Commands.wait(2.0)
	Commands.start_dialogue(dialogue_01)
	await Commands.wait(2.0)
	GameController.can_move = true
