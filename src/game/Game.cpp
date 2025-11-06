#include "Game.h"
#include "factories/MonsterFactory.h"
#include "factories/SkillFactory.h"
#include "factories/ItemFactory.h"
#include "../models/FinalBoss.h"
#include <QRandomGenerator>

Game::Game(QObject *parent)
: QObject(parent), player(nullptr), currentMonster(nullptr), combatActive(false), m_questManager(nullptr),
  m_dialogueManager(nullptr), m_storyManager(nullptr), m_codexManager(nullptr)
{
}

Game::~Game()
{
    if (player) {
        delete player;
    }
    if (currentMonster) {
        delete currentMonster;
    }
    if (m_questManager) {
        delete m_questManager;
    }
    if (m_dialogueManager) {
        delete m_dialogueManager;
    }
    if (m_storyManager) {
        delete m_storyManager;
    }
    if (m_codexManager) {
        delete m_codexManager;
    }
}

void Game::newGame(const QString &playerName, const QString &characterClass)
{
    // Clean up old player object if it exists
    if (player) {
        delete player;
    }
    player = new Player(playerName, characterClass);

    // Initialize game start time for playtime tracking
    m_gameStartTime = QTime::currentTime();

    // Give starting skills
    QList<Skill*> startingSkills = SkillFactory::getStartingSkills(characterClass);
    for (Skill* skill : startingSkills) {
        player->learnSkill(skill);
    }

    // Create and initialize QuestManager
    if (m_questManager) {
        delete m_questManager;
    }
    m_questManager = new QuestManager(player, this);

    // Create and initialize narrative managers (Phase 3)
    if (m_dialogueManager) {
        delete m_dialogueManager;
    }
    m_dialogueManager = new DialogueManager(player, this);
    m_dialogueManager->loadDialogues();

    if (m_storyManager) {
        delete m_storyManager;
    }
    m_storyManager = new StoryManager(player, this);
    m_storyManager->loadEvents();

    if (m_codexManager) {
        delete m_codexManager;
    }
    m_codexManager = new CodexManager(player, this);
    m_codexManager->loadLoreEntries();

    // Connect manager signals BEFORE loading quests
    // This ensures that when quests are auto-accepted, story events are triggered
    connect(m_questManager, &QuestManager::questAccepted, m_storyManager, &StoryManager::onQuestStarted, Qt::UniqueConnection);
    connect(m_questManager, &QuestManager::questCompleted, m_storyManager, &StoryManager::onQuestCompleted, Qt::UniqueConnection);
    connect(m_questManager, &QuestManager::questCompleted, m_codexManager, &CodexManager::onQuestCompleted, Qt::UniqueConnection);

    // NOTE: loadQuests() is now called by MainWindow AFTER it connects to StoryManager signals
    // This ensures the tutorial event displays properly on character creation
}

Player* Game::getPlayer()
{
return player;
}

Monster* Game::getCurrentMonster()
{
    return currentMonster;
}

QuestManager* Game::getQuestManager()
{
    return m_questManager;
}

DialogueManager* Game::getDialogueManager()
{
    return m_dialogueManager;
}

StoryManager* Game::getStoryManager()
{
    return m_storyManager;
}

CodexManager* Game::getCodexManager()
{
    return m_codexManager;
}

bool Game::saveGame(const QString &filePath)
{
    if (!player) return false;
    return saveManager.saveGame(player, filePath);
}

