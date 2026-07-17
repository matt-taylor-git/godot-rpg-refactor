extends Control

# ExplorationScene - Unified hub: character HUD, map travel, location card, actions
enum PrimaryKind { REST, EXPLORE, TRAVEL, NONE }
const InventoryDialog = preload("res://scenes/ui/inventory_dialog.tscn")
const ShopDialog = preload("res://scenes/ui/shop_dialog.tscn")
const QuestLogDialog = preload("res://scenes/ui/quest_log_dialog.tscn")
const GameMenuDialog = preload("res://scenes/ui/game_menu_dialog.tscn")
const UI_BUTTON_SCENE = preload("res://scenes/components/ui_button.tscn")
const MapMarkerScript = preload("res://scripts/components/MapMarker.gd")
const DANGER_MAX := 25.0
const BODY_FONT_PATH := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
const DISPLAY_FONT_PATH := "res://assets/Cinzel-VariableFont_wght.ttf"
const STATUS_ICON_CALM := "res://assets/ui/icons/checkmark.png"
const STATUS_ICON_WARN := "res://assets/ui/icons/warning.png"
const STATUS_ICON_DANGER := "res://assets/ui/icons/error.png"
var current_area_id: String = "town"
var selected_area_id: String = "town"
var danger_level: float = 0.0
var steps_taken: int = 0
var exploration_manager: ExplorationManager = null
var showing_choices: bool = false
var choice_buttons: Array = []
var map_markers: Dictionary = {}
var body_font: Font = null
var display_font: Font = null
var visited_areas: Array = ["town"]
var background: Panel
var character_portrait: TextureRect
var name_banner: Label
var level_label: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var gold_label: Label
var status_chip: PanelContainer
var status_icon: TextureRect
var status_label: Label
var danger_bar: ProgressBar
var map_texture: TextureRect
var markers_layer: Control
var location_art: TextureRect
var location_name: Label
var location_description: Label
var location_status: Label
var primary_action: Button
var secondary_actions: HBoxContainer
var explore_button: Button
var rest_button: Button
var travel_button: Button
var shop_button: Button
var narrative_log: RichTextLabel
var narrative_panel: PanelContainer
var context_actions: VBoxContainer
var inventory_button: Button
var quest_log_button: Button
var menu_button: Button
var _primary_kind: int = PrimaryKind.REST

func _ready():
	print("ExplorationScene ready")
	_bind_nodes()
	exploration_manager = ExplorationManager.new()
	add_child(exploration_manager)
	_load_fonts()
	_style_panels()
	_apply_typography()
	_load_exploration_state()
	selected_area_id = current_area_id
	_setup_map()
	_update_ui()
	_update_location_preview(selected_area_id)
	GameManager.connect("game_loaded", Callable(self, "_on_game_loaded"))
	_setup_focus_navigation()
	_append_narrative(_get_area_entry_text())
	await get_tree().process_frame
	_layout_map_markers()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and markers_layer:
		_layout_map_markers()

func _bind_nodes() -> void:
	background = $Background
	var left: Node = $Hub/LeftColumn/HudPanel/LeftMargin/LeftVBox
	character_portrait = left.get_node("CharacterPortrait")
	name_banner = left.get_node("NameLevelRow/NameBanner")
	level_label = left.get_node("NameLevelRow/LevelLabel")
	hp_bar = left.get_node("HpBar")
	mp_bar = left.get_node("MpBar")
	gold_label = left.get_node("GoldLabel")
	status_chip = left.get_node("StatusChip")
	status_icon = left.get_node("StatusChip/StatusChipMargin/StatusChipRow/StatusIcon")
	status_label = left.get_node("StatusChip/StatusChipMargin/StatusChipRow/StatusLabel")
	danger_bar = left.get_node("DangerBar")
	map_texture = $Hub/CenterColumn/MapPanel/MapInner/MapTexture
	markers_layer = $Hub/CenterColumn/MapPanel/MapInner/MarkersLayer
	var card: Node = $Hub/RightColumn/LocationCard/LocationCardMargin/LocationCardVBox
	location_art = card.get_node("LocationArt")
	location_name = card.get_node("LocationName")
	location_description = card.get_node("LocationDescription")
	location_status = card.get_node("LocationStatus")
	primary_action = $Hub/RightColumn/PrimaryAction
	secondary_actions = $Hub/RightColumn/SecondaryActions
	explore_button = $Hub/RightColumn/SecondaryActions/ExploreButton
	rest_button = $Hub/RightColumn/SecondaryActions/RestButton
	travel_button = $Hub/RightColumn/SecondaryActions/TravelButton
	shop_button = $Hub/RightColumn/SecondaryActions/ShopButton
	narrative_log = $Hub/RightColumn/NarrativePanel/NarrativeLog
	narrative_panel = $Hub/RightColumn/NarrativePanel
	context_actions = $Hub/RightColumn/ContextActions
	inventory_button = $Hub/RightColumn/UtilityBar/InventoryButton
	quest_log_button = $Hub/RightColumn/UtilityBar/QuestLogButton
	menu_button = $Hub/RightColumn/UtilityBar/MenuButton

