extends GutTest

# Test Lore/Codex System functionality

func test_codex_manager_initializes():
	assert_not_null(CodexManager)
	assert_not_null(CodexManager.lore_entries)
	assert_true(CodexManager.lore_entries.size() > 0)

func test_lore_entries_exist():
	assert_true(CodexManager.lore_entries.has("goblin_history"))
	assert_true(CodexManager.lore_entries.has("eldridge_founding"))
	assert_true(CodexManager.lore_entries.has("ancient_evil"))

func test_entry_unlock():
	CodexManager.unlocked_entries.clear()
	var entry_id = "goblin_history"
	
	assert_false(CodexManager.has_unlocked(entry_id))
	CodexManager.unlock_entry(entry_id)
	assert_true(CodexManager.has_unlocked(entry_id))

func test_duplicate_unlock_prevented():
	CodexManager.unlocked_entries.clear()
	var entry_id = "goblin_history"
	
	var result1 = CodexManager.unlock_entry(entry_id)
	var result2 = CodexManager.unlock_entry(entry_id)
	
	assert_true(result1)
	assert_false(result2)

func test_get_unlocked_entries():
	CodexManager.unlocked_entries.clear()
	
	CodexManager.unlock_entry("goblin_history")
	CodexManager.unlock_entry("ancient_evil")
	
	var unlocked = CodexManager.get_unlocked_entries()
	assert_eq(unlocked.size(), 2)

func test_get_entry():
	CodexManager.unlocked_entries.clear()
	CodexManager.unlock_entry("goblin_history")
	
	var entry = CodexManager.get_entry("goblin_history")
	assert_not_empty(entry)
	assert_eq(entry.get("title"), "The Goblin Tribes")

func test_get_locked_entry_returns_empty():
	CodexManager.unlocked_entries.clear()
	
	var entry = CodexManager.get_entry("goblin_history")
	assert_empty(entry)

func test_categories_exist():
	var categories = []
	for entry_id in CodexManager.lore_entries:
		var category = CodexManager.lore_entries[entry_id].get("category", "")
		if category and category not in categories:
			categories.append(category)
	
	assert_gt(categories.size(), 0)

func test_entries_by_category():
	CodexManager.unlocked_entries.clear()
	CodexManager.unlock_entry("goblin_history")
	CodexManager.unlock_entry("eldridge_founding")
	CodexManager.unlock_entry("ancient_evil")
	
	var creatures_entries = CodexManager.get_entries_by_category("creatures")
	var history_entries = CodexManager.get_entries_by_category("history")
	
	assert_eq(creatures_entries.size(), 1)
	assert_eq(history_entries.size(), 2)

func test_get_all_categories():
	CodexManager.unlocked_entries.clear()
	CodexManager.unlock_entry("goblin_history")
	CodexManager.unlock_entry("eldridge_founding")
	CodexManager.unlock_entry("magic_crystal")
	
	var categories = CodexManager.get_all_categories()
	assert_gt(categories.size(), 0)
	assert_true("creatures" in categories)

func test_entry_has_required_fields():
	for entry_id in CodexManager.lore_entries:
		var entry = CodexManager.lore_entries[entry_id]
		assert_true(entry.has("id"))
		assert_true(entry.has("title"))
		assert_true(entry.has("category"))
		assert_true(entry.has("content"))
		assert_true(entry.has("unlock_condition"))

func test_unlock_condition_types():
	var conditions = []
	for entry_id in CodexManager.lore_entries:
		var condition = CodexManager.lore_entries[entry_id].get("unlock_condition")
		if condition and condition not in conditions:
			conditions.append(condition)
	
	assert_true("enemy_killed" in conditions)
	assert_true("dialogue" in conditions)

func test_enemy_killed_lore_unlock():
	CodexManager.unlocked_entries.clear()
	CodexManager.on_enemy_killed("goblin")
	
	assert_true(CodexManager.has_unlocked("goblin_history"))

func test_quest_completion_lore_unlock():
	CodexManager.unlocked_entries.clear()
	CodexManager.on_quest_completed("Cave Exploration Quest")
	
	assert_true(CodexManager.has_unlocked("ancient_evil"))

func test_multiple_entries_unlock():
	CodexManager.unlocked_entries.clear()
	
	CodexManager.unlock_entry("goblin_history")
	CodexManager.unlock_entry("eldridge_founding")
	CodexManager.unlock_entry("ancient_evil")
	CodexManager.unlock_entry("magic_crystal")
	
	var unlocked = CodexManager.get_unlocked_entries()
	assert_eq(unlocked.size(), 4)
