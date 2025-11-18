#pragma once

#include <QString>
#include <QList>
#include <QDateTime>
#include <QSignalSpy>
#include <vector>
#include <memory>

// Include SaveManager for SaveSlotInfo
#include "persistence/SaveManager.h"

// Forward declarations for classes defined later
class Item;
class Skill;
class Monster;
class Game;

class Player;

// Mockable interface for SaveManager
class ISaveManager {
public:
    virtual ~ISaveManager() = default;
    virtual bool saveGame(Player* player, const QString& filePath) = 0;
    virtual Player* loadGame(const QString& filePath) = 0;
    virtual std::vector<SaveSlotInfo> getSaveSlots() const = 0;
    virtual bool saveToSlot(Player* player, int slotNumber) = 0;
    virtual Player* loadFromSlot(int slotNumber) = 0;
    virtual bool deleteSaveSlot(int slotNumber) = 0;
    virtual QString getSlotFilePath(int slotNumber) const = 0;
    virtual SaveSlotInfo getSlotInfo(int slotNumber) const = 0;
};

// Mock implementation for testing
class MockSaveManager : public ISaveManager {
public:
    MockSaveManager();
    ~MockSaveManager() override;

    // Mock control methods
    void setSaveShouldSucceed(bool success) { m_saveSuccess = success; }
    void setLoadShouldSucceed(bool success) { m_loadSuccess = success; }
    void setMockPlayer(Player* player) { m_mockPlayer = player; }

    // ISaveManager implementation
    bool saveGame(Player* player, const QString& filePath) override;
    Player* loadGame(const QString& filePath) override;
    std::vector<SaveSlotInfo> getSaveSlots() const override;
    bool saveToSlot(Player* player, int slotNumber) override;
    Player* loadFromSlot(int slotNumber) override;
    bool deleteSaveSlot(int slotNumber) override;
    QString getSlotFilePath(int slotNumber) const override;
    SaveSlotInfo getSlotInfo(int slotNumber) const override;

    // Mock verification methods
    int getSaveCallCount() const { return m_saveCallCount; }
    int getLoadCallCount() const { return m_loadCallCount; }
    QString getLastSavePath() const { return m_lastSavePath; }
    QString getLastLoadPath() const { return m_lastLoadPath; }

private:
    bool m_saveSuccess;
    bool m_loadSuccess;
    Player* m_mockPlayer;
    std::vector<SaveSlotInfo> m_mockSlots;
    int m_saveCallCount;
    int m_loadCallCount;
    QString m_lastSavePath;
    QString m_lastLoadPath;
};

// Fluent builder for Player objects
class PlayerBuilder {
public:
    PlayerBuilder();
    ~PlayerBuilder();

    PlayerBuilder& withName(const QString& name);
    PlayerBuilder& withClass(const QString& characterClass);
    PlayerBuilder& withLevel(int level);
    PlayerBuilder& withGold(int gold);
    PlayerBuilder& withHealth(int health);
    PlayerBuilder& withMaxHealth(int maxHealth);
    PlayerBuilder& withExperience(int experience);
    PlayerBuilder& withItems(const QList<Item*>& items);
    PlayerBuilder& withSkills(const QList<Skill*>& skills);

    Player* build();

private:
    QString m_name;
    QString m_characterClass;
    int m_level;
    int m_gold;
    int m_health;
    int m_maxHealth;
    int m_experience;
    QList<Item*> m_items;
    QList<Skill*> m_skills;
};

// Fluent builder for Monster objects
class MonsterBuilder {
public:
    MonsterBuilder();
    ~MonsterBuilder();

    MonsterBuilder& withName(const QString& name);
    MonsterBuilder& withLevel(int level);
    MonsterBuilder& withHealth(int health);
    MonsterBuilder& withMaxHealth(int maxHealth);
    MonsterBuilder& withAttack(int attack);
    MonsterBuilder& withDefense(int defense);
    MonsterBuilder& withExpReward(int expReward);
    MonsterBuilder& withGoldReward(int goldReward);

    Monster* build();

private:
    QString m_name;
    int m_level;
    int m_health;
    int m_maxHealth;
    int m_attack;
    int m_defense;
    int m_expReward;
    int m_goldReward;
};

// Test fixture presets
class TestFixtures {
public:
    // Player fixtures
    static Player* createBasicWarrior();
    static Player* createHighLevelWarrior();
    static Player* createLowHealthWarrior();

    // Monster fixtures
    static Monster* createWeakGoblin();
    static Monster* createStrongOrc();
    static Monster* createBossMonster();

    // Game state fixtures
    static void setupCombatScenario(Game* game, Player* player, Monster* monster);
    static void setupVictoryScenario(Game* game);
    static void setupDefeatScenario(Game* game);

    // Item fixtures
    static QList<Item*> createBasicInventory();
    static QList<Item*> createFullInventory();
};

// Signal testing utilities
class SignalTester {
public:
    SignalTester(QObject* sender, const char* signal);
    ~SignalTester();

    bool waitForSignal(int timeoutMs = 1000);
    int signalCount() const;
    QList<QVariantList> signalArguments() const;
    QVariantList lastSignalArguments() const;

private:
    QSignalSpy* m_spy;
};

// Mock signal emitter for testing slot connections
class MockSignalEmitter : public QObject {
    Q_OBJECT

public:
    explicit MockSignalEmitter(QObject* parent = nullptr);

public slots:
    void emitCombatEnded(bool playerWon);
    void emitBossEncountered(const QString& bossName);
    void emitBossPhaseChanged(int newPhase);
    void emitFinalBossDefeated();
    void emitGameCompleted(int finalLevel, int playtimeMinutes);

signals:
    void combatEnded(bool playerWon);
    void bossEncountered(const QString& bossName);
    void bossPhaseChanged(int newPhase);
    void finalBossDefeated();
    void gameCompleted(int finalLevel, int playtimeMinutes);
};

// Include necessary headers
#include "models/Player.h"
#include "models/Monster.h"
#include "models/Item.h"
#include "models/Skill.h"
#include "game/Game.h"
