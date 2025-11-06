#include "NewGameView.h"
#include "../components/ValidationLabel.h" // Assuming this will be created
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QFrame>
#include <QComboBox>
#include <QGraphicsDropShadowEffect>
#include <QColor>
#include <QPixmap>

NewGameView::NewGameView(QWidget *parent) : QWidget(parent)
{
    setupUi();
}

void NewGameView::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(20, 20, 20, 20);
    mainLayout->setSpacing(20);
    mainLayout->setAlignment(Qt::AlignCenter);

    // Title
    m_mainTitle = new QLabel("🌟 R E A L M   O F   L E G E N D S 🌟");
    m_mainTitle->setStyleSheet(QString(
        "font-size: 48px;"
        "font-weight: bold;"
        "color: %1;"
        "font-family: 'Segoe UI', 'Inter', sans-serif;"
    ).arg(Theme::PRIMARY.name()));
    m_mainTitle->setAlignment(Qt::AlignCenter);

    QGraphicsDropShadowEffect *shadow = new QGraphicsDropShadowEffect();
    shadow->setBlurRadius(20);
    shadow->setXOffset(2);
    shadow->setYOffset(4);
    shadow->setColor(QColor(Qt::black));
    m_mainTitle->setGraphicsEffect(shadow);
    mainLayout->addWidget(m_mainTitle);

    // Subtitle
    m_subtitle = new QLabel("Forge Your Destiny");
    m_subtitle->setStyleSheet("font-size: 18px; color: #9a96a5; margin-top: 10px;");
    m_subtitle->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_subtitle);

    // Creation Card
    m_createCard = new QFrame();
    m_createCard->setMinimumWidth(600);
    m_createCard->setMaximumWidth(800);
    m_createCard->setStyleSheet(QString("background-color: %1; border-radius: 12px;").arg(Theme::CARD.name()));
    
    QHBoxLayout *createLayout = new QHBoxLayout(m_createCard);
    createLayout->setSpacing(30);

    // Character Preview
    m_charPreview = new QFrame();
    m_charPreview->setFixedSize(200, 200);
    m_charPreview->setStyleSheet(QString("background-color: %1; border: 2px solid %2; border-radius: 12px;").arg(Theme::CARD.name()).arg(Theme::BORDER.name()));
    QVBoxLayout* previewLayout = new QVBoxLayout(m_charPreview);

    QLabel* previewLabel = new QLabel("Character Preview");
    previewLabel->setStyleSheet("font-size: 12px; color: #dc3545; font-weight: bold;");
    previewLabel->setAlignment(Qt::AlignCenter);
    previewLayout->addWidget(previewLabel);

    m_characterSpriteLabel = new QLabel();
    m_characterSpriteLabel->setAlignment(Qt::AlignCenter);
    m_characterSpriteLabel->setMinimumSize(150, 150);
    previewLayout->addWidget(m_characterSpriteLabel);

    createLayout->addWidget(m_charPreview);

    // Details Layout
    QVBoxLayout *detailsLayout = new QVBoxLayout();
    detailsLayout->setSpacing(15);

    // Name Input
    QLabel *nameTitle = new QLabel("Choose Your Name");
    nameTitle->setStyleSheet("font-size: 16px; font-weight: bold; color: #f1f0f2;");
    detailsLayout->addWidget(nameTitle);

    m_nameInput = new QLineEdit();
    m_nameInput->setPlaceholderText("Enter your hero's name...");
    m_nameInput->setStyleSheet(QString(
        "QLineEdit {"
        "    font-size: 14px;"
        "    padding: 12px;"
        "    border: 2px solid %1;"
        "    border-radius: 8px;"
        "    background-color: %2;"
        "    color: %3;"
        "    font-weight: 500;"
        "}"
        "QLineEdit:focus {"
        "    border-color: %4;"
        "    background-color: %5;"
        "}"
    ).arg(Theme::BORDER.name()).arg(Theme::CARD.name()).arg(Theme::FOREGROUND.name()).arg(Theme::PRIMARY.name()).arg(Theme::MUTED.name()));
    m_nameInput->setMaxLength(20);
    connect(m_nameInput, &QLineEdit::textChanged, this, &NewGameView::validateNameInput);
    detailsLayout->addWidget(m_nameInput);

    // Class Selection
    QLabel *classTitle = new QLabel("Choose Your Class");
    classTitle->setStyleSheet("font-size: 16px; font-weight: bold; color: #f1f0f2;");
    detailsLayout->addWidget(classTitle);

    m_classSelector = new QComboBox();
    m_classSelector->addItem("⚔️ Warrior - High strength and vitality");
    m_classSelector->addItem("🔮 Mage - Powerful magic and mana");
    m_classSelector->addItem("🗡️ Rogue - High dexterity and speed");
    m_classSelector->setStyleSheet(QString(
        "QComboBox {"
        "    font-size: 14px;"
        "    padding: 12px;"
        "    border: 2px solid %1;"
        "    border-radius: 8px;"
        "    background-color: %2;"
        "    color: %3;"
        "}"
    ).arg(Theme::BORDER.name()).arg(Theme::CARD.name()).arg(Theme::FOREGROUND.name()));
    connect(m_classSelector, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &NewGameView::updateStatsPreview);
    connect(m_classSelector, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &NewGameView::updateCharacterPreview);
    detailsLayout->addWidget(m_classSelector);

    // Validation Label
    m_validationLabel = new ValidationLabel();
    detailsLayout->addWidget(m_validationLabel);

    // Stats Preview
    QLabel *statsTitle = new QLabel("Starting Stats");
    statsTitle->setStyleSheet("font-size: 16px; font-weight: bold; color: #f1f0f2;");
    detailsLayout->addWidget(statsTitle);

    m_statsInfo = new QLabel();
    m_statsInfo->setTextFormat(Qt::RichText);
    detailsLayout->addWidget(m_statsInfo);

    // Start Button
    m_startButton = new QPushButton("✨ Begin Your Quest");
    m_startButton->setMinimumHeight(50);
    m_startButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border-radius: 8px;"
        "    padding: 10px;"
        "    font-size: 16px;"
        "    font-weight: bold;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:pressed { background-color: %4; }"
    ).arg(Theme::PRIMARY.name()).arg(Theme::PRIMARY_FOREGROUND.name()).arg(Theme::PRIMARY.lighter(110).name()).arg(Theme::PRIMARY.darker(110).name()));
    connect(m_startButton, &QPushButton::clicked, this, &NewGameView::startGame);
    detailsLayout->addWidget(m_startButton);

    createLayout->addLayout(detailsLayout);
    mainLayout->addWidget(m_createCard);

    // Footer
    m_footerLabel = new QLabel("Press Enter to create your character instantly");
    m_footerLabel->setStyleSheet("color: #6c757d; font-size: 12px; margin-top: 20px;");
    m_footerLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_footerLabel);

    validateNameInput(); // Set initial state of the button
    updateStatsPreview(); // Initialize stats display with default class
    updateCharacterPreview(); // Initialize character sprite with default class
}

