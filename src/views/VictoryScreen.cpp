#include "VictoryScreen.h"
#include "../theme/Theme.h"
#include "../components/ParticleSystem.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QPushButton>
#include <QFont>
#include <QGraphicsDropShadowEffect>
#include <QKeyEvent>
#include <QTimer>

VictoryScreen::VictoryScreen(int finalLevel, int playtime, int kills, int deaths,
                             int gold, int quests, QWidget *parent)
    : QDialog(parent),
      m_finalLevel(finalLevel),
      m_playtime(playtime),
      m_kills(kills),
      m_deaths(deaths),
      m_gold(gold),
      m_quests(quests),
      m_victoryTitle(nullptr),
      m_victoryMessage(nullptr),
      m_statsContainer(nullptr),
      m_continueButton(nullptr),
      m_menuButton(nullptr),
      m_particleSystem(nullptr)
{
    setWindowTitle("Victory!");
    setModal(true);
    setMinimumSize(800, 600);
    setupUi();

    // Initialize particle system
    m_particleSystem = new ParticleSystem(this);
    m_particleSystem->setGeometry(rect());
    m_particleSystem->raise();

    // Trigger celebratory particle effects after a short delay
    QTimer::singleShot(300, [this]() {
        if (m_particleSystem) {
            QPoint centerPos = rect().center();
            m_particleSystem->victoryExplosion(centerPos);

            // Trigger additional bursts for extra celebration
            QTimer::singleShot(600, [this, centerPos]() {
                m_particleSystem->goldRewardBurst(centerPos + QPoint(0, -100));
            });
            QTimer::singleShot(1000, [this, centerPos]() {
                m_particleSystem->createBurst(centerPos + QPoint(0, 100), 12, "star", "#9b59b6", false);
            });
        }
    });
}

void VictoryScreen::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(Theme::SPACING_XL);
    mainLayout->setContentsMargins(Theme::SPACING_XL, Theme::SPACING_XL,
                                   Theme::SPACING_XL, Theme::SPACING_XL);

    // Victory header
    mainLayout->addWidget(createVictoryHeader());

    // Add spacing
    mainLayout->addSpacing(Theme::SPACING_LG);

    // Statistics grid (2 columns x 3 rows)
    QGridLayout *statsGrid = new QGridLayout();
    statsGrid->setSpacing(Theme::SPACING_MD);
    statsGrid->setHorizontalSpacing(Theme::SPACING_LG);

    statsGrid->addWidget(createStatisticsCard("Final Level", QString::number(m_finalLevel)), 0, 0);
    statsGrid->addWidget(createStatisticsCard("Playtime", formatPlaytime(m_playtime)), 0, 1);
    statsGrid->addWidget(createStatisticsCard("Enemies Defeated", QString::number(m_kills)), 1, 0);
    statsGrid->addWidget(createStatisticsCard("Times Died", QString::number(m_deaths)), 1, 1);
    statsGrid->addWidget(createStatisticsCard("Gold Earned", QString::number(m_gold)), 2, 0);
    statsGrid->addWidget(createStatisticsCard("Quests Completed", QString::number(m_quests)), 2, 1);

    mainLayout->addLayout(statsGrid);

    // Add spacing
    mainLayout->addSpacing(Theme::SPACING_LG);

    // Action buttons
    mainLayout->addWidget(createActionButtons());
}

QWidget* VictoryScreen::createVictoryHeader()
{
    QWidget *header = new QWidget();
    QVBoxLayout *layout = new QVBoxLayout(header);
    layout->setSpacing(Theme::SPACING_MD);

    // Victory title with glow effect
    m_victoryTitle = new QLabel("🏆 VICTORY! 🏆");
    QFont titleFont;
    titleFont.setPointSize(Theme::FONT_SIZE_XXL * 2);
    titleFont.setBold(true);
    m_victoryTitle->setFont(titleFont);
    m_victoryTitle->setAlignment(Qt::AlignCenter);
    m_victoryTitle->setStyleSheet(QString(
        "color: %1; "
        "background: qlineargradient(x1:0, y1:0, x2:1, y2:0, "
        "    stop:0 #FFD700, stop:0.5 #FFA500, stop:1 #FFD700);"
        "-webkit-background-clip: text;"
    ).arg(Theme::PRIMARY.name()));

    // Apply glow effect
    QGraphicsDropShadowEffect *glow = new QGraphicsDropShadowEffect;
    glow->setBlurRadius(30);
    glow->setColor(QColor(255, 215, 0, 200));  // Gold with alpha
    glow->setOffset(0, 0);
    m_victoryTitle->setGraphicsEffect(glow);

    layout->addWidget(m_victoryTitle);

    // Victory message
    m_victoryMessage = new QLabel("You have defeated the final boss and completed the game!");
    QFont messageFont;
    messageFont.setPointSize(Theme::FONT_SIZE_LG);
    m_victoryMessage->setFont(messageFont);
    m_victoryMessage->setAlignment(Qt::AlignCenter);
    m_victoryMessage->setStyleSheet(QString("color: %1;").arg(Theme::FOREGROUND.name()));
    m_victoryMessage->setWordWrap(true);

    layout->addWidget(m_victoryMessage);

    return header;
}

