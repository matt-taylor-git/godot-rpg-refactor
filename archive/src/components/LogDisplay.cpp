#include "LogDisplay.h"
#include "../theme/Theme.h"
#include <QLabel>
#include <QVBoxLayout>
#include <QScrollArea>
#include <QSizePolicy>
#include <QScrollBar>
#include <QDebug>

// --- LogEntry Implementation ---

LogEntry::LogEntry(const QString &message, const QString &messageType)
    : message(message), messageType(messageType)
{
}

QColor LogEntry::getBorderColor() const
{
    if (messageType == "info") return Theme::MUTED_FOREGROUND;
    if (messageType == "success") return QColor("#28a745");
    if (messageType == "warning") return QColor("#ffc107");
    if (messageType == "error") return Theme::DESTRUCTIVE;
    if (messageType == "combat") return Theme::PRIMARY;
    return Theme::MUTED_FOREGROUND;
}

// --- LogDisplay Implementation ---

LogDisplay::~LogDisplay()
{
    qDeleteAll(m_logEntries);
    m_logEntries.clear();
}

LogDisplay::LogDisplay(int maxEntries, QWidget *parent)
    : QWidget(parent),
      m_maxEntries(maxEntries)
{
    initUi();
}

void LogDisplay::initUi()
{
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(0);

    // Scroll area for log entries
    m_scrollArea = new QScrollArea();
    m_scrollArea->setWidgetResizable(true);
    m_scrollArea->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    m_scrollArea->setMinimumHeight(150);
    m_scrollArea->setMaximumHeight(400);
    m_scrollArea->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

    // Container for log entries
    m_entriesContainer = new QWidget();
    m_entriesLayout = new QVBoxLayout(m_entriesContainer);
    m_entriesLayout->setContentsMargins(Theme::SPACING_SM, Theme::SPACING_SM, Theme::SPACING_SM, Theme::SPACING_SM);
    m_entriesLayout->setSpacing(Theme::SPACING_SM);
    m_entriesLayout->setAlignment(Qt::AlignTop);
    m_entriesLayout->addStretch(); // Push entries to top

    m_scrollArea->setWidget(m_entriesContainer);
    layout->addWidget(m_scrollArea);

    // Apply theme-consistent styling
    m_scrollArea->setStyleSheet(QString(R"(
        QScrollArea {
            border: %1px solid %2;
            border-radius: %3px;
            background-color: %4;
        }
        QScrollBar:vertical {
            width: %5px;
            background: %4;
        }
        QScrollBar::handle:vertical {
            background: %2;
            border-radius: 5px;
        }
        QScrollBar::handle:vertical:hover {
            background: %6;
        }
    )").arg(Theme::BORDER_WIDTH_MEDIUM)
      .arg(Theme::BORDER.name())
      .arg(Theme::BORDER_RADIUS_MD)
      .arg(Theme::CARD.name())
      .arg(Theme::SCROLLBAR_WIDTH)
      .arg(Theme::MUTED_FOREGROUND.name()));
}

void LogDisplay::addEntry(const QString &message, const QString &messageType)
{
    // Create entry and add to collection
    LogEntry *entry = new LogEntry(message, messageType);
    m_logEntries.append(entry);

    // Maintain max entries limit
    if (m_logEntries.size() > m_maxEntries) {
        // Remove oldest entry
        LogEntry *oldEntry = m_logEntries.takeFirst();
        if (oldEntry->_widget) {
            oldEntry->_widget->setParent(nullptr);
            oldEntry->_widget->deleteLater();
        }
        delete oldEntry;
    }

    // Create and add visual widget for this entry
    addEntryWidget(entry);

    // Scroll to bottom to show newest entries
    scrollToBottom();
}

void LogDisplay::addEntryWidget(LogEntry *entry)
{
    // Create label for this entry
    QLabel *entryLabel = new QLabel();
    entryLabel->setTextFormat(Qt::RichText);
    entryLabel->setWordWrap(true);
    entryLabel->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    // Format the entry with CSS styling
    QString borderColor = entry->getBorderColor().name();
    QString formattedText = QString(R"(
        <div style='
            border-left: 3px solid %1;
            padding-left: 8px;
            margin: 4px 0;
            color: %2;
            font-size: %3px;
            line-height: 1.5;
            background-color: transparent;
        '>
            %4
        </div>
    )").arg(borderColor)
      .arg(Theme::FOREGROUND.name())
      .arg(Theme::FONT_SIZE_MD)
      .arg(entry->message);

    entryLabel->setText(formattedText);

    // Store reference to widget for cleanup
    entry->_widget = entryLabel;

    // Add to layout (insert before the stretch, which is the last item)
    m_entriesLayout->insertWidget(m_entriesLayout->count() - 1, entryLabel);
}

void LogDisplay::scrollToBottom()
{
    QScrollBar *scrollbar = m_scrollArea->verticalScrollBar();
    scrollbar->setValue(scrollbar->maximum());
}

void LogDisplay::clearEntries()
{
    // Remove all entry widgets and delete LogEntry objects
    // Iterate backwards to safely remove items from the layout
    for (int i = m_entriesLayout->count() - 1; i >= 0; --i) {
        QLayoutItem *item = m_entriesLayout->itemAt(i);
        if (item->widget()) {
            item->widget()->setParent(nullptr);
            item->widget()->deleteLater();
        }
        // Do not delete the stretch item
        if (!item->spacerItem()) {
            m_entriesLayout->removeItem(item);
        }
    }

    qDeleteAll(m_logEntries);
    m_logEntries.clear();

    // Ensure the stretch item is the last item
    if (m_entriesLayout->count() == 0) {
        m_entriesLayout->addStretch();
    }
}

int LogDisplay::getEntryCount() const
{
    return m_logEntries.size();
}
