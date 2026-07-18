extends Control

# InventoryDialog - Inventory management with rarity borders and equipped glow

const SLOT_BG_FILLED = Color(0.12, 0.10, 0.08, 0.85)
const SLOT_BG_EMPTY = Color(0.10, 0.09, 0.07, 0.4)
const SLOT_BG_SELECTED = Color(0.20, 0.15, 0.08, 0.95)
const SLOT_BG_HOVER = Color(0.16, 0.13, 0.10, 0.9)
const SLOT_BORDER_RADIUS = 2
const SLOT_BORDER_WIDTH = 2

var selected_item_index = -1
var selected_item = null
var _selected_button: Button = null

@onready var dialog_panel = $DialogPanel
@onready var attack_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/AttackValue")
@onready var defense_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DefenseValue")
@onready var dexterity_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DexterityValue")
@onready var mana_value = get_node(
	"DialogPanel/MarginContainer/MainContainer/LeftPanel/"
	+ "CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/ManaValue")

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
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.SLIDE)
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
	# Effective combat stats (equipment bonuses applied once via getters)
	attack_value.text = str(player.get_attack_power())
	defense_value.text = str(player.get_defense_power())
	dexterity_value.text = str(player.dexterity)
	if mana_value:
		mana_value.text = "%d/%d" % [player.mana, player.max_mana]


func _update_equipment_display():
	var player = GameManager.get_player()
	if not player:
		return
	_update_slot_display(weapon_slot, player.equipment.get("weapon"))
	_update_slot_display(armor_slot, player.equipment.get("armor"))
	_update_slot_display(accessory_slot, player.equipment.get("accessory"))


func _update_slot_display(slot_node, item):
	var label = slot_node.get_node_or_null("SlotContent/Label")
	if label == null:
		label = slot_node.get_node_or_null("Label")
	var icon = slot_node.get_node_or_null("SlotContent/Icon")
	if item:
		if label:
			label.text = item.name
			label.add_theme_color_override(
				"font_color", UIThemeManager.get_color("text_primary"))
		if icon:
			icon.texture = ItemLookup.get_item_texture(item)
			icon.modulate = Color(1, 1, 1, 1)
	else:
		if label:
			label.text = "[Empty]"
			var dim = UIThemeManager.get_color("secondary")
			dim.a = 0.5
			label.add_theme_color_override("font_color", dim)
		if icon:
			icon.texture = null


func _style_equipment_slots():
	var gold = UIThemeManager.get_color("accent")
	var bronze = UIThemeManager.get_color("border_bronze")
	var dim_label_color = UIThemeManager.get_color("secondary")
	var player = GameManager.get_player()
	var pairs = [
		[weapon_slot, player.equipment.get("weapon") if player else null],
		[armor_slot, player.equipment.get("armor") if player else null],
		[accessory_slot, player.equipment.get("accessory") if player else null],
	]
	for pair in pairs:
		var slot: Control = pair[0]
		var item = pair[1]
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.09, 0.07, 0.6)
		if item:
			# Equipped glow
			style.border_color = gold
			style.set_border_width_all(SLOT_BORDER_WIDTH + 1)
			style.shadow_color = Color(gold.r, gold.g, gold.b, 0.45)
			style.shadow_size = 4
		else:
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


func _is_item_equipped(item) -> bool:
	var player = GameManager.get_player()
	if not player or not item:
		return false
	for slot in player.equipment.keys():
		var equipped_item = player.equipment[slot]
		if typeof(equipped_item) == typeof(item) and equipped_item == item:
			return true
	return false


func _apply_slot_styling(button: Button, item) -> void:
	var bronze = UIThemeManager.get_color("border_bronze")
	var gold = UIThemeManager.get_color("accent")
	var text_color = UIThemeManager.get_color("text_primary")
	var secondary = UIThemeManager.get_color("secondary")
	if item:
		var rarity_color: Color = item.get_rarity_border_color()
		var normal_border = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.85)
		var hover_border = Color(gold.r, gold.g, gold.b, 0.9)
		if _is_item_equipped(item):
			normal_border = gold
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

	var has_any_item := false
	for i in range(player.inventory.size()):
		var item = player.inventory[i]
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(80, 80)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.clip_text = true
		slot_button.expand_icon = true

		if item:
			has_any_item = true
			var tex = ItemLookup.get_item_texture(item)
			if tex:
				slot_button.icon = tex
				if item.stackable and item.quantity > 1:
					slot_button.text = "x%d" % item.quantity
				elif _is_item_equipped(item):
					slot_button.text = "E"
				else:
					slot_button.text = ""
			else:
				slot_button.text = item.name
			slot_button.tooltip_text = (
				item.name + "\n" + item.description + "\n"
				+ _get_item_stats_text(item))
			_apply_slot_styling(slot_button, item)
		else:
			slot_button.text = "\u2014"
			slot_button.disabled = true
			_apply_slot_styling(slot_button, null)

		slot_button.connect(
			"pressed", Callable(self, "_on_slot_pressed").bind(i))
		inventory_grid.add_child(slot_button)

	if not has_any_item:
		# Non-interactive empty-state hint overlaid via tooltip on first empty
		pass


