extends Control

# WorldMap - A simple world map for navigating between locations

@onready var background = $Background
@onready var town_button = $VBoxContainer/HBoxContainer/TownButton
@onready var forest_button = $VBoxContainer/HBoxContainer/ForestButton

func _ready():
	_apply_theme_background()
	_style_location_buttons()
	_setup_focus_navigation()


func _apply_theme_background() -> void:
	if background == null:
		return
	# Remove main_menu shader material — it samples default white and washes to flat gray
	background.material = null
	var style := StyleBoxFlat.new()
	var bg = UIThemeManager.get_background_color()
	# Warm charcoal parchment (clearly darker than mid-gray ~0.36)
	style.bg_color = Color(
		clampf(bg.r * 1.35, 0.0, 0.22),
		clampf(bg.g * 1.25, 0.0, 0.18),
		clampf(bg.b * 1.1, 0.0, 0.14),
		1.0
	)
	style.border_color = UIThemeManager.get_border_bronze_color()
	style.set_border_width_all(0)
	style.border_width_top = 4
	style.border_width_bottom = 4
	background.add_theme_stylebox_override("panel", style)


func _style_location_buttons() -> void:
	var hbox = get_node_or_null("VBoxContainer/HBoxContainer")
	if hbox:
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for btn in [town_button, forest_button]:
		if btn == null:
			continue
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(180, 200)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.10, 0.08, 0.95)
		style.border_color = UIThemeManager.get_border_bronze_color()
		style.set_border_width_all(2)
		style.set_corner_radius_all(2)
		style.set_content_margin_all(16)
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate()
		hover.border_color = UIThemeManager.get_accent_color()
		hover.bg_color = Color(0.16, 0.13, 0.10, 0.95)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_color_override(
			"font_color", UIThemeManager.get_text_primary_color())

func _setup_focus_navigation():
	# Horizontal chain with wrapping: Town <-> Forest
	town_button.set("focus_neighbor_right", forest_button.get_path())
	town_button.set("focus_neighbor_left", forest_button.get_path())

	forest_button.set("focus_neighbor_left", town_button.get_path())
	forest_button.set("focus_neighbor_right", town_button.get_path())

	town_button.grab_focus()

func _on_town_pressed():
	print("Town button pressed")
	GameManager.go_to_town()

func _on_forest_pressed():
	print("Forest button pressed")
	GameManager.go_to_exploration()
