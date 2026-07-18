class_name ExplorationEventFactory
extends Node

# ExplorationEventFactory - Generates narrative exploration events by area
# Follows factory pattern (MonsterFactory, ItemFactory, SkillFactory)

# Event weights per area: [combat, discovery, choice, flavor, quest]
const AREA_WEIGHTS = {
	"town": [0, 0, 0, 100, 0],
	"forest": [35, 25, 20, 15, 5],
	"mountain": [40, 20, 20, 15, 5],
	"cave": [45, 25, 15, 10, 5],
	"peak": [50, 20, 15, 10, 5],
}

const BASE_COMBAT_CHANCE := {
	"town": 0.0,
	"forest": 30.0,
	"mountain": 35.0,
	"cave": 40.0,
	"peak": 45.0,
}

const AREA_LEVEL_BANDS := {
	"forest": Vector2i(1, 2),
	"mountain": Vector2i(3, 4),
	"cave": Vector2i(5, 7),
	"peak": Vector2i(8, 10),
}

const LOW_DANGER_MONSTER_WEIGHTS := [60, 30, 10]
const MID_DANGER_MONSTER_WEIGHTS := [35, 45, 20]
const HIGH_DANGER_MONSTER_WEIGHTS := [20, 40, 40]

const EVENT_TYPES = ["combat", "discovery", "choice", "flavor", "quest"]

# -- Danger flavor text --
const DANGER_FLAVORS = [
	"The air is calm and still.",
	"You sense movement in the shadows.",
	"The darkness seems to watch you.",
	"Every sound sets your nerves on edge.",
	"Death stalks your every step.",
]

# -- Atomic combat encounters per area --
# Keep the displayed identity and combat monster type in the same record so they
# cannot drift apart when an event is generated.
const FOREST_COMBAT = [
	{
		"monster_type": "goblin",
		"title": "A Goblin Ambush!",
		"narrative": "Branches snap. A snarling goblin lunges!",
	},
	{
		"monster_type": "slime",
		"title": "Slime from the Roots!",
		"narrative": "The ground squelches. A slime oozes from the roots.",
	},
	{
		"monster_type": "wolf",
		"title": "Wolf on the Hunt!",
		"narrative": "Gleaming eyes appear between the trees. A wolf springs at you.",
	},
]

const MOUNTAIN_COMBAT = [
	{
		"monster_type": "goblin",
		"title": "Goblin Rockslide Ambush!",
		"narrative": "Stones tumble down -- a goblin above you is throwing them.",
	},
	{
		"monster_type": "orc",
		"title": "Orc Raider!",
		"narrative": "A hulking orc blocks the path, war-axe raised.",
	},
	{
		"monster_type": "skeleton",
		"title": "Skeleton Patrol!",
		"narrative": "Bones rattle in the fog. An armed skeleton advances.",
	},
]

const CAVE_COMBAT = [
	{
		"monster_type": "skeleton",
		"title": "Skeleton Guardian!",
		"narrative": "An ancient skeleton rises from a sarcophagus, sword in hand.",
	},
	{
		"monster_type": "spider",
		"title": "Spider's Lair!",
		"narrative": "Webs cling to your face. A giant spider skitters above.",
	},
	{
		"monster_type": "bat",
		"title": "Bat in the Dark!",
		"narrative": "A shriek echoes. A giant bat dives through the tunnel.",
	},
]

const PEAK_COMBAT = [
	{
		"monster_type": "orc",
		"title": "Orc Warlord!",
		"narrative": "A massive orc stands at the ridge, war-axe raised.",
	},
	{
		"monster_type": "troll",
		"title": "Troll Berserker!",
		"narrative": "The ground shakes. A troll charges down, roaring.",
	},
	{
		"monster_type": "dragon",
		"title": "Dragon's Territory!",
		"narrative": "A shadow blots out the sun. Dragon scales glint like obsidian.",
	},
]

