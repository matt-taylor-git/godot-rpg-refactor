#include "CharacterPreviewWidget.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QLabel>

CharacterPreviewWidget::CharacterPreviewWidget(QWidget *parent) : QFrame(parent)
{
    setupUi();
}

void CharacterPreviewWidget::setupUi()
{
    setFixedSize(250, 250);
    setStyleSheet(QString(
        "CharacterPreviewWidget {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: 12px;"
        "}"
    ).arg(Theme::CARD.name()).arg(Theme::BORDER.name()));

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(10, 10, 10, 10);

    QLabel *title = new QLabel("Character Preview");
    title->setStyleSheet("font-size: 14px; font-weight: bold; color: #dc3545;");
    title->setAlignment(Qt::AlignCenter);
    layout->addWidget(title);

    m_spriteLabel = new QLabel();
    m_spriteLabel->setMinimumSize(150, 150);
    m_spriteLabel->setAlignment(Qt::AlignCenter);
    m_spriteLabel->setStyleSheet("background: transparent;");
    m_spriteLabel->setText("👤"); // Placeholder icon
    layout->addWidget(m_spriteLabel);

    m_nameLabel = new QLabel("Name: Hero");
    m_nameLabel->setStyleSheet(QString(
        "QLabel {"
        "    color: %1;"
        "    font-size: 12px;"
        "    font-weight: bold;"
        "}"
    ).arg(Theme::FOREGROUND.name()));
    m_nameLabel->setAlignment(Qt::AlignCenter);
    layout->addWidget(m_nameLabel);
}
