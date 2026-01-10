import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property bool miniMode: false
    property bool isPinned: false

    signal toggleMiniRequested()
    signal minimizeRequested()
    signal closeRequested()
    signal togglePinRequested()

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
            onClicked: root.toggleMiniRequested()
        }

        // Pin button - between mini mode and minimize
        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "pin.png"
            iconColor: Theme.textMuted
            iconOpacity: root.isPinned ? 0.9 : 0.5
            active: root.isPinned
            activeBackgroundColor: Theme.accentSoft
            onClicked: root.togglePinRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "minus.png"
            iconColor: Theme.textMuted
            iconOpacity: 0.6
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
