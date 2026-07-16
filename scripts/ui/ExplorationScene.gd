extends Control

# ExplorationScene - Narrative-driven exploration with events, travel, and area system

const InventoryDialog = preload("res://scenes/ui/inventory_dialog.tscn")
const ShopDialog = preload("res://scenes/ui/shop_dialog.tscn")
const QuestLogDialog = preload("res://scenes/ui/quest_log_dialog.tscn")
const CodexDialog = preload("res://scenes/ui/codex_dialog.tscn")
const GameMenuDialog = preload("res://scenes/ui/game_menu_dialog.tscn")
const UI_BUTTON_SCENE = preload("res://scenes/components/ui_button.tscn")

const DANGER_MAX := 25.0

# Exploration state
var current_area_id: String = "town"
var danger_level: float = 0.0
var steps_taken: int = 0
var exploration_manager: ExplorationManager = null
var showing_choices: bool = false
var showing_travel: bool = false
var choice_buttons: Array = []
var travel_buttons: Array = []
var more_open: bool = false

@onready var area_name_label = $UI/TopBar/AreaInfo/AreaName
@onready var danger_label = $UI/TopBar/AreaInfo/DangerLevel
@onready var danger_bar = $UI/TopBar/AreaInfo/DangerBar
@onready var player_stats_label = $UI/TopBar/PlayerStats
@onready var narrative_log = $UI/MiddleSection/NarrativeLog
@onready var middle_section = $UI/MiddleSection
@onready var action_buttons = $UI/BottomBar/ActionButtons
@onready var explore_button = $UI/BottomBar/ActionButtons/ExploreButton
@onready var rest_button = $UI/BottomBar/ActionButtons/RestButton
@onready var travel_button = $UI/BottomBar/ActionButtons/TravelButton
@onready var inventory_button = $UI/BottomBar/ActionButtons/InventoryButton
@onready var more_button = $UI/BottomBar/ActionButtons/MoreButton
@onready var more_panel = $MorePanel
@onready var shop_button = $MorePanel/MoreMargin/MoreButtons/ShopButton
@onready var quest_log_button = $MorePanel/MoreMargin/MoreButtons/QuestLogButton
@onready var codex_button = $MorePanel/MoreMargin/MoreButtons/CodexButton
@onready var menu_button = $MorePanel/MoreMargin/MoreButtons/MenuButton
@onready var background = $Background


func _ready():
	print("ExplorationScene ready")

	exploration_manager = ExplorationManager.new()
	add_child(exploration_manager)

	_load_exploration_state()
	_apply_area_theme()
	_style_middle_section()
	_style_top_bar()
	_style_danger_bar()
	_update_ui()

	GameManager.connect("game_loaded", Callable(self, "_on_game_loaded"))

	_setup_focus_navigation()

	# Show area entry narrative
	_append_narrative(_get_area_entry_text())


func _input(event: InputEvent) -> void:
	if more_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_more_panel()


func _style_middle_section():
	if not middle_section:
		return
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.03, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = UIThemeManager.get_border_bronze_color()
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6
	middle_section.add_theme_stylebox_override("panel", panel_style)


func _style_top_bar():
	if area_name_label:
		area_name_label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
		area_name_label.add_theme_color_override(
			"font_shadow_color", Color(0, 0, 0, 0.7))
		area_name_label.add_theme_constant_override("shadow_offset_x", 2)
		area_name_label.add_theme_constant_override("shadow_offset_y", 2)
	if danger_label:
		danger_label.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color())


func _style_danger_bar():
	if not danger_bar:
		return
	danger_bar.max_value = DANGER_MAX
	danger_bar.show_percentage = false
	_update_danger_visuals()


