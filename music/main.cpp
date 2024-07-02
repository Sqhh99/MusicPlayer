#include "widget.h"
#include <QSystemTrayIcon>
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    Widget w;

    w.setWindowTitle("MusicPlayer");
    w.show();
    return a.exec();
}
