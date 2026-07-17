extends Control

# CombatScene - Location-stage combat with dock actions and arena feedback.

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const LOW_HP_THRESHOLD := 0.25

var animation_controller: CombatAnimationController = null
var turn_indicator: TurnIndicatorController = null
var performance_monitor: PerformanceMonitor = null
var reduced_motion: bool = false
var input_locked: bool = false
var round_number: int = 1
var log_expanded: bool = false
var dock_mode: String = "root" # root | skills | items
# Legacy aliases filled in _ready for integration tests
var player_portrait = null
var monster_portrait = null
var player_health_bar = null
var player_mana_bar = null
var monster_health_bar = null
var _low_hp_active: bool = false
var _phase_banner: Label = null
var _history: PackedStringArray = PackedStringArray()

@onready var stage_background: TextureRect = $StageLayer/StageBackground
@onready var stage_darken: ColorRect = $StageLayer/StageDarken
@onready var stage_vignette: ColorRect = $StageLayer/StageVignette
@onready var turn_banner = $MainColumn/ArenaLayer/TurnBanner
@onready var player_stage = $MainColumn/ArenaLayer/Combatants/PlayerStage
@onready var monster_stage = $MainColumn/ArenaLayer/Combatants/MonsterStage
@onready var fx_layer: Control = $MainColumn/ArenaLayer/FXLayer
@onready var event_strip: PanelContainer = $MainColumn/DockLayer/EventStrip
@onready var event_label: Label = $MainColumn/DockLayer/EventStrip/EventMargin/EventLabel
@onready var action_dock: PanelContainer = $MainColumn/DockLayer/ActionDock
@onready var root_actions: HBoxContainer = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/RootActions
@onready var attack_button: Button = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/RootActions/AttackButton
@onready var skills_button: Button = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/RootActions/SkillsButton
@onready var items_button: Button = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/RootActions/ItemsButton
@onready var run_button: Button = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/RootActions/RunButton
@onready var skills_panel: VBoxContainer = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/SkillsPanel
@onready var skills_list: HBoxContainer = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/SkillsPanel/SkillsList
@onready var skill_desc: Label = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/SkillsPanel/SkillDesc
@onready var items_panel: VBoxContainer = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/ItemsPanel
@onready var items_list: HBoxContainer = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/ItemsPanel/ItemsList
@onready var items_empty: Label = $MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/ItemsPanel/ItemsEmpty
@onready var log_toggle: Button = $MainColumn/DockLayer/LogSection/LogToggle
@onready var combat_log_panel: PanelContainer = $MainColumn/DockLayer/LogSection/CombatLogPanel
@onready var combat_log: RichTextLabel = $MainColumn/DockLayer/LogSection/CombatLogPanel/LogMargin/CombatLog


func _ready() -> void:
	print("CombatScene ready")
	player_portrait = player_stage
	monster_portrait = monster_stage
	if player_stage:
		player_health_bar = player_stage.health_bar
		player_mana_bar = player_stage.mana_bar
	if monster_stage:
		monster_health_bar = monster_stage.health_bar
	_setup_animation_systems()
	_apply_stage_background()
	_style_chrome()
	_configure_root_actions()
	_set_dock_mode("root")
	_set_log_expanded(false)

	GameManager.connect("combat_started", Callable(self, "_on_combat_started"))
	GameManager.connect("player_attacked", Callable(self, "_on_player_attacked"))
	GameManager.connect("monster_attacked", Callable(self, "_on_monster_attacked"))
	GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	GameManager.connect("loot_dropped", Callable(self, "_on_loot_dropped"))
	GameManager.connect("player_leveled_up", Callable(self, "_on_player_leveled_up"))
	GameManager.connect("boss_phase_changed", Callable(self, "_on_boss_phase_changed"))
	GameManager.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	# Scene often loads after combat_started already emitted — seed UI from current state.
	if GameManager.in_combat:
		GameManager.refresh_monster_intent()
		var mon = GameManager.get_current_monster()
		var mon_name: String = "enemy"
		if mon:
			mon_name = str(mon.name)
		_append_event("Combat begins! A %s appears." % mon_name)
		_update_ui()
		_show_player_turn(false)
	else:
		_update_ui()
		_show_player_turn(false)
	_setup_focus_navigation()
	if performance_monitor:
		performance_monitor.start_monitoring()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked or not GameManager.in_combat:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if dock_mode != "root":
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_BACKSPACE:
			_set_dock_mode("root")
			get_viewport().set_input_as_handled()
		return
	match key.keycode:
		KEY_1, KEY_KP_1:
			_on_attack_pressed()
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			_on_skills_pressed()
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			_on_items_pressed()
			get_viewport().set_input_as_handled()
		KEY_4, KEY_KP_4:
			_on_run_pressed()
			get_viewport().set_input_as_handled()


