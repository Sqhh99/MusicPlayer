import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    WindowDragArea {
        id: dragArea
        anchors.left: card.left
        anchors.right: card.right
        anchors.top: card.top
        appWindow: root
        isMiniMode: root.isMiniMode
        showPlaylist: root.showPlaylist
        showEq: root.showEq
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

    OpenFilesDialog {
        id: fileDialog
        controller: playerController
    }

    AppShortcuts {
        controller: playerController
        appWindow: root
    }

    TrayIcon {
        id: trayIcon
        appWindow: root
        controller: playerController
        isShuffle: root.isShuffle
        onToggleShuffleRequested: root.toggleShuffle()
    }

    Component.onCompleted: {
        playerController.loadSavedPlaylist()
    }
}
