extends Node

# CodexManager - Tracks lore discoveries and codex entries
# Autoload singleton for lore system

signal lore_entry_unlocked(entry_id: String, entry_title: String)
signal codex_updated()

var lore_entries: Dictionary = {}
var unlocked_entries: Dictionary = {}

func _ready():
	print("CodexManager initialized")
	load_lore_entries()

func load_lore_entries() -> void:
	# Sample lore entries - in a real implementation, this would load from JSON
	lore_entries = {
		"goblin_history": {
			"id": "goblin_history",
			"title": "The Goblin Tribes",
			"category": "creatures",
			"content": "Goblins are small, cunning creatures that dwell in caves and forests. They are known for their tribal society and territorial nature. Ancient texts suggest they were once peaceful forest dwellers before being corrupted by dark magic.",
			"unlock_condition": "enemy_killed",
			"unlock_target": "goblin",
			"unlock_count": 1
		},
		"eldridge_founding": {
			"id": "eldridge_founding",
			"title": "Founding of Eldridge",
			"category": "history",
			"content": "Eldridge Village was founded 200 years ago by settlers fleeing the great wars. The village elder's family has maintained the founding scrolls, which speak of a 'great darkness' that the founders sought to escape.",
			"unlock_condition": "dialogue",
			"unlock_target": "village_elder",
			"unlock_count": 1
		},
		"ancient_evil": {
			"id": "ancient_evil",
			"title": "The Ancient Evil",
			"category": "lore",
			"content": "Whispers speak of an ancient evil that sleeps beneath the mountains. Some say it was imprisoned by heroes of old, but its influence still seeps into the world, corrupting creatures and twisting the land.",
			"unlock_condition": "story_event",
			"unlock_target": "ancient_evil",
			"unlock_count": 1
		},
		"magic_crystal": {
			"id": "magic_crystal",
			"title": "Magic Crystals",
			"category": "items",
			"content": "These rare crystals pulse with magical energy. They are said to be fragments of the ancient world's magic, capable of powering artifacts or enhancing spells.",
			"unlock_condition": "item_found",
			"unlock_target": "magic_crystal",
			"unlock_count": 1
		},
		"hero_legacy": {
			"id": "hero_legacy",
			"title": "The Hero's Legacy",
			"category": "history",
			"content": "Legends tell of heroes who once wielded great power to protect the realm. Their bloodline continues, though their powers have diminished over generations. Some believe the ancient evil seeks to eradicate this lineage.",
			"unlock_condition": "level_reached",
			"unlock_target": 10,
			"unlock_count": 1
		}
	}

func unlock_entry(entry_id: String) -> bool:
	if not lore_entries.has(entry_id) or unlocked_entries.has(entry_id):
		return false

	var entry = lore_entries[entry_id]
	unlocked_entries[entry_id] = entry

	emit_signal("lore_entry_unlocked", entry_id, entry.title)
	emit_signal("codex_updated")

	print("Lore entry unlocked: ", entry.title)
	return true

func has_unlocked(entry_id: String) -> bool:
	return unlocked_entries.has(entry_id)

func get_unlocked_entries() -> Dictionary:
	return unlocked_entries.duplicate()

func get_entry(entry_id: String) -> Dictionary:
	if unlocked_entries.has(entry_id):
		return unlocked_entries[entry_id]
	return {}

func get_entries_by_category(category: String) -> Array:
	var category_entries = []
	for entry_id in unlocked_entries:
		var entry = unlocked_entries[entry_id]
		if entry.get("category") == category:
			category_entries.append(entry)
	return category_entries

func get_all_categories() -> Array:
	var categories = []
	for entry_id in unlocked_entries:
		var category = unlocked_entries[entry_id].get("category", "")
		if category not in categories:
			categories.append(category)
	return categories

func check_unlock_conditions() -> void:
	# Check all lore entries for unlock conditions
	for entry_id in lore_entries:
		if has_unlocked(entry_id):
			continue

		var entry = lore_entries[entry_id]
		var condition = entry.get("unlock_condition", "")
		var target = entry.get("unlock_target", "")
		var required_count = entry.get("unlock_count", 1)

		var should_unlock = false

		match condition:
			"enemy_killed":
				# Check if player has killed enough of this enemy type
				should_unlock = get_enemy_kill_count(target) >= required_count
			"dialogue":
				# Check if player has talked to this NPC
				should_unlock = has_talked_to_npc(target)
			"story_event":
				# Check if story event has been completed
				should_unlock = StoryManager.has_completed_event(target)
			"item_found":
				# Check if player has found this item
				should_unlock = has_found_item(target)
			"level_reached":
				# Check if player has reached this level
				if GameManager.get_player():
					should_unlock = GameManager.get_player().level >= target

		if should_unlock:
			unlock_entry(entry_id)

# Helper functions for checking unlock conditions
func get_enemy_kill_count(enemy_type: String) -> int:
	return StoryManager.get_story_flag("enemy_kills_" + enemy_type) as int

func has_talked_to_npc(npc_id: String) -> bool:
	return StoryManager.get_story_flag("talked_to_" + npc_id)

func has_found_item(item_id: String) -> bool:
	return StoryManager.get_story_flag("found_" + item_id)

# Event handlers
func on_enemy_killed(enemy_name: String) -> void:
	var enemy_type = enemy_name.to_lower()
	if lore_entries.has(enemy_type + "_history"):
		unlock_entry(enemy_type + "_history")

func on_quest_completed(quest_title: String) -> void:
	# Unlock lore based on quest completion
	if quest_title.contains("Cave"):
		unlock_entry("ancient_evil")
	elif quest_title.contains("Goblin"):
		unlock_entry("goblin_history")

func on_item_collected(item_name: String) -> void:
	var item_id = item_name.to_lower().replace(" ", "_")
	if lore_entries.has(item_id):
		unlock_entry(item_id)

func on_level_up(new_level: int) -> void:
	# Check for level-based lore unlocks
	for entry_id in lore_entries:
		var entry = lore_entries[entry_id]
		if entry.get("unlock_condition") == "level_reached":
			if new_level >= entry.get("unlock_target", 999):
				unlock_entry(entry_id)

# Save/Load functionality
func save_codex_state() -> Dictionary:
	return {
		"unlocked_entries": unlocked_entries.keys()
	}

func load_codex_state(data: Dictionary) -> void:
	unlocked_entries.clear()

	var unlocked_ids = data.get("unlocked_entries", [])
	for entry_id in unlocked_ids:
		if lore_entries.has(entry_id):
			unlocked_entries[entry_id] = lore_entries[entry_id]

func get_discovered_lore() -> Array:
	return unlocked_entries.keys()

func is_lore_discovered(entry_id: String) -> bool:
	return has_unlocked(entry_id)