func apply_screenshot_state(state: Dictionary) -> void:
	# Tour / test helper — seed HP, open dock modes, expand log.
	var player = GameManager.get_player()
	if player and state.has("player_hp_frac"):
		var frac: float = clampf(float(state["player_hp_frac"]), 0.01, 1.0)
		player.health = maxi(1, int(player.max_health * frac))
	var ui_mode := str(state.get("combat_ui", "root"))
	match ui_mode:
		"skills":
			_set_dock_mode("skills")
		"items":
			_set_dock_mode("items")
		"log_open":
			_set_log_expanded(true)
		_:
			_set_dock_mode("root")
	_update_ui()
	_update_low_hp_vignette()
	_refresh_intent()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if animation_controller:
		animation_controller.set_reduced_motion(enabled)
	if turn_indicator:
		turn_indicator.set_reduced_motion(enabled)
	if turn_banner:
		turn_banner.set_reduced_motion(enabled)
	if player_stage:
		player_stage.set_reduced_motion(enabled)
	if monster_stage:
		monster_stage.set_reduced_motion(enabled)


func _setup_animation_systems() -> void:
	reduced_motion = ProjectSettings.get_setting("accessibility/reduced_motion", false)
	if GameSettings:
		reduced_motion = GameSettings.get_reduced_motion()

	animation_controller = CombatAnimationController.new()
	animation_controller.name = "CombatAnimationController"
	add_child(animation_controller)

	var p_fig = player_stage.get_figure_node() if player_stage else null
	var m_fig = monster_stage.get_figure_node() if monster_stage else null
	animation_controller.setup(p_fig, m_fig, null, fx_layer if fx_layer else self)
	animation_controller.set_reduced_motion(reduced_motion)
	animation_controller.animation_started.connect(_on_animation_started)
	animation_controller.animation_completed.connect(_on_animation_completed)
	animation_controller.damage_number_spawned.connect(_on_damage_number_spawned)

	turn_indicator = TurnIndicatorController.new()
	turn_indicator.name = "TurnIndicatorController"
	add_child(turn_indicator)
	turn_indicator.setup(p_fig, m_fig)
	turn_indicator.set_reduced_motion(reduced_motion)

	performance_monitor = PerformanceMonitor.new()
	performance_monitor.name = "PerformanceMonitor"
	add_child(performance_monitor)
	performance_monitor.fps_warning.connect(_on_fps_warning)
	performance_monitor.memory_warning.connect(_on_memory_warning)

	if turn_banner:
		turn_banner.set_reduced_motion(reduced_motion)
		turn_banner.set_round(round_number)


func _apply_stage_background() -> void:
	var area_id := "forest"
	if GameManager.game_data is Dictionary:
		area_id = str(GameManager.game_data.get("current_area_id", "forest"))
	if area_id.is_empty():
		area_id = "forest"
	var path := _location_image_path(area_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		path = "res://assets/locations/forest.png"
	if stage_background and ResourceLoader.exists(path):
		stage_background.texture = load(path)
	if stage_darken:
		stage_darken.color = Color(0.04, 0.03, 0.025, 0.50)


func _location_image_path(area_id: String) -> String:
	# Prefer known promoted location paths (avoids orphan ExplorationManager nodes).
	var known := {
		"town": "res://assets/locations/town.png",
		"forest": "res://assets/locations/forest.png",
		"mountain": "res://assets/locations/mountain.png",
		"cave": "res://assets/locations/cave.png",
		"peak": "res://assets/locations/peak.png",
	}
	if known.has(area_id):
		return known[area_id]
	return "res://assets/locations/forest.png"


func _style_chrome() -> void:
	StageChrome.style_quiet_strip(event_strip)
	StageChrome.style_floating_panel(action_dock)
	StageChrome.style_floating_panel(combat_log_panel)
	StageChrome.style_log_toggle(log_toggle)
	if event_label:
		var serif := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
		if ResourceLoader.exists(serif):
			event_label.add_theme_font_override("font", load(serif))
		event_label.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_BODY_REGULAR)
		event_label.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())