void NewGameView::validateNameInput()
{
    QString name = m_nameInput->text().trimmed();
    if (name.isEmpty()) {
        m_validationLabel->showWarning("A hero needs a name!");
        m_startButton->setEnabled(false);
    } else if (name.length() < 3) {
        m_validationLabel->showWarning("Make it at least 3 characters long");
        m_startButton->setEnabled(false);
    } else {
        m_validationLabel->showSuccess("That's a heroic name!");
        m_startButton->setEnabled(true);
    }
}

void NewGameView::startGame()
{
    if (m_startButton->isEnabled()) {
        QString selectedClass;
        int classIndex = m_classSelector->currentIndex();
        if (classIndex == 0) {
            selectedClass = "Warrior";
        } else if (classIndex == 1) {
            selectedClass = "Mage";
        } else if (classIndex == 2) {
            selectedClass = "Rogue";
        } else {
            selectedClass = "Hero";
        }
        emit characterCreated(m_nameInput->text().trimmed(), selectedClass);
    }
}

void NewGameView::updateStatsPreview()
{
    int classIndex = m_classSelector->currentIndex();
    QString statsHtml;

    // Stats based on Player.cpp constructor (lines 21-41)
    if (classIndex == 0) { // Warrior
        statsHtml =
            "<html><body>"
            "<div style='line-height: 1.6; color: #abb2bf;'>"
            "<div>🏋️ Strength: <b style='color: #98c379;'>16</b></div>"
            "<div>🏃 Dexterity: <b>10</b></div>"
            "<div>🔮 Intelligence: <b style='color: #e06c75;'>6</b></div>"
            "<div>❤️ Vitality: <b style='color: #98c379;'>14</b></div>"
            "<div>💚 Health: <b style='color: #98c379;'>120</b></div>"
            "<div>💙 Mana: <b>50</b></div>"
            "</div></body></html>";
    } else if (classIndex == 1) { // Mage
        statsHtml =
            "<html><body>"
            "<div style='line-height: 1.6; color: #abb2bf;'>"
            "<div>🏋️ Strength: <b style='color: #e06c75;'>8</b></div>"
            "<div>🏃 Dexterity: <b style='color: #e06c75;'>8</b></div>"
            "<div>🔮 Intelligence: <b style='color: #98c379;'>16</b></div>"
            "<div>❤️ Vitality: <b>10</b></div>"
            "<div>💚 Health: <b>100</b></div>"
            "<div>💙 Mana: <b style='color: #98c379;'>80</b></div>"
            "</div></body></html>";
    } else if (classIndex == 2) { // Rogue
        statsHtml =
            "<html><body>"
            "<div style='line-height: 1.6; color: #abb2bf;'>"
            "<div>🏋️ Strength: <b>12</b></div>"
            "<div>🏃 Dexterity: <b style='color: #98c379;'>16</b></div>"
            "<div>🔮 Intelligence: <b style='color: #e06c75;'>8</b></div>"
            "<div>❤️ Vitality: <b style='color: #e06c75;'>8</b></div>"
            "<div>💚 Health: <b style='color: #e06c75;'>90</b></div>"
            "<div>💙 Mana: <b>50</b></div>"
            "</div></body></html>";
    } else { // Default/Hero
        statsHtml =
            "<html><body>"
            "<div style='line-height: 1.6; color: #abb2bf;'>"
            "<div>🏋️ Strength: <b>12</b></div>"
            "<div>🏃 Dexterity: <b>10</b></div>"
            "<div>🔮 Intelligence: <b>8</b></div>"
            "<div>❤️ Vitality: <b>10</b></div>"
            "<div>💚 Health: <b>100</b></div>"
            "<div>💙 Mana: <b>50</b></div>"
            "</div></body></html>";
    }

    m_statsInfo->setText(statsHtml);
}

void NewGameView::updateCharacterPreview()
{
    int classIndex = m_classSelector->currentIndex();
    QString spritePath;

    // Map class index to sprite file
    if (classIndex == 0) { // Warrior
        spritePath = ":/assets/warrior.png";
    } else if (classIndex == 1) { // Mage
        spritePath = ":/assets/mage.png";
    } else if (classIndex == 2) { // Rogue
        spritePath = ":/assets/rogue.png";
    } else { // Default
        spritePath = ":/assets/warrior.png";
    }

    // Load and display the sprite
    QPixmap sprite(spritePath);
    if (!sprite.isNull()) {
        m_characterSpriteLabel->setPixmap(sprite.scaled(140, 140, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    } else {
        m_characterSpriteLabel->setText("👤"); // Fallback emoji
    }
}