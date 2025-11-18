#include "ScalablePixmapLabel.h"
#include <QSizePolicy>
#include <Qt>

ScalablePixmapLabel::ScalablePixmapLabel(QWidget *parent)
    : QLabel(parent)
{
    setMinimumSize(150, 150); // Set a minimum size for the sprite
    setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    setAlignment(Qt::AlignCenter); // Center the pixmap
}

void ScalablePixmapLabel::setOriginalPixmap(const QPixmap &pixmap)
{
    m_originalPixmap = pixmap;
    updatePixmap(this->size());
}

void ScalablePixmapLabel::resizeEvent(QResizeEvent *event)
{
    if (!m_originalPixmap.isNull()) {
        updatePixmap(event->size());
    }
    QLabel::resizeEvent(event);
}

void ScalablePixmapLabel::updatePixmap(const QSize &size)
{
    if (m_originalPixmap.isNull()) {
        return;
    }
    // Scale the original pixmap to fit the new size while maintaining aspect ratio
    QPixmap scaledPixmap = m_originalPixmap.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    setPixmap(scaledPixmap);
}