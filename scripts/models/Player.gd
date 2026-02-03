class_name Player
extends Resource

# Player - Player character data and stats

@export var name: String = ""
@export var character_class: String = ""  # Hero, Warrior, Mage, Rogue
@export var level: int = 1
@export var experience: int = 0
@export var health: int = 100
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var dexterity: int = 5
@export var mana: int = 0
@export var max_mana: int = 0

@export var inventory: Array = []  # Array of Item resources
@export var equipment: Dictionary = {}  # weapon, armor, etc.
@export var skills: Array = []  # Array of Skill resources

@export var gold: int = 0

# Status effects: effect_type -> {duration: int, data: Dictionary}
@export var status_effects: Dictionary = {}

func _init():
	inventory.resize(20)  # 20-slot inventory
	equipment = {
		"weapon": null,
		"armor": null,
		"accessory": null
	}

func get_attack_power() -> int:
	var base_attack = attack
	if equipment.weapon:
		base_attack += equipment.weapon.attack_bonus
	return base_attack

func get_defense_power() -> int:
	var base_defense = defense
	if equipment.armor:
		base_defense += equipment.armor.defense_bonus
	return base_defense

func take_damage(amount: int) -> void:
	health = max(0, health - amount)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)

func add_experience(amount: int) -> void:
	experience += amount
	_check_level_up()

func _check_level_up() -> void:
	var exp_needed = get_exp_for_level(level + 1)
	while experience >= exp_needed and level < 100:  # Cap at level 100
		level += 1
		# Increase stats on level up
		max_health += 10
		health = max_health  # Full heal on level up
		attack += 2
		defense += 1
		dexterity += 1

		exp_needed = get_exp_for_level(level + 1)

func get_exp_for_level(target_level: int) -> int:
	# Simple exponential formula: 100 * level^1.5
	return int(100 * pow(target_level, 1.5))

func add_item(item: Resource) -> bool:
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			return true
	return false  # Inventory full

func remove_item(index: int) -> Resource:
	if index >= 0 and index < inventory.size():
		var item = inventory[index]
		inventory[index] = null
		return item
	return null

func equip_item(item: Resource, slot: String) -> bool:
	if not item or not item.can_equip():
		return false

	# Unequip current item in that slot if any
	if equipment.has(slot) and equipment[slot]:
		# Try to add the old item back to inventory
		if not add_item(equipment[slot]):
			return false  # No room in inventory

	# Equip the new item
	equipment[slot] = item

	# Apply stat bonuses
	attack += item.attack_bonus
	defense += item.defense_bonus
	max_health += item.health_bonus
	health += item.health_bonus  # Also heal for the bonus

	return true

func unequip_item(slot: String) -> Resource:
	if equipment.has(slot) and equipment[slot]:
		var item = equipment[slot]
		equipment[slot] = null

		# Remove stat bonuses
		attack -= item.attack_bonus
		defense -= item.defense_bonus
		max_health -= item.health_bonus
		health = min(health, max_health)  # Don't go over max health

		return item
	return null

func add_status_effect(effect_type: String, duration: int, effect_data: Dictionary = {}) -> void:
	# Add or update a status effect
	status_effects[effect_type] = {
		"duration": duration,
		"data": effect_data
	}

func remove_status_effect(effect_type: String) -> void:
	# Remove a status effect
	if status_effects.has(effect_type):
		status_effects.erase(effect_type)

func has_status_effect(effect_type: String) -> bool:
	# Check if player has a specific status effect
	return status_effects.has(effect_type)

func get_status_effect_duration(effect_type: String) -> int:
	# Get remaining duration of a status effect
	if status_effects.has(effect_type):
		return status_effects[effect_type].duration
	return 0

func tick_status_effects() -> Array:
	# Process status effects for one turn, return array of expired effects
	var expired_effects = []

	for effect_type in status_effects.keys():
		var effect = status_effects[effect_type]
		effect.duration -= 1

		if effect.duration <= 0:
			expired_effects.append(effect_type)

	# Remove expired effects
	for effect_type in expired_effects:
		status_effects.erase(effect_type)

	return expired_effects

func _serialize_equipment() -> Dictionary:
	var serialized = {}
	for slot in equipment.keys():
		var item = equipment[slot]
		serialized[slot] = item.to_dict() if item else null
	return serialized

func to_dict() -> Dictionary:
	return {
		"name": name,
		"character_class": character_class,
		"level": level,
		"experience": experience,
		"health": health,
		"max_health": max_health,
		"attack": attack,
		"defense": defense,
		"dexterity": dexterity,
		"mana": mana,
		"max_mana": max_mana,
		"inventory": inventory.map(func(item): return item.to_dict() if item else null),
		"equipment": _serialize_equipment(),
		"skills": skills.map(func(skill): return skill.to_dict() if skill else null),
		"gold": gold,
		"status_effects": status_effects
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", "")
	character_class = data.get("character_class", "")
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	health = data.get("health", 100)
	max_health = data.get("max_health", 100)
	attack = data.get("attack", 10)
	defense = data.get("defense", 5)
	dexterity = data.get("dexterity", 5)
	mana = data.get("mana", 0)
	max_mana = data.get("max_mana", 0)
	gold = data.get("gold", 0)

	# Load inventory
	inventory = data.get("inventory", []).map(func(item_data):
		if item_data:
			var item = Item.new()
			item.from_dict(item_data)
			return item
		return null
	)
	inventory.resize(20)

	# Load equipment
	equipment = data.get("equipment", {})

	# Load skills
	skills = data.get("skills", []).map(func(skill_data):
		if skill_data:
			var skill = Skill.new()
			skill.from_dict(skill_data)
			return skill
		return null
	)

	# Load status effects
	status_effects = data.get("status_effects", {})
