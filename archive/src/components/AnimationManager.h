#ifndef ANIMATIONMANAGER_H
#define ANIMATIONMANAGER_H

#include <QObject>

class CombatPage;
class QLabel;

class AnimationManager : public QObject
{
    Q_OBJECT
public:
    explicit AnimationManager(CombatPage *combatPage, QObject *parent = nullptr);

    void playPlayerAttackAnimation();
    void playDamageAnimation(QLabel* target);

signals:
    void animationFinished();

private:
    CombatPage* m_combatPage;
};

#endif // ANIMATIONMANAGER_H
