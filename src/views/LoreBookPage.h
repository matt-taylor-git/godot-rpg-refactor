#ifndef LOREBOOKPAGE_H
#define LOREBOOKPAGE_H

#include <QWidget>
#include <QLabel>
#include <QTabWidget>
#include <QListWidget>
#include <QTextEdit>
#include <QPushButton>
#include <QKeyEvent>
#include "../game/CodexManager.h"

class LoreBookPage : public QWidget
{
    Q_OBJECT

public:
    explicit LoreBookPage(QWidget *parent = nullptr);

    // Update lore display
    void updateLore(CodexManager *codexManager);

signals:
    void backRequested();

protected:
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void handleCategoryChanged(int index);
    void handleEntryClicked(QListWidgetItem *item);

private:
    void setupUi();
    void refreshEntryList(const QString &category);

    CodexManager *m_codexManager;
    QLabel *m_titleLabel;
    QTabWidget *m_categoryTabs;
    QListWidget *m_entryList;
    QTextEdit *m_entryDetails;
    QPushButton *m_backButton;
    QString m_currentCategory;
};

#endif // LOREBOOKPAGE_H
