#include "ItemSelectionOverlay.h"
#include "ItemCard.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QScrollArea>
#include <QGridLayout>
#include <QShowEvent>

// Helper function to get color name from QColor for stylesheet
extern QString colorName(const QColor &color);

ItemSelectionOverlay::ItemSelectionOverlay(const QList<Item*> &items, const QString &title, const QString &actionText, bool showPrice, QWidget *parent)
    : QDialog(parent),
      m_items(items),
      m_titleText(title),
      m_actionText(actionText),
      m_showPrice(showPrice),
      m_gridLayout(nullptr)
{
    setWindowTitle(title);
    setModal(true);
    resize(600, 400);
    initUi();
}

void ItemSelectionOverlay::initUi()
{
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    layout->setSpacing(Theme::SPACING_MD);

    // Title
    QLabel *titleLabel = new QLabel(m_titleText);
    titleLabel->setStyleSheet(QString("font-size: %1px; font-weight: bold; color: %2;").arg(Theme::FONT_SIZE_XL).arg(colorName(Theme::FOREGROUND)));
    titleLabel->setAlignment(Qt::AlignCenter);
    layout->addWidget(titleLabel);

    // Scrollable grid of item cards
    QScrollArea *scrollArea = new QScrollArea();
    scrollArea->setWidgetResizable(true);
    scrollArea->setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);

    QWidget *scrollContent = new QWidget();
    m_gridLayout = new QGridLayout(scrollContent);
    m_gridLayout->setSpacing(Theme::SPACING_SM);

    scrollArea->setWidget(scrollContent);
    layout->addWidget(scrollArea);

    // Cancel button
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    buttonLayout->addStretch();

    QPushButton *cancelBtn = new QPushButton("Cancel");
    cancelBtn->setStyleSheet(QString(R"(
        QPushButton {
            background-color: %1;
            color: %2;
            border: 1px solid %3;
            border-radius: %4px;
            padding: 8px 16px;
            font-size: %5px;
        }
        QPushButton:hover {
            background-color: %6;
            color: %7;
        }
    )").arg(colorName(Theme::SECONDARY))
      .arg(colorName(Theme::MUTED_FOREGROUND))
      .arg(colorName(Theme::BORDER))
      .arg(Theme::BORDER_RADIUS_MD)
      .arg(Theme::FONT_SIZE_MD)
      .arg(colorName(Theme::MUTED))
      .arg(colorName(Theme::FOREGROUND)));

    connect(cancelBtn, &QPushButton::clicked, this, &ItemSelectionOverlay::reject);
    buttonLayout->addWidget(cancelBtn);

    layout->addLayout(buttonLayout);
}

void ItemSelectionOverlay::refreshGrid()
{
    clearGrid();

    if (m_items.isEmpty()) {
        QLabel *emptyLabel = new QLabel("No items available");
        emptyLabel->setAlignment(Qt::AlignCenter);
        emptyLabel->setStyleSheet(QString("color: %1; font-size: %2px;").arg(colorName(Theme::MUTED_FOREGROUND)).arg(Theme::FONT_SIZE_LG));
        m_gridLayout->addWidget(emptyLabel, 0, 0, 1, 4);
        return;
    }

    // Add items to grid (4 columns)
    int row = 0;
    int col = 0;
    const int maxCols = 4;

    for (Item *item : m_items) {
        ItemCard *card = new ItemCard(item, m_actionText, m_showPrice);
        card->setMaximumSize(180, 220);
        connect(card, &ItemCard::actionClicked, this, &ItemSelectionOverlay::onItemSelected);
        m_gridLayout->addWidget(card, row, col);

        col++;
        if (col >= maxCols) {
            col = 0;
            row++;
        }
    }

    // Add stretch to push items to top
    m_gridLayout->setRowStretch(row + 1, 1);
    m_gridLayout->setColumnStretch(maxCols, 1);
}

void ItemSelectionOverlay::clearGrid()
{
    // Clear all widgets from the grid layout
    QLayoutItem *item;
    while ((item = m_gridLayout->takeAt(0)) != nullptr) {
        if (item->widget()) {
            item->widget()->deleteLater();
        }
        delete item;
    }
}

void ItemSelectionOverlay::onItemSelected(Item *item, const QString &action)
{
    Q_UNUSED(action);
    emit itemSelected(item);
    accept();
}

void ItemSelectionOverlay::showEvent(QShowEvent *event)
{
    // Refresh the grid when dialog is shown
    refreshGrid();
    QDialog::showEvent(event);
}
