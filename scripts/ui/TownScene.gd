extends Control

# TownScene - The central hub of the game

func _on_shop_pressed():
    print("Shop button pressed")
    var shop_dialog = preload("res://scenes/ui/shop_dialog.tscn").instantiate()
    add_child(shop_dialog)

func _on_quest_giver_pressed():
    print("Quest giver button pressed")
    var dialogue_scene = preload("res://scenes/ui/dialogue_scene.tscn").instantiate()
    add_child(dialogue_scene)
    dialogue_scene.start_dialogue("quest_giver")

func _on_leave_town_pressed():
    print("Leave town button pressed")
    	GameManager.change_scene("world_map")