const FOREST_DISCOVERY = [
	{
		"title": "Hidden Cache",
		"narrative": "[color=#d9b359]Hidden Cache[/color]\n" \
			+ "Beneath a moss-covered log, a forgotten pack.",
		"rewards": {"gold": 15}
	},
	{
		"title": "Healing Spring",
		"narrative": "[color=#d9b359]Healing Spring[/color]\n" \
			+ "Clear water bubbles from ancient stones.",
		"rewards": {"heal_percent": 30}
	},
	{
		"title": "Abandoned Camp",
		"narrative": "[color=#d9b359]Abandoned Camp[/color]\n" \
			+ "A cold campfire, a torn bedroll, a coin pouch.",
		"rewards": {"gold": 25}
	},
	{
		"title": "Herbalist's Stash",
		"narrative": "[color=#d9b359]Herbalist's Stash[/color]\n" \
			+ "Glowing mushrooms surround a hollow tree.",
		"rewards": {"item": "health_potion"}
	},
	{
		"title": "Ancient Marker",
		"narrative": "[color=#d9b359]Ancient Marker[/color]\n" \
			+ "A standing stone hums with faint energy.",
		"rewards": {"exp": 20}
	},
]

const MOUNTAIN_DISCOVERY = [
	{
		"title": "Miner's Vein",
		"narrative": "[color=#d9b359]Miner's Vein[/color]\n" \
			+ "Gold flecks glint in the exposed rock face.",
		"rewards": {"gold": 30}
	},
	{
		"title": "Eagle's Nest",
		"narrative": "[color=#d9b359]Eagle's Nest[/color]\n" \
			+ "Among feathers, something metallic catches your eye.",
		"rewards": {"gold": 20}
	},
	{
		"title": "Sheltered Alcove",
		"narrative": "[color=#d9b359]Sheltered Alcove[/color]\n" \
			+ "A natural shelter from the wind. You rest briefly.",
		"rewards": {"heal_percent": 20}
	},
	{
		"title": "Fallen Adventurer",
		"narrative": "[color=#d9b359]Fallen Adventurer[/color]\n" \
			+ "A skeleton clutches a leather pouch.",
		"rewards": {"gold": 35, "exp": 10}
	},
	{
		"title": "Mountain Shrine",
		"narrative": "[color=#d9b359]Mountain Shrine[/color]\n" \
			+ "A weathered shrine. Prayer fills you with resolve.",
		"rewards": {"exp": 25}
	},
]

const CAVE_DISCOVERY = [
	{
		"title": "Crystal Formation",
		"narrative": "[color=#d9b359]Crystal Formation[/color]\n" \
			+ "Luminescent crystals line the walls.",
		"rewards": {"gold": 40}
	},
	{
		"title": "Underground Pool",
		"narrative": "[color=#d9b359]Underground Pool[/color]\n" \
			+ "Still water reflects your torchlight.",
		"rewards": {"heal_percent": 25}
	},
	{
		"title": "Treasure Chest",
		"narrative": "[color=#d9b359]Treasure Chest[/color]\n" \
			+ "A rusted chest. The lock crumbles at your touch.",
		"rewards": {"gold": 50, "item": "health_potion"}
	},
	{
		"title": "Ancient Inscription",
		"narrative": "[color=#d9b359]Ancient Inscription[/color]\n" \
			+ "Runes in the stone pulse with fading power.",
		"rewards": {"exp": 35}
	},
	{
		"title": "Alchemical Deposit",
		"narrative": "[color=#d9b359]Alchemical Deposit[/color]\n" \
			+ "Bat guano -- disgusting, but alchemists pay well.",
		"rewards": {"gold": 20}
	},
]

