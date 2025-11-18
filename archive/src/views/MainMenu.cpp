#include "MainMenu.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QGraphicsDropShadowEffect>
#include <QColor>

MainMenu::MainMenu(QWidget *parent) : QWidget(parent)
{
    setupUi();
}

void MainMenu::setupUi()
{
    setStyleSheet(QString("background-color: %1;").arg(Theme::BACKGROUND.name()));

    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(20, 20, 20, 20);
    mainLayout->setSpacing(20);
    mainLayout->setAlignment(Qt::AlignCenter);

    // Title
    QLabel *title = new QLabel("🌟 R E A L M   O F   L E G E N D S 🌟");
    title->setStyleSheet(QString(
        "font-size: 48px;"
        "font-weight: bold;"
        "color: %1;"
        "font-family: 'Segoe UI', 'Inter', sans-serif;"
    ).arg(Theme::PRIMARY.name()));
    title->setAlignment(Qt::AlignCenter);

    QGraphicsDropShadowEffect *shadow = new QGraphicsDropShadowEffect();
    shadow->setBlurRadius(20);
    shadow->setXOffset(2);
    shadow->setYOffset(4);
    shadow->setColor(QColor(Qt::black));
    title->setGraphicsEffect(shadow);
    mainLayout->addWidget(title);

    // Subtitle
    QLabel *subtitle = new QLabel("Choose Your Path");
    subtitle->setStyleSheet("font-size: 18px; color: #9a96a5; margin-top: 10px;");
    subtitle->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(subtitle);

    // Menu buttons
    QVBoxLayout *menuLayout = new QVBoxLayout();
    menuLayout->setSpacing(15);
    menuLayout->setAlignment(Qt::AlignCenter);

    m_newGameButton = new QPushButton("🆕 New Game");
    m_newGameButton->setMinimumHeight(50);
    m_newGameButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border-radius: 8px;"
        "    padding: 10px;"
        "    font-size: 16px;"
        "    font-weight: bold;"
        "    min-width: 200px;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:pressed { background-color: %4; }"
    ).arg(Theme::PRIMARY.name()).arg(Theme::PRIMARY_FOREGROUND.name()).arg(Theme::PRIMARY.lighter(110).name()).arg(Theme::PRIMARY.darker(110).name()));
    connect(m_newGameButton, &QPushButton::clicked, this, &MainMenu::newGameRequested);
    menuLayout->addWidget(m_newGameButton);

    m_loadGameButton = new QPushButton("📁 Load Game");
    m_loadGameButton->setMinimumHeight(50);
    m_loadGameButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border-radius: 8px;"
        "    padding: 10px;"
        "    font-size: 16px;"
        "    font-weight: bold;"
        "    min-width: 200px;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:pressed { background-color: %4; }"
    ).arg(Theme::SECONDARY.name()).arg(Theme::FOREGROUND.name()).arg(Theme::SECONDARY.lighter(110).name()).arg(Theme::SECONDARY.darker(110).name()));
    connect(m_loadGameButton, &QPushButton::clicked, this, &MainMenu::loadGameRequested);
    menuLayout->addWidget(m_loadGameButton);

    m_exitButton = new QPushButton("🚪 Exit");
    m_exitButton->setMinimumHeight(50);
    m_exitButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border-radius: 8px;"
        "    padding: 10px;"
        "    font-size: 16px;"
        "    font-weight: bold;"
        "    min-width: 200px;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:pressed { background-color: %4; }"
    ).arg(Theme::DESTRUCTIVE.name()).arg(Theme::DESTRUCTIVE_FOREGROUND.name()).arg(Theme::DESTRUCTIVE.lighter(110).name()).arg(Theme::DESTRUCTIVE.darker(110).name()));
    connect(m_exitButton, &QPushButton::clicked, this, &MainMenu::exitRequested);
    menuLayout->addWidget(m_exitButton);

    mainLayout->addLayout(menuLayout);

    // Footer
    QLabel *footer = new QLabel("Built with Qt6 • C++17");
    footer->setStyleSheet("color: #6c757d; font-size: 12px; margin-top: 40px;");
    footer->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(footer);
}