func _load_fonts() -> void:
	if ResourceLoader.exists(BODY_FONT_PATH):
		body_font = load(BODY_FONT_PATH)
	if ResourceLoader.exists(DISPLAY_FONT_PATH):
		display_font = load(DISPLAY_FONT_PATH)

func _apply_typography() -> void:
	var body_nodes: Array = [
		level_label, gold_label, status_label, location_description, location_status, narrative_log
	]
	for node in body_nodes:
		if node == null:
			continue
		if body_font:
			node.add_theme_font_override("font", body_font)
		if node is Label or node is RichTextLabel:
			var size := UITypography.FONT_SIZE_BODY_REGULAR
			if node == location_description or node == status_label:
				size = UITypography.FONT_SIZE_CAPTION
			if node is Label:
				node.add_theme_font_size_override("font_size", size)
			elif node is RichTextLabel:
				node.add_theme_font_size_override("normal_font_size", size)
				if body_font:
					node.add_theme_font_override("normal_font", body_font)
	if display_font:
		if name_banner:
			name_banner.add_theme_font_override("font", display_font)
			name_banner.add_theme_font_size_override(
				"font_size", UITypography.FONT_SIZE_HEADING_MEDIUM
			)
		if location_name:
			location_name.add_theme_font_override("font", display_font)
			location_name.add_theme_font_size_override(
				"font_size", UITypography.FONT_SIZE_HEADING_MEDIUM
			)
		if primary_action:
			primary_action.add_theme_font_override("font", display_font)
			primary_action.add_theme_font_size_override(
				"font_size", UITypography.FONT_SIZE_BODY_LARGE
			)
	if location_description:
		location_description.add_theme_constant_override("line_spacing", 4)
	if narrative_log:
		narrative_log.add_theme_constant_override("line_separation", 4)

func _style_panels() -> void:
	if background:
		var bg_style := StyleBoxFlat.new()
		var bg = UIThemeManager.get_background_color()
		bg_style.bg_color = Color(
			clampf(bg.r * 1.15, 0.0, 0.16),
			clampf(bg.g * 1.05, 0.0, 0.13),
			clampf(bg.b * 1.0, 0.0, 0.11),
			1.0
		)
		background.add_theme_stylebox_override("panel", bg_style)
	_apply_panel_style($Hub/LeftColumn/HudPanel, false)
	_apply_panel_style($Hub/CenterColumn/MapPanel, false)
	_apply_panel_style($Hub/RightColumn/LocationCard, true)
	_apply_panel_style(narrative_panel, false)
	_apply_panel_style(status_chip, false)
	if name_banner:
		name_banner.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
	if location_name:
		location_name.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
	if location_status:
		location_status.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color())
	if location_description:
		location_description.add_theme_color_override(
			"font_color", UIThemeManager.get_text_primary_color())
	_style_primary_action_button()
	_style_secondary_buttons()
	_style_utility_buttons()

func _apply_panel_style(node: Control, framed: bool) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.94)
	style.set_corner_radius_all(2)
	if framed:
		style.border_color = UIThemeManager.get_border_bronze_color()
		style.border_color.a = 0.75
		style.set_border_width_all(2)
		style.set_content_margin_all(4)
	else:
		var edge := UIThemeManager.get_border_bronze_color()
		edge.a = 0.28
		style.border_color = edge
		style.set_border_width_all(1)
		style.set_content_margin_all(4)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)