const PEAK_DISCOVERY = [
	{
		"title": "Summit Cache",
		"narrative": "[color=#d9b359]Summit Cache[/color]\n" \
			+ "A climber's cache sealed against the elements.",
		"rewards": {"gold": 45, "item": "health_potion"}
	},
	{
		"title": "Wind-Carved Runes",
		"narrative": "[color=#d9b359]Wind-Carved Runes[/color]\n" \
			+ "Ancient symbols etched by centuries of wind.",
		"rewards": {"exp": 40}
	},
	{
		"title": "Dragon Scale",
		"narrative": "[color=#d9b359]Dragon Scale[/color]\n" \
			+ "A massive scale shed from some colossal beast.",
		"rewards": {"gold": 60}
	},
	{
		"title": "Skyward Spring",
		"narrative": "[color=#d9b359]Skyward Spring[/color]\n" \
			+ "Water flows upward here, defying nature.",
		"rewards": {"heal_percent": 35}
	},
	{
		"title": "Hermit's Offering",
		"narrative": "[color=#d9b359]Hermit's Offering[/color]\n" \
			+ "A small cairn. 'For the next brave soul.'",
		"rewards": {"gold": 30, "exp": 20}
	},
]

const FOREST_CHOICE = [
	{
		"title": "Fork in the Path",
		"narrative": "[color=#d9b359]Fork in the Path[/color]\n" \
			+ "The trail splits. Left: wildflowers. Right: smoke.",
		"choices": [
			{
				"label": "Take the left path",
				"id": "left",
				"result_narrative": "Flowers conceal a hidden " \
					+ "clearing with a small offering shrine.",
				"rewards": {"heal_percent": 15},
			},
			{
				"label": "Take the right path",
				"id": "right",
				"result_narrative": "A burned-out bandit camp. " \
					+ "Among the ashes, a coin pouch.",
				"rewards": {"gold": 30},
			},
		]
	},
	{
		"title": "Wounded Traveler",
		"narrative": "[color=#d9b359]Wounded Traveler[/color]\n" \
			+ "A figure limps along, clutching a bloodied arm.",
		"choices": [
			{
				"label": "Help them",
				"id": "help",
				"result_narrative": "'Thank you, stranger.' " \
					+ "They press a potion into your hand.",
				"rewards": {"item": "health_potion"},
			},
			{
				"label": "Search them",
				"id": "search",
				"result_narrative": "More gold than expected. " \
					+ "Guilt gnaws at you.",
				"rewards": {"gold": 40},
			},
			{
				"label": "Walk past",
				"id": "ignore",
				"result_narrative": "You press on. " \
					+ "The forest feels colder.",
				"rewards": {},
			},
		]
	},
	{
		"title": "Mysterious Chest",
		"narrative": "[color=#d9b359]Mysterious Chest[/color]\n" \
			+ "A wooden chest in a clearing. Could be a trap.",
		"choices": [
			{
				"label": "Open carefully",
				"id": "careful",
				"result_narrative": "No trap -- just coins. Lucky.",
				"rewards": {"gold": 20},
			},
			{
				"label": "Smash it open",
				"id": "smash",
				"result_narrative": "The chest splinters. Dust " \
					+ "and gold.",
				"rewards": {"gold": 25},
			},
		]
	},
]

const MOUNTAIN_CHOICE = [
	{
		"title": "Narrow Ledge",
		"narrative": "[color=#d9b359]Narrow Ledge[/color]\n" \
			+ "The path crumbles. A ledge or a longer route.",
		"choices": [
			{
				"label": "Risk the ledge",
				"id": "ledge",
				"result_narrative": "Heart pounding, you edge " \
					+ "across. A glinting stone rewards courage.",
				"rewards": {"gold": 35, "exp": 15},
			},
			{
				"label": "Take the safe route",
				"id": "safe",
				"result_narrative": "The longer path reveals " \
					+ "a sheltered campsite.",
				"rewards": {"heal_percent": 20},
			},
		]
	},
	{
		"title": "Orc Toll",
		"narrative": "[color=#d9b359]Orc Toll[/color]\n" \
			+ "An orc at a barricade. 'Pay 20 gold or turn back.'",
		"choices": [
			{
				"label": "Pay the toll",
				"id": "pay",
				"result_narrative": "The orc moves aside. " \
					+ "Beyond: a shortcut and a hidden cache.",
				"rewards": {"gold": -20, "exp": 25},
			},
			{
				"label": "Refuse and fight",
				"id": "fight",
				"result_narrative": "The orc snarls and attacks!",
				"rewards": {"combat": "orc"},
			},
		]
	},
]

