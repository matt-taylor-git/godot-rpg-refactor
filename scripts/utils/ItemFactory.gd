class_name ItemFactory
extends Node

# ItemFactory - Creates item instances

static func create_item(item_type: String) -> Item:
	var item = Item.new()
	item.item_id = item_type

	match item_type:
		"sword":
			item.name = "Iron Sword"
			item.description = "A sturdy iron sword"
			item.type = Item.ItemType.WEAPON
			item.rarity = Item.Rarity.COMMON
			item.value = 75
			item.attack_bonus = 5

		"shield":
			item.name = "Wooden Shield"
			item.description = "Basic protection"
			item.type = Item.ItemType.ARMOR
			item.rarity = Item.Rarity.COMMON
			item.value = 60
			item.defense_bonus = 5

		"health_potion":
			item.name = "Health Potion"
			item.description = "Restores 35% of maximum HP"
			item.type = Item.ItemType.CONSUMABLE
			item.rarity = Item.Rarity.UNCOMMON
			item.value = 30
			item.heal_amount = 35
			item.restore_percent = 0.35
			item.stackable = true
			item.max_stack = 5

		"mana_potion":
			item.name = "Mana Potion"
			item.description = "Restores 40% of maximum MP"
			item.type = Item.ItemType.CONSUMABLE
			item.rarity = Item.Rarity.UNCOMMON
			item.value = 25
			item.heal_amount = 40
			item.restore_percent = 0.40
			item.effect = "restore_mana"
			item.stackable = true
			item.max_stack = 5

		"gold_coin":
			item.name = "Gold Coin"
			item.description = "Currency"
			item.type = Item.ItemType.MISC
			item.rarity = Item.Rarity.COMMON
			item.value = 1

		_:
			# Default item
			item.item_id = "unknown"
			item.name = "Unknown Item"
			item.description = "An unknown item"
			item.type = Item.ItemType.MISC
			item.value = 1

	return item

static func create_random_weapon(level: int = 1) -> Item:
	var item = create_item("sword")
	item.attack_bonus = clampi(level + 4, 5, 8)
	item.value += (item.attack_bonus - 5) * 20
	item.name = "Level %d %s" % [level, item.name]

	return item

static func create_random_armor(level: int = 1) -> Item:
	var item = create_item("shield")
	item.defense_bonus = clampi(level + 4, 5, 8)
	item.value += (item.defense_bonus - 5) * 20
	item.name = "Level %d %s" % [level, item.name]

	return item

static func create_random_item(level: int = 1) -> Item:
	if randf() < 0.7:
		return create_item("health_potion" if randf() < 0.5 else "mana_potion")
	return create_random_weapon(level) if randf() < 0.5 else create_random_armor(level)


static func create_random_item_for_area(area_id: String) -> Item:
	var tiers := {"forest": 1, "mountain": 2, "cave": 3, "peak": 4}
	var tier: int = int(tiers.get(area_id, 1))
	var item := create_random_item(tier)
	if item.can_equip():
		var base_name := "Iron Sword" if item.item_id == "sword" else "Wooden Shield"
		item.name = "%s %s" % [area_id.capitalize(), base_name]
	return item

static func get_all_items() -> Array:
	var items = []
	items.append(create_item("sword"))
	items.append(create_item("shield"))
	items.append(create_item("health_potion"))
	items.append(create_item("mana_potion"))
	items.append(create_item("gold_coin"))
	return items
