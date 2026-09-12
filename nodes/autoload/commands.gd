extends Node

func change_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)

func wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout

func start_dialogue(dialogue: DialogueResource, cue = "start") -> void:
	DialogueManager.show_dialogue_balloon_scene(GameController.dialogue_balloon, dialogue, cue)
