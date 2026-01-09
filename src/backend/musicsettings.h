#ifndef MUSICSETTINGS_H
#define MUSICSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QStandardPaths>
#include <QDir>

class MusicSettings : public QObject
{
    Q_OBJECT
public:
    explicit MusicSettings(QObject *parent = nullptr);
    ~MusicSettings();

    void saveMusicPaths(const QStringList &musicPaths);

    QStringList loadMusicPaths() const;

    void clearMusicPaths();

    void printConfigPath() const;

    QString loadLastPath() const;

    void saveLastPath(const QString &path);
    
    // 添加通用设置操作方法
    void setValue(const QString &key, const QVariant &value);
    QVariant value(const QString &key, const QVariant &defaultValue = QVariant()) const;

private:
    QString getConfigPath() const;
    QSettings* settings;
};

#endif // MUSICSETTINGS_H
