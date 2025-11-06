#ifndef VALIDATIONLABEL_H
#define VALIDATIONLABEL_H

#include <QLabel>

class ValidationLabel : public QLabel
{
    Q_OBJECT

public:
    explicit ValidationLabel(QWidget *parent = nullptr);

    void showError(const QString &message);
    void showSuccess(const QString &message);
    void showWarning(const QString &message);
    void clearValidation();

private:
    void applyStyle(const QString &color, const QString &bgColor, const QString &messagePrefix);
};

#endif // VALIDATIONLABEL_H