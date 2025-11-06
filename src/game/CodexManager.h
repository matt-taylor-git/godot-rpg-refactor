#ifndef CODEXMANAGER_H
#define CODEXMANAGER_H

#include "models/LoreEntry.h"
#include "models/Player.h"
#include <QObject>
#include <QMap>
#include <QList>
#include <QString>

class CodexManager : public QObject
{
    Q_OBJECT

public:
    explicit CodexManager(Player* player, QObject* parent = nullptr);
    ~CodexManager();

    // Lore management
    void loadLoreEntries();
    void checkDiscoveryTriggers(const QString &triggerString);
    void unlockEntry(const QString &entryId);
    LoreEntry* getEntry(const QString &entryId) const;
    QList<LoreEntry*> getUnlockedEntries(const QString &category) const;
    QList<LoreEntry*> getAllEntriesInCategory(const QString &category) const;

    // Event handlers (connected to game signals)
    void onEnemyKilled(const QString &enemyName);
    void onQuestCompleted(const QString &questId);
    void onItemCollected(const QString &itemName);

signals:
    void loreUnlocked(const QString &entryId, const QString &title);

private:
    Player* m_player;  // Reference, not owned
    QMap<QString, LoreEntry*> m_loreMap;  // All lore, owned by factory
    QMap<QString, QList<LoreEntry*>> m_categoryMap;  // Entries by category
    QMap<QString, int> m_killCounts;  // Track kill counts per enemy
};

#endif // CODEXMANAGER_H
