extends Control

# MainMenu - Main menu scene with navigation options

@onready var title_label = $VBoxContainer/TitleLabel
@onready var new_game_button = $VBoxContainer/NewGameButton
@onready var load_game_button = $VBoxContainer/LoadGameButton
@onready var exit_button = $VBoxContainer/ExitButton

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

	# Button animations with stagger
	await title_tween.finished

	var button_tween = create_tween()
	button_tween.tween_property(new_game_button, "modulate:a", 1.0, 0.3)
	await button_tween.finished

	button_tween = create_tween()
	button_tween.tween_property(load_game_button, "modulate:a", 1.0, 0.3)
	await button_tween.finished

	button_tween = create_tween()
	button_tween.tween_property(exit_button, "modulate:a", 1.0, 0.3)

func _animate_button_press(button: Button):
	# Quick scale animation for button press
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.95, 0.1)
	tween.tween_property(button, "scale", original_scale, 0.1)

func _on_new_game_pressed():
	print("New Game pressed")
	_animate_button_press(new_game_button)
	await get_tree().create_timer(0.2).timeout

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
		_change_scene("exploration")  # Or whatever the loaded scene should be
	else:
		print("Failed to load game from slot ", slot_number)
		# Could show error message

func _on_save_slot_cancelled():
	print("Save slot selection cancelled")

func _change_scene(scene_name: String):
	# Animate menu out before changing scene
	_animate_menu_out()
	await get_tree().create_timer(0.3).timeout

	# Change to the appropriate scene
	match scene_name:
		"character_creation":
			get_tree().change_scene_to_file("res://scenes/ui/character_creation.tscn")
		"exploration":
			# For now, just print since exploration scene doesn't exist yet
			print("Would change to exploration scene")
			print("Game state updated - ready for exploration")
		_:
			print("Unknown scene: ", scene_name)

func _animate_menu_out():
	# Animate everything fading out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(new_game_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(load_game_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(exit_button, "modulate:a", 0.0, 0.3)