func _configure_root_actions() -> void:
	StageChrome.style_primary_action(attack_button)
	StageChrome.style_secondary_action(skills_button)
	StageChrome.style_secondary_action(items_button)
	StageChrome.style_danger_action(run_button)
	StageChrome.set_button_label(attack_button, "1  Attack")
	StageChrome.set_button_label(skills_button, "2  Skills")
	StageChrome.set_button_label(items_button, "3  Items")
	StageChrome.set_button_label(run_button, "4  Run")
	if attack_button:
		attack_button.add_theme_constant_override("icon_max_width", 28)
		attack_button.expand_icon = false
	var skills_back = get_node_or_null(
		"MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/SkillsPanel/SkillsHeader/SkillsBackButton")
	var items_back = get_node_or_null(
		"MainColumn/DockLayer/ActionDock/ActionMargin/DockStack/ItemsPanel/ItemsHeader/ItemsBackButton")
	StageChrome.style_secondary_action(skills_back)
	StageChrome.style_secondary_action(items_back)
	if skills_back:
		skills_back.custom_minimum_size = Vector2(90, 32)
		StageChrome.set_button_label(skills_back, "Back")
	if items_back:
		items_back.custom_minimum_size = Vector2(90, 32)
		StageChrome.set_button_label(items_back, "Back")


func _setup_focus_navigation() -> void:
	if attack_button == null:
		return
	attack_button.focus_neighbor_right = skills_button.get_path()
	skills_button.focus_neighbor_left = attack_button.get_path()
	skills_button.focus_neighbor_right = items_button.get_path()
	items_button.focus_neighbor_left = skills_button.get_path()
	items_button.focus_neighbor_right = run_button.get_path()
	run_button.focus_neighbor_left = items_button.get_path()
	attack_button.grab_focus()


func _set_input_locked(locked: bool) -> void:
	input_locked = locked
	for btn in [attack_button, skills_button, items_button, run_button]:
		if btn:
			btn.disabled = locked
	if skills_list:
		for child in skills_list.get_children():
			if child is Button:
				child.disabled = locked
	if items_list:
		for child in items_list.get_children():
			if child is Button:
				child.disabled = locked


func _set_dock_mode(mode: String) -> void:
	dock_mode = mode
	if root_actions:
		root_actions.visible = mode == "root"
	if skills_panel:
		skills_panel.visible = mode == "skills"
	if items_panel:
		items_panel.visible = mode == "items"
	if mode == "skills":
		_populate_skills_dock()
	elif mode == "items":
		_populate_items_dock()
	elif mode == "root" and attack_button and not input_locked:
		attack_button.grab_focus()


func _set_log_expanded(expanded: bool) -> void:
	log_expanded = expanded
	if combat_log_panel:
		combat_log_panel.visible = expanded
	if log_toggle:
		StageChrome.set_button_label(
			log_toggle,
			"Combat Log ▴" if expanded else "Combat Log ▾"
		)


func _update_ui() -> void:
	_update_player_ui()
	_update_monster_ui()
	_update_low_hp_vignette()


func _update_player_ui() -> void:
	var player = GameManager.get_player()
	if not player or not player_stage:
		return
	player_stage.set_identity(player.name, player.level)
	player_stage.set_figure_texture(PortraitLookup.get_player_texture(player))
	player_stage.set_health(player.health, player.max_health, true)
	player_stage.set_mana(player.mana, player.max_mana, true)
	player_stage.clear_status_effects()


func _update_monster_ui() -> void:
	var monster = GameManager.get_current_monster()
	if not monster or not monster_stage:
		if monster_stage:
			monster_stage.set_identity("No Monster", 1)
		return
	var extra := ""
	if GameManager.is_boss_combat():
		extra = "[Phase %d/%d]" % [monster.current_phase, monster.max_phase if "max_phase" in monster else 3]
	monster_stage.set_identity(monster.name, monster.level, extra)
	monster_stage.set_figure_texture(PortraitLookup.get_monster_texture(monster.name))
	monster_stage.set_health(monster.health, monster.max_health, true)
	monster_stage.clear_status_effects()
	_refresh_intent()


func _refresh_intent() -> void:
	if not monster_stage:
		return
	var intent: Dictionary = GameManager.get_monster_intent()
	if intent.is_empty():
		GameManager.refresh_monster_intent()
		intent = GameManager.get_monster_intent()
	var label := str(intent.get("label", ""))
	var min_d: int = int(intent.get("min", 0))
	var max_d: int = int(intent.get("max", 0))
	var text := label
	if min_d > 0 and max_d > 0 and str(intent.get("id", "")) != "defend":
		if min_d == max_d:
			text = "%s • %d damage" % [label, min_d]
		else:
			text = "%s • %d–%d damage" % [label, min_d, max_d]
	monster_stage.set_intent(text)


