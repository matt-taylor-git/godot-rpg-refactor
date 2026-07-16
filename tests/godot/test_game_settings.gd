extends GutTest

# Tests for GameSettings persistence and ProjectSettings application


func before_each():
	# Isolate tests from real user settings
	GameSettings.set_reduced_motion(false)
	GameSettings.save_settings()


func test_default_reduced_motion_false():
	GameSettings.load_settings()
	assert_false(GameSettings.get_reduced_motion(), "Default reduced motion should be false")


func test_set_and_get_reduced_motion():
	GameSettings.set_reduced_motion(true)
	assert_true(GameSettings.get_reduced_motion(), "Should return true after set")
	assert_true(
		ProjectSettings.get_setting("accessibility/reduced_motion", false),
		"ProjectSettings should mirror reduced motion"
	)


func test_save_and_reload_persistence():
	GameSettings.set_reduced_motion(true)
	GameSettings.save_settings()
	GameSettings.set_reduced_motion(false)
	GameSettings.load_settings()
	assert_true(GameSettings.get_reduced_motion(), "Saved true should reload as true")
	# Cleanup
	GameSettings.set_reduced_motion(false)
	GameSettings.save_settings()


func test_apply_false_to_project_settings():
	GameSettings.set_reduced_motion(true)
	GameSettings.set_reduced_motion(false)
	assert_false(
		ProjectSettings.get_setting("accessibility/reduced_motion", true),
		"ProjectSettings should be false when setting is false"
	)
