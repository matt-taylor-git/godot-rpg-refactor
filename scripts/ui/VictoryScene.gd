extends Control

# VictoryScene - Victory screen displaying endgame statistics

var stats = {}

@onready var victory_title = $VBoxContainer/VictoryHeader/VictoryTitle
@onready var victory_message = $VBoxContainer/VictoryHeader/VictoryMessage
@onready var stats_grid = $VBoxContainer/StatsGrid
@onready var button_container = $VBoxContainer/ButtonContainer
@onready var continue_button = $VBoxContainer/ButtonContainer/ContinueButton
@onready var menu_button = $VBoxContainer/ButtonContainer/MenuButton

func _ready():
	print("VictoryScene ready")

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
	if victory_title:
		victory_title.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
	if reduce_motion:
		return
	if victory_title:
		victory_title.modulate.a = 0.0
	if stats_grid:
		stats_grid.modulate.a = 0.0
	if button_container:
		button_container.modulate.a = 0.0
	var tween = create_tween()
	if victory_title:
		tween.tween_property(victory_title, "modulate:a", 1.0, 0.4)
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
	var labels = card.get_children()
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
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_continue_pressed():
	print("Continue playing")
	# Return to exploration or next gameplay area
	GameManager.change_scene("exploration_scene")

func _on_menu_pressed():
	print("Return to main menu")
	# Return to main menu
	GameManager.change_scene("main_menu")

func _setup_focus_navigation():
	# Horizontal chain with wrapping: Menu <-> Continue
	menu_button.set("focus_neighbor_right", continue_button.get_path())
	menu_button.set("focus_neighbor_left", continue_button.get_path())

	continue_button.set("focus_neighbor_left", menu_button.get_path())
	continue_button.set("focus_neighbor_right", menu_button.get_path())

	continue_button.grab_focus()
