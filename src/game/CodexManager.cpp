#include "CodexManager.h"
#include "factories/LoreFactory.h"
#include <QDebug>

CodexManager::CodexManager(Player* player, QObject* parent)
    : QObject(parent)
    , m_player(player)
{
}

CodexManager::~CodexManager()
{
    // Lore entries are managed by factory static cache, don't delete them here
    m_loreMap.clear();
    m_categoryMap.clear();
}

void CodexManager::loadLoreEntries()
{
    QList<LoreEntry*> entries = LoreFactory::getAllLoreEntries();
    for (LoreEntry* entry : entries) {
        if (entry) {
            m_loreMap[entry->entryId] = entry;
            m_categoryMap[entry->category].append(entry);
        }
    }
    qDebug() << "Loaded" << m_loreMap.size() << "lore entries";
}

void CodexManager::checkDiscoveryTriggers(const QString &triggerString)
{
    for (LoreEntry* entry : m_loreMap.values()) {
        if (entry->discoveryTrigger == triggerString) {
            unlockEntry(entry->entryId);
        }
    }
}

void CodexManager::unlockEntry(const QString &entryId)
{
    // Check if already unlocked
    if (m_player->hasUnlockedLore(entryId)) {
        return;
    }

    m_player->unlockLore(entryId);

    LoreEntry* entry = m_loreMap.value(entryId, nullptr);
    if (entry) {
        emit loreUnlocked(entryId, entry->title);
    }
}

LoreEntry* CodexManager::getEntry(const QString &entryId) const
{
    return m_loreMap.value(entryId, nullptr);
}

QList<LoreEntry*> CodexManager::getUnlockedEntries(const QString &category) const
{
    QList<LoreEntry*> result;

    for (LoreEntry* entry : m_categoryMap.value(category)) {
        if (m_player->hasUnlockedLore(entry->entryId)) {
            result.append(entry);
        }
    }

    return result;
}

QList<LoreEntry*> CodexManager::getAllEntriesInCategory(const QString &category) const
{
    return m_categoryMap.value(category);
}

void CodexManager::onEnemyKilled(const QString &enemyName)
{
    // Track kill counts per enemy
    m_killCounts[enemyName]++;

    int kills = m_killCounts[enemyName];
    QString trigger = QString("kill_%1_%2").arg(enemyName).arg(kills);

    qDebug() << "Enemy killed:" << enemyName << "Count:" << kills << "Trigger:" << trigger;
    checkDiscoveryTriggers(trigger);
}

void CodexManager::onQuestCompleted(const QString &questId)
{
    QString trigger = QString("quest_complete_%1").arg(questId);
    checkDiscoveryTriggers(trigger);
}

void CodexManager::onItemCollected(const QString &itemName)
{
    QString trigger = QString("item_get_%1").arg(itemName);
    checkDiscoveryTriggers(trigger);
}
