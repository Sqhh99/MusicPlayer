import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property bool miniMode: false
    property bool islandMode: false
    property bool isPinned: false
    property bool settingsOpen: false

    signal toggleMiniRequested()
    signal openIslandRequested()
    signal minimizeRequested()
    signal closeRequested()
    signal togglePinRequested()
    signal openSettingsRequested()

    implicitWidth: controlsRow.implicitWidth
    implicitHeight: controlsRow.implicitHeight

    property bool showControls: true
    property int hideDelay: 2000

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: root.showControls = false
    }

    MouseArea {
        id: hoverArea
        anchors.fill: controlsRow
        anchors.margins: -10
        hoverEnabled: true
        onEntered: {
            root.showControls = true
            hideTimer.stop()
        }
        onExited: hideTimer.start()
    }

    Row {
        id: controlsRow
        spacing: 6
        opacity: root.showControls ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + (root.miniMode ? "picture-in-picture-2.png" : "picture-in-picture.png")
            iconColor: Theme.buttonIconColor
            iconOpacity: Theme.buttonIconSoftOpacity
            active: false
            onClicked: root.toggleMiniRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "pill.png"
            iconColor: Theme.buttonIconColor
            iconOpacity: root.islandMode ? Theme.buttonIconStrongOpacity : Theme.buttonIconSoftOpacity
            active: root.islandMode
            activeBackgroundColor: Theme.accentSoft
            onClicked: root.openIslandRequested()
        }

        // Pin button - between mini mode and minimize
        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "pin.png"
            iconColor: Theme.buttonIconColor
            iconOpacity: root.isPinned ? Theme.buttonIconStrongOpacity : Theme.buttonIconMutedOpacity
            active: root.isPinned
            activeBackgroundColor: Theme.accentSoft
            onClicked: root.togglePinRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "settings.png"
            iconColor: Theme.buttonIconColor
            iconOpacity: root.settingsOpen ? Theme.buttonIconStrongOpacity : Theme.buttonIconSoftOpacity
            active: root.settingsOpen
            activeBackgroundColor: Theme.accentSoft
            onClicked: root.openSettingsRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "minus.png"
            iconColor: Theme.buttonIconColor
            iconOpacity: Theme.buttonIconSoftOpacity
            onClicked: root.minimizeRequested()
        }

        IconButton {
            size: 26
            iconSize: 12
            iconSource: Theme.iconPath + "x.png"
            iconColor: Theme.buttonIconColor
            iconOpacity: Theme.buttonIconSoftOpacity
            hoverColor: Theme.closeHoverBg
            activeColor: Theme.closeActiveColor
            onClicked: root.closeRequested()
        }
    }
}
