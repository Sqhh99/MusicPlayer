pragma Singleton
import QtQuick
import MusicPlayer

QtObject {
    readonly property string fontFamily: "Plus Jakarta Sans"
    readonly property string fontFamilyMono: "JetBrains Mono"

    readonly property color backgroundStart: "#f3f4f6"
    readonly property color backgroundEnd: "#f3f4f6"
    readonly property color glowBlue: "#bfdbfe"
    readonly property color glowRose: "#e9d5ff"

    readonly property color cardBg: "#ffffff"
    readonly property color cardBorder: "#e5e7eb"
    readonly property color cardShadow: "#0000001a"

    readonly property color textPrimary: "#111827"
    readonly property color textSecondary: "#1f2937"
    readonly property color textSubtle: "#6b7280"
    readonly property color textMuted: "#9ca3af"

    readonly property color accent: "#3b82f6"
    readonly property color accentSoft: "#eff6ff"
    readonly property color accentDark: "#1d4ed8"

    readonly property color controlBg: "#f8fafc"
    readonly property color hoverBg: "#0000000a"

    readonly property color trackBg: "#e5e7eb"
    readonly property color trackFill: "#1f2937"
    readonly property color handle: "#1f2937"

    readonly property color overlayBg: "#ffffff"
    readonly property color overlayBorder: "#f3f4f6"

    readonly property int fullWidth: 980
    readonly property int fullHeight: 712
    readonly property int miniWidth: 558
    readonly property int miniHeight: 205
    readonly property int minWidth: 980
    readonly property int minHeight: 712

    readonly property int outerPadding: 40
    readonly property int outerPaddingMini: 18
    readonly property int radiusLarge: 32
    readonly property int radiusMini: 24

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
