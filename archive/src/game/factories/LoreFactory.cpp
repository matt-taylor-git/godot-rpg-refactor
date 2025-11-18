#include "LoreFactory.h"
#include <QMap>

LoreEntry* LoreFactory::createLoreEntry(const QString &entryId)
{
    // Static cache to prevent memory leaks
    static QMap<QString, LoreEntry*> cache;

    if (cache.isEmpty()) {
        // ================================================================
        // BESTIARY ENTRIES
        // ================================================================

        // Bestiary: Goblin
        LoreEntry* goblin = new LoreEntry();
        goblin->entryId = "bestiary_goblin";
        goblin->category = "Bestiary";
        goblin->title = "Goblin";
        goblin->shortDescription = "Small, cunning creatures that hunt in packs.";
        goblin->fullText = R"(Goblins are among the most common threats to frontier settlements.

Physical Characteristics:
- Height: 3-4 feet
- Green or gray skin
- Sharp claws and teeth
- Excellent night vision

Behavior:
- Travel in packs of 3-8
- Cowardly when alone, aggressive in groups
- Prefer ambush tactics
- Known to steal shiny objects

Habitat: Caves, abandoned ruins, dense forests

Weakness: Fire-based attacks, bright light

Combat Tips: Eliminate the pack leader first - the rest will often flee.)";
        goblin->imagePath = "";
        goblin->discoveryTrigger = "kill_Goblin_3";

        cache["bestiary_goblin"] = goblin;

        // Bestiary: Shadow Wolf
        LoreEntry* shadowWolf = new LoreEntry();
        shadowWolf->entryId = "bestiary_shadow_wolf";
        shadowWolf->category = "Bestiary";
        shadowWolf->title = "Shadow Wolf";
        shadowWolf->shortDescription = "Corrupted wolves shrouded in dark energy.";
        shadowWolf->fullText = R"(Shadow Wolves are not natural creatures - they are ordinary wolves corrupted by dark magic.

Origins:
The corruption began approximately six months ago, coinciding with disturbances in the Whispering Woods.
Normal wolves transformed into these shadowy predators.

Physical Changes:
- Fur turns pitch black with purple undertones
- Eyes glow with an eerie violet light
- Larger and more aggressive than normal wolves
- Leave trails of dark mist when moving

Abilities:
- Enhanced strength and speed
- Can blend into shadows
- Their bite carries a weakening curse

The presence of Shadow Wolves always indicates a nearby source of dark magic.
Eliminating them is treating the symptom, not the cause.)";
        shadowWolf->imagePath = "";
        shadowWolf->discoveryTrigger = "kill_Shadow Wolf_1";

        cache["bestiary_shadow_wolf"] = shadowWolf;

        // Bestiary: Orc Warrior
        LoreEntry* orc = new LoreEntry();
        orc->entryId = "bestiary_orc";
        orc->category = "Bestiary";
        orc->title = "Orc Warrior";
        orc->shortDescription = "Brutish fighters with incredible strength.";
        orc->fullText = R"(Orcs are formidable opponents, bred for battle from birth.

Physical Traits:
- Height: 6-7 feet
- Muscular build, green or gray skin
- Tusks protruding from lower jaw
- High pain tolerance

Combat Style:
- Favor heavy weapons: axes, maces, greatswords
- Berserker rage in prolonged fights
- Simple but effective tactics
- Extremely durable

Culture:
- Honor-based warrior society
- Respect strength above all
- Can be reasoned with if you prove your worth

Weakness: Magic, particularly elemental spells
Strategy: Keep distance, avoid close combat unless well-armored)";
        orc->imagePath = "";
        orc->discoveryTrigger = "kill_Orc_2";

        cache["bestiary_orc"] = orc;

        // ================================================================
        // ITEM LORE
        // ================================================================

        // Item: Healing Potion
        LoreEntry* healingPotion = new LoreEntry();
        healingPotion->entryId = "item_healing_potion";
        healingPotion->category = "Items";
        healingPotion->title = "Healing Potion";
        healingPotion->shortDescription = "A miraculous elixir that mends wounds.";
        healingPotion->fullText = R"(The standard healing potion is a staple of adventurers worldwide.

Composition:
- Red moss from mountain caves
- Distilled spring water
- Essence of life flower
- Stabilizing agent (usually honey)

Creation Process:
Crafted by skilled alchemists, the brewing process takes three days and requires precise temperature control.
The characteristic red glow indicates proper potency.

Effects:
- Rapid tissue regeneration
- Stops bleeding within seconds
- Can heal minor to moderate wounds
- No effect on diseases or curses

The invention of healing potions revolutionized adventuring, making previously fatal wounds survivable.

Tip: Always carry at least three potions into dangerous situations.)";
        healingPotion->imagePath = "";
        healingPotion->discoveryTrigger = "item_get_Healing Potion";

        cache["item_healing_potion"] = healingPotion;

        // Item: Ancient Sword (example rare item)
        LoreEntry* ancientSword = new LoreEntry();
        ancientSword->entryId = "item_ancient_sword";
        ancientSword->category = "Items";
        ancientSword->title = "Ancient Blade";
        ancientSword->shortDescription = "A sword from a forgotten age.";
        ancientSword->fullText = R"(This sword predates the current kingdom by centuries.

Markings on the blade suggest it was forged by the Elven smiths of the Silver Age,
a time when magic and metalcraft were one art.

The blade never dulls, and whispers speak of it cutting through magical barriers
as easily as flesh.

Many heroes have wielded this weapon. Their victories are etched into its very essence.

Finding such a blade is destiny calling.)";
        ancientSword->imagePath = "";
        ancientSword->discoveryTrigger = "item_get_Ancient Sword";

        cache["item_ancient_sword"] = ancientSword;

        // ================================================================
        // WORLD LORE
        // ================================================================

        // World: The Whispering Woods
        LoreEntry* woods = new LoreEntry();
        woods->entryId = "world_whispering_woods";
        woods->category = "World";
        woods->title = "The Whispering Woods";
        woods->shortDescription = "An ancient forest with secrets.";
        woods->fullText = R"(The Whispering Woods have stood for over a thousand years.

