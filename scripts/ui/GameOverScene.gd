extends Control

# GameOverScene - Game over screen displayed when player dies

var stats = {}

@onready var game_over_title = $Content/VBoxContainer/GameOverHeader/GameOverTitle
@onready var game_over_message = $Content/VBoxContainer/GameOverHeader/GameOverMessage
@onready var stats_grid = $Content/VBoxContainer/StatsPanel/StatsGrid
@onready var button_container = $Content/VBoxContainer/ButtonContainer
@onready var restart_button = $Content/VBoxContainer/ButtonContainer/RestartButton
@onready var menu_button = $Content/VBoxContainer/ButtonContainer/MenuButton

func _ready():
	print("GameOverScene ready")

	# Gather statistics from GameManager
	stats = {
		"final_level": GameManager.get_player().level if GameManager.get_player() else 1,
		"playtime": GameManager.get_playtime_minutes(),
		"enemies_defeated": GameManager.get_enemies_defeated(),
		"deaths": GameManager.get_deaths(),
		"gold_earned": GameManager.get_gold_earned(),
		"quests_completed": GameManager.get_quests_completed()
	}

	# Populate UI
	_populate_statistics()
	_setup_buttons()
	_setup_focus_navigation()
	_animate_entrance()


func _animate_entrance() -> void:
	var reduce_motion = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false)
	if game_over_title:
		game_over_title.add_theme_color_override(
			"font_color", UIThemeManager.get_color("danger"))
	if reduce_motion:
		return
	if game_over_title:
		game_over_title.modulate.a = 0.0
	if stats_grid:
		stats_grid.modulate.a = 0.0
	if button_container:
		button_container.modulate.a = 0.0
	var tween = create_tween()
	if game_over_title:
		tween.tween_property(game_over_title, "modulate:a", 1.0, 0.45)
	if stats_grid:
		tween.tween_property(stats_grid, "modulate:a", 1.0, 0.35)
	if button_container:
		tween.tween_property(button_container, "modulate:a", 1.0, 0.3)
	tween.finished.connect(func(): tween.kill())

func _populate_statistics():
	# Update stat labels in grid
	var stat_labels = stats_grid.get_children()
	if stat_labels.size() >= 6:
		# Stats are organized as VBoxContainers with Label children
		# Final Level
		_update_stat_card(stat_labels[0], "Final Level", str(stats["final_level"]))
		# Playtime
		_update_stat_card(stat_labels[1], "Playtime", _format_playtime(stats["playtime"]))
		# Enemies Defeated
		_update_stat_card(stat_labels[2], "Enemies Defeated", str(stats["enemies_defeated"]))
		# Deaths
		_update_stat_card(stat_labels[3], "Times Died", str(stats["deaths"]))
		# Gold Earned
		_update_stat_card(stat_labels[4], "Gold Earned", str(stats["gold_earned"]))
		# Quests Completed
		_update_stat_card(stat_labels[5], "Quests Completed", str(stats["quests_completed"]))

func _update_stat_card(card: Control, label_text: String, value_text: String):
	# Cards are now PanelContainers with VBoxContainer children
	var vbox = card.get_child(0) if card.get_child_count() > 0 else null
	if vbox:
		var labels = vbox.get_children()
		if labels.size() >= 2:
			labels[0].text = label_text  # Label
			labels[1].text = value_text   # Value

func _format_playtime(minutes: int) -> String:
	if minutes < 60:
		return "%dm" % minutes
	var hours = minutes / 60
	var mins = minutes % 60
	return "%dh %dm" % [hours, mins]

func _setup_buttons():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_restart_pressed():
	print("Restarting game")
	# Start a new game
	GameManager.start_new_game()
	GameManager.change_scene("character_creation")

func _on_menu_pressed():
	print("Return to main menu")
	# Return to main menu
	GameManager.change_scene("main_menu")

func _setup_focus_navigation():
	# Horizontal chain with wrapping: Restart <-> Menu
	restart_button.set("focus_neighbor_right", menu_button.get_path())
	restart_button.set("focus_neighbor_left", menu_button.get_path())

	menu_button.set("focus_neighbor_left", restart_button.get_path())
	menu_button.set("focus_neighbor_right", restart_button.get_path())

	restart_button.grab_focus()
