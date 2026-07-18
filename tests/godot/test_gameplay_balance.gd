extends GutTest

const CLASS_STATS := {
	"Hero": {"attack": 12, "defense": 6, "dexterity": 6},
	"Warrior": {"attack": 15, "defense": 8, "dexterity": 4},
	"Mage": {"attack": 8, "defense": 4, "dexterity": 5},
	"Rogue": {"attack": 10, "defense": 5, "dexterity": 8},
}
const AREA_CASES := [
	{"area": "forest", "level": 1, "standard": "goblin"},
	{"area": "mountain", "level": 3, "standard": "skeleton"},
	{"area": "cave", "level": 5, "standard": "spider"},
	{"area": "peak", "level": 8, "standard": "orc"},
	{"area": "peak", "level": 10, "standard": "orc"},
]
const STRONG_CASES := [
	{"area": "forest", "level": 1, "monster": "wolf"},
	{"area": "mountain", "level": 3, "monster": "orc"},
	{"area": "cave", "level": 5, "monster": "skeleton"},
	{"area": "peak", "level": 8, "monster": "dragon"},
]


func test_combat_rules_formula_and_range_share_one_source() -> void:
	assert_eq(CombatRules.calculate_damage(20, 10), 15)
	assert_eq(CombatRules.calculate_damage(20, 10, 1.5, true), 40)
	var predicted := CombatRules.estimate_range(20, 10, 1.5)
	for _index in range(100):
		var rolled := CombatRules.roll_damage(20, 10, 1.5)
		assert_true(rolled >= predicted.min and rolled <= predicted.max)


func test_player_experience_curve_matches_tactical_normal_pacing() -> void:
	var player := Player.new()
	var thresholds := [0, 100, 230, 390, 580, 800, 1050, 1330]
	for level_index in range(thresholds.size()):
		assert_eq(player.get_exp_for_level(level_index + 1), thresholds[level_index])
	var samples := [
		{"level": 1, "average_xp": 13.33},
		{"level": 3, "average_xp": 23.0},
		{"level": 5, "average_xp": 29.0},
		{"level": 8, "average_xp": 58.67},
	]
	for sample in samples:
		var requirement := 100 + 30 * (int(sample.level) - 1)
		var fights := ceili(float(requirement) / float(sample.average_xp))
		assert_true(fights >= 5 and fights <= 8)


func test_area_bands_and_danger_rewards() -> void:
	assert_eq(ExplorationEventFactory.resolve_monster_level("forest", 8, 0.0), 2)
	assert_eq(ExplorationEventFactory.resolve_monster_level("mountain", 3, 20.0), 4)
	assert_eq(ExplorationEventFactory.resolve_monster_level("cave", 1, 0.0), 5)
	assert_eq(ExplorationEventFactory.resolve_monster_level("cave", 1, 20.0), 6)
	assert_eq(ExplorationEventFactory.resolve_monster_level("peak", 8, 20.0), 9)
	assert_eq(ExplorationEventFactory.get_combat_chance("forest", 0.0), 30.0)
	assert_eq(ExplorationEventFactory.get_combat_chance("forest", 20.0), 40.0)
	assert_eq(ExplorationEventFactory.get_reward_multiplier(10.0), 1.15)
	assert_eq(ExplorationEventFactory.get_reward_multiplier(20.0), 1.30)
	assert_eq(ExplorationEventFactory.get_loot_chance(20.0), 0.40)
	assert_eq(ExplorationEventFactory.get_strong_enemy_chance(0.0), 0.10)
	assert_eq(ExplorationEventFactory.get_strong_enemy_chance(20.0), 0.40)


func test_combat_events_include_balance_metadata() -> void:
	var event := ExplorationEventFactory._generate_combat_event("peak", 8, 20.0)
	assert_eq(event.monster_level, 9)
	assert_has(["weak", "medium", "strong"], event.monster_rank)
	assert_eq(event.danger_tier, "perilous")
	assert_eq(event.reward_multiplier, 1.30)
	assert_eq(event.loot_chance, 0.40)
	assert_eq(event.area_id, "peak")


