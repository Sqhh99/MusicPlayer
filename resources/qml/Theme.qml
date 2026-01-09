pragma Singleton
import QtQuick
import MusicPlayer

QtObject {
    // Colors
    readonly property color background: "#f0f0f0"
    readonly property color backgroundDark: "#e0e0e0"
    readonly property color border: "#e0e0e0"
    readonly property color accent: "#1DB954"
    readonly property color accentHover: "#18a349"
    readonly property color accentDark: "#15803d"
    readonly property color textPrimary: "#303030"
    readonly property color textSecondary: "#777777"
    readonly property color textLight: "#555555"
    readonly property color white: "#ffffff"
    readonly property color transparent: "transparent"
    readonly property color sliderTrack: "#cccccc"
    readonly property color sliderHandle: "#333333"
    readonly property color sliderHandleHover: "#000000"
    readonly property color hoverBg: "#e0e0e0"
    readonly property color pressedBg: "#d0d0d0"
    readonly property color notificationBg: "#323232"
    readonly property color notificationBorder: "#444444"

    // Fonts
    readonly property int fontSizeSmall: 9
    readonly property int fontSizeNormal: 10
    readonly property int fontSizeMedium: 12
    readonly property int fontSizeLarge: 14

    // Dimensions
    readonly property int buttonSize: 36
    readonly property int buttonSizeSmall: 20
    readonly property int iconSize: 24
    readonly property int iconSizeSmall: 16
    readonly property int borderRadius: 8
    readonly property int borderRadiusSmall: 4
    readonly property int sliderHeight: 4
    readonly property int sliderHandleSize: 12
    readonly property int sliderHandleSizeHover: 14

    // Spacing
    readonly property int spacingSmall: 5
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 10
    readonly property int marginNormal: 10
    readonly property int marginSmall: 5

    // Animation
    readonly property int animationDuration: 150
    readonly property int animationDurationFast: 100

    // Window
    readonly property int windowWidth: 480
    readonly property int windowHeight: 150
    readonly property int windowMinWidth: 400
    readonly property int windowMinHeight: 120
    readonly property int playlistHeight: 200
}

