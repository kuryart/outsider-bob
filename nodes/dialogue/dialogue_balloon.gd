extends CanvasLayer

## The action to use for advancing the dialogue
const NEXT_ACTION = &"ui_accept"

## The action to use to skip typing the dialogue
const SKIP_ACTION = &"ui_cancel"


@export var talk_sound: AudioStream

@onready var anchor: Node2D = %Anchor

@onready var vbox_up: VBoxContainer = %VBoxUp
@onready var pin_up: Polygon2D = %PinUp
@onready var balloon_up: PanelContainer = %BalloonUp
@onready var dialogue_label_up: DialogueLabel = %DialogueLabelUp
@onready var responses_menu_up: DialogueResponsesMenu = %ResponsesMenuUp

@onready var vbox_down: VBoxContainer = %VBoxDown
@onready var pin_down: Polygon2D = %PinDown
@onready var balloon_down: PanelContainer = %BalloonDown
@onready var dialogue_label_down: DialogueLabel = %DialogueLabelDown
@onready var responses_menu_down: DialogueResponsesMenu = %ResponsesMenuDown

@onready var response_template: Label = %ResponseTemplate
@onready var pointer: Node2D = %Pointer
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var vbox: VBoxContainer
var pin: Polygon2D
var balloon: PanelContainer
var dialogue_label: DialogueLabel
var responses_menu: DialogueResponsesMenu

var pin_up_base_position: Vector2
var pin_down_base_position: Vector2

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## The marker in the world that anchors the balloon
var dialogue_marker: DialogueMarker

## The current line
var dialogue_line: DialogueLine:
	set(value):
		dialogue_line = value
		apply_dialogue_line()
	get:
		return dialogue_line

var mutation_cooldown: Timer = Timer.new()


func _ready() -> void:
	anchor.modulate.a = 0
	DialogueManager.mutated.connect(_on_mutated)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	
	pin_up_base_position = pin_up.position
	pin_down_base_position = pin_down.position


