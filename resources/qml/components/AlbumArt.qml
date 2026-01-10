import QtQuick
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
        color: "#000000"
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
        color: root.source.length > 0 ? "transparent" : "#f3f4f6"
        border.color: root.source.length > 0 ? "transparent" : "#e5e7eb"
        border.width: root.source.length > 0 ? 0 : 1
        clip: true
        scale: root.playing ? 1.0 : 0.96
        Behavior on scale {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        // Album art image - simple version without problematic layer.effect
        Image {
            id: albumImage
            anchors.fill: parent
            source: root.source
            visible: root.source.length > 0
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        // Placeholder gradient when no image
        Rectangle {
            anchors.fill: parent
            radius: cover.radius
            visible: root.source.length === 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#d1d5db" }
                GradientStop { position: 1.0; color: "#f3f4f6" }
            }
        }
    }
}