bool Game::loadGame(const QString &filePath)
{
Player *loadedPlayer = saveManager.loadGame(filePath);
if (!loadedPlayer) return false;
if (player) {
delete player;
}
player = loadedPlayer;

// Recreate QuestManager for loaded player
if (m_questManager) {
    delete m_questManager;
}
m_questManager = new QuestManager(player, this);

// Recreate narrative managers (Phase 3)
if (m_dialogueManager) {
    delete m_dialogueManager;
}
m_dialogueManager = new DialogueManager(player, this);
m_dialogueManager->loadDialogues();

if (m_storyManager) {
    delete m_storyManager;
}
m_storyManager = new StoryManager(player, this);
m_storyManager->loadEvents();

if (m_codexManager) {
    delete m_codexManager;
}
m_codexManager = new CodexManager(player, this);
m_codexManager->loadLoreEntries();

// Connect manager signals BEFORE loading quests
connect(m_questManager, &QuestManager::questAccepted, m_storyManager, &StoryManager::onQuestStarted, Qt::UniqueConnection);
connect(m_questManager, &QuestManager::questCompleted, m_storyManager, &StoryManager::onQuestCompleted, Qt::UniqueConnection);
connect(m_questManager, &QuestManager::questCompleted, m_codexManager, &CodexManager::onQuestCompleted, Qt::UniqueConnection);

// Load quests AFTER connections are made
m_questManager->loadQuests();

return true;
}

bool Game::saveToSlot(int slotNumber)
{
    if (!player) return false;
    return saveManager.saveToSlot(player, slotNumber);
}

bool Game::loadFromSlot(int slotNumber)
{
    Player *loadedPlayer = saveManager.loadFromSlot(slotNumber);
    if (!loadedPlayer) return false;
    if (player) {
        delete player;
    }
    player = loadedPlayer;

    // Recreate QuestManager for loaded player
    if (m_questManager) {
        delete m_questManager;
    }
    m_questManager = new QuestManager(player, this);

    // Recreate narrative managers (Phase 3)
    if (m_dialogueManager) {
        delete m_dialogueManager;
    }
    m_dialogueManager = new DialogueManager(player, this);
    m_dialogueManager->loadDialogues();

    if (m_storyManager) {
        delete m_storyManager;
    }
    m_storyManager = new StoryManager(player, this);
    m_storyManager->loadEvents();

    if (m_codexManager) {
        delete m_codexManager;
    }
    m_codexManager = new CodexManager(player, this);
    m_codexManager->loadLoreEntries();

    // Connect manager signals BEFORE loading quests
    connect(m_questManager, &QuestManager::questAccepted, m_storyManager, &StoryManager::onQuestStarted, Qt::UniqueConnection);
    connect(m_questManager, &QuestManager::questCompleted, m_storyManager, &StoryManager::onQuestCompleted, Qt::UniqueConnection);
    connect(m_questManager, &QuestManager::questCompleted, m_codexManager, &CodexManager::onQuestCompleted, Qt::UniqueConnection);

    // NOTE: loadQuests() is now called by MainWindow AFTER it connects to StoryManager signals
    // This ensures the tutorial event displays properly on character creation

    return true;
}

bool Game::deleteSlot(int slotNumber)
{
    return saveManager.deleteSaveSlot(slotNumber);
}

// Combat
void Game::startCombat()
{
    // Create a random monster based on player level
    if (currentMonster) {
        delete currentMonster;
    }

    // Check if player has active quest objectives requiring specific monsters
    QString questMonsterType;
    if (m_questManager) {
        QList<Quest*> activeQuests = m_questManager->getActiveQuests();
        for (Quest* quest : activeQuests) {
            if (!quest) continue;

            for (const QuestObjective &obj : quest->objectives) {
                // Check for incomplete kill objectives
                if ((obj.type == "kill_enemies" || obj.type == "defeat_boss") && !obj.completed) {
                    questMonsterType = obj.targetId;
                    break;
                }
            }
            if (!questMonsterType.isEmpty()) {
                break;
            }
        }
    }

    // Spawn quest-specific monster or random monster
    if (!questMonsterType.isEmpty()) {
        // Try to create the quest monster
        currentMonster = MonsterFactory::createMonster(questMonsterType, player->level);
        if (currentMonster && currentMonster->name != "Unknown Beast") {
            combatActive = true;
            combatLog = QString("Combat started! A %1 (Level %2) appears!").arg(currentMonster->name).arg(currentMonster->level);
            return;
        }
        // Fall back to random if quest monster creation failed
        if (currentMonster) {
            delete currentMonster;
            currentMonster = nullptr;
        }
    }

    // Default: create a random monster
    currentMonster = MonsterFactory::createRandomMonster(player->level);
    combatActive = true;
    combatLog = QString("Combat started! A %1 (Level %2) appears!").arg(currentMonster->name).arg(currentMonster->level);
}