const CAVE_CHOICE = [
	{
		"title": "Branching Tunnels",
		"narrative": "[color=#d9b359]Branching Tunnels[/color]\n" \
			+ "Three tunnels: one glows, one drips, one is silent.",
		"choices": [
			{
				"label": "Follow the glow",
				"id": "glow",
				"result_narrative": "Luminescent fungi " \
					+ "lead to a crystal-lined chamber.",
				"rewards": {"gold": 35},
			},
			{
				"label": "Follow the dripping",
				"id": "drip",
				"result_narrative": "An underground spring. " \
					+ "Clean water revitalizes you.",
				"rewards": {"heal_percent": 25},
			},
			{
				"label": "Enter the silence",
				"id": "silent",
				"result_narrative": "The silence breaks " \
					+ "with a screech. Something attacks!",
				"rewards": {"combat": "skeleton"},
			},
		]
	},
	{
		"title": "Ancient Door",
		"narrative": "[color=#d9b359]Ancient Door[/color]\n" \
			+ "A stone door with two keyholes. One lock is rusted.",
		"choices": [
			{
				"label": "Force the lock",
				"id": "force",
				"result_narrative": "The door grinds open, " \
					+ "revealing a small treasury.",
				"rewards": {"gold": 50},
			},
			{
				"label": "Leave it alone",
				"id": "leave",
				"result_narrative": "Better safe than sorry. " \
					+ "You continue deeper.",
				"rewards": {"exp": 10},
			},
		]
	},
]

const PEAK_CHOICE = [
	{
		"title": "Dragon's Hoard",
		"narrative": "[color=#d9b359]Dragon's Hoard[/color]\n" \
			+ "A sleeping dragon curls around a pile of gold.",
		"choices": [
			{
				"label": "Steal from the hoard",
				"id": "steal",
				"result_narrative": "Trembling, you pocket " \
					+ "coins. The dragon stirs but doesn't wake.",
				"rewards": {"gold": 75},
			},
			{
				"label": "Leave quietly",
				"id": "leave",
				"result_narrative": "Wisdom is its own reward. " \
					+ "You back away slowly.",
				"rewards": {"exp": 30},
			},
		]
	},
	{
		"title": "Storm Shrine",
		"narrative": "[color=#d9b359]Storm Shrine[/color]\n" \
			+ "Lightning strikes a stone altar. An offering bowl.",
		"choices": [
			{
				"label": "Make an offering (20 gold)",
				"id": "offer",
				"result_narrative": "The lightning subsides. " \
					+ "Warmth floods through you.",
				"rewards": {"gold": -20, "heal_percent": 50},
			},
			{
				"label": "Pray without offering",
				"id": "pray",
				"result_narrative": "Thunder rumbles, but " \
					+ "you feel a spark of insight.",
				"rewards": {"exp": 20},
			},
		]
	},
]

const TOWN_FLAVOR = [
	"[color=#948d84]Cobblestones warm underfoot. " \
		+ "Merchants call out their wares.[/color]",
	"[color=#948d84]A bard plays near the fountain. " \
		+ "Children chase each other.[/color]",
	"[color=#948d84]Fresh bread wafts from the bakery. " \
		+ "Your stomach growls.[/color]",
	"[color=#948d84]An old soldier polishes a worn blade. " \
		+ "He nods as you pass.[/color]",
	"[color=#948d84]The notice board creaks. " \
		+ "New postings flutter in the breeze.[/color]",
	"[color=#948d84]A blacksmith's hammer rings out " \
		+ "a steady rhythm from the forge.[/color]",
	"[color=#948d84]Two merchants argue about dragon scales. " \
		+ "Neither has ever seen one.[/color]",
	"[color=#948d84]A cat watches you from a windowsill, " \
		+ "eyes glinting like copper coins.[/color]",
]

