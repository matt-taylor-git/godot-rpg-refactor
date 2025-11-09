extends Control

# ExplorationScene - World exploration interface with random encounters and rest mechanics

@onready var player_sprite = $Background/WorldArea/PlayerSprite
@onready var area_label = $Background/WorldArea/AreaLabel
@onready var player_stats_label = $UI/TopBar/PlayerStats
@onready var steps_label = $UI/TopBar/StepsLabel
@onready var encounter_chance_label = $UI/BottomBar/EncounterChanceLabel
@onready var explore_button = $UI/BottomBar/ActionButtons/ExploreButton
@onready var rest_button = $UI/BottomBar/ActionButtons/RestButton

# Exploration state
var steps_taken = 0
var encounter_chance = 0.0  # Percentage chance per step
var base_encounter_chance = 2.0  # 2% base chance
var max_encounter_chance = 25.0  # Cap at 25%
var steps_since_last_encounter = 0

# Player movement
var player_position = Vector2(400, 300)  # Center of screen
var movement_speed = 200.0
var is_moving = false
var target_position = Vector2.ZERO

func _ready():
	print("ExplorationScene ready")

	_load_exploration_state()
	_update_ui()

	# Set initial player sprite position
	if player_sprite:
		player_sprite.position = player_position - Vector2(32, 32)

	# Connect to GameManager signals
	GameManager.connect("game_loaded", Callable(self, "_on_game_loaded"))

func _process(delta):
	if is_moving and player_sprite:
		var direction = (target_position - player_position).normalized()
		var distance = player_position.distance_to(target_position)

		if distance > 5:
			player_position += direction * movement_speed * delta
			player_sprite.position = player_position - Vector2(32, 32)  # Center the 64x64 sprite
		else:
			player_position = target_position
			player_sprite.position = player_position - Vector2(32, 32)
			is_moving = false
			_on_reached_destination()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Don't move if clicking on UI buttons
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered and hovered is Button:
			return
		# Click to move
		target_position = event.position
		is_moving = true

func _update_ui():
	if not GameManager.get_player():
		return

	var player = GameManager.get_player()
	player_stats_label.text = "%s (Lv.%d) - HP: %d/%d - Gold: %d" % [
		player.name, player.level, player.health, player.max_health, player.gold
	]

	steps_label.text = "Steps: %d" % steps_taken

	var chance_text = "Low"
	if encounter_chance < 5:
		chance_text = "Low"
	elif encounter_chance < 15:
		chance_text = "Medium"
	else:
		chance_text = "High"
	encounter_chance_label.text = "Encounter chance: %s (%.1f%%)" % [chance_text, encounter_chance]

func _reset_encounter_chance():
	encounter_chance = base_encounter_chance
	steps_since_last_encounter = 0

func _take_step():
	steps_taken += 1
	steps_since_last_encounter += 1

	# Increase encounter chance over time without encounters
	encounter_chance = min(encounter_chance + 0.5, max_encounter_chance)

	# Check for random encounter
	var roll = randf() * 100
	if roll < encounter_chance:
		_trigger_encounter()

	_update_ui()

func _trigger_encounter():
	print("Random encounter triggered!")
	is_moving = false  # Stop movement

	# Save exploration state before combat
	_save_exploration_state()

	# Start combat
	GameManager.start_combat()
	# Scene will change automatically due to GameManager.start_combat()

func _on_reached_destination():
	_take_step()

func _on_explore_pressed():
	# Manual exploration - take multiple steps
	for i in range(5):
		_take_step()
	
	# Randomly offer a quest during exploration
	if randf() < 0.3:  # 30% chance to get a quest
		_offer_random_quest()

func _on_rest_pressed():
	if not GameManager.get_player():
		return

	var player = GameManager.get_player()

	# Rest for a bit, heal some HP
	var heal_amount = int(player.max_health * 0.2)  # 20% of max HP
	player.health = min(player.health + heal_amount, player.max_health)

	# Reset encounter chance after resting
	_reset_encounter_chance()

	_update_ui()

	# Show rest message
	print("Rested and recovered %d HP. Encounter chance reset." % heal_amount)

func _on_inventory_pressed():
	# Open inventory dialog
	var inventory_dialog = preload("res://scenes/ui/inventory_dialog.tscn").instantiate()
	add_child(inventory_dialog)
	print("Inventory dialog opened")

func _on_shop_pressed():
	# Open shop dialog
	var shop_dialog = preload("res://scenes/ui/shop_dialog.tscn").instantiate()
	add_child(shop_dialog)
	print("Shop dialog opened")

func _on_quest_log_pressed():
	# Open quest log dialog
	var quest_log_dialog = preload("res://scenes/ui/quest_log_dialog.tscn").instantiate()
	add_child(quest_log_dialog)
	print("Quest log dialog opened")

func _on_talk_pressed():
	# Open dialogue scene with a random NPC
	var npcs = ["village_elder", "merchant", "knight_commander"]
	var random_npc = npcs[randi() % npcs.size()]
	
	var dialogue_scene = preload("res://scenes/ui/dialogue_scene.tscn").instantiate()
	add_child(dialogue_scene)
	dialogue_scene.start_dialogue(random_npc)
	print("Started dialogue with: ", random_npc)

func _on_codex_pressed():
	# Open codex dialog
	var codex_dialog = preload("res://scenes/ui/codex_dialog.tscn").instantiate()
	add_child(codex_dialog)
	print("Codex dialog opened")

func _on_menu_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _load_exploration_state():
	var exploration_data = GameManager.get_exploration_state()
	steps_taken = exploration_data.get("steps_taken", 0)
	encounter_chance = exploration_data.get("encounter_chance", base_encounter_chance)
	steps_since_last_encounter = exploration_data.get("steps_since_last_encounter", 0)

func _save_exploration_state():
	GameManager.set_exploration_state({
		"steps_taken": steps_taken,
		"encounter_chance": encounter_chance,
		"steps_since_last_encounter": steps_since_last_encounter
	})

func _on_game_loaded():
	_load_exploration_state()
	_update_ui()

func _offer_random_quest():
	# Create and offer a random quest
	var player_level = 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	
	var quest = QuestFactory.get_random_quest(player_level)
	QuestManager.accept_quest(quest)
	print("Offered quest: ", quest.title)

# Save exploration state (could be added to GameManager later)
func get_exploration_data():
	return {
		"steps_taken": steps_taken,
		"encounter_chance": encounter_chance,
		"steps_since_last_encounter": steps_since_last_encounter
	}

func set_exploration_data(data):
	steps_taken = data.get("steps_taken", 0)
	encounter_chance = data.get("encounter_chance", base_encounter_chance)
	steps_since_last_encounter = data.get("steps_since_last_encounter", 0)
	_update_ui()
