extends Control
# ExplorationScene - full-bleed map with floating HUD / location docks
enum PrimaryKind { REST, EXPLORE, TRAVEL, NONE }
const InventoryDialog = preload("res://scenes/ui/inventory_dialog.tscn")
const ShopDialog = preload("res://scenes/ui/shop_dialog.tscn")
const QuestLogDialog = preload("res://scenes/ui/quest_log_dialog.tscn")
const GameMenuDialog = preload("res://scenes/ui/game_menu_dialog.tscn")
const UI_BUTTON_SCENE = preload("res://scenes/components/ui_button.tscn")
const MapMarkerScript = preload("res://scripts/components/MapMarker.gd")
const HubChrome = preload("res://scripts/ui/ExplorationHubChrome.gd")
const DANGER_MAX := 25.0
const BODY_FONT_PATH := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
const DISPLAY_FONT_PATH := "res://assets/Cinzel-VariableFont_wght.ttf"
const STATUS_ICON_CALM := "res://assets/ui/icons/checkmark.png"
const STATUS_ICON_WARN := "res://assets/ui/icons/warning.png"
const STATUS_ICON_DANGER := "res://assets/ui/icons/error.png"
const MAP_ZOOM_MIN := 1.0
const MAP_ZOOM_MAX := 1.75
const MAP_ZOOM_STEP := 0.15
const EVENT_EXPANDED_MIN_H := 140.0
const EVENT_NARRATIVE_MIN_H := 64.0
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
var xp_bar: UIProgressBar
var gold_label: Label
var danger_bar: ProgressBar
var threat_tag: Label
var threat_icon: TextureRect
var map_texture: TextureRect
var markers_layer: Control
var map_content: Control
var map_clip: Control
var left_dock: Control
var right_dock: Control
var legend_panel: Control
var zoom_out_button: Button
var zoom_in_button: Button
var recenter_button: Button
var legend_button: Button
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
var event_card: PanelContainer
var event_margin: MarginContainer
var event_eyebrow: Label
var event_title: Label
var context_actions: VBoxContainer
var inventory_button: Button
var quest_log_button: Button
var menu_button: Button
var hp_tag: Label
var mp_tag: Label
var mp_row: Control
var _primary_kind: int = PrimaryKind.REST
var _primary_disable_reason: String = ""
var _map_zoom: float = 1.0
var _map_pan: Vector2 = Vector2.ZERO
var _event_expanded: bool = false
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
	_set_event_idle()
	GameManager.connect("game_loaded", Callable(self, "_on_game_loaded"))
	_setup_focus_navigation()
	await get_tree().process_frame
	# UIButton._ready sets large min sizes; re-apply compact chrome after children settle.
	_style_map_controls()
	_style_utility_buttons()
	_style_secondary_buttons()
	_layout_docks()
	_layout_map_markers()
	_apply_map_transform()
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_docks()
		if markers_layer:
			_layout_map_markers()
			_apply_map_transform()
func _unhandled_input(event: InputEvent) -> void:
	if not showing_choices or choice_buttons.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			idx = 0
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			idx = 1
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			idx = 2
		if idx >= 0 and idx < choice_buttons.size():
			var btn: Button = choice_buttons[idx]
			if is_instance_valid(btn) and not btn.disabled:
				btn.emit_signal("pressed")
				get_viewport().set_input_as_handled()
