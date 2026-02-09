extends GutTest

# Tests for ExplorationEventFactory

const Factory = preload("res://scripts/utils/ExplorationEventFactory.gd")


func test_event_has_valid_structure():
	var event = Factory.generate_event("forest", 1, 0.0)
	assert_has(event, "type", "Event should have type")
	assert_has(event, "title", "Event should have title")
	assert_has(event, "narrative", "Event should have narrative")
	assert_has(event, "choices", "Event should have choices")
	assert_has(event, "rewards", "Event should have rewards")


func test_event_type_is_valid():
	for _i in range(20):
		var event = Factory.generate_event("forest", 1, 0.0)
		assert_has(
			["combat", "discovery", "choice", "flavor", "quest"],
			event.type,
			"Event type should be one of the valid types"
		)


func test_town_only_generates_flavor():
	for _i in range(30):
		var event = Factory.generate_event("town", 1, 0.0)
		assert_eq(event.type, "flavor", "Town should only generate flavor events")


func test_combat_event_has_monster_type():
	# Generate many events until we get a combat one
	var found_combat = false
	for _i in range(100):
		var event = Factory.generate_event("forest", 1, 10.0)
		if event.type == "combat":
			found_combat = true
			assert_ne(event.monster_type, "", "Combat event should have a monster_type")
			assert_has(
				["goblin", "slime", "wolf"],
				event.monster_type,
				"Forest combat should use forest monster pool"
			)
			break
	assert_true(found_combat, "Should find at least one combat event in 100 tries")


func test_discovery_event_has_rewards():
	var found_discovery = false
	for _i in range(100):
		var event = Factory.generate_event("forest", 1, 0.0)
		if event.type == "discovery":
			found_discovery = true
			assert_true(
				event.rewards.size() > 0,
				"Discovery event should have non-empty rewards"
			)
			break
	assert_true(found_discovery, "Should find at least one discovery event in 100 tries")


func test_choice_event_has_multiple_choices():
	var found_choice = false
	for _i in range(100):
		var event = Factory.generate_event("forest", 1, 0.0)
		if event.type == "choice":
			found_choice = true
			assert_true(
				event.choices.size() >= 2,
				"Choice event should have at least 2 choices"
			)
			# Verify each choice has required fields
			for choice in event.choices:
				assert_has(choice, "label", "Choice should have label")
				assert_has(choice, "id", "Choice should have id")
				assert_has(choice, "result_narrative", "Choice should have result_narrative")
				assert_has(choice, "rewards", "Choice should have rewards")
			break
	assert_true(found_choice, "Should find at least one choice event in 100 tries")


func test_cave_monster_pool():
	var found_combat = false
	for _i in range(100):
		var event = Factory.generate_event("cave", 5, 10.0)
		if event.type == "combat":
			found_combat = true
			assert_has(
				["skeleton", "spider", "bat"],
				event.monster_type,
				"Cave combat should use cave monster pool"
			)
			break
	assert_true(found_combat, "Should find at least one combat event in cave")


func test_peak_monster_pool():
	var found_combat = false
	for _i in range(100):
		var event = Factory.generate_event("peak", 8, 10.0)
		if event.type == "combat":
			found_combat = true
			assert_has(
				["orc", "troll", "dragon"],
				event.monster_type,
				"Peak combat should use peak monster pool"
			)
			break
	assert_true(found_combat, "Should find at least one combat event on peak")


func test_danger_flavor_levels():
	assert_eq(
		Factory.get_danger_flavor(0.0),
		"The air is calm and still.",
		"Low danger should be calm"
	)
	assert_eq(
		Factory.get_danger_flavor(7.0),
		"You sense movement in the shadows.",
		"Medium-low danger should mention shadows"
	)
	assert_eq(
		Factory.get_danger_flavor(22.0),
		"Death stalks your every step.",
		"High danger should be dire"
	)


func test_flavor_event_has_narrative():
	var event = Factory.generate_event("town", 1, 0.0)
	assert_ne(event.narrative, "", "Flavor event should have narrative text")
	assert_eq(event.choices.size(), 0, "Flavor event should have no choices")


func test_unknown_area_defaults_to_forest():
	var event = Factory.generate_event("nonexistent", 1, 0.0)
	assert_has(event, "type", "Unknown area should still generate valid event")
	assert_has(event, "narrative", "Unknown area should have narrative")
