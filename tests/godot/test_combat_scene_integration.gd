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
	GameManager.combat_area_id = "forest"

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

func test_standard_combat_uses_current_exploration_area():
	GameManager.new_game("Area Tester", "Warrior")
	var exploration_state := GameManager.get_exploration_state().duplicate(true)
	exploration_state["current_area_id"] = "mountain"
	GameManager.set_exploration_state(exploration_state)
	GameManager.start_combat()
	assert_eq(GameManager.combat_area_id, "mountain")

func test_typed_combat_uses_explicit_area():
	GameManager.new_game("Area Tester", "Warrior")
	GameManager.start_combat_with_type("spider", 5, 1.0, 0.25, "cave")
	assert_eq(GameManager.combat_area_id, "cave")

func test_event_combat_uses_event_area():
	GameManager.new_game("Area Tester", "Warrior")
	var event := ExplorationEventFactory._generate_combat_event("peak", 8, 0.0)
	GameManager.start_combat_from_event(event, "forest")
	assert_eq(GameManager.combat_area_id, "peak")

func test_boss_combat_uses_peak_area():
	GameManager.new_game("Area Tester", "Warrior")
	GameManager.get_player().level = 8
	GameManager.start_boss_combat()
	assert_eq(GameManager.combat_area_id, "peak")

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
	assert_not_null(combat_scene.player_portrait, "Player portrait should exist")
	assert_not_null(combat_scene.monster_portrait, "Monster portrait should exist")

func test_combat_log_exists():
	assert_not_null(combat_scene.combat_log, "Combat log should exist")

func test_stage_background_exists():
	var bg = combat_scene.get_node_or_null("StageLayer/StageBackground")
	assert_not_null(bg, "Stage background TextureRect should exist")

func test_stage_background_matches_combat_area_for_every_known_area():
	var expected_paths := {
		"forest": "res://assets/combat/forest.png",
		"mountain": "res://assets/combat/mountain.png",
		"cave": "res://assets/combat/cave.png",
		"peak": "res://assets/combat/peak.png",
		# Town is safe — no dedicated combat art; uses forest arena.
		"town": "res://assets/combat/forest.png",
	}
	for area_id in expected_paths:
		GameManager.combat_area_id = area_id
		combat_scene._apply_stage_background()
		assert_eq(
			combat_scene.stage_background.texture.resource_path,
			expected_paths[area_id],
			"%s combat should use its combat battlefield background" % area_id,
		)

func test_stage_background_falls_back_to_forest_for_invalid_combat_area():
	for area_id in ["", "nonexistent"]:
		GameManager.combat_area_id = area_id
		combat_scene._apply_stage_background()
		assert_eq(
			combat_scene.stage_background.texture.resource_path,
			"res://assets/combat/forest.png",
			"Invalid combat areas should safely use the forest combat background",
		)

func test_action_dock_is_horizontal():
	assert_not_null(combat_scene.root_actions, "Root actions row should exist")
	assert_true(combat_scene.root_actions is HBoxContainer, "Actions should be horizontal dock")

func test_event_strip_exists():
	assert_not_null(combat_scene.event_label, "Latest event strip should exist")

func test_turn_banner_exists():
	assert_not_null(combat_scene.turn_banner, "Turn banner should exist")

func test_bottom_hud_stays_inside_persistent_ui_budget():
	var dock = combat_scene.get_node("MainColumn/DockLayer")
	assert_lte(dock.custom_minimum_size.y / 720.0, 0.23, "persistent HUD should stay within 23%")
	assert_eq(dock.custom_minimum_size.y, 162.0, "base combat dock uses the fixed layout budget")

func test_visible_figures_are_grounded_below_clear_playfield():
	combat_scene.player_stage.set_figure_texture(PortraitLookup.get_class_texture("Warrior"))
	combat_scene.monster_stage.set_figure_texture(PortraitLookup.get_monster_texture("wolf"))
	await get_tree().process_frame
	for stage in [combat_scene.player_stage, combat_scene.monster_stage]:
		var expected_ground: float = stage.global_position.y + stage.size.y
		assert_almost_eq(
			stage.get_ground_contact_y(),
			expected_ground,
			2.0,
			"opaque feet should meet the shared arena ground line",
		)
	var player_rect: Rect2 = combat_scene.player_stage.get_visible_figure_rect()
	var monster_rect: Rect2 = combat_scene.monster_stage.get_visible_figure_rect()
	var player_status_rect := Rect2(
		combat_scene.player_status.global_position,
		combat_scene.player_status.size,
	)
	var monster_status_rect := Rect2(
		combat_scene.monster_status.global_position,
		combat_scene.monster_status.size,
	)
	assert_false(player_rect.intersects(player_status_rect), "player HUD must not cover the player")
	assert_false(monster_rect.intersects(monster_status_rect), "enemy HUD must not cover the enemy")

