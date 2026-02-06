extends Control

# InventoryDialog - New layout and theme

var selected_item_index = -1
var selected_item = null

@onready var attack_value = get_node(
	"DialogPanel/MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/AttackValue")
@onready var defense_value = get_node(
	"DialogPanel/MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DefenseValue")
@onready var dexterity_value = get_node(
	"DialogPanel/MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DexterityValue")

@onready var weapon_slot = $DialogPanel/MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/WeaponSlot
@onready var armor_slot = $DialogPanel/MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/ArmorSlot
@onready var accessory_slot = $DialogPanel/MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/AccessorySlot

@onready var inventory_grid = $DialogPanel/MainContainer/RightPanel/InventoryGrid
@onready var use_button = $DialogPanel/MainContainer/RightPanel/ActionButtons/UseButton
@onready var equip_button = $DialogPanel/MainContainer/RightPanel/ActionButtons/EquipButton
@onready var drop_button = $DialogPanel/MainContainer/RightPanel/ActionButtons/DropButton
@onready var close_button = $DialogPanel/MainContainer/RightPanel/CloseButton

func _ready():
	print("InventoryDialog ready")
	_update_character_stats()
	_update_equipment_display()
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
	# This is a placeholder. In a real implementation, you'd set the texture of an icon inside the slot.
	if item:
		slot_node.get_node("Label").text = item.name
	else:
		slot_node.get_node("Label").text = "[Empty]"


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
		slot_button.theme_type_variation = "ItemSlot"
		slot_button.focus_mode = Control.FOCUS_ALL

		if item:
			slot_button.text = item.name
			slot_button.tooltip_text = item.description + "\n" + _get_item_stats_text(item)
		else:
			slot_button.text = "[Empty]"
			slot_button.disabled = true

		slot_button.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))
		inventory_grid.add_child(slot_button)

func _on_slot_pressed(slot_index: int):
	selected_item_index = slot_index
	var player = GameManager.get_player()
	if player and slot_index < player.inventory.size():
		selected_item = player.inventory[slot_index]
	else:
		selected_item = null

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
			var old_item = player.unequip_item(selected_item.get_equip_slot())
			player.equip_item(selected_item, selected_item.get_equip_slot())
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
	# Setup grid focus navigation for inventory slots
	var slots = inventory_grid.get_children()
	var columns = inventory_grid.columns if inventory_grid.columns > 0 else 5

	for i in range(slots.size()):
		var col = i % columns
		var row = i / columns
		# Right neighbor
		if col < columns - 1 and i + 1 < slots.size():
			slots[i].set("focus_neighbor_right", slots[i + 1].get_path())
		elif col == columns - 1 and i - col >= 0:
			slots[i].set("focus_neighbor_right", slots[i - col].get_path())
		# Left neighbor
		if col > 0:
			slots[i].set("focus_neighbor_left", slots[i - 1].get_path())
		else:
			var row_end = min(i + columns - 1, slots.size() - 1)
			slots[i].set("focus_neighbor_left", slots[row_end].get_path())
		# Bottom neighbor
		if i + columns < slots.size():
			slots[i].set("focus_neighbor_bottom", slots[i + columns].get_path())
		else:
			slots[i].set("focus_neighbor_bottom", use_button.get_path())
		# Top neighbor
		if i - columns >= 0:
			slots[i].set("focus_neighbor_top", slots[i - columns].get_path())

	# Action buttons horizontal chain: Use <-> Equip <-> Drop
	use_button.set("focus_neighbor_right", equip_button.get_path())
	use_button.set("focus_neighbor_left", drop_button.get_path())
	use_button.set("focus_neighbor_bottom", close_button.get_path())

	equip_button.set("focus_neighbor_left", use_button.get_path())
	equip_button.set("focus_neighbor_right", drop_button.get_path())
	equip_button.set("focus_neighbor_bottom", close_button.get_path())

	drop_button.set("focus_neighbor_left", equip_button.get_path())
	drop_button.set("focus_neighbor_right", use_button.get_path())
	drop_button.set("focus_neighbor_bottom", close_button.get_path())

	# Close button wraps back to action buttons
	close_button.set("focus_neighbor_top", use_button.get_path())

	# Connect action buttons back up to grid
	if slots.size() > 0:
		use_button.set("focus_neighbor_top", slots[min(0, slots.size() - 1)].get_path())
		equip_button.set("focus_neighbor_top", slots[min(1, slots.size() - 1)].get_path())
		drop_button.set("focus_neighbor_top", slots[min(2, slots.size() - 1)].get_path())

	# Default focus: first non-disabled slot, or close button
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
	_update_character_stats()
	_update_equipment_display()
	_populate_inventory_grid()
	_update_action_buttons()
	_setup_focus_navigation()