func _bind_nodes() -> void:
	background = $Background
	left_dock = $LeftDock
	right_dock = $RightDock
	map_clip = $MapRoot/MapClip
	map_content = $MapRoot/MapClip/MapContent
	map_texture = $MapRoot/MapClip/MapContent/MapTexture
	markers_layer = $MapRoot/MapClip/MapContent/MarkersLayer
	legend_panel = $MapRoot/LegendPanel
	zoom_out_button = $MapRoot/MapControls/ZoomOutButton
	zoom_in_button = $MapRoot/MapControls/ZoomInButton
	recenter_button = $MapRoot/MapControls/RecenterButton
	legend_button = $MapRoot/MapControls/LegendButton
	var left: Node = $LeftDock/HudPanel/LeftMargin/LeftVBox
	character_portrait = left.get_node("CharacterPortrait")
	name_banner = left.get_node("NameLevelRow/NameBanner")
	level_label = left.get_node("NameLevelRow/LevelLabel")
	hp_tag = left.get_node("HpRow/HpTag")
	hp_bar = left.get_node("HpRow/HpBar")
	mp_row = left.get_node("MpRow")
	mp_tag = left.get_node("MpRow/MpTag")
	mp_bar = left.get_node("MpRow/MpBar")
	xp_bar = left.get_node("XpRow/XpBar")
	gold_label = left.get_node("MetaRow/GoldLabel")
	var status_chip: Control = left.get_node_or_null("MetaRow/StatusChip")
	if status_chip:
		status_chip.visible = false
	threat_icon = left.get_node("ThreatRow/ThreatIcon")
	threat_tag = left.get_node("ThreatRow/ThreatTag")
	danger_bar = left.get_node("ThreatRow/DangerBar")
	var art: Node = $RightDock/RightVBox/LocationCard/LocationCardVBox/ArtFrame
	location_art = art.get_node("LocationArt")
	location_name = art.get_node("LocationName")
	var meta: Node = $RightDock/RightVBox/LocationCard/LocationCardVBox/LocationCardMargin/MetaVBox
	location_description = meta.get_node("LocationDescription")
	location_status = meta.get_node("LocationStatus")
	primary_action = $RightDock/RightVBox/PrimaryAction
	secondary_actions = $RightDock/RightVBox/SecondaryActions
	explore_button = $RightDock/RightVBox/SecondaryActions/ExploreButton
	rest_button = $RightDock/RightVBox/SecondaryActions/RestButton
	travel_button = $RightDock/RightVBox/SecondaryActions/TravelButton
	shop_button = $RightDock/RightVBox/SecondaryActions/ShopButton
	event_card = $RightDock/RightVBox/EventCard
	event_margin = $RightDock/RightVBox/EventCard/EventMargin
	event_eyebrow = $RightDock/RightVBox/EventCard/EventMargin/EventVBox/EventEyebrow
	event_title = $RightDock/RightVBox/EventCard/EventMargin/EventVBox/EventTitle
	narrative_log = $RightDock/RightVBox/EventCard/EventMargin/EventVBox/NarrativeLog
	context_actions = $RightDock/RightVBox/EventCard/EventMargin/EventVBox/ContextActions
	inventory_button = $RightDock/RightVBox/UtilityBar/InventoryButton
	quest_log_button = $RightDock/RightVBox/UtilityBar/QuestLogButton
	menu_button = $RightDock/RightVBox/UtilityBar/MenuButton
func _load_fonts() -> void:
	if ResourceLoader.exists(BODY_FONT_PATH):
		body_font = load(BODY_FONT_PATH)
	if ResourceLoader.exists(DISPLAY_FONT_PATH):
		display_font = load(DISPLAY_FONT_PATH)
