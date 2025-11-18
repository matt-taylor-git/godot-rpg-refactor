#include "AnimatedProgressBar.h"

AnimatedProgressBar::AnimatedProgressBar(QWidget *parent)
    : QProgressBar(parent),
      m_animation(new QPropertyAnimation(this, "value", this))
{
    m_animation->setDuration(500); // 500ms animation
    m_animation->setEasingCurve(QEasingCurve::OutCubic);
}

void AnimatedProgressBar::setValueAnimation(int value)
{
    if (m_animation->state() == QAbstractAnimation::Running) {
        m_animation->stop();
    }

    m_animation->setStartValue(this->value());
    m_animation->setEndValue(value);
    m_animation->start();
}