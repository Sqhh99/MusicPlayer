import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Qt.labs.platform as Platform
import MusicPlayer
import "components"

ApplicationWindow {
    id: root

    visible: true
    width: isMiniMode ? Theme.miniWidth : Theme.fullWidth
    height: isMiniMode ? Theme.miniHeight : Theme.fullHeight
    minimumWidth: isMiniMode ? Theme.miniWidth : Theme.minWidth
    minimumHeight: isMiniMode ? Theme.miniHeight : Theme.minHeight
    maximumWidth: isMiniMode ? Theme.miniWidth : Theme.fullWidth
    maximumHeight: isMiniMode ? Theme.miniHeight : Theme.fullHeight

    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    title: "Music Player"
    font.family: Theme.fontFamily

    property bool isMiniMode: false
    property bool showPlaylist: false
    property bool showLyrics: false
    property bool showEq: false
    property bool isShuffle: false
    property bool compact: width < 900

    property string trayTooltip: {
        var text = "Music Player"
        if (playerController.currentSong.length > 0) {
            text = playerController.currentSong
            if (playerController.isPlaying) {
                text += " - 播放中"
            } else if (playerController.isPaused) {
                text += " - 已暂停"
            }
        }
        return text
    }

    property var lyricsLines: [
        "Waiting in a car",
        "Waiting for a ride in the dark",
        "The night city grows",
        "Look and see her eyes, they glow",
        "Waiting in a car",
        "Waiting for a ride in the dark",
        "Drinking in the lounge",
        "Following the neon signs",
        "Waiting for a word",
        "Looking at the milky way",
        "The city is my church",
        "It wraps me in its blinding twilight",
        "Waiting in a car",
        "Waiting for the right time"
    ]

    function showMainWindow() {
        root.show()
        root.raise()
        root.requestActivate()
    }

    onIsMiniModeChanged: {
        if (isMiniMode) {
            showPlaylist = false
            showLyrics = false
            showEq = false
        }
    }

    onShowPlaylistChanged: {
        if (showPlaylist) {
            showLyrics = false
            showEq = false
        }
    }

    onShowLyricsChanged: {
        if (showLyrics) {
            showEq = false
        }
    }

    Behavior on width {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 0
        radius: isMiniMode ? Theme.radiusMini : Theme.radiusLarge
        color: Theme.cardBg
        border.color: Theme.cardBorder
        border.width: 1
    }

    WindowControls {
        id: windowControls
        z: 3
        anchors.top: card.top
        anchors.right: card.right
        anchors.topMargin: 14
        anchors.rightMargin: 16
        visible: !showPlaylist
        miniMode: root.isMiniMode
        onToggleMiniRequested: root.isMiniMode = !root.isMiniMode
        onMinimizeRequested: root.showMinimized()
        onCloseRequested: root.hide()
    }

    property point dragStartPosition
    property bool isDragging: false

    Item {
        id: dragArea
        anchors.left: card.left
        anchors.right: card.right
        anchors.top: card.top
        height: Theme.dragHeight
        z: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            enabled: !root.showPlaylist && !root.showEq
            onPressed: (mouse) => {
                root.isDragging = true
                root.dragStartPosition = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.isDragging) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    root.x = globalPos.x - root.dragStartPosition.x
                    root.y = globalPos.y - root.dragStartPosition.y
                }
            }
            onReleased: root.isDragging = false
        }
    }

    Item {
        id: contentArea
        anchors.fill: card
        anchors.margins: 0
    }

    FullPlayer {
        id: fullPlayer
        anchors.fill: contentArea
        visible: !isMiniMode
        controller: playerController
        showLyrics: root.showLyrics
        showEq: root.showEq
        showPlaylist: root.showPlaylist
        isShuffle: root.isShuffle
        compact: root.compact
        lyrics: root.lyricsLines
        onToggleLyrics: root.showLyrics = !root.showLyrics
        onToggleEq: root.showEq = !root.showEq
        onTogglePlaylist: root.showPlaylist = !root.showPlaylist
        onToggleShuffle: root.isShuffle = !root.isShuffle
        onOpenFilesRequested: fileDialog.open()
    }

    MiniPlayer {
        id: miniPlayer
        anchors.fill: contentArea
        visible: isMiniMode
        controller: playerController
        title: playerController.currentSong
        artist: "本地音乐"
        isShuffle: root.isShuffle
        onToggleShuffle: root.isShuffle = !root.isShuffle
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

    Shortcut {
        sequence: "Space"
        onActivated: playerController.togglePlayPause()
    }

    Shortcut {
        sequence: "Left"
        onActivated: playerController.previous()
    }
    Shortcut {
        sequence: "Right"
        onActivated: playerController.next()
    }

    Shortcut {
        sequence: "Up"
        onActivated: playerController.volume = Math.min(100, playerController.volume + 5)
    }
    Shortcut {
        sequence: "Down"
        onActivated: playerController.volume = Math.max(0, playerController.volume - 5)
    }

    Shortcut {
        sequence: "M"
        onActivated: playerController.isMuted = !playerController.isMuted
    }
    Shortcut {
        sequence: "L"
        onActivated: showPlaylist = !showPlaylist
    }

    Shortcut {
        sequence: "E"
        onActivated: showEq = !showEq
    }

    Platform.SystemTrayIcon {
        id: trayIcon
        visible: available
        icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/listen1.ico"
        tooltip: trayTooltip
        menu: Platform.Menu {
            Platform.MenuItem {
                text: root.visible ? "隐藏窗口" : "显示窗口"
                onTriggered: {
                    if (root.visible) {
                        root.hide()
                    } else {
                        root.showMainWindow()
                    }
                }
            }
            Platform.MenuSeparator { }
            Platform.MenuItem {
                text: playerController.isPlaying ? "暂停" : "播放"
                onTriggered: playerController.togglePlayPause()
            }
            Platform.MenuItem {
                text: "停止"
                onTriggered: playerController.stop()
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "上一首"
                onTriggered: playerController.previous()
            }
            Platform.MenuItem {
                text: "下一首"
                onTriggered: playerController.next()
            }

            Platform.MenuSeparator { }
            Platform.Menu {
                title: "音量"
                Platform.MenuItem {
                    text: "增加音量"
                    onTriggered: playerController.volume = Math.min(100, playerController.volume + 5)
                }
                Platform.MenuItem {
                    text: "减小音量"
                    onTriggered: playerController.volume = Math.max(0, playerController.volume - 5)
                }
                Platform.MenuSeparator { }
                Platform.MenuItem {
                    text: "静音"
                    checkable: true
                    checked: playerController.isMuted
                    onTriggered: playerController.isMuted = !playerController.isMuted
                }
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "循环播放"
                checkable: true
                checked: playerController.isLooping
                onTriggered: playerController.isLooping = !playerController.isLooping
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "退出"
                onTriggered: Qt.quit()
            }
        }

        onActivated: (reason) => {
            if (reason === Platform.SystemTrayIcon.Trigger
                || reason === Platform.SystemTrayIcon.DoubleClick) {
                root.showMainWindow()
            } else if (reason === Platform.SystemTrayIcon.MiddleClick) {
                playerController.togglePlayPause()
            }
        }
    }

    Component.onCompleted: {
        playerController.loadSavedPlaylist()
    }
}
