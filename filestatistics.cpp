#include "filestatistics.h"
#include "ui_filestatistics.h"
#include <QFileDialog>
#include <QTextStream>
#include <QMessageBox>
#include <QSettings>
#include <QTextEdit>

FileStatistics::FileStatistics(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::FileStatistics)
{
    ui->setupUi(this);
    this->resize(560,600);
    this->setTextBorder();
    this->setTable();
    this->setTableColumnWidth();
    this->setTextColor();

    QString appDirPath = QCoreApplication::applicationDirPath();
    configFilePath = QDir(appDirPath).filePath("setting.ini");
    QSettings settings(configFilePath, QSettings::IniFormat);
    QString filterString = settings.value("FileStatistics/filter", "*.cpp, *.cc, *.c, *.h").toString();
    ui->FText->setText(filterString);
}

void FileStatistics::setTextColor()
{
    ui->FileNumText->setTextColor(QColor(102, 205, 170));  // Medium Aquamarine
    ui->ByteNumText->setTextColor(QColor(135, 206, 250));  // Light Sky Blue
    ui->TotNumText->setTextColor(QColor(144, 238, 144));   // Light Green
    ui->CodeRowNumText->setTextColor(QColor(255, 182, 193)); // Light Pink
    ui->AnnRowNumText->setTextColor(QColor(255, 165, 79));  // Light Salmon
    ui->BlankNumText->setTextColor(QColor(221, 160, 221)); // Plum
}

bool FileStatistics::isValidFilterFormat(const QString& filterString) {
    QStringList filters = filterString.split(", ", Qt::SkipEmptyParts);
    static QRegularExpression regex(R"(\*\.[a-zA-Z0-9]+)");
    for (const QString& filter : filters) {
        if (!regex.match(filter).hasMatch()) {
            return false;
        }
    }
    return true;
}

void FileStatistics::setTableColumnWidth()
{
    ui->FileStatisticsTableView->setColumnWidth(0, 80);
    ui->FileStatisticsTableView->setColumnWidth(1, 80);
    ui->FileStatisticsTableView->setColumnWidth(2, 70);
    ui->FileStatisticsTableView->setColumnWidth(3, 70);
    ui->FileStatisticsTableView->setColumnWidth(4, 70);
    ui->FileStatisticsTableView->setColumnWidth(5, 70);
    ui->FileStatisticsTableView->setColumnWidth(6, 70);
    ui->FileStatisticsTableView->setColumnWidth(7, 235);
}

void FileStatistics::setTextBorder()
{
    ui->FileStatisticsTableView->setStyleSheet("QTableView { border: 1px solid black; }");
    ui->FileNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->ByteNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->TotNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");

    ui->CodeRowNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->AnnRowNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->BlankNumText->setStyleSheet("QTextEdit { border: 1px solid gray; }");

    ui->Pro1Text->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->Pro2Text->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->Pro3Text->setStyleSheet("QTextEdit { border: 1px solid gray; }");

    ui->FilePathText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->ConPathText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
    ui->FText->setStyleSheet("QTextEdit { border: 1px solid gray; }");
}

void FileStatistics::setTable()
{
    tableTitle << "文件名" << "类型" << "大小" << "总行数" << "代码行数" << "注释行数" << "空白行数" << "路径";
    tableModel = new QStandardItemModel();
    ui->FileStatisticsTableView->setModel(tableModel);
    tableModel->setHorizontalHeaderLabels(tableTitle);
}

FileStatistics::~FileStatistics()
{
    if (tableModel != nullptr) {
        delete tableModel;
    }
    delete ui;
}

LineStats FileStatistics::countLines(const QString &filePath)
{
    QFile file(filePath);
    LineStats stats;

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Unable to open file:" << filePath;
        return stats; // 返回默认值
    }

    QTextStream in(&file);

    // 正确的正则表达式来匹配单行注释（如 C++、Python 等）
    static const QRegularExpression singleLineComment("//");
    static const QRegularExpression multiLineCommentStart("/\\*");
    static const QRegularExpression multiLineCommentEnd("\\*/");
    bool inMultiLineComment = false;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();

        if (line.isEmpty()) {
            stats.blankLines++;
        } else if (inMultiLineComment || line.contains(multiLineCommentStart)) {
            stats.commentLines++;
            if (line.contains(multiLineCommentEnd)) {
                inMultiLineComment = false; // 结束多行注释块
            } else {
                inMultiLineComment = true; // 继续多行注释块
            }
        } else if (line.contains(singleLineComment)) {
            stats.commentLines++;
        } else {
            stats.codeLines++;
        }
    }

    file.close();
    return stats;
}

