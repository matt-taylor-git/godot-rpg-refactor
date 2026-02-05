extends Node2D

# MainScene - Root scene that manages overall game flow
# Handles scene transitions and global UI elements

var current_scene_instance = null

@onready var scene_manager = $SceneManager

func _ready():
	print("MainScene ready")
	# Connect to GameManager signals
	GameManager.connect("scene_changed", Callable(self, "_on_scene_changed"))

	# Start with main menu (deferred to avoid busy node tree)
	call_deferred("_initial_scene_change")

func _initial_scene_change():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_scene_changed(scene_name: String):
	# Handle the actual scene change when GameManager signals it
	var scene_path = "res://scenes/ui/" + scene_name + ".tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Error: Scene file not found: ", scene_path)
