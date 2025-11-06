extends Node2D

# MainScene - Root scene that manages overall game flow
# Handles scene transitions and global UI elements

@onready var scene_manager = $SceneManager

var current_scene_instance = null

func _ready():
	print("MainScene ready")
	# Connect to GameManager signals
	GameManager.connect("scene_changed", Callable(self, "_on_scene_changed"))
	
	# Start with main menu
	_change_scene("main_menu")

func _change_scene(scene_name: String):
	# Remove current scene
	if current_scene_instance:
		current_scene_instance.queue_free()
	
	# Load new scene
	var scene_path = "res://scenes/ui/" + scene_name + ".tscn"
	var scene_resource = load(scene_path)
	
	if scene_resource:
		current_scene_instance = scene_resource.instantiate()
		add_child(current_scene_instance)
		print("Loaded scene: ", scene_name)
	else:
		print("Failed to load scene: ", scene_path)

func _on_scene_changed(scene_name: String):
	_change_scene(scene_name)
