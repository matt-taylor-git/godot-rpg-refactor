extends Control

# WorldMap - A simple world map for navigating between locations

func _on_town_pressed():
    print("Town button pressed")
    GameManager.go_to_town()

func _on_forest_pressed():
    print("Forest button pressed")
    GameManager.go_to_exploration()
