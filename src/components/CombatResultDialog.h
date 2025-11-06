#ifndef COMBATRESULTDIALOG_H
#define COMBATRESULTDIALOG_H

#include <QDialog>

class QLabel;
class QPushButton;
class ParticleSystem;

class CombatResultDialog : public QDialog
{
    Q_OBJECT

public:
    explicit CombatResultDialog(bool victory, int expGained, int goldGained,
                                const QString &lootMessage, bool leveledUp,
                                QWidget *parent = nullptr);

private:
    void setupUi(bool victory, int expGained, int goldGained,
                 const QString &lootMessage, bool leveledUp);

    // Particle effects
    ParticleSystem* m_particleSystem;
};

#endif // COMBATRESULTDIALOG_H