func _append_event(message: String) -> void:
	var clean := _strip_bbcode(message).strip_edges()
	if clean.is_empty():
		return
	# Prefer single-line latest event
	var line := clean.replace("\n", " ")
	if event_label:
		event_label.text = line
	_history.append(line)
	if combat_log:
		if combat_log.text.is_empty():
			combat_log.text = line
		else:
			combat_log.text += "\n" + line
		combat_log.scroll_to_line(combat_log.get_line_count() - 1)


func _strip_bbcode(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\[/?[^\\]]+\\]")
	return re.sub(text, "", true)


func _show_player_turn(animate: bool) -> void:
	if turn_banner:
		turn_banner.set_round(round_number)
		turn_banner.set_state(turn_banner.State.YOUR_TURN, animate)
	if turn_indicator:
		turn_indicator.highlight_player()
	if player_stage:
		player_stage.is_active = true
	if monster_stage:
		monster_stage.is_active = false
	_set_input_locked(false)
	_set_dock_mode("root")


func _show_enemy_turn(animate: bool) -> void:
	if turn_banner:
		turn_banner.set_state(turn_banner.State.ENEMY_TURN, animate)
	if turn_indicator:
		turn_indicator.highlight_monster()
	if player_stage:
		player_stage.is_active = false
	if monster_stage:
		monster_stage.is_active = true
	_set_input_locked(true)


func _on_combat_started(_monster_name: String) -> void:
	round_number = 1
	_history.clear()
	if combat_log:
		combat_log.text = ""
	_apply_stage_background()
	GameManager.refresh_monster_intent()
	_update_ui()
	_append_event("Combat begins! A %s appears." % _monster_name)
	_show_player_turn(true)


func _on_player_attacked(_damage: int, _is_critical: bool) -> void:
	# Event already recorded by the action handler; refresh bars + wait for FX.
	_update_ui()
	if animation_controller and not reduced_motion:
		await animation_controller.wait_for_animations()
	if not GameManager.in_combat:
		return
	await _run_monster_turn()


func _on_monster_attacked(_damage: int) -> void:
	_update_ui()
	_update_low_hp_vignette()


func _run_monster_turn() -> void:
	_show_enemy_turn(true)
	await get_tree().create_timer(0.35 if not reduced_motion else 0.05).timeout
	if not GameManager.in_combat:
		return
	var monster_attack_msg = GameManager.monster_attack()
	_append_event(monster_attack_msg)
	_update_ui()
	if animation_controller and not reduced_motion:
		await animation_controller.wait_for_animations()
	if GameManager.in_combat:
		round_number += 1
		GameManager.refresh_monster_intent()
		_refresh_intent()
		_show_player_turn(true)


func _on_combat_ended(player_won: bool) -> void:
	if performance_monitor:
		performance_monitor.stop_monitoring()
	_set_input_locked(true)
	if player_won:
		if turn_banner:
			turn_banner.set_state(turn_banner.State.VICTORY, true)
		_append_event("Victory! You defeated the monster.")
		await _play_enemy_defeat_fx()
		if GameManager.is_boss_combat():
			if is_inside_tree():
				await get_tree().create_timer(1.0).timeout
			GameManager.trigger_victory()
			GameManager.change_scene("victory_scene")
		else:
			if is_inside_tree():
				await get_tree().create_timer(1.0).timeout
			_change_to_exploration()
	else:
		if turn_banner:
			turn_banner.set_state(turn_banner.State.DEFEAT, true)
		_append_event("Defeat! You were defeated...")
		if is_inside_tree():
			await get_tree().create_timer(2.0).timeout
		GameManager.change_scene("game_over_scene")


func _play_enemy_defeat_fx() -> void:
	if not monster_stage:
		return
	var target = monster_stage.get_figure_node()
	if target == null:
		return
	if reduced_motion:
		target.modulate = Color(0.4, 0.4, 0.4, 0.5)
		return
	var tween = create_tween()
	tween.tween_property(target, "modulate", Color(1.2, 0.3, 0.25, 1.0), 0.15)
	tween.tween_property(target, "modulate", Color(0.35, 0.35, 0.35, 0.35), 0.45)
	await tween.finished
	tween.kill()


func _on_loot_dropped(item_name: String) -> void:
	_append_event("You found: %s" % item_name)
	UIToast.toast_on(self, "Loot: %s" % item_name, UIToast.Kind.LOOT, 2.0)


