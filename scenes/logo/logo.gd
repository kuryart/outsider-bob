extends Control

@onready var audio_player:= $AudioStreamPlayer

@export var title: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	await Commands.wait(1.0)
	audio_player.play()
	await audio_player.finished
	await Commands.wait(2.0)
	await Fade.fade_out().finished
	await Commands.wait(1.0)
	Commands.change_scene(title)
	Fade.fade_in()
