extends PanelContainer

# ShopDialog - Updated for new layout and ItemList

var shop_items = []

@onready var player_gold_label = $VBoxContainer/PlayerGold
@onready var shop_list = $VBoxContainer/MainContent/ShopInventory/VBoxContainer/ShopList
@onready var player_item_list = $VBoxContainer/MainContent/PlayerInventory/VBoxContainer/PlayerItemList
@onready var buy_button = $VBoxContainer/ActionButtons/BuyButton
@onready var sell_button = $VBoxContainer/ActionButtons/SellButton
@onready var close_button = $VBoxContainer/ActionButtons/CloseButton

func _ready():
    print("ShopDialog ready")
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
    shop_items = ItemFactory.get_all_items() # Using ItemFactory
    for item in shop_items:
        shop_list.add_item(item.name + " - " + str(item.value) + " gold")

func _populate_player_inventory():
    player_item_list.clear()
    var player = GameManager.get_player()
    if not player:
        return

    for item in player.inventory:
        if item:
            var sell_price = item.value / 2
            player_item_list.add_item(item.name + " - Sell: " + str(sell_price) + " gold")

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
        else:
            print("Inventory is full!")
    else:
        print("Not enough gold!")

func _on_sell_pressed():
    var selected_indices = player_item_list.get_selected_items()
    if selected_indices.is_empty():
        return

    var selected_index = selected_indices[0]
    var player = GameManager.get_player()
    if not player:
        return

    var item_to_sell = player.inventory[selected_index]
    if item_to_sell:
        var sell_price = item_to_sell.value / 2
        player.remove_item(selected_index)
        player.gold += sell_price
        _update_and_refresh()

func _on_close_pressed():
    queue_free()

func _update_and_refresh():
    _update_player_gold()
    _populate_shop_items()
    _populate_player_inventory()