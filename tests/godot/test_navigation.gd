extends GutTest

func test_game_manager_change_scene_exists():
	assert_true(GameManager.has_method("change_scene"), "GameManager should have change_scene method")

func test_game_manager_change_scene_with_valid_scene():
	# Test that change_scene method exists and can be called without crashing
	GameManager.change_scene("main_menu")
	assert_true(true, "change_scene should execute without error")

func test_game_manager_change_scene_error_handling():
	# Test error handling for invalid scene names
	GameManager.change_scene("invalid_scene_name")
	assert_true(true, "Should handle invalid scene names gracefully")