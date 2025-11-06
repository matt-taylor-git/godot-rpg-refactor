extends Control

# CombatScene - Turn-based combat interface with player and monster displays

@onready var monster_sprite = $VBoxContainer/MonsterSection/MonsterSprite
@onready var monster_name = $VBoxContainer/MonsterSection/MonsterInfo/MonsterName
@onready var monster_health_bar = $VBoxContainer/MonsterSection/MonsterInfo/MonsterHealthBar
@onready var combat_log = $VBoxContainer/CombatLog
@onready var player_name = $VBoxContainer/PlayerSection/PlayerInfo/PlayerName
@onready var player_health_bar = $VBoxContainer/PlayerSection/PlayerInfo/PlayerHealthBar
@onready var player_stats = $VBoxContainer/PlayerSection/PlayerInfo/PlayerStats
@onready var action_buttons = $VBoxContainer/PlayerSection/ActionButtons

# Skills dialog
const SKILLS_DIALOG = preload("res://scenes/ui/skills_dialog.tscn")
# const ITEMS_DIALOG = preload("res://scenes/ui/items_dialog.tscn")  # TODO: Create items dialog

var skills_dialog_instance = null
var items_dialog_instance = null

func _ready():
	print("CombatScene ready")

	# Connect to GameManager signals
	GameManager.connect("combat_started", Callable(self, "_on_combat_started"))
	GameManager.connect("player_attacked", Callable(self, "_on_player_attacked"))
	GameManager.connect("monster_attacked", Callable(self, "_on_monster_attacked"))
	GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	GameManager.connect("loot_dropped", Callable(self, "_on_loot_dropped"))
	GameManager.connect("player_leveled_up", Callable(self, "_on_player_leveled_up"))

	# Update initial UI
	_update_ui()

func _update_ui():
	if not GameManager.get_player():
		return

	var player = GameManager.get_player()
	player_name.text = player.name
	player_health_bar.max_value = player.max_health
	player_health_bar.value = player.health
	player_stats.text = "Level: %d\nHP: %d/%d\nEXP: %d" % [
		player.level, player.health, player.max_health, player.experience
	]

	var monster = GameManager.get_current_monster()
	if monster:
		monster_name.text = monster.name + " (Lv." + str(monster.level) + ")"
		monster_health_bar.max_value = monster.max_health
		monster_health_bar.value = monster.health
		# TODO: Set monster sprite based on type
		# monster_sprite.texture = load("res://assets/monsters/" + monster.type + ".png")
	else:
		monster_name.text = "No Monster"
		monster_health_bar.value = 0

func _append_to_log(message: String):
	combat_log.text += "\n" + message
	# Scroll to bottom
	await get_tree().process_frame
	combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func _on_combat_started(monster_name_param: String):
	print("Combat started with: ", monster_name_param)
	_update_ui()
	_append_to_log("[center]Combat begins![/center]")

func _on_player_attacked(damage: int, is_critical: bool):
	var message = GameManager.get_combat_log()
	_append_to_log(message)

	_update_ui()

	# If combat still ongoing, monster attacks next
	if GameManager.in_combat:
		await get_tree().create_timer(1.0).timeout  # Delay for turn feel
		var monster_attack_msg = GameManager.monster_attack()
		_append_to_log(monster_attack_msg)
		_update_ui()

func _on_monster_attacked(damage: int):
	_append_to_log(GameManager.get_combat_log())
	_update_ui()

func _on_combat_ended(player_won: bool):
	var message = ""
	if player_won:
		message = "[color=green]Victory! You defeated the monster![/color]"
		# Auto-return to exploration after short delay
		await get_tree().create_timer(2.0).timeout
		_change_to_exploration()
	else:
		message = "[color=red]Defeat! You were defeated...[/color]"
		# TODO: Game over screen
	_append_to_log(message)

func _on_loot_dropped(item_name: String):
	_append_to_log("[color=yellow]You found: " + item_name + "[/color]")

func _on_player_leveled_up(new_level: int):
	_append_to_log("[color=blue]Level up! You are now level " + str(new_level) + "![/color]")
	_update_ui()

func _on_attack_pressed():
	if not GameManager.in_combat:
		return

	print("Player attacks")
	var result = GameManager.player_attack()
	_append_to_log(result)
	_update_ui()

func _on_skills_pressed():
	if not GameManager.in_combat or not GameManager.get_player():
		return

	var player = GameManager.get_player()
	if player.skills.size() == 0:
		_append_to_log("You have no skills to use!")
		return

	# Show skills dialog
	if skills_dialog_instance == null:
		skills_dialog_instance = SKILLS_DIALOG.instantiate()
		add_child(skills_dialog_instance)
		skills_dialog_instance.connect("skill_selected", Callable(self, "_on_skill_selected"))
		skills_dialog_instance.connect("cancelled", Callable(self, "_on_skills_cancelled"))

func _on_items_pressed():
	if not GameManager.in_combat:
		return

	# TODO: Implement items dialog
	_append_to_log("Items not implemented yet")

func _on_run_pressed():
	if not GameManager.in_combat:
		return

	# Simple run logic: 50% chance to succeed
	var run_success = randf() < 0.5
	if run_success:
		GameManager.end_combat()
		_append_to_log("You successfully ran away!")
		await get_tree().create_timer(1.0).timeout
		_change_to_exploration()
	else:
		_append_to_log("Failed to run away!")
		# Monster gets a free attack
		await get_tree().create_timer(1.0).timeout
		var monster_attack_msg = GameManager.monster_attack()
		_append_to_log(monster_attack_msg)
		_update_ui()

func _change_to_exploration():
	# Return to exploration scene
	print("Returning to exploration")
	get_tree().change_scene_to_file("res://scenes/ui/exploration_scene.tscn")

# Placeholder methods for future dialogs
func _on_skill_selected(skill_index: int):
	var result = GameManager.player_use_skill(skill_index)
	_append_to_log(result)
	_update_ui()
	skills_dialog_instance = null  # Reset for next use

func _on_skills_cancelled():
	skills_dialog_instance = null

func _on_items_selected(item_index: int):
	pass  # TODO: Implement item usage

func _on_items_cancelled():
	pass
