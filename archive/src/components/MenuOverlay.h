#ifndef MENUOVERLAY_H
#define MENUOVERLAY_H

#include <QWidget>

class QTabWidget;
class QPushButton;
class QPropertyAnimation;
class InventoryPage;
class StatsPage;
class ShopPage;
class SaveLoadPage;
class Player;

class MenuOverlay : public QWidget
{
    Q_OBJECT
    Q_PROPERTY(qreal opacity READ opacity WRITE setOpacity)

public:
    explicit MenuOverlay(QWidget *parent = nullptr);

    void showOverlay();
    void hideOverlay();
    void updateContent(Player *player);

    qreal opacity() const { return m_opacity; }
    void setOpacity(qreal opacity);

signals:
    void overlayHidden();
    void saveRequested();
    void loadRequested();
    void saveToSlotRequested(int slotNumber);
    void loadFromSlotRequested(int slotNumber);
    void deleteSlotRequested(int slotNumber);
    void quitRequested();

private slots:
    void handleItemChanged();
    void handleSaveClicked();
    void handleLoadClicked();
    void handleQuitClicked();

protected:
    void paintEvent(QPaintEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;

private:
    void setupUi();
    void animateShow();
    void animateHide();

    QWidget *m_contentWidget;
    QTabWidget *m_tabWidget;
    QPushButton *m_closeButton;
    QPushButton *m_saveButton;
    QPushButton *m_loadButton;
    QPropertyAnimation *m_animation;

    InventoryPage *m_inventoryPage;
    StatsPage *m_statsPage;
    ShopPage *m_shopPage;
    SaveLoadPage *m_saveLoadPage;

    qreal m_opacity;
    Player *m_currentPlayer;
    QWidget *m_previousFocusWidget;
};

#endif // MENUOVERLAY_H
