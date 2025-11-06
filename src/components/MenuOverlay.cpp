#include "MenuOverlay.h"
#include "../views/InventoryPage.h"
#include "../views/StatsPage.h"
#include "../views/ShopPage.h"
#include "../views/SaveLoadPage.h"
#include "../models/Player.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QTabWidget>
#include <QPushButton>
#include <QPropertyAnimation>
#include <QPainter>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QLabel>
#include <QFont>
#include <QApplication>

MenuOverlay::MenuOverlay(QWidget *parent)
    : QWidget(parent)
    , m_opacity(0.0)
    , m_currentPlayer(nullptr)
    , m_previousFocusWidget(nullptr)
{
    setAttribute(Qt::WA_TransparentForMouseEvents, false);
    setAttribute(Qt::WA_NoSystemBackground);
    setAttribute(Qt::WA_TranslucentBackground);
    setFocusPolicy(Qt::StrongFocus);

    setupUi();

    m_animation = new QPropertyAnimation(this, "opacity");
    m_animation->setDuration(200);

    // Set up permanent connection for animation finished signal
    connect(m_animation, &QPropertyAnimation::finished, this, [this]() {
        // Only hide and emit signal if we were animating to 0 (hiding)
        if (m_animation->endValue().toReal() == 0.0) {
            hide();
            // Restore focus to previous widget
            if (m_previousFocusWidget) {
                m_previousFocusWidget->setFocus();
                m_previousFocusWidget = nullptr;
            }
            emit overlayHidden();
        }
    });

    hide();
}

