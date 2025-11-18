#include "ShadowedProgressBar.h"
#include <QPainter>
#include <QPaintEvent>
#include <QColor>
#include <QRect>
#include <Qt>

ShadowedProgressBar::ShadowedProgressBar(QWidget *parent)
    : AnimatedProgressBar(parent)
{
    // Ensure text is visible
    setTextVisible(true);
}

void ShadowedProgressBar::paintEvent(QPaintEvent *event)
{
    // Call the base class's paintEvent to draw the bar itself
    AnimatedProgressBar::paintEvent(event);

    QPainter painter(this);
    painter.setRenderHint(QPainter::TextAntialiasing);

    QString text = this->text();
    QRect text_rect = this->rect();

    // Draw the shadow/outline (color from Python: '#1e2228')
    painter.setPen(QColor("#1e2228"));
    painter.drawText(text_rect.translated(1, 1), Qt::AlignCenter, text);

    // Draw the main text (color from Python: '#ffffff')
    painter.setPen(QColor("#ffffff"));
    painter.drawText(text_rect, Qt::AlignCenter, text);
}