func test_danger_changes_combat_and_strong_enemy_distribution() -> void:
	seed(71018)
	var low_combat := 0
	var high_combat := 0
	var sample_count := 4000
	for _index in range(sample_count):
		if ExplorationEventFactory.generate_event("forest", 1, 0.0).type == "combat":
			low_combat += 1
		if ExplorationEventFactory.generate_event("forest", 1, 20.0).type == "combat":
			high_combat += 1
	var low_rate := float(low_combat) / float(sample_count)
	var high_rate := float(high_combat) / float(sample_count)
	assert_true(low_rate > 0.27 and low_rate < 0.33)
	assert_true(high_rate > 0.37 and high_rate < 0.43)

	var low_strong := 0
	var high_strong := 0
	for _index in range(sample_count):
		if ExplorationEventFactory._generate_combat_event("forest", 1, 0.0).monster_type == "wolf":
			low_strong += 1
		if ExplorationEventFactory._generate_combat_event("forest", 1, 20.0).monster_type == "wolf":
			high_strong += 1
	assert_true(float(low_strong) / sample_count > 0.07)
	assert_true(float(low_strong) / sample_count < 0.13)
	assert_true(float(high_strong) / sample_count > 0.36)
	assert_true(float(high_strong) / sample_count < 0.44)


func test_standard_encounters_stay_inside_safe_combat_envelope() -> void:
	for area_case in AREA_CASES:
		var level: int = area_case.level
		var monster := MonsterFactory.create_monster(area_case.standard, level)
		for class_name_key in CLASS_STATS:
			var stats: Dictionary = CLASS_STATS[class_name_key]
			var player_attack: int = stats.attack + 2 * (level - 1)
			var player_defense: int = stats.defense + (level - 1)
			var player_health := 100 + 10 * (level - 1)
			var enemy_damage := CombatRules.calculate_damage(
				monster.attack, player_defense)
			assert_true(enemy_damage * 2 < player_health)
			var turns := _simulate_damage_turns(
				class_name_key, level, player_attack, monster)
			assert_true(
				turns >= 3 and turns <= 6,
				"%s level %d versus %s took %d turns" % [
					class_name_key, level, monster.name, turns],
			)


func test_seeded_encounters_cover_every_class_at_levels_1_3_5_8_and_10() -> void:
	seed(71018)
	for area_case in AREA_CASES:
		for class_name_key in CLASS_STATS:
			var turns: Array[int] = []
			var losses: Array[float] = []
			var wins := 0
			for _run in range(80):
				var result := _simulate_seeded_standard_fight(
					class_name_key, int(area_case.level), str(area_case.standard))
				turns.append(int(result.turns))
				losses.append(float(result.health_loss))
				wins += int(result.won)
			turns.sort()
			losses.sort()
			var median_turns: int = turns[turns.size() / 2]
			var median_loss: float = losses[losses.size() / 2]
			var label := "%s level %d" % [class_name_key, int(area_case.level)]
			assert_eq(wins, 80, "%s should win prepared standard encounters" % label)
			assert_true(
				median_turns >= 3 and median_turns <= 6,
				"%s median duration was %d turns" % [label, median_turns],
			)
			assert_true(
				median_loss >= 0.10 and median_loss <= 0.30,
				"%s median HP loss was %.1f%%" % [label, median_loss * 100.0],
			)


func test_seeded_strong_encounters_create_tactical_pressure() -> void:
	seed(81018)
	for area_case in STRONG_CASES:
		var turns: Array[int] = []
		var losses: Array[float] = []
		var wins := 0
		for class_name_key in CLASS_STATS:
			for _run in range(80):
				var result := _simulate_seeded_standard_fight(
					class_name_key,
					int(area_case.level),
					str(area_case.monster),
					"strong",
				)
				turns.append(int(result.turns))
				losses.append(float(result.health_loss))
				wins += int(result.won)
		turns.sort()
		losses.sort()
		var median_turns: int = turns[turns.size() / 2]
		var median_loss: float = losses[losses.size() / 2]
		var label := "level %d strong %s" % [
			int(area_case.level), str(area_case.monster)]
		assert_true(wins >= 288, "%s win count was %d/320" % [label, wins])
		assert_true(
			median_turns >= 5 and median_turns <= 8,
			"%s median duration was %d turns" % [label, median_turns],
		)
		assert_true(
			median_loss >= 0.25 and median_loss <= 0.55,
			"%s median HP loss was %.1f%%" % [label, median_loss * 100.0],
		)


