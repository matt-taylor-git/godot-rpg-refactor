extends Control

# TownScene - DEPRECATED: absorbed into exploration hub (GameManager aliases town_scene).
# Kept so old scene files still load if opened directly.

@onready var title_label = $VBoxContainer/Title
@onready var shop_button = $VBoxContainer/CardsRow/ShopCard/VBox/ShopButton
@onready var quest_giver_button = $VBoxContainer/CardsRow/QuestCard/VBox/QuestGiverButton
@onready var leave_town_button = $VBoxContainer/CardsRow/GateCard/VBox/LeaveTownButton
@onready var shop_subtitle = $VBoxContainer/CardsRow/ShopCard/VBox/Subtitle
@onready var quest_subtitle = $VBoxContainer/CardsRow/QuestCard/VBox/Subtitle
@onready var gate_subtitle = $VBoxContainer/CardsRow/GateCard/VBox/Subtitle
@onready var background = $Background


func _ready():
	_style_title()
	_style_card_subtitles()
	_setup_focus_navigation()
	_animate_entrance()


func _style_title():
	if not title_label:
		return
	var player = GameManager.get_player()
	if player and player.name:
		title_label.text = "Welcome, %s" % player.name
	else:
		title_label.text = "Welcome to Town"
	title_label.add_theme_color_override(
		"font_color", UIThemeManager.get_color("title_gold"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)


func _style_card_subtitles():
	var secondary = UIThemeManager.get_color("secondary")
	for label in [shop_subtitle, quest_subtitle, gate_subtitle]:
		if label:
			label.add_theme_color_override("font_color", secondary)


func _animate_entrance():
	var reduce_motion = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false)
	if reduce_motion or not title_label:
		return
	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	tween.finished.connect(func(): tween.kill())


func _setup_focus_navigation():
	# Horizontal chain with wrapping: Shop <-> QuestGiver <-> LeaveTown
	shop_button.set("focus_neighbor_right", quest_giver_button.get_path())
	shop_button.set("focus_neighbor_left", leave_town_button.get_path())

	quest_giver_button.set("focus_neighbor_left", shop_button.get_path())
	quest_giver_button.set("focus_neighbor_right", leave_town_button.get_path())

	leave_town_button.set("focus_neighbor_left", quest_giver_button.get_path())
	leave_town_button.set("focus_neighbor_right", shop_button.get_path())

	shop_button.grab_focus()


func _on_shop_pressed():
	print("Shop button pressed")
	var shop_dialog = preload("res://scenes/ui/shop_dialog.tscn").instantiate()
	add_child(shop_dialog)
	shop_dialog.tree_exited.connect(func(): shop_button.grab_focus())


func _on_quest_giver_pressed():
	print("Quest giver button pressed")
	var dialogue_scene = preload("res://scenes/ui/dialogue_scene.tscn").instantiate()
	add_child(dialogue_scene)
	dialogue_scene.start_dialogue("quest_giver")
	dialogue_scene.tree_exited.connect(func(): quest_giver_button.grab_focus())


func _on_leave_town_pressed():
	print("Leave town button pressed")
	GameManager.change_scene("world_map")
