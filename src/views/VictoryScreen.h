#ifndef VICTORYSCREEN_H
#define VICTORYSCREEN_H

#include <QDialog>

class QLabel;
class QPushButton;
class QWidget;
class ParticleSystem;

class VictoryScreen : public QDialog
{
    Q_OBJECT

public:
    explicit VictoryScreen(int finalLevel, int playtime, int kills, int deaths,
                          int gold, int quests, QWidget *parent = nullptr);

signals:
    void continuePlaying();
    void returnToMainMenu();

protected:
    void keyPressEvent(QKeyEvent *event) override;

private:
    void setupUi();
    QWidget* createVictoryHeader();
    QWidget* createStatisticsCard(const QString &label, const QString &value);
    QWidget* createActionButtons();
    QString formatPlaytime(int minutes) const;

    // Statistics data
    int m_finalLevel;
    int m_playtime;
    int m_kills;
    int m_deaths;
    int m_gold;
    int m_quests;

    // UI components
    QLabel* m_victoryTitle;
    QLabel* m_victoryMessage;
    QWidget* m_statsContainer;
    QPushButton* m_continueButton;
    QPushButton* m_menuButton;

    // Particle effects
    ParticleSystem* m_particleSystem;
};

#endif // VICTORYSCREEN_H