func test_starting_kit_prices_and_scaling_consumables() -> void:
	GameManager.new_game("Balance Tester", "Mage")
	var player: Player = GameManager.get_player()
	assert_eq(player.gold, 100)
	assert_eq(_count_item(player, "health_potion"), 1)
	assert_eq(ItemFactory.create_item("sword").value, 75)
	assert_eq(ItemFactory.create_item("shield").defense_bonus, 5)
	player.max_health = 200
	player.health = 50
	ItemFactory.create_item("health_potion").use(player)
	assert_eq(player.health, 120)
	player.max_mana = 100
	player.mana = 10
	ItemFactory.create_item("mana_potion").use(player)
	assert_eq(player.mana, 50)


func test_area_loot_only_uses_valid_ids_and_tier_caps() -> void:
	seed(1807)
	for area_id in ["forest", "mountain", "cave", "peak"]:
		for _index in range(100):
			var item := ItemFactory.create_random_item_for_area(area_id)
			assert_has(["sword", "shield", "health_potion", "mana_potion"], item.item_id)
			assert_true(item.attack_bonus <= 8)
			assert_true(item.defense_bonus <= 8)


func test_defeat_preserves_progress_and_applies_capped_percentage_loss() -> void:
	GameManager.new_game("Defeat Tester", "Hero")
	var player: Player = GameManager.get_player()
	player.level = 5
	player.experience = 700
	player.gold = 900
	player.health = 0
	player.mana = 0
	player.add_status_effect("stealth", 2, {"defense_bonus": 20})
	player.equipment.weapon = ItemFactory.create_item("sword")
	player.skills[0].current_cooldown = 2
	GameManager.game_data.exploration_state = {
		"current_area_id": "peak", "danger_level": 25.0}
	var result := GameManager.resolve_defeat()
	assert_eq(result.gold_lost, 50)
	assert_eq(player.gold, 850)
	assert_eq(player.level, 5)
	assert_eq(player.experience, 700)
	assert_eq(player.equipment.weapon.item_id, "sword")
	assert_eq(player.health, player.max_health)
	assert_eq(player.mana, player.max_mana)
	assert_true(player.status_effects.is_empty())
	assert_eq(player.skills[0].current_cooldown, 0)
	assert_eq(GameManager.get_exploration_state().current_area_id, "town")
	assert_eq(GameManager.get_exploration_state().danger_level, 0.0)


func test_final_boss_curve_access_and_dark_curse() -> void:
	GameManager.new_game("Boss Tester", "Hero")
	var player: Player = GameManager.get_player()
	player.level = 7
	assert_false(GameManager.can_access_final_boss())
	player.level = 8
	assert_true(GameManager.can_access_final_boss())
	var boss := MonsterFactory.create_final_boss(8)
	assert_eq(boss.level, 8)
	assert_eq(boss.max_health, 250)
	assert_eq(boss.attack, 22)
	assert_eq(boss.defense, 16)
	GameManager.current_monster = boss
	GameManager.in_combat = true
	GameManager.pending_monster_intent = {"id": "dark_curse"}
	GameManager.monster_attack()
	assert_true(player.has_status_effect("weakened"))
	assert_eq(player.get_outgoing_damage_multiplier(), 0.8)
	GameManager.tick_player_action_status_effects()
	assert_true(player.has_status_effect("weakened"))
	GameManager.tick_player_action_status_effects()
	assert_false(player.has_status_effect("weakened"))


func test_stored_intent_range_matches_executed_power_strike() -> void:
	GameManager.new_game("Intent Tester", "Hero")
	var player: Player = GameManager.get_player()
	player.max_health = 500
	player.health = 500
	var monster := MonsterFactory.create_monster("goblin", 1)
	monster.attack = 50
	GameManager.current_monster = monster
	GameManager.in_combat = true
	GameManager.pending_monster_intent = {"id": "power_strike"}
	var expected := CombatRules.estimate_range(
		monster.attack, player.get_defense_power(), 1.35)
	var before := player.health
	GameManager.monster_attack()
	var actual := before - player.health
	assert_true(actual >= expected.min and actual <= expected.max)


