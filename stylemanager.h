#ifndef STYLEMANAGER_H
#define STYLEMANAGER_H

#include <QObject>
#include <QString>
#include <QFile>
#include <QDir>
#include <QApplication>
#include <QDebug>
#include <QStringList>

class StyleManager : public QObject
{
    Q_OBJECT
public:
    explicit StyleManager(QObject *parent = nullptr) : QObject(parent) {}

    // 加载单个样式表文件
    static bool loadStyleSheet(const QString &stylesheetFile) {
        QFile file(stylesheetFile);
        if (!file.exists()) {
            qWarning() << "Style sheet file not found:" << stylesheetFile;
            return false;
        }
        
        if (file.open(QFile::ReadOnly)) {
            QString styleSheet = QLatin1String(file.readAll());
            qApp->setStyleSheet(styleSheet);
            file.close();
            qInfo() << "Style sheet loaded successfully:" << stylesheetFile;
            return true;
        } else {
            qWarning() << "Failed to open style sheet file:" << stylesheetFile;
            return false;
        }
    }
    
    // 加载多个样式表文件
    static bool loadStyleSheets(const QStringList &stylesheetFiles) {
        QString combinedStyleSheet;
        
        for (const QString &file : stylesheetFiles) {
            QFile styleFile(file);
            if (!styleFile.exists()) {
                qWarning() << "Style sheet file not found:" << file;
                continue;
            }
            
            if (styleFile.open(QFile::ReadOnly)) {
                QString fileContent = QLatin1String(styleFile.readAll());
                combinedStyleSheet.append(fileContent);
                combinedStyleSheet.append("\n\n");
                styleFile.close();
                qInfo() << "Style sheet component loaded:" << file;
            } else {
                qWarning() << "Failed to open style sheet file:" << file;
            }
        }
        
        if (combinedStyleSheet.isEmpty()) {
            qWarning() << "No valid style sheets were loaded.";
            return false;
        }
        
        qApp->setStyleSheet(combinedStyleSheet);
        qInfo() << "Combined style sheets applied successfully.";
        return true;
    }
    
    // 加载目录中的所有样式表文件
    static bool loadStyleSheetsFromDirectory(const QString &directory, const QString &filter = "*.qss") {
        QDir dir(directory);
        if (!dir.exists()) {
            qWarning() << "Style sheet directory not found:" << directory;
            return false;
        }
        
        QStringList files = dir.entryList(QStringList() << filter, QDir::Files, QDir::Name);
        QStringList fullPaths;
        
        qDebug() << "Loading style sheets from directory:" << directory;
        qDebug() << "Found files:" << files;
        
        for (const QString &file : files) {
            fullPaths << dir.filePath(file);
        }
        
        if (fullPaths.isEmpty()) {
            qWarning() << "No style sheets found in directory:" << directory;
            return false;
        }
        
        QString combinedStyleSheet;
        
        for (const QString &file : fullPaths) {
            QFile styleFile(file);
            if (!styleFile.exists()) {
                qWarning() << "Style sheet file not found:" << file;
                continue;
            }
            
            if (styleFile.open(QFile::ReadOnly)) {
                QString fileContent = QLatin1String(styleFile.readAll());
                combinedStyleSheet.append(fileContent);
                combinedStyleSheet.append("\n\n");
                qDebug() << "Loaded style sheet:" << file << "(" << fileContent.length() << " bytes)";
                styleFile.close();
            } else {
                qWarning() << "Failed to open style sheet file:" << file;
            }
        }
        
        if (combinedStyleSheet.isEmpty()) {
            qWarning() << "No valid style sheets were loaded.";
            return false;
        }
        
        qDebug() << "Applying combined style sheet (" << combinedStyleSheet.length() << " bytes)";
        qApp->setStyleSheet(combinedStyleSheet);
        
        return true;
    }
};

#endif // STYLEMANAGER_H 