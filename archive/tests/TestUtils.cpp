#include "TestUtils.h"
#include <QDebug>
#include <QSignalSpy>

// Include model headers
#include "models/Player.h"
#include "models/Monster.h"
#include "models/Item.h"
#include "models/Skill.h"
#include "game/Game.h"
#include "game/factories/ItemFactory.h"

// MockSaveManager implementation
MockSaveManager::MockSaveManager()
    : m_saveSuccess(true)
    , m_loadSuccess(true)
    , m_mockPlayer(nullptr)
    , m_saveCallCount(0)
    , m_loadCallCount(0)
{
}



MockSaveManager::~MockSaveManager() {
    // Don't delete m_mockPlayer as it's managed by the test framework
}

bool MockSaveManager::saveGame(Player* player, const QString& filePath) {
    m_saveCallCount++;
    m_lastSavePath = filePath;
    return m_saveSuccess;
}

Player* MockSaveManager::loadGame(const QString& filePath) {
    m_loadCallCount++;
    m_lastLoadPath = filePath;
    return m_loadSuccess ? m_mockPlayer : nullptr;
}

std::vector<SaveSlotInfo> MockSaveManager::getSaveSlots() const {
    return m_mockSlots;
}

bool MockSaveManager::saveToSlot(Player* player, int slotNumber) {
    m_saveCallCount++;
    return m_saveSuccess;
}

Player* MockSaveManager::loadFromSlot(int slotNumber) {
    m_loadCallCount++;
    return m_loadSuccess ? m_mockPlayer : nullptr;
}

bool MockSaveManager::deleteSaveSlot(int slotNumber) {
    return true; // Always succeed for mocking
}

QString MockSaveManager::getSlotFilePath(int slotNumber) const {
    return QString("mock_slot_%1.save").arg(slotNumber);
}

SaveSlotInfo MockSaveManager::getSlotInfo(int slotNumber) const {
    for (const auto& slot : m_mockSlots) {
        if (slot.slotNumber == slotNumber) {
            return slot;
        }
    }
    return {slotNumber, "", "", 0, QDateTime(), false};
}

// PlayerBuilder implementation
PlayerBuilder::PlayerBuilder()
    : m_name("TestPlayer")
    , m_characterClass("Warrior")
    , m_level(1)
    , m_gold(100)
    , m_health(100)
    , m_maxHealth(100)
    , m_experience(0)
{
}

PlayerBuilder::~PlayerBuilder() {
    // Items and skills are managed by the caller
}

PlayerBuilder& PlayerBuilder::withName(const QString& name) {
    m_name = name;
    return *this;
}

PlayerBuilder& PlayerBuilder::withClass(const QString& characterClass) {
    m_characterClass = characterClass;
    return *this;
}

PlayerBuilder& PlayerBuilder::withLevel(int level) {
    m_level = level;
    return *this;
}

PlayerBuilder& PlayerBuilder::withGold(int gold) {
    m_gold = gold;
    return *this;
}

PlayerBuilder& PlayerBuilder::withHealth(int health) {
    m_health = health;
    return *this;
}

PlayerBuilder& PlayerBuilder::withMaxHealth(int maxHealth) {
    m_maxHealth = maxHealth;
    return *this;
}

PlayerBuilder& PlayerBuilder::withExperience(int experience) {
    m_experience = experience;
    return *this;
}

PlayerBuilder& PlayerBuilder::withItems(const QList<Item*>& items) {
    m_items = items;
    return *this;
}

PlayerBuilder& PlayerBuilder::withSkills(const QList<Skill*>& skills) {
    m_skills = skills;
    return *this;
}

Player* PlayerBuilder::build() {
    Player* player = new Player(m_name, m_characterClass);
    player->level = m_level;
    player->gold = m_gold;
    player->health = m_health;
    player->maxHealth = m_maxHealth;
    player->experience = m_experience;

    // Add items and skills
    for (Item* item : m_items) {
        if (item) {
            player->inventory.append(item);
        }
    }

    for (Skill* skill : m_skills) {
        if (skill) {
            player->skills.append(skill);
        }
    }

    return player;
}

// MonsterBuilder implementation
MonsterBuilder::MonsterBuilder()
    : m_name("TestMonster")
    , m_level(1)
    , m_health(50)
    , m_maxHealth(50)
    , m_attack(10)
    , m_defense(5)
    , m_expReward(10)
    , m_goldReward(10)
{
}

MonsterBuilder::~MonsterBuilder() {
    // No cleanup needed
}

MonsterBuilder& MonsterBuilder::withName(const QString& name) {
    m_name = name;
    return *this;
}

MonsterBuilder& MonsterBuilder::withLevel(int level) {
    m_level = level;
    return *this;
}

MonsterBuilder& MonsterBuilder::withHealth(int health) {
    m_health = health;
    return *this;
}

MonsterBuilder& MonsterBuilder::withMaxHealth(int maxHealth) {
    m_maxHealth = maxHealth;
    return *this;
}

MonsterBuilder& MonsterBuilder::withAttack(int attack) {
    m_attack = attack;
    return *this;
}

MonsterBuilder& MonsterBuilder::withDefense(int defense) {
    m_defense = defense;
    return *this;
}

MonsterBuilder& MonsterBuilder::withExpReward(int expReward) {
    m_expReward = expReward;
    return *this;
}

MonsterBuilder& MonsterBuilder::withGoldReward(int goldReward) {
    m_goldReward = goldReward;
    return *this;
}

