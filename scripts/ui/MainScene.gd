extends Node2D

# MainScene - Root scene that manages overall game flow
# Initial boot only; subsequent transitions go through GameManager + SceneTransition

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const OPENING_CINEMATIC_SCENE: String = "res://scenes/ui/opening_cinematic.tscn"

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

	# Start the boot flow (deferred to avoid a busy node tree)
	call_deferred("_initial_scene_change")


func _initial_scene_change():
	# Instant first load — no prior scene to fade from
	var initial_scene: String = OPENING_CINEMATIC_SCENE
	if _should_skip_opening():
		initial_scene = MAIN_MENU_SCENE
	get_tree().change_scene_to_file(initial_scene)


func _should_skip_opening() -> bool:
	if "--skip-intro" in OS.get_cmdline_user_args():
		return true
	return ProjectSettings.get_setting("accessibility/reduced_motion", false)