func _style_primary_action_button() -> void:
	if primary_action == null:
		return
	var gold := UIThemeManager.get_color("title_gold")
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.16, 0.08, 0.95)
	style.border_color = gold
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	primary_action.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.28, 0.20, 0.10, 0.98)
	hover.border_color = gold.lightened(0.12)
	primary_action.add_theme_stylebox_override("hover", hover)
	primary_action.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.16, 0.12, 0.06, 1.0)
	primary_action.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.12, 0.10, 0.08, 0.55)
	disabled.border_color = UIThemeManager.get_secondary_color()
	disabled.border_color.a = 0.35
	primary_action.add_theme_stylebox_override("disabled", disabled)
	primary_action.custom_minimum_size = Vector2(0, 48)

func _style_secondary_buttons() -> void:
	var bronze := UIThemeManager.get_border_bronze_color()
	bronze.a = 0.28
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.07, 0.75)
	style.border_color = bronze
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	var hover := style.duplicate()
	hover.bg_color = Color(0.15, 0.12, 0.09, 0.88)
	hover.border_color = UIThemeManager.get_accent_color()
	hover.border_color.a = 0.45
	for btn in [explore_button, rest_button, travel_button, shop_button]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		var disabled := style.duplicate()
		disabled.bg_color = Color(0.09, 0.08, 0.07, 0.45)
		disabled.border_color.a = 0.15
		btn.add_theme_stylebox_override("disabled", disabled)
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		btn.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color()
		)
		btn.add_theme_color_override(
			"font_hover_color", UIThemeManager.get_text_primary_color()
		)
		btn.add_theme_color_override(
			"font_disabled_color", UIThemeManager.get_color("disabled_text")
		)

func _style_utility_buttons() -> void:
	var bronze := UIThemeManager.get_border_bronze_color()
	bronze.a = 0.22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.06, 0.7)
	style.border_color = bronze
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	for btn in [inventory_button, quest_log_button, menu_button]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate()
		hover.bg_color = Color(0.13, 0.11, 0.08, 0.85)
		hover.border_color = UIThemeManager.get_accent_color()
		hover.border_color.a = 0.4
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		btn.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color()
		)

func _setup_map() -> void:
	if map_texture and ResourceLoader.exists(ExplorationManager.WORLD_MAP_TEXTURE):
		map_texture.texture = load(ExplorationManager.WORLD_MAP_TEXTURE)
	for child in markers_layer.get_children():
		child.queue_free()
	map_markers.clear()
	for area_id in exploration_manager.get_all_area_ids():
		var info = exploration_manager.get_area_info(area_id)
		var marker = MapMarkerScript.new()
		marker.setup(area_id, str(info.get("name", area_id)), body_font)
		marker.marker_pressed.connect(_on_map_marker_pressed)
		markers_layer.add_child(marker)
		map_markers[area_id] = marker
	_style_map_markers()

func _layout_map_markers() -> void:
	if markers_layer == null:
		return
	MapMarker.layout_all(
		map_markers,
		markers_layer.size,
		func(area_id: String) -> Vector2: return exploration_manager.get_map_pos(area_id)
	)

func _style_map_markers() -> void:
	var player_level := 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	for area_id in map_markers:
		var marker: MapMarker = map_markers[area_id]
		var status = exploration_manager.get_travel_status(
			current_area_id, area_id, player_level
		)
		var state: int = MapMarker.MarkerState.NEUTRAL
		var reason := ""
		if area_id == current_area_id:
			state = MapMarker.MarkerState.CURRENT
		elif area_id == selected_area_id:
			if area_id != current_area_id and not status.level_met and status.connected:
				state = MapMarker.MarkerState.LOCKED
				reason = "Requires level %d" % status.req_level
			elif area_id != current_area_id and not status.connected:
				state = MapMarker.MarkerState.UNREACHABLE
			else:
				state = MapMarker.MarkerState.SELECTED
		elif area_id != current_area_id and not status.connected:
			state = MapMarker.MarkerState.UNREACHABLE
		elif area_id != current_area_id and not status.level_met:
			state = MapMarker.MarkerState.LOCKED
			reason = "Requires level %d" % status.req_level
		else:
			state = MapMarker.MarkerState.NEUTRAL
		marker.set_marker_state(state, reason)

func _on_map_marker_pressed(area_id: String) -> void:
	if showing_choices:
		return
	selected_area_id = area_id
	_update_location_preview(area_id)
	_style_map_markers()
	_update_action_hierarchy()