func _process(_delta: float) -> void:
	position_balloon()

	# NOTE: The responses menu might be "visible" but have its alpha set to 0 so the
	# pointer needs to have its visibility based on the alpha instead.
	var control: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(control) and control.get_parent() == responses_menu_up:
		pointer.visible = responses_menu_up.modulate.a > 0.5
		pointer.global_position = control.global_position + control.size * Vector2(0, 0.5)
	elif is_instance_valid(control) and control.get_parent() == responses_menu_down:
		pointer.visible = responses_menu_down.modulate.a > 0.5
		pointer.global_position = control.global_position + control.size * Vector2(0, 0.5)
	else:
		pointer.hide()


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	if not is_node_ready():
		await ready
	temporary_game_states =  [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	is_waiting_for_input = false
	animation_player.play_backwards(&"appear")
	await animation_player.animation_finished
	dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


## Show the next dialogue line
func apply_dialogue_line() -> void:
	# The dialogue has finished so close the balloon
	if not dialogue_line:
		queue_free()
		return

	mutation_cooldown.stop()
	anchor.modulate.a = 0

	# Find the character on screen that is talking
	dialogue_marker = DialogueMarker2D.find_for_character(dialogue_line.character)
	get_viewport().get_camera_2d().global_position = dialogue_marker.owner.global_position

	# Work out which way to point the balloon based on where the dialogue marker is within its owner.
	if dialogue_marker.position.y > 0:
		vbox_down.show()
		vbox_up.hide()
		vbox = vbox_down
		pin = pin_down
		balloon = balloon_down
		dialogue_label = dialogue_label_down
		responses_menu = responses_menu_down
	else:
		vbox_up.show()
		vbox_down.hide()
		vbox = vbox_up
		pin = pin_up
		balloon = balloon_up
		dialogue_label = dialogue_label_up
		responses_menu = responses_menu_up

	# Set the colors for the balloon based on the character
	var panel: StyleBoxFlat = balloon.theme.get_stylebox("panel", "PanelContainer")
	panel.bg_color = dialogue_marker.balloon_color
	pin.color = dialogue_marker.balloon_color
	dialogue_label.add_theme_color_override("default_color", dialogue_marker.text_color)
	response_template.add_theme_color_override("font_color", Color(dialogue_marker.text_color, 0.6))

	# Work out a good width for the dialogue text based on its length
	var measurable_regex: RegEx = RegEx.create_from_string("\\[.+?\\]")
	var measurable_text: String = measurable_regex.sub(dialogue_line.text, "", true)
	var dialogue_label_font_size: int = balloon.theme.get_font_size("normal_font", "RichTextLabel")
	var optimal_width: float = dialogue_label.get_theme_font("normal_font").get_string_size(measurable_text, HORIZONTAL_ALIGNMENT_LEFT, -1, dialogue_label_font_size).x + 20
	if optimal_width > 500:
		optimal_width = optimal_width / ceil(optimal_width * 1.1 / 500)
	elif optimal_width > 400:
		optimal_width = optimal_width / ceil(optimal_width * 1.1 / 400)
	dialogue_label.hide()
	responses_menu.hide()
	balloon.custom_minimum_size = Vector2(optimal_width + panel.content_margin_left + panel.content_margin_right, 0)

	dialogue_label.dialogue_line = dialogue_line
	dialogue_label.show()
	dialogue_label.modulate.a = 0

	responses_menu.responses = []
	if dialogue_line.responses.size() > 0:
		# NOTE: Hiding the menu takes it out of the height of the balloon which results
		# in a jump when the menu is first visible. Setting it's alpha to 0 keeps it in
		# the height calculation and removes the sudden jump.
		responses_menu.modulate.a = 0
		responses_menu.responses = dialogue_line.responses
		responses_menu.show()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	# Animate the balloon appearing
	anchor.modulate.a = 1
	animation_player.play(&"appear")
	await animation_player.animation_finished

	will_hide_balloon = false

	# Show the dialogue
	if not dialogue_line.text.is_empty():
		dialogue_label.modulate.a = 1
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.modulate.a = 1
		responses_menu.get_menu_items()[0].grab_focus()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Make sure the balloon is attached to the relevant character
#func position_balloon() -> void:
	#if is_instance_valid(dialogue_marker):
		#anchor.global_position = dialogue_marker.get_position_in_viewport()
		
func position_balloon() -> void:
	if not is_instance_valid(dialogue_marker):
		return

	# 1. Posição desejada do anchor (onde o marcador está na tela)
	var desired_anchor_pos: Vector2 = dialogue_marker.get_position_in_viewport()

	# 2. Offset do balão em relação ao anchor.
	#    Isso é ESTÁVEL: não muda quando o anchor se move, pois ambos se movem juntos.
	#    É a distância "interna" entre o anchor e o balão (pin + margens do VBox).
	var balloon_relative_pos: Vector2 = balloon.global_position - anchor.global_position

	# 3. Onde o balão ESTARIA se o anchor fosse posicionado na posição-base (sem offset)
	var predicted_balloon_pos: Vector2 = desired_anchor_pos + balloon_relative_pos
	var predicted_balloon_rect: Rect2 = Rect2(predicted_balloon_pos, balloon.size)

	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	var correction: Vector2 = Vector2.ZERO

	if predicted_balloon_rect.position.x < screen_rect.position.x:
		correction.x = screen_rect.position.x - predicted_balloon_rect.position.x
	elif predicted_balloon_rect.end.x > screen_rect.end.x:
		correction.x = screen_rect.end.x - predicted_balloon_rect.end.x

	if predicted_balloon_rect.position.y < screen_rect.position.y:
		correction.y = screen_rect.position.y - predicted_balloon_rect.position.y
	elif predicted_balloon_rect.end.y > screen_rect.end.y:
		correction.y = screen_rect.end.y - predicted_balloon_rect.end.y

	# 4. Aplica a posição-base + correção (sempre determinístico, nunca oscila)
	anchor.global_position = desired_anchor_pos + correction
	pin.position = pin.position + correction
	
	# Reposiciona o pin na direção oposta para ele continuar apontando pro personagem.
	if pin == pin_up:
		pin.position = pin_up_base_position - correction
	else:
		pin.position = pin_down_base_position - correction

#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		anchor.modulate.a = 0


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	get_viewport().get_camera_2d().position = Vector2.ZERO


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(SKIP_ACTION)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		next(dialogue_line.next_id)
	elif event.is_action_pressed(NEXT_ACTION) and get_viewport().gui_get_focus_owner() == balloon:
		get_viewport().set_input_as_handled()
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


func _on_dialogue_label_spoke(letter: String, letter_index: int, _speed: float) -> void:
	if [" ", "."].has(letter): return
	if letter_index % 2 == 0: return

	audio_stream_player.stream = talk_sound
	audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
	audio_stream_player.play()


#endregion
