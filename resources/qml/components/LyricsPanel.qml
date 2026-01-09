import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property var lyrics: []
    property int highlightIndex: 6

    signal backRequested()

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: lyricsColumn.height + 92
        clip: true

        Column {
            id: lyricsColumn
            x: 16
            y: 16
            width: flickable.width - 32
            spacing: 12

            Repeater {
                model: root.lyrics

                Text {
                    width: lyricsColumn.width
                    text: modelData
                    color: index === root.highlightIndex ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: index === root.highlightIndex ? 18 : 12
                    font.family: Theme.fontFamily
                    font.weight: index === root.highlightIndex ? Font.DemiBold : Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    IconButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        size: 34
        iconSize: 16
        iconSource: Theme.iconPath + "chevron-down.png"
        iconColor: Theme.textSubtle
        hoverColor: Theme.hoverBg
        showBorder: true
        onClicked: root.backRequested()
    }
}
