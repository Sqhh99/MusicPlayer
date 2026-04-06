import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property var lyrics: []
    property int highlightIndex: -1

    signal backRequested()

    // Calculate where to scroll to keep current lyric centered
    onHighlightIndexChanged: {
        if (highlightIndex >= 0 && highlightIndex < lyricsRepeater.count) {
            var item = lyricsRepeater.itemAt(highlightIndex)
            if (item) {
                // Calculate target scroll position to center the highlighted item
                var itemCenterY = item.y + item.height / 2
                var viewportCenterY = flickable.height / 2
                var targetY = itemCenterY - viewportCenterY

                // Clamp to valid scroll range
                var maxY = Math.max(0, flickable.contentHeight - flickable.height)
                targetY = Math.max(0, Math.min(targetY, maxY))

                scrollAnimation.to = targetY
                scrollAnimation.restart()
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.bottomMargin: 60  // Space for back button
        contentWidth: width
        contentHeight: lyricsColumn.height + 40
        clip: true

        NumberAnimation on contentY {
            id: scrollAnimation
            duration: 300
            easing.type: Easing.OutCubic
            running: false
        }

        Column {
            id: lyricsColumn
            x: 16
            y: 20
            width: flickable.width - 32
            spacing: 16

            Repeater {
                id: lyricsRepeater
                model: root.lyrics

                Text {
                    width: lyricsColumn.width
                    text: modelData
                    color: index === root.highlightIndex ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: index === root.highlightIndex ? 16 : 13
                    font.family: Theme.fontFamily
                    font.weight: index === root.highlightIndex ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    opacity: index === root.highlightIndex ? 1.0 : 0.7

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 150 }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
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
        iconColor: Theme.buttonIconColor
        iconOpacity: Theme.buttonIconSoftOpacity
        hoverColor: Theme.hoverBg
        showBorder: true
        onClicked: root.backRequested()
    }
}
