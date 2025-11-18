#include <QTest>
#include <QSignalSpy>
#include "../src/views/InventoryPage.h"
#include "../src/models/Player.h"

class TestInventoryShortcuts : public QObject
{
    Q_OBJECT

private slots:
    void testESCKeyClosesInventory();
    // TODO: Add more tests for arrow navigation when implemented
};

void TestInventoryShortcuts::testESCKeyClosesInventory()
{
    InventoryPage page;
    Player player("Test");
    page.updateInventory(&player);

    QSignalSpy spy(&page, &InventoryPage::backRequested);

    // Simulate ESC key
    QKeyEvent keyPress(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
    QCoreApplication::sendEvent(&page, &keyPress);

    QCOMPARE(spy.count(), 1);
}

QTEST_MAIN(TestInventoryShortcuts)
#include "test_inventory_shortcuts.moc"
