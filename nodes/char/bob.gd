@icon("res://icon.svg")

class_name Bob extends CharacterBody2D

@onready var sprite: = $AnimatedSprite2D

@export var bob_data: BobData

var is_moving: bool = false
var is_jumping: bool = false
var move_vector: Vector2

func _ready():
	if bob_data.direction_looking == bob_data.Directions.LEFT:
		sprite.scale.x *= -1

func _process(delta: float) -> void:
	if is_moving:
		sprite.play("walk")
	elif is_jumping:
		sprite.play("jump")
	else:
		sprite.play("idle")
	
	if is_moving and move_vector.x < 0:
		if sprite.scale.x > 0:
			flip_sprite_x()
	if is_moving and move_vector.x > 0:
		if sprite.scale.x < 0:
			flip_sprite_x()

func _physics_process(delta: float) -> void:
	if GameController.can_move:
		move()
		move_and_slide()
		jump()

func move():
	move_vector = Input.get_vector("left", "right", "up", "down")
	velocity = move_vector * bob_data.move_speed
	
	if velocity != Vector2.ZERO:
		is_moving = true
	else:
		is_moving = false

func jump():
	if Input.is_action_just_pressed("jump"):
		is_jumping = true
		velocity.y = bob_data.jump_impulse
		
func flip_sprite_x():
	sprite.scale.x *= -1

func _on_animation_finished():
	print("teste")
	if is_jumping:
		is_jumping = false
	
