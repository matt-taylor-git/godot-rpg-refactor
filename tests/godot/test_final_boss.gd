extends GutTest

# Test Final Boss system functionality

func test_final_boss_creation():
	var boss = MonsterFactory.create_final_boss(1)
	assert_not_null(boss)
	assert_is(boss, FinalBoss)
	assert_eq(boss.name, "Dark Overlord")

func test_boss_stats_scale_with_level():
	var boss_level1 = MonsterFactory.create_final_boss(1)
	var boss_level5 = MonsterFactory.create_final_boss(5)
	var boss_level10 = MonsterFactory.create_final_boss(10)
	
	assert_lt(boss_level1.max_health, boss_level5.max_health)
	assert_lt(boss_level5.max_health, boss_level10.max_health)
	assert_lt(boss_level1.attack, boss_level5.attack)
	assert_lt(boss_level5.attack, boss_level10.attack)

func test_boss_starts_in_phase_1():
	var boss = MonsterFactory.create_final_boss(1)
	assert_eq(boss.current_phase, 1)

func test_phase_transition_at_75_percent():
	var boss = MonsterFactory.create_final_boss(1)
	var transition_health = int(boss.max_health * 0.75) - 1
	
	boss.health = transition_health
	var transitioned = boss.check_phase_transition()
	
	assert_true(transitioned)
	assert_eq(boss.current_phase, 2)

func test_phase_transition_at_50_percent():
	var boss = MonsterFactory.create_final_boss(1)
	# Jump to phase 2 first
	boss.current_phase = 2
	
	var transition_health = int(boss.max_health * 0.50) - 1
	boss.health = transition_health
	var transitioned = boss.check_phase_transition()
	
	assert_true(transitioned)
	assert_eq(boss.current_phase, 3)

func test_phase_transition_at_25_percent():
	var boss = MonsterFactory.create_final_boss(1)
	# Jump to phase 3 first
	boss.current_phase = 3
	
	var transition_health = int(boss.max_health * 0.25) - 1
	boss.health = transition_health
	var transitioned = boss.check_phase_transition()
	
	assert_true(transitioned)
	assert_eq(boss.current_phase, 4)

func test_no_transition_above_threshold():
	var boss = MonsterFactory.create_final_boss(1)
	var health_above_threshold = int(boss.max_health * 0.76)
	
	boss.health = health_above_threshold
	var transitioned = boss.check_phase_transition()
	
	assert_false(transitioned)
	assert_eq(boss.current_phase, 1)

func test_no_transition_in_final_phase():
	var boss = MonsterFactory.create_final_boss(1)
	boss.current_phase = 4
	boss.health = 1
	
	var transitioned = boss.check_phase_transition()
	assert_false(transitioned)
	assert_eq(boss.current_phase, 4)

func test_phase_data_exists_for_all_phases():
	var boss = MonsterFactory.create_final_boss(1)
	for phase in range(1, 5):
		boss.current_phase = phase
		var data = boss.get_current_phase_data()
		assert_not_empty(data)
		assert_true(data.has("attack_multiplier"))
		assert_true(data.has("defense_bonus"))
		assert_true(data.has("attacks_per_turn"))
		assert_true(data.has("ability_chance"))

func test_phase_difficulty_escalates():
	var boss = MonsterFactory.create_final_boss(1)
	
	var phase1_data = boss.phase_data[0]
	var phase2_data = boss.phase_data[1]
	var phase3_data = boss.phase_data[2]
	var phase4_data = boss.phase_data[3]
	
	assert_lt(phase1_data.attack_multiplier, phase2_data.attack_multiplier)
	assert_lt(phase2_data.attack_multiplier, phase3_data.attack_multiplier)
	assert_lt(phase3_data.attack_multiplier, phase4_data.attack_multiplier)
	
	assert_lt(phase1_data.ability_chance, phase2_data.ability_chance)
	assert_lt(phase2_data.ability_chance, phase3_data.ability_chance)

func test_special_abilities_available_by_phase():
	var boss = MonsterFactory.create_final_boss(1)
	
	# Phase 1: Only power strike
	boss.current_phase = 1
	var phase1_abilities = ["power_strike"]
	
	# Phase 2: Power strike + dark curse
	boss.current_phase = 2
	var phase2_abilities = ["power_strike", "dark_curse"]
	
	# Phase 3: Previous + whirlwind
	boss.current_phase = 3
	var phase3_abilities = ["power_strike", "dark_curse", "whirlwind"]
	
	# Phase 4: All abilities
	boss.current_phase = 4
	var phase4_abilities = ["power_strike", "dark_curse", "whirlwind", "last_stand", "realm_collapse"]