func _update_ui():
	if not GameManager.get_player():
		return

	var player = GameManager.get_player()
	if player.max_mana > 0:
		player_stats_label.text = "%s (Lv.%d) - HP: %d/%d - MP: %d/%d - Gold: %d" % [
			player.name, player.level, player.health, player.max_health,
			player.mana, player.max_mana, player.gold
		]
	else:
		player_stats_label.text = "%s (Lv.%d) - HP: %d/%d - Gold: %d" % [
			player.name, player.level, player.health, player.max_health, player.gold
		]

	var area_info = exploration_manager.get_current_area_info()
	area_name_label.text = area_info.get("name", "Unknown")
	danger_label.text = ExplorationEventFactory.get_danger_flavor(danger_level)
	_update_danger_visuals()

	# Disable explore in town; shop only meaningful in town
	var is_town = current_area_id == "town"
	explore_button.disabled = is_town
	if shop_button:
		shop_button.disabled = not is_town
		shop_button.visible = is_town


func _update_danger_visuals():
	if danger_bar:
		danger_bar.value = danger_level

	var t := clampf(danger_level / DANGER_MAX, 0.0, 1.0)
	var safe_color := UIThemeManager.get_color("success")
	var warn_color := UIThemeManager.get_color("accent")
	var danger_color := UIThemeManager.get_color("danger")
	var color: Color
	if t < 0.4:
		color = safe_color.lerp(warn_color, t / 0.4)
	else:
		color = warn_color.lerp(danger_color, (t - 0.4) / 0.6)

	if danger_label:
		danger_label.add_theme_color_override("font_color", color)

	if danger_bar:
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(2)
		danger_bar.add_theme_stylebox_override("fill", fill)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.12, 0.10, 0.08, 0.8)
		bg.set_corner_radius_all(2)
		danger_bar.add_theme_stylebox_override("background", bg)


func _append_narrative(bbcode_text: String):
	if not narrative_log:
		return
	if narrative_log.text.length() > 0:
		narrative_log.append_text(
			"\n[color=#99804020]" \
			+ "________________________________________" \
			+ "[/color]\n"
		)
	narrative_log.append_text(bbcode_text + "\n")


func _get_area_entry_text() -> String:
	var area_info = exploration_manager.get_current_area_info()
	var name_text = area_info.get("name", "Unknown")
	var desc = area_info.get("description", "")
	return "[color=#d9b359][b]-- %s --[/b][/color]\n%s" % [name_text, desc]


# -- Core exploration loop --

func _on_explore_pressed():
	if showing_choices or showing_travel:
		return
	_close_more_panel()

	steps_taken += 1
	danger_level = min(danger_level + 1.5, DANGER_MAX)

	var player_level = 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level

	var event = ExplorationEventFactory.generate_event(
		current_area_id, player_level, danger_level)

	_handle_event(event)
	_save_exploration_state()
	_update_ui()


func _handle_event(event: Dictionary):
	match event.type:
		"combat":
			_handle_combat_event(event)
		"discovery":
			_handle_discovery_event(event)
		"choice":
			_handle_choice_event(event)
		"flavor":
			_handle_flavor_event(event)
		"quest":
			_handle_quest_event(event)


func _handle_combat_event(event: Dictionary):
	_append_narrative(event.narrative)
	_save_exploration_state()

	# Tension pulse before combat
	await _play_encounter_pulse()

	var monster_type = event.get("monster_type", "")
	if monster_type != "":
		GameManager.start_combat_with_type(monster_type)
	else:
		GameManager.start_combat()


func _play_encounter_pulse() -> void:
	var reduce_motion = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false)
	if reduce_motion:
		await get_tree().create_timer(0.4).timeout
		return

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.15, 0.85, 0.75, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)
	await tween.finished
	tween.kill()
	await get_tree().create_timer(0.35).timeout


func _handle_discovery_event(event: Dictionary):
	_append_narrative(event.narrative)
	_apply_rewards(event.rewards)


func _handle_choice_event(event: Dictionary):
	_append_narrative(event.narrative)
	_show_choice_buttons(event.choices)


func _handle_flavor_event(event: Dictionary):
	_append_narrative(event.narrative)


