extends Node

@onready var difficulty_check_box: CheckBox = %DifficultyCheckBox

func _ready() -> void:
	difficulty_check_box.grab_focus()
	difficulty_check_box.toggled.connect(_on_toggled)

func _on_toggled(toggled_on):
	if !toggled_on:
		difficulty_check_box.button_pressed = true
