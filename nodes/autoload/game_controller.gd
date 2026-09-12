extends Node

@export var can_move: bool = false
@export var switches: Dictionary[String, bool]
@export var dialogue_balloon: PackedScene

func _ready() -> void:
	TranslationServer.set_locale("pt_BR")
	#get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
