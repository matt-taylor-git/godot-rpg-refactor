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
	_apply_theme_background()

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


func _apply_theme_background() -> void:
	var bg_node = get_node_or_null("Background")
	if bg_node is Panel or bg_node is PanelContainer:
		# Remove main_menu shader material — white texture mix washes themed StyleBox to gray
		bg_node.material = null
		var style := StyleBoxFlat.new()
		var bg = UIThemeManager.get_background_color()
		# Cool dark charcoal with red undertone for defeat (not mid-gray)
		style.bg_color = Color(
			clampf(bg.r * 1.1, 0.0, 0.16),
			clampf(bg.g * 0.85, 0.0, 0.11),
			clampf(bg.b * 0.95, 0.0, 0.13),
			1.0
		)
		style.border_color = UIThemeManager.get_danger_color()
		style.border_width_top = 3
		style.border_width_bottom = 3
		bg_node.add_theme_stylebox_override("panel", style)
	if stats_grid:
		for card in stats_grid.get_children():
			if card is PanelContainer or card is Panel:
				var card_style := StyleBoxFlat.new()
				card_style.bg_color = Color(0.12, 0.10, 0.08, 0.9)
				card_style.border_color = UIThemeManager.get_border_bronze_color()
				card_style.set_border_width_all(2)
				card_style.set_corner_radius_all(2)
				card_style.set_content_margin_all(8)
				card.add_theme_stylebox_override("panel", card_style)


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
