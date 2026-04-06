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
    property bool showSettings: false
    property bool isShuffle: false
    property bool compact: width < 900

    Component.onCompleted: {
        windowEffects.cornerRadius = isMiniMode ? Theme.radiusMini : Theme.radiusLarge
        playerController.loadSavedPlaylist()
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

    function openSettings() {
        if (root.isMiniMode) {
            root.isMiniMode = false
        }
        root.showPlaylist = false
        root.showEq = false
        root.showSettings = true
    }

    // Preserve lyrics state when switching to mini mode
    property bool savedLyricsState: false

    onIsMiniModeChanged: {
        windowEffects.cornerRadius = isMiniMode ? Theme.radiusMini : Theme.radiusLarge
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
            showSettings = false
            showEq = false
        }
    }

    onShowLyricsChanged: {
        if (showLyrics) {
            showEq = false
        }
    }

    onShowSettingsChanged: {
        if (showSettings) {
            showPlaylist = false
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
        id: surface
        anchors.fill: parent
        anchors.margins: 0
        radius: isMiniMode ? Theme.radiusMini : Theme.radiusLarge
        color: Theme.surfaceBg
        border.color: Theme.surfaceBorder
        border.width: 1
        clip: true

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.surfaceHighlight }
                GradientStop { position: 0.45; color: Theme.surfaceMidHighlight }
                GradientStop { position: 1.0; color: Theme.surfaceBottomTint }
            }
        }

        Rectangle {
            width: root.isMiniMode ? 180 : 320
            height: root.isMiniMode ? 120 : 260
            x: root.isMiniMode ? -24 : -72
            y: root.isMiniMode ? -30 : -88
            radius: width / 2
            color: Theme.surfaceGlowBlue
        }

        Rectangle {
            width: root.isMiniMode ? 120 : 220
            height: root.isMiniMode ? 120 : 220
            x: width + 90
            y: height - (root.isMiniMode ? 80 : 120)
            radius: width / 2
            color: Theme.surfaceGlowRose
        }

        Item {
            id: contentArea
            anchors.fill: parent

            FullPlayer {
                id: fullPlayer
                anchors.fill: parent
                visible: opacity > 0
                opacity: (isMiniMode || showPlaylist || showSettings) ? 0 : 1
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
                anchors.fill: parent
                visible: opacity > 0
                opacity: (isMiniMode && !showSettings) ? 1 : 0
                controller: playerController
                title: playerController.currentSong
                artist: "本地音乐"
                isShuffle: root.isShuffle
                onToggleShuffle: root.toggleShuffle()

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            PlaylistOverlay {
                id: playlistOverlay
                anchors.fill: parent
                open: root.showPlaylist && !root.isMiniMode
                model: playerController.playlist
                currentIndex: playerController.currentIndex
                isPlaying: playerController.isPlaying
                appWindow: root
                onCloseRequested: root.showPlaylist = false
                onOpenFilesRequested: fileDialog.open()
                onSelectIndex: (index) => {
                    playerController.playIndex(index)
                    if (root.compact) {
                        root.showPlaylist = false
                    }
                }
            }

            SettingsOverlay {
                id: settingsOverlay
                anchors.fill: parent
                open: root.showSettings
                appWindow: root
                settings: appSettings
                onCloseRequested: root.showSettings = false
            }
        }

        WindowControls {
            id: windowControls
            z: 3
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 16
            visible: !showPlaylist && !showSettings
            miniMode: root.isMiniMode
            isPinned: root.isPinned
            settingsOpen: root.showSettings
            onToggleMiniRequested: root.isMiniMode = !root.isMiniMode
            onMinimizeRequested: root.showMinimized()
            onCloseRequested: root.hide()
            onTogglePinRequested: root.isPinned = !root.isPinned
            onOpenSettingsRequested: root.openSettings()
        }

        WindowDragArea {
            id: dragArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            appWindow: root
            isMiniMode: root.isMiniMode
            showPlaylist: root.showPlaylist
            showEq: root.showEq
            showSettings: root.showSettings
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
}
