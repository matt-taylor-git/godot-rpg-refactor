#include "LoreBookPage.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFont>
#include <QVariant>

LoreBookPage::LoreBookPage(QWidget *parent)
    : QWidget(parent)
    , m_codexManager(nullptr)
    , m_currentCategory("Bestiary")
{
    setupUi();
}

void LoreBookPage::setupUi()
{
    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_MD);

    // Title
    m_titleLabel = new QLabel("Lore Codex", this);
    QFont titleFont;
    titleFont.setPixelSize(Theme::FONT_SIZE_XXL);
    titleFont.setBold(true);
    m_titleLabel->setFont(titleFont);
    m_titleLabel->setStyleSheet(QString("color: %1; padding: %2px;")
                                .arg(Theme::PRIMARY.name())
                                .arg(Theme::SPACING_SM));
    m_titleLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_titleLabel);

    // Content layout (tabs + list + details)
    QHBoxLayout *contentLayout = new QHBoxLayout();
    contentLayout->setSpacing(Theme::SPACING_MD);

    // Category tabs (left side)
    m_categoryTabs = new QTabWidget(this);
    m_categoryTabs->setMaximumWidth(150);
    m_categoryTabs->setTabPosition(QTabWidget::West);
    m_categoryTabs->addTab(new QWidget(), "Bestiary");
    m_categoryTabs->addTab(new QWidget(), "Items");
    m_categoryTabs->addTab(new QWidget(), "World");
    m_categoryTabs->addTab(new QWidget(), "Characters");
    m_categoryTabs->addTab(new QWidget(), "Locations");

    m_categoryTabs->setStyleSheet(QString(
        "QTabWidget::pane {"
        "    border: none;"
        "}"
        "QTabBar::tab {"
        "    background-color: %1;"
        "    color: %2;"
        "    padding: %3px %4px;"
        "    border: %5px solid %6;"
        "    border-radius: %7px;"
        "    margin: %8px;"
        "    min-width: 80px;"
        "}"
        "QTabBar::tab:selected {"
        "    background-color: %9;"
        "    color: %10;"
        "    border-color: %11;"
        "}"
        "QTabBar::tab:hover {"
        "    background-color: %12;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::SPACING_MD)
     .arg(Theme::SPACING_SM)
     .arg(Theme::BORDER_WIDTH_THIN)
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_XS)
     .arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT_FOREGROUND.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::SECONDARY.name()));

    connect(m_categoryTabs, &QTabWidget::currentChanged, this, &LoreBookPage::handleCategoryChanged);
    contentLayout->addWidget(m_categoryTabs);

    // Entry list (middle)
    m_entryList = new QListWidget(this);
    m_entryList->setMinimumWidth(200);
    m_entryList->setMaximumWidth(300);
    QFont listFont;
    listFont.setPixelSize(Theme::FONT_SIZE_MD);
    m_entryList->setFont(listFont);

    m_entryList->setStyleSheet(QString(
        "QListWidget {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: %3px solid %4;"
        "    border-radius: %5px;"
        "    padding: %6px;"
        "}"
        "QListWidget::item {"
        "    padding: %7px;"
        "    border-radius: %8px;"
        "    margin: %9px;"
        "}"
        "QListWidget::item:selected {"
        "    background-color: %10;"
        "    color: %11;"
        "}"
        "QListWidget::item:hover {"
        "    background-color: %12;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BORDER_WIDTH_THIN)
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_SM)
     .arg(Theme::SPACING_SM)
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_XS)
     .arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT_FOREGROUND.name())
     .arg(Theme::SECONDARY.name()));

    connect(m_entryList, &QListWidget::itemClicked, this, &LoreBookPage::handleEntryClicked);
    contentLayout->addWidget(m_entryList);

    // Entry details (right side)
    m_entryDetails = new QTextEdit(this);
    m_entryDetails->setReadOnly(true);
    QFont detailsFont;
    detailsFont.setPixelSize(Theme::FONT_SIZE_MD);
    m_entryDetails->setFont(detailsFont);

    m_entryDetails->setStyleSheet(QString(
        "QTextEdit {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: %3px solid %4;"
        "    border-radius: %5px;"
        "    padding: %6px;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BORDER_WIDTH_THIN)
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD));

    m_entryDetails->setHtml(QString(
        "<div style='text-align: center; color: %1; padding: 50px;'>"
        "<h2>Welcome to the Lore Codex</h2>"
        "<p>Select a category and entry to view its details.</p>"
        "<p style='color: %2; font-style: italic;'>Lore entries unlock as you explore and defeat enemies.</p>"
        "</div>"
    ).arg(Theme::FOREGROUND.name())
     .arg(Theme::MUTED_FOREGROUND.name()));

    contentLayout->addWidget(m_entryDetails, 1);

    mainLayout->addLayout(contentLayout, 1);

    // Back button
    m_backButton = new QPushButton("Back (ESC)", this);
    m_backButton->setMinimumHeight(40);
    m_backButton->setMaximumWidth(200);
    QFont btnFont;
    btnFont.setPixelSize(Theme::FONT_SIZE_MD);
    m_backButton->setFont(btnFont);

    m_backButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: %3px solid %4;"
        "    border-radius: %5px;"
        "    padding: %6px;"
        "}"
        "QPushButton:hover {"
        "    background-color: %7;"
        "    border-color: %8;"
        "}"
    ).arg(Theme::SECONDARY.name())
     .arg(Theme::SECONDARY_FOREGROUND.name())
     .arg(Theme::BORDER_WIDTH_THIN)
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_MD)
     .arg(Theme::MUTED.name())
     .arg(Theme::ACCENT.name()));

    connect(m_backButton, &QPushButton::clicked, this, &LoreBookPage::backRequested);

    QHBoxLayout *backLayout = new QHBoxLayout();
    backLayout->addStretch();
    backLayout->addWidget(m_backButton);
    mainLayout->addLayout(backLayout);

    // Apply theme to widget
    setStyleSheet(QString("QWidget { background-color: %1; }").arg(Theme::BACKGROUND.name()));
}

