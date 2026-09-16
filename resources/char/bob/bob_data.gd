class_name BobData extends Resource

enum Directions {LEFT, RIGHT}

@export var status: String = "Example: tired"
@export var move_speed: = 200.0
@export var direction_looking: Directions
@export_group("Jump")
@export var jump_impulse: float = 300.0
@export var gravity: float = 900.0
