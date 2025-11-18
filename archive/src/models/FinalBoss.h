#ifndef FINALBOSS_H
#define FINALBOSS_H

#include "Monster.h"
#include <QString>

class FinalBoss : public Monster
{
public:
    explicit FinalBoss(int playerLevel, const QString &bossName = "The Eternal Shadow");

    int getCurrentPhase() const;
    void updatePhase();
    int getPhaseAttackMultiplier() const;
    bool shouldEmitPhaseTransition();
    QString getPhaseDescription() const;

private:
    int currentPhase;
    int m_previousPhase;
    QString m_bossName;
};

#endif // FINALBOSS_H