QString Game::playerAttack()
{
    if (!combatActive || !currentMonster || !player) return "";

    bool critical = rollCritical(player->dexterity);
    int baseDamage = player->getTotalAttack();
    int damage = calculateDamage(baseDamage, player->level, currentMonster->defense, critical);

    currentMonster->health -= damage;

    if (critical) {
        combatLog = QString("**CRITICAL HIT!** You strike for %1 damage!").arg(damage);
    } else {
        combatLog = QString("You attack for %1 damage!").arg(damage);
    }

    // Check for boss phase transitions (before combat end check)
    if (FinalBoss* boss = dynamic_cast<FinalBoss*>(currentMonster)) {
        boss->updatePhase();
        if (boss->shouldEmitPhaseTransition()) {
            emit bossPhaseChanged(boss->getCurrentPhase());
            combatLog += QString("\n\n=== PHASE %1 ===\n%2\n")
                .arg(boss->getCurrentPhase())
                .arg(boss->getPhaseDescription());
        }
    }

    if (currentMonster->health <= 0) {
        currentMonster->health = 0;
        combatLog += QString(" %1 defeated!").arg(currentMonster->name);
    }

    checkCombatEndAfterAction();
    return combatLog;
}

QString Game::playerUseSkill(Skill* skill)
{
    if (!combatActive || !currentMonster || !player || !skill) return "";

    // Check mana
    if (player->mana < skill->manaCost) {
        return "Not enough mana!";
    }

    player->mana -= skill->manaCost;

    if (skill->skillType == "physical") {
        bool critical = rollCritical(player->dexterity);
        int baseDamage = player->getTotalAttack() + skill->damage;
        int damage = calculateDamage(baseDamage, player->level, currentMonster->defense, critical);
        currentMonster->health -= damage;

        if (critical) {
            combatLog = QString("**CRITICAL!** %1 deals %2 damage!").arg(skill->name).arg(damage);
        } else {
            combatLog = QString("%1 deals %2 damage!").arg(skill->name).arg(damage);
        }
    }
    else if (skill->skillType == "magic") {
        int baseDamage = (player->intelligence * 2) + skill->damage;
        int damage = calculateDamage(baseDamage, player->level, currentMonster->defense / 2); // Magic ignores some defense
        currentMonster->health -= damage;
        combatLog = QString("%1 hits for %2 magic damage!").arg(skill->name).arg(damage);
    }
    else if (skill->skillType == "buff") {
        combatLog = QString("You use %1! (Effect lasts 3 turns)").arg(skill->name);
        // TODO: Implement buff system properly when status effects are added
    }

    if (currentMonster->health <= 0) {
        currentMonster->health = 0;
        combatLog += QString(" %1 defeated!").arg(currentMonster->name);
    }

    checkCombatEndAfterAction();
    return combatLog;
}

QString Game::playerUseItem(Item* item)
{
    if (!combatActive || !player || !item) return "";

    QString itemName = item->name;  // Save name before deletion

    if (item->effect == "heal") {
        int oldHealth = player->health;
        player->useItem(item);
        int healed = player->health - oldHealth;
        delete item;  // Caller must delete item after use to prevent memory leak
        return QString("Used %1! Restored %2 HP.").arg(itemName).arg(healed);
    }
    else if (item->effect == "restore_mana") {
        int oldMana = player->mana;
        player->useItem(item);
        int restored = player->mana - oldMana;
        delete item;  // Caller must delete item after use to prevent memory leak
        return QString("Used %1! Restored %2 MP.").arg(itemName).arg(restored);
    }

    return "Item has no effect in combat.";
}

