#ifndef STATSPAGE_H
#define STATSPAGE_H

#include <QWidget>

class QLabel;
class QProgressBar;
class QPushButton;
class Player; // Forward declaration

class StatsPage : public QWidget
{
    Q_OBJECT
public:
    explicit StatsPage(QWidget *parent = nullptr);
    void updateStats(Player *player);

signals:
    void backRequested();

private slots:
    void handleStrengthUpgrade();
    void handleDefenseUpgrade();
    void handleMagicUpgrade();
    void handleSpeedUpgrade();

private:
    void setupUi();
    QWidget* createCharacterInfoCard();
    QWidget* createStatsAllocationCard();
    QWidget* createStatRow(const QString &name, const QString &description, QLabel* &valueLabel, QPushButton* &plusButton);

    // Character Info
    QLabel *m_levelBadge;
    QLabel *m_charNameLabel;
    QProgressBar *m_expBar;
    QProgressBar *m_healthBar;
    QProgressBar *m_manaBar;
    QLabel *m_goldLabel;

    // Stats Allocation
    QLabel *m_pointsBadge;
    QLabel *m_strengthValue;
    QPushButton *m_strengthPlusButton;
    QLabel *m_defenseValue;
    QPushButton *m_defensePlusButton;
    QLabel *m_magicValue;
    QPushButton *m_magicPlusButton;
    QLabel *m_speedValue;
    QPushButton *m_speedPlusButton;

    // Current player reference
    Player *m_currentPlayer;
};

#endif // STATSPAGE_H
