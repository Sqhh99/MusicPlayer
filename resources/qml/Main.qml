import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    
    visible: true
    width: Theme.windowWidth
    height: Theme.windowHeight
    minimumWidth: Theme.windowMinWidth
    minimumHeight: Theme.windowMinHeight
    
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    
    title: "Music Player"

    // Properties for playlist visibility
    property bool playlistVisible: false
    property bool isAlwaysOnTop: false

    // Window dragging
    property point dragStartPosition
    property bool isDragging: false

    // Main content
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: Theme.background
        radius: Theme.borderRadius
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.marginNormal
            spacing: 0

            // Title bar with song name and window controls
            TitleBar {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                
                songName: playerController.currentSong
                isAlwaysOnTop: root.isAlwaysOnTop
                
                onMinimizeClicked: root.showMinimized()
                onCloseClicked: root.hide()
                onAlwaysOnTopClicked: {
                    root.isAlwaysOnTop = !root.isAlwaysOnTop
                    if (root.isAlwaysOnTop) {
                        root.flags = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                    } else {
                        root.flags = Qt.Window | Qt.FramelessWindowHint
                    }
                    root.show()
                }
                
                onDragStarted: (mousePos) => {
                    root.isDragging = true
                    root.dragStartPosition = Qt.point(mousePos.x, mousePos.y)
                }
                
                onDragMoved: (mouseGlobalPos) => {
                    if (root.isDragging) {
                        root.x = mouseGlobalPos.x - root.dragStartPosition.x
                        root.y = mouseGlobalPos.y - root.dragStartPosition.y
                    }
                }
                
                onDragEnded: root.isDragging = false
            }

            // Player controls area
            PlayerControls {
                id: playerControls
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                
                onTogglePlaylist: {
                    root.playlistVisible = !root.playlistVisible
                }
                
                playlistVisible: root.playlistVisible
            }

            // Playlist (collapsible)
            PlaylistView {
                id: playlistView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Theme.playlistHeight
                visible: root.playlistVisible
            }
        }
    }

    // Notification overlay
    Rectangle {
        id: notification
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        width: notificationText.width + 24
        height: notificationText.height + 16
        color: Theme.notificationBg
        radius: 10
        border.color: Theme.notificationBorder
        border.width: 1
        opacity: 0
        visible: opacity > 0

        Text {
            id: notificationText
            anchors.centerIn: parent
            color: Theme.white
            font.pixelSize: Theme.fontSizeMedium
            text: ""
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationDuration }
        }
    }

    // Function to show notifications
    function showNotification(message, durationMs) {
        notificationText.text = message
        notification.opacity = 1
        notificationTimer.interval = durationMs || 3000
        notificationTimer.restart()
    }

    Timer {
        id: notificationTimer
        interval: 3000
        onTriggered: notification.opacity = 0
    }

    // Keyboard shortcuts
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
        onActivated: playerController.setVolume(Math.min(100, playerController.volume + 5))
    }

    Shortcut {
        sequence: "Down"
        onActivated: playerController.setVolume(Math.max(0, playerController.volume - 5))
    }

    Shortcut {
        sequence: "M"
        onActivated: playerController.setMuted(!playerController.isMuted)
    }

    Shortcut {
        sequence: "L"
        onActivated: root.playlistVisible = !root.playlistVisible
    }

    Shortcut {
        sequence: "E"
        onActivated: equalizerDialog.open()
    }

    // Equalizer dialog
    EqualizerDialog {
        id: equalizerDialog
        anchors.centerIn: parent
    }

    // Adjust window size when playlist visibility changes
    onPlaylistVisibleChanged: {
        if (playlistVisible) {
            root.height = Theme.windowHeight + Theme.playlistHeight
        } else {
            root.height = Theme.windowHeight
        }
    }

    // Load saved playlist on startup
    Component.onCompleted: {
        playerController.loadSavedPlaylist()
    }
}