func _update_location_preview(area_id: String) -> void:
	var info = exploration_manager.get_area_info(area_id)
	if location_name:
		location_name.text = str(info.get("name", "Unknown"))
	if location_description:
		location_description.text = str(info.get("description", ""))
	var player_level := 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	var status = exploration_manager.get_travel_status(
		current_area_id, area_id, player_level
	)
	if location_status:
		if area_id == current_area_id:
			location_status.text = "You are here"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("title_gold")
			)
		elif status.can_travel:
			location_status.text = "Travel ready"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("success")
			)
		elif not status.connected:
			location_status.text = "Not reachable from here"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_secondary_color()
			)
		elif not status.level_met:
			location_status.text = "Requires level %d" % status.req_level
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("danger")
			)
		else:
			location_status.text = ""

	if location_art:
		var path = exploration_manager.get_location_image_path(area_id)
		if path != "" and ResourceLoader.exists(path):
			location_art.texture = load(path)
		else:
			location_art.texture = null

func _update_action_hierarchy() -> void:
	if primary_action == null:
		return

	var player_level := 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	var status = exploration_manager.get_travel_status(
		current_area_id, selected_area_id, player_level
	)
	var is_current := selected_area_id == current_area_id
	var is_town := current_area_id == "town"
	var explore_ok := ExplorationManager.is_explore_enabled(current_area_id)
	var shop_ok := ExplorationManager.is_shop_visible(current_area_id)

	# Primary CTA first so secondaries can hide duplicates
	if showing_choices:
		_primary_kind = PrimaryKind.NONE
		_set_button_text(primary_action, "Choose below...")
		primary_action.disabled = true
	elif not is_current and status.can_travel:
		_primary_kind = PrimaryKind.TRAVEL
		var dest_name := str(
			exploration_manager.get_area_info(selected_area_id).get("name", "there")
		)
		_set_button_text(primary_action, "Travel to %s" % dest_name)
		primary_action.disabled = false
	elif not is_current and not status.can_travel:
		_primary_kind = PrimaryKind.NONE
		if not status.connected:
			_set_button_text(primary_action, "No path from here")
		elif not status.level_met:
			_set_button_text(primary_action, "Requires level %d" % status.req_level)
		else:
			_set_button_text(primary_action, "Cannot travel")
		primary_action.disabled = true
	elif is_current and is_town:
		_primary_kind = PrimaryKind.REST
		_set_button_text(primary_action, "Rest")
		primary_action.disabled = false
	elif is_current and explore_ok:
		_primary_kind = PrimaryKind.EXPLORE
		_set_button_text(primary_action, "Explore")
		primary_action.disabled = false
	else:
		_primary_kind = PrimaryKind.REST
		_set_button_text(primary_action, "Rest")
		primary_action.disabled = showing_choices

	# Compact secondaries: only useful alternatives, never duplicate primary
	if explore_button:
		explore_button.visible = (
			explore_ok and _primary_kind != PrimaryKind.EXPLORE and not showing_choices
		)
		explore_button.disabled = false
	if rest_button:
		rest_button.visible = (
			_primary_kind != PrimaryKind.REST and not showing_choices
		)
		rest_button.disabled = false
	if travel_button:
		travel_button.visible = (
			status.can_travel
			and _primary_kind != PrimaryKind.TRAVEL
			and not is_current
			and not showing_choices
		)
		travel_button.disabled = false
	if shop_button:
		shop_button.visible = shop_ok and not showing_choices
		shop_button.disabled = false

	if secondary_actions:
		var any_secondary := false
		for btn in [explore_button, rest_button, travel_button, shop_button]:
			if btn and btn.visible:
				any_secondary = true
				break
		secondary_actions.visible = any_secondary

	_style_primary_action_button()
	_style_secondary_buttons()

func _set_button_text(btn: Button, label: String) -> void:
	if btn == null:
		return
	if btn.get("button_text") != null:
		btn.set("button_text", label)
	btn.text = label

func _update_ui():
	if not GameManager.get_player():
		_update_action_hierarchy()
		return

	var player = GameManager.get_player()
	if name_banner:
		name_banner.text = str(player.name)
	if level_label:
		level_label.text = "Lv %d" % player.level
	if character_portrait:
		character_portrait.texture = PortraitLookup.get_player_texture(player)

	if hp_bar:
		hp_bar.max_value = max(1, player.max_health)
		if hp_bar.has_method("set_value_animated"):
			hp_bar.set_value_animated(player.health, false)
		else:
			hp_bar.value = player.health

	if player.max_mana > 0 and mp_bar:
		mp_bar.visible = true
		mp_bar.max_value = max(1, player.max_mana)
		if mp_bar.has_method("set_value_animated"):
			mp_bar.set_value_animated(player.mana, false)
		else:
			mp_bar.value = player.mana
	elif mp_bar:
		mp_bar.visible = false

	if gold_label:
		gold_label.text = "Gold: %d" % player.gold

	_update_status_chip()
	_update_danger_visuals()
	_style_map_markers()
	_update_action_hierarchy()

