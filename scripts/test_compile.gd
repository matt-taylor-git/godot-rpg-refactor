extends Node

func _ready():
	print("=== Compilation Test Started ===")
	
	# Test Monster instantiation
	var monster = Monster.new()
	print("✓ Monster class loads")
	
	# Test FinalBoss instantiation
	var boss = FinalBoss.new()
	print("✓ FinalBoss class loads")
	
	# Test set_stats_for_level
	boss.set_stats_for_level(5)
	print("✓ set_stats_for_level method exists")
	print("  Boss name: ", boss.name)
	print("  Boss health: ", boss.max_health)
	
	# Test MonsterFactory
	var test_boss = MonsterFactory.create_final_boss(5)
	print("✓ MonsterFactory.create_final_boss works")
	print("  Created boss: ", test_boss.name, " (level ", test_boss.level, ")")
	
	# Test GameManager loads
	var gm = GameManager
	print("✓ GameManager autoload loads successfully")
	
	print("\n=== All Compilation Tests Passed ===")
	get_tree().quit(0)
