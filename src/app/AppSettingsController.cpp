#include "AppSettingsController.h"

namespace {

constexpr auto kThemeModeKey = "ui/themeMode";
constexpr auto kMaterialStrengthKey = "ui/materialStrength";
constexpr auto kButtonMaterialStrengthKey = "ui/buttonMaterialStrength";
constexpr auto kBackgroundGlowEnabledKey = "ui/backgroundGlowEnabled";

QString sanitizeThemeMode(const QString &mode)
{
    return mode == "night" ? "night" : "day";
}

} // namespace

AppSettingsController::AppSettingsController(QObject *parent)
    : QObject(parent)
    , m_settings(this)
{
    m_themeMode = sanitizeThemeMode(m_settings.value(kThemeModeKey, "day").toString());
    m_materialStrength = clampPercent(m_settings.value(kMaterialStrengthKey, 72).toInt());
    m_buttonMaterialStrength = clampPercent(m_settings.value(kButtonMaterialStrengthKey, 62).toInt());
    m_backgroundGlowEnabled = m_settings.value(kBackgroundGlowEnabledKey, true).toBool();
}

QString AppSettingsController::themeMode() const
{
    return m_themeMode;
}

void AppSettingsController::setThemeMode(const QString &mode)
{
    const QString sanitized = sanitizeThemeMode(mode);
    if (m_themeMode == sanitized) {
        return;
    }

    m_themeMode = sanitized;
    m_settings.setValue(kThemeModeKey, m_themeMode);
    emit themeModeChanged();
}

int AppSettingsController::materialStrength() const
{
    return m_materialStrength;
}

void AppSettingsController::setMaterialStrength(int strength)
{
    const int clamped = clampPercent(strength);
    if (m_materialStrength == clamped) {
        return;
    }

    m_materialStrength = clamped;
    m_settings.setValue(kMaterialStrengthKey, m_materialStrength);
    emit materialStrengthChanged();
}

int AppSettingsController::buttonMaterialStrength() const
{
    return m_buttonMaterialStrength;
}

void AppSettingsController::setButtonMaterialStrength(int strength)
{
    const int clamped = clampPercent(strength);
    if (m_buttonMaterialStrength == clamped) {
        return;
    }

    m_buttonMaterialStrength = clamped;
    m_settings.setValue(kButtonMaterialStrengthKey, m_buttonMaterialStrength);
    emit buttonMaterialStrengthChanged();
}

bool AppSettingsController::backgroundGlowEnabled() const
{
    return m_backgroundGlowEnabled;
}

void AppSettingsController::setBackgroundGlowEnabled(bool enabled)
{
    if (m_backgroundGlowEnabled == enabled) {
        return;
    }

    m_backgroundGlowEnabled = enabled;
    m_settings.setValue(kBackgroundGlowEnabledKey, m_backgroundGlowEnabled);
    emit backgroundGlowEnabledChanged();
}

int AppSettingsController::clampPercent(int value)
{
    if (value < 0) {
        return 0;
    }
    if (value > 100) {
        return 100;
    }
    return value;
}
