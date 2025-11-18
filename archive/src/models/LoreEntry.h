#ifndef LOREENTRY_H
#define LOREENTRY_H

#include <QString>

// Lore codex entry for world-building
struct LoreEntry {
    QString entryId;              // "bestiary_goblin", "world_ancient_war"
    QString category;             // "Bestiary", "Items", "World", "Characters", "Locations"
    QString title;                // "Goblin"
    QString shortDescription;     // "Small, cunning creatures that hunt in packs."
    QString fullText;             // Multi-line lore text
    QString imagePath;            // ":/assets/goblin.png" or empty
    QString discoveryTrigger;     // "kill_Goblin_5", "quest_complete_main_quest_01", "item_get_Ancient_Tome"

    LoreEntry() {}
};

#endif // LOREENTRY_H
