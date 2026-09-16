extends EventBus

@onready var phantom_camera: PhantomCamera2D = %PhantomCamera2D
@onready var phantom_camera_anim: AnimationPlayer = phantom_camera.get_child(0)
@onready var bob: Bob = %Bob

@export var dialogue: DialogueResource

func _on_event_fired():
	GameController.can_move = false
	phantom_camera.follow_mode = phantom_camera.FollowMode.NONE
	phantom_camera_anim.get_animation("slide_right").track_set_key_value(0,0,phantom_camera.position)
	phantom_camera_anim.play("slide_right")
	await phantom_camera_anim.animation_finished
	await Commands.wait(2.0)
	Commands.start_dialogue(dialogue)
	await DialogueManager.dialogue_ended
	await Commands.wait(1.0)
	GameController.can_move = true
	phantom_camera.follow_mode = phantom_camera.FollowMode.SIMPLE
	event_finished.emit()
	GameController.game_data.switches.list["frizz_first_dialogue"] = true

func can_fire() -> bool:
	return not GameController.game_data.switches.list["frizz_first_dialogue"]
