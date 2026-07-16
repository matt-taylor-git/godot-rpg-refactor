extends Control

# ShopDialog - Buy/sell with afford states, stat compare, coin juice

var shop_items = []
## Maps player ItemList row index -> inventory slot index
var _player_sell_indices: Array = []
var _compare_label: Label = null
var _gold_base_scale: Vector2 = Vector2.ONE

@onready var dialog_panel = $DialogPanel
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
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.SLIDE)
	_ensure_compare_label()
	if shop_list:
		shop_list.fixed_icon_size = Vector2(32, 32)
		shop_list.auto_width = false
		shop_list.item_selected.connect(_on_shop_item_selected)
	if player_item_list:
		player_item_list.fixed_icon_size = Vector2(32, 32)
		player_item_list.auto_width = false
	if player_gold_label:
		player_gold_label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
		player_gold_label.add_theme_font_size_override("font_size", 18)
		_gold_base_scale = player_gold_label.scale
	_populate_shop_items()
	_populate_player_inventory()
	_update_player_gold()
	_setup_focus_navigation()


func _ensure_compare_label() -> void:
	if _compare_label and is_instance_valid(_compare_label):
		return
	var vbox = $DialogPanel/MarginContainer/VBoxContainer
	if vbox == null:
		return
	_compare_label = Label.new()
	_compare_label.name = "StatCompare"
	_compare_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compare_label.add_theme_color_override(
		"font_color", UIThemeManager.get_color("secondary"))
	_compare_label.add_theme_font_size_override("font_size", 12)
	_compare_label.text = ""
	# Insert above action buttons
	var actions = vbox.get_node_or_null("ActionButtons")
	if actions:
		var idx = actions.get_index()
		vbox.add_child(_compare_label)
		vbox.move_child(_compare_label, idx)
	else:
		vbox.add_child(_compare_label)


func _setup_focus_navigation():
	shop_list.set("focus_neighbor_right", player_item_list.get_path())
	player_item_list.set("focus_neighbor_left", shop_list.get_path())
	shop_list.set("focus_neighbor_bottom", buy_button.get_path())
	player_item_list.set("focus_neighbor_bottom", sell_button.get_path())
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
		player_gold_label.text = "Your Gold: %d" % player.gold


func _populate_shop_items():
	shop_list.clear()
	shop_items = ItemFactory.get_all_items()
	var player = GameManager.get_player()
	var gold: int = player.gold if player else 0
	var danger = UIThemeManager.get_danger_color()
	var secondary = UIThemeManager.get_secondary_color()
	for item in shop_items:
		var tex = ItemLookup.get_item_texture(item)
		var can_afford = gold >= item.value
		var label = "%s  %dg" % [item.name, item.value]
		if not can_afford:
			label = "%s  %dg ✕" % [item.name, item.value]
		if tex:
			shop_list.add_item(label, tex)
		else:
			shop_list.add_item(label)
		var idx = shop_list.item_count - 1
		if can_afford:
			shop_list.set_item_custom_fg_color(idx, UIThemeManager.get_text_primary_color())
		else:
			shop_list.set_item_custom_fg_color(idx, danger.darkened(0.15))
			shop_list.set_item_custom_bg_color(idx, Color(secondary.r, secondary.g, secondary.b, 0.15))


func _populate_player_inventory():
	player_item_list.clear()
	_player_sell_indices.clear()
	var player = GameManager.get_player()
	if not player:
		return
	for inv_index in range(player.inventory.size()):
		var item = player.inventory[inv_index]
		if item:
			var sell_price = int(item.value / 2)
			var tex = ItemLookup.get_item_texture(item)
			# Compact label so ItemList does not ellipsize prices
			var label = "%s  %dg" % [item.name, sell_price]
			if tex:
				player_item_list.add_item(label, tex)
			else:
				player_item_list.add_item(label)
			_player_sell_indices.append(inv_index)


func _on_shop_item_selected(index: int) -> void:
	_update_stat_compare(index)


func _update_stat_compare(shop_index: int) -> void:
	if _compare_label == null:
		return
	if shop_index < 0 or shop_index >= shop_items.size():
		_compare_label.text = ""
		return
	var item = shop_items[shop_index]
	if not item.can_equip():
		_compare_label.text = ""
		return
	var player = GameManager.get_player()
	if not player:
		_compare_label.text = ""
		return
	var slot = item.get_equip_slot()
	var equipped = player.equipment.get(slot)
	var lines: PackedStringArray = []
	lines.append("Compare vs equipped (%s):" % slot)
	var cur_atk = equipped.attack_bonus if equipped else 0
	var cur_def = equipped.defense_bonus if equipped else 0
	var d_atk = item.attack_bonus - cur_atk
	var d_def = item.defense_bonus - cur_def
	lines.append(
		"ATK %d → %d (%s)" % [cur_atk, item.attack_bonus, _delta_str(d_atk)])
	lines.append(
		"DEF %d → %d (%s)" % [cur_def, item.defense_bonus, _delta_str(d_def)])
	_compare_label.text = "\n".join(lines)
	if d_atk > 0 or d_def > 0:
		_compare_label.add_theme_color_override(
			"font_color", UIThemeManager.get_success_color())
	elif d_atk < 0 or d_def < 0:
		_compare_label.add_theme_color_override(
			"font_color", UIThemeManager.get_danger_color())
	else:
		_compare_label.add_theme_color_override(
			"font_color", UIThemeManager.get_secondary_color())


func _delta_str(delta: int) -> String:
	if delta > 0:
		return "+%d" % delta
	return str(delta)


func _punch_gold_label() -> void:
	if player_gold_label == null:
		return
	if UIDialogShell.is_reduced_motion():
		return
	player_gold_label.pivot_offset = player_gold_label.size / 2.0
	var tween = create_tween()
	tween.tween_property(player_gold_label, "scale", _gold_base_scale * 1.15, 0.12)
	tween.tween_property(player_gold_label, "scale", _gold_base_scale, 0.12)
	tween.finished.connect(func(): tween.kill())
	_spawn_coin_burst()


func _spawn_coin_burst() -> void:
	if UIDialogShell.is_reduced_motion() or player_gold_label == null:
		return
	var particles := CPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2(0, 120)
	particles.color = UIThemeManager.get_color("title_gold")
	particles.position = player_gold_label.global_position + player_gold_label.size / 2.0
	add_child(particles)
	particles.emitting = true
	var cleanup = create_tween()
	cleanup.tween_interval(0.8)
	cleanup.tween_callback(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


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
		# Fresh instance so shop stock is not shared with inventory
		var bought = ItemFactory.create_item(item_to_buy.item_id)
		if player.add_item(bought):
			player.gold -= item_to_buy.value
			_update_and_refresh()
			_punch_gold_label()
			UIToast.toast_on(
				self,
				"Purchased: %s" % bought.name,
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
		var sell_price = int(item_to_sell.value / 2)
		var sold_name = item_to_sell.name
		player.remove_item(inv_index)
		player.gold += sell_price
		_update_and_refresh()
		_punch_gold_label()
		UIToast.toast_on(
			self,
			"Sold: %s (+%d gold)" % [sold_name, sell_price],
			UIToast.Kind.LOOT,
			1.5
		)


func _on_close_pressed():
	UIDialogShell.play_close_and_free(self, dialog_panel)


func _update_and_refresh():
	_update_player_gold()
	_populate_shop_items()
	_populate_player_inventory()
	if _compare_label:
		_compare_label.text = ""
