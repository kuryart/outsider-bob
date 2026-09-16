@tool
class_name Event extends Node2D

@onready var event_bus: = $EventBus

var is_firing: bool = false
var is_completed: bool = false

signal fired

func _ready() -> void:
	add_to_group("event")
	fired.connect(event_bus._on_event_fired)
	event_bus.event_finished.connect(_on_event_finished)

func fire_event():
	if not can_fire():
		return
	is_firing = true
	fired.emit()

func can_fire() -> bool:
	return not is_firing and not is_completed and event_bus.can_fire()

func _on_event_finished():
	is_firing = false
	if event_bus.one_shot:
		is_completed = true
