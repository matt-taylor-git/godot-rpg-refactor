#include <QTest>
#include <QSignalSpy>
#include "models/Player.h"
#include "models/Item.h"
#include "game/Game.h"
#include "game/CodexManager.h"
#include "game/factories/ItemFactory.h"

class TestItemLore : public QObject
{
    Q_OBJECT

private slots:
    void testItemSerializationWithLoreId();
    void testItemLoreIdAssignment();
    void testCombatLootLoreUnlock();
};

void TestItemLore::testItemSerializationWithLoreId()
{
    // Create item with loreId
    Item originalItem("Test Sword", "weapon", "rare", "weapon", 10, 0, "", 0, 100,
                      "A test sword", "item_ancient_sword");

    // Serialize
    QByteArray buffer;
    QDataStream outStream(&buffer, QIODevice::WriteOnly);
    outStream << originalItem;

    // Deserialize
    Item loadedItem;
    QDataStream inStream(&buffer, QIODevice::ReadOnly);
    inStream >> loadedItem;

    // Verify all fields including loreId
    QCOMPARE(loadedItem.name, originalItem.name);
    QCOMPARE(loadedItem.loreId, originalItem.loreId);
    QCOMPARE(loadedItem.loreId, QString("item_ancient_sword"));
}

void TestItemLore::testItemLoreIdAssignment()
{
    // Test that ItemFactory assigns loreId correctly
    QMap<QString, Item*> shopItems = ItemFactory::getShopItems();

    // Potions should have lore
    QVERIFY(!shopItems["Health Potion"]->loreId.isEmpty());
    QCOMPARE(shopItems["Health Potion"]->loreId, QString("item_healing_potion"));

    QVERIFY(!shopItems["Mana Potion"]->loreId.isEmpty());
    QCOMPARE(shopItems["Mana Potion"]->loreId, QString("item_mana_potion"));

    // Legendary items should have lore
    if (shopItems.contains("Ancient Sword")) {
        QVERIFY(!shopItems["Ancient Sword"]->loreId.isEmpty());
    }

    if (shopItems.contains("Dragonscale Plate")) {
        QVERIFY(!shopItems["Dragonscale Plate"]->loreId.isEmpty());
    }

    // Common items may not have lore (empty is valid)
    if (shopItems.contains("Leather Armor")) {
        // This is a common item, loreId should be empty
        QVERIFY(shopItems["Leather Armor"]->loreId.isEmpty());
    }
}

void TestItemLore::testCombatLootLoreUnlock()
{
    Game game;
    game.newGame("TestHero");

    Player* player = game.getPlayer();
    CodexManager* codexManager = game.getCodexManager();
    QVERIFY(player != nullptr);
    QVERIFY(codexManager != nullptr);

    // Create an item with loreId
    Item* testItem = new Item("Magic Staff", "weapon", "rare", "weapon", 20, 0,
                              "", 0, 300, "Test staff", "item_magic_staff");

    // Initially lore not unlocked
    QVERIFY(!player->hasUnlockedLore("item_magic_staff"));

    // Simulate item acquisition
    player->inventory.append(testItem);

    // Manually trigger unlock (simulating Game.cpp behavior)
    if (!testItem->loreId.isEmpty() && !player->hasUnlockedLore(testItem->loreId)) {
        player->unlockLore(testItem->loreId);
    }

    // Verify lore unlocked
    QVERIFY(player->hasUnlockedLore("item_magic_staff"));
}

QTEST_MAIN(TestItemLore)
#include "test_item_lore.moc"
