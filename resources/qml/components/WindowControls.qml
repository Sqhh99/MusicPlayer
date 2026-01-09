import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property bool miniMode: false

    signal toggleMiniRequested()
    signal minimizeRequested()
    signal closeRequested()

    implicitWidth: controlsRow.implicitWidth
    implicitHeight: controlsRow.implicitHeight

    Row {
        id: controlsRow
        spacing: 6

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "maximize-2.png"
            iconColor: Theme.textMuted
            iconOpacity: 0.6
            active: false
            hoverColor: Theme.hoverBg
            onClicked: root.toggleMiniRequested()
        }

        Rectangle {
            width: 1
            height: 12
            radius: 1
            color: "#d1d5db"
            anchors.verticalCenter: parent.verticalCenter
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "minus.png"
            iconColor: Theme.textMuted
            iconOpacity: 0.6
            hoverColor: Theme.hoverBg
            onClicked: root.minimizeRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "x.png"
            iconColor: Theme.textMuted
            iconOpacity: 0.6
            hoverColor: "#ffe4e6"
            activeColor: "#ef4444"
            onClicked: root.closeRequested()
        }
    }
}
