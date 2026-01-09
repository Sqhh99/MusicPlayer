import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs


Item {
    id: root

    property bool playlistVisible: false
    signal togglePlaylist()

    // Internal control button component (must be inside root item)
    component ControlButton: Button {
        id: btn
        
        property string iconSource: ""
        property string toolTipText: ""
        
        implicitWidth: Theme.buttonSize
        implicitHeight: Theme.buttonSize
        
        background: Rectangle {
            radius: Theme.buttonSize / 2
            color: btn.pressed ? Theme.pressedBg : (btn.hovered ? Theme.hoverBg : Theme.transparent)
            
            Behavior on color {
                ColorAnimation { duration: Theme.animationDurationFast }
            }
        }
        
        contentItem: Item {
            Image {
                anchors.centerIn: parent
                source: btn.iconSource
                sourceSize: Qt.size(Theme.iconSize, Theme.iconSize)
                fillMode: Image.PreserveAspectFit
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
        }
        
        ToolTip.visible: hovered && toolTipText.length > 0
        ToolTip.text: toolTipText
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.marginSmall
        spacing: Theme.spacingNormal

        // Progress bar with time labels
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            // Current time
            Text {
                id: currentTimeLabel
                Layout.preferredWidth: 40
                text: playerController.positionText
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
            }

            // Progress slider
            ProgressSlider {
                id: progressSlider
                Layout.fillWidth: true
                
                from: 0
                to: playerController.duration
                value: playerController.position
                
                onSeekRequested: (position) => {
                    playerController.seek(position)
                }
            }

            // Total time
            Text {
                id: totalTimeLabel
                Layout.preferredWidth: 40
                text: playerController.durationText
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignLeft
            }
        }

        // Control buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacingLarge

            Item { Layout.fillWidth: true }

            // Open file button
            ControlButton {
                iconSource: "qrc:/qt/qml/MusicPlayer/resources/icons/File1.png"
                toolTipText: "打开文件"
                onClicked: fileDialog.open()
            }

            // Toggle playlist button
            ControlButton {
                iconSource: root.playlistVisible 
                    ? "qrc:/qt/qml/MusicPlayer/resources/icons/playlist_icon_active.png" 
                    : "qrc:/qt/qml/MusicPlayer/resources/icons/playlist_icon.png"
                toolTipText: root.playlistVisible ? "隐藏播放列表 (L键)" : "显示播放列表 (L键)"
                onClicked: root.togglePlaylist()
            }

            // Play mode button
            ControlButton {
                iconSource: playerController.isLooping 
                    ? "qrc:/qt/qml/MusicPlayer/resources/icons/xunhuanbof2.png" 
                    : "qrc:/qt/qml/MusicPlayer/resources/icons/ShunxuBof3.png"
                toolTipText: playerController.isLooping ? "循环播放" : "顺序播放"
                onClicked: playerController.setLooping(!playerController.isLooping)
            }

            // Previous button
            ControlButton {
                iconSource: "qrc:/qt/qml/MusicPlayer/resources/icons/icon_previous.png"
                toolTipText: "上一首"
                onClicked: playerController.previous()
            }

            // Play/Pause button
            ControlButton {
                iconSource: playerController.isPlaying 
                    ? "qrc:/qt/qml/MusicPlayer/resources/icons/player01.png" 
                    : "qrc:/qt/qml/MusicPlayer/resources/icons/pause01.png"
                toolTipText: playerController.isPlaying ? "暂停 (空格键)" : "播放 (空格键)"
                onClicked: playerController.togglePlayPause()
            }

            // Next button
            ControlButton {
                iconSource: "qrc:/qt/qml/MusicPlayer/resources/icons/icon_next.png"
                toolTipText: "下一首"
                onClicked: playerController.next()
            }

            // Volume button
            ControlButton {
                id: volumeButton
                iconSource: "qrc:/qt/qml/MusicPlayer/resources/icons/player_volume_increase.png"
                toolTipText: "音量"
                onClicked: volumePopup.open()
            }

            Item { Layout.fillWidth: true }
        }
    }

    // Volume popup
    VolumePopup {
        id: volumePopup
        x: volumeButton.x + (volumeButton.width - width) / 2
        y: volumeButton.y - height - 10
    }

    FileDialog {
        id: fileDialog
        title: "打开音乐文件"
        fileMode: FileDialog.OpenFiles
        currentFolder: playerController.lastFolder
        nameFilters: [
            "Music Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma *.3gp *.mp4 *.mov *.avi *.mkv *.webm)",
            "Audio Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma)",
            "Video Files (*.mp4 *.mov *.avi *.mkv *.webm *.3gp)",
            "All Files (*)"
        ]
        onAccepted: playerController.setPlaylistFromUrls(selectedFiles)
    }
}

