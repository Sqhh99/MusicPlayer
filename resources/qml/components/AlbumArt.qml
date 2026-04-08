import QtQuick
import Qt5Compat.GraphicalEffects
import MusicPlayer

Item {
    id: root

    property string title: ""
    property bool playing: false
    property int size: 280
    property string source: ""
    property int cornerRadius: 0

    width: size
    height: size

    // Shadow only when no image loaded
    Rectangle {
        id: shadow
        anchors.centerIn: parent
        width: root.width + 16
        height: root.height + 16
        radius: root.cornerRadius > 0 ? root.cornerRadius + 6 : root.width * 0.18
        color: Theme.surfaceShadow
        opacity: root.playing ? 0.10 : 0.06
        visible: root.source.length === 0
    }

    // Cover container with clipping for rounded corners
    Rectangle {
        id: cover
        anchors.centerIn: parent
        width: root.width
        height: root.height
        radius: root.cornerRadius > 0 ? root.cornerRadius : Math.max(18, Math.round(root.width * 0.14))
        antialiasing: true
        color: root.source.length > 0 ? "transparent" : Theme.albumPlaceholderBg
        border.color: root.source.length > 0 ? "transparent" : Theme.albumPlaceholderBorder
        border.width: root.source.length > 0 ? 0 : 1
        scale: root.playing ? 1.0 : 0.96
        Behavior on scale {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Image {
            id: albumMask
            anchors.fill: parent
            visible: false
            source: root.source
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        Rectangle {
            id: albumMaskShape
            anchors.fill: parent
            visible: false
            radius: cover.radius
            antialiasing: true
            color: "black"
        }

        OpacityMask {
            anchors.fill: parent
            visible: root.source.length > 0
            source: albumMask
            maskSource: albumMaskShape
        }

        // Placeholder gradient when no image
        Rectangle {
            anchors.fill: parent
            radius: cover.radius
            visible: root.source.length === 0
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.albumPlaceholderStart }
                GradientStop { position: 1.0; color: Theme.albumPlaceholderEnd }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: cover.radius
            visible: root.source.length > 0
            color: "transparent"
            border.color: "transparent"
        }
    }
}
