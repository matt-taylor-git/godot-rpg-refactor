#include "ItemCard.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QColor>
#include <QDebug>
#include <QFile>
#include <QMimeData>
#include <QDrag>
#include <QGridLayout>

// Helper function to get color name from QColor for stylesheet
QString colorName(const QColor &color) {
    return color.name(QColor::HexRgb);
}

ItemCard::ItemCard(Item *item, const QString &actionText, bool showPrice, QWidget *parent)
    : QFrame(parent),
      m_item(item),
      m_actionText(actionText),
      m_showPrice(showPrice),
      m_actionBtn(nullptr)
{
    setupUi();
    setupDragDrop();
}

void ItemCard::setupUi()
{
    setFrameShape(QFrame::Box);
    setMinimumSize(180, 200);
    setMaximumSize(200, 220);

    // Styling based on rarity using Theme constants
    QMap<QString, QColor> rarityStyles;
    rarityStyles["common_color"] = Theme::MUTED_FOREGROUND;
    rarityStyles["common_border"] = Theme::BORDER;
    rarityStyles["uncommon_color"] = Theme::ACCENT;
    rarityStyles["uncommon_border"] = Theme::ACCENT;
    rarityStyles["rare_color"] = Theme::PRIMARY;
    rarityStyles["rare_border"] = Theme::PRIMARY;
    rarityStyles["epic_color"] = Theme::SECONDARY;
    rarityStyles["epic_border"] = Theme::SECONDARY;
    rarityStyles["legendary_color"] = Theme::MUTED; // Using MUTED for gold-like color
    rarityStyles["legendary_border"] = Theme::MUTED;

    QString rarity = m_item->rarity.toLower();
    QColor borderColor = rarityStyles.value(rarity + "_border", rarityStyles["common_border"]);
    QColor textColor = rarityStyles.value(rarity + "_color", rarityStyles["common_color"]);

    setStyleSheet(QString(R"(
        ItemCard {
            background-color: %1;
            border: %2px solid %3;
            border-radius: %4px;
            padding: %5px;
        }
        ItemCard:hover {
            background-color: %6;
            border-color: %7;
        }
    )").arg(colorName(Theme::CARD))
      .arg(Theme::BORDER_WIDTH_MEDIUM)
      .arg(colorName(borderColor))
      .arg(Theme::BORDER_RADIUS_MD)
      .arg(Theme::SPACING_SM)
      .arg(colorName(Theme::MUTED))
      .arg(colorName(textColor)));

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setSpacing(Theme::SPACING_XS);
    layout->setContentsMargins(Theme::SPACING_SM, Theme::SPACING_SM, Theme::SPACING_SM, Theme::SPACING_SM);

    // Item icon/emoji
    QLabel *iconLabel = getItemIconLabel();
    layout->addWidget(iconLabel);

    // Item name
    QLabel *nameLabel = new QLabel(m_item->name);
    nameLabel->setStyleSheet(QString(R"(
        font-size: %1px;
        font-weight: %2;
        color: %3;
        background: transparent;
        border: none;
    )").arg(Theme::FONT_SIZE_MD - 1) // 13px
      .arg(Theme::FONT_WEIGHT_BOLD)
      .arg(colorName(textColor)));
    nameLabel->setAlignment(Qt::AlignCenter);
    nameLabel->setWordWrap(true);
    layout->addWidget(nameLabel);

    // Item stats/description
    QLabel *statsLabel = new QLabel(getStatsText());
    statsLabel->setStyleSheet(QString(R"(
        font-size: %1px;
        color: %2;
        background: transparent;
        border: none;
    )").arg(Theme::FONT_SIZE_XS + 1) // 11px
      .arg(colorName(Theme::MUTED_FOREGROUND)));
    statsLabel->setAlignment(Qt::AlignCenter);
    statsLabel->setWordWrap(true);
    layout->addWidget(statsLabel);

    // Rarity badge
    QLabel *rarityLabel = new QLabel(m_item->rarity.toUpper());
    rarityLabel->setStyleSheet(QString(R"(
        font-size: %1px;
        color: %2;
        background-color: rgba(0, 0, 0, 0.4);
        padding: %3px %4px;
        border-radius: %5px;
        border: none;
        font-weight: %6;
    )").arg(Theme::FONT_SIZE_XS) // 10px
      .arg(colorName(textColor))
      .arg(Theme::SPACING_XS)
      .arg(Theme::SPACING_SM)
      .arg(Theme::BORDER_RADIUS_SM)
      .arg(Theme::FONT_WEIGHT_MEDIUM));
    rarityLabel->setAlignment(Qt::AlignCenter);
    layout->addWidget(rarityLabel);

    layout->addStretch();

    // Price/Value
    if (m_showPrice) {
        QLabel *priceLabel = new QLabel(QString("💰 %1 gold").arg(m_item->value));
        priceLabel->setStyleSheet(QString(R"(
            font-size: %1px;
            font-weight: %2;
            color: %3;
            background: transparent;
            border: none;
        )").arg(Theme::FONT_SIZE_SM)
          .arg(Theme::FONT_WEIGHT_SEMIBOLD)
          .arg(colorName(Theme::ACCENT)));
        priceLabel->setAlignment(Qt::AlignCenter);
        layout->addWidget(priceLabel);
    }

    // Action button
    m_actionBtn = new QPushButton(m_actionText);
    m_actionBtn->setStyleSheet(QString(R"(
        QPushButton {
            background-color: %1;
            color: %2;
            border: 1px solid %2;
            border-radius: %3px;
            padding: %4px %5px;
            font-size: %6px;
            font-weight: %7;
        }
        QPushButton:hover {
            background-color: %8;
            color: %9;
        }
        QPushButton:pressed {
            background-color: %10;
        }
        QPushButton:disabled {
            background-color: %10;
            color: %11;
            border-color: %12;
        }
    )").arg(colorName(Theme::CARD))
      .arg(colorName(Theme::PRIMARY))
      .arg(Theme::BORDER_RADIUS_SM)
      .arg(Theme::SPACING_XS)
      .arg(Theme::SPACING_SM)
      .arg(Theme::FONT_SIZE_XS + 1) // 11px
      .arg(Theme::FONT_WEIGHT_MEDIUM)
      .arg(colorName(Theme::SECONDARY))
      .arg(colorName(Theme::SECONDARY_FOREGROUND))
      .arg(colorName(Theme::MUTED))
      .arg(colorName(Theme::MUTED_FOREGROUND))
      .arg(colorName(Theme::BORDER)));

    connect(m_actionBtn, &QPushButton::clicked, this, [this]() {
        emit actionClicked(m_item, m_actionText.toLower());
    });
    layout->addWidget(m_actionBtn);

    // Set up full tooltip
    setToolTip(getTooltipText());

    // Make the entire card clickable and focusable
    setCursor(Qt::PointingHandCursor);
    setFocusPolicy(Qt::StrongFocus);
}

