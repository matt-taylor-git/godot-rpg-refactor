extends GutTest

func test_game_initialization():
	# Test new_game creates valid player state
	GameManager.new_game("TestHero", "Warrior")

	var player = GameManager.get_player()
	assert_not_null(player, "Player should be created")
	assert_eq(player.name, "TestHero", "Player name should be set")
	assert_eq(player.character_class, "Warrior", "Player class should be set")
	assert_eq(player.level, 1, "Player should start at level 1")
	assert_gt(player.health, 0, "Player should have health")
	assert_eq(player.max_health, 100, "Player should have max health")

func test_character_class_stats():
	# Test different classes get correct base stats
	var test_cases = [
		{"class": "Hero", "expected_attack": 10, "expected_defense": 5},
		{"class": "Warrior", "expected_attack": 15, "expected_defense": 8},
		{"class": "Mage", "expected_attack": 8, "expected_defense": 4},
		{"class": "Rogue", "expected_attack": 10, "expected_defense": 5}
	]

	for test_case in test_cases:
		GameManager.new_game("TestHero", test_case["class"])
		var player = GameManager.get_player()

		assert_eq(player.attack, test_case["expected_attack"],
			"Class " + test_case["class"] + " should have correct attack")
		assert_eq(player.defense, test_case["expected_defense"],
			"Class " + test_case["class"] + " should have correct defense")

func test_combat_state_initialization():
	GameManager.new_game("TestHero")

	# Test initial combat state
	assert_false(GameManager.in_combat, "Should not be in combat initially")
	assert_null(GameManager.get_current_monster(), "Should have no current monster")
	assert_eq(GameManager.get_combat_log(), "", "Combat log should be empty")

func test_start_combat():
	GameManager.new_game("TestHero")

	var result = GameManager.start_combat()

	assert_true(GameManager.in_combat, "Should be in combat after start_combat")
	assert_not_null(GameManager.get_current_monster(), "Should have a monster")
	assert_true(result.length() > 0, "Should return combat start message")

func test_manager_state_persistence():
	GameManager.new_game("TestHero", "Warrior")

	# Simulate some game state changes
	GameManager.start_combat()
	var monster_before = GameManager.get_current_monster()

	# Force a save/load cycle
	GameManager.save_game(1)
	GameManager.load_game(1)

	var player_after = GameManager.get_player()
	assert_not_null(player_after, "Player should persist after load")
	assert_eq(player_after.name, "TestHero", "Player name should persist")
	assert_eq(player_after.character_class, "Warrior", "Player class should persist")

func test_playtime_tracking():
	var initial_time = GameManager.get_playtime_minutes()

	# Wait a bit
	await get_tree().create_timer(0.1).timeout

	var current_time = GameManager.get_playtime_minutes()
	assert_true(current_time >= initial_time, "Playtime should increase over time")
