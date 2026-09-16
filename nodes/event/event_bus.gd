@abstract class_name EventBus extends Node

@export var one_shot: bool = true

signal event_finished

func can_fire() -> bool:
	return true

@abstract func _on_event_fired()