QString Game::monsterAttack()
{
    if (!combatActive || !currentMonster || !player) return "";

    int baseDamage = currentMonster->attack;

    // Apply boss phase multiplier
    if (FinalBoss* boss = dynamic_cast<FinalBoss*>(currentMonster)) {
        int multiplier = boss->getPhaseAttackMultiplier();
        baseDamage = (baseDamage * multiplier) / 100;  // Scale by percentage
    }

    int damage = calculateDamage(baseDamage, currentMonster->level, player->getTotalDefense());

    player->health -= damage;

    combatLog = QString("%1 attacks for %2 damage!").arg(currentMonster->name).arg(damage);

    if (player->health <= 0) {
        player->health = 0;
        combatLog += " You are defeated!";
    }

    checkCombatEndAfterAction();
    return combatLog;
}

bool Game::isCombatOver()
{
    return !combatActive;
}

QString Game::getCombatResult()
{
    if (!player || !currentMonster) return "";

    if (player->health <= 0) {
        return "Defeat";
    } else if (currentMonster->health <= 0) {
        return "Victory";
    }
    return "Ongoing";
}

void Game::endCombat()
{
    if (!combatActive) return;

    combatActive = false;

    bool playerWon = (currentMonster && currentMonster->health <= 0 && player && player->health > 0);

    // If player won, give rewards
    if (playerWon) {
        giveCombatRewards();

        // FINAL BOSS VICTORY DETECTION
        if (currentMonster && currentMonster->enemyType == "final_boss") {
            // Mark player as game completer
            player->hasDefeatedFinalBoss = true;
            player->gameCompletionTime = QDateTime::currentDateTime().toString(Qt::ISODate);
            player->finalGameLevel = player->level;

            // Emit completion signals
            emit finalBossDefeated();
            emit gameCompleted(player->level, calculatePlaytimeMinutes());
        }
    }
}

bool Game::isInCombat() const
{
    return combatActive;
}

int Game::calculateDamage(int baseDamage, int attackerLevel, int defenderDefense, bool isCritical)
{
    // Base formula: damage = baseDamage * levelMultiplier - defense
    double levelMultiplier = 1.0 + (attackerLevel * 0.1);

    // Prevent overflow: cap the multiplier at a reasonable maximum
    if (levelMultiplier > 10.0) levelMultiplier = 10.0;

    // Use long long to prevent overflow during multiplication
    long long calculatedDamage = static_cast<long long>(baseDamage) * levelMultiplier;
    int damage = static_cast<int>(calculatedDamage) - defenderDefense;

    // Apply critical multiplier
    if (isCritical) {
        damage = static_cast<int>(static_cast<long long>(damage) * 1.75);
    }

    // Minimum damage is 1
    if (damage < 1) damage = 1;

    // Add some variance (±10%) - ensure bounded argument is positive
    int varianceUpper = damage / 5;
    int varianceLower = damage / 10;

    // Ensure variance bounds are valid
    if (varianceUpper <= 0) varianceUpper = 1;
    if (varianceLower < 0) varianceLower = 0;

    int variance = QRandomGenerator::global()->bounded(varianceUpper) - varianceLower;
    damage += variance;

    return damage > 0 ? damage : 1;
}

bool Game::rollCritical(int dexterity)
{
    // Base crit chance: 5% + (dexterity * 0.5%)
    int critChance = 5 + (dexterity / 2);
    if (critChance > 50) critChance = 50; // Cap at 50%

    int roll = QRandomGenerator::global()->bounded(100);
    return roll < critChance;
}

