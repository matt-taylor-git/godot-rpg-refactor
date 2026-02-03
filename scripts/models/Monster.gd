class_name Monster
extends Resource

# Monster - Enemy data and behavior

@export var name: String = ""
@export var level: int = 1
@export var health: int = 50
@export var max_health: int = 50
@export var attack: int = 8
@export var defense: int = 3
@export var dexterity: int = 3

@export var loot_table: Array = []  # Array of dictionaries: {item: Item, chance: float}
@export var experience_reward: int = 10
@export var gold_reward: int = 5

@export var ai_behavior: String = "aggressive"  # aggressive, defensive, etc.

# Status effects: effect_type -> {duration: int, data: Dictionary}
@export var status_effects: Dictionary = {}

func _init():
	loot_table = []

func take_damage(amount: int) -> void:
	health = max(0, health - amount)

func is_alive() -> bool:
	return health > 0

func get_loot() -> Array:
	var drops = []
	for loot_entry in loot_table:
		if randf() <= loot_entry.chance:
			drops.append(loot_entry.item)
	return drops

func get_ai_action() -> String:
	# Simple AI logic
	match ai_behavior:
		"aggressive":
			return "attack"
		"defensive":
			if health < max_health * 0.3:
				return "defend"
			return "attack"
		_:
			return "attack"

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
	# Check if monster has a specific status effect
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

func to_dict() -> Dictionary:
	return {
		"name": name,
		"level": level,
		"health": health,
		"max_health": max_health,
		"attack": attack,
		"defense": defense,
		"dexterity": dexterity,
		"loot_table": loot_table,
		"experience_reward": experience_reward,
		"gold_reward": gold_reward,
		"ai_behavior": ai_behavior,
		"status_effects": status_effects
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", "")
	level = data.get("level", 1)
	health = data.get("health", 50)
	max_health = data.get("max_health", 50)
	attack = data.get("attack", 8)
	defense = data.get("defense", 3)
	dexterity = data.get("dexterity", 3)
	loot_table = data.get("loot_table", [])
	experience_reward = data.get("experience_reward", 10)
	gold_reward = data.get("gold_reward", 5)
	ai_behavior = data.get("ai_behavior", "aggressive")
	status_effects = data.get("status_effects", {})
