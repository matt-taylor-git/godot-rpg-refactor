extends SceneTree

# Test combat scene with UIProgressBar integration
func _init():
	print("Testing Combat Scene with UIProgressBar integration...")

	# Load the combat scene
	var combat_scene = load("res://scenes/ui/combat_scene.tscn").instantiate()

	# Add to scene tree
	var root = get_root()
	root.add_child(combat_scene)

	# Wait for scene to initialize
	await create_timer(0.1).timeout

	# Check if UIProgressBar components exist
	var player_health_bar = combat_scene.get_node_or_null("MainContainer/InfoPanel/PlayerInfo/VBoxContainer/PlayerHealthBar")
	var monster_health_bar = combat_scene.get_node_or_null("MainContainer/InfoPanel/MonsterInfo/VBoxContainer/MonsterHealthBar")

	if player_health_bar:
		print("PlayerHealthBar found - Type: ", player_health_bar.get_class())
		print("Has set_value_animated method: ", player_health_bar.has_method("set_value_animated"))
	else:
		print("PlayerHealthBar not found!")

	if monster_health_bar:
		print("MonsterHealthBar found - Type: ", monster_health_bar.get_class())
		print("Has set_value_animated method: ", monster_health_bar.has_method("set_value_animated"))
	else:
		print("MonsterHealthBar not found!")

	# Test basic functionality
	if player_health_bar and player_health_bar.has_method("set_value_animated"):
		player_health_bar.max_value = 100
		player_health_bar.set_value_animated(75, false)  # No animation for test
		print("Player health bar value set to: ", player_health_bar.value)

	if monster_health_bar and monster_health_bar.has_method("set_value_animated"):
		monster_health_bar.max_value = 50
		monster_health_bar.set_value_animated(25, false)  # No animation for test
		print("Monster health bar value set to: ", monster_health_bar.value)

	print("Combat scene integration test completed!")
	combat_scene.queue_free()
	quit()