func test_get_ability_for_phase_returns_valid_ability():
	var boss = MonsterFactory.create_final_boss(1)
	
	for phase in range(1, 5):
		boss.current_phase = phase
		var ability = boss.get_ability_for_phase()
		assert_not_empty(ability)

func test_boss_ai_action_selection():
	var boss = MonsterFactory.create_final_boss(1)
	
	# Test multiple times to account for randomness
	var actions_seen = {}
	for i in range(100):
		boss.current_phase = 1
		var action = boss.get_ai_action()
		if not actions_seen.has(action):
			actions_seen[action] = 0
		actions_seen[action] += 1
	
	# Should see attack and at least one ability
	assert_true(actions_seen.has("attack"))

func test_boss_takes_damage():
	var boss = MonsterFactory.create_final_boss(1)
	var initial_health = boss.health
	boss.take_damage(10)
	assert_eq(boss.health, initial_health - 10)

func test_boss_is_alive_when_healthy():
	var boss = MonsterFactory.create_final_boss(1)
	boss.health = 50
	assert_true(boss.is_alive())

func test_boss_dies_at_zero_health():
	var boss = MonsterFactory.create_final_boss(1)
	boss.health = 0
	assert_false(boss.is_alive())

func test_boss_serialization():
	var boss = MonsterFactory.create_final_boss(1)
	boss.current_phase = 3
	boss.health = 100
	
	var dict = boss.to_dict()
	assert_eq(dict.current_phase, 3)
	assert_true(dict.is_final_boss)

func test_boss_deserialization():
	var boss = MonsterFactory.create_final_boss(1)
	var data = {
		"name": "Dark Overlord",
		"level": 5,
		"health": 200,
		"max_health": 500,
		"attack": 20,
		"defense": 10,
		"dexterity": 5,
		"current_phase": 2,
		"turns_in_phase": 5
	}
	
	boss.from_dict(data)
	assert_eq(boss.current_phase, 2)
	assert_eq(boss.turns_in_phase, 5)

func test_game_manager_start_boss_combat():
	# Setup player
	GameManager.new_game("TestHero", "Hero")
	
	var result = GameManager.start_boss_combat(1)
	assert_not_empty(result)
	assert_true(GameManager.in_combat)
	assert_true(GameManager.is_boss_combat())

func test_game_manager_get_boss_phase():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_boss_combat(1)
	
	var phase = GameManager.get_boss_phase()
	assert_eq(phase, 1)

func test_game_manager_not_boss_combat_for_regular_monster():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_combat()
	
	assert_false(GameManager.is_boss_combat())
	assert_eq(GameManager.get_boss_phase(), -1)

func test_boss_phase_transitions_during_combat():
	GameManager.new_game("TestHero", "Hero")
	GameManager.start_boss_combat(1)
	
	var boss = GameManager.get_current_monster() as FinalBoss
	assert_eq(boss.current_phase, 1)
	
	# Damage boss to phase 2 threshold
	boss.health = int(boss.max_health * 0.74)
	GameManager.player_attack()
	
	assert_eq(boss.current_phase, 2)

func test_boss_combat_rewards():
	GameManager.new_game("TestHero", "Hero")
	var initial_exp = GameManager.game_data.player.experience
	var initial_gold = GameManager.game_data.player.gold
	
	GameManager.start_boss_combat(1)
	var boss = GameManager.get_current_monster()
	boss.health = 0
	
	GameManager.player_attack()
	
	# Should get significantly more rewards than regular combat
	assert_gt(GameManager.game_data.player.experience, initial_exp)
	assert_gt(GameManager.game_data.player.gold, initial_gold)

func test_boss_is_significantly_stronger_than_regular_monster():
	var regular_monster = MonsterFactory.create_monster("orc", 5)
	var boss = MonsterFactory.create_final_boss(5)
	
	assert_gt(boss.max_health, regular_monster.max_health * 1.2)
	assert_gt(boss.attack, regular_monster.attack * 1.2)
	assert_gt(boss.experience_reward, regular_monster.experience_reward)

func test_boss_damage_calculation_with_multipliers():
	var boss = MonsterFactory.create_final_boss(1)
	
	# Phase 1: 1.0x multiplier
	boss.current_phase = 1
	var phase1_data = boss.get_current_phase_data()
	assert_eq(phase1_data.attack_multiplier, 1.0)
	
	# Phase 4: 2.0x multiplier
	boss.current_phase = 4
	var phase4_data = boss.get_current_phase_data()
	assert_eq(phase4_data.attack_multiplier, 2.0)
