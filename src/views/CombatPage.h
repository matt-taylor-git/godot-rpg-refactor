#ifndef COMBATPAGE_H
#define COMBATPAGE_H

#include <QWidget>

class QLabel;
class QProgressBar;
class QPushButton;
class QTextEdit;
class QVBoxLayout;
class Player;
class Monster;
class ParticleSystem;

class CombatPage : public QWidget
{
Q_OBJECT
Q_PROPERTY(bool inCombat READ isInCombat)
public:
explicit CombatPage(QWidget *parent = nullptr);
void updateCombatState(Player *player, Monster *monster, const QString &log);
void setCombatActive(bool active);
void setCombatMode(bool inCombat);
    bool isInCombat() const { return m_inCombat; }
    void addLogEntry(const QString &message, const QString &type = "");

    // Accessors for AnimationManager
    QLabel* getHeroSpriteLabel();
    QLabel* getEnemySpriteLabel();
    ParticleSystem* getParticleSystem();

signals:
void attackClicked();
void skillClicked();
void itemClicked();
void statsClicked();
    void runClicked();
    void exploreClicked();
    void restClicked();
    void menuClicked();

private:
    void setupUi();
    QWidget* createArenaCard();
    QWidget* createLogCard();
    QLayout* createCombatActionsLayout();
    QLayout* createNonCombatActionsLayout();

    // Arena widgets
    QLabel *m_heroSpriteLabel;
    QLabel *m_enemySpriteLabel;
    QLabel *m_monsterNameLabel;
    QProgressBar *m_heroHealthBar;
    QProgressBar *m_heroManaBar;
    QProgressBar *m_enemyHealthBar;

    // UI state
    QVBoxLayout *m_cardLayout;
    QLayout *m_actionsLayout;
    bool m_inCombat;

    // Log widgets
    QTextEdit *m_battleLog;

    // Particle effects
    ParticleSystem *m_particleSystem;
};

#endif // COMBATPAGE_H
