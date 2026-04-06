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
    height: parent ? parent.height : 180

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 22  // Larger to balance album art shadow effect
        anchors.rightMargin: Theme.outerPaddingMini
        anchors.topMargin: Theme.outerPaddingMini
        anchors.bottomMargin: Theme.outerPaddingMini
        spacing: 18

        AlbumArt {
            size: Theme.albumSizeMini
            cornerRadius: Theme.albumRadiusMini
            title: root.title
            playing: root.controller ? root.controller.isPlaying : false
            source: root.controller ? root.controller.albumArtUrl : ""
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 15

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
                Layout.topMargin: 11
                spacing: 3

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
                    activeOpacity: Theme.buttonIconStrongOpacity
                    activeBackgroundColor: Theme.accentSoft
                    iconOpacity: Theme.buttonIconMutedOpacity
                    onClicked: root.toggleShuffle()
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    size: 34
                    iconSize: 16
                    iconOpacity: Theme.buttonIconSoftOpacity
                    iconSource: Theme.iconPath + "skip-back.png"
                    onClicked: root.controller ? root.controller.previous() : undefined
                }

                IconButton {
                    size: Theme.controlSizeMiniPlay
                    iconSize: 20
                    iconSource: root.controller && root.controller.isPlaying
                        ? Theme.iconPath + "pause.png"
                        : Theme.iconPath + "play.png"
                    backgroundColor: Theme.materialPrimaryButtonBg
                    hoverColor: Theme.materialPrimaryButtonHoverBg
                    pressedColor: Theme.materialPrimaryButtonPressedBg
                    showBorder: true
                    borderColor: Theme.materialPrimaryButtonBorder
                    iconOpacity: Theme.buttonIconStrongOpacity
                    onClicked: root.controller ? root.controller.togglePlayPause() : undefined
                }

                IconButton {
                    size: 34
                    iconSize: 16
                    iconOpacity: Theme.buttonIconSoftOpacity
                    iconSource: Theme.iconPath + "skip-forward.png"
                    onClicked: root.controller ? root.controller.next() : undefined
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    size: 26
                    iconSize: 14
                    iconSource: Theme.iconPath + "repeat.png"
                    active: root.controller ? root.controller.isLooping : false
                    activeOpacity: Theme.buttonIconStrongOpacity
                    activeBackgroundColor: Theme.accentSoft
                    iconOpacity: Theme.buttonIconMutedOpacity
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
