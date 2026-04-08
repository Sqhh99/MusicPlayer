import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var controller
    property var appWindow

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (root.controller) {
                root.controller.togglePlayPause()
            }
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (root.controller) {
                root.controller.previous()
            }
        }
    }
    Shortcut {
        sequence: "Right"
        onActivated: {
            if (root.controller) {
                root.controller.next()
            }
        }
    }

    Shortcut {
        sequence: "Up"
        onActivated: {
            if (root.controller) {
                root.controller.volume = Math.min(100, root.controller.volume + 5)
            }
        }
    }
    Shortcut {
        sequence: "Down"
        onActivated: {
            if (root.controller) {
                root.controller.volume = Math.max(0, root.controller.volume - 5)
            }
        }
    }

    Shortcut {
        sequence: "M"
        onActivated: {
            if (root.controller) {
                root.controller.isMuted = !root.controller.isMuted
            }
        }
    }
    Shortcut {
        sequence: "L"
        onActivated: {
            if (root.appWindow) {
                root.appWindow.showPlaylist = !root.appWindow.showPlaylist
            }
        }
    }

    Shortcut {
        sequence: "E"
        onActivated: {
            if (root.appWindow) {
                root.appWindow.showEq = !root.appWindow.showEq
            }
        }
    }
}