func _handle_quest_event(event: Dictionary):
	_append_narrative(event.narrative)

	var player_level = 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level

	var quest = QuestFactory.get_random_quest(player_level)
	QuestManager.accept_quest(quest)
	_append_narrative(
		"[color=#73bf73]Quest accepted: %s[/color]" % quest.title)
	UIToast.toast_on(self, "Quest: %s" % quest.title, UIToast.Kind.SUCCESS, 2.0)


# -- Reward application --

func _apply_rewards(rewards: Dictionary):
	if not GameManager.get_player():
		return
	var player = GameManager.get_player()
	var msg_parts = []

	var gold_amount = rewards.get("gold", 0)
	if gold_amount > 0:
		player.gold += gold_amount
		msg_parts.append("[color=#d9b359]+%d gold[/color]" % gold_amount)
	elif gold_amount < 0:
		player.gold = max(0, player.gold + gold_amount)
		msg_parts.append("[color=#d9593a]%d gold[/color]" % gold_amount)

	var exp_amount = rewards.get("exp", 0)
	if exp_amount > 0:
		var old_level = player.level
		player.add_experience(exp_amount)
		msg_parts.append("[color=#d9b359]+%d exp[/color]" % exp_amount)
		if player.level > old_level:
			msg_parts.append(
				"[color=#73bf73]Level up! Now level %d[/color]" % player.level)
			UIToast.toast_on(
				self,
				"Level up! Now level %d" % player.level,
				UIToast.Kind.LEVEL_UP,
				2.2
			)

	var heal_pct = rewards.get("heal_percent", 0)
	if heal_pct > 0:
		var heal_amount = int(player.max_health * heal_pct / 100.0)
		player.health = min(player.health + heal_amount, player.max_health)
		msg_parts.append("[color=#73bf73]+%d HP[/color]" % heal_amount)

	var item_type = rewards.get("item", "")
	if item_type != "":
		var item = ItemFactory.create_item(item_type)
		if item and player.add_item(item):
			msg_parts.append(
				"[color=#73bf73]Found: %s[/color]" % item.name)
			UIToast.toast_on(self, "Found: %s" % item.name, UIToast.Kind.LOOT, 1.8)

	var combat_type = rewards.get("combat", "")
	if combat_type != "":
		_save_exploration_state()
		GameManager.start_combat_with_type(combat_type)
		return

	if msg_parts.size() > 0:
		_append_narrative("  " + " | ".join(msg_parts))
	_update_ui()


# -- Choice system --

func _make_runtime_button(label: String) -> Button:
	var btn = UI_BUTTON_SCENE.instantiate()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	# UIButton._ready overwrites min size from text width — re-apply after ready
	btn.ready.connect(_on_runtime_button_ready.bind(btn), CONNECT_ONE_SHOT)
	return btn


