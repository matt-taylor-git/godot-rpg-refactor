extends Control

# MainMenu - Main menu scene with navigation options

@onready var title_label = $CenterContainer/MenuPanel/VBoxContainer/TitleLabel
@onready var new_game_button = $CenterContainer/MenuPanel/VBoxContainer/NewGameButton
@onready var load_game_button = $CenterContainer/MenuPanel/VBoxContainer/LoadGameButton
@onready var exit_button = $CenterContainer/MenuPanel/VBoxContainer/ExitButton

const SAVE_SLOT_DIALOG = preload("res://scenes/ui/save_slot_dialog.tscn")

func _ready():
	print("MainMenu ready")
	_animate_menu_in()

func _animate_menu_in():
	# Animate title
	title_label.modulate.a = 0.0
	title_label.position.y -= 50

	# Animate buttons
	new_game_button.modulate.a = 0.0
	load_game_button.modulate.a = 0.0
	exit_button.modulate.a = 0.0

	# Title animation
	var title_tween = create_tween()
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	title_tween.parallel().tween_property(title_label, "position:y", title_label.position.y + 50, 0.5)
	title_tween.finished.connect(func(): title_tween.kill())

	# Button animations with stagger
	await title_tween.finished

	var new_game_tween = create_tween()
	new_game_tween.tween_property(new_game_button, "modulate:a", 1.0, 0.3)
	new_game_tween.finished.connect(func(): new_game_tween.kill())
	await new_game_tween.finished

	var load_game_tween = create_tween()
	load_game_tween.tween_property(load_game_button, "modulate:a", 1.0, 0.3)
	load_game_tween.finished.connect(func(): load_game_tween.kill())
	await load_game_tween.finished

	var exit_tween = create_tween()
	exit_tween.tween_property(exit_button, "modulate:a", 1.0, 0.3)
	exit_tween.finished.connect(func(): exit_tween.kill())

func _animate_button_press(button: Button):
	# Quick scale animation for button press
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.95, 0.1)
	tween.tween_property(button, "scale", original_scale, 0.1)
	tween.finished.connect(func(): tween.kill())

func _on_new_game_pressed():
	print("New Game pressed")
	GameManager.start_new_game()
	_change_scene("character_creation")

func _on_load_game_pressed():
	print("Load Game pressed")
	_animate_button_press(load_game_button)
	await get_tree().create_timer(0.2).timeout

	_show_save_slot_dialog()

func _on_exit_pressed():
	print("Exit pressed")
	_animate_button_press(exit_button)
	await get_tree().create_timer(0.2).timeout

	_animate_menu_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _show_save_slot_dialog():
	var dialog = SAVE_SLOT_DIALOG.instantiate()
	add_child(dialog)

	# Connect signals
	dialog.connect("slot_selected", Callable(self, "_on_save_slot_selected"))
	dialog.connect("cancelled", Callable(self, "_on_save_slot_cancelled"))

func _on_save_slot_selected(slot_number: int):
	print("Loading from slot ", slot_number)
	var success = GameManager.load_game(slot_number)
	if success:
		# Determine which scene to go to based on game state
		if GameManager.in_combat:
			GameManager.change_scene("combat_scene")
		else:
			GameManager.change_scene("town_scene")
	else:
		print("Failed to load game from slot ", slot_number)
		# Could show error message

func _on_save_slot_cancelled():
	print("Save slot selection cancelled")

func _change_scene(scene_name: String):
	# Change to the appropriate scene immediately (skip animation in headless mode)
	print("Changing to scene: ", scene_name)
	GameManager.change_scene(scene_name)

func _animate_menu_out():
	# Animate everything fading out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(new_game_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(load_game_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(exit_button, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): tween.kill())