void FileStatistics::setAllTest(QString FilePath,
                                QString ConPath,
                                QString FileNum,
                                qint64 &fileSize,
                                LineStats test)
{
    ui->FileNumText->setText(FileNum);
    ui->ByteNumText->setText(QString::number(fileSize) + "B");
    ui->TotNumText->setText(QString::number(test.total()));
    ui->CodeRowNumText->setText(QString::number(test.codeLines));
    ui->AnnRowNumText->setText(QString::number(test.commentLines));
    ui->BlankNumText->setText(QString::number(test.blankLines));
    ui->FilePathText->setText(FilePath);
    ui->ConPathText->setText(ConPath);

    double total = test.total();
    double pro1 = 0, pro2 = 0, pro3 = 0;
    if (total != 0)
    {
        pro1 = test.codeLines * 100/ total;
        pro2 = test.commentLines * 100/ total;
        pro3 = test.blankLines * 100/ total;
    }

    ui->Pro1Text->setText(QString::number(pro1,'f',2) + "%");
    ui->Pro2Text->setText(QString::number(pro2,'f',2) + "%");
    ui->Pro3Text->setText(QString::number(pro3,'f',2) + "%");
}

void FileStatistics::addData(QString fileName,
                             qint64 &fileSize,
                             QString &fileType,
                             LineStats &test,
                             QString &filePath)
{
    data << (QStringList() << fileName << fileType << QString::number(fileSize) + "B"
                           << QString::number(test.total()) << QString::number(test.codeLines)
                           << QString::number(test.commentLines) << QString::number(test.blankLines)
                           << filePath);
}

void FileStatistics::DataTotable()
{
    for (const QStringList &rowData : data) {
        QList<QStandardItem*> items;
        for (const QString &value : rowData) {
            QStandardItem *item = new QStandardItem(value);
            items.append(item);
        }
        tableModel->appendRow(items);
    }
}

void FileStatistics::countPathAllCodeFile(const QString &directoryPath)
{
    QDir dir(directoryPath);
    if (!dir.exists()) {
        qWarning() << "Directory does not exist:" << directoryPath;
        return;
    }
    data.clear();
    tableModel->removeRows(0, tableModel->rowCount());
    LineStats totalStats;
    int countFiles = 0;
    qint64 fileSize = 0;
    countDirectoryFiles(dir, filters, totalStats, countFiles, fileSize);

    setAllTest(nullptr, directoryPath, QString::number(countFiles), fileSize, totalStats);
    DataTotable();
}

void FileStatistics::countDirectoryFiles(QDir &dir,
                                         const QStringList &filters,
                                         LineStats &totalStats,
                                         int &countFiles,
                                         qint64 &fileSize)
{
    QStringList files = dir.entryList(filters, QDir::Files);
    if (!files.isEmpty()) {
        countFiles += files.size();
        for (const QString &fileName : files) {
            QString filePath = dir.filePath(fileName);
            QFileInfo fileInfo(filePath);
            LineStats fileStats = countLines(filePath);
            QString fileType = fileInfo.suffix(); // 文件扩展名
            fileSize += fileInfo.size();
            qint64 filesizetemp = fileInfo.size();
            totalStats += fileStats;
            addData(fileName, filesizetemp, fileType, fileStats, filePath);
        }
    }
    QStringList subDirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &subDirName : subDirs) {
        QDir subDir(dir.filePath(subDirName));
        countDirectoryFiles(subDir, filters, totalStats, countFiles, fileSize);
    }
}

void FileStatistics::on_OpenFileBtn_clicked()
{
    QString filePath = QFileDialog::getOpenFileName(
        nullptr,
        "Open File",
        "",
        "C++ Source Files (*.cpp *.cc *.c *.h);;All Files (*);;Java Source Files (*.java)"
        );
    if (!filePath.isEmpty())
    {
        data.clear();
        tableModel->removeRows(0, tableModel->rowCount());
        QFileInfo fileInfo(filePath);
        QString fileName = fileInfo.fileName();
        qint64 fileSize = fileInfo.size(); // 文件大小，以字节为单位
        QString fileType = fileInfo.suffix(); // 文件扩展名

        ui->FilePathText->setText(filePath);
        LineStats test = countLines(filePath);
        addData(fileName, fileSize, fileType, test, filePath);
        setAllTest(filePath,nullptr,"1", fileSize, test);
        DataTotable();
    }
    else
    {
        QMessageBox::information(nullptr, "No File Selected", "No file was selected.");
    }
}

void FileStatistics::on_OpenConBtn_clicked()
{
    QSettings settings(configFilePath, QSettings::IniFormat);
    QString filterString;
    if (!ui->FText->toPlainText().isEmpty()) {
        filterString = ui->FText->toPlainText();
        if (isValidFilterFormat(filterString)) {
            settings.setValue("FileStatistics/filter", filterString);
            filters = filterString.split(", ", Qt::SkipEmptyParts);
        }
    }

    QString Directorydir = QFileDialog::getExistingDirectory(
        nullptr,
        "Select Directory",
        "",
        QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);

    if (!Directorydir.isEmpty()) {
        countPathAllCodeFile(Directorydir);
    } else {
        QMessageBox::information(nullptr, "No Directory Selected", "No directory was selected.");
    }
}

void FileStatistics::on_ClearBtn_clicked()
{
    data.clear();        
    tableModel->removeRows(0, tableModel->rowCount());
    qint64 temp = 0;
    LineStats tempStats;
    setAllTest(nullptr, nullptr, nullptr, temp, tempStats);
}

