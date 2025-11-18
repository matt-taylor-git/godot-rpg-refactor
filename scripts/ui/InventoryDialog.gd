extends Control

# InventoryDialog - New layout and theme

@onready var attack_value = $MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/AttackValue
@onready var defense_value = $MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DefenseValue
@onready var dexterity_value = $MainContainer/LeftPanel/CharacterPanel/HBoxContainer/VBoxContainer/StatsGrid/DexterityValue

@onready var weapon_slot = $MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/WeaponSlot
@onready var armor_slot = $MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/ArmorSlot
@onready var accessory_slot = $MainContainer/LeftPanel/EquipmentPanel/VBoxContainer/AccessorySlot

@onready var inventory_grid = $MainContainer/RightPanel/InventoryGrid
@onready var use_button = $MainContainer/RightPanel/ActionButtons/UseButton
@onready var equip_button = $MainContainer/RightPanel/ActionButtons/EquipButton
@onready var drop_button = $MainContainer/RightPanel/ActionButtons/DropButton

var selected_item_index = -1
var selected_item = null

func _ready():
    print("InventoryDialog ready")
    _update_character_stats()
    _update_equipment_display()
    _populate_inventory_grid()
    _update_action_buttons()

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

func refresh_inventory():
    selected_item = null
    selected_item_index = -1
    _update_character_stats()
    _update_equipment_display()
    _populate_inventory_grid()
    _update_action_buttons()