extends Control

# InventoryDialog - Inventory management with styled slots

const SLOT_BG_FILLED = Color(0.12, 0.10, 0.08, 0.85)
const SLOT_BG_EMPTY = Color(0.10, 0.09, 0.07, 0.4)
const SLOT_BG_SELECTED = Color(0.20, 0.15, 0.08, 0.95)
const SLOT_BG_HOVER = Color(0.16, 0.13, 0.10, 0.9)
const SLOT_BORDER_RADIUS = 2
const SLOT_BORDER_WIDTH = 2

var selected_item_index = -1
var selected_item = null
var _selected_button: Button = null

@onready var attack_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/AttackValue")
@onready var defense_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DefenseValue")
@onready var dexterity_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DexterityValue")

@onready var weapon_slot = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/WeaponRow/WeaponSlot")
@onready var armor_slot = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/ArmorRow/ArmorSlot")
@onready var accessory_slot = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/AccessoryRow/AccessorySlot")
@onready var weapon_label = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/WeaponRow/WeaponLabel")
@onready var armor_label = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/ArmorRow/ArmorLabel")
@onready var accessory_label = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "EquipmentPanel/VBoxContainer/AccessoryRow/AccessoryLabel")

@onready var inventory_grid = get_node(
	"DialogPanel/MarginContainer/MainContainer/RightPanel/InventoryGrid")
@onready var use_button = get_node(
	"DialogPanel/MarginContainer/MainContainer/RightPanel/ActionButtons/UseButton")
@onready var equip_button = get_node(
	"DialogPanel/MarginContainer/MainContainer/RightPanel/ActionButtons/EquipButton")
@onready var drop_button = get_node(
	"DialogPanel/MarginContainer/MainContainer/RightPanel/ActionButtons/DropButton")
@onready var close_button = get_node(
	"DialogPanel/MarginContainer/MainContainer/RightPanel/CloseButton")


func _ready():
	print("InventoryDialog ready")
	_update_character_stats()
	_update_equipment_display()
	_style_equipment_slots()
	_populate_inventory_grid()
	_update_action_buttons()
	_setup_focus_navigation()


func _update_character_stats():
	var player = GameManager.get_player()
	if not player:
		return
	attack_value.text = str(player.attack)
	defense_value.text = str(player.defense)
	dexterity_value.text = str(player.dexterity)


func _update_equipment_display():
	var player = GameManager.get_player()
	if not player:
		return
	_update_slot_display(weapon_slot, player.equipment.get("weapon"))
	_update_slot_display(armor_slot, player.equipment.get("armor"))
	_update_slot_display(accessory_slot, player.equipment.get("accessory"))


func _update_slot_display(slot_node, item):
	var label = slot_node.get_node("Label")
	if item:
		label.text = item.name
		label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("text_primary"))
	else:
		label.text = "[Empty]"
		var dim = UIThemeManager.get_color("secondary")
		dim.a = 0.5
		label.add_theme_color_override("font_color", dim)


func _style_equipment_slots():
	var bronze = UIThemeManager.get_color("border_bronze")
	var dim_label_color = UIThemeManager.get_color("secondary")
	for slot in [weapon_slot, armor_slot, accessory_slot]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.09, 0.07, 0.6)
		style.border_color = Color(bronze.r, bronze.g, bronze.b, 0.4)
		style.set_border_width_all(SLOT_BORDER_WIDTH)
		style.set_corner_radius_all(SLOT_BORDER_RADIUS)
		style.set_content_margin_all(4)
		slot.add_theme_stylebox_override("panel", style)
	for label in [weapon_label, armor_label, accessory_label]:
		label.add_theme_color_override("font_color", dim_label_color)


func _create_slot_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(SLOT_BORDER_WIDTH)
	style.set_corner_radius_all(SLOT_BORDER_RADIUS)
	style.set_content_margin_all(4)
	return style


func _apply_slot_styling(button: Button, has_item: bool):
	var bronze = UIThemeManager.get_color("border_bronze")
	var gold = UIThemeManager.get_color("accent")
	var text_color = UIThemeManager.get_color("text_primary")
	var secondary = UIThemeManager.get_color("secondary")
	if has_item:
		var normal_border = Color(bronze.r, bronze.g, bronze.b, 0.5)
		var hover_border = Color(gold.r, gold.g, gold.b, 0.7)
		button.add_theme_stylebox_override(
			"normal", _create_slot_style(SLOT_BG_FILLED, normal_border))
		button.add_theme_stylebox_override(
			"hover", _create_slot_style(SLOT_BG_HOVER, hover_border))
		button.add_theme_stylebox_override(
			"pressed", _create_slot_style(SLOT_BG_SELECTED, gold))
		button.add_theme_stylebox_override(
			"focus", _create_slot_style(SLOT_BG_FILLED, gold))
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", text_color)
		button.add_theme_color_override("font_pressed_color", text_color)
		button.add_theme_color_override("font_focus_color", text_color)
	else:
		var empty_border = Color(bronze.r, bronze.g, bronze.b, 0.2)
		var empty_style = _create_slot_style(SLOT_BG_EMPTY, empty_border)
		button.add_theme_stylebox_override("normal", empty_style)
		button.add_theme_stylebox_override("disabled", empty_style)
		var dim_text = Color(secondary.r, secondary.g, secondary.b, 0.5)
		button.add_theme_color_override("font_color", dim_text)
		button.add_theme_color_override("font_disabled_color", dim_text)