func _apply_typography() -> void:
	var body_c := UIThemeManager.get_text_primary_color()
	for node in [level_label, gold_label, location_description, location_status,
			narrative_log, hp_tag, mp_tag, threat_tag, event_eyebrow, event_title]:
		if node == null:
			continue
		if body_font:
			node.add_theme_font_override("font", body_font)
		if node is Label:
			var size := UITypography.FONT_SIZE_BODY_REGULAR
			if node in [location_status, hp_tag, mp_tag, threat_tag, event_eyebrow]:
				size = UITypography.FONT_SIZE_CAPTION
			node.add_theme_font_size_override("font_size", size)
			node.add_theme_color_override("font_color", body_c)
		elif node is RichTextLabel:
			node.add_theme_font_size_override("normal_font_size", UITypography.FONT_SIZE_BODY_REGULAR)
			if body_font:
				node.add_theme_font_override("normal_font", body_font)
			node.add_theme_color_override("default_color", body_c)
	if display_font:
		if name_banner:
			name_banner.add_theme_font_override("font", display_font)
			name_banner.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_HEADING_MEDIUM)
		if location_name:
			location_name.add_theme_font_override("font", display_font)
			location_name.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_HEADING_MEDIUM)
		if primary_action:
			primary_action.add_theme_font_override("font", display_font)
			primary_action.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_BODY_LARGE)
	for btn in [inventory_button, quest_log_button, menu_button]:
		if btn == null:
			continue
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
func _style_panels() -> void:
	if background:
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.09, 0.07, 0.055, 1.0)
		background.add_theme_stylebox_override("panel", bg_style)
	HubChrome.style_floating_panel($LeftDock/HudPanel)
	HubChrome.style_floating_panel($RightDock/RightVBox/LocationCard)
	HubChrome.style_floating_panel(event_card)
	if legend_panel:
		HubChrome.style_floating_panel(legend_panel)
	if name_banner:
		name_banner.add_theme_color_override("font_color", UIThemeManager.get_color("title_gold"))
	if location_name:
		location_name.add_theme_color_override("font_color", UIThemeManager.get_color("title_gold"))
	if location_description:
		location_description.add_theme_color_override(
			"font_color", UIThemeManager.get_text_primary_color())
	_style_primary_action_button()
	_style_secondary_buttons()
	_style_utility_buttons()
	_style_map_controls()
func _style_primary_action_button() -> void:
	HubChrome.style_primary_action(primary_action, _primary_disable_reason)
func _style_secondary_buttons() -> void:
	HubChrome.style_quiet_buttons(
		[explore_button, rest_button, travel_button, shop_button], body_font, 34.0, 6)
func _style_utility_buttons() -> void:
	HubChrome.style_utility_buttons(
		[inventory_button, quest_log_button, menu_button], body_font)
func _style_map_controls() -> void:
	HubChrome.style_map_controls(
		zoom_out_button, zoom_in_button, recenter_button, legend_button, body_font)
func _layout_docks() -> void:
	if left_dock == null or right_dock == null:
		return
	var vp := size
	if vp.x < 32.0:
		vp = get_viewport_rect().size
	var left_w := clampf(vp.x * 0.15, 230.0, 280.0)
	var right_w := clampf(vp.x * 0.24, 340.0, 440.0)
	var pad := 10.0
	left_dock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_dock.offset_left = pad
	left_dock.offset_top = pad
	left_dock.offset_right = pad + left_w
	left_dock.offset_bottom = minf(vp.y - pad, pad + 520.0)
	right_dock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_dock.offset_left = -pad - right_w
	right_dock.offset_top = pad
	right_dock.offset_right = -pad
	right_dock.offset_bottom = vp.y - pad
func _apply_map_transform() -> void:
	if map_content == null or map_clip == null:
		return
	var base := map_clip.size
	if base.x < 8.0 or base.y < 8.0:
		return
	map_content.size = base
	map_content.pivot_offset = base * 0.5
	map_content.scale = Vector2(_map_zoom, _map_zoom)
	var max_pan_x := (base.x * (_map_zoom - 1.0)) * 0.5
	var max_pan_y := (base.y * (_map_zoom - 1.0)) * 0.5
	_map_pan.x = clampf(_map_pan.x, -max_pan_x, max_pan_x)
	_map_pan.y = clampf(_map_pan.y, -max_pan_y, max_pan_y)
	map_content.position = _map_pan
func _on_zoom_in_pressed() -> void:
	_map_zoom = minf(MAP_ZOOM_MAX, _map_zoom + MAP_ZOOM_STEP)
	_apply_map_transform()
	_layout_map_markers()
func _on_zoom_out_pressed() -> void:
	_map_zoom = maxf(MAP_ZOOM_MIN, _map_zoom - MAP_ZOOM_STEP)
	if is_equal_approx(_map_zoom, MAP_ZOOM_MIN):
		_map_pan = Vector2.ZERO
	_apply_map_transform()
	_layout_map_markers()
func _on_recenter_pressed() -> void:
	_map_zoom = 1.0
	_map_pan = Vector2.ZERO
	_apply_map_transform()
	_layout_map_markers()
