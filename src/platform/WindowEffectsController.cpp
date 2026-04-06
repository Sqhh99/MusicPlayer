#include "WindowEffectsController.h"

#include <QEvent>
#include <QPlatformSurfaceEvent>
#include <QQuickWindow>
#include <QTimer>

#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

namespace {

#ifdef Q_OS_WIN

using DwmSetWindowAttributeFn =
    HRESULT (WINAPI *)(HWND, DWORD, LPCVOID, DWORD);

enum DwmWindowCornerPreference {
    DWMWCP_DEFAULT = 0,
    DWMWCP_DONOTROUND = 1,
    DWMWCP_ROUND = 2,
    DWMWCP_ROUNDSMALL = 3
};

constexpr DWORD DWMWA_WINDOW_CORNER_PREFERENCE = 33;

DwmSetWindowAttributeFn resolveDwmSetWindowAttribute()
{
    static const auto fn = reinterpret_cast<DwmSetWindowAttributeFn>(
        GetProcAddress(GetModuleHandleW(L"dwmapi.dll"), "DwmSetWindowAttribute"));
    return fn;
}

void applyWindowCornerPreference(HWND hwnd, int radius)
{
    const auto dwmSetWindowAttribute = resolveDwmSetWindowAttribute();
    if (!hwnd || !dwmSetWindowAttribute) {
        return;
    }

    const DwmWindowCornerPreference preference =
        radius <= 8 ? DWMWCP_ROUNDSMALL : DWMWCP_ROUND;
    dwmSetWindowAttribute(hwnd,
                          DWMWA_WINDOW_CORNER_PREFERENCE,
                          &preference,
                          sizeof(preference));
}

#endif

} // namespace

WindowEffectsController::WindowEffectsController(QObject *parent)
    : QObject(parent)
{
}

void WindowEffectsController::attachTo(QQuickWindow *window)
{
    if (m_window == window) {
        return;
    }

    if (m_window) {
        m_window->removeEventFilter(this);
        disconnect(m_window, nullptr, this, nullptr);
    }

    m_window = window;

    if (!m_window) {
        setAcrylicEnabled(false);
        return;
    }

    m_window->installEventFilter(this);

    connect(m_window, &QObject::destroyed, this, [this]() {
        m_window = nullptr;
        m_applyScheduled = false;
        setAcrylicEnabled(false);
    });

    scheduleApply();
}

bool WindowEffectsController::acrylicEnabled() const
{
    return m_acrylicEnabled;
}

int WindowEffectsController::cornerRadius() const
{
    return m_cornerRadius;
}

void WindowEffectsController::setCornerRadius(int radius)
{
    radius = qMax(0, radius);
    if (m_cornerRadius == radius) {
        return;
    }

    m_cornerRadius = radius;
    emit cornerRadiusChanged();
    scheduleApply();
}

bool WindowEffectsController::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_window) {
        switch (event->type()) {
        case QEvent::Show:
        case QEvent::Expose:
        case QEvent::Resize:
        case QEvent::WinIdChange:
        case QEvent::DevicePixelRatioChange:
            scheduleApply();
            break;
        case QEvent::PlatformSurface: {
            const auto *surfaceEvent = static_cast<QPlatformSurfaceEvent *>(event);
            if (surfaceEvent->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated) {
                scheduleApply();
            }
            break;
        }
        default:
            break;
        }
    }

    return QObject::eventFilter(watched, event);
}

void WindowEffectsController::scheduleApply()
{
    if (m_applyScheduled) {
        return;
    }

    m_applyScheduled = true;
    QTimer::singleShot(0, this, [this]() {
        m_applyScheduled = false;
        applyEffects();
    });
}

void WindowEffectsController::applyEffects()
{
#ifdef Q_OS_WIN
    if (!m_window) {
        setAcrylicEnabled(false);
        return;
    }

    const auto hwnd = reinterpret_cast<HWND>(m_window->winId());
    applyWindowCornerPreference(hwnd, m_cornerRadius);
#endif
    setAcrylicEnabled(false);
}

void WindowEffectsController::setAcrylicEnabled(bool enabled)
{
    if (m_acrylicEnabled == enabled) {
        return;
    }

    m_acrylicEnabled = enabled;
    emit acrylicEnabledChanged();
}