Monster* MonsterBuilder::build() {
    Monster* monster = new Monster(m_name, m_level);
    monster->health = m_health;
    monster->maxHealth = m_maxHealth;
    monster->attack = m_attack;
    monster->defense = m_defense;
    monster->expReward = m_expReward;
    monster->goldReward = m_goldReward;
    return monster;
}

// TestFixtures implementation
Player* TestFixtures::createBasicWarrior() {
    return PlayerBuilder()
        .withName("BasicWarrior")
        .withClass("Warrior")
        .withLevel(1)
        .withGold(100)
        .withHealth(100)
        .withMaxHealth(100)
        .build();
}

Player* TestFixtures::createHighLevelWarrior() {
    return PlayerBuilder()
        .withName("HighLevelWarrior")
        .withClass("Warrior")
        .withLevel(10)
        .withGold(1000)
        .withHealth(200)
        .withMaxHealth(200)
        .withExperience(5000)
        .build();
}

Player* TestFixtures::createLowHealthWarrior() {
    return PlayerBuilder()
        .withName("LowHealthWarrior")
        .withClass("Warrior")
        .withLevel(5)
        .withGold(500)
        .withHealth(10)
        .withMaxHealth(150)
        .build();
}

Monster* TestFixtures::createWeakGoblin() {
    return MonsterBuilder()
        .withName("Weak Goblin")
        .withLevel(1)
        .withHealth(20)
        .withMaxHealth(20)
        .withAttack(5)
        .withDefense(2)
        .withExpReward(5)
        .withGoldReward(5)
        .build();
}

Monster* TestFixtures::createStrongOrc() {
    return MonsterBuilder()
        .withName("Strong Orc")
        .withLevel(5)
        .withHealth(100)
        .withMaxHealth(100)
        .withAttack(20)
        .withDefense(10)
        .withExpReward(50)
        .withGoldReward(50)
        .build();
}

Monster* TestFixtures::createBossMonster() {
    return MonsterBuilder()
        .withName("Boss Monster")
        .withLevel(10)
        .withHealth(300)
        .withMaxHealth(300)
        .withAttack(50)
        .withDefense(20)
        .withExpReward(200)
        .withGoldReward(200)
        .build();
}

void TestFixtures::setupCombatScenario(Game* game, Player* player, Monster* monster) {
    if (!game || !player || !monster) return;

    game->setPlayerForTesting(player);
    game->setCurrentMonsterForTesting(monster);
    game->setCombatActiveForTesting(true);
    game->clearCombatLogForTesting();
}

void TestFixtures::setupVictoryScenario(Game* game) {
    if (!game) return;

    // Create a scenario where player can easily win
    Player* player = createHighLevelWarrior();
    Monster* monster = createWeakGoblin();
    setupCombatScenario(game, player, monster);
}

void TestFixtures::setupDefeatScenario(Game* game) {
    if (!game) return;

    // Create a scenario where player will lose
    Player* player = createLowHealthWarrior();
    Monster* monster = createStrongOrc();
    setupCombatScenario(game, player, monster);
}

QList<Item*> TestFixtures::createBasicInventory() {
    QList<Item*> inventory;
    // Create some basic items
    Item* healthPotion = ItemFactory::createItem("Health Potion");
    Item* sword = ItemFactory::createItem("Iron Sword");

    if (healthPotion) inventory.append(healthPotion);
    if (sword) inventory.append(sword);

    return inventory;
}

QList<Item*> TestFixtures::createFullInventory() {
    QList<Item*> inventory;
    // Create a full set of items
    QStringList itemNames = {"Health Potion", "Mana Potion", "Iron Sword", "Steel Armor", "Magic Ring"};

    for (const QString& name : itemNames) {
        Item* item = ItemFactory::createItem(name);
        if (item) inventory.append(item);
    }

    return inventory;
}

// SignalTester implementation
SignalTester::SignalTester(QObject* sender, const char* signal)
    : m_spy(new QSignalSpy(sender, signal))
{
}

SignalTester::~SignalTester() {
    delete m_spy;
}

bool SignalTester::waitForSignal(int timeoutMs) {
    return m_spy->wait(timeoutMs);
}

int SignalTester::signalCount() const {
    return m_spy->count();
}

QList<QVariantList> SignalTester::signalArguments() const {
    QList<QVariantList> args;
    for (int i = 0; i < m_spy->count(); ++i) {
        args.append(m_spy->at(i));
    }
    return args;
}

QVariantList SignalTester::lastSignalArguments() const {
    if (m_spy->count() > 0) {
        return m_spy->last();
    }
    return QVariantList();
}

// MockSignalEmitter implementation
MockSignalEmitter::MockSignalEmitter(QObject* parent)
    : QObject(parent)
{
}

void MockSignalEmitter::emitCombatEnded(bool playerWon) {
    emit combatEnded(playerWon);
}

void MockSignalEmitter::emitBossEncountered(const QString& bossName) {
    emit bossEncountered(bossName);
}

void MockSignalEmitter::emitBossPhaseChanged(int newPhase) {
    emit bossPhaseChanged(newPhase);
}

void MockSignalEmitter::emitFinalBossDefeated() {
    emit finalBossDefeated();
}

void MockSignalEmitter::emitGameCompleted(int finalLevel, int playtimeMinutes) {
    emit gameCompleted(finalLevel, playtimeMinutes);
}
