extends Node

func _ready():
	var scene = load("res://scenes/ui/character_creation.tscn")
	if scene:
		var instance = scene.instantiate()
		print("✓ CharacterCreation scene loads successfully")
		instance.queue_free()
	else:
		print("✗ Failed to load scene")
	get_tree().quit()