func test_all_character_shapes_keep_the_same_ground_contact():
	var textures := [
		PortraitLookup.get_class_texture("Mage"),
		PortraitLookup.get_monster_texture("slime"),
		PortraitLookup.get_monster_texture("dragon"),
		PortraitLookup.get_monster_texture("final boss"),
	]
	for texture in textures:
		combat_scene.monster_stage.set_figure_texture(texture)
		await get_tree().process_frame
		var stage = combat_scene.monster_stage
		var expected_ground: float = stage.global_position.y + stage.size.y
		assert_almost_eq(
			stage.get_ground_contact_y(),
			expected_ground,
			2.0,
			"transparent padding and silhouette shape must not change grounding",
		)

func test_action_and_history_modes_do_not_move_the_battlefield():
	combat_scene.player_stage.set_figure_texture(PortraitLookup.get_class_texture("Warrior"))
	await get_tree().process_frame
	var arena_size: Vector2 = combat_scene.arena_layer.size
	var ground_y: float = combat_scene.player_stage.get_ground_contact_y()
	for mode in ["skills", "items", "root"]:
		combat_scene._set_dock_mode(mode)
		await get_tree().process_frame
		assert_eq(combat_scene.arena_layer.size, arena_size, "%s must not resize the arena" % mode)
		assert_almost_eq(
			combat_scene.player_stage.get_ground_contact_y(),
			ground_y,
			2.0,
			"%s must not move the ground line" % mode,
		)
	combat_scene._set_log_expanded(true)
	await get_tree().process_frame
	assert_eq(combat_scene.arena_layer.size, arena_size, "History overlay must not resize the arena")
	assert_almost_eq(
		combat_scene.player_stage.get_ground_contact_y(),
		ground_y,
		2.0,
		"History overlay must not move the ground line",
	)

func test_compact_layout_keeps_critical_status_surfaces_visible():
	combat_scene.size = Vector2(1000, 600)
	combat_scene._apply_responsive_layout()
	assert_true(combat_scene._compact_layout, "small windows should use compact combat layout")
	assert_eq(combat_scene.dock_layer.custom_minimum_size.y, 142.0)
	assert_true(combat_scene.player_status.visible, "player status remains visible in compact mode")
	assert_true(combat_scene.monster_status.visible, "enemy status remains visible in compact mode")
	assert_true(combat_scene.player_status.hp_value.visible, "numeric HP remains visible in compact mode")

func test_input_lock_disables_actions():
	combat_scene._set_input_locked(true)
	assert_true(combat_scene.attack_button.disabled, "Attack should disable when locked")
	combat_scene._set_input_locked(false)
	assert_false(combat_scene.attack_button.disabled, "Attack should enable when unlocked")

func test_boss_combat_keeps_root_action_labels_visible():
	GameManager.new_game("Boss UI", "Warrior")
	await GameManager.start_boss_combat(8)
	await get_tree().process_frame
	assert_eq(combat_scene.attack_card._title_label.text, "[1] ATTACK")
	assert_eq(combat_scene.skills_card._title_label.text, "[2] SKILLS")
	assert_eq(combat_scene.items_card._title_label.text, "[3] ITEMS")
	assert_eq(combat_scene.run_card._title_label.text, "[4] RUN")
	assert_true(combat_scene.attack_card._title_label.visible)
	assert_true(combat_scene.skills_card._title_label.visible)
	assert_true(combat_scene.items_card._title_label.visible)

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

func test_animation_state_and_combat_area_are_save_compatible():
	# Animation state should not affect saves
	# This is a sanity check - animation controllers should not persist

	if not GameManager.get_player():
		GameManager.new_game("TestPlayer", "Warrior")

	# Start some animations
	combat_scene.animation_controller.set_reduced_motion(false)
	GameManager.combat_area_id = "cave"

	# Save game
	assert_true(GameManager.save_game(99)) # Use slot 99 for test
	GameManager.combat_area_id = "forest"
	assert_true(GameManager.load_game(99))

	# Animation state is ignored while encounter context survives a resumed save.
	assert_eq(GameManager.combat_area_id, "cave")

	# Clean up test save
	var save_path = "user://save_slot_99.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