History:
Local legends claim the forest was planted by ancient druids to serve as a barrier
between civilization and the wild lands beyond.

For centuries, it lived up to its name - travelers reported hearing whispers
in unknown languages carried on the wind. Most dismissed these as superstition.

Recent Changes:
Six months ago, the whispers changed. Where once they were gentle and curious,
they now sound angry, warning travelers away.

Wildlife has become aggressive. The very trees seem darker.

Some scholars believe the forest is trying to warn us of a greater danger.
Others think the forest itself has been corrupted.

The truth likely lies buried deep within its heart, where few dare venture.)";
        woods->entryId = "world_whispering_woods";
        woods->discoveryTrigger = "quest_complete_main_quest_01";

        cache["world_whispering_woods"] = woods;

        // World: Ancient War
        LoreEntry* ancientWar = new LoreEntry();
        ancientWar->entryId = "world_ancient_war";
        ancientWar->category = "World";
        ancientWar->title = "The Shadow War";
        ancientWar->shortDescription = "A forgotten conflict that shaped the world.";
        ancientWar->fullText = R"(Three hundred years ago, the world nearly ended.

An entity known only as the Shadow Lord rose from the depths, commanding
legions of corrupted creatures.

The war lasted seven years and claimed millions of lives.

Heroes from all races - humans, elves, dwarves - united against the darkness.

In a final desperate battle, the Shadow Lord was not destroyed but sealed away,
his prison hidden in a place "where the trees speak and shadows walk."

The location of this prison was lost to time, known only to a secret order of guardians.

An order that disappeared fifty years ago.

Recent events suggest the seal may be weakening.)";
        ancientWar->entryId = "world_ancient_war";
        ancientWar->discoveryTrigger = "quest_complete_main_quest_02";

        cache["world_ancient_war"] = ancientWar;

        // ================================================================
        // CHARACTER LORE
        // ================================================================

        // Character: Village Elder
        LoreEntry* elder = new LoreEntry();
        elder->entryId = "character_village_elder";
        elder->category = "Characters";
        elder->title = "Elder Aldwin";
        elder->shortDescription = "The wise leader of Thornhaven.";
        elder->fullText = R"(Elder Aldwin has led Thornhaven for over thirty years.

Background:
In his youth, he was an adventurer himself, exploring ruins and battling monsters.
A near-fatal encounter with a dragon led him to settle down and dedicate his life
to protecting his home village.

Leadership:
Under his guidance, Thornhaven has prospered. He's known for his wisdom,
fairness, and uncanny ability to sense trouble before it arrives.

The Current Crisis:
The Shadow Wolves trouble him deeply. He claims to have seen similar corruption
during his adventuring days, though he won't speak of where or when.

Some villagers whisper that he knows more about the darkness than he admits.

But none doubt his dedication to protecting the village and its people.)";
        elder->entryId = "character_village_elder";
        elder->discoveryTrigger = "quest_complete_main_quest_01";

        cache["character_village_elder"] = elder;

        // Character: Traveling Merchant
        LoreEntry* merchant = new LoreEntry();
        merchant->entryId = "character_merchant";
        merchant->category = "Characters";
        merchant->title = "Marcus the Merchant";
        merchant->shortDescription = "A well-traveled trader with valuable goods.";
        merchant->fullText = R"(Marcus has been traveling the trade routes for fifteen years.

His wagon is a familiar sight in villages throughout the region.

Where he sources his rare items, he never says - trade secrets, he claims.

Some suspect he explores dungeons himself, though he denies this with a wink.

Reliable and fair in his dealings, he's saved many an adventurer with
a well-timed healing potion or emergency equipment.

"Gold keeps me traveling," he says, "but stories keep me alive.")";
        merchant->entryId = "character_merchant";
        merchant->discoveryTrigger = "manual";  // Unlocked through initial dialogue

        cache["character_merchant"] = merchant;

        // ================================================================
        // LOCATION LORE
        // ================================================================

        // Location: Thornhaven
        LoreEntry* thornhaven = new LoreEntry();
        thornhaven->entryId = "location_thornhaven";
        thornhaven->category = "Locations";
        thornhaven->title = "Thornhaven Village";
        thornhaven->shortDescription = "A peaceful frontier settlement.";
        thornhaven->fullText = R"(Thornhaven: Population 347

Founded eighty years ago by settlers seeking new opportunities,
Thornhaven has grown from a simple logging camp into a thriving village.

Key Features:
- The Rusty Tankard Inn: Central gathering place
- Market Square: Weekly trading hub
- Elder's Hall: Village governance and records
- Temple of Light: Spiritual center
- Smithy: Crafts and repairs

Economy:
Primarily logging and farming, with some mining in the nearby hills.

Strategic Importance:
Thornhaven sits at the crossroads of three trade routes, making it valuable
for commerce and communication.

Current Situation:
The Shadow Wolf threat has put the village on edge. Several outlying farms
have been abandoned. Trade has slowed as merchants fear the forest roads.

The people look to their Elder and to brave adventurers for salvation.)";
        thornhaven->entryId = "location_thornhaven";
        thornhaven->discoveryTrigger = "manual";  // Unlocked at game start

        cache["location_thornhaven"] = thornhaven;

        // Location: Old Ruins
        LoreEntry* ruins = new LoreEntry();
        ruins->entryId = "location_old_ruins";
        ruins->category = "Locations";
        ruins->title = "The Forgotten Ruins";
        ruins->shortDescription = "Ancient stone structures of unknown origin.";
        ruins->fullText = R"(Two miles north of Thornhaven lie ruins of an ancient civilization.

What little remains suggests sophisticated architecture and knowledge of magic.

The ruins consist of:
- Collapsed stone towers
- Underground chambers (partially explored)
- A central plaza with strange glyphs
- Fragments of statues depicting unknown deities

Scholars who've studied the site estimate it's at least 800 years old,
predating any known settlement in the region.

Strange lights are sometimes seen among the ruins at night.

Local children are forbidden from playing there, and with good reason -
several adventurers who entered the underground chambers were never seen again.

