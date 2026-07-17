class_name PortraitLookup
extends RefCounted

# PortraitLookup - Central texture resolution for classes, monsters, NPCs

const DEFAULT_PLAYER := "res://assets/characters/hero.png"
# Prefer transparent cutouts (goblin_t) over RGB plates with light backgrounds
const DEFAULT_MONSTER := "res://assets/goblin_t.png"
const DEFAULT_NPC := "res://assets/warrior.png"

# Full-body class art for hub (and shared player display)
const CLASS_TEXTURES := {
	"Warrior": "res://assets/characters/warrior.png",
	"Mage": "res://assets/characters/mage.png",
	"Rogue": "res://assets/characters/rogue.png",
	"Hero": "res://assets/characters/hero.png",
}

const MONSTER_TEXTURES := {
	"goblin": "res://assets/goblin_t.png",
	"orc": "res://assets/orc.png",
	"skeleton": "res://assets/skeleton.png",
	"slime": "res://assets/slime.png",
	"spider": "res://assets/spider.png",
	"wolf": "res://assets/wolf.png",
	"golem": "res://assets/golem.png",
	"bandit": "res://assets/bandit.png",
	"bat": "res://assets/bat.png",
	"troll": "res://assets/troll.png",
	"dragon": "res://assets/dragon.png",
	"boss": "res://assets/boss.png",
	"final boss": "res://assets/final_boss.png",
	"dark overlord": "res://assets/final_boss.png",
}

const NPC_TEXTURES := {
	"quest_giver": "res://assets/warrior.png",
	"village_elder": "res://assets/mage.png",
	"merchant": "res://assets/rogue.png",
	"knight_commander": "res://assets/warrior.png",
}


static func get_class_texture(character_class: String) -> Texture2D:
	var path: String = CLASS_TEXTURES.get(character_class, DEFAULT_PLAYER)
	return _load_texture(path, DEFAULT_PLAYER)


static func get_monster_texture(monster_name: String) -> Texture2D:
	var key := monster_name.to_lower()
	var path: String = MONSTER_TEXTURES.get(key, DEFAULT_MONSTER)
	return _load_texture(path, DEFAULT_MONSTER)


static func get_npc_texture(npc_id: String) -> Texture2D:
	var path: String = NPC_TEXTURES.get(npc_id, DEFAULT_NPC)
	return _load_texture(path, DEFAULT_NPC)


static func get_player_texture(player) -> Texture2D:
	if player == null:
		return _load_texture(DEFAULT_PLAYER, DEFAULT_PLAYER)
	return get_class_texture(str(player.character_class))


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
