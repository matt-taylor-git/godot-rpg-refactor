class_name SkillFactory
extends Node

# SkillFactory - Creates skill instances

static func create_skill(skill_type: String) -> Skill:
	var skill = Skill.new()

	match skill_type:
		"slash":
			skill.name = "Slash"
			skill.description = "A powerful slashing attack"
			skill.required_level = 1
			skill.cooldown = 2
			skill.damage_multiplier = 1.5

		"heal":
			skill.name = "Heal"
			skill.description = "Restore health to self"
			skill.required_level = 2
			skill.cooldown = 3
			skill.healing_amount = 30
			skill.effect_type = "heal"

		"fireball":
			skill.name = "Fireball"
			skill.description = "Launch a fireball at enemy"
			skill.required_level = 3
			skill.required_class = "Mage"
			skill.cooldown = 4
			skill.damage_multiplier = 2.0
			skill.mana_cost = 10

		"stealth":
			skill.name = "Stealth"
			skill.description = "Become harder to hit"
			skill.required_level = 2
			skill.required_class = "Rogue"
			skill.cooldown = 5
			skill.effect_type = "buff"

		_:
			# Default skill
			skill.name = "Unknown Skill"
			skill.description = "An unknown ability"
			skill.required_level = 1
			skill.cooldown = 1
			skill.damage_multiplier = 1.0

	return skill

static func get_class_skills(character_class: String) -> Array:
	var skills = []

	match character_class:
		"Hero":
			skills = ["slash", "heal"]
		"Warrior":
			skills = ["slash", "charge"]
		"Mage":
			skills = ["fireball", "lightning"]
		"Rogue":
			skills = ["stealth", "backstab"]
		_:
			skills = ["slash"]

	var skill_objects = []
	for skill_name in skills:
		skill_objects.append(create_skill(skill_name))

	return skill_objects