void LoreBookPage::updateLore(CodexManager *codexManager)
{
    m_codexManager = codexManager;
    refreshEntryList(m_currentCategory);
}

void LoreBookPage::handleCategoryChanged(int index)
{
    QStringList categories = {"Bestiary", "Items", "World", "Characters", "Locations"};
    if (index >= 0 && index < categories.size()) {
        m_currentCategory = categories[index];
        refreshEntryList(m_currentCategory);
    }
}

void LoreBookPage::refreshEntryList(const QString &category)
{
    m_entryList->clear();
    m_entryDetails->setHtml(QString(
        "<div style='text-align: center; color: %1; padding: 50px;'>"
        "<h2>%2</h2>"
        "<p>Select an entry to view its details.</p>"
        "</div>"
    ).arg(Theme::FOREGROUND.name())
     .arg(category));

    if (!m_codexManager) {
        return;
    }

    QList<LoreEntry*> unlockedEntries = m_codexManager->getUnlockedEntries(category);

    if (unlockedEntries.isEmpty()) {
        QListWidgetItem *item = new QListWidgetItem("No entries unlocked yet");
        item->setFlags(item->flags() & ~Qt::ItemIsEnabled);
        QFont italicFont;
        italicFont.setItalic(true);
        item->setFont(italicFont);
        item->setForeground(Theme::MUTED_FOREGROUND);
        m_entryList->addItem(item);
    } else {
        for (LoreEntry *entry : unlockedEntries) {
            QListWidgetItem *item = new QListWidgetItem(entry->title);
            item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(entry)));
            m_entryList->addItem(item);
        }
    }
}

void LoreBookPage::handleEntryClicked(QListWidgetItem *item)
{
    if (!item) return;

    LoreEntry *entry = static_cast<LoreEntry*>(item->data(Qt::UserRole).value<void*>());
    if (!entry) return;

    // Build HTML for entry details
    QString html = QString(
        "<div style='padding: %1px;'>"
        "<h1 style='color: %2; border-bottom: 2px solid %3; padding-bottom: %4px;'>%5</h1>"
        "<p style='font-style: italic; color: %6; margin-top: %7px;'>%8</p>"
        "<div style='margin-top: %9px; line-height: 1.6;'>"
        "%10"
        "</div>"
        "</div>"
    ).arg(Theme::SPACING_MD)
     .arg(Theme::PRIMARY.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::SPACING_SM)
     .arg(entry->title)
     .arg(Theme::MUTED_FOREGROUND.name())
     .arg(Theme::SPACING_MD)
     .arg(entry->shortDescription)
     .arg(Theme::SPACING_LG)
     .arg(entry->fullText.replace("\n", "<br/>"));

    m_entryDetails->setHtml(html);
}

void LoreBookPage::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Escape) {
        emit backRequested();
        return;
    }

    // Tab key to cycle categories
    if (event->key() == Qt::Key_Tab) {
        int nextIndex = (m_categoryTabs->currentIndex() + 1) % m_categoryTabs->count();
        m_categoryTabs->setCurrentIndex(nextIndex);
        return;
    }

    QWidget::keyPressEvent(event);
}
