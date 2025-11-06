#ifndef STATUSINDICATOR_H
#define STATUSINDICATOR_H

#include <QFrame>
#include <QTimer>
#include <QMap>
#include <QColor>

class StatusIndicator : public QFrame
{
    Q_OBJECT

public:
    explicit StatusIndicator(const QString &effectType, const QString &effectName, int duration = 0, QWidget *parent = nullptr);

signals:
    void effectExpired(const QString &effectName);

public slots:
    void updateDuration();

private:
    void initUi();
    void updateDisplay();
    void expireEffect();
    QMap<QString, QColor> getEffectColors() const;
    QString getEffectIcon() const;

    QString m_effectType;
    QString m_effectName;
    int m_remainingTime;
    QTimer *m_timer;
};

#endif // STATUSINDICATOR_H