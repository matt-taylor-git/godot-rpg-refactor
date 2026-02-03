class_name QuestFactory
extends Node

# QuestFactory - Creates quest instances

# Simple quest resource for now
class Quest extends Resource:
	var title: String = ""
	var description: String = ""
	var type: String = ""  # kill, delivery, exploration
	var target_count: int = 0
	var current_count: int = 0
	var reward_exp: int = 0
	var reward_gold: int = 0
	var completed: bool = false

	func is_completed() -> bool:
		return current_count >= target_count

	func update_progress(amount: int = 1) -> void:
		current_count += amount

static func create_quest(quest_type: String, level: int = 1) -> Quest:
	var quest = Quest.new()

	match quest_type:
		"kill_goblins":
			quest.title = "Goblin Extermination"
			quest.description = "Kill 5 goblins in the forest"
			quest.type = "kill"
			quest.target_count = 5
			quest.reward_exp = 50 + level * 10
			quest.reward_gold = 25 + level * 5

		"collect_herbs":
			quest.title = "Herbal Collection"
			quest.description = "Collect 3 healing herbs"
			quest.type = "collect"
			quest.target_count = 3
			quest.reward_exp = 30 + level * 5
			quest.reward_gold = 15 + level * 3

		"explore_cave":
			quest.title = "Cave Exploration"
			quest.description = "Explore the mysterious cave"
			quest.type = "exploration"
			quest.target_count = 1
			quest.reward_exp = 75 + level * 15
			quest.reward_gold = 40 + level * 8

		_:
			quest.title = "Unknown Quest"
			quest.description = "Complete this mysterious task"
			quest.type = "misc"
			quest.target_count = 1
			quest.reward_exp = 25
			quest.reward_gold = 10

	return quest

static func get_random_quest(level: int = 1) -> Quest:
	var quest_types = ["kill_goblins", "collect_herbs", "explore_cave"]
	var random_type = quest_types[randi() % quest_types.size()]
	return create_quest(random_type, level)
