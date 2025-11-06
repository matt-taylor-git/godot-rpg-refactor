extends Node

# StoryManager - Manages narrative progression and story events
# Autoload singleton for story system

signal story_event_triggered(event_id: String, event_data: Dictionary)
signal story_progression_unlocked(unlock_id: String)

var story_events: Dictionary = {}
var completed_events: Array = []
var story_flags: Dictionary = {}

func _ready():
	print("StoryManager initialized")
	load_events()

func load_events() -> void:
	# Sample story events - in a real implementation, this would load from JSON
	story_events = {
		"tutorial_welcome": {
			"id": "tutorial_welcome",
			"title": "Welcome to Adventure",
			"description": "You awaken in the village of Eldridge with no memory of how you got here.",
			"trigger_condition": "game_started",
			"auto_trigger": true,
			"unlocks": ["exploration_mechanics"]
		},
		"first_quest_complete": {
			"id": "first_quest_complete",
			"title": "First Victory",
			"description": "You've completed your first quest! The villagers are grateful.",
			"trigger_condition": "quest_completed",
			"required_quests": ["Goblin Extermination"],
			"unlocks": ["dialogue_system", "shop_access"]
		},
		"goblin_threat": {
			"id": "goblin_threat",
			"title": "The Goblin Menace",
			"description": "The goblin attacks have increased. Something is stirring in the darkness.",
			"trigger_condition": "enemy_killed_count",
			"enemy_type": "goblin",
			"required_count": 10,
			"unlocks": ["cave_entrance"]
		},
		"ancient_evil": {
			"id": "ancient_evil",
			"title": "Ancient Evil Awakens",
			"description": "You discover evidence of an ancient evil corrupting the land.",
			"trigger_condition": "exploration_complete",
			"location": "mysterious_cave",
			"unlocks": ["final_quest"]
		}
	}

func trigger_event(event_id: String, context: Dictionary = {}) -> void:
	if not story_events.has(event_id) or event_id in completed_events:
		return

	var event = story_events[event_id]

	# Check if conditions are met
	if check_event_conditions(event, context):
		complete_event(event_id, event)
		emit_signal("story_event_triggered", event_id, event)

func complete_event(event_id: String, event: Dictionary) -> void:
	completed_events.append(event_id)

	# Set story flags
	if event.has("unlocks"):
		for unlock in event.unlocks:
			story_flags[unlock] = true
			emit_signal("story_progression_unlocked", unlock)

	print("Story event completed: ", event.title)

func check_event_conditions(event: Dictionary, context: Dictionary) -> bool:
	var condition = event.get("trigger_condition", "")

	match condition:
		"game_started":
			return true
		"quest_completed":
			if context.has("quest_title"):
				var required_quests = event.get("required_quests", [])
				return context.quest_title in required_quests
		"enemy_killed_count":
			var enemy_type = event.get("enemy_type", "")
			var required_count = event.get("required_count", 0)
			return get_enemy_kill_count(enemy_type) >= required_count
		"exploration_complete":
			var location = event.get("location", "")
			return has_explored_location(location)

	return false

func get_enemy_kill_count(enemy_type: String) -> int:
	# This would track enemy kills - for now, return a placeholder
	# In a real implementation, this would be stored in game data
	return story_flags.get("enemy_kills_" + enemy_type, 0)

func has_explored_location(location: String) -> bool:
	return story_flags.get("explored_" + location, false)

func on_quest_started(quest_title: String) -> void:
	# Trigger story events based on quest acceptance
	if quest_title.contains("Goblin"):
		trigger_event("goblin_threat", {"quest_title": quest_title})

func on_quest_completed(quest_title: String) -> void:
	trigger_event("first_quest_complete", {"quest_title": quest_title})

	# Handle specific quest completions
	if quest_title.contains("Cave Exploration"):
		set_story_flag("explored_mysterious_cave", true)
		trigger_event("ancient_evil", {"location": "mysterious_cave"})

func on_enemy_killed(enemy_name: String) -> void:
	var enemy_type = enemy_name.to_lower()
	if not story_flags.has("enemy_kills_" + enemy_type):
		story_flags["enemy_kills_" + enemy_type] = 0
	story_flags["enemy_kills_" + enemy_type] += 1

	# Check for story events that depend on enemy kills
	for event_id in story_events:
		var event = story_events[event_id]
		if event.get("trigger_condition") == "enemy_killed_count":
			if event.get("enemy_type") == enemy_type:
				trigger_event(event_id)

func set_story_flag(flag_name: String, value: bool = true) -> void:
	story_flags[flag_name] = value

func get_story_flag(flag_name: String) -> bool:
	return story_flags.get(flag_name, false)

func has_completed_event(event_id: String) -> bool:
	return event_id in completed_events

func get_completed_events() -> Array:
	return completed_events.duplicate()

func get_available_events() -> Array:
	var available = []
	for event_id in story_events:
		if not has_completed_event(event_id):
			available.append(event_id)
	return available

# Auto-trigger events on game start
func on_game_started() -> void:
	trigger_event("tutorial_welcome")

# Save/Load functionality
func save_story_state() -> Dictionary:
	return {
		"completed_events": completed_events,
		"story_flags": story_flags
	}

func load_story_state(data: Dictionary) -> void:
	completed_events = data.get("completed_events", [])
	story_flags = data.get("story_flags", {})
