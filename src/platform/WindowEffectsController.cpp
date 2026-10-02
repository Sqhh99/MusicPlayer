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

enum DwmSystemBackdropType {
    DWMSBT_AUTO = 0,
    DWMSBT_NONE = 1,
    DWMSBT_MAINWINDOW = 2,
    DWMSBT_TRANSIENTWINDOW = 3,
    DWMSBT_TABBEDWINDOW = 4
};

constexpr DWORD DWMWA_WINDOW_CORNER_PREFERENCE = 33;
constexpr DWORD DWMWA_BORDER_COLOR = 34;
constexpr DWORD DWMWA_SYSTEMBACKDROP_TYPE = 38;
constexpr DWORD DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
constexpr COLORREF DWMWA_COLOR_NONE = 0xFFFFFFFE;

DwmSetWindowAttributeFn resolveDwmSetWindowAttribute()
{
    static const auto fn = reinterpret_cast<DwmSetWindowAttributeFn>(
        GetProcAddress(GetModuleHandleW(L"dwmapi.dll"), "DwmSetWindowAttribute"));
    return fn;
}

bool applyWindowCornerPreference(HWND hwnd, int radius)
{
    const auto dwmSetWindowAttribute = resolveDwmSetWindowAttribute();
    if (!hwnd || !dwmSetWindowAttribute) {
        return false;
    }

    const DwmWindowCornerPreference preference =
        radius <= 0 ? DWMWCP_DONOTROUND
                    : (radius <= 4 ? DWMWCP_ROUNDSMALL : DWMWCP_ROUND);
    const HRESULT cornerHr = dwmSetWindowAttribute(hwnd,
                                                   DWMWA_WINDOW_CORNER_PREFERENCE,
                                                   &preference,
                                                   sizeof(preference));

    // Suppress the system-drawn frame border so it does not glow against the QML surface.
    const COLORREF borderColor = DWMWA_COLOR_NONE;
    const HRESULT borderHr = dwmSetWindowAttribute(hwnd,
                                                   DWMWA_BORDER_COLOR,
                                                   &borderColor,
                                                   sizeof(borderColor));
    return SUCCEEDED(cornerHr) || SUCCEEDED(borderHr);
}

bool applySystemBackdropType(HWND hwnd, int backdropType)
{
    const auto dwmSetWindowAttribute = resolveDwmSetWindowAttribute();
    if (!hwnd || !dwmSetWindowAttribute) {
        return false;
    }

    const int boundedType = qBound(static_cast<int>(DWMSBT_AUTO),
                                   backdropType,
                                   static_cast<int>(DWMSBT_TABBEDWINDOW));
    const auto type = static_cast<DwmSystemBackdropType>(boundedType);
    const HRESULT hr = dwmSetWindowAttribute(hwnd,
                                             DWMWA_SYSTEMBACKDROP_TYPE,
                                             &type,
                                             sizeof(type));
    return SUCCEEDED(hr);
}

bool applyImmersiveDarkMode(HWND hwnd, bool enabled)
{
    const auto dwmSetWindowAttribute = resolveDwmSetWindowAttribute();
    if (!hwnd || !dwmSetWindowAttribute) {
        return false;
    }

    const BOOL darkMode = enabled ? TRUE : FALSE;
    const HRESULT hr = dwmSetWindowAttribute(hwnd,
                                             DWMWA_USE_IMMERSIVE_DARK_MODE,
                                             &darkMode,
                                             sizeof(darkMode));
    return SUCCEEDED(hr);
}

void applyWindowMask(HWND hwnd, int radius)
{
    if (!hwnd) {
        return;
    }

    RECT clientRect = {};
    if (!GetClientRect(hwnd, &clientRect)) {
        return;
    }

    const int width = clientRect.right - clientRect.left;
    const int height = clientRect.bottom - clientRect.top;

    if (radius <= 0 || width <= 0 || height <= 0) {
        SetWindowRgn(hwnd, nullptr, TRUE);
        return;
    }

    const int diameter = radius * 2;
    HRGN region = CreateRoundRectRgn(0, 0, width + 1, height + 1, diameter, diameter);
    if (!region) {
        return;
    }

    if (SetWindowRgn(hwnd, region, TRUE) == 0) {
        DeleteObject(region);
    }
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

int WindowEffectsController::systemBackdropType() const
{
    return m_systemBackdropType;
}

bool WindowEffectsController::darkModeEnabled() const
{
    return m_darkModeEnabled;
}

int WindowEffectsController::windowMaskRadius() const
{
    return m_windowMaskRadius;
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

void WindowEffectsController::setSystemBackdropType(int type)
{
    type = qBound(1, type, 4);
    if (m_systemBackdropType == type) {
        return;
    }

    m_systemBackdropType = type;
    emit systemBackdropTypeChanged();
    scheduleApply();
}

void WindowEffectsController::setDarkModeEnabled(bool enabled)
{
    if (m_darkModeEnabled == enabled) {
        return;
    }

    m_darkModeEnabled = enabled;
    emit darkModeEnabledChanged();
    scheduleApply();
}

void WindowEffectsController::setWindowMaskRadius(int radius)
{
    radius = qMax(0, radius);
    if (m_windowMaskRadius == radius) {
        return;
    }

    m_windowMaskRadius = radius;
    emit windowMaskRadiusChanged();
    scheduleApply();
}

void WindowEffectsController::applyNow()
{
    m_applyScheduled = false;
    applyEffects();
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
    const bool cornerApplied = applyWindowCornerPreference(hwnd, m_cornerRadius);
    const bool backdropApplied = applySystemBackdropType(hwnd, m_systemBackdropType);
    applyImmersiveDarkMode(hwnd, m_darkModeEnabled);
    applyWindowMask(hwnd, m_windowMaskRadius);
    setAcrylicEnabled(backdropApplied && m_systemBackdropType == DWMSBT_TRANSIENTWINDOW);
    if (!cornerApplied && !backdropApplied) {
        setAcrylicEnabled(false);
    }
    return;
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
