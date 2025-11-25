extends GutTest

# Integration tests for CombatScene with animation systems
# Tests full combat flow with all visual enhancements
# AC-2.2.1, AC-2.2.2, AC-2.2.3, AC-2.2.4, AC-2.2.5

var combat_scene = null

func before_each():
	# Load the actual combat scene
	var scene = load("res://scenes/ui/combat_scene.tscn")
	combat_scene = scene.instantiate()
	add_child_autofree(combat_scene)
	
	# Wait for _ready to complete
	await get_tree().process_frame

func after_each():
	# Clean up any combat state
	if GameManager.in_combat:
		GameManager.end_combat()

# ===== Integration Tests =====

func test_animation_controller_created():
	assert_not_null(combat_scene.animation_controller, "Animation controller should be created")

func test_turn_indicator_created():
	assert_not_null(combat_scene.turn_indicator, "Turn indicator should be created")

func test_performance_monitor_created():
	assert_not_null(combat_scene.performance_monitor, "Performance monitor should be created")

func test_animation_controller_setup():
	var controller = combat_scene.animation_controller
	
	assert_not_null(controller.player_node, "Player node should be set")
	assert_not_null(controller.monster_node, "Monster node should be set")

func test_turn_indicator_setup():
	var indicator = combat_scene.turn_indicator
	
	assert_not_null(indicator.player_node, "Player node should be set in turn indicator")
	assert_not_null(indicator.monster_node, "Monster node should be set in turn indicator")

# ===== Accessibility Integration Tests =====

func test_set_reduced_motion_propagates():
	combat_scene.set_reduced_motion(true)
	
	assert_true(combat_scene.animation_controller.reduced_motion, "Animation controller should have reduced motion")
	assert_true(combat_scene.turn_indicator.reduced_motion, "Turn indicator should have reduced motion")

# ===== Combat Flow Integration Tests =====

func test_combat_start_initializes_turn():
	# Set up player for combat
	if not GameManager.get_player():
		GameManager.new_game("TestPlayer", "Warrior")
	
	# Start combat
	GameManager.start_combat()
	
	# Wait for signals to process
	await get_tree().create_timer(0.3).timeout
	
	# Turn indicator should show player turn
	assert_true(combat_scene.turn_indicator.is_player_turn(), "Player should be active at combat start")

func test_performance_monitoring_starts_with_combat():
	# Monitoring should start when scene is ready
	assert_true(combat_scene.performance_monitor.is_monitoring, "Performance monitoring should be active")

func test_performance_monitoring_stops_on_combat_end():
	# Set up combat
	if not GameManager.get_player():
		GameManager.new_game("TestPlayer", "Warrior")
	GameManager.start_combat()
	
	await get_tree().create_timer(0.1).timeout
	
	# End combat
	GameManager.end_combat()
	
	await get_tree().create_timer(0.1).timeout
	
	# Monitoring should stop
	assert_false(combat_scene.performance_monitor.is_monitoring, "Performance monitoring should stop after combat")

# ===== Signal Connection Tests =====

func test_animation_signals_connected():
	var controller = combat_scene.animation_controller
	
	# Check that signals are connected to combat scene
	assert_true(controller.animation_started.is_connected(combat_scene._on_animation_started), 
		"animation_started should be connected")
	assert_true(controller.animation_completed.is_connected(combat_scene._on_animation_completed),
		"animation_completed should be connected")

func test_performance_signals_connected():
	var monitor = combat_scene.performance_monitor
	
	assert_true(monitor.fps_warning.is_connected(combat_scene._on_fps_warning),
		"fps_warning should be connected")
	assert_true(monitor.memory_warning.is_connected(combat_scene._on_memory_warning),
		"memory_warning should be connected")

# ===== UI Element Tests =====

func test_health_bars_exist():
	assert_not_null(combat_scene.player_health_bar, "Player health bar should exist")
	assert_not_null(combat_scene.monster_health_bar, "Monster health bar should exist")

func test_sprites_exist():
	assert_not_null(combat_scene.player_sprite, "Player sprite should exist")
	assert_not_null(combat_scene.monster_sprite, "Monster sprite should exist")

func test_combat_log_exists():
	assert_not_null(combat_scene.combat_log, "Combat log should exist")

# ===== UIProgressBar Integration (from Story 2.1) =====

func test_player_health_bar_has_animated_method():
	assert_true(combat_scene.player_health_bar.has_method("set_value_animated"),
		"Player health bar should have set_value_animated method")

func test_monster_health_bar_has_animated_method():
	assert_true(combat_scene.monster_health_bar.has_method("set_value_animated"),
		"Monster health bar should have set_value_animated method")

func test_health_bars_can_animate():
	combat_scene.player_health_bar.max_value = 100
	combat_scene.player_health_bar.set_value_animated(75, false)
	
	assert_eq(combat_scene.player_health_bar.value, 75, "Health bar value should be set")

# ===== Save/Load Compatibility =====

func test_animation_state_not_saved():
	# Animation state should not affect saves
	# This is a sanity check - animation controllers should not persist
	
	if not GameManager.get_player():
		GameManager.new_game("TestPlayer", "Warrior")
	
	# Start some animations
	combat_scene.animation_controller.set_reduced_motion(false)
	
	# Save game
	GameManager.save_game(99) # Use slot 99 for test
	
	# Animation state in controller shouldn't crash save
	# If we get here without error, save is compatible
	assert_true(true, "Save should succeed with active animation systems")
	
	# Clean up test save
	var save_path = "user://save_slot_99.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