func _on_player_leveled_up(new_level: int) -> void:
	_append_event("Level up! You are now level %d." % new_level)
	_update_ui()
	UIToast.toast_on(self, "Level up! Now level %d" % new_level, UIToast.Kind.LEVEL_UP, 2.4)
	if player_stage and not reduced_motion:
		var fig = player_stage.get_figure_node()
		if fig:
			var tween = create_tween()
			tween.tween_property(fig, "modulate", Color(1.25, 1.15, 0.7, 1.0), 0.15)
			tween.tween_property(fig, "modulate", Color.WHITE, 0.35)
			tween.finished.connect(func(): tween.kill())


func _on_boss_phase_changed(phase: int, description: String) -> void:
	_append_event(description)
	_update_ui()
	UIToast.toast_on(self, "Phase %d — %s" % [phase, description], UIToast.Kind.DANGER, 2.5)
	_show_phase_banner(description)
	_flash_vignette()


func _show_phase_banner(text: String) -> void:
	if _phase_banner == null:
		_phase_banner = Label.new()
		_phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_phase_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_phase_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_phase_banner.offset_top = 80
		_phase_banner.offset_bottom = 120
		_phase_banner.offset_left = -300
		_phase_banner.offset_right = 300
		_phase_banner.add_theme_font_size_override("font_size", 20)
		_phase_banner.add_theme_color_override("font_color", UIThemeManager.get_color("danger"))
		_phase_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		_phase_banner.add_theme_constant_override("shadow_offset_x", 2)
		_phase_banner.add_theme_constant_override("shadow_offset_y", 2)
		_phase_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_phase_banner)
	_phase_banner.text = text
	_phase_banner.modulate.a = 1.0
	if reduced_motion:
		return
	var tween = create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(_phase_banner, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func(): tween.kill())


func _flash_vignette() -> void:
	if reduced_motion or stage_vignette == null:
		return
	var tween = create_tween()
	tween.tween_property(stage_vignette, "color:a", 0.35, 0.12)
	tween.tween_property(stage_vignette, "color:a", 0.0 if not _low_hp_active else 0.22, 0.35)
	tween.finished.connect(func(): tween.kill())


func _update_low_hp_vignette() -> void:
	var player = GameManager.get_player()
	if stage_vignette == null or player == null or player.max_health <= 0:
		return
	var frac := float(player.health) / float(player.max_health)
	_low_hp_active = frac <= LOW_HP_THRESHOLD and player.health > 0
	if _low_hp_active:
		stage_vignette.color = Color(0.55, 0.05, 0.05, 0.22)
	else:
		stage_vignette.color = Color(0.05, 0.02, 0.02, 0.0)


func _on_boss_defeated() -> void:
	_append_event("The Dark Overlord has been defeated!")
	UIToast.toast_on(self, "The Dark Overlord has fallen!", UIToast.Kind.LEVEL_UP, 3.0)


func _on_attack_pressed() -> void:
	if input_locked or not GameManager.in_combat:
		return
	_set_input_locked(true)
	var result = GameManager.player_attack()
	_append_event(result)
	_update_ui()
	# Monster turn is driven by _on_player_attacked


func _on_skills_pressed() -> void:
	if input_locked or not GameManager.in_combat:
		return
	var player = GameManager.get_player()
	if player == null or player.skills.size() == 0:
		_append_event("You have no skills to use.")
		return
	_set_dock_mode("skills")


func _on_items_pressed() -> void:
	if input_locked or not GameManager.in_combat:
		return
	_set_dock_mode("items")


func _on_run_pressed() -> void:
	if input_locked or not GameManager.in_combat:
		return
	_set_input_locked(true)
	if randf() < 0.5:
		GameManager.end_combat()
		_append_event("You successfully ran away!")
		await get_tree().create_timer(1.0).timeout
		_change_to_exploration()
	else:
		_append_event("Failed to run away!")
		await _run_monster_turn()


func _on_skills_back_pressed() -> void:
	_set_dock_mode("root")


func _on_items_back_pressed() -> void:
	_set_dock_mode("root")


func _on_log_toggle_pressed() -> void:
	_set_log_expanded(not log_expanded)