const FOREST_FLAVOR = [
	"[color=#948d84]Sunlight filters through the canopy " \
		+ "in golden shafts.[/color]",
	"[color=#948d84]A deer watches from a thicket, " \
		+ "then bounds into shadow.[/color]",
	"[color=#948d84]Old trees creak and groan. " \
		+ "This forest was ancient long ago.[/color]",
	"[color=#948d84]Fireflies drift between the ferns. " \
		+ "Their light pulses slowly.[/color]",
	"[color=#948d84]A stream gurgles over smooth stones. " \
		+ "Ice cold and clear.[/color]",
	"[color=#948d84]Claw marks on a tree trunk. " \
		+ "Deep. Recent. Something large.[/color]",
	"[color=#948d84]A broken arrow juts from a stump. " \
		+ "Whoever shot it was running.[/color]",
	"[color=#948d84]Mushrooms form a perfect ring. " \
		+ "You step carefully around it.[/color]",
	"[color=#948d84]Distant horns call through the trees. " \
		+ "Hunt, or warning? Hard to say.[/color]",
]

const MOUNTAIN_FLAVOR = [
	"[color=#948d84]The wind howls between the crags, " \
		+ "carrying the scent of snow.[/color]",
	"[color=#948d84]Loose stones clatter down. " \
		+ "The mountain is restless.[/color]",
	"[color=#948d84]An eagle circles far above. " \
		+ "The forest looks like moss from here.[/color]",
	"[color=#948d84]A cairn marks where another stood. " \
		+ "You add a stone.[/color]",
	"[color=#948d84]The air thins. Each breath " \
		+ "feels like drinking cold fire.[/color]",
	"[color=#948d84]Fog rolls in, thick as wool. " \
		+ "Your next step could be your last.[/color]",
]

const CAVE_FLAVOR = [
	"[color=#948d84]Water drips in the darkness. " \
		+ "Each drop echoes endlessly.[/color]",
	"[color=#948d84]Torchlight dances across formations " \
		+ "that took millennia to form.[/color]",
	"[color=#948d84]The walls narrow. " \
		+ "Claustrophobia tightens its grip.[/color]",
	"[color=#948d84]Scratching from deeper in. " \
		+ "Rats? You hope it's rats.[/color]",
	"[color=#948d84]The air smells of old stone " \
		+ "and something faintly metallic.[/color]",
	"[color=#948d84]A cold draft from an unseen passage. " \
		+ "This cave breathes.[/color]",
	"[color=#948d84]Your torch sputters. " \
		+ "Shadows leap like living things.[/color]",
	"[color=#948d84]Faded murals line the wall — " \
		+ "warriors facing a crowned figure of darkness.[/color]",
	"[color=#948d84]Something wet brushes your boot. " \
		+ "You decide not to look down.[/color]",
]

const PEAK_FLAVOR = [
	"[color=#948d84]The world spreads below you " \
		+ "like a map drawn by the gods.[/color]",
	"[color=#948d84]Lightning flickers in clouds below. " \
		+ "You are above the storm.[/color]",
	"[color=#948d84]The stone here is warm to the touch. " \
		+ "Something burns deep beneath.[/color]",
	"[color=#948d84]A roar echoes across the peaks. " \
		+ "Thunder or something worse.[/color]",
	"[color=#948d84]The stars feel close enough " \
		+ "to touch from this height.[/color]",
	"[color=#948d84]Bones of enormous creatures " \
		+ "litter the ledge. A killing ground.[/color]",
]

const QUEST_NARRATIVES = [
	{
		"narrative": "[color=#d9b359]A weathered notice[/color] " \
			+ "flutters from a tree, pinned by a rusty dagger.",
		"area_hint": "forest"
	},
	{
		"narrative": "[color=#d9b359]A desperate messenger[/color] " \
			+ "stumbles past, dropping a sealed letter.",
		"area_hint": ""
	},
	{
		"narrative": "[color=#d9b359]Strange markings[/color] " \
			+ "lead to a hidden message carved in stone.",
		"area_hint": ""
	},
]


