import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    signal clicked()

    width: 30
    height: 30
    implicitWidth: width
    implicitHeight: height

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: closeButtonArea.pressed
            ? Theme.materialButtonPressedBg
            : (closeButtonArea.containsMouse ? Theme.closeHoverBg : "transparent")
    }

    TintedIcon {
        anchors.centerIn: parent
        source: Theme.iconPath + "x.png"
        width: 12
        height: 12
        tintColor: Theme.buttonIconColor
        opacity: closeButtonArea.containsMouse ? 0.9 : 0.6
    }

    MouseArea {
        id: closeButtonArea
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