func _on_legend_pressed() -> void:
	if legend_panel:
		legend_panel.visible = not legend_panel.visible
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
		map_markers, markers_layer.size,
		func(area_id: String) -> Vector2: return exploration_manager.get_map_pos(area_id)
	)
func _style_map_markers() -> void:
	var player_level := 1
	if GameManager.get_player():
		player_level = GameManager.get_player().level
	for area_id in map_markers:
		var marker: MapMarker = map_markers[area_id]
		var status = exploration_manager.get_travel_status(
			current_area_id, area_id, player_level)
		var state: int
		var reason := ""
		if area_id == current_area_id:
			state = MapMarker.MarkerState.CURRENT
		elif area_id != current_area_id and not status.connected:
			state = MapMarker.MarkerState.LOCKED
			reason = "No path from your current location"
		elif area_id != current_area_id and not status.level_met:
			state = MapMarker.MarkerState.LOCKED
			reason = "Requires level %d" % status.req_level
		elif area_id == selected_area_id:
			state = MapMarker.MarkerState.SELECTED
		else:
			state = MapMarker.MarkerState.AVAILABLE
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
		current_area_id, area_id, player_level)
	if location_status:
		if area_id == current_area_id:
			location_status.text = "Current location"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("title_gold"))
		elif status.can_travel:
			location_status.text = "Travel ready"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("success"))
		elif not status.connected:
			location_status.text = "No path from here"
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("danger"))
		elif not status.level_met:
			location_status.text = "Requires level %d" % status.req_level
			location_status.add_theme_color_override(
				"font_color", UIThemeManager.get_color("danger"))
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
		current_area_id, selected_area_id, player_level)
	var is_current := selected_area_id == current_area_id
	var is_town := current_area_id == "town"
	var explore_ok := ExplorationManager.is_explore_enabled(current_area_id)
	var shop_ok := ExplorationManager.is_shop_visible(current_area_id)
	_primary_disable_reason = ""
	if showing_choices:
		_primary_kind = PrimaryKind.NONE
		primary_action.visible = false
		primary_action.disabled = true
	elif not is_current and status.can_travel:
		primary_action.visible = true
		_primary_kind = PrimaryKind.TRAVEL
		var dest_name := str(exploration_manager.get_area_info(selected_area_id).get("name", "there"))
		_set_button_text(primary_action, "Travel to %s" % dest_name)
		primary_action.disabled = false
	elif not is_current and not status.can_travel:
		primary_action.visible = true
		_primary_kind = PrimaryKind.NONE
		if not status.connected:
			_set_button_text(primary_action, "No path from here")
			_primary_disable_reason = "No path from your current location."
		elif not status.level_met:
			_set_button_text(primary_action, "Requires level %d" % status.req_level)
			_primary_disable_reason = "Requires level %d." % status.req_level
		else:
			_set_button_text(primary_action, "Cannot travel")
			_primary_disable_reason = "Travel unavailable."
		primary_action.disabled = true
	elif is_current and is_town:
		primary_action.visible = true
		_primary_kind = PrimaryKind.REST
		_set_button_text(primary_action, "Rest")
		primary_action.disabled = false
	elif is_current and explore_ok:
		primary_action.visible = true
		_primary_kind = PrimaryKind.EXPLORE
		_set_button_text(primary_action, "Explore")
		primary_action.disabled = false
	else:
		primary_action.visible = true
		_primary_kind = PrimaryKind.REST
		_set_button_text(primary_action, "Rest")
		primary_action.disabled = false
	if explore_button:
		explore_button.visible = explore_ok and _primary_kind != PrimaryKind.EXPLORE and not showing_choices
	if rest_button:
		rest_button.visible = _primary_kind != PrimaryKind.REST and not showing_choices
	if travel_button:
		travel_button.visible = (
			status.can_travel and _primary_kind != PrimaryKind.TRAVEL
			and not is_current and not showing_choices)
	if shop_button:
		shop_button.visible = shop_ok and not showing_choices
	if secondary_actions:
		var any_s := false
		for btn in [explore_button, rest_button, travel_button, shop_button]:
			if btn and btn.visible:
				any_s = true
				break
		secondary_actions.visible = any_s
	_ensure_utility_enabled()
	_style_primary_action_button()
	_style_secondary_buttons()
