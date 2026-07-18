extends Control

# CombatScene - Location-stage combat with dock actions and arena feedback.

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const CombatActionCardScript = preload("res://scripts/components/CombatActionCard.gd")
const SceneLayout = preload("res://scripts/ui/CombatSceneLayout.gd")
const LOW_HP_THRESHOLD := 0.25
const EVENT_IDLE_DELAY := 1.4
const EVENT_IDLE_PROMPT := "Choose an action."
const NORMAL_DOCK_HEIGHT := 162.0
const COMPACT_DOCK_HEIGHT := 142.0
const NORMAL_ACTION_HEIGHT := 80.0
const COMPACT_ACTION_HEIGHT := 64.0

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
var attack_card = null
var skills_card = null
var items_card = null
var run_card = null
var _low_hp_active: bool = false
var _phase_banner: Label = null
var _history: PackedStringArray = PackedStringArray()
var _event_token: int = 0
var _showing_idle_prompt: bool = false
var _flee_failures: int = 0
var _compact_layout: bool = false

@onready var stage_background: TextureRect = $StageLayer/StageBackground
@onready var stage_darken: ColorRect = $StageLayer/StageDarken
@onready var stage_vignette: ColorRect = $StageLayer/StageVignette
@onready var arena_layer: Control = $MainColumn/ArenaLayer
@onready var turn_banner = $MainColumn/ArenaLayer/TurnBanner
@onready var player_stage = $MainColumn/ArenaLayer/Combatants/PlayerStage
@onready var monster_stage = $MainColumn/ArenaLayer/Combatants/MonsterStage
@onready var enemy_intent_panel: PanelContainer = $MainColumn/ArenaLayer/EnemyIntentPanel
@onready var enemy_intent_icon: TextureRect = (
	$MainColumn/ArenaLayer/EnemyIntentPanel/IntentMargin/IntentRow/IntentIcon
)
@onready var enemy_intent_label: Label = (
	$MainColumn/ArenaLayer/EnemyIntentPanel/IntentMargin/IntentRow/IntentLabel
)
@onready var fx_layer: Control = $MainColumn/ArenaLayer/FXLayer
@onready var dock_layer: VBoxContainer = $MainColumn/DockLayer
@onready var status_rail: HBoxContainer = $MainColumn/DockLayer/StatusRail
@onready var player_status: CombatantStatusView = $MainColumn/DockLayer/StatusRail/PlayerStatus
@onready var monster_status: CombatantStatusView = $MainColumn/DockLayer/StatusRail/MonsterStatus
@onready var event_strip: PanelContainer = $MainColumn/DockLayer/StatusRail/EventStrip
@onready var event_label: RichTextLabel = (
	$MainColumn/DockLayer/StatusRail/EventStrip/EventMargin/EventRow/EventLabel
)
@onready var history_toggle: Button = (
	$MainColumn/DockLayer/StatusRail/EventStrip/EventMargin/EventRow/HistoryToggle
)
@onready var action_dock: PanelContainer = $MainColumn/DockLayer/ActionDock
@onready var action_pages: Control = $MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages
@onready var root_actions: HBoxContainer = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/RootActions
)
@onready var attack_button: Button = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/RootActions/AttackButton
)
@onready var skills_button: Button = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/RootActions/SkillsButton
)
@onready var items_button: Button = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/RootActions/ItemsButton
)
@onready var run_button: Button = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/RootActions/RunButton
)
@onready var skills_panel: HBoxContainer = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/SkillsPanel
)
@onready var skills_list: HBoxContainer = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/SkillsPanel/SkillsList
)
@onready var skill_desc: Label = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/SkillsPanel/SkillsMeta/SkillDesc
)
@onready var items_panel: HBoxContainer = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/ItemsPanel
)
@onready var items_list: HBoxContainer = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/ItemsPanel/ItemsList
)
@onready var items_empty: Label = (
	$MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/ItemsPanel/ItemsMeta/ItemsEmpty
)
@onready var combat_log_panel: PanelContainer = $HistoryOverlay
@onready var combat_log: RichTextLabel = $HistoryOverlay/LogMargin/CombatLog


