#include "QuestManager.h"
#include "factories/QuestFactory.h"
#include "factories/ItemFactory.h"

QuestManager::QuestManager(Player* player, QObject *parent)
    : QObject(parent), m_player(player)
{
}

QuestManager::~QuestManager()
{
    // Clean up quest definitions (player owns their active quests)
    qDeleteAll(m_allQuests);
    m_allQuests.clear();
    m_questMap.clear();
}

void QuestManager::loadQuests()
{
    qDebug() << "QuestManager::loadQuests() called";
    // Load all main quest definitions
    m_allQuests = QuestFactory::getAllMainQuests();
    qDebug() << "Loaded" << m_allQuests.size() << "quests";

    // Build quick lookup map
    for (Quest* quest : m_allQuests) {
        if (quest) {
            m_questMap[quest->questId] = quest;
        }
    }

    // Check if player already has quests (loaded from save)
    if (m_player && m_player->quests.isEmpty()) {
        qDebug() << "New game detected - auto-activating first quest";
        // New game - activate first quest
        if (!m_allQuests.isEmpty()) {
            Quest* firstQuest = m_allQuests.first();
            qDebug() << "First quest:" << firstQuest->questId << "status:" << firstQuest->status;
            if (firstQuest && firstQuest->status == "available") {
                qDebug() << "Calling acceptQuest() for" << firstQuest->questId;
                acceptQuest(firstQuest->questId);
                qDebug() << "acceptQuest() returned";
            }
        }
    } else if (m_player) {
        qDebug() << "Loaded game - player has" << m_player->quests.size() << "quests";
        // Sync loaded player quests with our quest definitions
        // Update quest definitions to match player's quest state
        for (Quest* playerQuest : m_player->quests) {
            if (playerQuest && m_questMap.contains(playerQuest->questId)) {
                Quest* defQuest = m_questMap[playerQuest->questId];
                // Copy state from player's quest to our definition
                defQuest->status = playerQuest->status;
                defQuest->objectives = playerQuest->objectives;
            }
        }
    }

    // Check for newly unlocked quests
    checkQuestUnlocks();
    qDebug() << "QuestManager::loadQuests() completed";
}

bool QuestManager::acceptQuest(const QString &questId)
{
    qDebug() << "QuestManager::acceptQuest() called with questId:" << questId;
    Quest* quest = m_questMap.value(questId, nullptr);
    if (!quest || !m_player) {
        qDebug() << "QuestManager::acceptQuest() failed - quest or player is null";
        return false;
    }

    // Can only accept available quests
    if (quest->status != "available") {
        qDebug() << "QuestManager::acceptQuest() failed - quest status is" << quest->status << "not 'available'";
        return false;
    }

    qDebug() << "QuestManager::acceptQuest() accepting quest";
    // Change status to active
    quest->status = "active";

    // Add to player's quest list if not already there
    if (!m_player->getQuest(questId)) {
        m_player->addQuest(new Quest(*quest)); // Add copy to player
    } else {
        // Update existing quest in player's list
        Quest* playerQuest = m_player->getQuest(questId);
        if (playerQuest) {
            playerQuest->status = "active";
        }
    }

    qDebug() << "QuestManager::acceptQuest() EMITTING questAccepted signal";
    emit questAccepted(questId);
    qDebug() << "QuestManager::acceptQuest() signal emitted";
    return true;
}

void QuestManager::updateQuestProgress(const QString &questId, int objIndex, int progress)
{
    Quest* quest = m_questMap.value(questId, nullptr);
    if (!quest || !m_player) {
        return;
    }

    // Also update player's copy
    Quest* playerQuest = m_player->getQuest(questId);
    if (!playerQuest) {
        return;
    }

    // Update both copies
    quest->updateObjective(objIndex, progress);
    playerQuest->updateObjective(objIndex, progress);

    emit questProgressed(questId, objIndex);

    // Check if all objectives are now complete
    if (checkObjectivesComplete(quest)) {
        completeQuest(questId);
    }
}

void QuestManager::completeQuest(const QString &questId)
{
    Quest* quest = m_questMap.value(questId, nullptr);
    if (!quest || !m_player) {
        return;
    }

    // Can only complete active quests
    if (quest->status != "active") {
        return;
    }

    // Verify all objectives are actually complete
    if (!checkObjectivesComplete(quest)) {
        return;
    }

    // Change status
    quest->status = "completed";
    Quest* playerQuest = m_player->getQuest(questId);
    if (playerQuest) {
        playerQuest->status = "completed";
    }

    // Give rewards
    giveQuestRewards(quest);

    // Emit completion signal
    emit questCompleted(questId, quest->rewards.experience, quest->rewards.gold);

    // Check if new quests unlock
    checkQuestUnlocks();
}

Quest* QuestManager::getQuestById(const QString &questId) const
{
    return m_questMap.value(questId, nullptr);
}