The ruins may hold clues to the current darkness plaguing the forest.)";
        ruins->entryId = "location_old_ruins";
        ruins->discoveryTrigger = "quest_complete_main_quest_02";

        cache["location_old_ruins"] = ruins;

        // ================================================================
        // PHASE 5 EXPANSION: Additional Bestiary Entries
        // ================================================================

        // Bestiary: Dark Mage
        LoreEntry* darkMage = new LoreEntry();
        darkMage->entryId = "bestiary_dark_mage";
        darkMage->category = "Bestiary";
        darkMage->title = "Dark Mage";
        darkMage->shortDescription = "Corrupted spellcasters who wield shadow magic.";
        darkMage->fullText = R"(Dark Mages are scholars who traded their humanity for forbidden power.

Origins:
They were once respected members of magical academies, driven by curiosity to study the shadow arts.
The corruption was gradual - a whisper here, a dark ritual there - until transformation became inevitable.

Physical Manifestation:
- Eyes turned completely black, void of light
- Skin pale and cold to touch
- Surrounded by tendrils of shadow energy
- Fingers elongated, ending in sharp points

Abilities:
- Shadow bolt attacks that pierce armor
- Can summon lesser shadow creatures
- Drain life force from victims
- Create zones of darkness that blind opponents

Defeating a Dark Mage requires disrupting their concentration. They are powerful but fragile,
relying on magic for defense. Swift, decisive strikes are most effective.

The tragedy is that buried beneath the corruption, fragments of their original selves remain,
screaming silently for release.)";
        darkMage->imagePath = "";
        darkMage->discoveryTrigger = "kill_Dark Mage_2";
        cache["bestiary_dark_mage"] = darkMage;

        // Bestiary: Stone Golem
        LoreEntry* golem = new LoreEntry();
        golem->entryId = "bestiary_stone_golem";
        golem->category = "Bestiary";
        golem->title = "Stone Golem";
        golem->shortDescription = "Ancient guardians awakened by dark magic.";
        golem->fullText = R"(Stone Golems are constructs created centuries ago to guard important sites.

Construction:
Crafted by master artificers of the ancient civilization that built the Forgotten Ruins.
Each golem required months of work, enchanting every stone block with binding runes.

Original Purpose:
They served as tireless guardians, distinguishing friend from foe through magical recognition.
For centuries, they stood dormant, their magical fuel exhausted.

Reawakening:
The recent surge of shadow corruption has reactivated many golems, but twisted their programming.
Now they attack all living creatures indiscriminately.

Combat Characteristics:
- Incredibly durable, resistant to most weapons
- Devastating melee attacks
- Immune to poison and mental effects
- Vulnerable to magic, especially lightning

Strategic Value:
The runes inscribed on their bodies hold clues to the ancient civilization's knowledge.
Scholars pay handsomely for intact golem cores.)";
        golem->imagePath = "";
        golem->discoveryTrigger = "kill_Stone Golem_1";
        cache["bestiary_stone_golem"] = golem;

        // Bestiary: Corrupted Guardian
        LoreEntry* guardian = new LoreEntry();
        guardian->entryId = "bestiary_corrupted_guardian";
        guardian->category = "Bestiary";
        guardian->title = "Corrupted Guardian";
        guardian->shortDescription = "Former protectors transformed into nightmarish hunters.";
        guardian->fullText = R"(Corrupted Guardians were once elite knights sworn to protect the realm.

The Fall:
When shadow corruption reached their garrison, they fought valiantly to contain it.
But shadow magic doesn't just kill - it transforms. The very dedication that made them elite guardians
became their curse, binding their corrupted forms to eternal service.

Physical Transformation:
- Armor fused to flesh, indistinguishable from skin
- Eyes glow with malevolent red light
- Weapons drip with shadow essence
- Move with unnatural speed despite heavy armor

Retained Skills:
Unlike mindless undead, Corrupted Guardians retain combat expertise.
They use formations, tactics, and weapon techniques from their living days.
This makes them far more dangerous than typical corrupted creatures.

Tragedy:
Some retain fragments of memory. Witnesses report hearing them cry out orders to long-dead comrades
or call names of loved ones between attacks.

To end their torment is a mercy, though they will not go down easily.)";
        guardian->imagePath = "";
        guardian->discoveryTrigger = "kill_Corrupted Guardian_1";
        cache["bestiary_corrupted_guardian"] = guardian;

        // Bestiary: Ancient Dragon
        LoreEntry* dragon = new LoreEntry();
        dragon->entryId = "bestiary_ancient_dragon";
        dragon->category = "Bestiary";
        dragon->title = "Ancient Dragon";
        dragon->shortDescription = "Legendary creatures of immense power, rare and dangerous.";
        dragon->fullText = R"(Dragons are among the oldest and most powerful creatures in existence.

History:
Dragons existed before recorded history. They witnessed the rise and fall of empires,
the birth of magic, and cataclysms that reshaped continents.

Ancient Dragons specifically are those who have survived for millennia, accumulating both power and wisdom.

Characteristics:
- Scales harder than any metal
- Breath weapons of devastating power (fire, ice, lightning, or poison)
- Innate magical abilities
- Intelligence surpassing most humanoid races
- Immense physical strength

Dragon Culture:
Contrary to popular belief, dragons are not mindless beasts. They possess complex thoughts,
motivations, and even morality - though their values differ vastly from human understanding.

Some collect knowledge rather than gold. Others enforce ancient pacts or guard sacred locations.

Combat Warning:
Engaging a dragon is suicidal without extensive preparation. They have no exploitable weaknesses,
only comparative vulnerabilities. Victory requires legendary equipment, powerful magic, and considerable luck.

If you encounter a dragon, diplomacy should be your first option. Many dragons will parley before fighting.)";
        dragon->imagePath = "";
        dragon->discoveryTrigger = "kill_Dragon_1";
        cache["bestiary_ancient_dragon"] = dragon;

        // Bestiary: Shadow Lord (Final Boss)
        LoreEntry* shadowLord = new LoreEntry();
        shadowLord->entryId = "bestiary_shadow_lord";
        shadowLord->category = "Bestiary";
        shadowLord->title = "The Shadow Lord";
        shadowLord->shortDescription = "The entity behind the corruption, sealed away but breaking free.";
        shadowLord->fullText = R"(The Shadow Lord is not merely a powerful monster - it is corruption incarnate.

