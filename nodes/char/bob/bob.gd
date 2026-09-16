@icon("res://icon.svg")

class_name Bob extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var ray: ShapeCast2D = %Ray

@export var bob_data: BobData

var is_moving: bool = false
var is_jumping: bool = false
var move_vector: Vector2
var jump_velocity: float = 0.0
var jump_height: float = 0.0

func _ready():
	if bob_data.direction_looking == bob_data.Directions.LEFT:
		sprite.scale.x *= -1

func _process(_delta: float) -> void:
	update_sprite()

func update_sprite() -> void:
	if not GameController.can_move:
		sprite.play("idle")
		return

	if is_jumping:
		sprite.play("jump")
	elif is_moving:
		sprite.play("walk")
	else:
		sprite.play("idle")

	if is_moving and move_vector.x < 0 and sprite.scale.x > 0:
		flip_sprite_x()
	elif is_moving and move_vector.x > 0 and sprite.scale.x < 0:
		flip_sprite_x()

func _physics_process(delta: float) -> void:
	if not GameController.can_move:
		velocity = Vector2.ZERO
		is_moving = false
		is_jumping = false
		jump_height = 0.0
		jump_velocity = 0.0
		update_jump_offset()
		return

	if is_jumping:
		process_jump(delta)
	else:
		move()
		move_and_slide()
		jump()
		check_for_event_area()
		check_for_event()

func move():
	move_vector = Input.get_vector("left", "right", "up", "down")
	velocity = move_vector * bob_data.move_speed
	
	if velocity != Vector2.ZERO:
		is_moving = true
	else:
		is_moving = false

func jump() -> void:
	if Input.is_action_just_pressed("jump"):
		is_jumping = true
		jump_velocity = bob_data.jump_impulse
		velocity = Vector2.ZERO
		is_moving = false
		
func process_jump(delta: float) -> void:
	# Aplica gravidade (acelera para baixo)
	jump_velocity -= bob_data.gravity * delta
	# Integra a altura
	jump_height += jump_velocity * delta

	# Aterrissou
	if jump_height <= 0.0:
		jump_height = 0.0
		jump_velocity = 0.0
		is_jumping = false

	update_jump_offset()
	
func update_jump_offset() -> void:
	sprite.position.y = -jump_height
		
func flip_sprite_x():
	sprite.scale.x *= -1

func check_for_event_area():
	if ray.is_colliding():
		var collider = ray.get_collider(0)
		if collider.is_in_group("event_area") and collider.has_method("fire_event"):
			collider.fire_event()

func check_for_event():
	if Input.is_action_just_pressed("interact") and ray.is_colliding():
		var collider = ray.get_collider(0)
		if collider.is_in_group("event") and collider.has_method("fire_event"):
			collider.fire_event()

func _on_animation_finished():
	if is_jumping:
		is_jumping = false
	
