#include "StatusIndicator.h"
#include <QLabel>
#include <QVBoxLayout>
#include <QDebug>

StatusIndicator::StatusIndicator(const QString &effectType, const QString &effectName, int duration, QWidget *parent)
    : QFrame(parent),
      m_effectType(effectType),
      m_effectName(effectName),
      m_remainingTime(duration),
      m_timer(nullptr)
{
    initUi();

    // Set up timer for duration countdown if applicable
    if (duration > 0) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout, this, &StatusIndicator::updateDuration);
        m_timer->start(1000); // Update every second
    }
}

QMap<QString, QColor> StatusIndicator::getEffectColors() const
{
    QMap<QString, QColor> colorMap;
    colorMap["buff_bg"] = QColor("#d4edda");
    colorMap["buff_border"] = QColor("#27ae60");
    colorMap["debuff_bg"] = QColor("#f8d7da");
    colorMap["debuff_border"] = QColor("#e74c3c");
    colorMap["heal_bg"] = QColor("#d1ecf1");
    colorMap["heal_border"] = QColor("#3498db");
    colorMap["damage_bg"] = QColor("#fff3cd");
    colorMap["damage_border"] = QColor("#f39c12");
    colorMap["default_bg"] = QColor("#f8f9fa");
    colorMap["default_border"] = QColor("#6c757d");

    QString type = m_effectType;
    if (type == "strength" || type == "defense" || type == "speed" || type == "regeneration") type = "buff";
    if (type == "poison" || type == "burn" || type == "freeze" || type == "stun") type = "debuff";

    if (colorMap.contains(type + "_bg")) {
        return {{"bg", colorMap.value(type + "_bg")}, {"border", colorMap.value(type + "_border")}};
    }
    return {{"bg", colorMap.value("default_bg")}, {"border", colorMap.value("default_border")}};
}

QString StatusIndicator::getEffectIcon() const
{
    QMap<QString, QString> iconMap;
    iconMap["buff"] = "💪";
    iconMap["debuff"] = "☠️";
    iconMap["heal"] = "❤️";
    iconMap["damage"] = "💥";
    iconMap["poison"] = "☠️";
    iconMap["strength"] = "💪";
    iconMap["defense"] = "🛡️";
    iconMap["speed"] = "⚡";
    iconMap["regeneration"] = "💚";
    iconMap["burn"] = "🔥";
    iconMap["freeze"] = "🧊";
    iconMap["stun"] = "💫";
    iconMap["default"] = "✨";

    return iconMap.value(m_effectType, iconMap["default"]);
}

void StatusIndicator::initUi()
{
    setFixedSize(60, 60);
    setFrameShape(QFrame::Box);

    // Get colors based on effect type
    QMap<QString, QColor> colors = getEffectColors();

    setStyleSheet(QString(R"(
        StatusIndicator {
            background-color: %1;
            border: 2px solid %2;
            border-radius: 8px;
        }
    )").arg(colors["bg"].name())
      .arg(colors["border"].name()));

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(2);

    // Icon/emoji
    QLabel *iconLabel = new QLabel(getEffectIcon());
    iconLabel->setAlignment(Qt::AlignCenter);
    iconLabel->setStyleSheet("font-size: 16px;");
    layout->addWidget(iconLabel);

    // Duration/Name Label (for display updates)
    QLabel *nameLabel = new QLabel(m_effectName);
    nameLabel->setAlignment(Qt::AlignCenter);
    nameLabel->setStyleSheet("font-size: 10px; font-weight: bold;");
    layout->addWidget(nameLabel);

    updateDisplay();
}

void StatusIndicator::updateDuration()
{
    if (m_remainingTime > 0) {
        m_remainingTime -= 1;
        if (m_remainingTime <= 0) {
            expireEffect();
        } else {
            updateDisplay();
        }
    }
}

void StatusIndicator::updateDisplay()
{
    // Find the name label (second widget in the layout)
    if (layout() && layout()->count() > 1) {
        QLabel *nameLabel = qobject_cast<QLabel*>(layout()->itemAt(1)->widget());
        if (nameLabel) {
            if (m_remainingTime > 0) {
                nameLabel->setText(QString::number(m_remainingTime) + "T"); // T for Turns
            } else {
                nameLabel->setText(m_effectName);
            }
        }
    }
}

void StatusIndicator::expireEffect()
{
    if (m_timer) {
        m_timer->stop();
        delete m_timer;
        m_timer = nullptr;
    }
    hide();
    emit effectExpired(m_effectName);
    // Note: We use deleteLater() in the Python version, which is good practice for self-destructing widgets.
    deleteLater();
}