True Nature:
The Shadow Lord is not native to this realm. It arrived from the void between worlds during the Shadow War,
seeking to consume all light and life.

It cannot be killed through conventional means, only contained. The ancient heroes learned this
after years of devastating warfare.

The Seal:
Three hundred years ago, at tremendous cost, the Shadow Lord was imprisoned in a magical seal.
The location: the heart of the Whispering Woods.

Breaking Free:
The seal was designed to last forever, but "forever" assumed someone would maintain it.
With the guardian order extinct, the seal has degraded.

For six months, the Shadow Lord has been projecting its influence through cracks in the seal,
corrupting wildlife and warping reality around its prison.

The Final Battle:
When the seal breaks completely, the Shadow Lord will emerge in physical form.
It will possess power accumulated over three centuries of imprisonment.

Only a hero armed with legendary weapons and unbreakable will can hope to face it.
The battle will determine whether civilization survives or falls into eternal darkness.)";
        shadowLord->imagePath = "";
        shadowLord->discoveryTrigger = "quest_complete_final_quest";
        cache["bestiary_shadow_lord"] = shadowLord;

        // ================================================================
        // PHASE 5 EXPANSION: Additional Item Entries
        // ================================================================

        // Item: Mana Potion
        LoreEntry* manaPotion = new LoreEntry();
        manaPotion->entryId = "item_mana_potion";
        manaPotion->category = "Items";
        manaPotion->title = "Mana Potion";
        manaPotion->shortDescription = "A mystical concoction that restores magical energy.";
        manaPotion->fullText = R"(Mana potions are essential for any spellcaster venturing into danger.

Composition:
- Liquid moonstone extract (primary ingredient)
- Crystallized starlight powder
- Distilled essence of ley line energy
- Sage and lavender for stabilization

The characteristic blue glow indicates active magical energy contained within.

Brewing Process:
Unlike healing potions, mana potions must be brewed under moonlight during specific lunar phases.
Master alchemists guard their exact formulas jealously, as improper ratios can result in explosive failure.

Effects:
- Rapidly restores magical energy reserves
- Enhances spell clarity and focus
- Temporary increase in magical perception
- Duration: approximately 30 minutes

Historical Note:
Before the invention of mana potions four centuries ago, spellcasters were severely limited
in extended engagements. A mage who exhausted their mana was defenseless.

The development of mana potions revolutionized magical warfare and dungeon exploration.

Warning: Consuming more than three mana potions in a day can cause "mana sickness" -
nausea, magical instability, and temporary loss of spellcasting ability.)";
        manaPotion->imagePath = "";
        manaPotion->discoveryTrigger = "item_get_Mana Potion";
        cache["item_mana_potion"] = manaPotion;

        // Item: Legendary Armor
        LoreEntry* legendaryArmor = new LoreEntry();
        legendaryArmor->entryId = "item_legendary_armor";
        legendaryArmor->category = "Items";
        legendaryArmor->title = "Dragonscale Plate";
        legendaryArmor->shortDescription = "Armor crafted from the scales of an ancient dragon.";
        legendaryArmor->fullText = R"(Dragonscale Plate represents the pinnacle of protective equipment.

Origins:
This armor was crafted from scales shed by the Crimson Dragon Tyranthax during his century-long slumber.
The dragon gifted these scales to a hero who had earned his respect through trial by combat.

Crafting:
Master dwarf smiths worked for three years to shape the scales. Dragon scales cannot be worked
with conventional heat - they require magical forges burning with elemental fire.

The process cost the life of one smith, consumed by the very flames needed to work the scales.

Properties:
- Nearly impenetrable defense against physical attacks
- Innate resistance to fire, ice, and lightning
- Self-repairing when exposed to heat
- Never tarnishes or degrades
- Remarkably light despite its strength

Wearing the Armor:
The armor bonds with its wearer over time, becoming an extension of their will.
Experienced wearers report the armor shifting to deflect blows they didn't consciously see.

Legacy:
Seven heroes have worn this armor across the centuries. All achieved legendary status.
Each wearer's essence left an imprint, creating a lineage of courage and determination
that future bearers can draw upon in moments of desperation.)";
        legendaryArmor->imagePath = "";
        legendaryArmor->discoveryTrigger = "item_get_Dragonscale Plate";
        cache["item_legendary_armor"] = legendaryArmor;

        // Item: Magic Staff
        LoreEntry* magicStaff = new LoreEntry();
        magicStaff->entryId = "item_magic_staff";
        magicStaff->category = "Items";
        magicStaff->title = "Staff of Resonance";
        magicStaff->shortDescription = "A conduit that amplifies magical power.";
        magicStaff->fullText = R"(The Staff of Resonance is a masterwork of magical engineering.

Construction:
The staff's core is heartwood from an ancient World Tree, a species now extinct.
Wrapped around the core are silver threads infused with ley line energy.
The crystal at its crown is a naturally-formed mana prism.

Function:
Unlike simple wooden staves, this staff actively channels and amplifies magical energy.
It reduces the mana cost of spells while increasing their potency and stability.

Attunement:
The staff must attune to its wielder over days of use. During attunement, it learns
the wielder's magical signature, optimizing its resonance patterns.

A fully attuned staff feels like an extension of the caster's will, responding to
intent as readily as to spoken incantations.

Historical Significance:
This staff passed through the hands of the Archmages Council during the Shadow War.
It channeled the final sealing ritual that imprisoned the Shadow Lord.

The magical echoes of that ritual still resonate within the staff's crystalline matrix.
Sensitive spellcasters can hear faint whispers of the incantation when wielding it.

Some believe the staff retains knowledge of the sealing magic, waiting for a worthy mage
to unlock its secrets.)";
        magicStaff->imagePath = "";
        magicStaff->discoveryTrigger = "item_get_Magic Staff";
        cache["item_magic_staff"] = magicStaff;

        // Item: Cursed Ring
        LoreEntry* cursedRing = new LoreEntry();
        cursedRing->entryId = "item_cursed_ring";
        cursedRing->category = "Items";
        cursedRing->title = "Ring of Shadows";
        cursedRing->shortDescription = "Powerful but dangerous, this ring comes with a terrible price.";
        cursedRing->fullText = R"(The Ring of Shadows embodies the seductive danger of dark power.

