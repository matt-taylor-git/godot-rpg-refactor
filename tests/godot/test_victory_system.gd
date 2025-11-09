extends GutTest

# Test Victory System functionality

func test_victory_signal_emits_on_boss_defeat():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_boss_combat(1)
	
	var signal_fired = false
	GameManager.game_victory.connect(func(): signal_fired = true)
	
	GameManager.trigger_victory()
	assert_true(signal_fired)

func test_statistics_tracking_enemies_defeated():
	GameManager.new_game("TestHero", "Hero")
	assert_eq(GameManager.get_enemies_defeated(), 0)
	
	# Start and win combat
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	monster.health = 0
	GameManager.player_attack()
	
	assert_eq(GameManager.get_enemies_defeated(), 1)

func test_statistics_tracking_gold_earned():
	GameManager.new_game("TestHero", "Hero")
	var initial_gold = GameManager.get_gold_earned()
	assert_eq(initial_gold, 0)
	
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	monster.health = 0
	GameManager.player_attack()
	
	assert_gt(GameManager.get_gold_earned(), initial_gold)

func test_statistics_multiple_enemies():
	GameManager.new_game("TestHero", "Hero")
	
	# First combat
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	monster.health = 0
	GameManager.player_attack()
	assert_eq(GameManager.get_enemies_defeated(), 1)
	GameManager.end_combat()
	
	# Second combat
	GameManager.start_combat()
	monster = GameManager.get_current_monster()
	monster.health = 0
	GameManager.player_attack()
	assert_eq(GameManager.get_enemies_defeated(), 2)

func test_statistics_playtime():
	GameManager.new_game("TestHero", "Hero")
	var playtime = GameManager.get_playtime_minutes()
	assert_gte(playtime, 0)

func test_statistics_deaths_tracking():
	GameManager.new_game("TestHero", "Hero")
	assert_eq(GameManager.get_deaths(), 0)
	
	# Set player health to 1 and have monster attack
	GameManager.start_combat()
	GameManager.get_player().health = 1
	GameManager.monster_attack()
	
	if GameManager.get_player().health <= 0:
		assert_eq(GameManager.get_deaths(), 1)

func test_statistics_reset_on_new_game():
	GameManager.new_game("TestHero", "Hero")
	
	# Win some combats
	for i in range(3):
		GameManager.start_combat()
		var monster = GameManager.get_current_monster()
		monster.health = 0
		GameManager.player_attack()
		GameManager.end_combat()
	
	assert_eq(GameManager.get_enemies_defeated(), 3)
	
	# Start new game
	GameManager.new_game("NewHero", "Warrior")
	assert_eq(GameManager.get_enemies_defeated(), 0)

func test_quests_completed_setter():
	GameManager.new_game("TestHero", "Hero")
	assert_eq(GameManager.get_quests_completed(), 0)
	
	GameManager.set_quests_completed(5)
	assert_eq(GameManager.get_quests_completed(), 5)

func test_all_statistics_gathered():
	GameManager.new_game("TestHero", "Hero")
	
	# Complete some actions
	for i in range(2):
		GameManager.start_combat()
		var monster = GameManager.get_current_monster()
		monster.health = 0
		GameManager.player_attack()
		GameManager.end_combat()
	
	GameManager.set_quests_completed(3)
	
	# Verify all stats are accessible
	var level = GameManager.get_player().level
	var playtime = GameManager.get_playtime_minutes()
	var enemies = GameManager.get_enemies_defeated()
	var deaths = GameManager.get_deaths()
	var gold = GameManager.get_gold_earned()
	var quests = GameManager.get_quests_completed()
	
	assert_gte(level, 1)
	assert_gte(playtime, 0)
	assert_eq(enemies, 2)
	assert_eq(deaths, 0)
	assert_gt(gold, 0)
	assert_eq(quests, 3)

func test_boss_victory_tracking():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_boss_combat(1)
	
	# Defeat the boss
	var boss = GameManager.get_current_monster() as FinalBoss
	assert_not_null(boss)
	
	boss.health = 0
	GameManager.player_attack()
	
	assert_eq(GameManager.get_enemies_defeated(), 1)
	assert_gt(GameManager.get_gold_earned(), 0)

func test_combat_log_includes_rewards():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_combat()
	
	var monster = GameManager.get_current_monster()
	var initial_log = GameManager.get_combat_log()
	
	monster.health = 0
	GameManager.player_attack()
	
	var final_log = GameManager.get_combat_log()
	assert_true("Gained" in final_log or "gold" in final_log or "EXP" in final_log)

func test_statistics_survive_resets():
	GameManager.new_game("TestHero", "Hero")
	
	# Win combat
	GameManager.start_combat()
	GameManager.get_current_monster().health = 0
	GameManager.player_attack()
	GameManager.end_combat()
	
	var enemies_before = GameManager.get_enemies_defeated()
	
	# Clear combat state but keep game active
	GameManager.current_monster = null
	GameManager.in_combat = false
	
	# Stats should persist
	assert_eq(GameManager.get_enemies_defeated(), enemies_before)

func test_victory_scene_exists():
	# Check that victory scene is properly defined
	assert_true(ResourceLoader.exists("res://scenes/ui/victory_scene.tscn"))

func test_victory_statistics_completeness():
	GameManager.new_game("TestHero", "Warrior")
	
	# Engage in combat and get experience/gold
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()
	var initial_exp = GameManager.get_player().experience
	var initial_gold = GameManager.get_player().gold
	
	monster.health = 0
	GameManager.player_attack()
	
	# Check that both player and statistics track the same resources
	assert_gt(GameManager.get_player().gold, initial_gold)
	assert_gt(GameManager.get_gold_earned(), 0)
	assert_gt(GameManager.get_player().experience, initial_exp)

func test_boss_specific_victory():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_boss_combat(1)
	
	assert_true(GameManager.is_boss_combat())
	
	var boss = GameManager.get_current_monster() as FinalBoss
	assert_not_null(boss)
	assert_eq(boss.name, "Dark Overlord")
	
	# Defeat the boss
	boss.health = 0
	GameManager.player_attack()
	
	# Boss should count as enemy defeat
	assert_eq(GameManager.get_enemies_defeated(), 1)
