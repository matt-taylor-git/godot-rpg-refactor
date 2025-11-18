#ifndef CUSTOMIZATIONSECTION_H
#define CUSTOMIZATIONSECTION_H

#include <QGroupBox>

class QVBoxLayout;

class CustomizationSection : public QGroupBox
{
    Q_OBJECT
public:
    explicit CustomizationSection(const QString &title, QWidget *parent = nullptr);
    void addOption(const QString &labelText, const QString &optionKey, const QList<QPair<QString, QString>> &options);

private:
    QVBoxLayout *m_sectionLayout;
};

#endif // CUSTOMIZATIONSECTION_H
