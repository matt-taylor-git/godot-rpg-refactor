extends Node2D

# MainScene - Root scene that manages overall game flow
# Initial boot only; subsequent transitions go through GameManager + SceneTransition

func _ready():
	print("MainScene ready")
	# Load persisted settings before any UI animates
	GameSettings.load_settings()
	# Start with main menu (deferred to avoid busy node tree)
	call_deferred("_initial_scene_change")


func _initial_scene_change():
	# Instant first load — no prior scene to fade from
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
