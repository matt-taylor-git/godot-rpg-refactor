extends Control

# TownScene - The central hub of the game

@onready var shop_button = $VBoxContainer/HBoxContainer/ShopButton
@onready var quest_giver_button = $VBoxContainer/HBoxContainer/QuestGiverButton
@onready var leave_town_button = $VBoxContainer/HBoxContainer/LeaveTownButton

func _ready():
	_setup_focus_navigation()

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
