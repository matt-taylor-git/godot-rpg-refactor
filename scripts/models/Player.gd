extends Resource
class_name Player

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

@export var inventory: Array = []  # Array of Item resources
@export var equipment: Dictionary = {}  # weapon, armor, etc.
@export var skills: Array = []  # Array of Skill resources

@export var gold: int = 0

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
	# TODO: Level up logic

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
		"inventory": inventory.map(func(item): return item.to_dict() if item else null),
		"equipment": equipment,
		"skills": skills.map(func(skill): return skill.to_dict() if skill else null),
		"gold": gold
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
