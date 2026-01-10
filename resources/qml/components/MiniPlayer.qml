import QtQuick
import QtQuick.Layouts
import MusicPlayer
import "./"

Item {
    id: root

    property var controller
    property string title: ""
    property string artist: ""
    property bool isShuffle: false

    signal toggleShuffle()

    width: parent ? parent.width : 520
    height: parent ? parent.height : 190

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.outerPaddingMini
        spacing: 20

        AlbumArt {
            size: Theme.albumSizeMini
            cornerRadius: Theme.albumRadiusMini
            title: root.title
            playing: root.controller ? root.controller.isPlaying : false
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.title.length > 0 ? root.title : "未选择歌曲"
                    font.pixelSize: Theme.titleSizeMini
                    font.family: Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    rightPadding: Theme.headerInset
                    Layout.fillWidth: true
                }

                Text {
                    text: root.artist
                    font.pixelSize: Theme.artistSizeMini
                    font.family: Theme.fontFamily
                    color: Theme.textSubtle
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                ProgressBar {
                    Layout.fillWidth: true
                    height: Theme.progressHeightMini
                    handleSize: 10
                    from: 0
                    to: root.controller ? root.controller.duration : 0
                    value: root.controller ? root.controller.position : 0
                    showHandle: true
                    onSeekRequested: (value) => {
                        if (root.controller) {
                            root.controller.seek(value)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.controller ? root.controller.positionText : "0:00"
                        font.pixelSize: 10
                        font.family: Theme.fontFamilyMono
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignLeft
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.controller ? root.controller.durationText : "0:00"
                        font.pixelSize: 10
                        font.family: Theme.fontFamilyMono
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                IconButton {
                    size: 26
                    iconSize: 14
                    iconSource: Theme.iconPath + "shuffle.png"
                    active: root.isShuffle
                    activeOpacity: 0.9
                    activeBackgroundColor: Theme.accentSoft
                    iconOpacity: 0.55
                    onClicked: root.toggleShuffle()
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    size: 36
                    iconSize: 18
                    iconOpacity: 0.7
                    iconSource: Theme.iconPath + "skip-back.png"
                    onClicked: root.controller ? root.controller.previous() : undefined
                }

                IconButton {
                    size: Theme.controlSizeMiniPlay
                    iconSize: 20
                    iconSource: root.controller && root.controller.isPlaying
                        ? Theme.iconPath + "pause.png"
                        : Theme.iconPath + "play.png"
                    backgroundColor: "#ffffff"
                    showBorder: true
                    iconOpacity: 0.9
                    onClicked: root.controller ? root.controller.togglePlayPause() : undefined
                }

                IconButton {
                    size: 36
                    iconSize: 18
                    iconOpacity: 0.7
                    iconSource: Theme.iconPath + "skip-forward.png"
                    onClicked: root.controller ? root.controller.next() : undefined
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    size: 26
                    iconSize: 14
                    iconSource: Theme.iconPath + "repeat.png"
                    active: root.controller ? root.controller.isLooping : false
                    activeOpacity: 0.9
                    activeBackgroundColor: Theme.accentSoft
                    iconOpacity: 0.55
                    onClicked: {
                        if (root.controller) {
                            root.controller.isLooping = !root.controller.isLooping
                        }
                    }
                }
            }
        }
    }
}