void MenuOverlay::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(50, 50, 50, 50);

    // Content widget (the actual menu dialog)
    m_contentWidget = new QWidget();
    m_contentWidget->setObjectName("menuOverlayContent");
    m_contentWidget->setStyleSheet(QString(
        "QWidget#menuOverlayContent { "
        "background-color: %1; "
        "border: %2px solid %3; "
        "border-radius: %4px; "
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER_WIDTH_MEDIUM)
     .arg(Theme::ACCENT.name())
     .arg(Theme::BORDER_RADIUS_XL));

    QVBoxLayout *contentLayout = new QVBoxLayout(m_contentWidget);
    contentLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    contentLayout->setSpacing(Theme::SPACING_MD);

    // Header with title and close button
    QHBoxLayout *headerLayout = new QHBoxLayout();

    QLabel *titleLabel = new QLabel("Menu");
    QFont titleFont;
    titleFont.setPointSize(Theme::FONT_SIZE_XL);
    titleFont.setWeight(static_cast<QFont::Weight>(Theme::FONT_WEIGHT_SEMIBOLD));
    titleLabel->setFont(titleFont);
    titleLabel->setStyleSheet(QString("color: %1;").arg(Theme::ACCENT.name()));

    m_closeButton = new QPushButton("✕");
    m_closeButton->setObjectName("closeButton");
    m_closeButton->setFixedSize(32, 32);
    m_closeButton->setStyleSheet(QString(
        "QPushButton#closeButton { "
        "background-color: %1; "
        "color: %2; "
        "border: 1px solid %3; "
        "border-radius: 16px; "
        "font-size: 16px; "
        "font-weight: bold; "
        "} "
        "QPushButton#closeButton:hover { "
        "background-color: %4; "
        "}"
    ).arg(Theme::MUTED.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::DESTRUCTIVE.name()));
    connect(m_closeButton, &QPushButton::clicked, this, &MenuOverlay::hideOverlay);

    headerLayout->addWidget(titleLabel);
    headerLayout->addStretch();
    headerLayout->addWidget(m_closeButton);
    contentLayout->addLayout(headerLayout);

    // Tab widget
    m_tabWidget = new QTabWidget();
    m_tabWidget->setMinimumSize(600, 400);
    m_tabWidget->setStyleSheet(QString(
        "QTabWidget::pane { "
        "border: 1px solid %1; "
        "border-radius: %2px; "
        "background-color: %3; "
        "} "
        "QTabBar::tab { "
        "background-color: %4; "
        "color: %5; "
        "padding: 10px 20px; "
        "margin-right: 2px; "
        "border: 1px solid %6; "
        "border-bottom: none; "
        "border-top-left-radius: 4px; "
        "border-top-right-radius: 4px; "
        "} "
        "QTabBar::tab:selected { "
        "background-color: %7; "
        "color: %8; "
        "border-color: %9; "
        "} "
        "QTabBar::tab:hover { "
        "background-color: %10; "
        "}"
    ).arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::CARD.name())
     .arg(Theme::SECONDARY.name())
     .arg(Theme::MUTED_FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT_FOREGROUND.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::MUTED.name()));

    // Create the pages
    m_inventoryPage = new InventoryPage();
    m_statsPage = new StatsPage();
    m_shopPage = new ShopPage();
    m_saveLoadPage = new SaveLoadPage();

    // Connect back signals to close the overlay
    connect(m_inventoryPage, &InventoryPage::backRequested, this, &MenuOverlay::hideOverlay);
    connect(m_statsPage, &StatsPage::backRequested, this, &MenuOverlay::hideOverlay);
    connect(m_shopPage, &ShopPage::leaveRequested, this, &MenuOverlay::hideOverlay);
    connect(m_saveLoadPage, &SaveLoadPage::backRequested, this, &MenuOverlay::hideOverlay);

    // Connect item change signals to refresh content
    connect(m_inventoryPage, &InventoryPage::itemEquipped, this, &MenuOverlay::handleItemChanged);
    connect(m_shopPage, &ShopPage::itemPurchased, this, &MenuOverlay::handleItemChanged);

    // Connect SaveLoadPage signals
    connect(m_saveLoadPage, &SaveLoadPage::quickSaveRequested, this, &MenuOverlay::saveRequested);
    connect(m_saveLoadPage, &SaveLoadPage::quickLoadRequested, this, &MenuOverlay::loadRequested);
    connect(m_saveLoadPage, &SaveLoadPage::saveToSlotRequested, this, &MenuOverlay::saveToSlotRequested);
    connect(m_saveLoadPage, &SaveLoadPage::loadFromSlotRequested, this, &MenuOverlay::loadFromSlotRequested);
    connect(m_saveLoadPage, &SaveLoadPage::deleteSlotRequested, this, &MenuOverlay::deleteSlotRequested);

    // Add tabs
    m_tabWidget->addTab(m_inventoryPage, "🎒 Inventory");
    m_tabWidget->addTab(m_statsPage, "📊 Stats");
    m_tabWidget->addTab(m_shopPage, "🏪 Shop");
    m_tabWidget->addTab(m_saveLoadPage, "💾 Save/Load");

    contentLayout->addWidget(m_tabWidget);

    // Save/Load buttons row
    QHBoxLayout *saveLoadLayout = new QHBoxLayout();
    saveLoadLayout->setSpacing(Theme::SPACING_MD);

    m_saveButton = new QPushButton("💾 Save Game");
    m_saveButton->setObjectName("saveButton");
    m_saveButton->setMinimumHeight(40);
    m_saveButton->setStyleSheet(QString(
        "QPushButton#saveButton { "
        "background-color: %1; "
        "color: %2; "
        "border: 1px solid %3; "
        "border-radius: %4px; "
        "padding: 8px 16px; "
        "font-size: %5px; "
        "font-weight: %6; "
        "} "
        "QPushButton#saveButton:hover { "
        "background-color: %7; "
        "}"
    ).arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT_FOREGROUND.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_MEDIUM)
     .arg(Theme::ACCENT.lighter(110).name()));
    connect(m_saveButton, &QPushButton::clicked, this, &MenuOverlay::handleSaveClicked);

    m_loadButton = new QPushButton("📂 Load Game");
    m_loadButton->setObjectName("loadButton");
    m_loadButton->setMinimumHeight(40);
    m_loadButton->setStyleSheet(QString(
        "QPushButton#loadButton { "
        "background-color: %1; "
        "color: %2; "
        "border: 1px solid %3; "
        "border-radius: %4px; "
        "padding: 8px 16px; "
        "font-size: %5px; "
        "font-weight: %6; "
        "} "
        "QPushButton#loadButton:hover { "
        "background-color: %7; "
        "}"
    ).arg(Theme::SECONDARY.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_MEDIUM)
     .arg(Theme::MUTED.name()));
    connect(m_loadButton, &QPushButton::clicked, this, &MenuOverlay::handleLoadClicked);

    saveLoadLayout->addWidget(m_saveButton);
    saveLoadLayout->addWidget(m_loadButton);
    contentLayout->addLayout(saveLoadLayout);
    // Add quit button
    QPushButton *quitButton = new QPushButton("🚪 Quit Game");
    quitButton->setObjectName("quitButton");
    quitButton->setMinimumHeight(40);
    quitButton->setStyleSheet(QString(
        "QPushButton#quitButton { "
        "background-color: %1; "
        "color: %2; "
        "border: 1px solid %3; "
        "border-radius: 8px; "
        "font-size: 14px; "
        "font-weight: bold; "
        "padding: 10px; "
        "} "
        "QPushButton#quitButton:hover { "
        "background-color: %4; "
        "}"
    ).arg(Theme::DESTRUCTIVE.name())
     .arg(Theme::DESTRUCTIVE_FOREGROUND.name())
     .arg(Theme::DESTRUCTIVE.darker(110).name())
     .arg(Theme::DESTRUCTIVE.lighter(110).name()));
    connect(quitButton, &QPushButton::clicked, this, &MenuOverlay::handleQuitClicked);
    contentLayout->addWidget(quitButton);

    // Add hint text
    QLabel *hintLabel = new QLabel("Press ESC to close");
    hintLabel->setStyleSheet(QString("color: %1; font-size: %2px;")
                                .arg(Theme::MUTED_FOREGROUND.name())
                                .arg(Theme::FONT_SIZE_SM));
    hintLabel->setAlignment(Qt::AlignCenter);
    contentLayout->addWidget(hintLabel);

    mainLayout->addWidget(m_contentWidget);
}

