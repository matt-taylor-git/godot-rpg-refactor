#ifndef QUESTLOGPAGE_H
#define QUESTLOGPAGE_H

#include <QWidget>
#include <QLabel>
#include <QListWidget>
#include <QTextEdit>
#include <QPushButton>
#include "../models/Quest.h"
#include "../game/QuestManager.h"
#include "../models/Player.h"

class QuestLogPage : public QWidget
{
    Q_OBJECT

public:
    explicit QuestLogPage(QWidget *parent = nullptr);
    void updateQuests(QuestManager* questManager, Player* player);

signals:
    void backRequested();
    void questAccepted(const QString &questId);

protected:
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void handleQuestClicked(QListWidgetItem *item);
    void handleAcceptQuest();
    void handleBackClicked();

private:
    void setupUi();
    void clearQuests();
    QString getStatusBadge(const Quest* quest) const;
    QString getObjectiveText(const QuestObjective &obj) const;

    QuestManager* m_questManager;
    Player* m_currentPlayer;
    Quest* m_selectedQuest;

    QLabel* m_titleLabel;
    QListWidget* m_questList;
    QTextEdit* m_questDetails;
    QPushButton* m_backButton;
    QPushButton* m_acceptButton;
};

#endif // QUESTLOGPAGE_H
