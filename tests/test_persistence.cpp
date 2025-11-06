#include <QtTest/QtTest>
#include <vector>
#include "TestBase.h"

class TestPersistence : public TestBase
{
    Q_OBJECT

private slots:
    void testSaveLoadGame();
    void testSaveToSlot();
    void testLoadFromSlot();
    void testDeleteSlot();
    void testGetSaveSlots();
    void testSlotBoundaries();
    void testSlotOverwrite();
    void testEmptySlotLoad();
    void testCharacterClassSerialization();
    void testSkillSerialization();
    void testEquipmentSerialization();
    void cleanupTestData();

private:
    void cleanupTestSlots();
};

void TestPersistence::cleanupTestSlots()
{
    SaveManager saveManager;
    for (int i = 1; i <= 10; ++i) {
        saveManager.deleteSaveSlot(i);
    }
}

void TestPersistence::testSaveLoadGame()
{
    // Setup
    Player *originalPlayer = createTestPlayer("TestHero", "Warrior", 5, 500);
    Item* sword = createTestItem("Iron Sword");
    if (sword) {
        originalPlayer->inventory.append(sword);
    }

    SaveManager saveManager;
    const QString saveFilePath = "test_save.dat";

    // Save the game
    bool saveSuccess = saveManager.saveGame(originalPlayer, saveFilePath);
    QVERIFY(saveSuccess);

    // Load the game
    Player *loadedPlayer = saveManager.loadGame(saveFilePath);
    QVERIFY(loadedPlayer != nullptr);

    // Verify data
    QCOMPARE(loadedPlayer->name, originalPlayer->name);
    QCOMPARE(loadedPlayer->gold, originalPlayer->gold);
    QCOMPARE(loadedPlayer->level, originalPlayer->level);
    QCOMPARE(loadedPlayer->inventory.size(), originalPlayer->inventory.size());
    QCOMPARE(loadedPlayer->inventory.first()->name, originalPlayer->inventory.first()->name);

    // Cleanup
    delete loadedPlayer; // originalPlayer cleaned up by TestBase
    QFile::remove(saveFilePath);
}

void TestPersistence::testSaveToSlot()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("SlotTest", "Warrior", 10, 1000);

    // Test saving to slot
    QVERIFY(saveManager.saveToSlot(player, 1));

    // Verify slot info
    SaveSlotInfo info = saveManager.getSlotInfo(1);
    QVERIFY(info.exists);
    QCOMPARE(info.characterName, QString("SlotTest"));
    QCOMPARE(info.level, 10);

    // player cleaned up by TestBase
}

void TestPersistence::testLoadFromSlot()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("LoadTest", "Mage", 15, 2000);

    // Save to slot
    QVERIFY(saveManager.saveToSlot(player, 2));

    // Load from slot
    Player *loaded = saveManager.loadFromSlot(2);
    QVERIFY(loaded != nullptr);
    QCOMPARE(loaded->name, QString("LoadTest"));
    QCOMPARE(loaded->characterClass, QString("Mage"));
    QCOMPARE(loaded->gold, 2000);
    QCOMPARE(loaded->level, 15);

    delete loaded; // player cleaned up by TestBase
}

void TestPersistence::testDeleteSlot()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("DeleteTest");

    // Save to slot
    QVERIFY(saveManager.saveToSlot(player, 3));
    QVERIFY(saveManager.getSlotInfo(3).exists);

    // Delete slot
    QVERIFY(saveManager.deleteSaveSlot(3));
    SaveSlotInfo info = saveManager.getSlotInfo(3);
    QVERIFY(!info.exists);

    // player cleaned up by TestBase
}

void TestPersistence::testGetSaveSlots()
{
    SaveManager saveManager;

    // Ensure clean slate
    cleanupTestSlots();

    // Create saves in multiple slots
    Player *p1 = createTestPlayer("Player1", "Warrior");
    Player *p2 = createTestPlayer("Player2", "Mage");
    Player *p3 = createTestPlayer("Player3", "Rogue");

    saveManager.saveToSlot(p1, 1);
    saveManager.saveToSlot(p2, 5);
    saveManager.saveToSlot(p3, 10);

    // Get all slots
    auto save_slots = saveManager.getSaveSlots();
    QCOMPARE((int)save_slots.size(), 10);

    // Verify specific slots
    QVERIFY(save_slots[0].exists);
    QCOMPARE(save_slots[0].characterName, QString("Player1"));
    QVERIFY(save_slots[4].exists);
    QCOMPARE(save_slots[4].characterName, QString("Player2"));
    QVERIFY(save_slots[9].exists);
    QCOMPARE(save_slots[9].characterName, QString("Player3"));

    // Verify some other slots are empty (don't check all to avoid test interference)
    QVERIFY(!save_slots[6].exists); // slot 7 should be empty

    // players cleaned up by TestBase
}