Creation:
Forged by a desperate king seeking power to save his failing kingdom,
the ring was created through ritual sacrifice and blood magic.

It granted him the power he sought - and destroyed everything he loved.

Powers:
- Grants wielder enhanced strength and speed
- Allows manipulation of shadows for stealth or attack
- Provides resistance to mental effects
- Slowly regenerates wielder's health

The Curse:
Every use of the ring's power exacts a toll. The wielder's humanity slowly erodes.
Emotions fade, replaced by cold calculation. Compassion dies, leaving only ambition.

The king who created it became a tyrant, then a monster. His kingdom fell not to external threats
but to his own corrupted rule.

Safe Usage:
Scholars debate whether the ring can be used safely. Some argue brief, infrequent use allows
the wielder to avoid corruption. Others claim any use starts inevitable descent.

All agree on one point: the ring must never be worn continuously. Those who sleep wearing it
wake changed, if they wake at all.

The ring seeks a new master whenever one falls. It whispers promises of power to anyone who holds it.
Strong will is required to resist its influence.)";
        cursedRing->imagePath = "";
        cursedRing->discoveryTrigger = "item_get_Cursed Ring";
        cache["item_cursed_ring"] = cursedRing;

        // ================================================================
        // PHASE 5 EXPANSION: Additional World History Entries
        // ================================================================

        // World: Fall of Kingdoms
        LoreEntry* fallKingdoms = new LoreEntry();
        fallKingdoms->entryId = "world_fall_kingdoms";
        fallKingdoms->category = "World";
        fallKingdoms->title = "The Fall of Kingdoms";
        fallKingdoms->shortDescription = "How the great empires crumbled before the Shadow Lord.";
        fallKingdoms->fullText = R"(Before the Shadow War, seven great kingdoms ruled the known world.

The Golden Age:
For two centuries, these kingdoms coexisted in relative peace. Trade flourished,
magic academies shared knowledge, and civilization reached unprecedented heights.

Cultural marvels were created - floating cities, magical transportation networks,
artifacts of incredible power.

The Coming Dark:
The Shadow Lord emerged without warning from the Void Gate, a tear in reality located
in what is now the Whispering Woods.

Initial Response:
Each kingdom initially fought independently, arrogance preventing cooperation.
The Shadow Lord exploited these divisions, conquering kingdoms one by one.

The Kanthros Empire fell first, its vaunted legions turned to shadow-corrupted soldiers.
The Elven Sovereignty lasted longer, but their forest cities burned with corrupted fire.

United Front:
Only when three kingdoms had fallen did the remaining four unite.
The combined armies, led by heroes from each kingdom, pushed back the darkness.

Victory and Price:
The war lasted seven years. When it ended, all seven kingdoms were shattered.
The population was reduced by two-thirds. Magical knowledge was lost as academies burned.

The victors were too exhausted and depleted to rebuild empires.
From their ruins rose smaller nations, city-states, and frontier settlements like Thornhaven.

The golden age ended. We still live in its shadow.)";
        fallKingdoms->imagePath = "";
        fallKingdoms->discoveryTrigger = "quest_complete_main_quest_03";
        cache["world_fall_kingdoms"] = fallKingdoms;

        // World: The Prophecy
        LoreEntry* prophecy = new LoreEntry();
        prophecy->entryId = "world_prophecy";
        prophecy->category = "World";
        prophecy->title = "The Prophecy of Return";
        prophecy->shortDescription = "Ancient predictions warn of the Shadow Lord's return.";
        prophecy->fullText = R"(Among the texts recovered from pre-Shadow War archives, one stands out: The Prophecy of Return.

Original Text:
"When three centuries pass and guardians fall,
When shadows walk where light once stood tall,
When the seal cracks and whispers grow loud,
The darkness returns beneath crimson shroud.

Only the hero forged in shadow's own flame,
Who walks between darkness and light without shame,
Armed with twelve relics from the ancient age,
Can end the cycle and turn history's page."

Interpretation:
Scholars have debated this prophecy for decades. Several elements are clear:

"Three centuries pass" - It has been exactly 300 years since the sealing.
"Guardians fall" - The order that maintained the seal is extinct.
"Seal cracks" - The recent surge in shadow corruption confirms this.

The controversial element is "hero forged in shadow's own flame."
Does this mean the hero must use dark power? Or survive corruption?
The "walk between darkness and light" suggests balance, not capitulation.

The Twelve Relics:
Most mysterious is the reference to "twelve relics from the ancient age."
Historical records mention twelve legendary weapons created during the Shadow War,
but only three have been found in the centuries since.

The Ancient Blade in circulation may be one of these twelve.
Where are the others?

Current Relevance:
With shadow corruption spreading and the seal weakening, many believe the prophecy
is coming to pass. The question becomes: who is the prophesied hero?

Or more frightening: what if no such hero exists, and we face the Shadow Lord alone?)";
        prophecy->imagePath = "";
        prophecy->discoveryTrigger = "quest_complete_main_quest_04";
        cache["world_prophecy"] = prophecy;

        // World: The Void
        LoreEntry* theVoid = new LoreEntry();
        theVoid->entryId = "world_the_void";
        theVoid->category = "World";
        theVoid->title = "The Void Between Worlds";
        theVoid->shortDescription = "The space between realities where the Shadow Lord originated.";
        theVoid->fullText = R"(The Void is not merely empty space - it is the absence of existence itself.

Nature of the Void:
Between all worlds, realities, and dimensions exists the Void.
It is a place without light, matter, time, or natural law.

Creatures born in the Void - if "born" is the right word - exist in a state incomprehensible
to beings from ordered reality. They hunger for the structure and energy our world possesses.

The Shadow Lord:
The Shadow Lord is one such Void entity. It became aware of our world through unknown means
and tore open a gate to enter.

Unlike mindless Void spawn, the Shadow Lord possesses intelligence and purpose.
It doesn't merely destroy - it corrupts, transforming our reality into something closer to the Void.