func _update_status_chip() -> void:
	var short := _danger_short_label(danger_level)
	var color := _danger_color(danger_level)
	if status_label:
		status_label.text = short
		status_label.add_theme_color_override("font_color", color)
		status_label.tooltip_text = ExplorationEventFactory.get_danger_flavor(danger_level)
	if status_icon:
		var path := STATUS_ICON_CALM
		if danger_level >= 15.0:
			path = STATUS_ICON_DANGER
		elif danger_level >= 5.0:
			path = STATUS_ICON_WARN
		if ResourceLoader.exists(path):
			status_icon.texture = load(path)
		status_icon.modulate = color

func _danger_short_label(level: float) -> String:
	if level < 5.0:
		return "Calm"
	if level < 10.0:
		return "Uneasy"
	if level < 15.0:
		return "Tense"
	if level < 20.0:
		return "Dangerous"
	return "Perilous"

func _danger_color(level: float) -> Color:
	var t := clampf(level / DANGER_MAX, 0.0, 1.0)
	var safe_color := UIThemeManager.get_color("success")
	var warn_color := UIThemeManager.get_color("accent")
	var danger_color := UIThemeManager.get_color("danger")
	if t < 0.4:
		return safe_color.lerp(warn_color, t / 0.4)
	return warn_color.lerp(danger_color, (t - 0.4) / 0.6)

func _style_fill_bar(bar: ProgressBar, color: Color) -> void:
	if bar == null:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.10, 0.08, 0.8)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

func _update_danger_visuals():
	if danger_bar:
		danger_bar.max_value = DANGER_MAX
		danger_bar.value = danger_level
		danger_bar.show_percentage = false
		_style_fill_bar(danger_bar, _danger_color(danger_level))

func _append_narrative(bbcode_text: String):
	if not narrative_log:
		return
	if narrative_log.text.length() > 0:
		narrative_log.append_text("\n[color=#99804020]---[/color]\n")
	narrative_log.append_text(bbcode_text + "\n")

func _get_area_entry_text() -> String:
	# Location name/description live on the right card — log stays event-only.
	var area_info = exploration_manager.get_current_area_info()
	if str(area_info.get("type", "")) == "safe":
		return "[color=#948d84]A quiet moment to prepare.[/color]"
	return "[color=#948d84]Keep your guard up.[/color]"

func _on_primary_action_pressed() -> void:
	match _primary_kind:
		PrimaryKind.REST:
			_on_rest_pressed()
		PrimaryKind.EXPLORE:
			_on_explore_pressed()
		PrimaryKind.TRAVEL:
			_on_travel_confirm_pressed()
		_:
			pass

func _on_explore_pressed():
	if showing_choices:
		return
	if not ExplorationManager.is_explore_enabled(current_area_id):
		return

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
	await _play_encounter_pulse()
	var monster_type = event.get("monster_type", "")
	if monster_type != "":
		GameManager.start_combat_with_type(monster_type)
	else:
		GameManager.start_combat()

func _play_encounter_pulse() -> void:
	var reduce_motion = GameSettings.get_reduced_motion()
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

func _make_runtime_button(label: String) -> Button:
	var btn = UI_BUTTON_SCENE.instantiate()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	btn.ready.connect(_on_runtime_button_ready.bind(btn), CONNECT_ONE_SHOT)
	return btn

