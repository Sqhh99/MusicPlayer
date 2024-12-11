#include "filestatistics.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    FileStatistics w;
    w.show();
    return a.exec();
}