void Game::giveCombatRewards()
{
    if (!player || !currentMonster) return;

    // Store old level to detect level ups
    int oldLevel = player->level;

    // Give experience
    int expGained = currentMonster->expReward;

    // Final boss gets 2x XP multiplier
    if (currentMonster->enemyType == "final_boss") {
        expGained *= 2;
    }

    player->gainExperience(expGained);

    // Check if player leveled up and notify quest manager
    if (m_questManager && player->level > oldLevel) {
        m_questManager->onLevelUp(player->level);
    }

    // Give gold
    int goldGained = currentMonster->goldReward;
    player->gold += goldGained;

    // Random loot drop (30% chance)
    int lootRoll = QRandomGenerator::global()->bounded(100);
    if (lootRoll < 30) {
        Item* loot = ItemFactory::generateRandomItem(currentMonster->level);
        if (loot) {
            player->inventory.append(loot);
            combatLog += QString("\nFound loot: %1!").arg(loot->name);
            // Notify quest manager about item collection
            if (m_questManager) {
                m_questManager->onItemCollected(loot->name);
            }
            // Unlock lore entry if item has associated lore (Phase 5)
            if (!loot->loreId.isEmpty() && m_codexManager) {
                m_codexManager->unlockEntry(loot->loreId);
            }
        }
    }

    // Final boss guaranteed legendary drop
    if (currentMonster->enemyType == "final_boss") {
        Item* legendary = ItemFactory::generateRandomItem(player->level + 5);
        if (legendary) {
            legendary->rarity = "Legendary";
            player->inventory.append(legendary);
            combatLog += QString("\n*** LEGENDARY REWARD: %1 ***").arg(legendary->name);
            // Unlock lore entry if legendary has associated lore (Phase 5)
            if (!legendary->loreId.isEmpty() && m_codexManager) {
                m_codexManager->unlockEntry(legendary->loreId);
            }
        }
    }

    combatLog += QString("\nGained %1 EXP and %2 gold!").arg(expGained).arg(goldGained);

    // Notify quest manager about combat end (for kill quests)
    if (m_questManager) {
        m_questManager->onCombatEnd(currentMonster->name);
    }

    // Notify codex manager about enemy kill (for lore unlocks) - Phase 3
    if (m_codexManager) {
        m_codexManager->onEnemyKilled(currentMonster->name);
    }
}

void Game::checkCombatEndAfterAction()
{
    if (!combatActive) return;

    bool playerWon = (currentMonster && currentMonster->health <= 0);
    bool playerLost = (player && player->health <= 0);

    if (playerWon || playerLost) {
        endCombat();
        emit combatEnded(playerWon);
    }
}

// Final Boss Methods
void Game::startFinalBossCombat()
{
    // Clean up existing monster
    if (currentMonster) {
        delete currentMonster;
    }

    // Check if quest requires "Dark Overlord"
    QString bossType = "The Eternal Shadow";  // Default
    if (m_questManager) {
        QList<Quest*> activeQuests = m_questManager->getActiveQuests();
        for (Quest* quest : activeQuests) {
            if (!quest) continue;

            for (const QuestObjective &obj : quest->objectives) {
                // Check for incomplete final boss objectives
                if (obj.type == "defeat_boss" && !obj.completed &&
                    (obj.targetId == "Dark Overlord" || obj.targetId == "dark_overlord")) {
                    bossType = "Dark Overlord";
                    break;
                }
            }
            if (bossType == "Dark Overlord") {
                break;
            }
        }
    }

    // Create final boss with appropriate name
    currentMonster = MonsterFactory::createFinalBoss(player->level, bossType);
    combatActive = true;

    // Emit boss encountered signal
    emit bossEncountered(currentMonster->name);

    combatLog = QString("=== THE FINAL BATTLE BEGINS ===\n%1 emerges from the shadows!\nPrepare yourself for the ultimate challenge!").arg(currentMonster->name);
}

bool Game::canAccessFinalBoss() const
{
    if (!player || !m_questManager) return false;

    // Check level requirement
    if (player->level < 20) {
        return false;
    }

    // Check all main quests complete
    // We need to verify that there are no active or locked main quests
    QList<Quest*> activeQuests = m_questManager->getActiveQuests();
    for (Quest* quest : activeQuests) {
        if (quest && quest->questId.startsWith("main_quest_")) {
            return false;  // Block if any main quest is still active
        }
    }

    return true;  // All requirements met
}

int Game::calculatePlaytimeMinutes() const
{
    QTime now = QTime::currentTime();
    int seconds = m_gameStartTime.secsTo(now);
    return seconds / 60;
}

// Test utilities implementation
void Game::setPlayerForTesting(Player* player) {
    this->player = player;
}

void Game::setCurrentMonsterForTesting(Monster* monster) {
    this->currentMonster = monster;
}

void Game::setCombatActiveForTesting(bool active) {
    this->combatActive = active;
}

void Game::clearCombatLogForTesting() {
    this->combatLog.clear();
}
