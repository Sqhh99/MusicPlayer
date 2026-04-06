pragma Singleton
import QtQuick
import MusicPlayer

QtObject {
    function clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }

    function rgba(red, green, blue, alpha) {
        return Qt.rgba(red / 255, green / 255, blue / 255, clamp01(alpha))
    }

    readonly property bool darkMode: appSettings.themeMode === "night"
    readonly property real materialAmount: appSettings.materialStrength / 100
    readonly property real buttonMaterialAmount: appSettings.buttonMaterialStrength / 100

    readonly property string fontFamily: "Plus Jakarta Sans"
    readonly property string fontFamilyMono: "JetBrains Mono"

    readonly property color backgroundStart: darkMode ? "#0a0a0b" : "#f3f4f6"
    readonly property color backgroundEnd: darkMode ? "#121214" : "#f3f4f6"
    readonly property color glowBlue: darkMode ? "#3b82f6" : "#bfdbfe"
    readonly property color glowRose: darkMode ? "#374151" : "#e9d5ff"

    readonly property color cardBg: darkMode ? rgba(16, 16, 18, 0.94) : "#ffffff"
    readonly property color cardBorder: darkMode ? rgba(255, 255, 255, 0.10) : "#e5e7eb"
    readonly property color cardShadow: darkMode ? "#66000000" : "#0000001a"
    readonly property color acrylicCardBg: darkMode ? rgba(12, 12, 14, 0.74) : rgba(255, 255, 255, 0.66)
    readonly property color acrylicCardBorder: darkMode ? rgba(255, 255, 255, 0.14) : rgba(255, 255, 255, 0.55)
    readonly property color acrylicOverlayBg: darkMode ? rgba(16, 16, 18, 0.88) : rgba(255, 255, 255, 0.74)
    readonly property color acrylicOverlayBorder: darkMode ? rgba(255, 255, 255, 0.12) : rgba(255, 255, 255, 0.59)
    readonly property color surfaceBg: darkMode
        ? rgba(12, 12, 14, 0.78 + (0.14 * materialAmount))
        : rgba(248, 248, 249, 0.84 + (0.10 * materialAmount))
    readonly property color surfaceBorder: darkMode
        ? rgba(255, 255, 255, 0.10 + (0.10 * materialAmount))
        : rgba(255, 255, 255, 0.50 + (0.24 * materialAmount))
    readonly property color surfaceOverlayBg: darkMode
        ? rgba(16, 16, 18, 0.88 + (0.08 * materialAmount))
        : rgba(252, 252, 253, 0.90 + (0.06 * materialAmount))
    readonly property color surfaceOverlayBorder: darkMode
        ? rgba(255, 255, 255, 0.10 + (0.08 * materialAmount))
        : rgba(229, 231, 235, 0.70 + (0.10 * materialAmount))
    readonly property color surfacePanelBg: darkMode
        ? rgba(24, 24, 27, 0.84 + (0.08 * materialAmount))
        : rgba(253, 253, 253, 0.82 + (0.10 * materialAmount))
    readonly property color surfacePanelBorder: darkMode
        ? rgba(255, 255, 255, 0.10 + (0.08 * materialAmount))
        : rgba(229, 231, 235, 0.62 + (0.12 * materialAmount))
    readonly property color surfaceHighlight: darkMode
        ? rgba(255, 255, 255, 0.04 + (0.04 * materialAmount))
        : rgba(255, 255, 255, 0.38 + (0.14 * materialAmount))
    readonly property color surfaceMidHighlight: darkMode
        ? rgba(255, 255, 255, 0.03 + (0.03 * materialAmount))
        : rgba(255, 255, 255, 0.16 + (0.06 * materialAmount))
    readonly property color surfaceBottomTint: darkMode
        ? rgba(255, 255, 255, 0.02 + (0.02 * materialAmount))
        : rgba(203, 213, 225, 0.04 + (0.06 * materialAmount))
    readonly property color surfaceGlowBlue: appSettings.backgroundGlowEnabled
        ? (darkMode ? rgba(59, 130, 246, 0.08) : rgba(191, 219, 254, 0.15))
        : rgba(0, 0, 0, 0)
    readonly property color surfaceGlowRose: appSettings.backgroundGlowEnabled
        ? (darkMode ? rgba(255, 255, 255, 0.03) : rgba(233, 213, 255, 0.10))
        : rgba(0, 0, 0, 0)
    readonly property color surfaceShadow: darkMode ? rgba(0, 0, 0, 0.50) : rgba(15, 23, 42, 0.09)
    readonly property color materialButtonBg: darkMode
        ? rgba(255, 255, 255, 0.10 + (0.08 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.22 + (0.20 * buttonMaterialAmount))
    readonly property color materialButtonHoverBg: darkMode
        ? rgba(255, 255, 255, 0.14 + (0.10 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.34 + (0.22 * buttonMaterialAmount))
    readonly property color materialButtonPressedBg: darkMode
        ? rgba(255, 255, 255, 0.18 + (0.10 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.46 + (0.22 * buttonMaterialAmount))
    readonly property color materialButtonBorder: darkMode
        ? rgba(255, 255, 255, 0.12 + (0.10 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.28 + (0.18 * buttonMaterialAmount))
    readonly property color materialButtonActiveBg: darkMode
        ? rgba(90, 150, 255, 0.20 + (0.12 * buttonMaterialAmount))
        : rgba(239, 246, 255, 0.58 + (0.18 * buttonMaterialAmount))
    readonly property color materialPrimaryButtonBg: darkMode
        ? rgba(255, 255, 255, 0.18 + (0.12 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.46 + (0.24 * buttonMaterialAmount))
    readonly property color materialPrimaryButtonHoverBg: darkMode
        ? rgba(255, 255, 255, 0.24 + (0.12 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.58 + (0.24 * buttonMaterialAmount))
    readonly property color materialPrimaryButtonPressedBg: darkMode
        ? rgba(255, 255, 255, 0.30 + (0.10 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.68 + (0.24 * buttonMaterialAmount))
    readonly property color materialPrimaryButtonBorder: darkMode
        ? rgba(255, 255, 255, 0.18 + (0.10 * buttonMaterialAmount))
        : rgba(255, 255, 255, 0.34 + (0.18 * buttonMaterialAmount))
    readonly property color playlistRowHoverBg: darkMode
        ? rgba(255, 255, 255, 0.06 + (0.04 * materialAmount))
        : rgba(255, 255, 255, 0.32 + (0.12 * materialAmount))
    readonly property color playlistRowActiveBg: darkMode
        ? rgba(90, 150, 255, 0.16 + (0.08 * materialAmount))
        : rgba(239, 246, 255, 0.48 + (0.10 * materialAmount))
    readonly property color albumPlaceholderBg: darkMode
        ? rgba(24, 24, 27, 0.92)
        : "#f3f4f6"
    readonly property color albumPlaceholderBorder: darkMode
        ? rgba(255, 255, 255, 0.10)
        : "#e5e7eb"
    readonly property color albumPlaceholderStart: darkMode
        ? rgba(97, 97, 105, 0.62)
        : "#d1d5db"
    readonly property color albumPlaceholderEnd: darkMode
        ? rgba(32, 32, 36, 0.96)
        : "#f3f4f6"
    readonly property color closeHoverBg: darkMode
        ? rgba(239, 68, 68, 0.24)
        : "#ffe4e6"
    readonly property color closeActiveColor: "#ef4444"

    readonly property color textPrimary: darkMode ? "#f5f5f5" : "#111827"
    readonly property color textSecondary: darkMode ? "#e5e7eb" : "#1f2937"
    readonly property color textSubtle: darkMode ? "#c9cdd3" : "#6b7280"
    readonly property color textMuted: darkMode ? "#aeb4be" : "#9ca3af"
    readonly property color buttonIconColor: darkMode ? "#f3f4f6" : "#1f2937"
    readonly property color buttonIconActiveColor: darkMode ? "#ffffff" : "#1d4ed8"
    readonly property real buttonIconOpacity: darkMode ? 0.90 : 0.88
    readonly property real buttonIconMutedOpacity: darkMode ? 0.82 : 0.74
    readonly property real buttonIconSoftOpacity: darkMode ? 0.88 : 0.82
    readonly property real buttonIconStrongOpacity: darkMode ? 1.00 : 0.96

    readonly property color accent: darkMode ? "#7ab2ff" : "#3b82f6"
    readonly property color accentSoft: darkMode ? rgba(122, 178, 255, 0.16) : "#eff6ff"
    readonly property color accentDark: darkMode ? "#dbeafe" : "#1d4ed8"

    readonly property color controlBg: darkMode ? rgba(26, 26, 28, 0.96) : "#f8fafc"
    readonly property color hoverBg: darkMode ? rgba(255, 255, 255, 0.08) : "#0000000a"

    readonly property color trackBg: darkMode ? rgba(255, 255, 255, 0.12) : "#e5e7eb"
    readonly property color trackFill: darkMode ? "#f3f4f6" : "#1f2937"
    readonly property color handle: darkMode ? "#ffffff" : "#1f2937"

    readonly property color overlayBg: darkMode ? rgba(12, 12, 14, 0.96) : "#ffffff"
    readonly property color overlayBorder: darkMode ? rgba(255, 255, 255, 0.10) : "#f3f4f6"

    readonly property int fullWidth: 980
    readonly property int fullHeight: 712
    readonly property int miniWidth: 558
    readonly property int miniHeight: 180
    readonly property int minWidth: 980
    readonly property int minHeight: 712

    readonly property int outerPadding: 40
    readonly property int outerPaddingMini: 14
    readonly property int radiusLarge: 8
    readonly property int radiusMini: 8

    readonly property int albumSize: 300
    readonly property int albumSizeMini: 128
    readonly property int albumRadius: 36
    readonly property int albumRadiusMini: 22
    readonly property int albumColumnWidth: 396
    readonly property int columnSpacing: 32
    readonly property int titleSize: 34
    readonly property int artistSize: 17
    readonly property int titleSizeMini: 18
    readonly property int artistSizeMini: 12
    readonly property int controlSizeXl: 68
    readonly property int controlSizeMd: 48
    readonly property int controlSizeMiniPlay: 44
    readonly property int progressHeight: 6
    readonly property int progressHeightMini: 5
    readonly property int bottomBarHeight: 36
    readonly property int headerInset: 64

    readonly property int iconSizeSm: 14
    readonly property int iconSize: 18
    readonly property int iconSizeLg: 26

    readonly property int controlSize: 40
    readonly property int controlSizeSm: 30
    readonly property int controlSizeLg: 72

    readonly property int spacingSm: 6
    readonly property int spacingMd: 10
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    readonly property int dragHeight: 48

    readonly property string iconPath: "qrc:/qt/qml/MusicPlayer/resources/icons/"
}
