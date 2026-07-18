class_name Item
extends Resource

# Item - Equipment and consumables

enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_id: String = ""  # Stable factory id for icons/lookup
@export var name: String = ""
@export var description: String = ""
@export var type: ItemType = ItemType.MISC
@export var rarity: Rarity = Rarity.COMMON
@export var value: int = 0  # Gold value

# Combat stats
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0

# For consumables
@export var heal_amount: int = 0
@export var restore_percent: float = 0.0
@export var effect: String = ""  # buff, debuff, etc.

@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

func _init():
	pass

func use(target) -> bool:
	match type:
		ItemType.CONSUMABLE:
			if effect == "restore_mana":
				if target.has_method("restore_mana"):
					var mana_amount := heal_amount
					if restore_percent > 0.0 and "max_mana" in target:
						mana_amount = roundi(float(target.max_mana) * restore_percent)
					target.restore_mana(mana_amount)
					quantity -= 1
					return true
				return false
			if target.has_method("heal"):
				var health_amount := heal_amount
				if restore_percent > 0.0 and "max_health" in target:
					health_amount = roundi(float(target.max_health) * restore_percent)
				target.heal(health_amount)
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


## Border color for inventory/shop rarity framing (theme-aligned).
static func rarity_border_color(r: Rarity) -> Color:
	match r:
		Rarity.UNCOMMON:
			return Color(0.45, 0.75, 0.45, 1.0)  # success green
		Rarity.RARE:
			return Color(0.35, 0.56, 0.85, 1.0)
		Rarity.EPIC:
			return Color(0.61, 0.42, 0.85, 1.0)
		Rarity.LEGENDARY:
			return Color(0.85, 0.70, 0.35, 1.0)  # gold
		_:
			return Color(0.60, 0.45, 0.20, 1.0)  # bronze


func get_rarity_border_color() -> Color:
	return rarity_border_color(rarity)


func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"type": type,
		"rarity": rarity,
		"value": value,
		"attack_bonus": attack_bonus,
		"defense_bonus": defense_bonus,
		"health_bonus": health_bonus,
		"heal_amount": heal_amount,
		"restore_percent": restore_percent,
		"effect": effect,
		"stackable": stackable,
		"max_stack": max_stack,
		"quantity": quantity
	}

func from_dict(data: Dictionary) -> void:
	item_id = data.get("item_id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	type = data.get("type", ItemType.MISC)
	rarity = data.get("rarity", Rarity.COMMON)
	value = data.get("value", 0)
	attack_bonus = data.get("attack_bonus", 0)
	defense_bonus = data.get("defense_bonus", 0)
	health_bonus = data.get("health_bonus", 0)
	heal_amount = data.get("heal_amount", 0)
	restore_percent = data.get("restore_percent", 0.0)
	effect = data.get("effect", "")
	stackable = data.get("stackable", false)
	max_stack = data.get("max_stack", 1)
	quantity = data.get("quantity", 1)
