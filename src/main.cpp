#include <QApplication>
#include <QFile>
#include <QTextStream>
#include "MainWindow.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // Set application details
    app.setApplicationName("Pyrpg-Qt");
    app.setOrganizationName("Gemini");
    app.setApplicationVersion("1.0");

    // Load and apply the stylesheet from the Qt Resource System
    QFile file(":/assets/styles.qss");
    if (file.open(QFile::ReadOnly | QFile::Text)) {
        QTextStream stream(&file);
        QString styleSheet = stream.readAll();
        app.setStyleSheet(styleSheet);
        file.close();
    }

    MainWindow window;
    window.show();

    return app.exec();
}
