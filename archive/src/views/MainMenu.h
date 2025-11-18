#ifndef MAINMENU_H
#define MAINMENU_H

#include <QWidget>

class QPushButton;

class MainMenu : public QWidget
{
    Q_OBJECT
public:
    explicit MainMenu(QWidget *parent = nullptr);

signals:
    void newGameRequested();
    void loadGameRequested();
    void exitRequested();

private:
    void setupUi();

    QPushButton *m_newGameButton;
    QPushButton *m_loadGameButton;
    QPushButton *m_exitButton;
};

#endif // MAINMENU_H
