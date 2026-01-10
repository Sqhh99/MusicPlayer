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

    flags: isPinned ? (Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint) 
                    : (Qt.Window | Qt.FramelessWindowHint)
    color: "transparent"
    title: "Music Player"
    font.family: Theme.fontFamily

    property bool isPinned: false

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

    function setShuffleEnabled(enabled) {
        root.isShuffle = enabled
        if (enabled && playerController.isLooping) {
            playerController.isLooping = false
        }
    }

    function toggleShuffle() {
        setShuffleEnabled(!root.isShuffle)
    }

    // Preserve lyrics state when switching to mini mode
    property bool savedLyricsState: false

    onIsMiniModeChanged: {
        if (isMiniMode) {
            // Save lyrics state before switching to mini mode
            savedLyricsState = showLyrics
            showPlaylist = false
            showLyrics = false
            showEq = false
        } else {
            // Restore lyrics state when switching back to full mode
            if (savedLyricsState) {
                showLyrics = true
            }
        }
    }

    onShowPlaylistChanged: {
        if (showPlaylist) {
            // Don't reset showLyrics - just hide it temporarily
            showEq = false
        }
    }

    onShowLyricsChanged: {
        if (showLyrics) {
            showEq = false
        }
    }

    Connections {
        target: playerController
        function onLoopingChanged() {
            if (playerController.isLooping && root.isShuffle) {
                root.isShuffle = false
            }
        }
    }

    Behavior on width {
        NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
    }
    Behavior on height {
        NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
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
        isPinned: root.isPinned
        onToggleMiniRequested: root.isMiniMode = !root.isMiniMode
        onMinimizeRequested: root.showMinimized()
        onCloseRequested: root.hide()
        onTogglePinRequested: root.isPinned = !root.isPinned
    }

    property point dragStartPosition
    property bool isDragging: false
    property int snapThreshold: 20  // Snap distance from screen edge

    // Edge snapping function for mini mode
    function snapToEdge(newX, newY) {
        var screenWidth = Screen.width
        var screenHeight = Screen.height
        var windowWidth = root.width
        var windowHeight = root.height

        // Snap to left edge
        if (newX < snapThreshold) {
            newX = 0
        }
        // Snap to right edge
        else if (newX + windowWidth > screenWidth - snapThreshold) {
            newX = screenWidth - windowWidth
        }

        // Snap to top edge
        if (newY < snapThreshold) {
            newY = 0
        }
        // Snap to bottom edge (accounting for taskbar ~40px)
        else if (newY + windowHeight > screenHeight - snapThreshold - 40) {
            newY = screenHeight - windowHeight - 40
        }

        return Qt.point(newX, newY)
    }

    Item {
        id: dragArea
        anchors.left: card.left
        anchors.right: card.right
        anchors.top: card.top
        height: Theme.dragHeight
        z: 1
        visible: !root.showPlaylist && !root.showEq  // Hide when playlist/EQ open

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            onPressed: (mouse) => {
                root.isDragging = true
                root.dragStartPosition = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.isDragging) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    var newX = globalPos.x - root.dragStartPosition.x
                    var newY = globalPos.y - root.dragStartPosition.y
                    
                    // Apply edge snapping only in mini mode
                    if (root.isMiniMode) {
                        var snapped = root.snapToEdge(newX, newY)
                        root.x = snapped.x
                        root.y = snapped.y
                    } else {
                        root.x = newX
                        root.y = newY
                    }
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
        visible: opacity > 0
        opacity: isMiniMode ? 0 : 1
        controller: playerController
        appWindow: root
        showLyrics: root.showLyrics
        showEq: root.showEq
        showPlaylist: root.showPlaylist
        isShuffle: root.isShuffle
        compact: root.compact
        lyrics: root.lyricsLines
        onToggleLyrics: root.showLyrics = !root.showLyrics
        onToggleEq: root.showEq = !root.showEq
        onTogglePlaylist: root.showPlaylist = !root.showPlaylist
        onToggleShuffle: root.toggleShuffle()
        onOpenFilesRequested: fileDialog.open()

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }
    }

    MiniPlayer {
        id: miniPlayer
        anchors.fill: contentArea
        visible: opacity > 0
        opacity: isMiniMode ? 1 : 0
        controller: playerController
        title: playerController.currentSong
        artist: "本地音乐"
        isShuffle: root.isShuffle
        onToggleShuffle: root.toggleShuffle()

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }
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
                icon.source: root.visible ? "qrc:/qt/qml/MusicPlayer/resources/icons/minus.png" : "qrc:/qt/qml/MusicPlayer/resources/icons/maximize-2.png"
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
                icon.source: playerController.isPlaying 
                    ? "qrc:/qt/qml/MusicPlayer/resources/icons/pause.png" 
                    : "qrc:/qt/qml/MusicPlayer/resources/icons/play.png"
                onTriggered: playerController.togglePlayPause()
            }
            Platform.MenuItem {
                text: "上一首"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/skip-back.png"
                onTriggered: playerController.previous()
            }
            Platform.MenuItem {
                text: "下一首"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/skip-forward.png"
                onTriggered: playerController.next()
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "增加音量"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
                onTriggered: playerController.volume = Math.min(100, playerController.volume + 10)
            }
            Platform.MenuItem {
                text: "减小音量"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
                onTriggered: playerController.volume = Math.max(0, playerController.volume - 10)
            }
            Platform.MenuItem {
                text: playerController.isMuted ? "取消静音" : "静音"
                icon.source: playerController.isMuted 
                    ? "qrc:/qt/qml/MusicPlayer/resources/icons/volume-x.png"
                    : "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
                onTriggered: playerController.isMuted = !playerController.isMuted
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "循环播放"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/repeat.png"
                checkable: true
                checked: playerController.isLooping
                onTriggered: playerController.isLooping = !playerController.isLooping
            }

            Platform.MenuItem {
                text: "随机播放"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/shuffle.png"
                checkable: true
                checked: root.isShuffle
                onTriggered: root.toggleShuffle()
            }

            Platform.MenuSeparator { }

            Platform.MenuItem {
                text: "退出"
                icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/x.png"
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
