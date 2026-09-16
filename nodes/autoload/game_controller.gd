extends Node

@export var can_move: bool = false
@export var dialogue_balloon: PackedScene
@export var game_data: GameData

func _ready() -> void:
	#TranslationServer.set_locale("en")
	TranslationServer.set_locale("pt_BR")
	#TranslationServer.set_locale("es")
