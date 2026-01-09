import QtQuick
import QtQuick.Layouts
import MusicPlayer
import "./"

Item {
    id: root

    property int volume: 80
    property bool muted: false

    signal volumeRequested(int value)
    signal muteToggled()

    RowLayout {
        id: layoutRow
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        IconButton {
            size: 26
            iconSize: 14
            iconSource: root.muted || root.volume === 0
                ? Theme.iconPath + "volume-x.png"
                : Theme.iconPath + "volume-2.png"
            iconOpacity: 0.6
            hoverColor: Theme.hoverBg
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.muteToggled()
        }

        ProgressBar {
            id: slider
            width: 110
            height: 5
            handleSize: 10
            live: true
            alwaysShowHandle: true
            from: 0
            to: 100
            value: root.volume
            showHandle: true
            Layout.alignment: Qt.AlignVCenter
            onSeekRequested: (value) => root.volumeRequested(Math.round(value))
        }
    }

    implicitWidth: layoutRow.implicitWidth
    implicitHeight: layoutRow.implicitHeight
}
