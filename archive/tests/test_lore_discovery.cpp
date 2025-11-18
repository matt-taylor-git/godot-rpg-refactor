#include <QTest>
#include <QSignalSpy>
#include "models/Player.h"
#include "models/LoreEntry.h"
#include "game/Game.h"
#include "game/CodexManager.h"
#include "game/factories/LoreFactory.h"
#include "game/factories/ItemFactory.h"

class TestLoreDiscovery : public QObject
{
    Q_OBJECT

private slots:
    void testLoreFactoryCreation();
    void testPlayerLoreTracking();
    void testCodexManagerUnlocking();
    void testKillCountLoreUnlock();
    void testItemLoreConnection();
    void testDuplicateUnlockPrevention();
};

void TestLoreDiscovery::testLoreFactoryCreation()
{
    // Test that lore entries are created correctly
    LoreEntry* goblinEntry = LoreFactory::createLoreEntry("bestiary_goblin");
    QVERIFY(goblinEntry != nullptr);
    QCOMPARE(goblinEntry->entryId, QString("bestiary_goblin"));
    QCOMPARE(goblinEntry->category, QString("Bestiary"));
    QCOMPARE(goblinEntry->title, QString("Goblin"));
    QVERIFY(!goblinEntry->fullText.isEmpty());

    // Test that all 30 entries exist
    QList<LoreEntry*> allEntries = LoreFactory::getAllLoreEntries();
    QCOMPARE(allEntries.size(), 30);

    // Test category filtering
    QList<LoreEntry*> bestiaryEntries = LoreFactory::getLoreByCategory("Bestiary");
    QCOMPARE(bestiaryEntries.size(), 8);
}

void TestLoreDiscovery::testPlayerLoreTracking()
{
    Player player("TestHero");

    // Initially no lore unlocked
    QVERIFY(!player.hasUnlockedLore("bestiary_goblin"));
    QCOMPARE(player.getUnlockedLoreEntries().size(), 0);

    // Unlock lore
    player.unlockLore("bestiary_goblin");
    QVERIFY(player.hasUnlockedLore("bestiary_goblin"));
    QCOMPARE(player.getUnlockedLoreEntries().size(), 1);

    // Unlock another
    player.unlockLore("item_healing_potion");
    QCOMPARE(player.getUnlockedLoreEntries().size(), 2);
}

void TestLoreDiscovery::testCodexManagerUnlocking()
{
    Player player("TestHero");
    CodexManager codexManager(&player);
    codexManager.loadLoreEntries();

    // Test signal emission
    QSignalSpy spy(&codexManager, &CodexManager::loreUnlocked);

    // Unlock entry
    codexManager.unlockEntry("bestiary_goblin");

    // Verify signal emitted
    QCOMPARE(spy.count(), 1);
    QList<QVariant> arguments = spy.takeFirst();
    QCOMPARE(arguments.at(0).toString(), QString("bestiary_goblin"));
    QCOMPARE(arguments.at(1).toString(), QString("Goblin"));

    // Verify player updated
    QVERIFY(player.hasUnlockedLore("bestiary_goblin"));
}

void TestLoreDiscovery::testKillCountLoreUnlock()
{
    Player player("TestHero");
    CodexManager codexManager(&player);
    codexManager.loadLoreEntries();

    QSignalSpy spy(&codexManager, &CodexManager::loreUnlocked);

    // Kill goblins - should unlock on 3rd kill
    codexManager.onEnemyKilled("Goblin");
    QCOMPARE(spy.count(), 0);  // Not yet

    codexManager.onEnemyKilled("Goblin");
    QCOMPARE(spy.count(), 0);  // Still not

    codexManager.onEnemyKilled("Goblin");
    QCOMPARE(spy.count(), 1);  // Unlocked!

    QList<QVariant> arguments = spy.takeFirst();
    QCOMPARE(arguments.at(1).toString(), QString("Goblin"));

    // Verify player has lore
    QVERIFY(player.hasUnlockedLore("bestiary_goblin"));
}

void TestLoreDiscovery::testItemLoreConnection()
{
    // Test that items have loreId fields
    QMap<QString, Item*> shopItems = ItemFactory::getShopItems();

    // Health Potion should have lore
    QVERIFY(shopItems.contains("Health Potion"));
    Item* healthPotion = shopItems["Health Potion"];
    QCOMPARE(healthPotion->loreId, QString("item_healing_potion"));

    // Mana Potion should have lore
    QVERIFY(shopItems.contains("Mana Potion"));
    Item* manaPotion = shopItems["Mana Potion"];
    QCOMPARE(manaPotion->loreId, QString("item_mana_potion"));

    // Magic Staff should have lore
    QVERIFY(shopItems.contains("Magic Staff"));
    Item* magicStaff = shopItems["Magic Staff"];
    QCOMPARE(magicStaff->loreId, QString("item_magic_staff"));

    // Common items may not have lore
    QVERIFY(shopItems.contains("Iron Sword"));
    Item* ironSword = shopItems["Iron Sword"];
    QVERIFY(ironSword->loreId.isEmpty());
}

void TestLoreDiscovery::testDuplicateUnlockPrevention()
{
    Player player("TestHero");
    CodexManager codexManager(&player);
    codexManager.loadLoreEntries();

    QSignalSpy spy(&codexManager, &CodexManager::loreUnlocked);

    // Unlock once
    codexManager.unlockEntry("bestiary_goblin");
    QCOMPARE(spy.count(), 1);

    // Try to unlock again - should not emit signal
    codexManager.unlockEntry("bestiary_goblin");
    QCOMPARE(spy.count(), 1);  // Still 1, not 2

    // Player should still have it only once
    QCOMPARE(player.getUnlockedLoreEntries().size(), 1);
}

QTEST_MAIN(TestLoreDiscovery)
#include "test_lore_discovery.moc"
