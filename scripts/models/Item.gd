class_name Item
extends Resource

# Item - Equipment and consumables

enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, MISC }

@export var name: String = ""
@export var description: String = ""
@export var type: ItemType = ItemType.MISC
@export var value: int = 0  # Gold value

# Combat stats
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0

# For consumables
@export var heal_amount: int = 0
@export var effect: String = ""  # buff, debuff, etc.

@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

func _init():
	pass

func use(target) -> bool:
	match type:
		ItemType.CONSUMABLE:
			if target.has_method("heal"):
				target.heal(heal_amount)
				quantity -= 1
				return true
		_:
			return false
	return false

func is_consumable() -> bool:
	return type == ItemType.CONSUMABLE

func can_equip() -> bool:
	return type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.ACCESSORY]

func get_equip_slot() -> String:
	match type:
		ItemType.WEAPON:
			return "weapon"
		ItemType.ARMOR:
			return "armor"
		ItemType.ACCESSORY:
			return "accessory"
		_:
			return ""

func to_dict() -> Dictionary:
	return {
		"name": name,
		"description": description,
		"type": type,
		"value": value,
		"attack_bonus": attack_bonus,
		"defense_bonus": defense_bonus,
		"health_bonus": health_bonus,
		"heal_amount": heal_amount,
		"effect": effect,
		"stackable": stackable,
		"max_stack": max_stack,
		"quantity": quantity
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", "")
	description = data.get("description", "")
	type = data.get("type", ItemType.MISC)
	value = data.get("value", 0)
	attack_bonus = data.get("attack_bonus", 0)
	defense_bonus = data.get("defense_bonus", 0)
	health_bonus = data.get("health_bonus", 0)
	heal_amount = data.get("heal_amount", 0)
	effect = data.get("effect", "")
	stackable = data.get("stackable", false)
	max_stack = data.get("max_stack", 1)
	quantity = data.get("quantity", 1)