Void Gates:
The original gate opened in what is now the Whispering Woods. It was sealed during the Shadow War,
but sealing is not closing. The gate still exists, merely locked from this side.

Scholars who have studied the seal report feeling an immense pressure from the other side,
as if something is constantly pushing, testing for weaknesses.

Danger of Study:
Understanding the Void is perilous. Those who gaze too long into that absence risk losing themselves.
Several researchers have gone mad, claiming they heard the Void call their names.

The most disturbing accounts come from those who survived: they report the Void is not merely empty.
It is watching. Waiting. Hungry.

Our world is but one light in infinite darkness, and the darkness knows we're here.)";
        theVoid->imagePath = "";
        theVoid->discoveryTrigger = "quest_complete_main_quest_05";
        cache["world_the_void"] = theVoid;

        // World: Shadow Corruption
        LoreEntry* corruption = new LoreEntry();
        corruption->entryId = "world_shadow_corruption";
        corruption->category = "World";
        corruption->title = "Nature of Shadow Corruption";
        corruption->shortDescription = "Understanding the transformation that creates monsters.";
        corruption->fullText = R"(Shadow corruption is not disease or poison - it is reality itself being rewritten.

The Process:
When shadow energy touches living beings, it begins altering them at a fundamental level.
Physical changes are just symptoms of deeper transformation.

Stages:
Stage 1 - Exposure: Victim feels cold, reports seeing shadows move independently.
Stage 2 - Infection: Shadow tendrils visible beneath skin, personality changes begin.
Stage 3 - Transformation: Physical mutation, original personality fragmenting.
Stage 4 - Complete Corruption: Original self destroyed, replaced by shadow construct.

The tragedy is that consciousness persists through transformation. Corrupted beings
retain fragments of memory and personality, trapped in forms that act against their will.

Resistance:
Strong will can slow corruption but not stop it. Magic can purify early stages,
but Stage 3 and beyond is irreversible with current knowledge.

The ancient heroes who fought the Shadow War had access to purification rituals now lost.
Without this knowledge, our only option is to end the suffering of the corrupted.

Environmental Effect:
Corruption doesn't only affect living beings. It warps the land itself.
Trees grow twisted, water turns black, even stone begins to change.

The Whispering Woods shows all stages of environmental corruption. If left unchecked,
it will spread until the entire region becomes an extension of the Void.

Cure Research:
Alchemists and mages desperately seek a cure. The key may lie in the Shadow War archives,
if any survive. Or in understanding the seal itself - if it contains corruption,
perhaps its principles can purify it.

Time is running out. As the seal weakens, corruption accelerates.)";
        corruption->imagePath = "";
        corruption->discoveryTrigger = "quest_complete_main_quest_02";
        cache["world_shadow_corruption"] = corruption;

        // ================================================================
        // PHASE 5 EXPANSION: Additional Character Entries
        // ================================================================

        // Character: Wandering Scholar
        LoreEntry* scholar = new LoreEntry();
        scholar->entryId = "character_scholar";
        scholar->category = "Characters";
        scholar->title = "Scholar Theron";
        scholar->shortDescription = "A mysterious researcher seeking knowledge of the ancient war.";
        scholar->fullText = R"(Scholar Theron appears to be in his fifties, though his eyes suggest far greater age.

Background:
He arrived in Thornhaven six months ago, claiming to research pre-Shadow War civilizations.
His knowledge of ancient history is encyclopedic, far beyond what any ordinary scholar could possess.

Research Focus:
Theron seeks specific information: the location of the original Void Gate, details of the sealing ritual,
and most critically, the fate of the twelve legendary weapons.

He pays generously for ancient artifacts and will trade valuable items for historical information.

Mysterious Nature:
Several facts don't add up:
- He quotes from texts supposedly destroyed centuries ago
- He displays knowledge of events no record mentions
- Despite his age, he moves with a warrior's grace
- His magic, rarely displayed, is far more powerful than expected

Village Opinion:
Most villagers find him odd but harmless. Elder Aldwin watches him with barely concealed suspicion.
The two have been seen in heated discussion multiple times.

The Truth?:
Some speculate Theron is older than he appears - perhaps a survivor from the Shadow War itself,
preserved through magic. Others suggest he's a former guardian, carrying knowledge his order died protecting.

His true identity and motives remain unknown. But his arrival coinciding with the seal's weakening
seems too convenient to be coincidence.

One thing is certain: Theron knows far more than he admits, and his research may be crucial
to understanding and stopping the coming darkness.)";
        scholar->imagePath = "";
        scholar->discoveryTrigger = "quest_complete_main_quest_03";
        cache["character_scholar"] = scholar;

        // Character: The Dark Lord
        LoreEntry* darkLord = new LoreEntry();
        darkLord->entryId = "character_dark_lord";
        darkLord->category = "Characters";
        darkLord->title = "Lord Malachar, The Fallen";
        darkLord->shortDescription = "A hero who fell to corruption, now serving the Shadow Lord.";
        darkLord->fullText = R"(Lord Malachar was once the kingdom's greatest champion, but pride led to his fall.

The Hero Years:
For twenty years, Malachar defended the realm from countless threats.
He slew dragons, destroyed lich lords, and scattered bandit armies.
His victories were legendary, his courage unquestioned.

The Flaw:
But Malachar's greatest strength was also his weakness: unshakeable confidence in his own power.
He believed no force could corrupt him, no darkness could claim him.

The Fall:
When investigating shadow corruption, Malachar deliberately exposed himself, believing he could
resist and study the effect from within.

He was wrong.

The corruption took him slowly, so gradually he didn't recognize the change.
By the time he realized his error, it was too late. The hero became the villain.

Current State:
Now Malachar serves the Shadow Lord, commanding corrupted forces with the same tactical genius
he once used to defend the realm.

He retains his skills, his equipment, and fragmented memories of his heroic past.
This makes him far more dangerous than mindless corrupted creatures.

Tragic Encounters:
Those who have faced him and survived report the worst part is the moment of recognition
in his eyes - brief flashes where the real Malachar surfaces, realizes what he's become,
and screams in silent horror before the corruption retakes control.

