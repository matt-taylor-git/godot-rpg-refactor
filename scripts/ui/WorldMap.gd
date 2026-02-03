extends Control

# WorldMap - A simple world map for navigating between locations

@onready var town_button = $VBoxContainer/HBoxContainer/TownButton
@onready var forest_button = $VBoxContainer/HBoxContainer/ForestButton

func _ready():
	_setup_focus_navigation()

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
