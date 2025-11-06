extends Control

# MainMenu - Main menu scene with navigation options

func _ready():
	print("MainMenu ready")

func _on_new_game_pressed():
	print("New Game pressed")
	GameManager.start_new_game()

func _on_load_game_pressed():
	print("Load Game pressed")
	# TODO: Implement load game dialog

func _on_exit_pressed():
	print("Exit pressed")
	get_tree().quit()
