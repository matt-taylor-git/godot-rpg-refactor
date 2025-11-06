#ifndef POINTOFNORETURNDIALOG_H
#define POINTOFNORETURNDIALOG_H

#include <QDialog>

class QLabel;
class QPushButton;

class PointOfNoReturnDialog : public QDialog
{
    Q_OBJECT

public:
    explicit PointOfNoReturnDialog(QWidget *parent = nullptr);

private:
    void setupUi();
};

#endif // POINTOFNORETURNDIALOG_H
