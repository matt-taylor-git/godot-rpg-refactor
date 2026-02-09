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

const EVENT_TYPES = ["combat", "discovery", "choice", "flavor", "quest"]

# -- Danger flavor text --
const DANGER_FLAVORS = [
	"The air is calm and still.",
	"You sense movement in the shadows.",
	"The darkness seems to watch you.",
	"Every sound sets your nerves on edge.",
	"Death stalks your every step.",
]

# -- Narrative pools per area --
const FOREST_COMBAT = [
	"[color=#d9b359]A Goblin Ambush![/color]\n" \
		+ "Branches snap. A snarling creature lunges!",
	"[color=#d9b359]Wolves on the Hunt![/color]\n" \
		+ "Gleaming eyes between the trees. Unmistakable.",
	"[color=#d9b359]Forest Stalker![/color]\n" \
		+ "Something followed you. It finally strikes.",
	"[color=#d9b359]Slime Swarm![/color]\n" \
		+ "The ground squelches. Shapes ooze from the roots.",
	"[color=#d9b359]Bandit Scout![/color]\n" \
		+ "A figure drops from the canopy, blade drawn.",
]

const MOUNTAIN_COMBAT = [
	"[color=#d9b359]Orc Raider![/color]\n" \
		+ "A hulking figure blocks the path, war-axe raised.",
	"[color=#d9b359]Skeleton Patrol![/color]\n" \
		+ "Bones rattle in the fog. The dead walk these slopes.",
	"[color=#d9b359]Rock Slide Ambush![/color]\n" \
		+ "Stones tumble down -- something is throwing them.",
	"[color=#d9b359]Mountain Troll![/color]\n" \
		+ "The boulder you were resting against... moves.",
	"[color=#d9b359]Wind Wraith![/color]\n" \
		+ "A howling gust coalesces into something with claws.",
]

const CAVE_COMBAT = [
	"[color=#d9b359]Spider's Lair![/color]\n" \
		+ "Webs cling to your face. Legs skitter above.",
	"[color=#d9b359]Bat Swarm![/color]\n" \
		+ "A shriek echoes. Wings fill the tunnel.",
	"[color=#d9b359]Skeleton Guardian![/color]\n" \
		+ "Ancient bones rise from a sarcophagus, sword in hand.",
	"[color=#d9b359]Cave Dweller![/color]\n" \
		+ "Something pale and eyeless crawls from the wall.",
	"[color=#d9b359]Trapped![/color]\n" \
		+ "The passage narrows. Something lurks -- no going back.",
]

const PEAK_COMBAT = [
	"[color=#d9b359]Dragon's Territory![/color]\n" \
		+ "A shadow blots out the sun. Scales glint like obsidian.",
	"[color=#d9b359]Orc Warlord![/color]\n" \
		+ "A massive orc stands at the ridge, flanked by brutes.",
	"[color=#d9b359]Storm Elemental![/color]\n" \
		+ "Lightning arcs between the crags. The storm attacks.",
	"[color=#d9b359]Troll Berserker![/color]\n" \
		+ "The ground shakes. A troll charges down, roaring.",
	"[color=#d9b359]Peak Guardian![/color]\n" \
		+ "An ancient sentinel stirs, bound to protect this height.",
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
	_danger_level: float,
) -> Dictionary:
	var weights = AREA_WEIGHTS.get(area_id, AREA_WEIGHTS["forest"])
	var event_type = _pick_weighted(weights)

	match event_type:
		"combat":
			return _generate_combat_event(area_id, player_level)
		"discovery":
			return _generate_discovery_event(area_id, player_level)
		"choice":
			return _generate_choice_event(area_id)
		"flavor":
			return _generate_flavor_event(area_id)
		"quest":
			return _generate_quest_event(area_id, player_level)

	return _generate_flavor_event(area_id)


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
	area_id: String, _player_level: int
) -> Dictionary:
	var pool: Array
	var monster_pool: Array
	match area_id:
		"forest":
			pool = FOREST_COMBAT
			monster_pool = ["goblin", "slime", "wolf"]
		"mountain":
			pool = MOUNTAIN_COMBAT
			monster_pool = ["goblin", "orc", "skeleton"]
		"cave":
			pool = CAVE_COMBAT
			monster_pool = ["skeleton", "spider", "bat"]
		"peak":
			pool = PEAK_COMBAT
			monster_pool = ["orc", "troll", "dragon"]
		_:
			pool = FOREST_COMBAT
			monster_pool = ["goblin"]

	var narrative = pool[randi() % pool.size()]
	var monster_type = monster_pool[randi() % monster_pool.size()]

	return {
		"type": "combat",
		"title": "Combat Encounter",
		"narrative": narrative,
		"monster_type": monster_type,
		"choices": [],
		"rewards": {},
	}


static func _generate_discovery_event(
	area_id: String, _player_level: int
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
	return {
		"type": "discovery",
		"title": discovery["title"],
		"narrative": discovery["narrative"],
		"monster_type": "",
		"choices": [],
		"rewards": discovery["rewards"].duplicate(),
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