func _ready() -> void:
	print("CombatScene ready")
	player_portrait = player_stage
	monster_portrait = monster_stage
	if player_status:
		player_health_bar = player_status.health_bar
		player_mana_bar = player_status.mana_bar
	if monster_status:
		monster_health_bar = monster_status.health_bar
	_setup_animation_systems()
	_apply_stage_background()
	_style_chrome()
	_configure_root_actions()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
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
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if log_expanded and (key.keycode == KEY_ESCAPE or key.keycode == KEY_BACKSPACE):
		_set_log_expanded(false)
		history_toggle.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if input_locked or not GameManager.in_combat:
		return
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
	_set_log_expanded(ui_mode == "log_open")
	match ui_mode:
		"skills":
			_set_dock_mode("skills")
		"items":
			_set_dock_mode("items")
		"log_open":
			_set_dock_mode("root")
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
	if player_status:
		player_status.set_reduced_motion(enabled)
	if monster_status:
		monster_status.set_reduced_motion(enabled)
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
	var area_id := str(GameManager.combat_area_id)
	if area_id.is_empty():
		area_id = "forest"
	var path := _combat_background_path(area_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		path = "res://assets/combat/forest.png"
	if stage_background and ResourceLoader.exists(path):
		stage_background.texture = load(path)
	if stage_darken:
		stage_darken.color = Color(0.04, 0.03, 0.025, 0.34)
func _combat_background_path(area_id: String) -> String:
	return SceneLayout.background_path(area_id)
func _style_chrome() -> void:
	SceneLayout.style_chrome(self)
func _configure_root_actions() -> void:
	attack_card = _upgrade_to_action_card(attack_button)
	skills_card = _upgrade_to_action_card(skills_button)
	items_card = _upgrade_to_action_card(items_button)
	run_card = _upgrade_to_action_card(run_button)
	if attack_card:
		attack_card.setup("[1] ATTACK", "— damage", CombatActionCardScript.Kind.PRIMARY, null)
	if skills_card:
		skills_card.setup("[2] SKILLS", "— ready", CombatActionCardScript.Kind.SECONDARY, null)
	if items_card:
		items_card.setup("[3] ITEMS", "— usable", CombatActionCardScript.Kind.SECONDARY, null)
	if run_card:
		run_card.setup(
			"[4] RUN",
			"%d%% escape chance" % int(CombatRules.get_escape_chance(0) * 100),
			CombatActionCardScript.Kind.DANGER,
			null
		)
	_refresh_action_subtitles()
	var skills_back = get_node_or_null(
		"MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/SkillsPanel/SkillsMeta/SkillsBackButton")
	var items_back = get_node_or_null(
		"MainColumn/DockLayer/ActionDock/ActionMargin/ActionPages/ItemsPanel/ItemsMeta/ItemsBackButton")
	StageChrome.style_secondary_action(skills_back)
	StageChrome.style_secondary_action(items_back)
	if skills_back:
		skills_back.custom_minimum_size = Vector2(110, 30)
		StageChrome.set_button_label(skills_back, "Back")
	if items_back:
		items_back.custom_minimum_size = Vector2(110, 30)
		StageChrome.set_button_label(items_back, "Back")
func _upgrade_to_action_card(btn: Button):
	if btn == null:
		return null
	if btn.get_script() == CombatActionCardScript:
		return btn
	btn.set_script(CombatActionCardScript)
	if btn.has_method("_build_if_needed"):
		btn._build_if_needed()
	return btn
func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	_compact_layout = size.x < 1100.0 or size.y < 650.0
	var dock_height := COMPACT_DOCK_HEIGHT if _compact_layout else NORMAL_DOCK_HEIGHT
	var action_height := COMPACT_ACTION_HEIGHT if _compact_layout else NORMAL_ACTION_HEIGHT
	SceneLayout.apply_responsive(self, _compact_layout, dock_height, action_height)
func _refresh_action_subtitles() -> void:
	var player = GameManager.get_player()
	var monster = GameManager.get_current_monster()
	if attack_card:
		attack_card.set_title("[1] ATTACK")
	if skills_card:
		skills_card.set_title("[2] SKILLS")
	if items_card:
		items_card.set_title("[3] ITEMS")
	if run_card:
		run_card.set_title("[4] RUN")
	if attack_card and player and monster:
		var dmg: Dictionary = GameManager.estimate_damage_range(
			player.get_attack_power(),
			player.level,
			monster.defense,
			player.get_outgoing_damage_multiplier(),
		)
		var dmin: int = int(dmg.get("min", 1))
		var dmax: int = int(dmg.get("max", 1))
		if dmin == dmax:
			attack_card.set_subtitle("%d damage" % dmin)
		else:
			attack_card.set_subtitle("%d–%d damage" % [dmin, dmax])
	elif attack_card:
		attack_card.set_subtitle("Attack")
	if skills_card and player:
		var ready := 0
		for skill in player.skills:
			if skill and skill.can_use(player):
				ready += 1
		skills_card.set_subtitle("%d ready" % ready)
	elif skills_card:
		skills_card.set_subtitle("Skills")
	if items_card and player:
		var count := 0
		for item in player.inventory:
			if item and item.is_consumable() and item.quantity > 0:
				count += item.quantity
		items_card.set_subtitle("%d usable" % count)
	elif items_card:
		items_card.set_subtitle("Items")
	if run_card:
		if GameManager.is_boss_combat():
			run_card.set_subtitle("Unavailable against bosses")
		elif _flee_failures > 0:
			run_card.set_subtitle("100% escape chance")
		else:
			run_card.set_subtitle(
				"%d%% escape chance" % int(CombatRules.get_escape_chance(0) * 100))
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
			var boss_run_blocked: bool = btn == run_button and GameManager.is_boss_combat()
			btn.disabled = locked or boss_run_blocked
			if btn.has_method("set_card_disabled"):
				btn.set_card_disabled(locked or boss_run_blocked)
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
	if history_toggle:
		StageChrome.set_button_label(
			history_toggle,
			"History ▴" if expanded else "History ▾"
		)
	if expanded and combat_log:
		combat_log.scroll_to_line(maxi(0, combat_log.get_line_count() - 1))


func _update_ui() -> void:
	_update_player_ui()
	_update_monster_ui()
	_update_low_hp_vignette()
	_refresh_action_subtitles()


func _update_player_ui() -> void:
	var player = GameManager.get_player()
	if not player or not player_stage or not player_status:
		return
	player_stage.set_figure_texture(PortraitLookup.get_player_texture(player))
	player_stage.set_boss_scale(false)
	player_status.set_identity(player.name, player.level)
	player_status.set_health(player.health, player.max_health, true)
	player_status.set_mana(player.mana, player.max_mana, true)
	player_status.clear_status_effects()
	for effect_type in player.status_effects:
		var effect: Dictionary = player.status_effects[effect_type]
		player_status.add_status_effect(str(effect_type), int(effect.get("duration", 0)))


func _update_monster_ui() -> void:
	var monster = GameManager.get_current_monster()
	if not monster or not monster_stage or not monster_status:
		if monster_status:
			monster_status.set_identity("No Monster", 1)
		return
	var extra := ""
	if GameManager.is_boss_combat():
		extra = "[Phase %d/%d]" % [monster.current_phase, monster.max_phase if "max_phase" in monster else 3]
	monster_stage.set_figure_texture(PortraitLookup.get_monster_texture(monster.name))
	monster_stage.set_boss_scale(GameManager.is_boss_combat())
	monster_status.set_identity(monster.name, monster.level, extra)
	monster_status.set_health(monster.health, monster.max_health, true)
	monster_status.clear_status_effects()
	for effect_type in monster.status_effects:
		var effect: Dictionary = monster.status_effects[effect_type]
		monster_status.add_status_effect(str(effect_type), int(effect.get("duration", 0)))
	_refresh_intent()


func _refresh_intent() -> void:
	if not enemy_intent_panel or not enemy_intent_label:
		return
	var intent: Dictionary = GameManager.get_monster_intent()
	if intent.is_empty():
		GameManager.refresh_monster_intent()
		intent = GameManager.get_monster_intent()
	var label := str(intent.get("label", ""))
	var min_d: int = int(intent.get("min", 0))
	var max_d: int = int(intent.get("max", 0))
	var text := label
	var show_icon := str(intent.get("id", "")) != "defend"
	if min_d > 0 and max_d > 0 and str(intent.get("id", "")) != "defend":
		if min_d == max_d:
			text = "%s • %d damage" % [label, min_d]
		else:
			text = "%s • %d–%d damage" % [label, min_d, max_d]
	enemy_intent_label.text = text
	enemy_intent_icon.visible = show_icon and not text.is_empty()
	enemy_intent_panel.visible = not text.is_empty()


func _append_event(message: String, kind: String = "auto", idle_after: bool = true) -> void:
	var clean := _strip_bbcode(message).strip_edges()
	if clean.is_empty():
		return
	var line := clean.replace("\n", " ")
	var resolved_kind := kind
	if resolved_kind == "auto":
		resolved_kind = _classify_event(line)
	# Clarify that enemy lines are prior resolution when it is the player's turn again
	var display_line := line
	if resolved_kind == "enemy" and not input_locked:
		display_line = "Last: " + line
	var bb := _colorize_event(display_line, resolved_kind)
	_showing_idle_prompt = false
	_event_token += 1
	var token := _event_token
	if event_label:
		event_label.modulate.a = 1.0
		event_label.text = bb
	_history.append(line)
	if combat_log:
		var log_bb := _colorize_event(line, resolved_kind)
		if combat_log.text.is_empty():
			combat_log.text = log_bb
		else:
			combat_log.text += "\n" + log_bb
		combat_log.scroll_to_line(combat_log.get_line_count() - 1)
	if idle_after and GameManager.in_combat and not input_locked:
		_schedule_event_idle(token)


func _schedule_event_idle(token: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(EVENT_IDLE_DELAY).timeout
	if token != _event_token:
		return
	if not GameManager.in_combat or input_locked:
		return
	_showing_idle_prompt = true
	if event_label:
		var muted := UIThemeManager.get_color("secondary").to_html(false)
		event_label.text = "[color=#%s]%s[/color]" % [muted, EVENT_IDLE_PROMPT]


func _classify_event(line: String) -> String:
	var lower := line.to_lower()
	if "heal" in lower or "restores" in lower or ("use " in lower and "potion" in lower):
		return "heal"
	if "strikes" in lower or "critical" in lower or "you attack" in lower:
		return "player"
	if "attacks for" in lower or "hits for" in lower:
		return "enemy"
	if "damage" in lower and "strike" not in lower:
		return "enemy"
	return "neutral"


func _strip_bbcode(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\[/?[^\\]]+\\]")
	return re.sub(text, "", true)


func _colorize_event(line: String, kind: String) -> String:
	var gold := UIThemeManager.get_color("title_gold").to_html(false)
	var danger := UIThemeManager.get_color("danger").to_html(false)
	var success := UIThemeManager.get_color("success").to_html(false)
	var resolved := kind if kind != "auto" else _classify_event(line)
	var out := line
	var num_re := RegEx.new()
	num_re.compile("\\b(\\d+)\\b")
	match resolved:
		"player":
			out = num_re.sub(out, "[color=#%s]$1[/color]" % gold, true)
			out = out.replace("strikes", "[color=#%s]strikes[/color]" % gold)
			out = out.replace("Critical hit", "[color=#%s]Critical hit[/color]" % gold)
		"enemy":
			out = num_re.sub(out, "[color=#%s]$1[/color]" % danger, true)
			out = out.replace("damage", "[color=#%s]damage[/color]" % danger)
		"heal":
			out = num_re.sub(out, "[color=#%s]$1[/color]" % success, true)
			out = out.replace("Healed", "[color=#%s]Healed[/color]" % success)
			out = out.replace("restores", "[color=#%s]restores[/color]" % success)
		_:
			pass
	return out


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
	if player_status:
		player_status.set_active(true)
	if monster_status:
		monster_status.set_active(false)
	_set_input_locked(false)
	_set_dock_mode("root")
	# If last message was an enemy hit, schedule idle prompt so it does not fight the banner
	if not _showing_idle_prompt and event_label and "Last:" in event_label.text:
		_event_token += 1
		_schedule_event_idle(_event_token)


func _show_enemy_turn(animate: bool) -> void:
	if turn_banner:
		turn_banner.set_state(turn_banner.State.ENEMY_TURN, animate)
	if turn_indicator:
		turn_indicator.highlight_monster()
	if player_stage:
		player_stage.is_active = false
	if monster_stage:
		monster_stage.is_active = true
	if player_status:
		player_status.set_active(false)
	if monster_status:
		monster_status.set_active(true)
	_set_input_locked(true)


func _on_combat_started(_monster_name: String) -> void:
	round_number = 1
	_flee_failures = 0
	_history.clear()
	_set_log_expanded(false)
	_set_dock_mode("root")
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
		_refresh_intent()
		_show_player_turn(true)


func _on_combat_ended(player_won: bool) -> void:
	if performance_monitor:
		performance_monitor.stop_monitoring()
	_set_input_locked(true)
	var player = GameManager.get_player()
	if not player_won and player and player.health > 0:
		return
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
		var result: Dictionary = GameManager.resolve_defeat()
		_append_event(
			"Defeat. You recover in town and lose %d gold." % int(result.gold_lost))
		if is_inside_tree():
			await get_tree().create_timer(2.0).timeout
		GameManager.change_scene(str(result.return_scene))


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
	if GameManager.is_boss_combat():
		_append_event("There is no escape from the final battle.", "enemy")
		return
	_set_input_locked(true)
	GameManager.tick_player_action_status_effects()
	var flee_chance := CombatRules.get_escape_chance(_flee_failures)
	if randf() < flee_chance:
		GameManager.end_combat()
		_append_event("You successfully ran away!", "neutral")
		await get_tree().create_timer(1.0).timeout
		_change_to_exploration()
	else:
		_flee_failures += 1
		_append_event("Failed to run away!", "enemy")
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
		btn.custom_minimum_size = Vector2(130 if _compact_layout else 140, 52 if _compact_layout else 56)
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
		btn.custom_minimum_size = Vector2(130 if _compact_layout else 140, 52 if _compact_layout else 56)
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