func _on_slot_pressed(slot_index: int):
	if _selected_button and is_instance_valid(_selected_button):
		var player = GameManager.get_player()
		var prev_item = null
		if player and selected_item_index >= 0 and selected_item_index < player.inventory.size():
			prev_item = player.inventory[selected_item_index]
		_apply_slot_styling(_selected_button, prev_item)

	selected_item_index = slot_index
	var player2 = GameManager.get_player()
	if player2 and slot_index < player2.inventory.size():
		selected_item = player2.inventory[slot_index]
	else:
		selected_item = null

	var slots = inventory_grid.get_children()
	if slot_index < slots.size():
		_selected_button = slots[slot_index]
		_apply_selected_styling(_selected_button)

	_update_action_buttons()


func _update_action_buttons():
	var text_color = UIThemeManager.get_color("text_primary")
	var secondary = UIThemeManager.get_color("secondary")
	if selected_item:
		use_button.disabled = not selected_item.is_consumable()
		equip_button.disabled = not selected_item.can_equip()
		drop_button.disabled = false
	else:
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true
	for btn in [use_button, equip_button, drop_button]:
		if btn.disabled:
			btn.modulate = Color(1, 1, 1, 0.45)
			btn.add_theme_color_override("font_color", secondary)
		else:
			btn.modulate = Color.WHITE
			btn.add_theme_color_override("font_color", text_color)


func _get_item_stats_text(item) -> String:
	var stats_text = "Value: " + str(item.value) + " gold"
	var rarity_name := "Common"
	match item.rarity:
		Item.Rarity.UNCOMMON:
			rarity_name = "Uncommon"
		Item.Rarity.RARE:
			rarity_name = "Rare"
		Item.Rarity.EPIC:
			rarity_name = "Epic"
		Item.Rarity.LEGENDARY:
			rarity_name = "Legendary"
		_:
			rarity_name = "Common"
	stats_text += "\nRarity: " + rarity_name
	if item.attack_bonus > 0:
		stats_text += "\nAttack: +" + str(item.attack_bonus)
	if item.defense_bonus > 0:
		stats_text += "\nDefense: +" + str(item.defense_bonus)
	if item.health_bonus > 0:
		stats_text += "\nHealth: +" + str(item.health_bonus)
	if item.is_consumable():
		if item.effect == "restore_mana":
			stats_text += "\nRestore: " + str(item.heal_amount) + " MP"
		else:
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
			var equipped_name = selected_item.name
			var slot = selected_item.get_equip_slot()
			var old_item = player.unequip_item(slot)
			player.equip_item(selected_item, slot)
			player.inventory[selected_item_index] = old_item
			refresh_inventory()
			_flash_equipment_slot(slot)
			UIToast.toast_on(
				self,
				"Equipped: %s" % equipped_name,
				UIToast.Kind.SUCCESS,
				1.5
			)


func _flash_equipment_slot(slot: String) -> void:
	var slot_node = null
	match slot:
		"weapon":
			slot_node = weapon_slot
		"armor":
			slot_node = armor_slot
		"accessory":
			slot_node = accessory_slot
	if not slot_node:
		return
	var gold = UIThemeManager.get_color("accent")
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.08, 0.95)
	style.border_color = gold
	style.set_border_width_all(SLOT_BORDER_WIDTH + 1)
	style.set_corner_radius_all(SLOT_BORDER_RADIUS)
	style.set_content_margin_all(4)
	style.shadow_color = Color(gold.r, gold.g, gold.b, 0.6)
	style.shadow_size = 6
	slot_node.add_theme_stylebox_override("panel", style)
	if UIDialogShell.is_reduced_motion():
		await get_tree().create_timer(0.4).timeout
		_style_equipment_slots()
		return
	var tween = create_tween()
	tween.tween_interval(0.45)
	await tween.finished
	tween.kill()
	_style_equipment_slots()


func _on_drop_pressed():
	if selected_item:
		var player = GameManager.get_player()
		if player:
			player.inventory[selected_item_index] = null
			refresh_inventory()


func _on_close_pressed():
	UIDialogShell.play_close_and_free(self, dialog_panel)


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
			var row_end = mini(i + columns - 1, slots.size() - 1)
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
			slots[mini(0, slots.size() - 1)].get_path())
		equip_button.set(
			"focus_neighbor_top",
			slots[mini(1, slots.size() - 1)].get_path())
		drop_button.set(
			"focus_neighbor_top",
			slots[mini(2, slots.size() - 1)].get_path())

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
