#ifndef CHARACTERCUSTOMIZATIONPAGE_H
#define CHARACTERCUSTOMIZATIONPAGE_H

#include <QWidget>

class CharacterPreviewWidget;
class CustomizationSection;
class QLineEdit;
class ValidationLabel;
class QPushButton;

class CharacterCustomizationPage : public QWidget
{
    Q_OBJECT
public:
    explicit CharacterCustomizationPage(QWidget *parent = nullptr);

private:
    void setupUi();

    CharacterPreviewWidget *m_previewWidget;
    QLineEdit *m_nameInput;
    ValidationLabel *m_nameValidation;
    CustomizationSection *m_appearanceSection;
    CustomizationSection *m_cosmeticSection;
    QPushButton *m_saveButton;
    QPushButton *m_loadButton;
    QPushButton *m_resetButton;
};

#endif // CHARACTERCUSTOMIZATIONPAGE_H