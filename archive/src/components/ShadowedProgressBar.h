#ifndef SHADOWEDPROGRESSBAR_H
#define SHADOWEDPROGRESSBAR_H

#include "AnimatedProgressBar.h"

class ShadowedProgressBar : public AnimatedProgressBar
{
    Q_OBJECT

public:
    explicit ShadowedProgressBar(QWidget *parent = nullptr);

protected:
    void paintEvent(QPaintEvent *event) override;
};

#endif // SHADOWEDPROGRESSBAR_H