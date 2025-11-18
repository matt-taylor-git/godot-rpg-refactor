#ifndef LOREFACTORY_H
#define LOREFACTORY_H

#include "models/LoreEntry.h"
#include <QList>
#include <QString>

class LoreFactory
{
public:
    // Get specific lore entry by ID
    static LoreEntry* createLoreEntry(const QString &entryId);

    // Get all lore entries
    static QList<LoreEntry*> getAllLoreEntries();

    // Get lore entries by category
    static QList<LoreEntry*> getLoreByCategory(const QString &category);

private:
    LoreFactory() = delete;  // Prevent instantiation
};

#endif // LOREFACTORY_H