func _on_runtime_button_ready(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	btn.custom_minimum_size = Vector2(100, 36)
	btn.clip_text = true
	if body_font:
		btn.add_theme_font_override("font", body_font)

func _show_choice_buttons(choices: Array):
	showing_choices = true
	_set_primary_actions_enabled(false)
	_clear_context_actions()

	for choice in choices:
		var btn = _make_runtime_button(choice.get("label", "???"))
		var choice_data = choice
		btn.pressed.connect(func(): _on_choice_selected(choice_data))
		context_actions.add_child(btn)
		choice_buttons.append(btn)

	if choice_buttons.size() > 0:
		_restore_focus(choice_buttons[0])
	_update_action_hierarchy()

func _on_choice_selected(choice_data: Dictionary):
	_clear_context_actions()
	showing_choices = false
	_set_primary_actions_enabled(true)

	var result_text = choice_data.get("result_narrative", "")
	if result_text != "":
		_append_narrative(result_text)

	var rewards = choice_data.get("rewards", {})
	_apply_rewards(rewards)
	_save_exploration_state()
	_update_ui()
	_restore_focus(primary_action)

func _clear_context_actions() -> void:
	for btn in choice_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	choice_buttons.clear()
	if context_actions:
		for child in context_actions.get_children():
			child.queue_free()

func _on_travel_confirm_pressed():
	if showing_choices:
		return
	var player_level = 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	var status = exploration_manager.get_travel_status(
		current_area_id, selected_area_id, player_level)
	if not status.can_travel:
		if status.reason == "level":
			_append_narrative(
				"[color=#948d84]You are not strong enough yet (level %d required).[/color]" \
				% status.req_level)
		elif status.reason == "not_connected":
			_append_narrative(
				"[color=#948d84]There is no path to that place from here.[/color]")
		return
	_enter_area(selected_area_id)

func _enter_area(area_id: String):
	current_area_id = area_id
	selected_area_id = area_id
	exploration_manager.enter_area(area_id)
	danger_level = 0.0
	if not area_id in visited_areas:
		visited_areas.append(area_id)
	_update_location_preview(area_id)
	_update_ui()
	_append_narrative(_get_area_entry_text())
	_save_exploration_state()
	_restore_focus(primary_action)

func _on_rest_pressed():
	if showing_choices:
		return
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

func _restore_focus(btn: Control) -> void:
	# Dialogs may exit because the hub itself is freeing (e.g. Game Menu → main menu).
	if btn == null or not is_instance_valid(btn):
		return
	if not btn.is_inside_tree():
		return
	btn.grab_focus()

func _on_inventory_pressed():
	if showing_choices:
		return
	var dialog = InventoryDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(inventory_button))

func _on_shop_pressed():
	if showing_choices:
		return
	if not ExplorationManager.is_shop_visible(current_area_id):
		return
	var dialog = ShopDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(shop_button))

func _on_quest_log_pressed():
	if showing_choices:
		return
	var dialog = QuestLogDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(quest_log_button))

func _on_menu_pressed():
	if showing_choices:
		return
	var dialog = GameMenuDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(menu_button))

func _set_primary_actions_enabled(enabled: bool) -> void:
	var buttons = [
		primary_action, explore_button, rest_button, travel_button, shop_button,
		inventory_button, quest_log_button, menu_button
	]
	for btn in buttons:
		if btn == null:
			continue
		if not enabled:
			btn.disabled = true
	if enabled:
		_update_ui()

func _setup_focus_navigation():
	var row = [
		primary_action, explore_button, rest_button, travel_button, shop_button,
		inventory_button, quest_log_button, menu_button
	]
	for i in range(row.size()):
		if row[i] == null:
			continue
		var prev = (i - 1 + row.size()) % row.size()
		var next = (i + 1) % row.size()
		while row[prev] == null:
			prev = (prev - 1 + row.size()) % row.size()
		while row[next] == null:
			next = (next + 1) % row.size()
		row[i].set("focus_neighbor_top", row[prev].get_path())
		row[i].set("focus_neighbor_bottom", row[next].get_path())

	_restore_focus(primary_action)

func _load_exploration_state():
	var state = GameManager.get_exploration_state()
	steps_taken = state.get("steps_taken", 0)
	current_area_id = state.get("current_area_id", "town")
	danger_level = state.get("danger_level", 0.0)
	visited_areas = state.get("visited_areas", ["town"])
	if visited_areas is Array and not current_area_id in visited_areas:
		visited_areas.append(current_area_id)
	exploration_manager.enter_area(current_area_id)

func _save_exploration_state():
	GameManager.set_exploration_state({
		"steps_taken": steps_taken,
		"encounter_chance": danger_level,
		"steps_since_last_encounter": 0,
		"current_area_id": current_area_id,
		"danger_level": danger_level,
		"visited_areas": visited_areas,
	})

func _on_game_loaded():
	_load_exploration_state()
	selected_area_id = current_area_id
	_update_location_preview(selected_area_id)
	_update_ui()
	if narrative_log:
		narrative_log.clear()
	_append_narrative(_get_area_entry_text())
