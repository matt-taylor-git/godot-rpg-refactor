class_name CombatRules
extends RefCounted

## Shared, deterministic combat math for attacks, skills, and intent previews.

const CRITICAL_MULTIPLIER := 1.5
const DEFENSE_MULTIPLIER := 0.5
const MIN_VARIANCE := 0.92
const MAX_VARIANCE := 1.08


static func calculate_damage(
	attack_power: int,
	defense_power: int,
	action_multiplier: float = 1.0,
	is_critical: bool = false,
	variance: float = 1.0,
) -> int:
	var critical_multiplier := CRITICAL_MULTIPLIER if is_critical else 1.0
	var raw_damage := float(attack_power) * action_multiplier * critical_multiplier
	var mitigated_damage := maxf(1.0, raw_damage - float(defense_power) * DEFENSE_MULTIPLIER)
	return maxi(1, roundi(mitigated_damage * variance))


static func roll_damage(
	attack_power: int,
	defense_power: int,
	action_multiplier: float = 1.0,
	is_critical: bool = false,
) -> int:
	return calculate_damage(
		attack_power,
		defense_power,
		action_multiplier,
		is_critical,
		randf_range(MIN_VARIANCE, MAX_VARIANCE),
	)


static func estimate_range(
	attack_power: int,
	defense_power: int,
	action_multiplier: float = 1.0,
	is_critical: bool = false,
) -> Dictionary:
	return {
		"min": calculate_damage(
			attack_power, defense_power, action_multiplier, is_critical, MIN_VARIANCE),
		"max": calculate_damage(
			attack_power, defense_power, action_multiplier, is_critical, MAX_VARIANCE),
	}


static func get_escape_chance(failed_attempts: int, final_boss: bool = false) -> float:
	if final_boss:
		return 0.0
	return 1.0 if failed_attempts > 0 else 0.75
