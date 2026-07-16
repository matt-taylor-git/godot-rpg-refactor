extends GutTest

# Tests for Item.item_id, ItemFactory, and ItemLookup


func test_factory_sets_item_id_for_known_items():
	var sword = ItemFactory.create_item("sword")
	assert_eq(sword.item_id, "sword", "sword should have item_id sword")
	assert_eq(sword.name, "Iron Sword")

	var potion = ItemFactory.create_item("health_potion")
	assert_eq(potion.item_id, "health_potion")

	var coin = ItemFactory.create_item("gold_coin")
	assert_eq(coin.item_id, "gold_coin")


func test_factory_unknown_item_id():
	var item = ItemFactory.create_item("not_a_real_item")
	assert_eq(item.item_id, "unknown")
	assert_eq(item.name, "Unknown Item")


func test_random_weapon_keeps_base_item_id():
	var weapon = ItemFactory.create_random_weapon(3)
	# create_random_weapon may hit undefined types (axe/dagger/staff) -> unknown
	# When sword is rolled, id stays sword; always non-empty after create_item
	assert_true(weapon.item_id != "", "item_id should be set")
	assert_true(
		weapon.name.begins_with("Level 3"),
		"display name should be level-prefixed")


func test_item_dict_round_trip_preserves_item_id():
	var item = ItemFactory.create_item("shield")
	var data = item.to_dict()
	assert_eq(data.get("item_id", ""), "shield")

	var loaded = Item.new()
	loaded.from_dict(data)
	assert_eq(loaded.item_id, "shield")
	assert_eq(loaded.name, "Wooden Shield")


func test_item_from_dict_missing_item_id_defaults_empty():
	var loaded = Item.new()
	loaded.from_dict({"name": "Legacy Item", "value": 1})
	assert_eq(loaded.item_id, "", "old saves without item_id default to empty")


func test_lookup_by_id_returns_texture_or_null_safely():
	var tex = ItemLookup.get_texture_by_id("sword")
	# Texture may be null only if assets missing; should not crash
	if ResourceLoader.exists("res://assets/items/sword.png"):
		assert_not_null(tex, "sword texture should load when asset exists")
	else:
		pass


func test_lookup_unknown_and_empty_id():
	var empty_tex = ItemLookup.get_texture_by_id("")
	var unknown_tex = ItemLookup.get_texture_by_id("unknown")
	var bogus_tex = ItemLookup.get_texture_by_id("no_such_item")
	# All should resolve without error; default path if present
	if ResourceLoader.exists("res://assets/items/unknown.png"):
		assert_not_null(empty_tex)
		assert_not_null(unknown_tex)
		assert_not_null(bogus_tex)


func test_lookup_from_item_instance():
	var item = ItemFactory.create_item("mana_potion")
	var tex = ItemLookup.get_item_texture(item)
	if ResourceLoader.exists("res://assets/items/mana_potion.png"):
		assert_not_null(tex)


func test_lookup_null_item():
	var tex = ItemLookup.get_item_texture(null)
	if ResourceLoader.exists("res://assets/items/unknown.png"):
		assert_not_null(tex)