func _on_runtime_button_ready(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	btn.custom_minimum_size = Vector2(120, 40)
	btn.clip_text = true


func _show_choice_buttons(choices: Array):
	showing_choices = true
	_close_more_panel()
	_set_action_buttons_visible(false)

	for choice in choices:
		var btn = _make_runtime_button(choice.get("label", "???"))
		var choice_data = choice
		btn.pressed.connect(func(): _on_choice_selected(choice_data))
		action_buttons.add_child(btn)
		choice_buttons.append(btn)

	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()


func _on_choice_selected(choice_data: Dictionary):
	for btn in choice_buttons:
		btn.queue_free()
	choice_buttons.clear()
	showing_choices = false

	_set_action_buttons_visible(true)

	var result_text = choice_data.get("result_narrative", "")
	if result_text != "":
		_append_narrative(result_text)

	var rewards = choice_data.get("rewards", {})
	_apply_rewards(rewards)
	_save_exploration_state()
	_update_ui()
	explore_button.grab_focus()


# -- Travel system --

func _on_travel_pressed():
	if showing_choices or showing_travel:
		return
	_close_more_panel()

	var player_level = 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level

	var areas = exploration_manager.get_accessible_areas(player_level)
	if areas.size() == 0:
		_append_narrative(
			"[color=#948d84]There is nowhere to travel from here.[/color]")
		return

	showing_travel = true
	_set_action_buttons_visible(false)

	# 2-column grid so long destination names don't overflow the 800px footer
	if action_buttons is GridContainer:
		action_buttons.columns = 2

	for area in areas:
		# Short labels fit the compact grid; tooltip has full requirement text
		var label = "%s (Lv.%d+)" % [area.name, area.level_requirement]
		var btn = _make_runtime_button(label)
		if area.accessible:
			btn.tooltip_text = "Travel to %s (requires level %d)" % [
				area.name, area.level_requirement
			]
		else:
			btn.disabled = true
			btn.tooltip_text = "Requires level %d" % area.level_requirement
		var area_id = area.id
		btn.pressed.connect(func(): _on_travel_destination_selected(area_id))
		action_buttons.add_child(btn)
		travel_buttons.append(btn)

	var cancel_btn = _make_runtime_button("Cancel")
	cancel_btn.pressed.connect(func(): _cancel_travel())
	action_buttons.add_child(cancel_btn)
	travel_buttons.append(cancel_btn)

	if travel_buttons.size() > 0:
		travel_buttons[0].grab_focus()


func _on_travel_destination_selected(area_id: String):
	_clear_travel_buttons()
	_enter_area(area_id)


func _cancel_travel():
	_clear_travel_buttons()
	travel_button.grab_focus()


func _clear_travel_buttons():
	for btn in travel_buttons:
		btn.queue_free()
	travel_buttons.clear()
	showing_travel = false
	_set_action_buttons_visible(true)


func _enter_area(area_id: String):
	current_area_id = area_id
	exploration_manager.enter_area(area_id)
	danger_level = 0.0
	_apply_area_theme()
	_update_ui()
	_append_narrative(_get_area_entry_text())
	_save_exploration_state()
	explore_button.grab_focus()


func _apply_area_theme():
	if not background or not background.material:
		return
	var shader_params = exploration_manager.get_area_shader_params(current_area_id)
	var mat = background.material as ShaderMaterial
	if not mat:
		return
	for param_name in shader_params:
		mat.set_shader_parameter(param_name, shader_params[param_name])


# -- Rest system --

func _on_rest_pressed():
	if showing_choices or showing_travel:
		return
	_close_more_panel()
	if not GameManager.get_player():
		return

	var player = GameManager.get_player()
	var is_town = current_area_id == "town"

	if is_town:
		var heal_amount = player.max_health - player.health
		var mana_amount = player.max_mana - player.mana
		player.health = player.max_health
		player.mana = player.max_mana
		danger_level = 0.0
		if heal_amount > 0 or mana_amount > 0:
			var parts: Array[String] = []
			if heal_amount > 0:
				parts.append("+%d HP" % heal_amount)
			if mana_amount > 0:
				parts.append("+%d MP" % mana_amount)
			_append_narrative(
				"[color=#73bf73]You rest at the inn and fully recover." \
				+ " (%s)[/color]" % ", ".join(parts))
		else:
			_append_narrative(
				"[color=#948d84]You rest at the inn. You are already fully recovered.[/color]")
	else:
		var ambush_chance = exploration_manager.get_rest_ambush_chance(current_area_id)
		var ambushed = randf() < ambush_chance

		if ambushed:
			var heal_amount = int(player.max_health * 0.15)
			var mana_restored = int(player.max_mana * 0.15)
			player.health = min(player.health + heal_amount, player.max_health)
			player.restore_mana(mana_restored)
			danger_level = max(danger_level - 2.0, 0.0)
			_append_narrative(
				"[color=#d9593a]You try to rest, but something finds you!" \
				+ " (+%d HP, +%d MP before the attack)[/color]" % [heal_amount, mana_restored])
			_save_exploration_state()
			_update_ui()

			await _play_encounter_pulse()

			var area_info = exploration_manager.get_current_area_info()
			var monster_types = area_info.get("monster_types", ["goblin"])
			var monster = monster_types[randi() % monster_types.size()]
			GameManager.start_combat_with_type(monster)
			return

		var heal_amount = int(player.max_health * 0.30)
		var mana_restored = int(player.max_mana * 0.30)
		player.health = min(player.health + heal_amount, player.max_health)
		player.restore_mana(mana_restored)
		danger_level = max(danger_level - 3.0, 0.0)
		_append_narrative(
			"[color=#73bf73]You find a sheltered spot and rest cautiously." \
			+ " (+%d HP, +%d MP)[/color]" % [heal_amount, mana_restored])

	_save_exploration_state()
	_update_ui()


# -- More panel / dialogs --

func _on_more_pressed():
	if showing_choices or showing_travel:
		return
	if more_open:
		_close_more_panel()
	else:
		_open_more_panel()


func _open_more_panel():
	more_open = true
	if more_panel:
		more_panel.visible = true
		var is_town = current_area_id == "town"
		shop_button.visible = is_town
		if is_town:
			shop_button.grab_focus()
		else:
			quest_log_button.grab_focus()


func _close_more_panel():
	more_open = false
	if more_panel:
		more_panel.visible = false


func _on_inventory_pressed():
	_close_more_panel()
	var dialog = InventoryDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): inventory_button.grab_focus())


