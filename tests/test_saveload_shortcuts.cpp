#include <QTest>
#include <QSignalSpy>
#include "../src/views/SaveLoadPage.h"

class TestSaveLoadShortcuts : public QObject
{
    Q_OBJECT

private slots:
    void testESCKeyClosesSaveLoad();
    void testQKeyQuickSave();
    void testWKeyQuickLoad();
    // TODO: Add tests for number keys when implemented
};

void TestSaveLoadShortcuts::testESCKeyClosesSaveLoad()
{
    SaveLoadPage page;

    QSignalSpy spy(&page, &SaveLoadPage::backRequested);

    // Simulate ESC key
    QKeyEvent keyPress(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
    QCoreApplication::sendEvent(&page, &keyPress);

    QCOMPARE(spy.count(), 1);
}

void TestSaveLoadShortcuts::testQKeyQuickSave()
{
    SaveLoadPage page;

    QSignalSpy spy(&page, &SaveLoadPage::quickSaveRequested);

    // Simulate Q key
    QKeyEvent keyPress(QEvent::KeyPress, Qt::Key_Q, Qt::NoModifier);
    QCoreApplication::sendEvent(&page, &keyPress);

    QCOMPARE(spy.count(), 1);
}

void TestSaveLoadShortcuts::testWKeyQuickLoad()
{
    SaveLoadPage page;

    QSignalSpy spy(&page, &SaveLoadPage::quickLoadRequested);

    // Simulate W key
    QKeyEvent keyPress(QEvent::KeyPress, Qt::Key_W, Qt::NoModifier);
    QCoreApplication::sendEvent(&page, &keyPress);

    QCOMPARE(spy.count(), 1);
}

QTEST_MAIN(TestSaveLoadShortcuts)
#include "test_saveload_shortcuts.moc"