static func generate_event(
	area_id: String,
	player_level: int,
	danger_level: float,
) -> Dictionary:
	if area_id == "town":
		return _generate_flavor_event(area_id)
	if randf() * 100.0 < get_combat_chance(area_id, danger_level):
		return _generate_combat_event(area_id, player_level, danger_level)
	var weights = AREA_WEIGHTS.get(area_id, AREA_WEIGHTS["forest"])
	weights = [0, weights[1], weights[2], weights[3], weights[4]]
	var event_type = _pick_weighted(weights)

	match event_type:
		"discovery":
			return _generate_discovery_event(area_id, player_level)
		"choice":
			return _generate_choice_event(area_id)
		"flavor":
			return _generate_flavor_event(area_id)
		"quest":
			return _generate_quest_event(area_id, player_level)

	return _generate_flavor_event(area_id)


static func get_combat_chance(area_id: String, danger_level: float) -> float:
	var chance: float = float(BASE_COMBAT_CHANCE.get(area_id, 30.0))
	if danger_level >= 10.0:
		chance += 5.0
	if danger_level >= 20.0:
		chance += 5.0
	return chance


static func get_danger_tier(danger_level: float) -> String:
	if danger_level >= 20.0:
		return "perilous"
	if danger_level >= 10.0:
		return "wary"
	return "calm"


static func get_reward_multiplier(danger_level: float) -> float:
	match get_danger_tier(danger_level):
		"perilous":
			return 1.30
		"wary":
			return 1.15
		_:
			return 1.0


static func get_loot_chance(danger_level: float) -> float:
	match get_danger_tier(danger_level):
		"perilous":
			return 0.40
		"wary":
			return 0.30
		_:
			return 0.25


static func get_strong_enemy_chance(danger_level: float) -> float:
	match get_danger_tier(danger_level):
		"perilous":
			return 0.40
		"wary":
			return 0.20
		_:
			return 0.10


static func get_danger_summary(
	area_id: String, danger_level: float, danger_max: float
) -> String:
	var combat_chance := get_combat_chance(area_id, danger_level)
	var reward_bonus := roundi((get_reward_multiplier(danger_level) - 1.0) * 100.0)
	var loot_percent := roundi(get_loot_chance(danger_level) * 100.0)
	var strong_percent := roundi(get_strong_enemy_chance(danger_level) * 100.0)
	return (
		"Area threat %.0f / %.0f: %.0f%% combat chance, +%d%% combat rewards, " \
		+ "%d%% loot chance, %d%% strong enemies. %s"
	) % [danger_level, danger_max, combat_chance, reward_bonus, loot_percent,
		strong_percent, get_danger_flavor(danger_level)]


static func resolve_monster_level(
	area_id: String, player_level: int, danger_level: float
) -> int:
	var band: Vector2i = AREA_LEVEL_BANDS.get(area_id, Vector2i(1, 2))
	var resolved_level := clampi(player_level, band.x, band.y)
	if danger_level >= 20.0:
		resolved_level = mini(resolved_level + 1, band.y)
	return resolved_level


static func get_danger_flavor(danger_level: float) -> String:
	var index: int
	if danger_level < 5.0:
		index = 0
	elif danger_level < 10.0:
		index = 1
	elif danger_level < 15.0:
		index = 2
	elif danger_level < 20.0:
		index = 3
	else:
		index = 4
	return DANGER_FLAVORS[index]


static func _pick_weighted(weights: Array) -> String:
	var total = 0
	for w in weights:
		total += w
	if total <= 0:
		return "flavor"

	var roll = randi() % total
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return EVENT_TYPES[i]
	return EVENT_TYPES[weights.size() - 1]