QWidget* VictoryScreen::createStatisticsCard(const QString &label, const QString &value)
{
    QWidget *card = new QWidget();
    card->setMinimumHeight(120);
    card->setStyleSheet(QString(
        "QWidget {"
        "    background-color: %1; "
        "    border: 2px solid %2; "
        "    border-radius: %3px; "
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_LG));

    QVBoxLayout *layout = new QVBoxLayout(card);
    layout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG,
                               Theme::SPACING_LG, Theme::SPACING_LG);
    layout->setSpacing(Theme::SPACING_SM);

    // Label
    QLabel *labelWidget = new QLabel(label);
    QFont labelFont;
    labelFont.setPointSize(Theme::FONT_SIZE_MD);
    labelWidget->setFont(labelFont);
    labelWidget->setAlignment(Qt::AlignCenter);
    labelWidget->setStyleSheet(QString("color: %1; border: none;").arg(Theme::MUTED_FOREGROUND.name()));

    // Value
    QLabel *valueWidget = new QLabel(value);
    QFont valueFont;
    valueFont.setPointSize(Theme::FONT_SIZE_XXL);
    valueFont.setBold(true);
    valueWidget->setFont(valueFont);
    valueWidget->setAlignment(Qt::AlignCenter);
    valueWidget->setStyleSheet(QString("color: %1; border: none;").arg(Theme::PRIMARY.name()));

    layout->addWidget(labelWidget);
    layout->addWidget(valueWidget);
    layout->addStretch();

    return card;
}

QWidget* VictoryScreen::createActionButtons()
{
    QWidget *buttonContainer = new QWidget();
    QHBoxLayout *layout = new QHBoxLayout(buttonContainer);
    layout->setSpacing(Theme::SPACING_LG);

    // Main Menu button
    m_menuButton = new QPushButton("Return to Main Menu (Esc)");
    m_menuButton->setMinimumHeight(50);
    m_menuButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: 2px solid %3;"
        "    border-radius: %4px;"
        "    padding: %5px %6px;"
        "    font-size: %7px;"
        "    font-weight: %8;"
        "}"
        "QPushButton:hover {"
        "    background-color: %9;"
        "}"
    ).arg(Theme::SECONDARY.name())
     .arg(Theme::SECONDARY_FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::SPACING_XL)
     .arg(Theme::FONT_SIZE_LG)
     .arg(Theme::FONT_WEIGHT_BOLD)
     .arg(Theme::MUTED.name()));
    connect(m_menuButton, &QPushButton::clicked, this, [this]() {
        emit returnToMainMenu();
        accept();
    });

    // Continue button
    m_continueButton = new QPushButton("Continue Playing (Space/Enter)");
    m_continueButton->setMinimumHeight(50);
    m_continueButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: none;"
        "    border-radius: %3px;"
        "    padding: %4px %5px;"
        "    font-size: %6px;"
        "    font-weight: %7;"
        "}"
        "QPushButton:hover {"
        "    opacity: 0.9;"
        "}"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::SPACING_XL)
     .arg(Theme::FONT_SIZE_LG)
     .arg(Theme::FONT_WEIGHT_BOLD));
    connect(m_continueButton, &QPushButton::clicked, this, [this]() {
        emit continuePlaying();
        accept();
    });

    layout->addWidget(m_menuButton);
    layout->addWidget(m_continueButton);

    return buttonContainer;
}

QString VictoryScreen::formatPlaytime(int minutes) const
{
    if (minutes < 60) {
        return QString("%1m").arg(minutes);
    }
    int hours = minutes / 60;
    int mins = minutes % 60;
    return QString("%1h %2m").arg(hours).arg(mins);
}

void VictoryScreen::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Space || event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter) {
        emit continuePlaying();
        accept();
    } else if (event->key() == Qt::Key_Escape) {
        emit returnToMainMenu();
        accept();
    } else {
        QDialog::keyPressEvent(event);
    }
}
