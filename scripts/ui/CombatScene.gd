extends Control

# CombatScene - Redesigned turn-based combat interface

@onready var player_sprite = $MainContainer/ArenaPanel/HBoxContainer/PlayerSprite
@onready var monster_sprite = $MainContainer/ArenaPanel/HBoxContainer/MonsterSprite

@onready var player_name_label = $MainContainer/InfoPanel/PlayerInfo/VBoxContainer/PlayerName
@onready var player_health_bar = $MainContainer/InfoPanel/PlayerInfo/VBoxContainer/PlayerHealthBar

@onready var monster_name_label = $MainContainer/InfoPanel/MonsterInfo/VBoxContainer/MonsterName
@onready var monster_health_bar = $MainContainer/InfoPanel/MonsterInfo/VBoxContainer/MonsterHealthBar

@onready var combat_log = $MainContainer/BottomPanel/CombatLogPanel/CombatLog

const SKILLS_DIALOG = preload("res://scenes/ui/skills_dialog.tscn")
var skills_dialog_instance = null

func _ready():
    print("CombatScene ready")
    # Connect to GameManager signals
    GameManager.connect("combat_started", Callable(self, "_on_combat_started"))
    GameManager.connect("player_attacked", Callable(self, "_on_player_attacked"))
    GameManager.connect("monster_attacked", Callable(self, "_on_monster_attacked"))
    GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))
    GameManager.connect("loot_dropped", Callable(self, "_on_loot_dropped"))
    GameManager.connect("player_leveled_up", Callable(self, "_on_player_leveled_up"))
    GameManager.connect("boss_phase_changed", Callable(self, "_on_boss_phase_changed"))
    GameManager.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

    _update_ui()

func _update_ui():
    _update_player_ui()
    _update_monster_ui()

func _update_player_ui():
    var player = GameManager.get_player()
    if not player:
        return
    player_name_label.text = player.name
    player_health_bar.max_value = player.max_health
    # Use animated value change for smooth health transitions
    player_health_bar.set_value_animated(player.health, true)
    # TODO: Set player sprite based on class

func _update_monster_ui():
    var monster = GameManager.get_current_monster()
    if not monster:
        monster_name_label.text = "No Monster"
        monster_health_bar.set_value_animated(0, true)
        return

    var name_text = monster.name + " (Lv." + str(monster.level) + ")"
    if GameManager.is_boss_combat():
        name_text += " [Phase " + str(monster.current_phase) + "/4]"
    monster_name_label.text = name_text

    monster_health_bar.max_value = monster.max_health
    # Use animated value change for smooth health transitions
    monster_health_bar.set_value_animated(monster.health, true)
    # TODO: Set monster sprite based on type

func _append_to_log(message: String):
    if combat_log:
        combat_log.text += "\n" + message
        combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func _on_combat_started(monster_name_param: String):
    _update_ui()
    _append_to_log("[center]Combat begins![/center]")

func _on_player_attacked(damage: int, is_critical: bool):
    _append_to_log(GameManager.get_combat_log())
    _update_ui()
    if GameManager.in_combat:
        await get_tree().create_timer(1.0).timeout
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
        if GameManager.is_boss_combat():
            _append_to_log(message)
            if is_inside_tree():
                await get_tree().create_timer(2.0).timeout
            GameManager.trigger_victory()
            GameManager.change_scene("victory_scene")
        else:
            _append_to_log(message)
            if is_inside_tree():
                await get_tree().create_timer(2.0).timeout
            _change_to_exploration()
    else:
        message = "[color=red]Defeat! You were defeated...[/color]"
        _append_to_log(message)
        if is_inside_tree():
            await get_tree().create_timer(2.0).timeout
        GameManager.change_scene("game_over_scene")

func _on_loot_dropped(item_name: String):
    _append_to_log("[color=yellow]You found: " + item_name + "[/color]")

func _on_player_leveled_up(new_level: int):
    _append_to_log("[color=blue]Level up! You are now level " + str(new_level) + "![/color]")
    _update_ui()

func _on_boss_phase_changed(phase: int, description: String):
    _append_to_log("[color=red]" + description + "[/color]")
    _update_ui()

func _on_boss_defeated():
    _append_to_log("[color=gold]THE DARK OVERLORD HAS BEEN DEFEATED![/color]")

func _on_attack_pressed():
    if not GameManager.in_combat: return
    var result = GameManager.player_attack()
    _append_to_log(result)
    _update_ui()

func _on_skills_pressed():
    if not GameManager.in_combat or not GameManager.get_player(): return
    var player = GameManager.get_player()
    if player.skills.size() == 0:
        _append_to_log("You have no skills to use!")
        return
    if skills_dialog_instance == null:
        skills_dialog_instance = SKILLS_DIALOG.instantiate()
        add_child(skills_dialog_instance)
        skills_dialog_instance.connect("skill_selected", Callable(self, "_on_skill_selected"))
        skills_dialog_instance.connect("cancelled", Callable(self, "_on_skills_cancelled"))

func _on_items_pressed():
    if not GameManager.in_combat: return
    _append_to_log("Items not implemented yet")

func _on_run_pressed():
    if not GameManager.in_combat: return
    if randf() < 0.5:
        GameManager.end_combat()
        _append_to_log("You successfully ran away!")
        await get_tree().create_timer(1.0).timeout
        _change_to_exploration()
    else:
        _append_to_log("Failed to run away!")
        await get_tree().create_timer(1.0).timeout
        var monster_attack_msg = GameManager.monster_attack()
        _append_to_log(monster_attack_msg)
        _update_ui()

func _change_to_exploration():
    GameManager.change_scene("exploration_scene")

func _on_skill_selected(skill_index: int):
    var result = GameManager.player_use_skill(skill_index)
    _append_to_log(result)
    _update_ui()
    skills_dialog_instance = null

func _on_skills_cancelled():
    skills_dialog_instance = null