#ifndef ANIMATEDPROGRESSBAR_H
#define ANIMATEDPROGRESSBAR_H

#include <QProgressBar>
#include <QPropertyAnimation>
#include <QEasingCurve>

class AnimatedProgressBar : public QProgressBar
{
    Q_OBJECT
    Q_PROPERTY(int value READ value WRITE setValueAnimation)

public:
    explicit AnimatedProgressBar(QWidget *parent = nullptr);

public slots:
    void setValueAnimation(int value);

private:
    QPropertyAnimation *m_animation;
};

#endif // ANIMATEDPROGRESSBAR_H