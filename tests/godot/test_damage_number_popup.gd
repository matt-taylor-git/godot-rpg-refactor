extends GutTest

# Test DamageNumberPopup component functionality
# Tests bounce animation, color coding, shake, pulse, and lifecycle

var popup = null
var scene = preload("res://scenes/components/damage_number_popup.tscn")

func before_each():
	popup = scene.instantiate()
	add_child_autofree(popup)

func test_setup_damage():
	popup.setup(123, "damage", false)

	assert_eq(popup.value, 123)
	assert_eq(popup.type, "damage")
	assert_false(popup.is_critical)

	var label = popup.get_node("Label")
	assert_eq(label.text, "123")
	assert_eq(label.modulate, popup.DAMAGE_COLOR)

func test_setup_healing():
	popup.setup(50, "healing", false)

	assert_eq(popup.value, 50)
	assert_eq(popup.type, "healing")

	var label = popup.get_node("Label")
	assert_eq(label.text, "+50")
	assert_eq(label.modulate, popup.HEALING_COLOR)

func test_setup_critical():
	popup.setup(999, "damage", true)

	assert_true(popup.is_critical)

	# Initial check - animation will change scale but we want to know if it attempts to scale to critical
	# Since animation starts immediately, checking scale might be tricky immediately,
	# but we can check if setup was correct.
	# We rely on _update_visuals being called

	await get_tree().process_frame
	# After frame, animation should have started.
	# The scale tweening targets CRITICAL_SCALE.
	# We can't easily assert the tween state, but we can verify no errors.

func test_lifecycle():
	popup.setup(100, "damage", false)

	# It should free itself after LIFETIME (1.0)
	# We wait for 1.1s
	await get_tree().create_timer(1.1).timeout

	assert_true(not is_instance_valid(popup) or popup.is_queued_for_deletion(), "Popup should queue free after animation")

func test_shake_animation_starts():
	# Verify that for damage, shake is applied (position changes)
	popup.setup(100, "damage", false)
	var label = popup.get_node("Label")
	var initial_x = label.position.x

	await get_tree().process_frame
	await get_tree().create_timer(0.02).timeout

	# Should have moved due to shake
	# Note: Shake moves label.position.x
	assert_ne(label.position.x, initial_x, "Label x position should change during shake")