func _ensure_utility_enabled() -> void:
	for btn in [inventory_button, quest_log_button, menu_button]:
		if btn:
			btn.disabled = false
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
		if mp_row:
			mp_row.visible = true
		mp_bar.visible = true
		mp_bar.max_value = max(1, player.max_mana)
		if mp_bar.has_method("set_value_animated"):
			mp_bar.set_value_animated(player.mana, false)
		else:
			mp_bar.value = player.mana
	elif mp_bar:
		if mp_row:
			mp_row.visible = false
		mp_bar.visible = false
	xp_bar.set_experience_progress(player)
	if gold_label:
		gold_label.text = "Gold  %d" % player.gold
	_update_danger_visuals()
	_style_map_markers()
	_update_action_hierarchy()
func _threat_level_word(level: float) -> String:
	if level < 5.0:
		return "Low"
	if level < 10.0:
		return "Moderate"
	if level < 15.0:
		return "Elevated"
	if level < 20.0:
		return "High"
	return "Critical"
func _danger_color(level: float) -> Color:
	var t := clampf(level / DANGER_MAX, 0.0, 1.0)
	var safe_color := UIThemeManager.get_color("success")
	var warn_color := UIThemeManager.get_color("accent")
	var danger_color := UIThemeManager.get_color("danger")
	if t < 0.4:
		return safe_color.lerp(warn_color, t / 0.4)
	return warn_color.lerp(danger_color, (t - 0.4) / 0.6)
func _restrained_threat_color(level: float) -> Color:
	var c := _danger_color(level)
	# Soften so the row never competes with combat/danger UI.
	c.a = 0.88
	return c.lerp(UIThemeManager.get_text_primary_color(), 0.18)
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
	var word := _threat_level_word(danger_level)
	var color := _restrained_threat_color(danger_level)
	var tip := (
		"Area threat (%.0f / %.0f). Higher threat raises combat odds while exploring. %s"
		% [danger_level, DANGER_MAX, ExplorationEventFactory.get_danger_flavor(danger_level)]
	)
	if threat_tag:
		threat_tag.text = "Threat: %s" % word
		threat_tag.add_theme_color_override("font_color", color)
		threat_tag.tooltip_text = tip
	if threat_icon:
		var path := STATUS_ICON_CALM
		if danger_level >= 15.0:
			path = STATUS_ICON_DANGER
		elif danger_level >= 5.0:
			path = STATUS_ICON_WARN
		if ResourceLoader.exists(path):
			threat_icon.texture = load(path)
		threat_icon.modulate = color
		threat_icon.tooltip_text = tip
	if danger_bar:
		danger_bar.max_value = DANGER_MAX
		danger_bar.value = danger_level
		danger_bar.show_percentage = false
		var bar_color := color
		bar_color.a = 0.65
		_style_fill_bar(danger_bar, bar_color)
		danger_bar.tooltip_text = tip
func _set_event_card_expanded(expanded: bool) -> void:
	_event_expanded = expanded
	if event_margin:
		var v_margin := 6 if expanded else 4
		event_margin.add_theme_constant_override("margin_top", v_margin)
		event_margin.add_theme_constant_override("margin_bottom", v_margin)
		event_margin.add_theme_constant_override("margin_left", 8)
		event_margin.add_theme_constant_override("margin_right", 8)
	if event_card:
		event_card.custom_minimum_size = (
			Vector2(0, EVENT_EXPANDED_MIN_H) if expanded else Vector2.ZERO
		)
	if event_title:
		event_title.visible = expanded and event_title.text != ""
	if narrative_log:
		narrative_log.visible = expanded
		narrative_log.custom_minimum_size = (
			Vector2(0, EVENT_NARRATIVE_MIN_H) if expanded else Vector2.ZERO
		)
	if context_actions:
		var has_choices := showing_choices or (
			context_actions.get_child_count() > 0 and expanded
		)
		context_actions.visible = expanded and has_choices
