#ifndef GAME_H
#define GAME_H

#include "../models/Player.h"
#include "../models/Monster.h"
#include "../models/Skill.h"
#include "../persistence/SaveManager.h"
#include "QuestManager.h"
#include "DialogueManager.h"
#include "StoryManager.h"
#include "CodexManager.h"
#include <QObject>
#include <QTime>
#include <QDateTime>

class Game : public QObject
{
Q_OBJECT

public:
explicit Game(QObject *parent = nullptr);
~Game();
void newGame(const QString &playerName, const QString &characterClass = "Hero");
Player* getPlayer();
Monster* getCurrentMonster();
QuestManager* getQuestManager();
DialogueManager* getDialogueManager();
StoryManager* getStoryManager();
CodexManager* getCodexManager();
bool saveGame(const QString &filePath);
    bool loadGame(const QString &filePath);

    // Save slot methods
    bool saveToSlot(int slotNumber);
    bool loadFromSlot(int slotNumber);
    bool deleteSlot(int slotNumber);

// Combat
void startCombat();
    QString playerAttack();
    QString playerUseSkill(Skill* skill);
    QString playerUseItem(Item* item);
    QString monsterAttack();
bool isCombatOver();
QString getCombatResult();
void endCombat();
    bool isInCombat() const;

// Final Boss
void startFinalBossCombat();
bool canAccessFinalBoss() const;
int calculatePlaytimeMinutes() const;

    // Test utilities (public for testing)
    void setPlayerForTesting(Player* player);
    void setCurrentMonsterForTesting(Monster* monster);
    void setCombatActiveForTesting(bool active);
    void clearCombatLogForTesting();

signals:
    void combatEnded(bool playerWon);
    void bossEncountered(const QString &bossName);
    void bossPhaseChanged(int newPhase);
    void finalBossDefeated();
    void gameCompleted(int finalLevel, int playtimeMinutes);

private:
    Player *player;
    Monster *currentMonster;
    bool combatActive;
    QString combatLog;
    SaveManager saveManager;
    QuestManager *m_questManager;
    DialogueManager *m_dialogueManager;
    StoryManager *m_storyManager;
    CodexManager *m_codexManager;
    QTime m_gameStartTime;

    friend class TestModels;
    friend class TestUtils;

    // Combat helpers
    int calculateDamage(int baseDamage, int attackerLevel, int defenderDefense, bool isCritical = false);
    bool rollCritical(int dexterity);
    void giveCombatRewards();
    void checkCombatEndAfterAction();
};

#endif // GAME_H
