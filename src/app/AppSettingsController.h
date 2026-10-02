#ifndef APPSETTINGSCONTROLLER_H
#define APPSETTINGSCONTROLLER_H

#include <QObject>

#include "../backend/musicsettings.h"

class AppSettingsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(int materialStrength READ materialStrength WRITE setMaterialStrength NOTIFY materialStrengthChanged)
    Q_PROPERTY(int buttonMaterialStrength READ buttonMaterialStrength WRITE setButtonMaterialStrength NOTIFY buttonMaterialStrengthChanged)
    Q_PROPERTY(bool backgroundGlowEnabled READ backgroundGlowEnabled WRITE setBackgroundGlowEnabled NOTIFY backgroundGlowEnabledChanged)

public:
    explicit AppSettingsController(QObject *parent = nullptr);

    QString themeMode() const;
    void setThemeMode(const QString &mode);

    int materialStrength() const;
    void setMaterialStrength(int strength);

    int buttonMaterialStrength() const;
    void setButtonMaterialStrength(int strength);

    bool backgroundGlowEnabled() const;
    void setBackgroundGlowEnabled(bool enabled);

signals:
    void themeModeChanged();
    void materialStrengthChanged();
    void buttonMaterialStrengthChanged();
    void backgroundGlowEnabledChanged();

private:
    static int clampPercent(int value);

    MusicSettings m_settings;
    QString m_themeMode;
    int m_materialStrength = 72;
    int m_buttonMaterialStrength = 62;
    bool m_backgroundGlowEnabled = true;
};

#endif // APPSETTINGSCONTROLLER_H
