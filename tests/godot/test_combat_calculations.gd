extends GutTest

func test_damage_calculation_basic():
	# Test basic damage calculation
	GameManager.new_game("TestHero")

	# Start combat to get a monster
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	assert_not_null(monster, "Should have a monster for testing")

	# Get initial health
	var initial_monster_health = monster.health

	# Player attack
	var attack_result = GameManager.player_attack()

	# Monster should take damage
	assert_lt(monster.health, initial_monster_health, "Monster should take damage")
	assert_gt(monster.health, 0, "Monster should not be dead yet")
	assert_true(attack_result.length() > 0, "Should return attack message")

func test_damage_calculation_formula():
	# Test that damage follows expected formula
	GameManager.new_game("TestHero")

	# Create a predictable scenario
	var player = GameManager.get_player()
	player.attack = 10
	player.level = 1

	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	monster.defense = 0  # No defense for predictable calculation

	var initial_health = monster.health

	# Attack and check damage range
	GameManager.player_attack()
	var damage_taken = initial_health - monster.health

	# Damage should be base_damage * level_multiplier - defense + variance
	# With attack=10, level=1, defense=0: 10 * 1.0 - 0 = 10, ±10%
	assert_gt(damage_taken, 8, "Damage should be at least 90% of base")
	assert_lt(damage_taken, 12, "Damage should be at most 110% of base")

func test_critical_hit_mechanics():
	# Test critical hit system
	GameManager.new_game("TestHero")

	var player = GameManager.get_player()
	player.dexterity = 100  # Very high dexterity for guaranteed crit

	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	var initial_health = monster.health

	# Attack - should be critical
	var attack_result = GameManager.player_attack()

	assert_true(attack_result.contains("CRITICAL"), "High dexterity should trigger critical hit")
	assert_lt(monster.health, initial_health, "Critical should still deal damage")

func test_monster_attack_damage():
	GameManager.new_game("TestHero")

	var player = GameManager.get_player()
	var initial_player_health = player.health

	GameManager.start_combat()
	var monster = GameManager.get_current_monster()

	# Monster attack
	var attack_result = GameManager.monster_attack()

	assert_lt(player.health, initial_player_health, "Player should take damage")
	assert_true(attack_result.contains("attacks"), "Should return monster attack message")

func test_combat_victory():
	GameManager.new_game("TestHero")

	# Create a very weak monster
	var weak_monster = Monster.new()
	weak_monster.name = "Weakling"
	weak_monster.level = 1
	weak_monster.health = 1
	weak_monster.max_health = 1
	weak_monster.attack = 1
	weak_monster.defense = 0
	weak_monster.experience_reward = 10
	weak_monster.gold_reward = 10

	GameManager.current_monster = weak_monster
	GameManager.in_combat = true

	# Player attack should kill monster
	var attack_result = GameManager.player_attack()

	assert_true(attack_result.contains("defeated"), "Should defeat weak monster")
	assert_false(GameManager.in_combat, "Combat should end on victory")

	# Check rewards
	var player = GameManager.get_player()
	assert_eq(player.experience, 10, "Should gain experience")
	assert_eq(player.gold, 110, "Should gain gold (100 + 10)")

func test_combat_defeat():
	GameManager.new_game("TestHero")

	var player = GameManager.get_player()
	player.health = 1  # Almost dead

	# Create a strong monster
	var strong_monster = Monster.new()
	strong_monster.name = "Boss"
	strong_monster.level = 10
	strong_monster.health = 100
	strong_monster.max_health = 100
	strong_monster.attack = 200  # Very high damage
	strong_monster.defense = 0

	GameManager.current_monster = strong_monster
	GameManager.in_combat = true

	# Monster attack should kill player
	var attack_result = GameManager.monster_attack()

	assert_true(attack_result.contains("defeated"), "Should defeat player")
	assert_false(GameManager.in_combat, "Combat should end on defeat")
	assert_eq(player.health, 0, "Player should be dead")

func test_skill_usage():
	GameManager.new_game("TestHero", "Mage")  # Mage has skills

	var player = GameManager.get_player()
	assert_gt(player.skills.size(), 0, "Mage should have skills")

	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	var initial_monster_health = monster.health

	# Use first skill
	var skill_result = GameManager.player_use_skill(0)

	# Should either succeed or fail with appropriate message
	assert_true(skill_result.length() > 0, "Should return skill usage result")

	# If skill was damage type, monster should take damage
	if skill_result.contains("damage"):
		assert_lt(monster.health, initial_monster_health, "Damage skill should hurt monster")
