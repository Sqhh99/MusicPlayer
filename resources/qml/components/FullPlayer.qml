import QtQuick
import QtQuick.Layouts
import MusicPlayer
import "./"

Item {
    id: root

    property var controller
    property bool showLyrics: false
    property bool showEq: false
    property bool showPlaylist: false
    property bool isShuffle: false
    property bool compact: false
    property var lyrics: []
    property var appWindow: null

    signal toggleLyrics()
    signal toggleEq()
    signal togglePlaylist()
    signal toggleShuffle()
    signal openFilesRequested()

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.outerPadding
        spacing: Theme.columnSpacing

        Item {
            Layout.preferredWidth: Theme.albumColumnWidth
            Layout.fillHeight: true

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 22

                AlbumArt {
                    size: Theme.albumSize
                    cornerRadius: Theme.albumRadius
                    title: root.controller ? root.controller.currentSong : ""
                    playing: root.controller ? root.controller.isPlaying : false
                    source: root.controller ? root.controller.albumArtUrl : ""
                }

                EqualizerBars {
                    width: Theme.albumSize
                    height: 26
                    playing: root.controller ? root.controller.isPlaying : false
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item { Layout.preferredHeight: 58 }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: root.controller && root.controller.currentSong.length > 0
                            ? root.controller.currentSong
                            : "未选择歌曲"
                        font.pixelSize: Theme.titleSize
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        rightPadding: Theme.headerInset
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "本地音乐"
                        font.pixelSize: Theme.artistSize
                        font.family: Theme.fontFamily
                        color: Theme.textSubtle
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.preferredHeight: 2 }

                Item {
                    id: centerArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.showLyrics ? 0 : 220
                    Layout.minimumHeight: 200
                    Layout.fillHeight: root.showLyrics

                    LyricsPanel {
                        id: lyricsPanel
                        anchors.fill: parent
                        lyrics: root.controller ? root.controller.lyrics : []
                        highlightIndex: root.controller ? root.controller.currentLyricIndex : -1
                        visible: root.showLyrics
                        opacity: root.showLyrics ? 1 : 0
                        onBackRequested: root.toggleLyrics()
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Item {
                        id: controlsPanel
                        anchors.fill: parent
                        visible: !root.showLyrics
                        opacity: root.showLyrics ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                RowLayout {
                                    spacing: 10

                                    IconButton {
                                        size: 34
                                        iconSize: 16
                                        iconSource: Theme.iconPath + "mic-vocal.png"
                                        iconOpacity: Theme.buttonIconMutedOpacity
                                        activeOpacity: Theme.buttonIconStrongOpacity
                                        active: root.showLyrics
                                        onClicked: root.toggleLyrics()
                                    }

                                    IconButton {
                                        size: 34
                                        iconSize: 16
                                        iconSource: Theme.iconPath + "sliders-vertical.png"
                                        iconOpacity: Theme.buttonIconMutedOpacity
                                        activeOpacity: Theme.buttonIconStrongOpacity
                                        active: root.showEq
                                        onClicked: root.toggleEq()
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 10

                                    IconButton {
                                        size: 34
                                        iconSize: 16
                                        iconSource: Theme.iconPath + "shuffle.png"
                                        iconOpacity: Theme.buttonIconMutedOpacity
                                        activeOpacity: Theme.buttonIconStrongOpacity
                                        activeBackgroundColor: Theme.accentSoft
                                        active: root.isShuffle
                                        onClicked: root.toggleShuffle()
                                    }

                                    IconButton {
                                        size: 34
                                        iconSize: 16
                                        iconSource: Theme.iconPath + "repeat.png"
                                        iconOpacity: Theme.buttonIconMutedOpacity
                                        activeOpacity: Theme.buttonIconStrongOpacity
                                        activeBackgroundColor: Theme.accentSoft
                                        active: root.controller ? root.controller.isLooping : false
                                        onClicked: {
                                            if (root.controller) {
                                                root.controller.isLooping = !root.controller.isLooping
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                ProgressBar {
                                    Layout.fillWidth: true
                                    height: Theme.progressHeight
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

                                    Text {
                                        text: root.controller ? root.controller.positionText : "0:00"
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamilyMono
                                        color: Theme.textMuted
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: root.controller ? root.controller.durationText : "0:00"
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamilyMono
                                        color: Theme.textMuted
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 36
                                Layout.alignment: Qt.AlignHCenter

                                IconButton {
                                    size: Theme.controlSizeMd
                                    iconSize: 24
                                    iconOpacity: Theme.buttonIconSoftOpacity
                                    iconSource: Theme.iconPath + "skip-back.png"
                                    onClicked: root.controller ? root.controller.previous() : undefined
                                }

                                IconButton {
                                    size: Theme.controlSizeMd
                                    iconSize: 24
                                    iconOpacity: Theme.buttonIconStrongOpacity
                                    iconSource: root.controller && root.controller.isPlaying
                                        ? Theme.iconPath + "pause.png"
                                        : Theme.iconPath + "play.png"
                                    onClicked: root.controller ? root.controller.togglePlayPause() : undefined
                                }

                                IconButton {
                                    size: Theme.controlSizeMd
                                    iconSize: 24
                                    iconOpacity: Theme.buttonIconSoftOpacity
                                    iconSource: Theme.iconPath + "skip-forward.png"
                                    onClicked: root.controller ? root.controller.next() : undefined
                                }
                            }

                        }
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.bottomBarHeight
                    spacing: 14

                    Rectangle {
                        id: playlistButton
                        height: 36
                        radius: 12
                        property bool hovered: playlistButtonArea.containsMouse
                        color: root.showPlaylist
                            ? Theme.materialButtonActiveBg
                            : (playlistButtonArea.pressed
                                ? Theme.materialButtonPressedBg
                                : (hovered ? Theme.materialButtonHoverBg : Theme.materialButtonBg))
                        border.color: Theme.materialButtonBorder
                        border.width: 1
                        implicitWidth: playlistRow.implicitWidth + 20
                        Layout.alignment: Qt.AlignVCenter

                        Row {
                            id: playlistRow
                            spacing: 8
                            anchors.centerIn: parent

                            TintedIcon {
                                source: Theme.iconPath + "list-music.png"
                                width: 16
                                height: 16
                                tintColor: Theme.buttonIconColor
                                opacity: 0.78
                            }

                            Text {
                                text: "播放列表"
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                                font.weight: Font.DemiBold
                                color: Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: playlistButtonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePlaylist()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    VolumeControl {
                        volume: root.controller ? root.controller.volume : 0
                        muted: root.controller ? root.controller.isMuted : false
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        onVolumeRequested: (value) => { if (root.controller) { root.controller.volume = value } }
                        onMuteToggled: { if (root.controller) { root.controller.isMuted = !root.controller.isMuted } }
                    }
                }
            }
        }
    }

    Item {
        id: eqOverlay
        anchors.fill: parent
        visible: root.showEq && !root.showLyrics
        opacity: root.showEq && !root.showLyrics ? 1 : 0
        z: 3
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            onClicked: root.toggleEq()
        }

        EqualizerPanel {
            id: eqPanel
            anchors.centerIn: parent
            z: 1
            bass: root.controller ? root.controller.bassLevel : 50
            mid: root.controller ? root.controller.midLevel : 50
            treble: root.controller ? root.controller.trebleLevel : 50
            onBassRequested: (value) => { if (root.controller) { root.controller.bassLevel = value } }
            onMidRequested: (value) => { if (root.controller) { root.controller.midLevel = value } }
            onTrebleRequested: (value) => { if (root.controller) { root.controller.trebleLevel = value } }
        }
    }

}
