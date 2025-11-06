#include "ValidationLabel.h"
#include "../theme/Theme.h"
#include <QColor>
#include <QDebug>

ValidationLabel::ValidationLabel(QWidget *parent)
    : QLabel(parent)
{
    setAlignment(Qt::AlignLeft | Qt::AlignVCenter);
    setWordWrap(true);
    clearValidation();
}

void ValidationLabel::applyStyle(const QString &color, const QString &bgColor, const QString &messagePrefix)
{
    QString styleSheet = QString(R"(
        color: %1;
        font-size: %2px;
        background-color: %3;
        padding: %4px;
        border-radius: %5px;
        border: 1px solid %1;
    )").arg(color)
      .arg(Theme::FONT_SIZE_SM)
      .arg(bgColor)
      .arg(Theme::SPACING_XS)
      .arg(Theme::BORDER_RADIUS_SM);

    setStyleSheet(styleSheet);
    setText(messagePrefix + text());
    show();
}

void ValidationLabel::showError(const QString &message)
{
    setText(message);
    // Theme::DESTRUCTIVE is QColor, need to convert to string for stylesheet
    QString color = Theme::DESTRUCTIVE.name();
    // Background color is rgba(210, 58, 26, 0.1)
    QColor bgColor = Theme::DESTRUCTIVE;
    bgColor.setAlphaF(0.1);
    applyStyle(color, bgColor.name(QColor::HexRgb), "❌ ");
}

void ValidationLabel::showSuccess(const QString &message)
{
    setText(message);
    // Success color is #28a745
    QString color = "#28a745";
    // Background color is rgba(40, 167, 69, 0.1)
    QColor bgColor(40, 167, 69);
    bgColor.setAlphaF(0.1);
    applyStyle(color, bgColor.name(QColor::HexRgb), "✓ ");
}

void ValidationLabel::showWarning(const QString &message)
{
    setText(message);
    // Warning color is #ffc107
    QString color = "#ffc107";
    // Background color is rgba(255, 193, 7, 0.1)
    QColor bgColor(255, 193, 7);
    bgColor.setAlphaF(0.1);
    applyStyle(color, bgColor.name(QColor::HexRgb), "⚠️ ");
}

void ValidationLabel::clearValidation()
{
    setText("");
    setStyleSheet(""); // Clear any previous styling
    hide();
}