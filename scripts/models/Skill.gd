class_name Skill
extends Resource

# Skill - Abilities that can be used in combat

@export var name: String = ""
@export var description: String = ""
@export var required_level: int = 1
@export var required_class: String = ""  # Specific class or empty for all

@export var cooldown: int = 0
@export var current_cooldown: int = 0

@export var damage_multiplier: float = 1.0
@export var healing_amount: int = 0
@export var effect_type: String = "damage"  # damage, heal, buff, debuff

@export var mana_cost: int = 0

func _init():
	pass

func can_use(user) -> bool:
	if current_cooldown > 0:
		return false
	if mana_cost > 0 and user.mana < mana_cost:
		return false
	# Level gate only applies when learning skills; if it's on the bar, it is usable.
	# (Old saves still have required_level=2 on starting skills.)
	if required_class and user.character_class != required_class:
		return false
	return true

func get_unusable_reason(user) -> String:
	if current_cooldown > 0:
		return "On cooldown (%d turns)" % current_cooldown
	if mana_cost > 0 and user.mana < mana_cost:
		return "Need %d MP (have %d)" % [mana_cost, user.mana]
	if required_class and user.character_class != required_class:
		return "Requires class: %s" % required_class
	return ""

func use(user, target) -> Dictionary:
	var result = {
		"success": false,
		"damage": 0,
		"healing": 0,
		"effects": []
	}

	if not can_use(user):
		return result

	result.success = true

	if mana_cost > 0:
		if user.has_method("spend_mana"):
			user.spend_mana(mana_cost)
		else:
			user.mana = maxi(0, user.mana - mana_cost)

	match effect_type:
		"damage":
			var defense_power: int = target.defense
			if target.has_method("get_defense_power"):
				defense_power = target.get_defense_power()
			var outgoing_multiplier := 1.0
			if user.has_method("get_outgoing_damage_multiplier"):
				outgoing_multiplier = user.get_outgoing_damage_multiplier()
			var damage := CombatRules.roll_damage(
				user.get_attack_power(),
				defense_power,
				damage_multiplier * outgoing_multiplier,
			)
			target.take_damage(damage)
			result.damage = damage
		"heal":
			var scaled_healing := maxi(30, roundi(float(user.max_health) * 0.25))
			var old_health: int = user.health
			user.heal(scaled_healing)
			result.healing = user.health - old_health
		"buff":
			# Stealth / generic self-buff: temporary defense boost
			if user.has_method("add_status_effect"):
				user.add_status_effect("stealth", 2, {"defense_bonus": 20})
			result.effects.append("stealth")
		_:
			pass

	current_cooldown = cooldown
	return result

func tick_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1

func to_dict() -> Dictionary:
	return {
		"name": name,
		"description": description,
		"required_level": required_level,
		"required_class": required_class,
		"cooldown": cooldown,
		"current_cooldown": current_cooldown,
		"damage_multiplier": damage_multiplier,
		"healing_amount": healing_amount,
		"effect_type": effect_type,
		"mana_cost": mana_cost
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", "")
	description = data.get("description", "")
	required_level = data.get("required_level", 1)
	required_class = data.get("required_class", "")
	cooldown = data.get("cooldown", 0)
	current_cooldown = data.get("current_cooldown", 0)
	damage_multiplier = data.get("damage_multiplier", 1.0)
	healing_amount = data.get("healing_amount", 0)
	effect_type = data.get("effect_type", "damage")
	mana_cost = data.get("mana_cost", 0)
