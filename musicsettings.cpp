#include "musicsettings.h"
#include <QDir> // For QDir::homePath()
#include <QDebug> // For qDebug, if not already implicitly included by QObject
#include <QStandardPaths> // For QStandardPaths

MusicSettings::MusicSettings(QObject *parent)
    : QObject{parent}
    , settings(new QSettings(getConfigPath(), QSettings::IniFormat))
{
    // Ensure the encoding is set to UTF-8 for broader compatibility if needed
    // settings->setIniCodec("UTF-8"); // Uncomment if you face encoding issues with paths
    // 输出配置文件路径信息
    qDebug() << "配置文件保存路径:" << settings->fileName();
}

MusicSettings::~MusicSettings() {
    delete settings;
}

void MusicSettings::saveMusicPaths(const QStringList &musicPaths) {
    settings->setValue("Music/Paths", musicPaths);
    settings->sync();
}

QStringList MusicSettings::loadMusicPaths() const {
    return settings->value("Music/Paths").toStringList();
}

void MusicSettings::clearMusicPaths() {
    settings->remove("Music/Paths");
    settings->sync();
}

void MusicSettings::printConfigPath() const {
    qDebug() << "Config file path:" << settings->fileName();
}

// Implementation of new methods
QString MusicSettings::loadLastPath() const {
    return settings->value("General/LastPath", QDir::homePath()).toString();
}

void MusicSettings::saveLastPath(const QString &path) {
    if (!path.isEmpty()) {
        settings->setValue("General/LastPath", path);
        settings->sync();
    }
}

// 通用设置方法
void MusicSettings::setValue(const QString &key, const QVariant &value) {
    settings->setValue(key, value);
    settings->sync();
}

QVariant MusicSettings::value(const QString &key, const QVariant &defaultValue) const {
    return settings->value(key, defaultValue);
}

// 获取配置文件路径
QString MusicSettings::getConfigPath() const {
    // 获取应用程序数据的标准路径
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    
    // 确保目录存在
    QDir dir(appDataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    
    // 返回完整的配置文件路径
    return appDataPath + "/musicConfig.ini";
}
