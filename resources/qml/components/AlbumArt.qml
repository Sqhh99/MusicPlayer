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

    Rectangle {
        id: shadow
        anchors.centerIn: parent
        width: root.width + 16
        height: root.height + 16
        radius: root.cornerRadius > 0 ? root.cornerRadius + 6 : root.width * 0.18
        color: "#000000"
        opacity: root.playing ? 0.10 : 0.06
    }

    Rectangle {
        id: cover
        anchors.centerIn: parent
        width: root.width
        height: root.height
        radius: root.cornerRadius > 0 ? root.cornerRadius : Math.max(18, Math.round(root.width * 0.14))
        color: "#f3f4f6"
        border.color: "#e5e7eb"
        border.width: 1
        clip: true
        scale: root.playing ? 1.0 : 0.96
        Behavior on scale {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Image {
            anchors.fill: parent
            source: root.source
            visible: root.source.length > 0
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

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
