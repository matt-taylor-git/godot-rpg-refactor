#ifndef CHARACTERPREVIEWWIDGET_H
#define CHARACTERPREVIEWWIDGET_H

#include <QFrame>

class QLabel;

class CharacterPreviewWidget : public QFrame
{
    Q_OBJECT
public:
    explicit CharacterPreviewWidget(QWidget *parent = nullptr);

private:
    void setupUi();
    QLabel *m_spriteLabel;
    QLabel *m_nameLabel;
};

#endif // CHARACTERPREVIEWWIDGET_H