void ItemCard::setupDragDrop()
{
    setAcceptDrops(true);
}

QLabel *ItemCard::getItemIconLabel() const
{
    QLabel *label = new QLabel();
    label->setAlignment(Qt::AlignCenter);
    label->setFixedSize(48, 48); // Fixed size for icon area

    QString iconText;
    QPixmap pixmap;

    if (m_item->itemType == "weapon") {
        pixmap = getWeaponPixmap(m_item->name);
        if (!pixmap.isNull()) {
            pixmap = pixmap.scaled(32, 32, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            label->setPixmap(pixmap);
            return label;
        }
        iconText = "⚔️";
    } else if (m_item->itemType == "armor") {
        iconText = "🛡️";
    } else if (m_item->itemType == "accessory") {
        iconText = "💍";
    } else if (m_item->itemType == "consumable") {
        iconText = "🧪";
    } else {
        iconText = "📦";
    }

    label->setText(iconText);
    label->setStyleSheet("font-size: 32px; background: transparent; border: none;");
    return label;
}

QPixmap ItemCard::getWeaponPixmap(const QString &weaponName) const
{
    // Map weapon names to icon files (using Qt Resource paths, assuming task 5.3 is done later)
    QMap<QString, QString> weaponIcons = {
        {"Iron Sword", ":/assets/iron_sword.png"},
        {"Steel Sword", ":/assets/steel_sword.png"},
        {"Magic Sword", ":/assets/magic_sword.png"}
    };

    QString path = weaponIcons.value(weaponName);
    if (!path.isEmpty()) {
        QPixmap pixmap(path);
        if (pixmap.isNull()) {
            // Fallback for development before resource file is set up
            // The path to the assets directory from the executable is complex.
            // For now, we will rely on the resource system path (:/assets/...) 
            // and assume the user will complete task 5.3 (Asset Management) soon.
            // If the pixmap is null, it will fall back to the emoji icon.
        }
        return pixmap;
    }
    return QPixmap(); // Return null pixmap
}

QString ItemCard::getStatsText() const
{
    QStringList stats;
    if (m_item->attackBonus > 0) {
        stats.append(QString("+%1 ATK").arg(m_item->attackBonus));
    }
    if (m_item->defenseBonus > 0) {
        stats.append(QString("+%1 DEF").arg(m_item->defenseBonus));
    }
    if (m_item->effect == "heal") {
        stats.append(QString("Heals %1 HP").arg(m_item->power));
    } else if (m_item->effect == "restore_mana") {
        stats.append(QString("Restores %1 MP").arg(m_item->power));
    }

    if (!stats.isEmpty()) {
        return stats.join(" | ");
    } else if (!m_item->description.isEmpty()) {
        return m_item->description.left(30) + (m_item->description.length() > 30 ? "..." : "");
    }
    return "No special stats";
}

QString ItemCard::getEffectDescription() const
{
    if (m_item->effect.isEmpty()) {
        return "";
    }

    if (m_item->effect == "heal") {
        return QString("Heals %1 HP when used").arg(m_item->power);
    } else if (m_item->effect == "restore_mana") {
        return QString("Restores %1 MP when used").arg(m_item->power);
    } else {
        return QString("Special effect: %1").arg(m_item->effect.toUpper());
    }
}

QString ItemCard::getTooltipText() const
{
    if (!m_item) return "";

    QStringList tooltipLines;
    tooltipLines.append(QString("<b>%1</b>").arg(m_item->name));
    tooltipLines.append("");

    // Type and rarity
    tooltipLines.append(QString("<i>%1 - %2</i>").arg(m_item->itemType.toUpper()).arg(m_item->rarity.toUpper()));
    tooltipLines.append("");

    // Stats section
    QStringList stats;
    if (m_item->attackBonus > 0) {
        stats.append(QString("⚔️ +%1 Attack").arg(m_item->attackBonus));
    }
    if (m_item->defenseBonus > 0) {
        stats.append(QString("🛡️ +%1 Defense").arg(m_item->defenseBonus));
    }

    if (!stats.isEmpty()) {
        tooltipLines.append("• Stats:");
        tooltipLines.append(stats.join("\n  "));
        tooltipLines.append("");
    }

    // Effect section
    QString effectDesc = getEffectDescription();
    if (!effectDesc.isEmpty()) {
        tooltipLines.append("• Effect:");
        tooltipLines.append(QString("  %1").arg(effectDesc));
        tooltipLines.append("");
    }

    // Description section
    if (!m_item->description.isEmpty()) {
        tooltipLines.append("• Description:");
        tooltipLines.append(QString("  %1").arg(m_item->description));
    }

    // Value section
    if (m_item->value > 0) {
        tooltipLines.append("");
        tooltipLines.append(QString("<i>💰 Sell for: %1 gold</i>").arg(m_item->value / 2));
    }

    return tooltipLines.join("\n");
}

void ItemCard::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton) {
        emit clicked(m_item);

        // Start drag operation (for inventory management)
        QDrag *drag = new QDrag(this);
        QMimeData *mimeData = new QMimeData;
        // Store item ID or a unique identifier in the mime data
        mimeData->setText(QString("item:%1").arg(m_item->name));
        drag->setMimeData(mimeData);

        // Use a small pixmap for the drag image
        QPixmap pixmap(this->size());
        this->render(&pixmap);
        drag->setPixmap(pixmap.scaled(100, 100, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        drag->setHotSpot(event->pos());

        // The drag operation will block until finished
        drag->exec(Qt::MoveAction | Qt::CopyAction);
    }
    QFrame::mousePressEvent(event);
}

void ItemCard::dragEnterEvent(QDragEnterEvent *event)
{
    if (event->mimeData()->hasText() && event->mimeData()->text().startsWith("item:")) {
        event->acceptProposedAction();
    } else {
        event->ignore();
    }
}

void ItemCard::dropEvent(QDropEvent *event)
{
    if (event->mimeData()->hasText() && event->mimeData()->text().startsWith("item:")) {
        // This is where logic for swapping items would go.
        // For now, we just accept the drop to enable visual feedback.
        event->acceptProposedAction();
    }
}
