#ifndef FILESTATISTICS_H
#define FILESTATISTICS_H

#include <QWidget>
#include <QStandardItemModel>
#include <QFile>
#include <QDir>
#include "linestats.h"

QT_BEGIN_NAMESPACE
namespace Ui {
class FileStatistics;
}
QT_END_NAMESPACE

class FileStatistics : public QWidget
{
    Q_OBJECT

public:
    FileStatistics(QWidget *parent = nullptr);
    ~FileStatistics();

private slots:
    void on_OpenFileBtn_clicked();
    void on_OpenConBtn_clicked();
    void on_ClearBtn_clicked();

private:
    Ui::FileStatistics *ui;
    QStandardItemModel* tableModel = Q_NULLPTR;
    void setTextBorder();
    void setTableColumnWidth();
    void setTable();
    void setTextColor();

private:
    QList<QStringList> data;

    QStringList filters = {"*.cpp", "*.cc", "*.c", "*.h"}; // 文件扩展名过滤器
    QStringList tableTitle; // 表头
    QString configFilePath;

    void countPathAllCodeFile(const QString &directoryPath);

    LineStats countLines(const QString &filePath);

    void setAllTest(QString FilePath,
                    QString ConPath,
                    QString FileNum,
                    qint64 &fileSize,
                    LineStats test);

    void addData(QString fileName,
                 qint64 &fileSize,
                 QString &fileType,
                 LineStats &test,
                 QString &filePath);

    void DataTotable();

    void countDirectoryFiles(QDir &dir,
                             const QStringList &filters,
                             LineStats &totalStats,
                             int &couf,
                             qint64 &fileSize);

    bool isValidFilterFormat(const QString& filterString);
};
#endif // FILESTATISTICS_H