func _apply_selected_styling(button: Button):
	var gold = UIThemeManager.get_color("accent")
	var text_color = UIThemeManager.get_color("text_primary")
	button.add_theme_stylebox_override(
		"normal", _create_slot_style(SLOT_BG_SELECTED, gold))
	button.add_theme_stylebox_override(
		"hover", _create_slot_style(SLOT_BG_SELECTED, gold))
	button.add_theme_stylebox_override(
		"focus", _create_slot_style(SLOT_BG_SELECTED, gold))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)


func _populate_inventory_grid():
	for child in inventory_grid.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	for i in range(player.inventory.size()):
		var item = player.inventory[i]
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(80, 80)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.clip_text = true

		if item:
			slot_button.text = item.name
			slot_button.tooltip_text = (
				item.description + "\n" + _get_item_stats_text(item))
			_apply_slot_styling(slot_button, true)
		else:
			slot_button.text = "\u2014"
			slot_button.disabled = true
			_apply_slot_styling(slot_button, false)

		slot_button.connect(
			"pressed", Callable(self, "_on_slot_pressed").bind(i))
		inventory_grid.add_child(slot_button)


func _on_slot_pressed(slot_index: int):
	if _selected_button:
		_apply_slot_styling(_selected_button, true)

	selected_item_index = slot_index
	var player = GameManager.get_player()
	if player and slot_index < player.inventory.size():
		selected_item = player.inventory[slot_index]
	else:
		selected_item = null

	var slots = inventory_grid.get_children()
	if slot_index < slots.size():
		_selected_button = slots[slot_index]
		_apply_selected_styling(_selected_button)

	_update_action_buttons()


func _update_action_buttons():
	if selected_item:
		use_button.disabled = not selected_item.is_consumable()
		equip_button.disabled = not selected_item.can_equip()
		drop_button.disabled = false
	else:
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true


func _get_item_stats_text(item) -> String:
	var stats_text = "Value: " + str(item.value) + " gold"
	if item.attack_bonus > 0:
		stats_text += "\nAttack: +" + str(item.attack_bonus)
	if item.defense_bonus > 0:
		stats_text += "\nDefense: +" + str(item.defense_bonus)
	if item.health_bonus > 0:
		stats_text += "\nHealth: +" + str(item.health_bonus)
	if item.is_consumable():
		stats_text += "\nHeal: " + str(item.heal_amount) + " HP"
	return stats_text


func _on_use_pressed():
	if selected_item and selected_item.is_consumable():
		var player = GameManager.get_player()
		if player and selected_item.use(player):
			if selected_item.quantity <= 0:
				player.inventory[selected_item_index] = null
			refresh_inventory()


func _on_equip_pressed():
	if selected_item and selected_item.can_equip():
		var player = GameManager.get_player()
		if player:
			var slot = selected_item.get_equip_slot()
			var old_item = player.unequip_item(slot)
			player.equip_item(selected_item, slot)
			player.inventory[selected_item_index] = old_item
			refresh_inventory()


func _on_drop_pressed():
	if selected_item:
		var player = GameManager.get_player()
		if player:
			player.inventory[selected_item_index] = null
			refresh_inventory()


func _on_close_pressed():
	queue_free()


func _setup_focus_navigation():
	var slots = inventory_grid.get_children()
	var columns = inventory_grid.columns if inventory_grid.columns > 0 else 5

	for i in range(slots.size()):
		var col = i % columns
		if col < columns - 1 and i + 1 < slots.size():
			slots[i].set("focus_neighbor_right", slots[i + 1].get_path())
		elif col == columns - 1 and i - col >= 0:
			slots[i].set("focus_neighbor_right", slots[i - col].get_path())
		if col > 0:
			slots[i].set("focus_neighbor_left", slots[i - 1].get_path())
		else:
			var row_end = min(i + columns - 1, slots.size() - 1)
			slots[i].set("focus_neighbor_left", slots[row_end].get_path())
		if i + columns < slots.size():
			slots[i].set(
				"focus_neighbor_bottom", slots[i + columns].get_path())
		else:
			slots[i].set(
				"focus_neighbor_bottom", use_button.get_path())
		if i - columns >= 0:
			slots[i].set(
				"focus_neighbor_top", slots[i - columns].get_path())

	use_button.set("focus_neighbor_right", equip_button.get_path())
	use_button.set("focus_neighbor_left", drop_button.get_path())
	use_button.set("focus_neighbor_bottom", close_button.get_path())

	equip_button.set("focus_neighbor_left", use_button.get_path())
	equip_button.set("focus_neighbor_right", drop_button.get_path())
	equip_button.set("focus_neighbor_bottom", close_button.get_path())

	drop_button.set("focus_neighbor_left", equip_button.get_path())
	drop_button.set("focus_neighbor_right", use_button.get_path())
	drop_button.set("focus_neighbor_bottom", close_button.get_path())

	close_button.set("focus_neighbor_top", use_button.get_path())

	if slots.size() > 0:
		use_button.set(
			"focus_neighbor_top",
			slots[min(0, slots.size() - 1)].get_path())
		equip_button.set(
			"focus_neighbor_top",
			slots[min(1, slots.size() - 1)].get_path())
		drop_button.set(
			"focus_neighbor_top",
			slots[min(2, slots.size() - 1)].get_path())

	var focused = false
	for slot in slots:
		if not slot.disabled:
			slot.grab_focus()
			focused = true
			break
	if not focused:
		close_button.grab_focus()


func refresh_inventory():
	selected_item = null
	selected_item_index = -1
	_selected_button = null
	_update_character_stats()
	_update_equipment_display()
	_style_equipment_slots()
	_populate_inventory_grid()
	_update_action_buttons()
	_setup_focus_navigation()
