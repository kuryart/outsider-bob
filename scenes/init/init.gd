extends Control

@export var title_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	var language = OS.get_locale_language()
	var locale = OS.get_locale()
			
	await get_tree().create_timer(2.0).timeout
	await Fade.fade_out().finished
	Commands.change_scene(title_scene)
	Fade.fade_in()
