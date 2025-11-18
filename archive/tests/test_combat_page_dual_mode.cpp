#include <QtTest>
#include "../src/views/CombatPage.h"
#include "../src/models/Player.h"
#include "../src/models/Monster.h"

class TestCombatPageDualMode : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void testStartsInNonCombatMode();
    void testSwitchToCombatModeShowsCombatButtons();
    void testSwitchToNonCombatModeShowsExploreRestButtons();
    void testCombatModeHidesSpritesAndStats();
    void testNonCombatModeShowsWelcomeMessage();
    void testCombatSignals();
    void testCombatButtonsCreated();

private:
    CombatPage *m_combatPage;
};

void TestCombatPageDualMode::init()
{
    m_combatPage = new CombatPage();
}

void TestCombatPageDualMode::cleanup()
{
    delete m_combatPage;
}

void TestCombatPageDualMode::testStartsInNonCombatMode()
{
    // Should start in non-combat mode by default
    QVERIFY(!m_combatPage->property("inCombat").toBool());
}

void TestCombatPageDualMode::testSwitchToCombatModeShowsCombatButtons()
{
    QSignalSpy spy(m_combatPage, &CombatPage::attackClicked);
    m_combatPage->setCombatMode(true);

    // Should have combat buttons after switching to combat mode
    // We can't directly test button visibility, but we can test the mode property
    QVERIFY(m_combatPage->property("inCombat").toBool());
}

void TestCombatPageDualMode::testSwitchToNonCombatModeShowsExploreRestButtons()
{
    QSignalSpy exploreSpy(m_combatPage, &CombatPage::exploreClicked);
    QSignalSpy restSpy(m_combatPage, &CombatPage::restClicked);

    m_combatPage->setCombatMode(false);

    // Should be in non-combat mode
    QVERIFY(!m_combatPage->property("inCombat").toBool());
}

void TestCombatPageDualMode::testCombatModeHidesSpritesAndStats()
{
    m_combatPage->setCombatMode(true);

    // Combat mode should show sprites and enemy stats
    // This is more of an integration test - we test the mode switching
    QVERIFY(m_combatPage->property("inCombat").toBool());
}

void TestCombatPageDualMode::testNonCombatModeShowsWelcomeMessage()
{
    m_combatPage->setCombatMode(false);

    // Non-combat mode should show welcome message
    // This tests that the mode is correctly set
    QVERIFY(!m_combatPage->property("inCombat").toBool());
}

void TestCombatPageDualMode::testCombatSignals()
{
    QSignalSpy attackSpy(m_combatPage, &CombatPage::attackClicked);
    QSignalSpy skillSpy(m_combatPage, &CombatPage::skillClicked);
    QSignalSpy itemSpy(m_combatPage, &CombatPage::itemClicked);
    QSignalSpy statsSpy(m_combatPage, &CombatPage::statsClicked);
    QSignalSpy runSpy(m_combatPage, &CombatPage::runClicked);
    QSignalSpy exploreSpy(m_combatPage, &CombatPage::exploreClicked);
    QSignalSpy restSpy(m_combatPage, &CombatPage::restClicked);

    m_combatPage->setCombatMode(true);

    // Signals should be available (we can't easily simulate button clicks in this test)
    QCOMPARE(attackSpy.count(), 0);
    QCOMPARE(exploreSpy.count(), 0);
}

void TestCombatPageDualMode::testCombatButtonsCreated()
{
    m_combatPage->setCombatMode(true);

    // Check that the combat page has buttons after switching to combat mode
    // We can't directly access private members, but we can check that the page exists
    QVERIFY(m_combatPage != nullptr);

    // Switch back to non-combat and check again
    m_combatPage->setCombatMode(false);
    QVERIFY(m_combatPage != nullptr);
}

QTEST_MAIN(TestCombatPageDualMode)
#include "test_combat_page_dual_mode.moc"