Some believe he can be saved. Others argue the mercy is to end his torment permanently.
What is certain: defeating Malachar will require confronting not just his power,
but the tragedy of what he represents - the potential fate of any hero who stands against the darkness.)";
        darkLord->imagePath = "";
        darkLord->discoveryTrigger = "quest_complete_main_quest_06";
        cache["character_dark_lord"] = darkLord;

        // Character: Lost Hero
        LoreEntry* lostHero = new LoreEntry();
        lostHero->entryId = "character_lost_hero";
        lostHero->category = "Characters";
        lostHero->title = "Thornhaven the Lightbringer";
        lostHero->shortDescription = "The legendary hero who sealed the Shadow Lord three centuries ago.";
        lostHero->fullText = R"(Thornhaven the Lightbringer led the final assault that ended the Shadow War.

Origins:
Born to common farmers, Thornhaven showed no signs of greatness in youth.
The Shadow War changed that. When corruption claimed his village, he alone survived,
driven by grief and determination to a strength that surprised even him.

Rise to Legend:
He gathered heroes from the fallen kingdoms, united fractious armies under one banner,
and led assaults on the Shadow Lord's strongholds that all deemed suicide missions.

Against impossible odds, he succeeded. His victories inspired hope when despair had taken root.

The Final Battle:
At the Void Gate, Thornhaven faced the Shadow Lord directly. The battle lasted three days.
Witnesses reported reality itself warping from the clash of powers.

Thornhaven could not destroy the Shadow Lord - Void entities cannot be killed in our world.
Instead, he channeled the power of all twelve legendary weapons into a sealing ritual.

The Sacrifice:
The ritual required a life to power the seal. Thornhaven gave his own.
His final words: "May this seal last forever, or until a greater hero can finish what I began."

He was twenty-eight years old.

Legacy:
Thornhaven Village is named for him, built where he made his final stand.
Every child learns his story. His ideals of courage, sacrifice, and hope survive through generations.

The Mystery:
Some claim Thornhaven's spirit remains bound to the seal, sustaining it through sheer will.
Others believe his essence merged with the barrier itself.

Scholars point to unusual properties of the seal - it has lasted far longer than similar magic should.
Perhaps Thornhaven's sacrifice was more profound than simple death.

If the seal breaks, does he finally rest? Or does his torment continue in some form we cannot imagine?)";
        lostHero->imagePath = "";
        lostHero->discoveryTrigger = "quest_complete_main_quest_07";
        cache["character_lost_hero"] = lostHero;

        // ================================================================
        // PHASE 5 EXPANSION: Additional Location Entries
        // ================================================================

        // Location: Shadow Realm
        LoreEntry* shadowRealm = new LoreEntry();
        shadowRealm->entryId = "location_shadow_realm";
        shadowRealm->category = "Locations";
        shadowRealm->title = "The Shadow Realm";
        shadowRealm->shortDescription = "A pocket dimension where reality breaks down and nightmares manifest.";
        shadowRealm->fullText = R"(The Shadow Realm is not a place that exists in normal geography.

Nature:
It is a pocket dimension created by concentrated shadow corruption, existing in the space
between reality and the Void.

Entry Points:
Accessing the Shadow Realm requires passing through thin points in reality, often found
near areas of intense corruption. The heart of the Whispering Woods contains such a threshold.

Inside the Realm:
Physical laws bend or break entirely. Gravity is inconsistent. Time flows irregularly -
minutes inside may be hours outside, or vice versa.

The landscape shifts according to no logic. Paths that existed moments ago vanish.
Structures appear and disappear. The realm seems almost alive, aware of intruders.

Inhabitants:
Creatures within the Shadow Realm defy classification. Some are corrupted beings pulled from
reality. Others are manifestations of negative emotions given physical form.

Most disturbing are the "memories" - shadowy recreations of people and events from the past,
playing out fragments of scenes over and over with slight variations each time.

Danger:
Beyond the hostile inhabitants, the realm itself is deadly. Extended exposure causes
disorientation, paranoia, and eventual madness.

Those who spend too long inside risk being absorbed, becoming permanent residents of nightmare.

Purpose:
Why does the Shadow Realm exist? Some theorize it's a byproduct of the Shadow Lord's imprisonment -
corruption leaking from the seal, creating this twisted space.

Others believe it's deliberate, a staging ground where the Shadow Lord gathers power
and assembles forces for the moment the seal breaks.

Strategic Concern:
If the Shadow Realm continues expanding, it could eventually overlap with normal reality,
transforming the Whispering Woods permanently into this nightmarish state.

Entering it may be necessary to strengthen the seal, or to find the Shadow Lord's prison.
But those who venture inside may never return unchanged - if they return at all.)";
        shadowRealm->imagePath = "";
        shadowRealm->discoveryTrigger = "quest_complete_main_quest_06";
        cache["location_shadow_realm"] = shadowRealm;

        // Location: Ancient Temple
        LoreEntry* temple = new LoreEntry();
        temple->entryId = "location_ancient_temple";
        temple->category = "Locations";
        temple->title = "Temple of the Seal";
        temple->shortDescription = "The sacred site where the Shadow Lord was imprisoned.";
        temple->fullText = R"(Deep within the Whispering Woods lies the Temple of the Seal.

Original Purpose:
The temple predates the Shadow War by centuries. It was built by the ancient civilization
as a focal point for magical research and ritual.

When the Void Gate opened nearby, its proximity made it the natural location for the sealing ritual.

Architecture:
The temple combines practical fortification with ritual significance.
Outer walls form a perfect circle, inscribed with protective runes.
Inner chambers spiral downward in a geometric pattern designed to channel magical energy.

At its heart: the Seal Chamber.

The Seal:
The chamber contains a massive crystalline structure, pulsing with barely-contained energy.
Twelve alcoves surround it - one for each legendary weapon used in the original ritual.

The weapons themselves were consumed in the sealing, their power permanently bound into the barrier.
This explains why the twelve weapons have never been found - they no longer exist as physical objects.

Current State:
The temple shows severe degradation. Three centuries of neglect have taken their toll.
Support pillars crack, magical runes fade, and most critically, the seal shows fractures.

Shadow energy leaks through these cracks, corrupting the surrounding forest.