void MenuOverlay::showOverlay()
{
    // Stop any in-progress animation to prevent race conditions
    m_animation->stop();

    // Store the currently focused widget so we can restore it later
    m_previousFocusWidget = QApplication::focusWidget();

    show();
    raise();
    setFocus();
    animateShow();
}

void MenuOverlay::hideOverlay()
{
    // Check if we're already hiding - prevent redundant animations
    if (m_animation->state() == QAbstractAnimation::Running &&
        m_animation->endValue().toReal() == 0.0) {
        return;  // Already hiding
    }

    animateHide();
}

void MenuOverlay::updateContent(Player *player)
{
    m_currentPlayer = player;
    if (player) {
        m_inventoryPage->updateInventory(player);
        m_statsPage->updateStats(player);
        m_shopPage->updateShop(player);
        m_saveLoadPage->refreshSaveSlots();
    }
}

void MenuOverlay::setOpacity(qreal opacity)
{
    m_opacity = opacity;
    update();
}

void MenuOverlay::paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);

    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    // Draw semi-transparent background
    QColor overlayColor = QColor(0, 0, 0);
    overlayColor.setAlphaF(0.7 * m_opacity);
    painter.fillRect(rect(), overlayColor);

    // The content widget will be drawn by Qt's normal rendering
}

void MenuOverlay::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Escape) {
        hideOverlay();
        event->accept();
    } else {
        QWidget::keyPressEvent(event);
    }
}

void MenuOverlay::mousePressEvent(QMouseEvent *event)
{
    // Close overlay if clicking outside the content widget
    if (!m_contentWidget->geometry().contains(event->pos())) {
        hideOverlay();
        event->accept();
    } else {
        QWidget::mousePressEvent(event);
    }
}

void MenuOverlay::animateShow()
{
    m_animation->stop();
    m_animation->setStartValue(0.0);
    m_animation->setEndValue(1.0);
    m_animation->start();
}

void MenuOverlay::animateHide()
{
    m_animation->stop();
    m_animation->setStartValue(m_opacity);
    m_animation->setEndValue(0.0);
    m_animation->start();
    // Note: The finished signal is handled by the permanent connection in the constructor
}

void MenuOverlay::handleItemChanged()
{
    // Refresh all tabs when inventory or shop changes
    if (m_currentPlayer) {
        updateContent(m_currentPlayer);
    }
}

void MenuOverlay::handleSaveClicked()
{
    emit saveRequested();
    hideOverlay();
}

void MenuOverlay::handleLoadClicked()
{
    emit loadRequested();
    hideOverlay();
}

void MenuOverlay::handleQuitClicked()
{
    emit quitRequested();
}
