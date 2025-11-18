#ifndef SCALABLEPIXMAPLABEL_H
#define SCALABLEPIXMAPLABEL_H

#include <QLabel>
#include <QPixmap>
#include <QResizeEvent>

class ScalablePixmapLabel : public QLabel
{
    Q_OBJECT

public:
    explicit ScalablePixmapLabel(QWidget *parent = nullptr);

    void setOriginalPixmap(const QPixmap &pixmap);

protected:
    void resizeEvent(QResizeEvent *event) override;

private:
    QPixmap m_originalPixmap;
    void updatePixmap(const QSize &size);
};

#endif // SCALABLEPIXMAPLABEL_H