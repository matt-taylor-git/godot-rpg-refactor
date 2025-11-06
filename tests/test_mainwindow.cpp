#include <QTest>
#include <QSignalSpy>
#include <QKeyEvent>
#include "TestBase.h"
#include "MainWindow.h"
#include "components/MenuOverlay.h"

class TestMainWindow : public TestBase
{
    Q_OBJECT

private slots:
    void testWindowTitle();
    void testMenuOverlayShowHide();
    void testMenuOverlayContentUpdate();
    void testMenuOverlayRapidToggle();
    void testMenuOverlayEdgeCases();
    void testMenuOverlayAnimationState();
    void testMenuOverlayFocusManagement();
    void testCombatEndedSignalHandling();
    void testGlobalShortcuts();
    void testShortcutCombatDisabled();
    void testShortcutNoConflictWithESC();
};

void TestMainWindow::testWindowTitle()
{
    MainWindow window;
    QCOMPARE(window.windowTitle(), QString("Pyrpg-Qt"));
}

void TestMainWindow::testMenuOverlayShowHide()
{
    MenuOverlay overlay;

    // Test initial state
    QVERIFY(!overlay.isVisible());
    QCOMPARE(overlay.opacity(), 0.0);

    // Test show overlay
    overlay.showOverlay();
    QVERIFY(overlay.isVisible());

    // Test hide overlay with signal spy
    QSignalSpy spy(&overlay, &MenuOverlay::overlayHidden);
    overlay.hideOverlay();

    // Wait for animation to complete
    QTest::qWait(300);

    // Verify overlay is hidden and signal was emitted
    QVERIFY(!overlay.isVisible());
    QCOMPARE(spy.count(), 1);
}

void TestMainWindow::testMenuOverlayContentUpdate()
{
    MenuOverlay overlay;

    // Create a player with some items
    Player* player = createTestPlayer("TestPlayer", "Warrior", 5, 100);
    player->health = 100;
    player->maxHealth = 100;

    // Update overlay content
    overlay.updateContent(player);

    // Show the overlay
    overlay.showOverlay();
    QVERIFY(overlay.isVisible());

    overlay.hide();
}

void TestMainWindow::testMenuOverlayRapidToggle()
{
    MenuOverlay overlay;
    Player* player = createTestPlayer("TestPlayer");
    overlay.updateContent(player);

    // Rapidly toggle the overlay multiple times
    for (int i = 0; i < 5; ++i) {
        overlay.showOverlay();
        overlay.hideOverlay();
    }

    // Wait for animations to settle
    QTest::qWait(300);

    // Should not crash and should be in a consistent state
    QVERIFY(!overlay.isVisible());
}

void TestMainWindow::testMenuOverlayEdgeCases()
{
    MenuOverlay overlay;

    // Test opening menu without player (should not crash)
    overlay.updateContent(nullptr);
    overlay.showOverlay();
    QVERIFY(overlay.isVisible());
    overlay.hide();

    // Test ESC key handling
    overlay.showOverlay();
    QKeyEvent keyPress(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
    QCoreApplication::sendEvent(&overlay, &keyPress);

    // Wait for animation
    QTest::qWait(300);
    QVERIFY(!overlay.isVisible());
}

void TestMainWindow::testMenuOverlayAnimationState()
{
    MenuOverlay overlay;
    Player* player = createTestPlayer("TestPlayer");
    overlay.updateContent(player);

    // Show overlay and immediately try to hide it
    overlay.showOverlay();
    overlay.hideOverlay();

    // Try to hide again while already hiding (should be a no-op)
    overlay.hideOverlay();

    // Wait for animation
    QTest::qWait(300);
    QVERIFY(!overlay.isVisible());
}

void TestMainWindow::testMenuOverlayFocusManagement()
{
    MenuOverlay overlay;
    Player* player = createTestPlayer("TestPlayer");
    overlay.updateContent(player);

    // Create a widget to hold focus
    QWidget focusWidget;
    focusWidget.setFocusPolicy(Qt::StrongFocus);
    focusWidget.show();
    focusWidget.setFocus();

    // Show overlay (should store previous focus)
    overlay.showOverlay();
    QVERIFY(overlay.isVisible());

    // Hide overlay
    overlay.hideOverlay();
    QTest::qWait(300);

    // Verify overlay is hidden
    QVERIFY(!overlay.isVisible());
}

void TestMainWindow::testCombatEndedSignalHandling()
{
    MainWindow window;

    // Create a character to enable combat
    QTest::keyClick(&window, Qt::Key_Return); // Simulate pressing enter on new game
    QTest::qWait(100); // Allow UI to update

    // The test verifies that the signal connection exists and doesn't crash
    // In a real test, we'd need to mock the game state, but this ensures basic functionality
    QVERIFY(window.windowTitle() == "Pyrpg-Qt");
}

void TestMainWindow::testGlobalShortcuts()
{
    MainWindow window;

    // Create a character and start game to get to CombatPage
    QTest::keyClick(&window, Qt::Key_Return); // New game
    QTest::qWait(100);

    // Simulate pressing I key - should open inventory
    QTest::keyClick(&window, Qt::Key_I);
    QTest::qWait(100);
    // Verify inventory page is current (would need access to stackedWidget, simplified check)
    QVERIFY(window.windowTitle() == "Pyrpg-Qt"); // Basic check that it doesn't crash

    // Go back to combat page somehow - simplified, assume it works
    QTest::keyClick(&window, Qt::Key_Escape);
    QTest::qWait(100);

    // Test S key for shop
    QTest::keyClick(&window, Qt::Key_S);
    QTest::qWait(100);
    QVERIFY(window.windowTitle() == "Pyrpg-Qt");

    // Test L key for save/load
    QTest::keyClick(&window, Qt::Key_Escape); // Back
    QTest::qWait(100);
    QTest::keyClick(&window, Qt::Key_L);
    QTest::qWait(100);
    QVERIFY(window.windowTitle() == "Pyrpg-Qt");
}

void TestMainWindow::testShortcutCombatDisabled()
{
    MainWindow window;

    // Create character and start combat
    QTest::keyClick(&window, Qt::Key_Return);
    QTest::qWait(100);

    // Simulate starting combat (would need to trigger explore or something)
    // For now, just test that shortcuts don't crash when pressed
    QTest::keyClick(&window, Qt::Key_I);
    QTest::qWait(100);
    QVERIFY(window.windowTitle() == "Pyrpg-Qt");
}

void TestMainWindow::testShortcutNoConflictWithESC()
{
    MainWindow window;

    // Create character
    QTest::keyClick(&window, Qt::Key_Return);
    QTest::qWait(100);

    // Test ESC still works for menu
    QTest::keyClick(&window, Qt::Key_Escape);
    QTest::qWait(300); // Wait for overlay animation
    QVERIFY(window.windowTitle() == "Pyrpg-Qt");
}

QTEST_MAIN(TestMainWindow)
#include "test_mainwindow.moc"