static func _generate_combat_event(
	area_id: String, player_level: int, danger_level: float = 0.0
) -> Dictionary:
	var encounters: Array
	match area_id:
		"forest":
			encounters = FOREST_COMBAT
		"mountain":
			encounters = [MOUNTAIN_COMBAT[0], MOUNTAIN_COMBAT[2], MOUNTAIN_COMBAT[1]]
		"cave":
			encounters = [CAVE_COMBAT[2], CAVE_COMBAT[1], CAVE_COMBAT[0]]
		"peak":
			encounters = PEAK_COMBAT
		_:
			encounters = [FOREST_COMBAT[0], FOREST_COMBAT[0], FOREST_COMBAT[0]]

	var monster_weights := LOW_DANGER_MONSTER_WEIGHTS
	if danger_level >= 20.0:
		monster_weights = HIGH_DANGER_MONSTER_WEIGHTS
	elif danger_level >= 10.0:
		monster_weights = MID_DANGER_MONSTER_WEIGHTS
	var encounter_index := _pick_weighted_index(monster_weights)
	var encounter: Dictionary = encounters[encounter_index]

	return {
		"type": "combat",
		"title": encounter.title,
		"narrative": encounter.narrative,
		"monster_type": encounter.monster_type,
		"monster_rank": ["weak", "medium", "strong"][encounter_index],
		"monster_level": resolve_monster_level(area_id, player_level, danger_level),
		"danger_tier": get_danger_tier(danger_level),
		"reward_multiplier": get_reward_multiplier(danger_level),
		"loot_chance": get_loot_chance(danger_level),
		"area_id": area_id,
		"choices": [],
		"rewards": {},
	}


static func _pick_weighted_index(weights: Array) -> int:
	var total := 0
	for weight in weights:
		total += int(weight)
	if total <= 0:
		return 0
	var roll := randi() % total
	var cumulative := 0
	for index in range(weights.size()):
		cumulative += int(weights[index])
		if roll < cumulative:
			return index
	return weights.size() - 1


static func _generate_discovery_event(
	area_id: String, player_level: int
) -> Dictionary:
	var pool: Array
	match area_id:
		"forest":
			pool = FOREST_DISCOVERY
		"mountain":
			pool = MOUNTAIN_DISCOVERY
		"cave":
			pool = CAVE_DISCOVERY
		"peak":
			pool = PEAK_DISCOVERY
		_:
			pool = FOREST_DISCOVERY

	var discovery = pool[randi() % pool.size()]
	var rewards: Dictionary = discovery["rewards"].duplicate()
	if int(rewards.get("exp", 0)) > 0:
		var next_level_exp: int = 100 + 30 * (player_level - 1)
		rewards["exp"] = roundi(float(next_level_exp) * 0.10)
	return {
		"type": "discovery",
		"title": discovery["title"],
		"narrative": discovery["narrative"],
		"monster_type": "",
		"choices": [],
		"rewards": rewards,
	}


static func _generate_choice_event(area_id: String) -> Dictionary:
	var pool: Array
	match area_id:
		"forest":
			pool = FOREST_CHOICE
		"mountain":
			pool = MOUNTAIN_CHOICE
		"cave":
			pool = CAVE_CHOICE
		"peak":
			pool = PEAK_CHOICE
		_:
			pool = FOREST_CHOICE

	var choice_data = pool[randi() % pool.size()]
	return {
		"type": "choice",
		"title": choice_data["title"],
		"narrative": choice_data["narrative"],
		"monster_type": "",
		"choices": choice_data["choices"].duplicate(true),
		"rewards": {},
	}


static func _generate_flavor_event(area_id: String) -> Dictionary:
	var pool: Array
	match area_id:
		"town":
			pool = TOWN_FLAVOR
		"forest":
			pool = FOREST_FLAVOR
		"mountain":
			pool = MOUNTAIN_FLAVOR
		"cave":
			pool = CAVE_FLAVOR
		"peak":
			pool = PEAK_FLAVOR
		_:
			pool = FOREST_FLAVOR

	var narrative = pool[randi() % pool.size()]
	return {
		"type": "flavor",
		"title": "",
		"narrative": narrative,
		"monster_type": "",
		"choices": [],
		"rewards": {},
	}


static func _generate_quest_event(
	area_id: String, player_level: int
) -> Dictionary:
	var quest_info = QUEST_NARRATIVES[randi() % QUEST_NARRATIVES.size()]
	return {
		"type": "quest",
		"title": "Quest Found",
		"narrative": quest_info["narrative"],
		"monster_type": "",
		"choices": [],
		"rewards": {},
		"quest_level": player_level,
		"area_id": area_id,
	}
