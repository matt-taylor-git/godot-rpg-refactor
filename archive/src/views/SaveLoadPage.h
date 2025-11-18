#ifndef SAVELOADPAGE_H
#define SAVELOADPAGE_H

#include <QWidget>

class QListWidget;
class QKeyEvent;
class QPushButton;

class SaveLoadPage : public QWidget
{
    Q_OBJECT
public:
    explicit SaveLoadPage(QWidget *parent = nullptr);
    void refreshSaveSlots();

signals:
    void quickSaveRequested();
    void quickLoadRequested();
    void saveToSlotRequested(int slotNumber);
    void loadFromSlotRequested(int slotNumber);
    void deleteSlotRequested(int slotNumber);
    void backRequested();

protected:
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void onQuickSaveClicked();
    void onQuickLoadClicked();
    void onSaveSelectedClicked();
    void onLoadSelectedClicked();
    void onDeleteClicked();
    void onBackClicked();

private:
    void setupUi();
    int getSelectedSlotNumber() const;

    QListWidget *m_savesList;
    QPushButton *m_deleteButton;
    QPushButton *m_quickSaveButton;
    QPushButton *m_quickLoadButton;
    QPushButton *m_saveSelectedButton;
    QPushButton *m_loadSelectedButton;
    QPushButton *m_backButton;
    bool m_isRefreshing = false;
};

#endif // SAVELOADPAGE_H