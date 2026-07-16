class_name ItemLookup
extends RefCounted

# ItemLookup - Central texture resolution for inventory item icons

const DEFAULT_ITEM := "res://assets/items/unknown.png"

const ITEM_TEXTURES := {
	"sword": "res://assets/items/sword.png",
	"shield": "res://assets/items/shield.png",
	"health_potion": "res://assets/items/health_potion.png",
	"mana_potion": "res://assets/items/mana_potion.png",
	"gold_coin": "res://assets/items/gold_coin.png",
	"unknown": DEFAULT_ITEM,
}


static func get_item_texture(item) -> Texture2D:
	if item == null:
		return get_texture_by_id("unknown")
	var id := ""
	if "item_id" in item:
		id = str(item.item_id)
	return get_texture_by_id(id)


static func get_texture_by_id(item_id: String) -> Texture2D:
	var key := item_id.strip_edges().to_lower()
	if key.is_empty():
		key = "unknown"
	var path: String = ITEM_TEXTURES.get(key, DEFAULT_ITEM)
	return _load_texture(path, DEFAULT_ITEM)


static func _load_texture(path: String, fallback: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	if path != fallback and ResourceLoader.exists(fallback):
		var fb = load(fallback)
		if fb is Texture2D:
			return fb
	return null