func _populate_skills_dock() -> void:
	if skills_list == null:
		return
	for child in skills_list.get_children():
		child.queue_free()
	var player = GameManager.get_player()
	if player == null:
		return
	if skill_desc:
		skill_desc.text = "Choose a skill."
	for i in range(player.skills.size()):
		var skill = player.skills[i]
		var btn := Button.new()
		var cd := ""
		if skill.current_cooldown > 0:
			cd = " CD%d" % skill.current_cooldown
		var cost := ""
		if skill.mana_cost > 0:
			cost = " %dMP" % skill.mana_cost
		btn.text = "%s%s%s" % [skill.name, cost, cd]
		btn.tooltip_text = skill.description if skill.description else skill.get_unusable_reason(player)
		btn.custom_minimum_size = Vector2(140, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		StageChrome.style_secondary_action(btn)
		var can_use_skill: bool = skill.can_use(player)
		btn.disabled = not can_use_skill
		if not can_use_skill:
			btn.tooltip_text = skill.get_unusable_reason(player)
		var idx := i
		btn.pressed.connect(func(): _on_skill_chosen(idx))
		btn.mouse_entered.connect(func():
			if skill_desc:
				skill_desc.text = skill.description if skill.description else skill.name
		)
		skills_list.add_child(btn)


func _on_skill_chosen(skill_index: int) -> void:
	if input_locked or not GameManager.in_combat:
		return
	_set_input_locked(true)
	_set_dock_mode("root")
	var player = GameManager.get_player()
	var skill_name := ""
	var effect_type := "damage"
	if player and skill_index >= 0 and skill_index < player.skills.size():
		skill_name = player.skills[skill_index].name
		effect_type = player.skills[skill_index].effect_type

	if animation_controller and not reduced_motion and skill_name != "":
		var p_img = player_stage.get_figure_node()
		var m_img = monster_stage.get_figure_node()
		if effect_type == "heal":
			await animation_controller.play_healing_effect(p_img, 0)
		else:
			await animation_controller.play_spell_cast(p_img, m_img, skill_name)

	var result = GameManager.player_use_skill(skill_index)
	_append_event(result)
	_update_ui()

	# Show damage/heal numbers for skills
	if animation_controller and player:
		var skill = player.skills[skill_index] if skill_index < player.skills.size() else null
		if skill and skill.effect_type == "damage" and monster_stage:
			# Approximate from log is hard; spawn using last combat values if present
			pass

	if GameManager.in_combat:
		await _run_monster_turn()


func _populate_items_dock() -> void:
	if items_list == null:
		return
	for child in items_list.get_children():
		child.queue_free()
	var player = GameManager.get_player()
	if player == null:
		return
	var found := 0
	for i in range(player.inventory.size()):
		var item = player.inventory[i]
		if item == null:
			continue
		if not item.is_consumable():
			continue
		if item.quantity <= 0:
			continue
		found += 1
		var btn := Button.new()
		var qty := " x%d" % item.quantity if item.quantity > 1 else ""
		btn.text = "%s%s" % [item.name, qty]
		btn.tooltip_text = item.description if item.description else item.name
		btn.custom_minimum_size = Vector2(140, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		StageChrome.style_secondary_action(btn)
		var inv_idx := i
		btn.pressed.connect(func(): _on_item_chosen(inv_idx))
		items_list.add_child(btn)
	if items_empty:
		items_empty.visible = found == 0


func _on_item_chosen(inventory_index: int) -> void:
	if input_locked or not GameManager.in_combat:
		return
	_set_input_locked(true)
	_set_dock_mode("root")
	var result = GameManager.player_use_consumable(inventory_index)
	_append_event(result)
	var player = GameManager.get_player()
	if animation_controller and player and not reduced_motion:
		await animation_controller.play_healing_effect(player_stage.get_figure_node(), 0)
	_update_ui()
	if GameManager.in_combat:
		await _run_monster_turn()


func _change_to_exploration() -> void:
	GameManager.change_scene("exploration_scene")


func _on_animation_started(animation_id: String) -> void:
	if performance_monitor:
		performance_monitor.start_animation_timing(animation_id)


func _on_animation_completed(animation_id: String) -> void:
	if performance_monitor:
		performance_monitor.end_animation_timing(animation_id)


func _on_damage_number_spawned(_value: int, _position: Vector2) -> void:
	pass


func _on_fps_warning(fps: float) -> void:
	if OS.is_debug_build():
		print("[Performance] FPS Warning: %.1f fps" % fps)


func _on_memory_warning(memory_mb: float) -> void:
	if OS.is_debug_build():
		print("[Performance] Memory Warning: %.1f MB" % memory_mb)


func _exit_tree() -> void:
	if performance_monitor:
		performance_monitor.stop_monitoring()
