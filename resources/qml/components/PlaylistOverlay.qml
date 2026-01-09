import QtQuick
import QtQuick.Layouts
import MusicPlayer
import "./"

Rectangle {
    id: root

    property bool open: false
    property var model
    property int currentIndex: -1
    property bool isPlaying: false

    signal closeRequested()
    signal openFilesRequested()
    signal selectIndex(int index)

    visible: open || opacity > 0
    opacity: open ? 1 : 0
    x: open ? 0 : width

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: parent.width
    radius: Theme.radiusLarge
    color: Theme.overlayBg
    border.color: Theme.overlayBorder
    border.width: 1
    clip: true
    z: 4


    Behavior on opacity {
        NumberAnimation { duration: 240 }
    }
    Behavior on x {
        NumberAnimation { duration: 320; easing.type: Easing.InOutQuad }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Text {
                    text: "播放队列"
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                }

                IconButton {
                    size: 30
                    iconSize: 12
                    iconSource: Theme.iconPath + "x.png"
                    iconOpacity: 0.6
                    hoverColor: Theme.hoverBg
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.overlayBorder
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.model
            boundsBehavior: Flickable.StopAtBounds
            interactive: true
            leftMargin: 16
            rightMargin: 16
            topMargin: 16
            bottomMargin: 16

            delegate: Item {
                id: rowItem
                width: listView.width - 32
                height: 54
                property bool hovered: false

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: root.currentIndex === itemIndex
                        ? "#eff6ff"
                        : (rowItem.hovered ? "#f9fafb" : "transparent")
                    opacity: root.currentIndex === itemIndex ? 0.5 : 1
                    border.color: "transparent"
                    border.width: 0
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: fileName
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: (root.currentIndex === itemIndex) ? Theme.accentDark : Theme.textSecondary
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "本地音乐"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            color: Theme.textSubtle
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: durationText
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyMono
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: rowItem.hovered = true
                    onExited: rowItem.hovered = false
                    onClicked: root.selectIndex(itemIndex)
                }
            }
        }
    }
}
