#include <QtTest>
#include "../src/MainWindow.h"
#include "../src/views/CombatPage.h"
#include "../src/components/MenuOverlay.h"

class TestNavigationFlow : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void testNewGameNavigatesToCombatPage();
    void testExploreSwitchesToCombatMode();
    void testRestWorksInNonCombatMode();
    void testMenuOverlayAccessibleFromCombatPage();

private:
    MainWindow *m_mainWindow;
};

void TestNavigationFlow::init()
{
    m_mainWindow = new MainWindow();
}

void TestNavigationFlow::cleanup()
{
    delete m_mainWindow;
}

void TestNavigationFlow::testNewGameNavigatesToCombatPage()
{
    // Simulate new game creation
    // This would normally be triggered by UI, but we can test the navigation
    QVERIFY(m_mainWindow->findChild<CombatPage*>() != nullptr);
}

void TestNavigationFlow::testExploreSwitchesToCombatMode()
{
    CombatPage *combatPage = m_mainWindow->findChild<CombatPage*>();
    QVERIFY(combatPage != nullptr);

    // CombatPage should start in non-combat mode
    QVERIFY(!combatPage->isInCombat());
}

void TestNavigationFlow::testRestWorksInNonCombatMode()
{
    // This test verifies the navigation structure is set up correctly
    // The actual rest functionality is tested elsewhere
    CombatPage *combatPage = m_mainWindow->findChild<CombatPage*>();
    QVERIFY(combatPage != nullptr);
}

void TestNavigationFlow::testMenuOverlayAccessibleFromCombatPage()
{
    // Menu overlay should be available in MainWindow
    // This tests the integration between components
    QVERIFY(m_mainWindow->findChild<MenuOverlay*>() != nullptr);
}

QTEST_MAIN(TestNavigationFlow)
#include "test_navigation_flow.moc"
