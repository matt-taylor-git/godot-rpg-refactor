#include "FinalBoss.h"

FinalBoss::FinalBoss(int playerLevel, const QString &bossName)
    : Monster(bossName, playerLevel + 2, "final_boss"),
      currentPhase(1),
      m_previousPhase(1),
      m_bossName(bossName)
{
    // Enhanced stats (significantly harder than normal boss)
    health = 500 + (playerLevel * 50);
    maxHealth = health;
    attack = 30 + (playerLevel * 5);
    defense = 20 + (playerLevel * 4);
    magicAttack = 25 + (playerLevel * 4);
    expReward = playerLevel * 500;
    goldReward = playerLevel * 200;
}

int FinalBoss::getCurrentPhase() const
{
    double hpPercent = ((double)health / maxHealth) * 100.0;
    if (hpPercent > 75.0) return 1;
    if (hpPercent > 50.0) return 2;
    if (hpPercent > 25.0) return 3;
    return 4;  // Desperate final phase
}

void FinalBoss::updatePhase()
{
    currentPhase = getCurrentPhase();
}

int FinalBoss::getPhaseAttackMultiplier() const
{
    switch(currentPhase) {
        case 1: return 100;  // Base damage
        case 2: return 125;  // +25%
        case 3: return 150;  // +50%
        case 4: return 175;  // +75% - desperate final attacks
        default: return 100;
    }
}

bool FinalBoss::shouldEmitPhaseTransition()
{
    if (currentPhase != m_previousPhase) {
        m_previousPhase = currentPhase;
        return true;  // Emit ONCE per phase change
    }
    return false;
}

QString FinalBoss::getPhaseDescription() const
{
    switch(currentPhase) {
        case 1: return "The battle begins...";
        case 2: return "The Shadow grows stronger!";
        case 3: return "Darkness intensifies! Beware powerful attacks!";
        case 4: return "The Shadow's final desperate assault!";
        default: return "";
    }
}
