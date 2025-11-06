extends Control

# ShopDialog - Shop interface for buying and selling items

@onready var player_gold_label = $DialogPanel/VBoxContainer/PlayerGold
@onready var shop_list = $DialogPanel/VBoxContainer/Content/ShopItems/ShopList
@onready var inventory_list = $DialogPanel/VBoxContainer/Content/PlayerItems/InventoryList

# Shop inventory - items available for purchase
var shop_items = [
	{"name": "Health Potion", "price": 20, "item_type": "consumable"},
	{"name": "Iron Sword", "price": 50, "item_type": "weapon"},
	{"name": "Wooden Shield", "price": 30, "item_type": "armor"},
	{"name": "Leather Boots", "price": 25, "item_type": "armor"},
	{"name": "Magic Ring", "price": 100, "item_type": "accessory"}
]

func _ready():
	print("ShopDialog ready")
	_populate_shop_items()
	_populate_player_inventory()
	_update_player_gold()

func _update_player_gold():
	var player = GameManager.get_player()
	if player:
		player_gold_label.text = "Your Gold: " + str(player.gold)

func _populate_shop_items():
	# Clear existing items
	for child in shop_list.get_children():
		child.queue_free()

	# Add shop items
	for item_data in shop_items:
		var item_button = Button.new()
		item_button.text = item_data.name + " - " + str(item_data.price) + " gold"
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Connect to purchase
		item_button.connect("pressed", Callable(self, "_on_shop_item_pressed").bind(item_data))

		shop_list.add_child(item_button)

func _populate_player_inventory():
	# Clear existing items
	for child in inventory_list.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	# Add player inventory items
	for i in range(player.inventory.size()):
		var item = player.inventory[i]
		if item:
			var item_button = Button.new()
			var sell_price = item.value / 2  # Sell for half value
			item_button.text = item.name
			if item.quantity > 1:
				item_button.text += " (" + str(item.quantity) + ")"
			item_button.text += " - Sell: " + str(sell_price) + " gold"
			item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			# Connect to sell
			item_button.connect("pressed", Callable(self, "_on_inventory_item_pressed").bind(i))

			inventory_list.add_child(item_button)

	# If no items, show message
	if inventory_list.get_child_count() == 0:
		var no_items_label = Label.new()
		no_items_label.text = "No items to sell"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_list.add_child(no_items_label)

func _on_shop_item_pressed(item_data: Dictionary):
	var player = GameManager.get_player()
	if not player:
		return

	# Check if player has enough gold
	if player.gold >= item_data.price:
		# Create the item
		var item = ItemFactory.create_item(item_data.item_type)
		if item_data.has("name"):
			item.name = item_data.name

		# Try to add to inventory
		if player.add_item(item):
			player.gold -= item_data.price
			print("Purchased: " + item.name + " for " + str(item_data.price) + " gold")
			_update_player_gold()
			_populate_player_inventory()  # Refresh inventory display
		else:
			print("Inventory full! Cannot purchase item.")
	else:
		print("Not enough gold! Need " + str(item_data.price) + " gold.")

func _on_inventory_item_pressed(slot_index: int):
	var player = GameManager.get_player()
	if not player:
		return

	var item = player.inventory[slot_index]
	if item:
		var sell_price = item.value / 2

		# Remove item from inventory
		player.remove_item(slot_index)

		# Add gold
		player.gold += sell_price

		print("Sold: " + item.name + " for " + str(sell_price) + " gold")
		_update_player_gold()
		_populate_player_inventory()  # Refresh inventory display

func _on_close_pressed():
	queue_free()

# Method to set custom shop inventory (for different shop types)
func set_shop_inventory(items: Array):
	shop_items = items
	if is_inside_tree():
		_populate_shop_items()