func _append_narrative(bbcode_text: String):
	if not narrative_log:
		return
	if not _event_expanded:
		if event_eyebrow:
			var cur := event_eyebrow.text
			if cur == "" or cur == "Ready" or cur == "READY":
				event_eyebrow.text = "Notice"
				event_eyebrow.add_theme_color_override(
					"font_color", UIThemeManager.get_color("title_gold"))
		if narrative_log:
			narrative_log.clear()
	elif narrative_log.get_parsed_text().length() > 0:
		narrative_log.append_text("\n[color=#99804020]---[/color]\n")
	narrative_log.append_text(bbcode_text + "\n")
	_set_event_card_expanded(true)
func _set_event_idle() -> void:
	if event_eyebrow:
		event_eyebrow.text = "Ready"
		event_eyebrow.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color())
	if event_title:
		event_title.text = ""
		event_title.visible = false
	if narrative_log:
		narrative_log.clear()
	_clear_context_actions()
	showing_choices = false
	_set_event_card_expanded(false)
func _present_event(event: Dictionary) -> void:
	var kind := str(event.get("type", "flavor"))
	var title := str(event.get("title", ""))
	var narrative := str(event.get("narrative", ""))
	var eyebrow := "Encounter"
	match kind:
		"combat":
			eyebrow = "Combat"
		"discovery":
			eyebrow = "Discovery"
		"choice":
			eyebrow = "Encounter"
		"quest":
			eyebrow = "Quest"
		"flavor":
			eyebrow = "Travel"
	if event_eyebrow:
		event_eyebrow.text = eyebrow
		event_eyebrow.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
	if event_title:
		if title != "":
			event_title.text = title
			if display_font:
				event_title.add_theme_font_override("font", display_font)
			event_title.add_theme_font_size_override(
				"font_size", UITypography.FONT_SIZE_BODY_LARGE)
			event_title.add_theme_color_override(
				"font_color", UIThemeManager.get_text_primary_color())
		else:
			event_title.text = ""
	if narrative_log:
		narrative_log.clear()
		var body := narrative
		if title != "":
			var title_bb := "[color=#d9b359]%s[/color]" % title
			body = body.replace(title_bb + "\n", "")
			body = body.replace(title_bb, "")
		narrative_log.append_text(body)
	_set_event_card_expanded(true)
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
	_present_event(event)
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
	_present_event(event)
	_apply_rewards(event.rewards)
func _handle_choice_event(event: Dictionary):
	_present_event(event)
	_show_choice_buttons(event.choices)
func _handle_flavor_event(event: Dictionary):
	_present_event(event)
func _handle_quest_event(event: Dictionary):
	_present_event(event)
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
			UIToast.toast_on(self, "Level up! Now level %d" % player.level, UIToast.Kind.LEVEL_UP, 2.2)
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
	var i := 0
	for choice in choices:
		var raw := str(choice.get("label", "???"))
		var label := ("%d  %s" % [i + 1, raw]) if i < 9 else raw
		var btn = _make_runtime_button(label)
		var choice_data = choice
		btn.pressed.connect(func(): _on_choice_selected(choice_data))
		context_actions.add_child(btn)
		choice_buttons.append(btn)
		i += 1
	_set_event_card_expanded(true)
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
	_set_event_idle()
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
	var dialog = QuestLogDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(quest_log_button))
func _on_menu_pressed():
	var dialog = GameMenuDialog.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): _restore_focus(menu_button))
func _set_primary_actions_enabled(enabled: bool) -> void:
	# World actions only — Inventory / Quests / Menu stay available.
	var buttons = [
		primary_action, explore_button, rest_button, travel_button, shop_button
	]
	for btn in buttons:
		if btn == null:
			continue
		if not enabled:
			btn.disabled = true
	if enabled:
		_update_ui()
	_ensure_utility_enabled()
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
	_set_event_idle()
