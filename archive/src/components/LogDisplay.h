#ifndef LOGDISPLAY_H
#define LOGDISPLAY_H

#include <QWidget>
#include <QList>
#include <QColor>

class QLabel;
class QVBoxLayout;
class QScrollArea;

// Helper class for a single log entry
class LogEntry
{
public:
    LogEntry(const QString &message, const QString &messageType = "info");
    ~LogEntry() { /* _widget is deleted by LogDisplay */ }

    QString message;
    QString messageType; // "info", "success", "warning", "error", "combat"
    QColor getBorderColor() const;

    // Used to hold the visual widget reference for cleanup
    QLabel *_widget = nullptr;
};

class LogDisplay : public QWidget
{
    Q_OBJECT

public:
    explicit LogDisplay(int maxEntries = 20, QWidget *parent = nullptr);
    ~LogDisplay();

    void addEntry(const QString &message, const QString &messageType = "info");
    void clearEntries();
    int getEntryCount() const;

private:
    void initUi();
    void addEntryWidget(LogEntry *entry);
    void scrollToBottom();

    QList<LogEntry*> m_logEntries;
    int m_maxEntries;

    QScrollArea *m_scrollArea;
    QWidget *m_entriesContainer;
    QVBoxLayout *m_entriesLayout;
};

#endif // LOGDISPLAY_H
