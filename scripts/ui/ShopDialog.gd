extends Control

# ShopDialog - Updated for new layout and ItemList

var shop_items = []
## Maps player ItemList row index -> inventory slot index
var _player_sell_indices: Array = []

@onready var player_gold_label = $DialogPanel/MarginContainer/VBoxContainer/PlayerGold
@onready var shop_list = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/ShopInventory/VBoxContainer/ShopList")
@onready var player_item_list = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/PlayerInventory/VBoxContainer/PlayerItemList")
@onready var buy_button = $DialogPanel/MarginContainer/VBoxContainer/ActionButtons/BuyButton
@onready var sell_button = $DialogPanel/MarginContainer/VBoxContainer/ActionButtons/SellButton
@onready var close_button = $DialogPanel/MarginContainer/VBoxContainer/ActionButtons/CloseButton

func _ready():
	print("ShopDialog ready")
	if shop_list:
		shop_list.fixed_icon_size = Vector2(32, 32)
	if player_item_list:
		player_item_list.fixed_icon_size = Vector2(32, 32)
	_populate_shop_items()
	_populate_player_inventory()
	_update_player_gold()
	_setup_focus_navigation()

func _setup_focus_navigation():
	# Lists navigate right/left between each other
	shop_list.set("focus_neighbor_right", player_item_list.get_path())
	player_item_list.set("focus_neighbor_left", shop_list.get_path())

	# Lists navigate down to action buttons
	shop_list.set("focus_neighbor_bottom", buy_button.get_path())
	player_item_list.set("focus_neighbor_bottom", sell_button.get_path())

	# Action buttons horizontal chain: Buy <-> Sell <-> Close
	buy_button.set("focus_neighbor_right", sell_button.get_path())
	buy_button.set("focus_neighbor_left", close_button.get_path())
	buy_button.set("focus_neighbor_top", shop_list.get_path())

	sell_button.set("focus_neighbor_left", buy_button.get_path())
	sell_button.set("focus_neighbor_right", close_button.get_path())
	sell_button.set("focus_neighbor_top", player_item_list.get_path())

	close_button.set("focus_neighbor_left", sell_button.get_path())
	close_button.set("focus_neighbor_right", buy_button.get_path())
	close_button.set("focus_neighbor_top", player_item_list.get_path())

	shop_list.grab_focus()

func _update_player_gold():
	var player = GameManager.get_player()
	if player:
		player_gold_label.text = "Your Gold: " + str(player.gold)

func _populate_shop_items():
	shop_list.clear()
	shop_items = ItemFactory.get_all_items()
	for item in shop_items:
		var tex = ItemLookup.get_item_texture(item)
		var label = "%s - %s gold" % [item.name, item.value]
		if tex:
			shop_list.add_item(label, tex)
		else:
			shop_list.add_item(label)

func _populate_player_inventory():
	player_item_list.clear()
	_player_sell_indices.clear()
	var player = GameManager.get_player()
	if not player:
		return

	for inv_index in range(player.inventory.size()):
		var item = player.inventory[inv_index]
		if item:
			var sell_price = item.value / 2
			var tex = ItemLookup.get_item_texture(item)
			var label = "%s - Sell: %s gold" % [item.name, sell_price]
			if tex:
				player_item_list.add_item(label, tex)
			else:
				player_item_list.add_item(label)
			_player_sell_indices.append(inv_index)

func _on_buy_pressed():
	var selected_indices = shop_list.get_selected_items()
	if selected_indices.is_empty():
		return

	var selected_index = selected_indices[0]
	var item_to_buy = shop_items[selected_index]
	var player = GameManager.get_player()
	if not player:
		return

	if player.gold >= item_to_buy.value:
		if player.add_item(item_to_buy):
			player.gold -= item_to_buy.value
			_update_and_refresh()
			UIToast.toast_on(
				self,
				"Purchased: %s" % item_to_buy.name,
				UIToast.Kind.SUCCESS,
				1.5
			)
		else:
			UIToast.toast_on(self, "Inventory is full!", UIToast.Kind.DANGER, 1.5)
	else:
		UIToast.toast_on(self, "Not enough gold!", UIToast.Kind.DANGER, 1.5)

func _on_sell_pressed():
	var selected_indices = player_item_list.get_selected_items()
	if selected_indices.is_empty():
		return

	var list_index = selected_indices[0]
	if list_index < 0 or list_index >= _player_sell_indices.size():
		return
	var inv_index = _player_sell_indices[list_index]
	var player = GameManager.get_player()
	if not player:
		return

	var item_to_sell = player.inventory[inv_index]
	if item_to_sell:
		var sell_price = item_to_sell.value / 2
		var sold_name = item_to_sell.name
		player.remove_item(inv_index)
		player.gold += sell_price
		_update_and_refresh()
		UIToast.toast_on(
			self,
			"Sold: %s (+%d gold)" % [sold_name, sell_price],
			UIToast.Kind.LOOT,
			1.5
		)

func _on_close_pressed():
	queue_free()

func _update_and_refresh():
	_update_player_gold()
	_populate_shop_items()
	_populate_player_inventory()
