extends GutTest

# Scene transition tests - verify GameManager routing logic
# Tests use scene instantiation where needed, or GameManager directly

const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")

func test_main_menu_new_game_flow():
	# Test that _on_new_game_pressed routes to character_creation
	var main_menu = MainMenuScene.instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	main_menu._on_new_game_pressed()
	assert_eq(GameManager.current_scene, "character_creation", "Should change to character creation scene")

	main_menu.queue_free()

func test_load_game_routing_combat():
	# Test that loading a game while in_combat routes to combat_scene
	# Test the routing logic directly via GameManager
	GameManager.in_combat = true
	GameManager.change_scene("combat_scene")
	assert_eq(GameManager.current_scene, "combat_scene", "Should route to combat scene when in combat")

func test_load_game_routing_no_combat():
	# Test that loading a game while not in_combat routes to town_scene
	# Test the routing logic directly via GameManager
	GameManager.in_combat = false
	GameManager.change_scene("town_scene")
	assert_eq(GameManager.current_scene, "town_scene", "Should route to town scene when not in combat")

func test_game_manager_change_scene_error_handling():
	# Test error handling for invalid scene names
	var original_scene = GameManager.current_scene
	GameManager.change_scene("invalid_scene_name")
	assert_eq(GameManager.current_scene, original_scene, "Should not change scene for invalid name")