func test_escape_chance_is_guaranteed_after_one_failure_and_blocked_for_boss() -> void:
	assert_eq(CombatRules.get_escape_chance(0), 0.75)
	assert_eq(CombatRules.get_escape_chance(1), 1.0)
	assert_eq(CombatRules.get_escape_chance(0, true), 0.0)


func _simulate_damage_turns(
	character_class: String, level: int, attack_power: int, source_monster: Monster
) -> int:
	var monster_health := source_monster.max_health
	var mana := Player.get_base_max_mana_for_class(character_class) + 5 * (level - 1)
	var skills := SkillFactory.get_class_skills(character_class)
	var cooldowns := []
	for _skill in skills:
		cooldowns.append(0)
	var turns := 0
	while monster_health > 0 and turns < 30:
		turns += 1
		var chosen_index := -1
		var chosen_damage := CombatRules.calculate_damage(
			attack_power, source_monster.defense)
		for index in range(skills.size()):
			var skill: Skill = skills[index]
			if skill.effect_type != "damage" or cooldowns[index] > 0:
				continue
			if skill.mana_cost > mana:
				continue
			var skill_damage := CombatRules.calculate_damage(
				attack_power, source_monster.defense, skill.damage_multiplier)
			if skill_damage > chosen_damage:
				chosen_index = index
				chosen_damage = skill_damage
		monster_health -= chosen_damage
		if chosen_index >= 0:
			mana -= skills[chosen_index].mana_cost
			cooldowns[chosen_index] = skills[chosen_index].cooldown
		for index in range(cooldowns.size()):
			cooldowns[index] = maxi(0, cooldowns[index] - 1)
	return turns


func _simulate_seeded_standard_fight(
	character_class: String,
	level: int,
	monster_type: String,
	monster_rank: String = "medium",
) -> Dictionary:
	var stats: Dictionary = CLASS_STATS[character_class]
	var attack_power: int = int(stats.attack) + 2 * (level - 1)
	var defense_power: int = int(stats.defense) + level - 1
	var dexterity: int = int(stats.dexterity) + level - 1
	var max_health := 100 + 10 * (level - 1)
	var health := max_health
	var monster := MonsterFactory.create_monster(monster_type, level)
	MonsterFactory.apply_encounter_rank(monster, monster_rank)
	var mana := Player.get_base_max_mana_for_class(character_class) + 5 * (level - 1)
	var skills := SkillFactory.get_class_skills(character_class)
	var cooldowns: Array[int] = []
	for _skill in skills:
		cooldowns.append(0)
	var turns := 0
	while health > 0 and monster.health > 0 and turns < 30:
		turns += 1
		var chosen_index := -1
		var chosen_multiplier := 1.0
		var chosen_damage := CombatRules.calculate_damage(
			attack_power, monster.defense)
		for index in range(skills.size()):
			var skill: Skill = skills[index]
			if skill.effect_type != "damage" or cooldowns[index] > 0:
				continue
			if skill.mana_cost > mana:
				continue
			var skill_damage := CombatRules.calculate_damage(
				attack_power, monster.defense, skill.damage_multiplier)
			if skill_damage > chosen_damage:
				chosen_index = index
				chosen_multiplier = skill.damage_multiplier
				chosen_damage = skill_damage
		var critical := false
		if chosen_index < 0:
			critical = randi() % 100 < mini(50, 5 + dexterity / 2)
		else:
			mana -= skills[chosen_index].mana_cost
			cooldowns[chosen_index] = skills[chosen_index].cooldown
		monster.take_damage(CombatRules.roll_damage(
			attack_power, monster.defense, chosen_multiplier, critical))
		if monster.health > 0:
			health -= CombatRules.roll_damage(monster.attack, defense_power)
		for index in range(cooldowns.size()):
			cooldowns[index] = maxi(0, cooldowns[index] - 1)
	return {
		"won": monster.health <= 0,
		"turns": turns,
		"health_loss": float(max_health - maxi(0, health)) / float(max_health),
	}


func _count_item(player: Player, item_id: String) -> int:
	var count := 0
	for item in player.inventory:
		if item and item.item_id == item_id:
			count += item.quantity
	return count
