extends Node2D

# MainScene - Root scene that manages overall game flow
# Initial boot only; subsequent transitions go through GameManager + SceneTransition

func _ready():
	print("MainScene ready")
	# Load persisted settings before any UI animates
	GameSettings.load_settings()

	# Dev tool: scene gallery screenshots (see scripts/tools/ScreenshotTour.gd)
	if "--screenshot-tour" in OS.get_cmdline_user_args():
		var tour: Node = load("res://scripts/tools/ScreenshotTour.gd").new()
		tour.name = "ScreenshotTour"
		# Parent under root so change_scene() does not free the tour
		get_tree().root.call_deferred("add_child", tour)
		return

	# Start with main menu (deferred to avoid busy node tree)
	call_deferred("_initial_scene_change")


func _initial_scene_change():
	# Instant first load — no prior scene to fade from
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
