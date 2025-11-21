extends SceneTree

# Simple test script to verify UIProgressBar works
func _init():
	var progress_bar = load("res://scripts/components/UIProgressBar.gd").new()

	# Test basic instantiation
	print("UIProgressBar instantiated successfully")
	print("Max value: ", progress_bar.max_value)
	print("Current value: ", progress_bar.value)
	print("Show value text: ", progress_bar.show_value_text)

	# Test value setting
	progress_bar.max_value = 100
	progress_bar.value = 75
	print("After setting value to 75: ", progress_bar.value)

	# Test animated value change
	progress_bar.set_value_animated(50.0, false)  # No animation for test
	print("After animated change to 50: ", progress_bar.value)

	# Test status effect
	progress_bar.add_status_effect_overlay("poison")
	print("Added poison effect")

	# Clean up
	progress_bar.queue_free()

	print("UIProgressBar basic test completed successfully")
	quit()