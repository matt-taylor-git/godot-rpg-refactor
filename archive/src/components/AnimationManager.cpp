#include "AnimationManager.h"
#include "../views/CombatPage.h"
#include "ParticleSystem.h"
#include <QPropertyAnimation>
#include <QSequentialAnimationGroup>
#include <QPauseAnimation>
#include <QLabel>
#include <QEasingCurve>
#include <QTimer>

AnimationManager::AnimationManager(CombatPage *combatPage, QObject *parent)
    : QObject(parent), m_combatPage(combatPage)
{
}

void AnimationManager::playPlayerAttackAnimation()
{
    QLabel* heroSprite = m_combatPage->getHeroSpriteLabel();
    QLabel* enemySprite = m_combatPage->getEnemySpriteLabel();
    ParticleSystem* particles = m_combatPage->getParticleSystem();

    if (!heroSprite || !enemySprite) {
        emit animationFinished();
        return;
    }

    // Raise hero sprite to ensure it renders on top of sibling widgets during animation
    heroSprite->raise();

    QPoint startPos = heroSprite->pos();
    QPoint endPos = enemySprite->pos();

    QSequentialAnimationGroup *group = new QSequentialAnimationGroup(this);

    // Animation to move to the enemy
    QPropertyAnimation *attackAnimation = new QPropertyAnimation(heroSprite, "pos");
    attackAnimation->setDuration(300);
    attackAnimation->setStartValue(startPos);
    attackAnimation->setEndValue(endPos);
    attackAnimation->setEasingCurve(QEasingCurve::InOutQuad);

    // Trigger particle effect at impact (midpoint of attack)
    if (particles) {
        QTimer::singleShot(ParticleConstants::ATTACK_IMPACT_DELAY_MS, [particles, enemySprite]() {
            QPoint impactPos = enemySprite->geometry().center();
            particles->createBurst(impactPos, 10, "spark", "#e74c3c", false);
        });
    }

    // Animation to return to the original position
    QPropertyAnimation *returnAnimation = new QPropertyAnimation(heroSprite, "pos");
    returnAnimation->setDuration(300);
    returnAnimation->setStartValue(endPos);
    returnAnimation->setEndValue(startPos);
    returnAnimation->setEasingCurve(QEasingCurve::InOutQuad);

    group->addAnimation(attackAnimation);
    group->addPause(100);
    group->addAnimation(returnAnimation);

    connect(group, &QSequentialAnimationGroup::finished, this, &AnimationManager::animationFinished);
    connect(group, &QSequentialAnimationGroup::finished, group, &QSequentialAnimationGroup::deleteLater);

    group->start();
}

void AnimationManager::playDamageAnimation(QLabel* target)
{
    ParticleSystem* particles = m_combatPage->getParticleSystem();

    if (particles && target) {
        // Trigger damage indicator particles at target location
        QPoint damagePos = target->geometry().center();
        particles->createBurst(damagePos, 8, "spark", "#e74c3c", false);
    }

    emit animationFinished();
}
