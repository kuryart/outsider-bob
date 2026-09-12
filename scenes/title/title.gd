extends Node2D

@onready var main_menu: MarginContainer = %main_menu
@onready var new_game_button: UIButton = %new_game_button
@onready var load_game_button: UIButton = %load_game_button
@onready var options_button: UIButton = %options_button
@onready var exit_button: UIButton = %exit_button
@onready var menu_animator: AnimationPlayer = %menu_animator
@onready var portal: Sprite2D = %Portal
@onready var bob: Bob = %Bob

@export var dialogue: DialogueResource
@export var first_scene: PackedScene

var menu_speed = 2.0

func _ready() -> void:
	portal.hide()
	Audio.play_bgm(Audio.bgm_bank.bank["intro"], 0.0)
	new_game_button.connect("button_up", _on_new_game_pressed)
	await Commands.wait(2.0)
	menu_animator.play("slide_down")
	await menu_animator.animation_finished
	enable_menu()
	new_game_button.grab_focus()
	
func enable_menu():
	new_game_button.disabled = false
	load_game_button.disabled = false
	options_button.disabled = false
	exit_button.disabled = false
	
func _on_new_game_pressed():
	menu_animator.play("slide_up")
	await menu_animator.animation_finished
	await Commands.wait(2.0)
	Commands.start_dialogue(dialogue)
	await DialogueManager.dialogue_ended
	await Commands.wait(2.0)
	Audio.stop_bgm()
	await Commands.wait(4.0)
	var portal_rotation_glow: AnimationPlayer = portal.get_child(0)
	var portal_scale: AnimationPlayer = portal.get_child(1)
	portal.scale = Vector2.ZERO
	portal.show()
	portal_rotation_glow.play("glow")
	portal_scale.play("scale")
	Audio.play_se(Audio.se_bank_misc.bank["portal"])
	await portal_scale.animation_finished
	Audio.play_bgs(Audio.bgs_bank.bank["portal_noise"])
	await Commands.wait(2.0)
	var bob_anim: AnimationPlayer = bob.get_node("AnimationPlayer")
	bob_anim.play("portal_swallowed")
	await bob_anim.animation_finished
	await Commands.wait(3.0)
	await Fade.fade_out(4.0).finished
	Commands.change_scene(first_scene)
	await Fade.fade_in(4.0).finished
