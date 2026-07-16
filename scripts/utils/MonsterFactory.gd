class_name MonsterFactory
extends Node

# MonsterFactory - Creates monster instances for combat and exploration

static func create_monster(monster_type: String, level: int = 1) -> Monster:
	var monster = Monster.new()
	var key := monster_type.to_lower().strip_edges()

	match key:
		"goblin":
			_apply_stats(monster, "Goblin", level, 30, 5, 5, 2, 4, 8, 3)
			var potion = ItemFactory.create_item("health_potion")
			monster.loot_table.append({"item": potion, "chance": 0.3})
		"orc":
			_apply_stats(monster, "Orc", level, 50, 8, 8, 4, 2, 15, 8)
		"skeleton":
			_apply_stats(monster, "Skeleton", level, 25, 4, 6, 3, 5, 10, 5)
		"slime":
			_apply_stats(monster, "Slime", level, 35, 6, 4, 5, 2, 9, 4)
		"wolf":
			_apply_stats(monster, "Wolf", level, 28, 5, 7, 2, 7, 11, 5)
		"spider":
			_apply_stats(monster, "Spider", level, 22, 4, 6, 2, 8, 10, 4)
		"bat":
			_apply_stats(monster, "Bat", level, 18, 3, 5, 1, 9, 7, 3)
		"bandit":
			_apply_stats(monster, "Bandit", level, 32, 5, 7, 3, 6, 12, 10)
		"golem":
			_apply_stats(monster, "Golem", level, 70, 10, 6, 8, 1, 20, 12)
		"troll":
			_apply_stats(monster, "Troll", level, 80, 12, 10, 6, 2, 25, 15)
		"dragon":
			_apply_stats(monster, "Dragon", level, 120, 15, 14, 8, 5, 40, 30)
		"boss":
			_apply_stats(monster, "Boss", level, 100, 12, 12, 7, 4, 35, 25)
		_:
			# Friendly fallback name instead of "Unknown Monster"
			var display := key.capitalize() if key != "" else "Wanderer"
			_apply_stats(monster, display, level, 40, 6, 7, 3, 3, 12, 6)

	return monster


static func _apply_stats(
	monster: Monster,
	display_name: String,
	level: int,
	base_hp: int,
	hp_per_level: int,
	base_atk: int,
	base_def: int,
	base_dex: int,
	base_exp: int,
	base_gold: int
) -> void:
	monster.name = display_name
	monster.level = level
	monster.max_health = base_hp + (level * hp_per_level)
	monster.health = monster.max_health
	monster.attack = base_atk + level
	monster.defense = base_def + level
	monster.dexterity = base_dex + level
	monster.experience_reward = base_exp + level
	monster.gold_reward = base_gold + level


static func get_random_monster_type() -> String:
	var types = [
		"goblin", "orc", "skeleton", "slime", "wolf",
		"spider", "bandit", "golem"
	]
	return types[randi() % types.size()]


static func create_final_boss(level: int = 1) -> Monster:
	# Use late binding to avoid forward reference issues
	var FinalBossClass = load("res://scripts/models/FinalBoss.gd")
	var boss = FinalBossClass.new()
	boss.set_stats_for_level(level)
	return boss