func _on_shop_pressed():
	_close_more_panel()
	var dialog = ShopDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): more_button.grab_focus())


func _on_quest_log_pressed():
	_close_more_panel()
	var dialog = QuestLogDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): more_button.grab_focus())


func _on_codex_pressed():
	_close_more_panel()
	var dialog = CodexDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): more_button.grab_focus())


func _on_menu_pressed():
	_close_more_panel()
	var dialog = GameMenuDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): more_button.grab_focus())


func _set_action_buttons_visible(vis: bool):
	explore_button.visible = vis
	rest_button.visible = vis
	travel_button.visible = vis
	inventory_button.visible = vis
	more_button.visible = vis
	if not vis:
		_close_more_panel()


func _setup_focus_navigation():
	var row = [explore_button, rest_button, travel_button, inventory_button, more_button]
	for i in range(row.size()):
		var left_idx = (i - 1 + row.size()) % row.size()
		var right_idx = (i + 1) % row.size()
		row[i].set("focus_neighbor_left", row[left_idx].get_path())
		row[i].set("focus_neighbor_right", row[right_idx].get_path())

	# More panel vertical chain
	var more_row = [shop_button, quest_log_button, codex_button, menu_button]
	for i in range(more_row.size()):
		var prev_idx = (i - 1 + more_row.size()) % more_row.size()
		var next_idx = (i + 1) % more_row.size()
		more_row[i].set("focus_neighbor_top", more_row[prev_idx].get_path())
		more_row[i].set("focus_neighbor_bottom", more_row[next_idx].get_path())

	explore_button.grab_focus()


# -- State persistence --

func _load_exploration_state():
	var state = GameManager.get_exploration_state()
	steps_taken = state.get("steps_taken", 0)
	current_area_id = state.get("current_area_id", "town")
	danger_level = state.get("danger_level", 0.0)
	exploration_manager.enter_area(current_area_id)


func _save_exploration_state():
	GameManager.set_exploration_state({
		"steps_taken": steps_taken,
		"encounter_chance": danger_level,
		"steps_since_last_encounter": 0,
		"current_area_id": current_area_id,
		"danger_level": danger_level,
	})


func _on_game_loaded():
	_load_exploration_state()
	_apply_area_theme()
	_update_ui()
	narrative_log.clear()
	_append_narrative(_get_area_entry_text())
