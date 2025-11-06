extends Control

# InventoryDialog - Grid-based inventory management interface

@onready var inventory_grid = $DialogPanel/VBoxContainer/Content/InventoryGrid
@onready var item_sprite = $DialogPanel/VBoxContainer/Content/ItemInfo/ItemSprite
@onready var item_name_label = $DialogPanel/VBoxContainer/Content/ItemInfo/ItemName
@onready var item_description = $DialogPanel/VBoxContainer/Content/ItemInfo/ItemDescription
@onready var item_stats = $DialogPanel/VBoxContainer/Content/ItemInfo/ItemStats
@onready var use_button = $DialogPanel/VBoxContainer/Content/ItemInfo/ActionButtons/UseButton
@onready var equip_button = $DialogPanel/VBoxContainer/Content/ItemInfo/ActionButtons/EquipButton
@onready var drop_button = $DialogPanel/VBoxContainer/Content/ItemInfo/ActionButtons/DropButton

var selected_item_index = -1
var selected_item = null

func _ready():
	print("InventoryDialog ready")
	_populate_inventory_grid()
	_update_selected_item_display()

func _populate_inventory_grid():
	# Clear existing grid
	for child in inventory_grid.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	# Create inventory slots
	for i in range(player.inventory.size()):
		var item = player.inventory[i]

		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(60, 60)
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if item:
			slot_button.text = item.name
			if item.quantity > 1:
				slot_button.text += " (" + str(item.quantity) + ")"
		else:
			slot_button.text = "[Empty]"
			slot_button.disabled = true

		# Connect to slot selection
		slot_button.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))

		inventory_grid.add_child(slot_button)

func _on_slot_pressed(slot_index: int):
	selected_item_index = slot_index
	var player = GameManager.get_player()
	if player and slot_index < player.inventory.size():
		selected_item = player.inventory[slot_index]
	else:
		selected_item = null

	_update_selected_item_display()

func _update_selected_item_display():
	if selected_item:
		item_name_label.text = selected_item.name
		item_description.text = selected_item.description

		var stats_text = "Value: " + str(selected_item.value) + " gold"
		if selected_item.attack_bonus > 0:
			stats_text += "\nAttack: +" + str(selected_item.attack_bonus)
		if selected_item.defense_bonus > 0:
			stats_text += "\nDefense: +" + str(selected_item.defense_bonus)
		if selected_item.health_bonus > 0:
			stats_text += "\nHealth: +" + str(selected_item.health_bonus)
		if selected_item.is_consumable():
			stats_text += "\nHeal: " + str(selected_item.heal_amount) + " HP"

		item_stats.text = stats_text

		# Set sprite (placeholder - would need item sprites)
		# item_sprite.texture = selected_item.icon_texture

		# Enable appropriate buttons
		use_button.disabled = not selected_item.is_consumable()
		equip_button.disabled = not selected_item.can_equip()
		drop_button.disabled = false
	else:
		item_name_label.text = "No item selected"
		item_description.text = "Select an item to view details"
		item_stats.text = "Stats:"
		# item_sprite.texture = null

		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true

func _on_use_pressed():
	if selected_item and selected_item.is_consumable():
		var player = GameManager.get_player()
		if player:
			if selected_item.use(player):
				print("Used item: " + selected_item.name)
				if selected_item.quantity <= 0:
					# Remove item if quantity is 0
					player.inventory[selected_item_index] = null
				_populate_inventory_grid()
				_update_selected_item_display()
			else:
				print("Failed to use item")

func _on_equip_pressed():
	if selected_item and selected_item.can_equip():
		var player = GameManager.get_player()
		if player:
			var equip_slot = selected_item.get_equip_slot()
			if player.equip_item(selected_item, equip_slot):
				print("Equipped item: " + selected_item.name)
				player.inventory[selected_item_index] = null
				_populate_inventory_grid()
				_update_selected_item_display()
			else:
				print("Failed to equip item")

func _on_drop_pressed():
	if selected_item:
		var player = GameManager.get_player()
		if player:
			player.inventory[selected_item_index] = null
			print("Dropped item: " + selected_item.name)
			_populate_inventory_grid()
			_update_selected_item_display()

func _on_close_pressed():
	queue_free()

# Helper method to refresh inventory display
func refresh_inventory():
	_populate_inventory_grid()
	_update_selected_item_display()
