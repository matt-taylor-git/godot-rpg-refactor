extends Node
class_name ItemFactory

# ItemFactory - Creates item instances

static func create_item(item_type: String) -> Item:
	var item = Item.new()
	
	match item_type:
		"sword":
			item.name = "Iron Sword"
			item.description = "A sturdy iron sword"
			item.type = Item.ItemType.WEAPON
			item.value = 50
			item.attack_bonus = 5
		
		"shield":
			item.name = "Wooden Shield"
			item.description = "Basic protection"
			item.type = Item.ItemType.ARMOR
			item.value = 30
			item.defense_bonus = 3
		
		"health_potion":
			item.name = "Health Potion"
			item.description = "Restores 50 HP"
			item.type = Item.ItemType.CONSUMABLE
			item.value = 20
			item.heal_amount = 50
			item.stackable = true
			item.max_stack = 5
		
		"mana_potion":
			item.name = "Mana Potion"
			item.description = "Restores 30 MP"
			item.type = Item.ItemType.CONSUMABLE
			item.value = 25
			item.effect = "restore_mana"
		
		"gold_coin":
			item.name = "Gold Coin"
			item.description = "Currency"
			item.type = Item.ItemType.MISC
			item.value = 1
		
		_:
			# Default item
			item.name = "Unknown Item"
			item.description = "An unknown item"
			item.type = Item.ItemType.MISC
			item.value = 1
	
	return item

static func create_random_weapon(level: int = 1) -> Item:
	var weapons = ["sword", "axe", "dagger", "staff"]
	var weapon_type = weapons[randi() % weapons.size()]
	var item = create_item(weapon_type)
	
	# Scale by level
	item.attack_bonus += level * 2
	item.value += level * 10
	item.name = "Level %d %s" % [level, item.name]
	
	return item

static func create_random_armor(level: int = 1) -> Item:
	var armors = ["shield", "helmet", "chestplate", "boots"]
	var armor_type = armors[randi() % armors.size()]
	var item = create_item(armor_type)

	# Scale by level
	item.defense_bonus += level
	item.value += level * 8
	item.name = "Level %d %s" % [level, item.name]

	return item

static func create_random_item(level: int = 1) -> Item:
	var item_types = ["weapon", "armor", "consumable"]
	var item_type = item_types[randi() % item_types.size()]

	match item_type:
		"weapon":
			return create_random_weapon(level)
		"armor":
			return create_random_armor(level)
		"consumable":
			var consumables = ["health_potion", "mana_potion"]
			return create_item(consumables[randi() % consumables.size()])

	return create_item("health_potion")  # fallback
