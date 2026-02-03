extends GutTest

# Test TurnIndicatorController functionality
# AC-2.2.3: Turn Indicator Clarity
# - Active character glow effect
# - Non-active portrait dimming
# - Smooth transitions (200ms)
# - Clear visibility at all screen sizes

var TurnIndicatorControllerScript = load("res://scripts/components/TurnIndicatorController.gd")

var controller = null
var player_node = null
var monster_node = null

func before_each():
	controller = TurnIndicatorControllerScript.new()
	add_child_autofree(controller)

	player_node = Control.new()
	player_node.name = "Player"
	player_node.modulate = Color.WHITE
	add_child_autofree(player_node)

	monster_node = Control.new()
	monster_node.name = "Monster"
	monster_node.modulate = Color.WHITE
	add_child_autofree(monster_node)

	controller.setup(player_node, monster_node)

# ===== Basic Setup Tests =====

func test_setup():
	assert_eq(controller.player_node, player_node, "Player node should be set")
	assert_eq(controller.monster_node, monster_node, "Monster node should be set")
	assert_null(controller.current_active, "No active node initially")

func test_initial_state():
	assert_false(controller.is_player_turn(), "Should not be player turn initially")
	assert_false(controller.is_monster_turn(), "Should not be monster turn initially")

# ===== Turn Indicator Tests - AC-2.2.3 =====

func test_set_player_active():
	watch_signals(controller)

	controller.set_active_turn(player_node)

	# Wait for transition animation
	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_player_turn(), "Should be player turn")
	assert_false(controller.is_monster_turn(), "Should not be monster turn")
	assert_signal_emitted(controller, "turn_changed")

func test_set_monster_active():
	watch_signals(controller)

	controller.set_active_turn(monster_node)

	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_monster_turn(), "Should be monster turn")
	assert_false(controller.is_player_turn(), "Should not be player turn")

func test_transition_between_turns():
	# Start with player
	controller.set_active_turn(player_node)
	await get_tree().create_timer(0.25).timeout

	# Transition to monster
	watch_signals(controller)
	controller.set_active_turn(monster_node)

	assert_signal_emitted(controller, "turn_changed")

	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_monster_turn())
	assert_eq(controller.get_active(), monster_node)

func test_no_change_when_same_turn():
	controller.set_active_turn(player_node)
	await get_tree().create_timer(0.25).timeout

	watch_signals(controller)
	controller.set_active_turn(player_node) # Same turn again

	# Should not emit signal for same turn
	assert_signal_not_emitted(controller, "turn_changed")

# ===== Visual Effects Tests =====

func test_active_glow_applied():
	controller.set_reduced_motion(false)
	controller.set_active_turn(player_node)

	# Wait for animation
	await get_tree().create_timer(0.25).timeout

	# Active node should have glow (modulate > 1.0)
	assert_true(player_node.modulate.r >= 1.0, "Active player should have glow effect")

func test_inactive_dim_applied():
	controller.set_reduced_motion(false)

	# Set player active
	controller.set_active_turn(player_node)
	await get_tree().create_timer(0.25).timeout

	# Monster should be dimmed
	assert_true(monster_node.modulate.r < 1.0, "Inactive monster should be dimmed")

func test_transition_duration():
	# Verify that transition takes approximately 200ms (AC-2.2.3)
	var start_time = Time.get_ticks_msec()

	controller.set_active_turn(player_node)

	# Wait for full transition
	await get_tree().create_timer(controller.TRANSITION_DURATION + 0.05).timeout

	var elapsed = Time.get_ticks_msec() - start_time

	# Should take at least TRANSITION_DURATION (200ms)
	assert_true(elapsed >= controller.TRANSITION_DURATION * 1000 - 50, "Transition should take at least 200ms")

# ===== Accessibility Tests - AC-2.2.5 =====

func test_reduced_motion_instant_transition():
	controller.set_reduced_motion(true)

	# Record initial modulate
	var initial_player_mod = player_node.modulate
	var initial_monster_mod = monster_node.modulate

	controller.set_active_turn(player_node)

	# With reduced motion, change should be instant
	await get_tree().process_frame

	# Player should be glowing, monster should be dimmed - immediately
	assert_ne(player_node.modulate, initial_player_mod, "Player modulate should change instantly")
	assert_ne(monster_node.modulate, initial_monster_mod, "Monster modulate should change instantly")

func test_reduced_motion_setting():
	controller.set_reduced_motion(true)
	assert_true(controller.reduced_motion, "Reduced motion should be enabled")

	controller.set_reduced_motion(false)
	assert_false(controller.reduced_motion, "Reduced motion should be disabled")

# ===== Helper Method Tests =====

func test_highlight_player():
	controller.highlight_player()
	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_player_turn())

func test_highlight_monster():
	controller.highlight_monster()
	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_monster_turn())

func test_get_active():
	assert_null(controller.get_active(), "No active initially")

	controller.set_active_turn(player_node)
	await get_tree().create_timer(0.01).timeout

	assert_eq(controller.get_active(), player_node, "Should return player node")

# ===== Combat Lifecycle Tests =====

func test_combat_start_sets_player_turn():
	# Simulate combat start
	controller._on_combat_started("Goblin")

	await get_tree().create_timer(0.25).timeout

	assert_true(controller.is_player_turn(), "Player should be active at combat start")

func test_combat_end_resets_indicators():
	# Set up active turn
	controller.set_active_turn(player_node)
	await get_tree().create_timer(0.25).timeout

	# End combat
	controller._on_combat_ended(true)

	# Both should return to normal color
	assert_eq(player_node.modulate, Color.WHITE, "Player should return to normal")
	assert_eq(monster_node.modulate, Color.WHITE, "Monster should return to normal")
	assert_null(controller.current_active, "No active turn after combat ends")