Guardian Absence:
The guardian order once maintained the temple, performing regular reinforcement rituals.
Without them, entropy accelerates.

Recent Intrusion:
Something has been attacking the temple from within. Deep claw marks scar the walls of the Seal Chamber.
Whatever is trapped on the other side is no longer dormant.

Mission Critical:
Reaching the temple and assessing the seal's condition is vital. If it can be reinforced, disaster might
be averted. If not, preparation for the Shadow Lord's emergence becomes paramount.

The temple may also contain knowledge - ritual texts, historical records, or artifacts that could aid
in the coming conflict. But entering means facing whatever corrupted guardians lurk within,
and risking exposure to concentrated shadow energy.

The choice is stark: avoid the temple and face the Shadow Lord unprepared,
or risk everything to gain knowledge and potentially strengthen the seal.)";
        temple->imagePath = "";
        temple->discoveryTrigger = "quest_complete_final_quest";
        cache["location_ancient_temple"] = temple;

        // Location: Void Gate
        LoreEntry* voidGate = new LoreEntry();
        voidGate->entryId = "location_void_gate";
        voidGate->category = "Locations";
        voidGate->title = "The Void Gate";
        voidGate->shortDescription = "The tear in reality through which the Shadow Lord entered our world.";
        voidGate->fullText = R"(The Void Gate is reality's wound, and three hundred years have not healed it.

Discovery:
Ancient records place the gate's opening at coordinates that now lie beneath the Temple of the Seal.
It wasn't created deliberately - it tore open spontaneously, a catastrophic failure in the fabric of existence.

The cause remains unknown. Natural instability? Magical catastrophe? Deliberate action by Void entities?

Appearance:
Those who witnessed it before the sealing described a vertical rip in space itself.
Through it, the absolute black of the Void was visible - not darkness, but true absence.

Looking at it caused physical pain and psychological trauma. Several observers went mad,
their minds unable to process the fundamental wrongness of what they saw.

The Shadow Lord emerged through this tear, followed by legions of Void spawn.

The Sealing:
Closing the gate proved impossible. It could only be locked from this side,
with the Shadow Lord trapped halfway between our world and the Void.

The seal is essentially a magical lock on an open door. It prevents passage but doesn't close the opening.

Current Status:
The gate still exists behind the seal. As the barrier weakens, more of the gate's nature becomes visible.

Scholars who have studied the seal in recent months report disturbing developments:
The gate appears to be widening. Whatever force created it initially continues to pull reality apart.

Implications:
If the seal breaks completely, the gate will reopen fully. The Shadow Lord will emerge,
but that may be the least of our problems.

A fully open Void Gate could allow unlimited Void entities to enter our world.
The Shadow War would look like a minor skirmish compared to full-scale Void invasion.

Closing the Gate:
No one knows if permanent closure is possible. Ancient texts hint at a ritual requiring
immense power - possibly more than currently exists in our world.

Some speculate that the legendary weapons, if reconstituted, might provide enough energy.
Others believe only divine intervention could seal a wound this fundamental.

The gate represents an existential threat to reality itself. Defeating the Shadow Lord means nothing
if the gate remains open. Yet we have no answer for how to close it.

This is the true crisis: not merely a powerful enemy, but a hole in existence that grows wider each day.)";
        voidGate->imagePath = "";
        voidGate->discoveryTrigger = "quest_complete_final_quest";
        cache["location_void_gate"] = voidGate;
    }

    return cache.value(entryId, nullptr);
}

QList<LoreEntry*> LoreFactory::getAllLoreEntries()
{
    static QList<LoreEntry*> allEntries;

    if (allEntries.isEmpty()) {
        // Bestiary (8 total)
        allEntries.append(createLoreEntry("bestiary_goblin"));
        allEntries.append(createLoreEntry("bestiary_shadow_wolf"));
        allEntries.append(createLoreEntry("bestiary_orc"));
        allEntries.append(createLoreEntry("bestiary_dark_mage"));
        allEntries.append(createLoreEntry("bestiary_stone_golem"));
        allEntries.append(createLoreEntry("bestiary_corrupted_guardian"));
        allEntries.append(createLoreEntry("bestiary_ancient_dragon"));
        allEntries.append(createLoreEntry("bestiary_shadow_lord"));

        // Items (6 total)
        allEntries.append(createLoreEntry("item_healing_potion"));
        allEntries.append(createLoreEntry("item_ancient_sword"));
        allEntries.append(createLoreEntry("item_mana_potion"));
        allEntries.append(createLoreEntry("item_legendary_armor"));
        allEntries.append(createLoreEntry("item_magic_staff"));
        allEntries.append(createLoreEntry("item_cursed_ring"));

        // World (6 total)
        allEntries.append(createLoreEntry("world_whispering_woods"));
        allEntries.append(createLoreEntry("world_ancient_war"));
        allEntries.append(createLoreEntry("world_fall_kingdoms"));
        allEntries.append(createLoreEntry("world_prophecy"));
        allEntries.append(createLoreEntry("world_the_void"));
        allEntries.append(createLoreEntry("world_shadow_corruption"));

        // Characters (5 total)
        allEntries.append(createLoreEntry("character_village_elder"));
        allEntries.append(createLoreEntry("character_merchant"));
        allEntries.append(createLoreEntry("character_scholar"));
        allEntries.append(createLoreEntry("character_dark_lord"));
        allEntries.append(createLoreEntry("character_lost_hero"));

        // Locations (5 total)
        allEntries.append(createLoreEntry("location_thornhaven"));
        allEntries.append(createLoreEntry("location_old_ruins"));
        allEntries.append(createLoreEntry("location_shadow_realm"));
        allEntries.append(createLoreEntry("location_ancient_temple"));
        allEntries.append(createLoreEntry("location_void_gate"));
    }

    return allEntries;
}

QList<LoreEntry*> LoreFactory::getLoreByCategory(const QString &category)
{
    QList<LoreEntry*> categoryEntries;
    QList<LoreEntry*> allEntries = getAllLoreEntries();

    for (LoreEntry* entry : allEntries) {
        if (entry && entry->category == category) {
            categoryEntries.append(entry);
        }
    }

    return categoryEntries;
}