void QuestManager::onCombatEnd(const QString &enemyName)
{
    if (!m_player) {
        return;
    }

    // Get active quests from player
    QList<Quest*> activeQuests = m_player->getActiveQuests();

    // Check each active quest for matching kill objectives
    for (Quest* playerQuest : activeQuests) {
        if (!playerQuest) continue;

        for (int i = 0; i < playerQuest->objectives.size(); ++i) {
            QuestObjective &obj = playerQuest->objectives[i];

            // Check if this objective matches the killed enemy
            if ((obj.type == "kill_enemies" || obj.type == "defeat_boss") &&
                QString::compare(obj.targetId, enemyName, Qt::CaseInsensitive) == 0 &&
                !obj.completed) {

                // Update progress
                updateQuestProgress(playerQuest->questId, i, 1);
            }
        }
    }
}

void QuestManager::onLevelUp(int newLevel)
{
    if (!m_player) {
        return;
    }

    // Get active quests from player
    QList<Quest*> activeQuests = m_player->getActiveQuests();

    // Check each active quest for level objectives
    for (Quest* playerQuest : activeQuests) {
        if (!playerQuest) continue;

        for (int i = 0; i < playerQuest->objectives.size(); ++i) {
            QuestObjective &obj = playerQuest->objectives[i];

            // Check if this is a level objective
            if (obj.type == "reach_level" && !obj.completed) {
                // If player reached or exceeded required level
                if (newLevel >= obj.required) {
                    // Set progress to required amount
                    int progressNeeded = obj.required - obj.current;
                    updateQuestProgress(playerQuest->questId, i, progressNeeded);
                }
            }
        }
    }

    // Also check if new quests can be unlocked based on level
    checkQuestUnlocks();
}

void QuestManager::onItemCollected(const QString &itemName)
{
    if (!m_player) {
        return;
    }

    // Get active quests from player
    QList<Quest*> activeQuests = m_player->getActiveQuests();

    // Check each active quest for item collection objectives
    for (Quest* playerQuest : activeQuests) {
        if (!playerQuest) continue;

        for (int i = 0; i < playerQuest->objectives.size(); ++i) {
            QuestObjective &obj = playerQuest->objectives[i];

            // Check if this objective matches the collected item
            if (obj.type == "collect_item" &&
                obj.targetId == itemName &&
                !obj.completed) {

                // Update progress
                updateQuestProgress(playerQuest->questId, i, 1);
            }
        }
    }
}

QList<Quest*> QuestManager::getActiveQuests() const
{
    if (!m_player) {
        return QList<Quest*>();
    }
    return m_player->getActiveQuests();
}

QList<Quest*> QuestManager::getAvailableQuests() const
{
    QList<Quest*> available;
    for (Quest* quest : m_allQuests) {
        if (quest && quest->status == "available") {
            available.append(quest);
        }
    }
    return available;
}

QList<Quest*> QuestManager::getCompletedQuests() const
{
    if (!m_player) {
        return QList<Quest*>();
    }
    return m_player->getCompletedQuests();
}

QList<Quest*> QuestManager::getLockedQuests() const
{
    QList<Quest*> locked;
    for (Quest* quest : m_allQuests) {
        if (quest && quest->status == "locked") {
            locked.append(quest);
        }
    }
    return locked;
}

// Private helper methods

void QuestManager::checkQuestUnlocks()
{
    if (!m_player) {
        return;
    }

    // Check all locked quests to see if they can be unlocked
    for (Quest* quest : m_allQuests) {
        if (!quest || quest->status != "locked") {
            continue;
        }

        // Check level requirement
        if (m_player->level < quest->minimumLevel) {
            continue;
        }

        // Check prerequisites
        bool prereqsMet = true;
        for (const QString &prereqId : quest->prerequisiteQuestIds) {
            Quest* prereqQuest = m_player->getQuest(prereqId);
            if (!prereqQuest || !prereqQuest->isComplete()) {
                prereqsMet = false;
                break;
            }
        }

        // If all requirements met, unlock quest
        if (prereqsMet) {
            quest->status = "available";
            emit questAvailable(quest->questId);
        }
    }
}

bool QuestManager::checkObjectivesComplete(Quest* quest)
{
    if (!quest) {
        return false;
    }

    // All objectives must be completed
    for (const QuestObjective &obj : quest->objectives) {
        if (!obj.completed) {
            return false;
        }
    }

    return !quest->objectives.isEmpty(); // At least one objective must exist
}

void QuestManager::giveQuestRewards(Quest* quest)
{
    if (!quest || !m_player) {
        return;
    }

    // Give experience
    m_player->gainExperience(quest->rewards.experience);

    // Give gold
    m_player->gold += quest->rewards.gold;

    // Give items
    for (const QString &itemName : quest->rewards.itemNames) {
        Item* item = ItemFactory::createItem(itemName);
        if (item) {
            m_player->inventory.append(item);
            // Unlock lore entry if item has associated lore (Phase 5)
            if (!item->loreId.isEmpty()) {
                if (!m_player->hasUnlockedLore(item->loreId)) {
                    m_player->unlockLore(item->loreId);
                    // Signal will be caught by CodexManager via Game connections
                }
            }
        }
    }
}