void TestPersistence::testSlotBoundaries()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("BoundaryTest");

    // Test invalid slot numbers
    QVERIFY(!saveManager.saveToSlot(player, 0));
    QVERIFY(!saveManager.saveToSlot(player, -1));
    QVERIFY(!saveManager.saveToSlot(player, 11));
    QVERIFY(!saveManager.saveToSlot(player, 100));

    // Test valid boundaries
    QVERIFY(saveManager.saveToSlot(player, 1));
    QVERIFY(saveManager.saveToSlot(player, 10));

    // player cleaned up by TestBase
}

void TestPersistence::testSlotOverwrite()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player1 = createTestPlayer("Original", "Warrior", 1, 100);
    Player *player2 = createTestPlayer("Overwrite", "Mage", 1, 500);

    // Save first player
    QVERIFY(saveManager.saveToSlot(player1, 4));
    SaveSlotInfo info1 = saveManager.getSlotInfo(4);
    QCOMPARE(info1.characterName, QString("Original"));

    // Overwrite with second player
    QVERIFY(saveManager.saveToSlot(player2, 4));
    SaveSlotInfo info2 = saveManager.getSlotInfo(4);
    QCOMPARE(info2.characterName, QString("Overwrite"));

    // Verify loaded data is from second player
    Player *loaded = saveManager.loadFromSlot(4);
    QVERIFY(loaded != nullptr);
    QCOMPARE(loaded->name, QString("Overwrite"));
    QCOMPARE(loaded->gold, 500);

    delete loaded; // players cleaned up by TestBase
}

void TestPersistence::testEmptySlotLoad()
{
    SaveManager saveManager;

    // Ensure slot is empty
    saveManager.deleteSaveSlot(7);

    // Try to load from empty slot
    Player *loaded = saveManager.loadFromSlot(7);
    QVERIFY(loaded == nullptr);
}

void TestPersistence::testCharacterClassSerialization()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate

    // Test each character class
    QStringList classes = {"Warrior", "Mage", "Rogue"};
    int slot = 1;

    for (const QString &className : classes) {
        Player *player = createTestPlayer("TestChar", className);
        QVERIFY(saveManager.saveToSlot(player, slot));

        Player *loaded = saveManager.loadFromSlot(slot);
        QVERIFY(loaded != nullptr);
        QCOMPARE(loaded->characterClass, className);

        delete loaded; // player cleaned up by TestBase
        slot++;
    }
}

void TestPersistence::testSkillSerialization()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("SkillTest");

    // Add skills
    Skill *skill1 = new Skill("Fireball", "magic", 50, 20, "A powerful fire spell");
    Skill *skill2 = new Skill("Sword Slash", "physical", 30, 10, "A basic sword attack");
    player->learnSkill(skill1);
    player->learnSkill(skill2);

    // Save and load
    QVERIFY(saveManager.saveToSlot(player, 8));
    Player *loaded = saveManager.loadFromSlot(8);

    // Verify skills
    QVERIFY(loaded != nullptr);
    QCOMPARE(loaded->skills.size(), 2);
    QVERIFY(loaded->hasSkill("Fireball"));
    QVERIFY(loaded->hasSkill("Sword Slash"));

    Skill *loadedSkill = loaded->getSkill("Fireball");
    QVERIFY(loadedSkill != nullptr);
    QCOMPARE(loadedSkill->damage, 50);
    QCOMPARE(loadedSkill->manaCost, 20);

    delete loaded; // player and skills cleaned up by TestBase
}

void TestPersistence::testEquipmentSerialization()
{
    SaveManager saveManager;
    cleanupTestSlots(); // Ensure clean slate
    Player *player = createTestPlayer("EquipTest");

    // Equip items
    Item *weapon = createTestItem("Iron Sword");
    Item *armor = createTestItem("Leather Armor");
    if (weapon) player->equipItem(weapon);
    if (armor) player->equipItem(armor);

    // Save and load
    QVERIFY(saveManager.saveToSlot(player, 9));
    Player *loaded = saveManager.loadFromSlot(9);

    // Verify equipment
    QVERIFY(loaded != nullptr);
    QVERIFY(loaded->equipment.contains("weapon"));
    QVERIFY(loaded->equipment["weapon"] != nullptr);
    QCOMPARE(loaded->equipment["weapon"]->name, QString("Iron Sword"));

    QVERIFY(loaded->equipment.contains("armor"));
    QVERIFY(loaded->equipment["armor"] != nullptr);
    QCOMPARE(loaded->equipment["armor"]->name, QString("Leather Armor"));

    delete loaded; // player and items cleaned up by TestBase
}

void TestPersistence::cleanupTestData()
{
    cleanupTestSlots();
}

QTEST_MAIN(TestPersistence)
#include "test_persistence.moc"
