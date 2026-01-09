import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts


Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.marginNormal
        spacing: Theme.spacingNormal

        // Playlist ListView
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 100

            model: playerController.playlist
            clip: true
            currentIndex: playerController.currentIndex

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                
                background: Rectangle {
                    implicitWidth: 8
                    color: "transparent"
                }
                
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: parent.pressed ? Theme.accent : Theme.sliderTrack
                    opacity: parent.active ? 1.0 : 0.5
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationDurationFast }
                    }
                }
            }

            delegate: ItemDelegate {
                id: delegateItem
                width: listView.width
                height: 36

                required property int index
                required property string fileName

                highlighted: listView.currentIndex === index
                
                background: Rectangle {
                    color: {
                        if (delegateItem.highlighted) {
                            return Theme.accent
                        } else if (delegateItem.hovered) {
                            return Theme.hoverBg
                        }
                        return Theme.transparent
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationDurationFast }
                    }
                }

                contentItem: Item {
                    Text {
                        anchors.fill: parent
                        text: delegateItem.fileName
                        color: delegateItem.highlighted ? Theme.white : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeNormal
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        leftPadding: Theme.marginNormal
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                onClicked: {
                    listView.currentIndex = index
                }

                onDoubleClicked: {
                    playerController.playIndex(index)
                }
            }

            // Highlight current item
            highlight: Rectangle {
                color: Theme.accent
                radius: 0
            }
            highlightFollowsCurrentItem: true

            // Empty state
            Text {
                anchors.centerIn: parent
                text: "点击\"打开文件\"添加音乐"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeNormal
                visible: listView.count === 0
            }
        }
    }
}

