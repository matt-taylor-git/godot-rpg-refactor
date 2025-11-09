extends Node
class_name MonsterFactory

# MonsterFactory - Creates monster instances

static func create_monster(monster_type: String, level: int = 1) -> Monster:
	var monster = Monster.new()
	
	match monster_type:
		"goblin":
			monster.name = "Goblin"
			monster.level = level
			monster.max_health = 30 + (level * 5)
			monster.health = monster.max_health
			monster.attack = 5 + level
			monster.defense = 2 + level
			monster.dexterity = 4 + level
			monster.experience_reward = 8 + level
			monster.gold_reward = 3 + level
			# Add loot table
			var potion = ItemFactory.create_item("health_potion")
			monster.loot_table.append({"item": potion, "chance": 0.3})
		
		"orc":
			monster.name = "Orc"
			monster.level = level
			monster.max_health = 50 + (level * 8)
			monster.health = monster.max_health
			monster.attack = 8 + level
			monster.defense = 4 + level
			monster.dexterity = 2 + level
			monster.experience_reward = 15 + level
			monster.gold_reward = 8 + level
		
		"skeleton":
			monster.name = "Skeleton"
			monster.level = level
			monster.max_health = 25 + (level * 4)
			monster.health = monster.max_health
			monster.attack = 6 + level
			monster.defense = 3 + level
			monster.dexterity = 5 + level
			monster.experience_reward = 10 + level
			monster.gold_reward = 5 + level
		
		_:
			# Default monster
			monster.name = "Unknown Monster"
			monster.level = level
			monster.max_health = 40 + (level * 6)
			monster.health = monster.max_health
			monster.attack = 7 + level
			monster.defense = 3 + level
			monster.dexterity = 3 + level
			monster.experience_reward = 12 + level
			monster.gold_reward = 6 + level
	
	return monster

static func get_random_monster_type() -> String:
	var types = ["goblin", "orc", "skeleton"]
	return types[randi() % types.size()]

static func create_final_boss(level: int = 1) -> FinalBoss:
	var boss = FinalBoss.new()
	boss.set_stats_for_level(level)
	return boss
