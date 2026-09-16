extends Node

@export var dialogue_01: DialogueResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Audio.play_bgm(Audio.bgm_bank.bank["first_scene"], 0.0)
	await Commands.wait(2.0)
	Commands.start_dialogue(dialogue_01)
	await Commands.wait(2.0)
	GameController.can_move = true
	
